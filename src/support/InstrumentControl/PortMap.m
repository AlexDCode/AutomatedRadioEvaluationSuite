classdef PortMap < handle
    %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
    % PortMap
    %
    % DESCRIPTION:
    % Describes how VNA ports are used in an antenna measurement so the
    % measurement code can derive which S-parameters to read and how to
    % interpret them. Each used port has TWO independent attributes:
    %
    %   Direction : Transmitter | Receiver   -- who drives, who measures.
    %               Determines which transmissions are captured: for a
    %               transmitter t and receiver r the path is S(r,t).
    %   Role      : AUT | Reference          -- the antenna's job in the test.
    %               A Reference has a known gain (a gain file + column); the
    %               AUT is the antenna being characterized.
    %
    % A port that is neither (Direction "Unused") is not in the measurement.
    %
    % WHY BOTH: Direction is what makes the map useful for general transmission
    % testing (measure any Tx->Rx you like). Role is what turns a path into an
    % absolute gain: a Tx->Rx path that crosses the AUT<->Reference boundary is
    % a gain measurement (the AUT's gain via the reference); other paths are
    % just transmissions (insertion loss).
    %
    % DERIVED QUANTITIES:
    %   paths()          - every Transmitter -> Receiver path, flagged with
    %                      whether it is a gain path and which end is which.
    %   reciprocityPairs() - S(r,t) vs S(t,r) per Tx/Rx pair (non-reciprocity).
    %   sparamsNeeded()  - self terms + both directions of every Tx<->Rx pair.
    %
    % USAGE:
    % leaky-wave AUT on ports 1-2, reference horn on port 3:
    %   pm = PortMap(4);
    %   pm.setPort(1, "Transmitter", "AUT");
    %   pm.setPort(2, "Receiver",    "AUT");
    %   pm.setPort(3, "Receiver",    "Reference", "horn_cal.csv", "Gain (dBi)");
    %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

    properties
        % Total number of ports available on the VNA (2, 4, ...).
        NumPorts (1,1) double = 0

        % Per-port assignment (used ports only). Struct array with fields:
        % Port (double), Direction (string "Transmitter"|"Receiver"),
        % Role (string "AUT"|"Reference"), GainFile (string), GainColumn
        % (string). GainFile/GainColumn are "" unless Role is "Reference".
        Ports struct = struct('Port', {}, 'Direction', {}, 'Role', {}, ...
                              'GainFile', {}, 'GainColumn', {})
    end

    properties (Constant)
        ValidDirections = ["Transmitter", "Receiver", "Unused"];
        ValidRoles      = ["AUT", "Reference"];
    end

    properties (Access = private)
        % True once NumPorts is pinned to a VNA's physical port count (via the
        % constructor), so setPort will not silently grow it and out-of-range
        % ports are caught by validation. An unsized map grows to fit.
        NumPortsFixed_ (1,1) logical = false
    end

    methods
        function obj = PortMap(numPorts)
            % PORTMAP  Construct a (possibly empty) port map.
            %   pm = PortMap()        % unsized; NumPorts grows as ports add
            %   pm = PortMap(4)       % 4-port map (fixed); no ports set yet
            if nargin >= 1 && ~isempty(numPorts)
                obj.NumPorts = numPorts;
                obj.NumPortsFixed_ = true;
            end
        end

        %% Building
        function setPort(obj, port, direction, role, gainFile, gainColumn)
            % SETPORT  Assign one port's direction + role (and optional
            % reference gain). Re-setting a port replaces its assignment.
            %   setPort(port, "Transmitter", "AUT")
            %   setPort(port, "Receiver", "Reference", gainFile, gainColumn)
            if nargin < 4, role = "AUT"; end
            if nargin < 5, gainFile   = ""; end
            if nargin < 6, gainColumn = ""; end

            port = double(port);
            e.Port       = port;
            e.Direction  = string(direction);
            e.Role       = string(role);
            e.GainFile   = string(gainFile);
            e.GainColumn = string(gainColumn);

            idx = obj.indexOfPort_(port);
            if isempty(idx)
                if isempty(obj.Ports), obj.Ports = e; else, obj.Ports(end+1) = e; end
            else
                obj.Ports(idx) = e;
            end

            if ~obj.NumPortsFixed_
                obj.NumPorts = max(obj.NumPorts, port);
            end
        end

        %% Direction / role / port queries
        function n = numAssigned(obj)
            n = numel(obj.Ports);
        end

        function p = portsByDirection(obj, direction)
            if isempty(obj.Ports), p = []; return; end
            p = sort([obj.Ports(strcmpi(string({obj.Ports.Direction}), direction)).Port]);
        end

        function p = portsByRole(obj, role)
            if isempty(obj.Ports), p = []; return; end
            p = sort([obj.Ports(strcmpi(string({obj.Ports.Role}), role)).Port]);
        end

        function p = transmitPorts(obj);  p = obj.portsByDirection("Transmitter"); end
        function p = receivePorts(obj);   p = obj.portsByDirection("Receiver");    end
        function p = autPorts(obj);       p = obj.portsByRole("AUT");              end
        function p = referencePorts(obj); p = obj.portsByRole("Reference");        end

        function p = usedPorts(obj)
            % USEDPORTS  Sorted transmitter + receiver ports.
            p = sort([obj.transmitPorts(), obj.receivePorts()]);
        end

        function dir = directionAtPort(obj, port)
            dir = "";
            idx = obj.indexOfPort_(port);
            if ~isempty(idx), dir = obj.Ports(idx).Direction; end
        end

        function role = roleAtPort(obj, port)
            role = "";
            idx = obj.indexOfPort_(port);
            if ~isempty(idx), role = obj.Ports(idx).Role; end
        end

        function tf = isReferencePort(obj, port)
            tf = strcmpi(obj.roleAtPort(port), "Reference");
        end

        function [file, column] = gainSourceAtPort(obj, port)
            file = "";  column = "";
            idx = obj.indexOfPort_(port);
            if ~isempty(idx)
                file   = obj.Ports(idx).GainFile;
                column = obj.Ports(idx).GainColumn;
            end
        end

        %% Derived measurement structure
        function paths = paths(obj)
            % PATHS  Every Transmitter -> Receiver path. Struct array fields:
            %   TxPort, RxPort, TxRole, RxRole,
            %   SParamFwd (S_{Rx,Tx}), SParamRev (S_{Tx,Rx}),
            %   IsGainPath (true when the pair crosses AUT<->Reference),
            %   RefPort / AUTPort (the reference / AUT end, NaN if not a gain
            %   path).
            paths = struct('TxPort', {}, 'RxPort', {}, 'TxRole', {}, ...
                           'RxRole', {}, 'SParamFwd', {}, 'SParamRev', {}, ...
                           'IsGainPath', {}, 'RefPort', {}, 'AUTPort', {});
            for t = obj.transmitPorts()
                for r = obj.receivePorts()
                    tRole = obj.roleAtPort(t);
                    rRole = obj.roleAtPort(r);
                    entry.TxPort    = t;
                    entry.RxPort    = r;
                    entry.TxRole    = tRole;
                    entry.RxRole    = rRole;
                    entry.SParamFwd = PortMap.sparamName(r, t);
                    entry.SParamRev = PortMap.sparamName(t, r);
                    isGain = (strcmpi(tRole,"AUT") && strcmpi(rRole,"Reference")) ...
                          || (strcmpi(tRole,"Reference") && strcmpi(rRole,"AUT"));
                    entry.IsGainPath = isGain;
                    if isGain && strcmpi(rRole, "Reference")
                        entry.RefPort = r;  entry.AUTPort = t;
                    elseif isGain
                        entry.RefPort = t;  entry.AUTPort = r;
                    else
                        entry.RefPort = NaN; entry.AUTPort = NaN;
                    end
                    paths(end + 1) = entry; %#ok<AGROW>
                end
            end
        end

        function pairs = reciprocityPairs(obj)
            % RECIPROCITYPAIRS  Each Transmitter/Receiver pair with the two
            % directed S-parameters to compare (S_rt vs S_tr).
            pairs = struct('PortA', {}, 'PortB', {}, ...
                           'SParamFwd', {}, 'SParamRev', {});
            for t = obj.transmitPorts()
                for r = obj.receivePorts()
                    entry.PortA     = t;
                    entry.PortB     = r;
                    entry.SParamFwd = PortMap.sparamName(r, t);
                    entry.SParamRev = PortMap.sparamName(t, r);
                    pairs(end + 1) = entry; %#ok<AGROW>
                end
            end
        end

        function names = sparamsNeeded(obj)
            % SPARAMSNEEDED  Self terms S_ii (return loss / efficiency) plus
            % both directions of every Transmitter<->Receiver pair (insertion
            % loss / gain + reciprocity). Sorted, unique.
            names = strings(1, 0);
            for i = obj.usedPorts()
                names(end + 1) = PortMap.sparamName(i, i); %#ok<AGROW>
            end
            for t = obj.transmitPorts()
                for r = obj.receivePorts()
                    names(end + 1) = PortMap.sparamName(r, t); %#ok<AGROW>
                    names(end + 1) = PortMap.sparamName(t, r); %#ok<AGROW>
                end
            end
            names = sort(unique(names));
        end

        function tf = isLegacyTwoPort(obj)
            % ISLEGACYTWOPORT  True for the default 2-port shape (port 1
            % transmitter, port 2 receiver, no reference). The legacy
            % runAntennaMeasurement path handles this so its results stay
            % bit-identical; any other map routes to the n-port path.
            tf = obj.NumPorts == 2 ...
                && isequal(obj.transmitPorts(), 1) ...
                && isequal(obj.receivePorts(), 2) ...
                && isempty(obj.referencePorts());
        end

        %% Validation
        function tf = validate(obj, uiFig)
            if nargin < 2, uiFig = []; end
            [tf, title, msg] = obj.check();
            if ~tf && ~isempty(uiFig)
                uialert(uiFig, msg, title);
            end
        end

        function [tf, title, msg] = check(obj)
            % CHECK  Pure validation logic (no UI).
            tf = false;

            if ~isfinite(obj.NumPorts) || obj.NumPorts < 2 ...
                    || floor(obj.NumPorts) ~= obj.NumPorts
                title = "Invalid Port Count";
                msg = "NumPorts must be an integer >= 2.";
                return;
            end

            seen = [];
            for k = 1:obj.numAssigned()
                e = obj.Ports(k);
                if ~any(strcmpi(e.Direction, ["Transmitter","Receiver"]))
                    title = "Invalid Direction";
                    msg = sprintf("Port %g has direction '%s' (need Transmitter or Receiver).", e.Port, e.Direction);
                    return;
                end
                if ~any(strcmpi(e.Role, obj.ValidRoles))
                    title = "Invalid Role";
                    msg = sprintf("Port %g has role '%s' (need AUT or Reference).", e.Port, e.Role);
                    return;
                end
                if ~isfinite(e.Port) || floor(e.Port) ~= e.Port ...
                        || e.Port < 1 || e.Port > obj.NumPorts
                    title = "Invalid Port Number";
                    msg = sprintf("Port %g is outside 1..%d.", e.Port, obj.NumPorts);
                    return;
                end
                if any(seen == e.Port)
                    title = "Port Assigned Twice";
                    msg = sprintf("Port %g is assigned more than once.", e.Port);
                    return;
                end
                seen = [seen, e.Port]; %#ok<AGROW>

                % Reference gain is OPTIONAL: a Reference port may have no gain
                % file (then no absolute gain is computed for its paths, but
                % insertion loss / reciprocity / return loss still are). The
                % only rule is consistency -- a file and its column go together.
                hasFile = strlength(e.GainFile) > 0;
                hasCol  = strlength(e.GainColumn) > 0;
                if hasFile ~= hasCol
                    title = "Incomplete Reference Gain";
                    msg = sprintf("Port %g has a gain file without a column (or a " + ...
                        "column without a file); set BOTH or neither.", e.Port);
                    return;
                end
            end

            if isempty(obj.transmitPorts())
                title = "No Transmitter"; msg = "At least one port must be a Transmitter."; return;
            end
            if isempty(obj.receivePorts())
                title = "No Receiver"; msg = "At least one port must be a Receiver."; return;
            end
            if isempty(obj.autPorts())
                title = "No AUT"; msg = "At least one port must have role AUT."; return;
            end

            tf = true; title = ""; msg = "";
        end

        %% UI table interchange (per-port rows, matching a VNA-tab uitable)
        function T = toPortRows(obj)
            % TOPORTROWS  One row per port for the VNA-tab uitable:
            %   Port | Direction | Role
            % Direction and Role are CATEGORICAL, so App Designer renders them
            % as in-cell dropdowns automatically (no ColumnFormat needed, and
            % ColumnFormat is ignored anyway when a uitable's Data is a table).
            % The reference gain file is NOT a column here -- it is uploaded
            % separately and merged onto the reference port(s) in fromApp.
            port      = (1:obj.NumPorts)';
            direction = repmat("Unused", obj.NumPorts, 1);
            role      = repmat("AUT",    obj.NumPorts, 1);
            for k = 1:obj.numAssigned()
                e = obj.Ports(k);
                if e.Port >= 1 && e.Port <= obj.NumPorts
                    direction(e.Port) = e.Direction;
                    role(e.Port)      = e.Role;
                end
            end
            T = table(port, ...
                categorical(direction, ["Transmitter", "Receiver", "Unused"]), ...
                categorical(role,      ["AUT", "Reference"]), ...
                'VariableNames', {'Port', 'Direction', 'Role'});
        end

        %% Serialization
        function s = toStruct(obj)
            s.NumPorts = obj.NumPorts;
            s.Ports = struct('Port', {}, 'Direction', {}, 'Role', {}, ...
                             'GainFile', {}, 'GainColumn', {});
            for k = 1:obj.numAssigned()
                e = obj.Ports(k);
                s.Ports(k).Port       = e.Port;
                s.Ports(k).Direction  = char(e.Direction);
                s.Ports(k).Role       = char(e.Role);
                s.Ports(k).GainFile   = char(e.GainFile);
                s.Ports(k).GainColumn = char(e.GainColumn);
            end
        end

        function saveToJSON(obj, path)
            txt = jsonencode(obj.toStruct(), "PrettyPrint", true);
            fid = fopen(path, "w");
            if fid == -1
                error("PortMap:FileError", "Could not open %s for writing.", path);
            end
            cleaner = onCleanup(@() fclose(fid));
            fwrite(fid, txt, "char");
        end
    end

    methods (Static)
        function pm = legacyTwoPort()
            % LEGACYTWOPORT  The default 2-port shape: port 1 transmits,
            % port 2 receives, both AUT, no reference. Recognised by
            % isLegacyTwoPort so the app keeps its original 2-port behavior
            % until a different map is configured.
            pm = PortMap(2);
            pm.setPort(1, "Transmitter", "AUT");
            pm.setPort(2, "Receiver",    "AUT");
        end

        function name = sparamName(receivePort, drivePort)
            % SPARAMNAME  "Sij" label where i = receiver, j = stimulus.
            name = "S" + string(receivePort) + string(drivePort);
        end

        function pm = fromPortRows(ports, directions, roles, gainFiles, gainColumns)
            % FROMPORTROWS  Build a map from per-port columns (as a uitable
            % gives them). Rows with an empty or "Unused" direction are skipped.
            ports      = double(ports(:));
            directions = string(directions(:));
            n = numel(ports);
            if nargin < 3 || isempty(roles),        roles       = repmat("AUT", n, 1); end
            if nargin < 4 || isempty(gainFiles),    gainFiles   = repmat("", n, 1);    end
            if nargin < 5 || isempty(gainColumns),  gainColumns = repmat("", n, 1);    end
            roles       = string(roles(:));
            gainFiles   = string(gainFiles(:));
            gainColumns = string(gainColumns(:));

            pm = PortMap(max([0; ports]));
            for i = 1:n
                if strlength(directions(i)) == 0 || strcmpi(directions(i), "Unused")
                    continue;
                end
                pm.setPort(ports(i), directions(i), roles(i), gainFiles(i), gainColumns(i));
            end
        end

        function pm = fromUITable(data)
            % FROMUITABLE  Build a map from a VNA-tab uitable's Data. Accepts a
            % MATLAB table with variables Port, Direction, Role and optionally
            % GainFile, GainColumn (extra columns are ignored).
            T = data;
            if ~istable(T)
                error("PortMap:BadUITable", ...
                    "PortMap.fromUITable expects a table (the uitable Data).");
            end
            rl = repmat("AUT", height(T), 1);
            gf = strings(height(T), 1); gc = strings(height(T), 1);
            if any(strcmpi(T.Properties.VariableNames, "Role"))
                rl = string(T.Role);
            end
            if any(strcmpi(T.Properties.VariableNames, "GainFile"))
                gf = string(T.GainFile);
            end
            if any(strcmpi(T.Properties.VariableNames, "GainColumn"))
                gc = string(T.GainColumn);
            end
            pm = PortMap.fromPortRows(T.Port, T.Direction, rl, gf, gc);
        end

        function pm = fromStruct(s)
            pm = PortMap();
            if isfield(s, "NumPorts") && ~isempty(s.NumPorts)
                pm.NumPorts = s.NumPorts;
            end
            if isfield(s, "Ports") && ~isempty(s.Ports)
                pr = s.Ports;
                for k = 1:numel(pr)
                    p = pr(k);
                    role = "AUT"; gf = ""; gc = "";
                    if isfield(p, "Role"),       role = string(p.Role);     end
                    if isfield(p, "GainFile"),   gf = string(p.GainFile);   end
                    if isfield(p, "GainColumn"), gc = string(p.GainColumn); end
                    pm.setPort(p.Port, string(p.Direction), role, gf, gc);
                end
            end
            if isfield(s, "NumPorts") && ~isempty(s.NumPorts)
                pm.NumPorts = max(pm.NumPorts, s.NumPorts);
            end
        end

        function pm = loadFromJSON(path)
            pm = PortMap.fromStruct(jsondecode(fileread(path)));
        end
    end

    methods (Access = private)
        function idx = indexOfPort_(obj, port)
            idx = [];
            if isempty(obj.Ports), return; end
            idx = find([obj.Ports.Port] == port, 1);
        end
    end
end
