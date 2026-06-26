classdef EmCenterSlider < handle
    %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
    % EmCenterSlider
    %
    % DESCRIPTION:
    % Driver for the ETS-Lindgren EMCenter linear slider axis controller
    % (raw TCP, default 192.168.0.100:1206). Manages a persistent connection
    % so the slider is connected once at app startup and reused for every
    % move — no reconnect churn per call.
    %
    % This is the paper's prototype folded onto the shared ITransport
    % seam and merged with the hardened standalone slider work already in
    % ARES (support/AntennaFunctions/setLinearSlider.m / homeLinearSlider.m):
    %
    %   - TRANSPORT-BACKED. I/O goes through TcpTransport, so the slider is
    %     simulatable by injecting a SimTransport ("Transport" name-value).
    %     Functionality on real hardware is unchanged: same commands, same
    %     line protocol, same socket.
    %   - MOVE TIMEOUT. Blocking moves abort with AXIS:STOP and a clear
    %     error after TimeoutSec (default 120 s — full-rail at slowest
    %     preset takes ~90 s). The prototype could poll forever.
    %   - FAULT CHECKING. home() checks AXIS:ERR? before and after the
    %     procedure; getError() translates fault codes to readable text.
    %   - HOME WAITS CORRECTLY. The wait loop polls *OPC? and sends nothing
    %     else (the legacy script's mid-home AXIS:ZERO corrupted state).
    %   - POSITION TOLERANCE. "Already at target" uses a 0.5 cm tolerance,
    %     not exact float equality.
    %   - FIXED CLEANUP. Disconnect releases the socket via the transport
    %     (the prototype's `clear obj.Client` was a no-op leak).
    %
    % COORDINATE FRAMES:
    %   Device:   centimeters along the rail, as reported by AXIS:CP?.
    %   Physical: meters in the chamber frame,
    %             physical_m = DirectionSign*(device_cm/100) + Offset_m
    %   Offset_m defaults to 0.8062 m (Purdue chamber geometry, formerly
    %   hard-coded in ARES.mlapp).
    %
    % TYPICAL USAGE:
    %   s = EmCenterSlider("192.168.0.100", 1206, 1);
    %   s.setSpeedPreset(4);
    %   s.moveTo(120);                      % device cm, blocks until done
    %   p = s.getPhysicalPosition_m();
    %   s.disconnect();
    %
    % SIMULATION:
    %   t = SimTransport();
    %   t.setResponse("AXIS1:LL?", "0");
    %   t.setResponse("AXIS1:UL?", "200");
    %   s = EmCenterSlider("sim", 0, 1, "Transport", t);
    %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

    properties (SetAccess = private)
        Host   (1,1) string = "192.168.0.100"
        Port   (1,1) double = 1206
        AxisId (1,1) double = 1

        % Mechanical travel limits (cm), queried once at connect.
        LowerLimit_cm (1,1) double = NaN
        UpperLimit_cm (1,1) double = NaN
    end

    properties
        % Physical-frame offset (m). Default matches the ARES chamber.
        Offset_m (1,1) double = 0.8062

        % +1 if physical position increases with device position, else -1.
        DirectionSign (1,1) double = 1

        % Poll period during blocking moves (s).
        PollPeriod_s (1,1) double = 0.25

        % Blocking-move / homing timeout (s).
        TimeoutSec (1,1) double = 120

        % Positions within this tolerance (cm) count as "already there".
        PositionTolerance_cm (1,1) double = 0.5

        % Print live position during moves (bring-up aid).
        Verbose (1,1) logical = false
    end

    properties (SetAccess = private)
        Transport = []   % ITransport (TcpTransport on hardware)
    end

    methods
        function obj = EmCenterSlider(host, port, axisId, opts)
            % EMCENTERSLIDER  Construct, connect, and cache limits.
            %
            % INPUT:
            %   host   - controller IP (default "192.168.0.100")
            %   port   - TCP port (default 1206)
            %   axisId - axis index (default 1)
            %
            % Name-Value:
            %   Offset_m, DirectionSign, PollPeriod_s, TimeoutSec,
            %   PositionTolerance_cm, Verbose
            %   Transport - inject a pre-built ITransport (e.g. SimTransport
            %               for hardware-free testing)
            arguments
                host   (1,1) string = "192.168.0.100"
                port   (1,1) double = 1206
                axisId (1,1) double = 1
                opts.Offset_m      (1,1) double {mustBeFinite} = 0.8062
                opts.DirectionSign (1,1) double {mustBeMember(opts.DirectionSign, [-1 1])} = 1
                opts.PollPeriod_s  (1,1) double {mustBePositive} = 0.25
                opts.TimeoutSec    (1,1) double {mustBePositive} = 120
                opts.PositionTolerance_cm (1,1) double {mustBeNonnegative} = 0.5
                opts.Verbose       (1,1) logical = false
                opts.Transport = []
            end

            obj.Host   = host;
            obj.Port   = port;
            obj.AxisId = axisId;
            obj.Offset_m             = opts.Offset_m;
            obj.DirectionSign        = opts.DirectionSign;
            obj.PollPeriod_s         = opts.PollPeriod_s;
            obj.TimeoutSec           = opts.TimeoutSec;
            obj.PositionTolerance_cm = opts.PositionTolerance_cm;
            obj.Verbose              = opts.Verbose;

            if isempty(opts.Transport)
                obj.Transport = TcpTransport(obj.Host, obj.Port);
            else
                obj.Transport = opts.Transport;
            end

            obj.Transport.open();
            obj.getLimits();
        end

        function delete(obj)
            % Destructor: release the socket when the object is cleared.
            try obj.disconnect(); catch, end
        end

        %% Connection
        function tf = isConnected(obj)
            % ISCONNECTED  True if the transport link is open.
            tf = ~isempty(obj.Transport) && obj.Transport.isOpen();
        end

        function disconnect(obj)
            % DISCONNECT  Release the connection (transport handles cleanup).
            if ~isempty(obj.Transport)
                obj.Transport.close();
            end
        end

        function reset(obj)
            obj.Transport.writeLine('AXIS1:CR'); % Turn CR mode on to disable soft limits
            obj.Transport.writeLine('AXIS1:CC'); % Move backwards
            obj.Transport.writeLine('AXIS1:ST'); % STOP
            obj.Transport.writeLine('AXIS1:NCR'); % Turn NCR mode on to enable soft limits
            obj.Transport.writeLine('AXIS1:HOME')
            obj.Transport.writeRead('AXIS1:*OPC?')
        end

        %% Identification & status
        function s = idn(obj)
            % IDN  Query *IDN? (supported by EMCenter slider firmware).
            s = obj.writeread_("*IDN?");
        end

        function [code, msg] = getError(obj)
            % GETERROR  Query AXIS:ERR? and translate the fault code.
            code = str2double(obj.queryAxis_("ERR?"));
            msg  = EmCenterSlider.faultDescription(code);
        end

        %% Legacy compatibility shims
        % Let existing ARES code that does writeline(app.EMSlider, 'AXIS1:..')
        % keep working when app.EMSlider becomes an EmCenterSlider. These pass
        % straight through to the transport (you supply the full command,
        % including the AXIS<n>: prefix, just as the legacy code did).
        function writeline(obj, cmd)
            SCPIInstrument.legacyLog('record', 'writeline(slider)', cmd);
            obj.Transport.writeLine(cmd);
        end

        function s = readline(obj)
            SCPIInstrument.legacyLog('record', 'readline(slider)', '');
            s = obj.Transport.readLine();
        end

        function s = writeread(obj, cmd)
            SCPIInstrument.legacyLog('record', 'writeread(slider)', cmd);
            s = obj.Transport.writeRead(cmd);
        end

        function flush(obj)
            obj.Transport.flush();
        end

        %% Speed
        function setSpeedPreset(obj, preset)
            % SETSPEEDPRESET  Select speed preset 1 (slowest) .. 8 (fastest).
            validateattributes(preset, {'numeric'}, ...
                {'scalar','integer','>=',1,'<=',8}, mfilename, "preset");
            obj.writeAxis_(sprintf("S%d", preset));
        end

        %% Limits
        function [ll_cm, ul_cm] = getLimits(obj)
            % Query and cache LL/UL once for fast bounds checks.
            obj.LowerLimit_cm = str2double(obj.queryAxis_("LL?"));
            obj.UpperLimit_cm = str2double(obj.queryAxis_("UL?"));

            % GETLIMITS  Cached mechanical limits in device units (cm).
            ll_cm = obj.LowerLimit_cm;
            ul_cm = obj.UpperLimit_cm;
        end

        function [ll_m, ul_m] = getPhysicalLimits_m(obj)
            % GETPHYSICALLIMITS_M  Mechanical limits in the physical frame (m).
            [ll_cm, ul_cm] = obj.getLimits();
            ll_m = obj.deviceCmToPhysicalM_(ll_cm);
            ul_m = obj.deviceCmToPhysicalM_(ul_cm);
        end

        function setLimits(obj,ll_cm, ul_cm)
            % Query and cache LL/UL once for fast bounds checks.
            obj.Transport.writeLine(sprintf("AXIS%d:LL %f", obj.AxisId, ll_cm));
            obj.Transport.writeLine(sprintf("AXIS%d:UL %f", obj.AxisId, ul_cm));

            obj.getLimits();
        end

        %% Position
        function pos_cm = getPosition(obj)
            % GETPOSITION  Current device position (cm).
            pos_cm = str2double(obj.queryAxis_("CP?"));
        end

        function pos_m = getPosition_m(obj)
            % GETPOSITION_M  Device position in meters (no offset applied).
            pos_m = obj.getPosition() / 100.0;
        end

        function posPhys_m = getPhysicalPosition_m(obj)
            % GETPHYSICALPOSITION_M  Position in the physical frame (m).
            posPhys_m = obj.deviceCmToPhysicalM_(obj.getPosition());
        end

        %% Motion
        function moveTo(obj, targetPosition_cm)
            % MOVETO  Move to a device-frame target (cm); blocks until the
            % move completes, the timeout expires (STOP is sent and an error
            % thrown), or the target is already within tolerance.
            [ll, ul] = obj.getLimits();
            if targetPosition_cm < ll || targetPosition_cm > ul
                error("EmCenterSlider:TargetOutOfRange", ...
                    "Target %.3f cm outside mechanical limits [%.3f, %.3f] cm.", ...
                    targetPosition_cm, ll, ul);
            end

            current_cm = obj.getPosition();
            if abs(current_cm - targetPosition_cm) <= obj.PositionTolerance_cm
                if obj.Verbose
                    fprintf("EmCenterSlider: already at %.3f cm (target %.3f cm).\n", ...
                        current_cm, targetPosition_cm);
                end
                return;
            end

            % Legacy-compatible: the controller takes integer cm targets.
            obj.writeAxis_(sprintf("SK %d", round(targetPosition_cm)));

            t0 = tic;
            while obj.isMoving_()
                if toc(t0) > obj.TimeoutSec
                    obj.stop();
                    error("EmCenterSlider:MoveTimeout", ...
                        "Move to %.2f cm did not complete within %g s. STOP sent.", ...
                        targetPosition_cm, obj.TimeoutSec);
                end
                if obj.Verbose
                    fprintf("  pos = %.3f cm\n", obj.getPosition());
                end
                pause(obj.PollPeriod_s);
            end

            if obj.Verbose
                fprintf("EmCenterSlider: move complete -> %.3f cm.\n", obj.getPosition());
            end
        end

        function moveToPhysical_m(obj, targetPhysical_m)
            % MOVETOPHYSICAL_M  Move using the physical frame (m).
            obj.moveTo(obj.physicalMToDeviceCm_(targetPhysical_m));
        end

        function stop(obj)
            % STOP  Halt motion immediately.
            obj.writeAxis_("STOP");
        end

        function home(obj)
            % HOME  Run the controller's homing procedure and wait for it.
            %
            % Fault-checked on both sides: refuses to start with an active
            % fault (homing would fail with codes 400-499) and verifies the
            % fault register afterward. The wait loop polls *OPC? ONLY —
            % sending anything else mid-home (as the legacy script did with
            % AXIS:ZERO) corrupts the controller's position reference.
            [code, msg] = obj.getError();
            if code ~= 0
                error("EmCenterSlider:PreHomeFault", ...
                    "Slider reports fault %d (%s) before homing. Resolve it first.", ...
                    code, msg);
            end

            obj.writeAxis_("HOME");

            t0 = tic;
            while true
                opc = str2double(obj.queryAxis_("*OPC?"));
                if opc == 1, break; end
                if toc(t0) > obj.TimeoutSec
                    error("EmCenterSlider:HomeTimeout", ...
                        "HOME did not complete within %g s. Check for a limit fault or obstruction.", ...
                        obj.TimeoutSec);
                end
                pause(obj.PollPeriod_s);
            end

            [code, msg] = obj.getError();
            if code ~= 0
                error("EmCenterSlider:PostHomeFault", ...
                    "Slider reports fault %d (%s) after homing.", code, msg);
            end
        end
    end

    methods (Static)
        function msg = faultDescription(code)
            % FAULTDESCRIPTION  Human-readable text for an EMCenter slider
            % fault code (from the controller's documented code table).
            if isnan(code), msg = "Unparseable fault response"; return; end
            switch code
                case 0,  msg = "No error";
                case 1,  msg = "Controller board Flash memory malfunction";
                case 2,  msg = "Axis not moving";
                case 3,  msg = "Motor not stopping";
                case 4,  msg = "Motor moving in wrong direction";
                case 5,  msg = "Hardware limit hit";
                case 6,  msg = "Polarization limit violation";
                case 7,  msg = "Lost communication";
                case 9,  msg = "Encoder failure";
                case 10, msg = "Trigger failure";
                case 11, msg = "Motor overheat";
                case 12, msg = "Relay failure";
                case 13, msg = "Position out of bounds";
                case 14, msg = "Trying to move a locked axis";
                case 32, msg = "Motor driver fault";
                otherwise
                    if code >= 100 && code <= 399
                        msg = "Command syntax error";
                    elseif code >= 400 && code <= 499
                        msg = "Home procedure failure";
                    elseif code >= 500 && code <= 599
                        msg = "Trigger command malformed";
                    elseif code == 1000
                        msg = "Firmware upgrade failure";
                    else
                        msg = "Unknown fault code";
                    end
            end
        end
    end

    methods (Access = private)
        function tf = isMoving_(obj)
            % DIR? returns +1/-1 while moving, 0 when stopped. Handle both
            % numeric and string-style firmware responses.
            s = strtrim(obj.queryAxis_("DIR?"));
            d = str2double(s);
            if ~isnan(d)
                tf = (d ~= 0);
            else
                tf = any(string(s) == ["+1", "-1"]);
            end
        end

        %% Coordinate mapping
        function phys_m = deviceCmToPhysicalM_(obj, device_cm)
            phys_m = obj.DirectionSign * (device_cm / 100.0) + obj.Offset_m;
        end

        function device_cm = physicalMToDeviceCm_(obj, phys_m)
            device_cm = ((phys_m - obj.Offset_m) / obj.DirectionSign) * 100.0;
        end

        %% Axis-scoped I/O through the transport
        function writeAxis_(obj, cmd)
            obj.Transport.writeLine(sprintf("AXIS%d:%s", obj.AxisId, cmd));
        end

        function out = queryAxis_(obj, cmd)
            out = obj.Transport.writeRead(sprintf("AXIS%d:%s", obj.AxisId, cmd));
        end

        function out = writeread_(obj, cmd)
            out = obj.Transport.writeRead(cmd);
        end
    end
end
