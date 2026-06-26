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
    % Adapted from paper's prototype with two integration changes:
    %
    %   1. CANCEL SUPPORT. waitUntilStill accepts a CancelFcn. ARES lets the
    %      operator stop a sweep from the progress dialog
    %      (d.CancelRequested in runAntennaMeasurement.m); the wait loop
    %      polls that function and stops both axes if it returns true.
    %
    %   2. SIMPLIFIED CONSTRUCTOR. An arguments block replaces the
    %      positional/name-value juggling in the prototype.
    %
    % The underlying EMCenter object must expose scpi() — i.e. be a
    % SCPIInstrument (or subclass). Because SCPIInstrument is
    % transport-backed, this positioner is automatically simulatable.
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

        % Axis-scoped query used to read current position (degrees).
        % "CP?" is the EMControl default; override here if your card uses a
        % different mnemonic (no code edit needed). See rawPosition() to
        % discover what your controller actually answers.
        PositionQuery (1,1) string = "CP?"
    end

    properties (SetAccess = private)
        LastThetaDeg double = NaN   % last commanded angles (debug/app logic)
        LastPhiDeg   double = NaN
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
            % MOVETHETA  Seek the turntable to an absolute angle (deg).
            obj.writeAxis_(obj.TableAxis, sprintf("SK %d", round(thetaDeg)));
            obj.LastThetaDeg = thetaDeg;
        end

        function movePhi(obj, phiDeg)
            % MOVEPHI  Seek the tower to an absolute angle (deg).
            obj.writeAxis_(obj.TowerAxis, sprintf("SK %d", round(phiDeg)));
            obj.LastPhiDeg = phiDeg;
        end

        function moveTo(obj, thetaDeg, phiDeg)
            % MOVETO  Command both axes (does not block; pair with
            % waitUntilStill).
            obj.moveTheta(thetaDeg);
            obj.movePhi(phiDeg);
        end

        %% Readback
        function thetaDeg = getTheta(obj)
            % GETTHETA  Current turntable angle (deg).
            thetaDeg = AntennaPositioner.parseLeadingNumber_( ...
                obj.queryAxis_(obj.TableAxis, obj.PositionQuery));
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
            % WAITUNTILSTILL  Block until both axes report motion complete.
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

                statusA = str2double(obj.queryAxis_(obj.TableAxis, "*OPC?"));
                statusB = str2double(obj.queryAxis_(obj.TowerAxis, "*OPC?"));
                if (statusA == 1) && (statusB == 1)
                    return;
                end

                if toc(t0) > opts.TimeoutSec
                    error("AntennaPositioner:Timeout", ...
                        "Timed out waiting for positioner motion (%.1f s).", ...
                        opts.TimeoutSec);
                end

                if obj.Verbose
                    fprintf("Waiting... OPC table=%g, tower=%g\n", statusA, statusB);
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

    methods (Access = private)
        function writeAxis_(obj, axis, cmd)
            obj.EMCenter.scpi(sprintf("%s:%s", axis, cmd));
        end

        function out = queryAxis_(obj, axis, cmd)
            out = obj.EMCenter.scpi(sprintf("%s:%s", axis, cmd));
        end
    end

    methods (Static, Access = private)
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
