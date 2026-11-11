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
    %   - The EMCenter answers every action command (SK, SPEED, ST) with a
    %     line of its own: "OK", or "ERROR n" if it refused. Those lines have
    %     to be read. Left unread they sit in front of the next query's
    %     answer, so *OPC? is handed the "OK" from a seek, CP? is handed the
    %     answer to *OPC?, and so on. (That froze the 2026-11 chamber run at
    %     its first position: the three checks could never agree. With only
    %     *OPC? polled, the same stale answers can end a wait early.) This
    %     class keeps replies in step with commands: after sending them it
    %     sends SyncQuery (*IDN?) and reads up to that reply, which clears
    %     whatever is queued no matter who sent it; a refused command is
    %     reported; and a reply that cannot belong to its query causes one
    %     resync before anything is concluded from it.
    %   - A move the operator starts by hand (the app's Move to Angle
    %     buttons) uses waitForAxis instead: one axis, no re-send, and
    %     stopping short is not an error, so the Stop button (stopTable /
    %     stopTower) ends the wait instead of fighting it.
    %   - AntennaPositioner.trace(true) prints every command and reply, to
    %     check the conversation with the controller in the chamber.
    %   - The underlying EMCenter object must expose write() and read(),
    %     meaning it is a SCPIInstrument or a subclass. Because
    %     SCPIInstrument is transport-backed, this positioner is simulatable
    %     without changes.
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

        % Query used to line replies back up with commands (see NOTES). Its
        % reply must be text that no other reply can be mistaken for: not
        % "OK", not "ERROR n", not a number. *IDN? is.
        SyncQuery (1,1) string {mustBeNonzeroLengthText} = "*IDN?"
    end

    properties (SetAccess = private)
        LastThetaDeg double = NaN   % last commanded angles (debug/app logic)
        LastPhiDeg   double = NaN
    end

    properties (Access = private)
        LastThetaCmd_ double = NaN  % last angle actually SENT to each axis
        LastPhiCmd_   double = NaN

        % Reply bookkeeping (see settle_).
        Unsettled_ (:,1) string = strings(0, 1)  % commands sent, answers not read yet
        Backlog_   (:,1) string = strings(0, 1)  % lines read off the link, not handed out yet
        Odd_       (:,1) string = strings(0, 1)  % queries this controller never answers usably
        TableRefusal_ (1,1) string = ""          % how the controller refused the last seek, if it did
        TowerRefusal_ (1,1) string = ""
        LastRaw_ = struct('table', "none yet", 'tower', "none yet")  % last poll's raw replies
    end

    properties (Constant, Access = private)
        MaxSyncLines = 2000   % stop clearing the link after this many stale lines
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
            % SETSPEEDS  Set turntable and tower speed (percent of maximum).
            obj.send_(obj.TableAxis, AntennaPositioner.speedCommand_(tableSpeed));
            obj.send_(obj.TowerAxis, AntennaPositioner.speedCommand_(towerSpeed));
            obj.settle_();
        end

        function setTableSpeed(obj, speed)
            % SETTABLESPEED  Set only the turntable speed.
            obj.send_(obj.TableAxis, AntennaPositioner.speedCommand_(speed));
            obj.settle_();
        end

        function setTowerSpeed(obj, speed)
            % SETTOWERSPEED  Set only the tower speed.
            obj.send_(obj.TowerAxis, AntennaPositioner.speedCommand_(speed));
            obj.settle_();
        end

        %% Motion
        function moveTheta(obj, thetaDeg)
            % MOVETHETA  Seek the turntable to an absolute angle (deg),
            % converted to the controller's ThetaRange.
            obj.sendTheta_(thetaDeg);
            obj.settle_();
        end

        function movePhi(obj, phiDeg)
            % MOVEPHI  Seek the tower to an absolute angle (deg).
            obj.sendPhi_(phiDeg);
            obj.settle_();
        end

        function moveTo(obj, thetaDeg, phiDeg)
            % MOVETO  Command both axes (does not block; pair with
            % waitUntilStill). Both seeks go out back to back so the axes
            % start together; the controller's answers are read afterwards.
            obj.sendTheta_(thetaDeg);
            obj.sendPhi_(phiDeg);
            obj.settle_();
        end

        %% Readback
        function thetaDeg = getTheta(obj)
            % GETTHETA  Current turntable angle (deg), in the measurement
            % (-180,180] range whatever ThetaRange the controller counts in.
            obj.settle_();
            thetaDeg = AntennaPositioner.replyNumber_(obj.ask_(obj.TableAxis, ...
                obj.PositionQuery, @(s) AntennaPositioner.isNumberReply_(s)));
            thetaDeg = AntennaPositioner.thetaMeasurementAngle(thetaDeg, obj.ThetaRange);
        end

        function phiDeg = getPhi(obj)
            % GETPHI  Current tower angle (deg).
            obj.settle_();
            phiDeg = AntennaPositioner.replyNumber_(obj.ask_(obj.TowerAxis, ...
                obj.PositionQuery, @(s) AntennaPositioner.isNumberReply_(s)));
        end

        function raw = rawPosition(obj, which)
            % RAWPOSITION  Return the un-parsed device reply to the position
            % query for one axis. Diagnostic aid for when getTheta/getPhi
            % return NaN: shows exactly what the controller sent back.
            %
            %   which - "table"/"theta" (default) or "tower"/"phi"
            if nargin < 2, which = "table"; end
            axis = obj.TableAxis;
            if any(lower(string(which)) == ["tower","phi"])
                axis = obj.TowerAxis;
            end
            obj.settle_();
            raw = obj.exchange_(sprintf("%s:%s", axis, obj.PositionQuery));
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
            % The wait starts by clearing any replies still queued on the
            % link (see NOTES), so each answer it acts on belongs to the
            % query that asked for it.
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
            % cancellation occurs within the timeout, and
            % AntennaPositioner:NoReply if the controller stops answering.
            arguments
                obj
                opts.TimeoutSec (1,1) double {mustBePositive} = obj.TimeoutSec
                opts.CancelFcn = []
                opts.OnPoll    = []
            end

            % Start in step: read off anything still queued on the link,
            % including answers to commands other code sent (for example the
            % app's manual move buttons).
            obj.settle_();

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
                            "tower at %g (sent %g).%s", posA, obj.LastThetaCmd_, posB, ...
                            obj.LastPhiCmd_, obj.diagnosis_());
                    end
                    if stuckA
                        obj.TableRefusal_ = "";
                        obj.send_(obj.TableAxis, sprintf("SK %d", obj.LastThetaCmd_));
                        changedA = tic;
                    end
                    if stuckB
                        obj.TowerRefusal_ = "";
                        obj.send_(obj.TowerAxis, sprintf("SK %d", obj.LastPhiCmd_));
                        changedB = tic;
                    end
                    obj.settle_();
                    resent = true;
                    settledPolls = 0;
                end

                if toc(t0) > opts.TimeoutSec
                    error("AntennaPositioner:Timeout", ...
                        "Timed out waiting for positioner motion (%.1f s): table at %g (sent %g), " + ...
                        "tower at %g (sent %g).%s", opts.TimeoutSec, ...
                        posA, obj.LastThetaCmd_, posB, obj.LastPhiCmd_, obj.diagnosis_());
                end

                if obj.Verbose
                    fprintf("Waiting... table %g -> %g, tower %g -> %g\n", ...
                        posA, obj.LastThetaCmd_, posB, obj.LastPhiCmd_);
                end
                pause(obj.PollDelaySec);
            end
        end

        function arrived = waitForAxis(obj, which, opts)
            % WAITFORAXIS  Block until one axis has stopped, wherever it
            % stopped. This is the wait for a move the operator starts by
            % hand (the app's Move to Angle buttons).
            %
            % Unlike waitUntilStill it watches one axis, never re-sends the
            % move, and does not treat stopping short as an error: the
            % operator may have pressed Stop, and that has to end the wait,
            % not restart the motion.
            %
            %   which - "table"/"theta" or "tower"/"phi"
            %
            % Name-Value:
            %   TimeoutSec - overrides obj.TimeoutSec for this wait
            %   OnPoll     - called once per poll. Pass @() drawnow so the
            %                app stays responsive and its Stop button works.
            %
            % OUTPUT:
            %   arrived - true if the axis stopped at the last angle sent to
            %             it. false if it stopped somewhere else, or had not
            %             started moving after StallSec.
            %
            % Throws AntennaPositioner:Timeout if the axis is still moving
            % after the timeout.
            arguments
                obj
                which (1,1) string = "table"
                opts.TimeoutSec (1,1) double {mustBePositive} = obj.TimeoutSec
                opts.OnPoll = []
            end
            [axis, target] = obj.axisFor_(which);

            obj.settle_();   % start in step (see waitUntilStill)

            arrived = false;
            t0 = tic;
            stoppedPolls = 0;    % consecutive polls with the axis stopped
            sawMotion = false;   % the axis has been seen moving during this wait
            firstPos = NaN;
            while true
                if ~isempty(opts.OnPoll)
                    opts.OnPoll();
                end

                [onTarget, stopped, ~, pos, inMotion] = obj.axisState_(axis, target);
                if isnan(firstPos), firstPos = pos; end
                if inMotion || (isfinite(pos) && isfinite(firstPos) && pos ~= firstPos)
                    sawMotion = true;
                end

                if stopped
                    stoppedPolls = stoppedPolls + 1;
                else
                    stoppedPolls = 0;
                end

                if stoppedPolls >= 2
                    if onTarget
                        arrived = true;
                        return;
                    end
                    % Stopped somewhere else. If it had been moving, something
                    % stopped it (the Stop button, a travel limit): done. If
                    % it has not moved at all, give it StallSec to start.
                    if sawMotion || toc(t0) > obj.StallSec
                        return;
                    end
                end

                if toc(t0) > opts.TimeoutSec
                    error("AntennaPositioner:Timeout", ...
                        "Timed out waiting for the %s to stop (%.1f s): at %g (sent %g).%s", ...
                        which, opts.TimeoutSec, pos, target, obj.diagnosis_());
                end
                pause(obj.PollDelaySec);
            end
        end

        function why = lastRefusal(obj, which)
            % LASTREFUSAL  How the controller refused the last seek sent to
            % an axis, for example '"ERROR 2" to "1A:SK 400"'. Empty ("") if
            % it accepted the seek.
            %
            %   which - "table"/"theta" (default) or "tower"/"phi"
            if nargin < 2, which = "table"; end
            if obj.axisFor_(which) == obj.TableAxis
                why = obj.TableRefusal_;
            else
                why = obj.TowerRefusal_;
            end
        end

        %% Safety
        function stopAll(obj)
            % STOPALL  Stop motion on both axes immediately. Both stops are
            % sent before anything is read back, so nothing can hold up the
            % second one.
            obj.send_(obj.TableAxis, "ST");
            obj.send_(obj.TowerAxis, "ST");
            try
                obj.settle_();
            catch
                % The stops are already sent. A controller that will not
                % answer is reported by the next command that needs it.
            end
        end

        function stopTable(obj)
            % STOPTABLE  Stop the turntable only.
            obj.send_(obj.TableAxis, "ST");
            obj.settle_();
        end

        function stopTower(obj)
            % STOPTOWER  Stop the tower only.
            obj.send_(obj.TowerAxis, "ST");
            obj.settle_();
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

        function was = trace(tf)
            % TRACE  Print every command sent to the controller and every
            % reply read back, for all positioner objects this session.
            %
            %   AntennaPositioner.trace(true)    % on
            %   AntennaPositioner.trace(false)   % off
            %   tf = AntennaPositioner.trace()   % current setting
            %
            % Lines look like "[positioner] > 1A:SK 90" (sent) and
            % "[positioner] < OK" (read). Use it in the chamber to see what
            % the controller actually answers.
            persistent ON
            if isempty(ON), ON = false; end
            was = ON;
            if nargin > 0, ON = logical(tf); end
        end
    end

    methods (Access = private)
        function [arrived, stopped, offTarget, pos, inMotion] = axisState_(obj, axis, target)
            % One poll of an axis. arrived = *OPC? done, not moving, and at
            % the target. stopped = *OPC? done and not moving. offTarget =
            % position known and further than the tolerance from target.
            % inMotion = the controller says so (*OPC? = 0, or DIR? moving).
            % Unparseable DIR?/CP? replies (or no commanded target yet) are
            % treated as "no information", never as a reason to wait forever.
            opcRaw = obj.ask_(axis, "*OPC?", @(s) AntennaPositioner.isOpcReply_(s));
            opc = AntennaPositioner.replyNumber_(opcRaw);

            moving = false;
            dirRaw = "";
            if strlength(obj.DirectionQuery) > 0
                dirRaw = obj.ask_(axis, obj.DirectionQuery, @(s) AntennaPositioner.isDirReply_(s));
                moving = AntennaPositioner.isMovingReply_(dirRaw);
            end

            pos = NaN;
            posRaw = "";
            offTarget = false;
            if isfinite(obj.PositionToleranceDeg) && isfinite(target)
                posRaw = obj.ask_(axis, obj.PositionQuery, @(s) AntennaPositioner.isNumberReply_(s));
                pos = AntennaPositioner.replyNumber_(posRaw);
                if isfinite(pos)
                    err = abs(mod(pos - target + 180, 360) - 180);   % wrap-aware
                    offTarget = err > obj.PositionToleranceDeg;
                end
            end

            stopped = (opc == 1) && ~moving;
            arrived = stopped && ~offTarget;
            inMotion = (opc == 0) || moving;

            % Keep what the controller said, word for word, for error text.
            raw = sprintf('*OPC? "%s", %s "%s", %s "%s"', opcRaw, ...
                obj.DirectionQuery, dirRaw, obj.PositionQuery, posRaw);
            if axis == obj.TableAxis
                obj.LastRaw_.table = raw;
            else
                obj.LastRaw_.tower = raw;
            end
        end

        %% Commands and replies, kept in step
        % Every line the controller sends is the answer to one command, in
        % the order the commands arrived. The methods below make sure each
        % answer is read by the command that caused it:
        %   send_     action command; its "OK"/"ERROR n" answer is owed
        %   settle_   reads everything owed (and anything stale) off the link
        %   ask_      query; one reply, checked against what the query can say
        function [axis, target] = axisFor_(obj, which)
            % "table"/"theta" or "tower"/"phi" -> axis ID and the last angle
            % sent to that axis.
            switch lower(string(which))
                case {"table", "theta"}
                    axis = obj.TableAxis;
                    target = obj.LastThetaCmd_;
                case {"tower", "phi"}
                    axis = obj.TowerAxis;
                    target = obj.LastPhiCmd_;
                otherwise
                    error("AntennaPositioner:BadAxis", ...
                        'Axis must be "table" or "tower", not "%s".', which);
            end
        end

        function sendTheta_(obj, thetaDeg)
            cmd = round(AntennaPositioner.thetaCommandAngle(thetaDeg, obj.ThetaRange));
            obj.TableRefusal_ = "";
            obj.send_(obj.TableAxis, sprintf("SK %d", cmd));
            obj.LastThetaDeg = thetaDeg;
            obj.LastThetaCmd_ = cmd;
        end

        function sendPhi_(obj, phiDeg)
            cmd = round(phiDeg);
            obj.TowerRefusal_ = "";
            obj.send_(obj.TowerAxis, sprintf("SK %d", cmd));
            obj.LastPhiDeg = phiDeg;
            obj.LastPhiCmd_ = cmd;
        end

        function send_(obj, axis, cmd)
            % Send an action command (SK, SPEED, ST) without waiting. The
            % controller answers each with "OK" or "ERROR n"; that answer is
            % remembered as owed and read by the next settle_().
            full = string(sprintf("%s:%s", axis, cmd));
            obj.EMCenter.write(full);
            obj.log_(">", full);
            obj.Unsettled_(end+1, 1) = full;
        end

        function settle_(obj)
            % Read off everything the controller has queued, so the next
            % reply read is the answer to the next query sent.
            %
            % It sends SyncQuery and reads lines until that query's answer
            % turns up. Whatever came before it was queued earlier: the
            % "OK"/"ERROR n" answers to the commands sent since the last
            % settle (the newest lines), and anything other code left unread.
            % This needs no knowledge of which commands the controller
            % answers, and nothing waits on a line that is not coming.
            sent = obj.Unsettled_;
            obj.Unsettled_ = strings(0, 1);

            [queued, found] = obj.readToSync_();
            if ~found
                % One more try before giving up (a slow answer to the first
                % sync is read here as a stale line).
                [more, found] = obj.readToSync_();
                queued = [queued; more];
            end
            if ~found
                error("AntennaPositioner:NoReply", ...
                    "The positioner controller did not answer %s, so its replies cannot be " + ...
                    "matched to the commands sent. Check the EMCenter connection. " + ...
                    "(Read while waiting: %s)", obj.SyncQuery, AntennaPositioner.quoteList_(queued));
            end

            % The answers to our own commands are the newest lines.
            n = min(numel(sent), numel(queued));
            for k = 1:n
                answer = queued(end - n + k);
                if AntennaPositioner.isErrorReply_(answer)
                    obj.refused_(sent(end - n + k), answer);
                end
            end
        end

        function [queued, found] = readToSync_(obj)
            % Send SyncQuery and read until its answer. queued = the lines
            % that were ahead of it. found = false if the answer never came
            % (the read timed out, or MaxSyncLines other lines arrived).
            queued = strings(0, 1);
            found = false;
            obj.EMCenter.write(obj.SyncQuery);
            obj.log_(">", obj.SyncQuery);
            for k = 1:obj.MaxSyncLines
                try
                    line = obj.nextLine_();
                catch
                    line = "";
                end
                obj.log_("<", line);
                if strlength(line) == 0
                    return;   % nothing more is coming
                end
                if AntennaPositioner.isSyncReply_(line)
                    found = true;
                    return;
                end
                queued(end+1, 1) = line; %#ok<AGROW>
            end
        end

        function reply = ask_(obj, axis, cmd, isValid)
            % Send a query and return its reply. isValid(reply) says whether
            % the reply is something this query can answer. If it is not (an
            % unread "OK", someone else's answer, nothing at all), the link
            % is out of step: clear it and ask once more. A query the
            % controller never answers usably is remembered, so it is not
            % resynced over on every poll.
            full = string(sprintf("%s:%s", axis, cmd));
            if ~isempty(obj.Unsettled_)
                obj.settle_();
            end

            reply = obj.exchange_(full);
            if isValid(reply)
                obj.Odd_(obj.Odd_ == full) = [];
                return;
            end
            if any(obj.Odd_ == full)
                return;
            end

            obj.settle_();
            reply = obj.exchange_(full);
            if ~isValid(reply)
                obj.Odd_(end+1, 1) = full;
            end
        end

        function reply = exchange_(obj, full)
            % One query out, one reply line back ("" if nothing came).
            obj.EMCenter.write(full);
            obj.log_(">", full);
            try
                reply = obj.nextLine_();
            catch
                reply = "";
            end
            obj.log_("<", reply);
        end

        function line = nextLine_(obj)
            % Next reply line from the controller. A read normally carries
            % one reply, but replies end in a carriage return and one read
            % can deliver several, so split them and hand out one at a time.
            if isempty(obj.Backlog_)
                raw = string(obj.EMCenter.read());
                parts = strings(0, 1);
                for k = 1:numel(raw)
                    if ismissing(raw(k)), continue; end
                    parts = [parts; strip(split(raw(k), [string(char(13)), string(newline)]))]; %#ok<AGROW>
                end
                obj.Backlog_ = parts(strlength(parts) > 0);
            end
            if isempty(obj.Backlog_)
                line = "";
            else
                line = obj.Backlog_(1);
                obj.Backlog_(1) = [];
            end
        end

        function refused_(obj, cmd, answer)
            % The controller answered an action command with an error.
            note = string(sprintf('"%s" to "%s"', answer, cmd));
            if startsWith(cmd, obj.TableAxis + ":SK"), obj.TableRefusal_ = note; end
            if startsWith(cmd, obj.TowerAxis + ":SK"), obj.TowerRefusal_ = note; end
            warning("AntennaPositioner:CommandRefused", ...
                "The positioner controller answered %s.", note);
        end

        function note = diagnosis_(obj)
            % Text for wait errors: what the controller last said, so the
            % cause can be read from the error itself.
            note = string(sprintf(" Last replies: table %s; tower %s.", ...
                obj.LastRaw_.table, obj.LastRaw_.tower));
            for refusal = [obj.TableRefusal_, obj.TowerRefusal_]
                if strlength(refusal) > 0
                    note = note + sprintf(" The controller answered %s.", refusal);
                end
            end
        end

        function log_(obj, arrow, text)
            if obj.Verbose || AntennaPositioner.trace()
                fprintf("[positioner] %s %s\n", arrow, text);
            end
        end
    end

    methods (Static, Access = private)
        function cmd = speedCommand_(speed)
            % SPEED takes a percentage of maximum speed with at most one
            % decimal ("SPEED 54.3"). A slider value such as 63.7255 would
            % print as "6.372549e+01" with %d, which is not a valid command.
            cmd = string(sprintf("SPEED %g", round(double(speed), 1)));
        end

        function tf = isMovingReply_(s)
            % DIR? reply -> moving? Numeric +1/-1 (or any non-zero) or
            % CW/CCW/UP/DOWN mean moving; 0, N, NONE, STOP, or anything
            % unrecognized mean not moving (so an odd reply never blocks).
            d = AntennaPositioner.replyNumber_(s);
            if ~isnan(d)
                tf = (d ~= 0);
            else
                tf = any(upper(strtrim(string(s))) == ["CW", "CCW", "UP", "DN", "DOWN", "+", "-"]);
            end
        end

        function tf = isOpcReply_(s)
            % *OPC? answers 0 (in motion) or 1 (motion complete).
            v = AntennaPositioner.replyNumber_(s);
            tf = (v == 0) || (v == 1);
        end

        function tf = isDirReply_(s)
            % DIR? answers a number (+1, 0, -1) or a direction word.
            tf = ~isnan(AntennaPositioner.replyNumber_(s)) || ...
                any(upper(strtrim(string(s))) == ...
                    ["CW", "CCW", "UP", "DN", "DOWN", "+", "-", "N", "NONE", "STOP", "STOPPED"]);
        end

        function tf = isNumberReply_(s)
            tf = ~isnan(AntennaPositioner.replyNumber_(s));
        end

        function tf = isAckReply_(s)
            tf = strcmpi(strtrim(string(s)), "OK");
        end

        function tf = isErrorReply_(s)
            % "ERROR n" (the EMCenter's answer to a command it refuses).
            tf = startsWith(upper(strtrim(string(s))), "ERR");
        end

        function tf = isSyncReply_(s)
            % The answer to SyncQuery is the one line that is not "OK", not
            % an error, and not a status reply (a number or direction word).
            tf = strlength(strtrim(string(s))) > 0 ...
                && ~AntennaPositioner.isAckReply_(s) ...
                && ~AntennaPositioner.isErrorReply_(s) ...
                && ~AntennaPositioner.isDirReply_(s);
        end

        function v = replyNumber_(s)
            % The number a reply consists of, with an optional unit after it:
            % "1", "+1", "-90.0", "200.5 DEGREES". NaN for anything else
            % ("OK", "ERROR 2", an identification string), so a line that is
            % not the answer to a numeric query is never read as one.
            v = NaN;
            s = string(s);
            if ~isscalar(s) || ismissing(s)
                return;
            end
            tok = regexp(char(s), '^\s*([-+]?(?:\d+\.?\d*|\.\d+)(?:[eE][-+]?\d+)?)\s*[A-Za-z%]*\s*$', ...
                'tokens', 'once');
            if ~isempty(tok)
                v = str2double(tok{1});
            end
        end

        function txt = quoteList_(lines)
            if isempty(lines)
                txt = "nothing";
            else
                txt = join("""" + lines(max(1, end-9):end) + """", ", ");
            end
        end
    end
end
