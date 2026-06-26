function inst = aresConnectInstrument(instrumentName, resource)
    %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
    % aresConnectInstrument
    %
    % DESCRIPTION:
    % Build, connect, and return the object-oriented driver for an ARES
    % instrument, given the app's instrument property name and its VISA/socket
    % resource string.
    %
    % This is the drop-in replacement for the legacy two lines in the ARES.mlapp
    % connect callback:
    %
    %     app.(instrumentName) = visadev(instrumentResource);
    %     app.(instrumentName).ByteOrder = 'little-endian';
    %
    % which become, after migration, simply:
    %
    %     app.(instrumentName) = aresConnectInstrument(instrumentName, instrumentResource);
    %
    % Every subsequent legacy call in the app and support functions
    % (writeline/writeread/readbinblock/flush on app.(name)) keeps working
    % because the returned drivers expose those as methods; new code can use
    % the high-level driver methods instead.
    %
    % INPUT:
    %   instrumentName - app property name: "VNA", "SignalGenerator",
    %                    "InputSignalAnalyzer", "OutputSignalAnalyzer",
    %                    "PowerSupplyA", "PowerSupplyB", "EMCenter", "EMSlider"
    %   resource       - VISA resource or "TCPIP::host::port::SOCKET" string
    %
    % OUTPUT:
    %   inst - connected driver object
    %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

    name = string(instrumentName);

    % Resolve the model from the instrument database (by address) so the
    % per-model dialect CommandSets/<Model>.json actually loads. The app calls
    % us with only (name, resource), so without this lookup the model stays
    % "auto" and the dialect is skipped — which left the Copper Mountain
    % CMT808U running the Keysight default SCPI and timing out on its first
    % binary-block trace read. Existing instruments are unaffected: each
    % bundled JSON equals its driver's built-in defaults, so loading it is a
    % verified no-op. Falls back to "auto" when the model can't be resolved
    % (preserving the prior behavior: built-in driver defaults stay in effect).
    model = aresModelForResource_(resource);

    switch name
        case "VNA"
            inst = VNAInstCtrl("auto", model, resource);
        case "SignalGenerator"
            inst = SignalGeneratorInstCtrl("auto", model, resource);
        case {"InputSignalAnalyzer", "OutputSignalAnalyzer"}
            inst = SignalAnalyzerInstCtrl("auto", model, resource);
        case {"PowerSupplyA", "PowerSupplyB"}
            inst = PSUInstCtrl("auto", model, resource);
        case "EMCenter"
            % Generic SCPI instrument; AntennaPositioner wraps it for motion.
            inst = SCPIInstrument("auto", model, resource, "InstType", "Chamber");
        case "EMSlider"
            % Raw-socket linear slider. Constructor connects + caches limits,
            % so there is no separate connect() step below.
            tt = TcpTransport.fromResource(resource);
            inst = EmCenterSlider(tt.Host, tt.Port, 1, "Transport", tt);
            return;
        otherwise
            % Unknown name: fall back to a generic SCPI instrument so the
            % app still gets a usable, legacy-compatible object.
            inst = SCPIInstrument("auto", model, resource);
    end

    inst.connect();
end

function model = aresModelForResource_(resource)
    % ARESMODELFORRESOURCE_  Look up the model token for a resource string in
    % the ARES instrument database, so the matching CommandSets/<Model>.json
    % dialect loads on connect. Returns "auto" when the model cannot be
    % determined (missing DB, no match, or read error) — which preserves the
    % previous behavior: the driver's built-in default dialect stays in effect.
    model = "auto";
    resource = strtrim(string(resource));
    if resource == ""
        return;
    end

    csvPath = aresInstrumentDbPath_();
    if csvPath == "" || ~isfile(csvPath)
        return;
    end

    try
        tbl = readtable(csvPath, "TextType", "string", "Delimiter", ",");
        cols = string(tbl.Properties.VariableNames);
        if ~all(ismember(["Description", "Address"], cols))
            return;
        end
        match = strcmpi(strtrim(tbl.Address), resource);
        if any(match)
            desc = tbl.Description(find(match, 1));
            [~, model] = InstrumentFactory.splitDescription(desc);
        end
    catch
        % Leave model = "auto"; a DB hiccup must not block connecting.
    end
end

function p = aresInstrumentDbPath_()
    % ARESINSTRUMENTDBPATH_  Path to the live instrument database the app
    % reads (userpath/ARES/instrumentAddresses.csv), falling back to the
    % framework's bundled support copy. Mirrors the app's
    % loadInstrumentAddressestoApp lookup so the model resolved here matches
    % the row the operator actually selected.
    p = "";
    try
        live = string(fullfile(userpath, 'ARES', 'instrumentAddresses.csv'));
        if isfile(live)
            p = live;
            return;
        end
    catch
    end
    here   = fileparts(mfilename('fullpath'));   % .../support/InstrumentControl
    backup = string(fullfile(here, '..', 'instrumentAddresses.csv'));
    if isfile(backup)
        p = backup;
    end
end
