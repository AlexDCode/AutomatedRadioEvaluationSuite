classdef SimTransport < ITransport
    %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
    % SimTransport
    %
    % DESCRIPTION:
    % ITransport implementation with NO hardware behind it. Realizes the
    % paper's goal of "simulated instruments, bypassing VISA drivers when
    % virtually testing and debugging new features."
    %
    % Unlike the prototype's `Simulate` flag (which returned a fixed
    % "SIM-RESPONSE" for everything), this transport is behavioral enough to
    % run real ARES code paths headless:
    %
    %   1. Every command written is appended to CommandLog. This enables the
    %      regression strategy from paper §VII.B: run a measurement against
    %      SimTransport and diff the generated SCPI sequence against a
    %      known-good log captured from real hardware.
    %
    %   2. Responses are resolved in priority order:
    %        a. ResponseMap  - exact-match table you preload for the device
    %                          (e.g. "AXIS1:LL?" -> "0", "AXIS1:UL?" -> "200")
    %        b. ResponseFcn  - your function handle f(cmd) -> string, for
    %                          dynamic behavior (moving positions, sweeps)
    %        c. Built-in heuristics - *IDN? -> IdnString, *OPC? -> "1",
    %                          SYST:ERR? -> '+0,"No error"', any other
    %                          query -> "0"
    %      The defaults are chosen so wait loops terminate and parsers get
    %      parseable numbers, letting measurement code run to completion.
    %
    %   3. Binary-block queries (VNA/analyzer traces) are served by
    %      BinaryFcn if set, otherwise by zeros(1, DefaultTraceLength).
    %
    % USAGE:
    %   t = SimTransport("IdnString", "Keysight,N5232B,SIM,1.0");
    %   t.setResponse("AXIS1:LL?", "0");
    %   t.BinaryFcn = @(cmd, type) randn(1, 201);   % fake trace data
    %   ...
    %   disp(t.CommandLog)                          % audit what was sent
    %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

    properties
        % Synthetic *IDN? response.
        IdnString (1,1) string = "SIMCO,SIMMODEL,SIM12345,1.0"

        % Optional dynamic responder: f(cmdString) -> response string, or []
        % to fall through to built-in heuristics.
        ResponseFcn = []

        % Optional binary responder: f(cmdString, datatype) -> numeric vector.
        BinaryFcn = []

        % Length of the default all-zeros binary trace.
        DefaultTraceLength (1,1) double = 201

        % If true, echo simulated traffic to the console (bring-up aid).
        Verbose (1,1) logical = false
    end

    properties (SetAccess = private)
        % Every command sent through this transport, in order (string array).
        CommandLog string = string.empty(0,1)
    end

    properties (Access = private)
        Open_ (1,1) logical = false
        ResponseMap            % containers.Map: exact command -> response
        LastCommand (1,1) string = ""
    end

    methods
        function obj = SimTransport(opts)
            % SIMTRANSPORT  Construct a simulated transport.
            %
            % Name-Value:
            %   IdnString          - synthetic *IDN? response
            %   DefaultTraceLength - default binary trace length (default 201)
            %   Verbose            - echo traffic to console (default false)
            arguments
                opts.IdnString (1,1) string = "SIMCO,SIMMODEL,SIM12345,1.0"
                opts.DefaultTraceLength (1,1) double = 201
                opts.Verbose (1,1) logical = false
            end
            obj.IdnString          = opts.IdnString;
            obj.DefaultTraceLength = opts.DefaultTraceLength;
            obj.Verbose            = opts.Verbose;
            obj.ResponseMap = containers.Map("KeyType", "char", "ValueType", "char");
            obj.Description = "SIM " + obj.IdnString;
        end

        function open(obj),  obj.Open_ = true;  end
        function close(obj), obj.Open_ = false; end
        function tf = isOpen(obj), tf = obj.Open_; end

        function setResponse(obj, cmd, response)
            % SETRESPONSE  Preload an exact-match canned response.
            %
            %   t.setResponse("AXIS1:UL?", "200")
            obj.ResponseMap(char(strtrim(cmd))) = char(string(response));
        end

        function clearLog(obj)
            % CLEARLOG  Reset the command log (e.g. between test cases).
            obj.CommandLog = string.empty(0,1);
        end

        function writeLine(obj, cmd)
            obj.assertOpen_();
            cmd = string(cmd);
            obj.LastCommand = strtrim(cmd);
            obj.CommandLog(end+1,1) = cmd;
            if obj.Verbose
                fprintf("[SIM tx] %s\n", cmd);
            end
        end

        function s = readLine(obj)
            obj.assertOpen_();
            s = obj.resolveResponse_(obj.LastCommand);
            if obj.Verbose
                fprintf("[SIM rx] %s\n", s);
            end
        end

        function d = readBinaryBlock(obj, datatype)
            obj.assertOpen_();
            if nargin < 2, datatype = "double"; end
            if ~isempty(obj.BinaryFcn)
                d = obj.BinaryFcn(obj.LastCommand, datatype);
            else
                d = zeros(1, obj.DefaultTraceLength);
            end
            if obj.Verbose
                fprintf("[SIM rx] <binary block: %d points>\n", numel(d));
            end
        end

        function flush(obj)
            obj.assertOpen_();
            % Nothing buffered in simulation; kept for interface parity.
        end
    end

    methods (Access = private)
        function s = resolveResponse_(obj, cmd)
            key = char(strtrim(cmd));

            % a. Exact-match canned responses
            if isKey(obj.ResponseMap, key)
                s = string(obj.ResponseMap(key));
                return;
            end

            % b. User-supplied dynamic responder
            if ~isempty(obj.ResponseFcn)
                s = string(obj.ResponseFcn(string(cmd)));
                if strlength(s) > 0
                    return;
                end
            end

            % c. Built-in heuristics — chosen so legacy ARES code paths
            %    terminate: OPC waits exit, error checks pass, str2double
            %    parses cleanly.
            u = upper(string(key));
            if contains(u, "*IDN?")
                s = obj.IdnString;
            elseif contains(u, "*OPC?")
                s = "1";
            elseif contains(u, "ERR?")
                s = '+0,"No error"';
            elseif contains(u, "?")
                % Note: contains, not endsWith — many SCPI queries carry
                % arguments after the '?', e.g. ":MEAS:VOLT:DC? CH1".
                s = "0";
            else
                % A read after a write-only command: nothing sensible to
                % return, but never hang.
                s = "";
            end
        end

        function assertOpen_(obj)
            if ~obj.Open_
                error("SimTransport:NotOpen", ...
                    "Simulated transport is not open. Call open() first.");
            end
        end
    end
end
