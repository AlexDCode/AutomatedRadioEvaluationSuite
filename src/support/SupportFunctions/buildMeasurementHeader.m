function header = buildMeasurementHeader(app, portMap)
    %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
    % DESCRIPTION:
    % Builds the metadata block written at the top of an antenna results file (see saveData). It records the
    % setup the data was measured with, so a file explains itself:
    %
    %   ARES Measurement File
    %   Measurement,Antenna
    %   Saved,2026-11-02 14:05:33
    %   Antenna Spacing (m),1.231
    %   Antenna Offset (m),0.8062
    %   ...
    %   PORT MAP
    %   Port,Direction,Role,Gain File,Gain Column
    %   1,Transmitter,AUT,,
    %   2,Receiver,Reference,C:\cal\horn.csv,Gain (dBi)
    %
    % saveData then writes a line "DATA" and the measurement table. readMeasurementHeader reads it back.
    % Any setting the app does not have is left blank, so this never stops a save.
    %
    % INPUT:
    %   app     - ARES application object.
    %   portMap - PortMap used for the measurement (PortMap.legacyTwoPort() for the legacy 2-port run).
    %
    % OUTPUT:
    %   header  - cell array, one row per line (rows may have different widths).
    %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

    header = {
        'ARES Measurement File'
        };
    header(end+1, 1:2) = {'Measurement', 'Antenna'};
    header(end+1, 1:2) = {'Saved', char(datetime('now', 'Format', 'yyyy-MM-dd HH:mm:ss'))};
    header(end+1, 1:2) = {'Antenna Spacing (m)', value_(@() app.setupSpacing)};
    header(end+1, 1:2) = {'Antenna Offset (m)', offset_(app)};
    header(end+1, 1:2) = {'Linear Slider Position (cm)', value_(@() app.LinearSliderCurrentPosition.Value)};
    header(end+1, 1:2) = {'Turntable Range', char(AntennaMeasurementConfig.thetaRangeFromApp(app))};
    header(end+1, 1:2) = {'Start Frequency (MHz)', value_(@() app.VNAStartFrequency.Value)};
    header(end+1, 1:2) = {'End Frequency (MHz)', value_(@() app.VNAEndFrequency.Value)};
    header(end+1, 1:2) = {'Sweep Points', value_(@() app.VNASweepPoints.Value)};
    header(end+1, 1:2) = {'Smoothing Points', value_(@() app.SmoothingPoints.Value)};

    header(end+1, 1) = {'PORT MAP'};
    header(end+1, 1:5) = {'Port', 'Direction', 'Role', 'Gain File', 'Gain Column'};
    if ~isempty(portMap)
        rows = portMap.toPortRows();
        for k = 1:height(rows)
            role = char(rows.Role(k));
            if string(rows.Direction(k)) == "Unused", role = ''; end
            header(end+1, 1:5) = {rows.Port(k), char(rows.Direction(k)), role, ...
                char(rows.GainFile(k)), char(rows.GainColumn(k))}; %#ok<AGROW>
        end
    end
end

function v = offset_(app)
    % The app keeps offsetSpacing private, so read it through antennaOffset();
    % a plain struct (tests) can carry offsetSpacing directly.
    if isobject(app) && ismethod(app, 'antennaOffset')
        v = value_(@() app.antennaOffset());
    else
        v = value_(@() app.offsetSpacing);
    end
end

function v = value_(getter)
    % A setting's value, or '' if the app does not have it (or it is blank).
    try
        v = getter();
    catch
        v = '';
    end
    if isempty(v), v = ''; end
    if isstring(v), v = char(v); end
end
