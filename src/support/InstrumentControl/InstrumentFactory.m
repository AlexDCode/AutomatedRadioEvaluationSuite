classdef InstrumentFactory
    %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
    % InstrumentFactory
    %
    % DESCRIPTION:
    % Data-driven construction of instrument controllers from the ARES
    % instrument database (instrumentAddresses.csv). Realizes the paper's
    % §VIII.A design: "adding support for new hardware becomes primarily a
    % data-entry task."
    %
    % CSV SCHEMA:
    %   Description, Address, Type[, Class]
    %
    %   Description - human-readable "Manufacturer Model" (e.g.
    %                 "Keysight Technologies N5232B"). The model is taken as
    %                 the last whitespace-separated token, which also selects
    %                 the CommandSets/<Model>.json dialect file.
    %   Address     - VISA resource or "TCPIP::host::port::SOCKET" string.
    %   Type        - functional type label: VNA, PSU, Generator, Analyzer,
    %                 Chamber, Slider. If absent/empty it is inferred from the
    %                 Description (SCPIInstrument.guessTypeFromModelOrRole).
    %   Class       - controller class to instantiate. If absent/empty it is
    %                 derived from Type via classForType().
    %
    % Adding a new instrument to ARES is then:
    %   1. one row in instrumentAddresses.csv
    %   2. (only if its SCPI dialect differs) one JSON file in CommandSets/
    % No MATLAB code changes.
    %
    % TYPICAL USAGE (App startup):
    %   tbl = InstrumentFactory.readDatabase("instrumentAddresses.csv");
    %   vna = InstrumentFactory.createFromRow(tbl(contains(tbl.Description,"N5232B"),:));
    %   vna.connect();
    %
    %   % Everything at once, simulated (headless dev / regression tests):
    %   instruments = InstrumentFactory.createAll(csvPath, "Simulate", true);
    %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

    methods (Static)
        function tbl = readDatabase(csvPath)
            % READDATABASE  Load the instrument CSV into a normalized table.
            %
            % Guarantees Description/Address/Type/Class columns exist
            % (backfilling Type and Class when missing) and drops blank rows.
            tbl = readtable(csvPath, "TextType", "string", "Delimiter", ",");

            required = ["Description", "Address"];
            for c = required
                if ~ismember(c, string(tbl.Properties.VariableNames))
                    error("InstrumentFactory:BadCSV", ...
                        "Instrument database %s is missing column '%s'.", csvPath, c);
                end
            end

            % Drop blank/placeholder rows (no description).
            tbl = tbl(strlength(strtrim(tbl.Description)) > 0, :);

            % Backfill Type from the Description (model substring heuristics).
            if ~ismember("Type", string(tbl.Properties.VariableNames))
                tbl.Type = strings(height(tbl), 1);
            end
            for k = 1:height(tbl)
                if strlength(strtrim(tbl.Type(k))) == 0
                    tbl.Type(k) = SCPIInstrument.guessTypeFromModelOrRole(tbl.Description(k));
                end
            end

            % Backfill Class from Type.
            if ~ismember("Class", string(tbl.Properties.VariableNames))
                tbl.Class = strings(height(tbl), 1);
            end
            for k = 1:height(tbl)
                if strlength(strtrim(tbl.Class(k))) == 0
                    tbl.Class(k) = InstrumentFactory.classForType(tbl.Type(k));
                end
            end
        end

        function cls = classForType(type)
            % CLASSFORTYPE  Default controller class for a type label.
            switch lower(strtrim(string(type)))
                case "vna",       cls = "VNAInstCtrl";
                case "psu",       cls = "PSUInstCtrl";
                case "generator", cls = "SignalGeneratorInstCtrl";
                case "analyzer",  cls = "SignalAnalyzerInstCtrl";
                case "chamber",   cls = "SCPIInstrument";   % EMCenter: wrapped by AntennaPositioner
                case "slider",    cls = "EmCenterSlider";
                otherwise,        cls = "SCPIInstrument";
            end
        end

        function [man, model] = splitDescription(description)
            % SPLITDESCRIPTION  Split "Manufacturer Model" into its parts.
            %
            % The model is the last whitespace token (model numbers like
            % N5232B, EMSlider, SMW200A are always last); the manufacturer is
            % everything before it (which may itself contain spaces, e.g.
            % "Rohde & Schwarz"). The model token also selects the
            % CommandSets/<Model>.json dialect, so this split preserves the
            % per-model command loading that the old Model column provided.
            parts = split(strtrim(string(description)));
            if numel(parts) >= 2
                model = parts(end);
                man   = strjoin(parts(1:end-1), " ");
            else
                man   = "auto";
                model = strtrim(string(description));
            end
        end

        function inst = createFromRow(row, opts)
            % CREATEFROMROW  Instantiate the controller for one table row.
            %
            % INPUT:
            %   row - 1-row table slice from readDatabase()
            %
            % Name-Value:
            %   Simulate   - build on SimTransport instead of hardware
            %   TimeoutSec - I/O timeout for the transport
            %
            % The returned object is constructed but NOT connected (except
            % EmCenterSlider, whose constructor connects by design).
            arguments
                row table
                opts.Simulate   (1,1) logical = false
                opts.TimeoutSec (1,1) double  = 5
            end
            if height(row) ~= 1
                error("InstrumentFactory:BadRow", ...
                    "createFromRow expects exactly one table row (got %d).", height(row));
            end

            [man, model] = InstrumentFactory.splitDescription(row.Description(1));
            address = row.Address(1);
            cls     = strtrim(row.Class(1));

            if exist(cls, "class") ~= 8
                error("InstrumentFactory:UnknownClass", ...
                    "Class '%s' (%s) not found on the MATLAB path.", ...
                    cls, row.Description(1));
            end

            if cls == "EmCenterSlider"
                % Different constructor signature: (host, port, axisId).
                inst = InstrumentFactory.createSlider_(address, opts);
            else
                % All SCPIInstrument-family classes share one signature.
                inst = feval(cls, man, model, address, ...
                    "Simulate", opts.Simulate, "TimeoutSec", opts.TimeoutSec);
            end
        end

        function instruments = createAll(csvPath, opts)
            % CREATEALL  Build controllers for every row in the database.
            %
            % OUTPUT:
            %   instruments - containers.Map: model token -> controller object.
            %                 Rows whose class fails to construct are skipped
            %                 with a warning (one bad instrument should not
            %                 block the rest of the lab).
            arguments
                csvPath (1,1) string
                opts.Simulate   (1,1) logical = false
                opts.TimeoutSec (1,1) double  = 5
            end

            tbl = InstrumentFactory.readDatabase(csvPath);
            instruments = containers.Map("KeyType", "char", "ValueType", "any");

            for k = 1:height(tbl)
                [~, model] = InstrumentFactory.splitDescription(tbl.Description(k));
                try
                    inst = InstrumentFactory.createFromRow(tbl(k,:), ...
                        "Simulate", opts.Simulate, "TimeoutSec", opts.TimeoutSec);
                    instruments(char(model)) = inst;
                catch ME
                    warning("InstrumentFactory:CreateFailed", ...
                        "Could not create %s (%s): %s", ...
                        tbl.Description(k), tbl.Class(k), ME.message);
                end
            end
        end
    end

    methods (Static, Access = private)
        function inst = createSlider_(address, opts)
            % Build an EmCenterSlider from a socket resource string, with
            % optional simulation backing.
            if opts.Simulate
                t = SimTransport("IdnString", "ETS-Lindgren,EMSlider,SIM,1.0");
                % Plausible defaults so the constructor's limit caching and
                % subsequent bounds checks behave like the real 2 m rail.
                t.setResponse("AXIS1:LL?", "0");
                t.setResponse("AXIS1:UL?", "200");
                inst = EmCenterSlider("sim", 1206, 1, "Transport", t);
            else
                if TcpTransport.isSocketResource(address)
                    tt = TcpTransport.fromResource(address, "TimeoutSec", opts.TimeoutSec);
                    inst = EmCenterSlider(tt.Host, tt.Port, 1, "Transport", tt);
                else
                    error("InstrumentFactory:BadSliderAddress", ...
                        "EmCenterSlider expects a TCPIP::host::port::SOCKET resource, got: %s", ...
                        address);
                end
            end
        end
    end
end
