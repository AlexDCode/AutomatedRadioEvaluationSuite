function inst = aresInstrument(handle, role)
    %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
    % aresInstrument
    %
    % DESCRIPTION:
    % Adapter that returns an object-oriented driver for an ARES instrument,
    % whether the app currently stores it as a RAW handle (visadev/tcpclient)
    % or already as a framework driver object.
    %
    % This is the linchpin of the incremental migration. A measurement
    % function can do:
    %
    %     vna = aresInstrument(app.VNA, "VNA");
    %     [sdB, sPh, f] = vna.measureSParameters(smoothing);
    %
    % and it works:
    %   - BEFORE ARES.mlapp is migrated: app.VNA is a raw visadev, so this
    %     wraps it in a non-owning HandleTransport (the app keeps owning the
    %     connection) and returns a VNAInstCtrl.
    %   - AFTER ARES.mlapp is migrated: app.VNA is already a VNAInstCtrl, so
    %     this returns it unchanged (idempotent).
    %
    % Either way the app keeps working and nothing double-opens or
    % double-closes the underlying connection.
    %
    % INPUT:
    %   handle - a raw visadev/tcpclient OR an existing framework driver
    %   role   - "VNA" | "PSU" | "Generator" | "Analyzer" | "Chamber" |
    %            "Slider" (case-insensitive)
    %
    % OUTPUT:
    %   inst - the matching driver object, connected and ready
    %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

    % Already a framework driver? Return as-is (idempotent).
    if isa(handle, 'SCPIInstrument') || isa(handle, 'EmCenterSlider')
        inst = handle;
        return;
    end

    % Otherwise wrap the live handle without taking ownership of it.
    t = HandleTransport(handle);

    switch upper(string(role))
        case "VNA"
            inst = VNAInstCtrl("auto", "auto", "wrapped", "Transport", t);
        case "PSU"
            inst = PSUInstCtrl("auto", "auto", "wrapped", "Transport", t);
        case "GENERATOR"
            inst = SignalGeneratorInstCtrl("auto", "auto", "wrapped", "Transport", t);
        case "ANALYZER"
            inst = SignalAnalyzerInstCtrl("auto", "auto", "wrapped", "Transport", t);
        case {"CHAMBER", "EMCENTER", "POSITIONER"}
            inst = SCPIInstrument("auto", "auto", "wrapped", ...
                "InstType", "Chamber", "Transport", t);
        case {"SLIDER", "EMSLIDER"}
            % EmCenterSlider connects + caches limits in its constructor.
            inst = EmCenterSlider("wrapped", 1206, 1, "Transport", t);
            return;
        otherwise
            inst = SCPIInstrument("auto", "auto", "wrapped", "Transport", t);
    end

    % SCPIInstrument-family needs an explicit connect(): open() is a no-op on
    % the already-open handle, then *IDN? runs and identity is backfilled.
    inst.connect();
end
