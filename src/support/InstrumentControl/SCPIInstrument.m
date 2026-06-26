classdef SCPIInstrument < handle
    %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
    % SCPIInstrument
    %
    % DESCRIPTION:
    % Base class for all ARES SCPI instruments. Adapted from "Object-Oriented
    % MATLAB Framework for Instrument Control Within the ARES Platform")
    % with the changes required for integration into the production ARES App:
    %
    %   1. TRANSPORT SEAM. I/O goes through an ITransport (VisaTransport,
    %      TcpTransport, or SimTransport) instead of a hardwired visadev.
    %      Simulation is now "just another transport" rather than an
    %      if-Simulate branch in every method.
    %
    %   2. BINARY-BLOCK TRANSFERS. The command registry and scpi() dispatcher
    %      understand `read: "binblock:double"` specs, and queryBinary()
    %      exposes raw binary reads. Required for VNA / signal-analyzer
    %      trace transfers (legacy readbinblock usage) — without this no
    %      VNA could be migrated.
    %
    %   3. JSON COMMAND DIALECTS. On construction, the class auto-loads
    %      CommandSets/<Model>.json (next to this file) if it exists. Adding
    %      support for a new instrument model is therefore a data-entry task:
    %      drop a JSON file, no class edits ("drop-in support of new
    %      instrument command sets without invasive code changes").
    %
    %   4. LEGACY COMPATIBILITY SHIMS. writeline(obj,cmd), readline(obj),
    %      writeread(obj,cmd), readbinblock(obj,type), and flush(obj) are
    %      provided as methods. MATLAB dispatches function-call syntax to
    %      methods, so existing ARES helper functions like
    %         writeline(app.VNA, 'SENS1:SWE:MODE SING')
    %      keep working unchanged when app.VNA becomes a driver object.
    %      This is the staged-migration mechanism from paper §VII: legacy
    %      code paths remain available while workflows migrate one at a time.
    %
    %   5. FIXED DISCONNECT. The prototype's `clear obj.io` was a no-op that
    %      leaked connections; release now happens in the transport.
    %
    % TYPICAL USAGE:
    %   vna = VNAInstCtrl("Keysight", "N5232B", "TCPIP0::...::inst0::INSTR");
    %   vna.connect();
    %   [sdB, sPh, f] = vna.measureSParameters(1);
    %   vna.disconnect();
    %
    % SIMULATION:
    %   vna = VNAInstCtrl("Keysight", "N5232B", "SIM", "Simulate", true);
    %   vna.connect();          % no hardware touched; SimTransport underneath
    %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

    properties (SetAccess = private)
        % Identity is intentionally NOT stored as Manufacturer/Model
        % attributes — that metadata isn't needed to control an instrument.
        % The live identity is always available via the raw IDN string below
        % (queried at connect), and the model is used transiently at
        % construction only to select the per-model command dialect.
        Address      string = ""         % VISA resource / logical address
        InstType     string = "Unknown"  % PSU, VNA, Analyzer, Generator, Chamber, Slider
        IsConnected  logical = false
        IDN          string = ""         % Raw *IDN? response
    end

    properties (SetAccess = protected)
        % The transport this instrument talks through. Settable by
        % subclasses and the factory; inject a SimTransport for testing.
        Transport = []   % ITransport or []
    end

    properties (Access = protected)
        Simulate    logical = false
        TimeoutSec  double  = 5
        Termination string  = "LF"
        CommandMap              % containers.Map: name -> struct(fmt,type,read)
    end

    methods
        %% Constructor
        function obj = SCPIInstrument(man, model, address, varargin)
            % SCPIINSTRUMENT  Construct an instrument (does not connect).
            %
            % INPUT:
            %   man     - Manufacturer string. Used only transiently (not
            %             stored); pass "auto" if unknown.
            %   model   - Model string. Used transiently to select the
            %             per-model command dialect (CommandSets/<model>.json);
            %             not stored as a property.
            %   address - VISA resource string, or anything when simulating
            %
            % Name-Value:
            %   'InstType'    - role label (default "Unknown")
            %   'Simulate'    - true => use SimTransport (default false)
            %   'TimeoutSec'  - I/O timeout, seconds (default 5)
            %   'Termination' - "LF" | "CR" | "CR/LF" | "none" (default "LF")
            %   'Transport'   - inject a pre-built ITransport (overrides
            %                   Simulate/address-based transport selection)

            p = inputParser;
            addParameter(p, 'InstType', "Unknown");
            addParameter(p, 'Simulate', false, @islogical);
            addParameter(p, 'TimeoutSec', 5, @isnumeric);
            addParameter(p, 'Termination', "LF");
            addParameter(p, 'Transport', []);
            parse(p, varargin{:});

            % Manufacturer/model are deliberately not stored (see properties
            % block). 'man' is accepted for call-site compatibility; 'model'
            % is used right here to pick the command dialect, then discarded.
            obj.Address      = string(address);
            obj.InstType     = string(p.Results.InstType);
            obj.Simulate     = p.Results.Simulate;
            obj.TimeoutSec   = p.Results.TimeoutSec;
            obj.Termination  = string(p.Results.Termination);
            obj.Transport    = p.Results.Transport;

            obj.CommandMap = containers.Map('KeyType','char','ValueType','any');
            obj.registerDefaultSCPI_();

            % JSON dialect auto-load: CommandSets/<model>.json next to this
            % classdef. Silent if absent — defaults registered by the
            % subclass remain in effect.
            obj.tryLoadModelCommandSet_(model);
        end

        %% Connection lifecycle
        function connect(obj)
            % CONNECT  Open the transport and identify the instrument.
            if obj.IsConnected, return; end

            % Build a transport if one wasn't injected.
            if isempty(obj.Transport)
                if obj.Simulate
                    obj.Transport = SimTransport( ...
                        "IdnString", sprintf("ARES-SIM,%s,SIM,1.0", obj.InstType));
                else
                    obj.Transport = SCPIInstrument.transportForAddress( ...
                        obj.Address, obj.TimeoutSec, obj.Termination);
                end
            end

            try
                obj.Transport.open();
                obj.IsConnected = true;
                obj.IDN = obj.Transport.writeRead("*IDN?");
                obj.backfillFromIDN_();
            catch ME
                % Clean up local state, then propagate (paper V.H strategy:
                % catch near the transport, clean up, rethrow informatively).
                try obj.Transport.close(); catch, end
                obj.IsConnected = false;
                obj.IDN = "";
                rethrow(ME);
            end
        end

        function disconnect(obj)
            % DISCONNECT  Close the transport and reset state.
            if ~isempty(obj.Transport)
                obj.Transport.close();
            end
            obj.IsConnected = false;
            obj.IDN = "";
        end

        function delete(obj)
            % Destructor: never leak a connection when the object is cleared.
            try obj.disconnect(); catch, end
        end

        %% Primitive I/O (preferred names for new code)
        function write(obj, cmd)
            % WRITE  Send a SCPI command, no response expected.
            obj.assertConnected_();
            obj.Transport.writeLine(cmd);
        end

        function s = read(obj)
            % READ  Read one line from the instrument.
            obj.assertConnected_();
            s = obj.Transport.readLine();
        end

        function s = writeread(obj, cmd)
            % WRITEREAD  Send a command and read the one-line response.
            obj.assertConnected_();
            s = obj.Transport.writeRead(cmd);
        end

        %% Legacy compatibility shims (migration mechanism — paper VII)
        % These let untouched ARES helper functions keep calling the visadev-
        % style verbs (writeline/readline/readbinblock) on instrument objects
        % exactly as they did on raw handles. They are NOT primitives — the
        % primitives are write/read/writeread above. Each call is recorded by
        % the session legacy log (SCPIInstrument.legacyLog) so the team can
        % see which code paths still depend on the old API during migration.
        %
        % NOTE: writeread is intentionally not logged (it doubles as the
        % preferred query primitive, used internally by scpi). flush is not
        % logged either — it is a normal operation the new OO methods use too,
        % so logging it would produce false positives.
        function writeline(obj, cmd)
            SCPIInstrument.legacyLog('record', 'writeline', cmd);
            obj.write(cmd);
        end

        function s = readline(obj)
            SCPIInstrument.legacyLog('record', 'readline', '');
            s = obj.read();
        end

        function d = readbinblock(obj, datatype)
            if nargin < 2, datatype = "double"; end
            SCPIInstrument.legacyLog('record', 'readbinblock', char(string(datatype)));
            obj.assertConnected_();
            d = obj.Transport.readBinaryBlock(datatype);
        end

        function flush(obj)
            obj.assertConnected_();
            obj.Transport.flush();
        end

        %% Command registry
        function registerCommand(obj, name, fmt, type, readSpec)
            % REGISTERCOMMAND  Register a named SCPI command.
            %
            % INPUT:
            %   name     - logical name, e.g. 'trace_fdata'
            %   fmt      - SCPI format string, e.g. 'CALC1:DATA? FDATA'
            %   type     - 'write' | 'query' | 'auto' (default 'auto':
            %              query iff fmt ends with '?')
            %   readSpec - 'ascii' (default) or 'binblock:<datatype>',
            %              e.g. 'binblock:double' for trace transfers
            if nargin < 4 || isempty(type),     type = 'auto';      end
            if nargin < 5 || isempty(readSpec), readSpec = 'ascii'; end

            t = lower(string(type));
            if ~ismember(t, ["write","query","auto"])
                error("SCPIInstrument:BadCommandType", ...
                    "type must be 'write', 'query', or 'auto'.");
            end

            spec.fmt  = char(fmt);
            spec.read = char(lower(string(readSpec)));
            if t == "auto"
                if endsWith(strtrim(spec.fmt), '?'), spec.type = 'query';
                else,                                spec.type = 'write';
                end
            else
                spec.type = char(t);
            end

            obj.CommandMap(lower(char(name))) = spec;
        end

        function loadCommandsFromJSON(obj, pathOrJson)
            % LOADCOMMANDSFROMJSON  Bulk-load command specs from JSON.
            %
            % Schema (array of objects):
            %   [
            %     {"name": "sweep_single", "fmt": "SENS1:SWE:MODE SING",
            %      "type": "write"},
            %     {"name": "trace_fdata",  "fmt": "CALC1:DATA? FDATA",
            %      "type": "query", "read": "binblock:double"}
            %   ]
            %
            % "type" defaults to "auto", "read" defaults to "ascii".
            % Entries override any same-named command already registered, so
            % a model JSON can re-dialect a driver's built-in defaults.
            if isfile(pathOrJson)
                txt = fileread(pathOrJson);
            else
                txt = char(pathOrJson);
            end
            data = jsondecode(txt);

            if isstruct(data)
                data = num2cell(data);
            elseif ~iscell(data)
                error("SCPIInstrument:BadJSON", "Unsupported JSON command schema.");
            end

            for k = 1:numel(data)
                d = data{k};
                if ~isfield(d, 'name') || ~isfield(d, 'fmt')
                    error("SCPIInstrument:BadJSON", ...
                        'Each command needs "name" and "fmt".');
                end
                if isfield(d, 'type'), tp = d.type; else, tp = 'auto';  end
                if isfield(d, 'read'), rd = d.read; else, rd = 'ascii'; end
                obj.registerCommand(d.name, d.fmt, tp, rd);
            end
        end

        function tf = hasCommand(obj, name)
            % HASCOMMAND  True if a named command is registered.
            tf = isKey(obj.CommandMap, lower(char(name)));
        end

        %% SCPI dispatcher
        function out = scpi(obj, nameOrFmt, varargin)
            % SCPI  Issue a command via the registry or ad hoc.
            %
            %   obj.scpi('sweep_single')           % registered write
            %   t = obj.scpi('trace_fdata')        % registered binary query
            %   obj.scpi('FREQ %g', 1e9)           % ad hoc format string
            %   v = obj.scpi('MEAS:VOLT? (@%d)',1) % ad hoc query
            %
            % Registered commands carry their own type and read spec
            % (ascii vs binblock). Ad hoc commands: query iff the final
            % string ends with '?', read as ascii.
            obj.assertConnected_();

            key = lower(char(nameOrFmt));
            if isKey(obj.CommandMap, key)
                spec  = obj.CommandMap(key);
                cmd   = sprintf(spec.fmt, varargin{:});
                ctype = spec.type;
                rspec = spec.read;
            else
                fmt = char(nameOrFmt);
                if contains(fmt, '%')
                    cmd = sprintf(fmt, varargin{:});
                else
                    pieces = [{fmt}, varargin];
                    for i = 1:numel(pieces)
                        if ~ischar(pieces{i})
                            pieces{i} = char(string(pieces{i}));
                        end
                    end
                    cmd = strjoin(pieces, ' ');
                end
                if endsWith(strtrim(cmd), '?'), ctype = 'query';
                else,                            ctype = 'write';
                end
                rspec = 'ascii';
            end

            if strcmp(ctype, 'query')
                if startsWith(rspec, 'binblock')
                    out = obj.binaryQuery_(cmd, rspec);
                else
                    out = obj.writeread(cmd);
                end
            else
                obj.write(cmd);
                out = string.empty();
            end
        end

        function d = queryBinary(obj, nameOrFmt, varargin)
            % QUERYBINARY  Force a binary-block read for a command,
            % regardless of how (or whether) it is registered.
            %
            %   trace = obj.queryBinary('CALC1:DATA? FDATA');
            obj.assertConnected_();
            key = lower(char(nameOrFmt));
            if isKey(obj.CommandMap, key)
                spec = obj.CommandMap(key);
                cmd  = sprintf(spec.fmt, varargin{:});
                rspec = spec.read;
                if ~startsWith(rspec, 'binblock'), rspec = 'binblock:double'; end
            else
                cmd = sprintf(char(nameOrFmt), varargin{:});
                rspec = 'binblock:double';
            end
            d = obj.binaryQuery_(cmd, rspec);
        end

        %% Synchronization & error helpers
        function ok = opcWait(obj, timeoutSec, pollSec)
            % OPCWAIT  Poll *OPC? until the instrument reports complete.
            %
            %   ok = obj.opcWait()            % defaults: 15 s timeout, 0.1 s poll
            %   ok = obj.opcWait(60)          % custom timeout
            %   ok = obj.opcWait(60, 0.25)    % custom timeout and poll period
            %
            % Returns true if the instrument completed, false on timeout
            % (mirrors the soft-timeout behavior of the legacy
            % waitForInstrument helper rather than throwing).
            if nargin < 2 || isempty(timeoutSec), timeoutSec = 15;  end
            if nargin < 3 || isempty(pollSec),    pollSec    = 0.1; end
            obj.assertConnected_();

            t0 = tic;
            while true
                try
                    status = str2double(obj.writeread('*OPC?'));
                catch
                    ok = false;
                    return;
                end
                if status == 1
                    ok = true;
                    return;
                end
                if toc(t0) > timeoutSec
                    ok = false;
                    return;
                end
                pause(pollSec);
            end
        end

        function [code, msg] = checkError(obj)
            % CHECKERROR  Query SYST:ERR? and parse the response.
            %
            %   [code, msg] = obj.checkError()
            %
            % Returns code 0 / msg "No error" when the queue is clean.
            raw = obj.scpi('err?');
            code = sscanf(char(raw), '%d', 1);
            if isempty(code), code = NaN; end
            q = regexp(char(raw), '"([^"]*)"', 'tokens', 'once');
            if isempty(q), msg = string(raw); else, msg = string(q{1}); end
        end
    end

    methods (Access = private)
        function d = binaryQuery_(obj, cmd, rspec)
            % Send a command and read the response as a binary block.
            parts = split(string(rspec), ":");
            if numel(parts) >= 2, datatype = parts(2); else, datatype = "double"; end
            obj.Transport.writeLine(cmd);
            d = obj.Transport.readBinaryBlock(datatype);
            obj.Transport.flush();   % discard trailing terminator bytes
        end

        function assertConnected_(obj)
            if ~obj.IsConnected
                error("SCPIInstrument:NotConnected", ...
                    "%s instrument (%s) is not connected. Call connect() first.", ...
                    obj.InstType, obj.Address);
            end
        end

        function backfillFromIDN_(obj)
            % Guess InstType from the *IDN? model field if still unknown.
            % (Manufacturer/Model are no longer stored; the raw IDN remains
            % available for any caller that wants the identity.)
            if obj.InstType == "" || obj.InstType == "Unknown"
                [~, mdl] = SCPIInstrument.parseIdn(obj.IDN);
                obj.InstType = SCPIInstrument.guessTypeFromModelOrRole(mdl);
            end
        end

        function registerDefaultSCPI_(obj)
            % Core IEEE 488.2 commands every SCPI instrument understands.
            obj.registerCommand('idn?', '*IDN?', 'query');
            obj.registerCommand('rst',  '*RST',  'write');
            obj.registerCommand('cls',  '*CLS',  'write');
            obj.registerCommand('opc?', '*OPC?', 'query');
            obj.registerCommand('wai',  '*WAI',  'write');
            obj.registerCommand('err?', 'SYST:ERR?', 'query');
        end
    end

    methods (Access = protected)
        function tryLoadModelCommandSet_(obj, model)
            % Auto-load CommandSets/<model>.json if present (drop-in dialects).
            % 'model' is supplied by the constructor; it is not stored.
            %
            % PROTECTED (not private) so a driver subclass can RE-APPLY the
            % dialect at the END of its own constructor. The base constructor
            % loads it once, but the subclass then registers its built-in
            % defaults (e.g. registerVNACommands_), which would otherwise
            % clobber the JSON. Re-invoking this after those defaults lets the
            % per-model JSON win — honoring the "JSON re-dialects a driver's
            % built-in defaults" contract documented in the class header.
            model = string(model);
            if model == "" || lower(model) == "auto"
                return;
            end
            here = fileparts(mfilename('fullpath'));
            jsonPath = fullfile(here, 'CommandSets', char(model) + ".json");
            if isfile(jsonPath)
                try
                    obj.loadCommandsFromJSON(jsonPath);
                catch ME
                    warning("SCPIInstrument:BadCommandSet", ...
                        "Failed to load command set %s: %s", jsonPath, ME.message);
                end
            end
        end
    end

    methods (Static)
        function out = legacyLog(action, varargin)
            % LEGACYLOG  Session-wide record of legacy I/O shim usage.
            %
            % The framework records every call to the visadev-style shims
            % (writeline/readline/readbinblock) here, so the team can see how
            % much code still depends on the old API during the migration.
            %
            % USER-FACING ACTIONS:
            %   SCPIInstrument.legacyLog('report')        % print + return table
            %   SCPIInstrument.legacyLog('reset')         % clear the log
            %   SCPIInstrument.legacyLog('verbose', true) % print EVERY call
            %                                             %  (default: notice
            %                                             %   on first call per
            %                                             %   shim, then count)
            %
            % INTERNAL ACTION (called by the shims):
            %   SCPIInstrument.legacyLog('record', method, cmd)
            %
            % State persists for the MATLAB session (until 'reset' or clear).
            %
            % TODO:Add to the log which instrument the legacy code is com
            persistent ENTRIES COUNTS VERBOSE
            if isempty(COUNTS)
                ENTRIES = cell(0, 3);   % {datetime, method, command}
                COUNTS  = containers.Map('KeyType', 'char', 'ValueType', 'double');
                VERBOSE = false;
            end
            out = [];

            switch lower(string(action))
                case "record"
                    method = char(varargin{1});
                    cmd    = char(string(varargin{2}));
                    ENTRIES(end+1, :) = {datetime('now'), string(method), string(cmd)};
                    if isKey(COUNTS, method)
                        COUNTS(method) = COUNTS(method) + 1;
                    else
                        COUNTS(method) = 1;
                    end
                    if VERBOSE
                        fprintf('[legacy] %s("%s")\n', method, cmd);
                    elseif COUNTS(method) == 1
                        fprintf(['[legacy] "%s" shim used (first call this ' ...
                            'session; further calls are counted). Prefer the ' ...
                            'OO API; run SCPIInstrument.legacyLog(''report'').\n'], method);
                    end

                case "report"
                    if isempty(ENTRIES)
                        fprintf('No legacy I/O shim calls recorded this session.\n');
                        out = cell2table(cell(0,3), ...
                            'VariableNames', {'Time','Method','Command'});
                    else
                        fprintf('Legacy I/O shim usage this session:\n');
                        ks = keys(COUNTS);
                        for i = 1:numel(ks)
                            fprintf('  %-14s %d call(s)\n', ks{i}, COUNTS(ks{i}));
                        end
                        fprintf('  ---- %d total ----\n', size(ENTRIES, 1));
                        out = cell2table(ENTRIES, ...
                            'VariableNames', {'Time','Method','Command'});
                    end

                case "reset"
                    ENTRIES = cell(0, 3);
                    COUNTS  = containers.Map('KeyType', 'char', 'ValueType', 'double');
                    fprintf('Legacy log cleared.\n');

                case "verbose"
                    VERBOSE = logical(varargin{1});

                otherwise
                    error("SCPIInstrument:BadLegacyLogAction", ...
                        "Unknown action '%s'. Use record/report/reset/verbose.", action);
            end
        end

        function t = transportForAddress(address, timeoutSec, termination)
            % TRANSPORTFORADDRESS  Pick the right transport for a resource
            % string: raw-socket resources get TcpTransport, everything else
            % gets VisaTransport. Used by connect() and the factory.
            if nargin < 2 || isempty(timeoutSec),  timeoutSec  = 5;    end
            if nargin < 3 || isempty(termination), termination = "LF"; end

            if TcpTransport.isSocketResource(address)
                t = TcpTransport.fromResource(address, "TimeoutSec", timeoutSec);
            else
                t = VisaTransport(address, "TimeoutSec", timeoutSec, ...
                                  "Termination", termination);
            end
        end

        function [manufacturer, model, serial, firmware] = parseIdn(idnStr)
            % PARSEIDN  Split "MAN,MODEL,SERIAL,FW" (or space-separated).
            s = string(strtrim(idnStr));
            manufacturer = ""; model = ""; serial = ""; firmware = "";
            if s == "", return; end

            parts = split(s, ",");
            if numel(parts) < 2, parts = split(s); end
            parts = strip(parts);

            if numel(parts) >= 1, manufacturer = parts(1); end
            if numel(parts) >= 2, model        = parts(2); end
            if numel(parts) >= 3, serial       = parts(3); end
            if numel(parts) >= 4, firmware     = parts(4); end
        end

        function t = guessTypeFromModelOrRole(str)
            % GUESSTYPEFROMMODELORROLE  Heuristic model/role -> type label.
            s = lower(string(str));
            if contains(s, ["sig gen","generator","smw","e44","n5182"])
                t = "Generator";
            elseif contains(s, ["spectrum","signal analyzer","fsv","rsa","mxr","n9000","cxa"])
                t = "Analyzer";
            elseif contains(s, ["vna","znb","ena","pna","e5072","n5232"])
                t = "VNA";
            elseif contains(s, ["supply","psu","dp8","e36","ngp","ngm"])
                t = "PSU";
            elseif contains(s, ["emcenter","tower","table"])
                t = "Chamber";
            elseif contains(s, ["slider","axis"])
                t = "Slider";
            else
                t = "Unknown";
            end
        end
    end
end
