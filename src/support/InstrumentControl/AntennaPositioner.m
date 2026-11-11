classdef AntennaPositioner < handle
    %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
    % AntennaPositioner
    %
    % DESCRIPTION:
    % Wrapper for the ETS-Lindgren EMCenter dual-axis antenna positioner
    % (turntable = theta, tower = phi) used in ARES antenna measurements.
    % Hides axis naming ("1A"/"1B") and command formatting from measurement
    % code, which then reads as physical intent:
    %
    %   pos.setSpeeds(tableSpeed, towerSpeed);
    %   pos.moveTo(theta, phi);
    %   pos.waitUntilStill();
    %
    % NOTES:
    %   - waitUntilStill accepts a CancelFcn so an operator can stop a sweep
    %     from the progress dialog. The wait loop polls that function and
    %     stops both axes if it returns true.
    %   - waitUntilStill does not trust *OPC? alone. An axis counts as done
    %     only when *OPC? = 1, DIR? says it is not moving, and CP? is within
    %     PositionToleranceDeg of the commanded angle, on two polls in a row.
    %     (Chamber data showed measurements taken while the tower was still
    %     turning when only *OPC? was checked.)
    %   - The underlying EMCenter object must expose scpi(), meaning it is a
    %     SCPIInstrument or a subclass. Because SCPIInstrument is
    %     transport-backed, this positioner is simulatable without changes.
    %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

    properties
        EMCenter                          % SCPIInstrument-compatible object
        TableAxis    (1,1) string = "1A"  % turntable (theta) axis ID
        TowerAxis    (1,1) string = "1B"  % tower (phi) axis ID
        HomeThetaDeg (1,1) double = 0
        HomePhiDeg   (1,1) double = 0
        PollDelaySec (1,1) double = 0.1
        TimeoutSec   (1,1) double = 60
        Verbose      (1,1) logical = false

        % Angle range the turntable controller counts in. Measurement angles
        % are always entered and saved in (-180,180); this only changes what
        % is SENT to the turntable. "-180to180" sends the angle as-is (never
        % wraps through a cable stop at 180); "0to360" sends mod(theta,360).
        ThetaRange   (1,1) string {mustBeMember(ThetaRange, ["-180to180", "0to360"])} = "-180to180"

        % Axis-scoped query used to read current position (degrees).
        % "CP?" is the EMControl default; override here if your card uses a
        % different mnemonic (no code edit needed). See rawPosition() to
        % discover what your controller actually answers.
        PositionQuery (1,1) string = "CP?"

        % How close (deg) an axis must report itself to the commanded angle
        % before waitUntilStill treats it as arrived. Inf skips the check.
        PositionToleranceDeg (1,1) double {mustBePositive} = 1

        % Seconds an axis must sit still away from its target before it is
        % treated as stuck (move re-sent once, then an error).
        StallSec (1,1) double {mustBePositive} = 3

        % Axis-scoped query reporting whether an axis is moving ("DIR?"
        % answers +1/-1 or CW/CCW while moving, 0 or N when stopped). Set to
        % "" to skip this check.
        DirectionQuery (1,1) string = "DIR?"
    end

    properties (SetAccess = private)
        LastThetaDeg double = NaN   % last commanded angles (debug/app logic)
        LastPhiDeg   double = NaN
    end

    properties (Access = private)
        LastThetaCmd_ double = NaN  % last angle actually SENT to each axis
        LastPhiCmd_   double = NaN
    end

    methods
        function obj = AntennaPositioner(emcenter, tableAxis, towerAxis, opts)
            % ANTENNAPOSITIONER  Construct a positioner wrapper.
            %
            % INPUT:
            %   emcenter  - SCPIInstrument-compatible EMCenter object
            %   tableAxis - turntable axis ID (default "1A")
            %   towerAxis - tower axis ID (default "1B")
            %
            % Name-Value:
            %   HomeThetaDeg, HomePhiDeg, PollDelaySec, TimeoutSec, Verbose
            arguments
                emcenter
                tableAxis (1,1) string = "1A"
                towerAxis (1,1) string = "1B"
                opts.HomeThetaDeg (1,1) double = 0
                opts.HomePhiDeg   (1,1) double = 0
                opts.PollDelaySec (1,1) double {mustBePositive} = 0.1
                opts.TimeoutSec   (1,1) double {mustBePositive} = 60
                opts.Verbose      (1,1) logical = false
            end

            obj.EMCenter     = emcenter;
            obj.TableAxis    = tableAxis;
            obj.TowerAxis    = towerAxis;
            obj.HomeThetaDeg = opts.HomeThetaDeg;
            obj.HomePhiDeg   = opts.HomePhiDeg;
            obj.PollDelaySec = opts.PollDelaySec;
            obj.TimeoutSec   = opts.TimeoutSec;
            obj.Verbose      = opts.Verbose;
        end

        %% Speed configuration
        function setSpeeds(obj, tableSpeed, towerSpeed)
            % SETSPEEDS  Set turntable and tower speed presets.
            obj.writeAxis_(obj.TableAxis, sprintf("SPEED %d", tableSpeed));
            obj.writeAxis_(obj.TowerAxis, sprintf("SPEED %d", towerSpeed));
        end

        function setTableSpeed(obj, speed)
            % SETTABLESPEED  Set only the turntable speed preset.
            obj.writeAxis_(obj.TableAxis, sprintf("SPEED %d", speed));
        end

        function setTowerSpeed(obj, speed)
            % SETTOWERSPEED  Set only the tower speed preset.
            obj.writeAxis_(obj.TowerAxis, sprintf("SPEED %d", speed));
        end

        %% Motion
        function moveTheta(obj, thetaDeg)
            % MOVETHETA  Seek the turntable to an absolute angle (deg),
            % converted to the controller's ThetaRange.
            cmd = round(AntennaPositioner.thetaCommandAngle(thetaDeg, obj.ThetaRange));
            obj.writeAxis_(obj.TableAxis, sprintf("SK %d", cmd));
            obj.LastThetaDeg = thetaDeg;
            obj.LastThetaCmd_ = cmd;
        end

        function movePhi(obj, phiDeg)
            % MOVEPHI  Seek the tower to an absolute angle (deg).
            cmd = round(phiDeg);
            obj.writeAxis_(obj.TowerAxis, sprintf("SK %d", cmd));
            obj.LastPhiDeg = phiDeg;
            obj.LastPhiCmd_ = cmd;
        end

        function moveTo(obj, thetaDeg, phiDeg)
            % MOVETO  Command both axes (does not block; pair with
            % waitUntilStill).
            obj.moveTheta(thetaDeg);
            obj.movePhi(phiDeg);
        end

        %% Readback
        function thetaDeg = getTheta(obj)
            % GETTHETA  Current turntable angle (deg), in the measurement
            % (-180,180] range whatever ThetaRange the controller counts in.
            thetaDeg = AntennaPositioner.parseLeadingNumber_( ...
                obj.queryAxis_(obj.TableAxis, obj.PositionQuery));
            thetaDeg = AntennaPositioner.thetaMeasurementAngle(thetaDeg, obj.ThetaRange);
        end

        function phiDeg = getPhi(obj)
            % GETPHI  Current tower angle (deg).
            phiDeg = AntennaPositioner.parseLeadingNumber_( ...
                obj.queryAxis_(obj.TowerAxis, obj.PositionQuery));
        end

        function raw = rawPosition(obj, which)
            % RAWPOSITION  Return the un-parsed device reply to the position
            % query for one axis. Diagnostic aid for when getTheta/getPhi
            % return NaN — shows exactly what the controller sent back.
            %
            %   which - "table"/"theta" (default) or "tower"/"phi"
            if nargin < 2, which = "table"; end
            if any(lower(string(which)) == ["tower","phi"])
                raw = obj.queryAxis_(obj.TowerAxis, obj.PositionQuery);
            else
                raw = obj.queryAxis_(obj.TableAxis, obj.PositionQuery);
            end
        end

        %% Synchronization
        function canceled = waitUntilStill(obj, opts)
            % WAITUNTILSTILL  Block until both axes have arrived and stopped.
            %
            % An axis has arrived when *OPC? = 1, DIR? reports it stopped, and
            % CP? is within PositionToleranceDeg of the last commanded angle,
            % on two polls in a row. A DIR?/CP? reply that cannot be parsed is
            % skipped rather than waited on. If an axis stops short of its
            % target, the move is re-sent once; if it stops short again, this
            % errors (AntennaPositioner:OffTarget) instead of letting a
            % measurement run at the wrong angle.
            %
            % Name-Value:
            %   TimeoutSec - overrides obj.TimeoutSec for this wait
            %   CancelFcn  - function handle returning true to abort; when it
            %                fires, both axes are stopped and the method
            %                returns canceled = true. Wire this to the ARES
            %                progress dialog: @() d.CancelRequested
            %
            % OUTPUT:
            %   canceled - true if CancelFcn aborted the wait
            %
            % Throws AntennaPositioner:Timeout if neither completion nor
            % cancellation occurs within the timeout.
            arguments
                obj
                opts.TimeoutSec (1,1) double {mustBePositive} = obj.TimeoutSec
                opts.CancelFcn = []
                opts.OnPoll    = []
            end

            canceled = false;
            t0 = tic;
            settledPolls = 0;   % consecutive polls with both axes arrived
            resent = false;     % one re-send allowed for an axis that stops short
            % Per-axis stall tracking: last position seen and when it last
            % changed. An axis is stuck only if it is off target AND its
            % position has not moved for StallSec (so the moment before motion
            % starts, or a controller without DIR?, is not mistaken for it).
            lastA = NaN;  changedA = tic;
            lastB = NaN;  changedB = tic;
            while true
                % Per-iteration hook (UI-agnostic). The antenna app passes
                % @() drawnow here so the progress dialog stays responsive and
                % its Cancel button can fire during a blocking wait.
                if ~isempty(opts.OnPoll)
                    opts.OnPoll();
                end

                % Cancellation check first so a stuck axis can't mask it.
                if ~isempty(opts.CancelFcn) && opts.CancelFcn()
                    obj.stopAll();
                    canceled = true;
                    return;
                end

                [doneA, stoppedA, offA, posA] = obj.axisState_(obj.TableAxis, obj.LastThetaCmd_);
                [doneB, stoppedB, offB, posB] = obj.axisState_(obj.TowerAxis, obj.LastPhiCmd_);
                if ~isequaln(posA, lastA), lastA = posA; changedA = tic; end
                if ~isequaln(posB, lastB), lastB = posB; changedB = tic; end

                if doneA && doneB
                    settledPolls = settledPolls + 1;
                    if settledPolls >= 2
                        return;
                    end
                else
                    settledPolls = 0;
                end

                % Stopped away from the target and not moving any more: the
                % move was dropped or cut short. Re-send once, then give up
                % loudly rather than measure at the wrong angle.
                stuckA = stoppedA && offA && toc(changedA) > obj.StallSec;
                stuckB = stoppedB && offB && toc(changedB) > obj.StallSec;
                if stuckA || stuckB
                    if resent
                        error("AntennaPositioner:OffTarget", ...
                            "Positioner stopped away from its target: table at %g (sent %g), " + ...
                            "tower at %g (sent %g).", posA, obj.LastThetaCmd_, posB, obj.LastPhiCmd_);
                    end
                    if stuckA
                        obj.writeAxis_(obj.TableAxis, sprintf("SK %d", obj.LastThetaCmd_));
                        changedA = tic;
                    end
                    if stuckB
                        obj.writeAxis_(obj.TowerAxis, sprintf("SK %d", obj.LastPhiCmd_));
                        changedB = tic;
                    end
                    resent = true;
                    settledPolls = 0;
                end

                if toc(t0) > opts.TimeoutSec
                    error("AntennaPositioner:Timeout", ...
                        "Timed out waiting for positioner motion (%.1f s): table at %g (sent %g), " + ...
                        "tower at %g (sent %g).", opts.TimeoutSec, ...
                        posA, obj.LastThetaCmd_, posB, obj.LastPhiCmd_);
                end

                if obj.Verbose
                    fprintf("Waiting... table %g -> %g, tower %g -> %g\n", ...
                        posA, obj.LastThetaCmd_, posB, obj.LastPhiCmd_);
                end
                pause(obj.PollDelaySec);
            end
        end

        %% Safety
        function stopAll(obj)
            % STOPALL  Stop motion on both axes immediately.
            obj.writeAxis_(obj.TableAxis, "ST");
            obj.writeAxis_(obj.TowerAxis, "ST");
        end

        function home(obj)
            % HOME  Command both axes to their configured home angles.
            obj.moveTo(obj.HomeThetaDeg, obj.HomePhiDeg);
        end
    end

    methods (Static)
        function cmd = thetaCommandAngle(thetaDeg, thetaRange)
            % THETACOMMANDANGLE  Measurement angle(s) -> angle(s) sent to the
            % turntable for the given ThetaRange ("-180to180" | "0to360").
            % Works on vectors, so the run loops can sort positions by the
            % angle the turntable actually travels to.
            cmd = double(thetaDeg);
            if string(thetaRange) == "0to360"
                out = cmd < 0 | cmd > 360;
                cmd(out) = mod(cmd(out), 360);
            else
                out = cmd < -180 | cmd > 180;
                cmd(out) = mod(cmd(out) + 180, 360) - 180;
            end
        end

        function thetaDeg = thetaMeasurementAngle(cmdDeg, thetaRange)
            % THETAMEASUREMENTANGLE  Inverse of thetaCommandAngle: an angle in
            % the controller's range back into the (-180,180] measurement range.
            thetaDeg = double(cmdDeg);
            if string(thetaRange) == "0to360"
                hi = thetaDeg > 180;
                thetaDeg(hi) = thetaDeg(hi) - 360;
            end
        end
    end

    methods (Access = private)
        function [arrived, stopped, offTarget, pos] = axisState_(obj, axis, target)
            % One poll of an axis. arrived = *OPC? done, not moving, and at
            % the target. stopped = *OPC? done and not moving. offTarget =
            % position known and further than the tolerance from target.
            % Unparseable DIR?/CP? replies (or no commanded target yet) are
            % treated as "no information", never as a reason to wait forever.
            opc = str2double(obj.queryAxis_(axis, "*OPC?"));

            moving = false;
            if strlength(obj.DirectionQuery) > 0
                moving = AntennaPositioner.isMovingReply_(obj.queryAxis_(axis, obj.DirectionQuery));
            end

            pos = NaN;
            offTarget = false;
            if isfinite(obj.PositionToleranceDeg) && isfinite(target)
                pos = AntennaPositioner.parseLeadingNumber_(obj.queryAxis_(axis, obj.PositionQuery));
                if isfinite(pos)
                    err = abs(mod(pos - target + 180, 360) - 180);   % wrap-aware
                    offTarget = err > obj.PositionToleranceDeg;
                end
            end

            stopped = (opc == 1) && ~moving;
            arrived = stopped && ~offTarget;
        end

        function writeAxis_(obj, axis, cmd)
            obj.EMCenter.scpi(sprintf("%s:%s", axis, cmd));
        end

        function out = queryAxis_(obj, axis, cmd)
            out = obj.EMCenter.scpi(sprintf("%s:%s", axis, cmd));
        end
    end

    methods (Static, Access = private)
        function tf = isMovingReply_(s)
            % DIR? reply -> moving? Numeric +1/-1 (or any non-zero) or
            % CW/CCW/UP/DOWN mean moving; 0, N, NONE, STOP, or anything
            % unrecognized mean not moving (so an odd reply never blocks).
            s = upper(strtrim(string(s)));
            d = str2double(s);
            if ~isnan(d)
                tf = (d ~= 0);
            else
                tf = any(s == ["CW", "CCW", "UP", "DN", "DOWN", "+", "-"]);
            end
        end

        function v = parseLeadingNumber_(s)
            % Extract the first signed/decimal/exponent number from a device
            % reply. Tolerates leading +, sign, units, or an echoed command
            % (e.g. "1A:CP +045.0 DEG" -> 45). Returns NaN if none found.
            tok = regexp(string(s), '[-+]?\d*\.?\d+([eE][-+]?\d+)?', ...
                         'match', 'once');
            if strlength(tok) == 0
                v = NaN;
            else
                v = str2double(tok);
            end
        end
    end
end
