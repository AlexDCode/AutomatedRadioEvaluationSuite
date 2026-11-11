function refs = referenceAntennaCurves(app)
    %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
    % DESCRIPTION:
    % Collects every reference antenna loaded in the app, for the Reference Antenna tab:
    %
    %   - the file loaded with Browse Reference (app.ReferenceGainFile), and
    %   - each reference port's own gain file picked in the VNA tab's port map (PortMapTable.UserData).
    %
    % Port-map files are re-read only when they change on disk (cached by path, column and modified time).
    % A file that cannot be read is skipped.
    %
    % INPUT:
    %   app  - ARES application object.
    %
    % OUTPUT:
    %   refs - struct array with fields Label, FrequencyMHz, GaindBi, ReturnLossdB (column vectors).
    %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

    persistent cache
    if isempty(cache), cache = containers.Map('KeyType', 'char', 'ValueType', 'any'); end

    refs = struct('Label', {}, 'FrequencyMHz', {}, 'GaindBi', {}, 'ReturnLossdB', {});

    % Browse Reference file.
    R = app.ReferenceGainFile;
    if ~isempty(R) && istable(R) && ~isempty(R.GaindBi)
        name = "Reference file";
        if ~isempty(app.ReferenceGainFilePath)
            [~, n, e] = fileparts(app.ReferenceGainFilePath);
            name = string(n) + string(e);
        end
        rl = nan(height(R), 1);
        if any(strcmp(R.Properties.VariableNames, 'ReturnLossdB')), rl = R.ReturnLossdB; end
        refs(end + 1) = struct('Label', "Reference tab: " + name, 'FrequencyMHz', R.FrequencyMHz(:), ...
            'GaindBi', R.GaindBi(:), 'ReturnLossdB', rl(:));
    end

    % Port-map reference files.
    if ~isprop(app, 'PortMapTable') || ~isstruct(app.PortMapTable.UserData), return; end
    for s = app.PortMapTable.UserData(:)'
        try
            info = dir(s.File);
            key = char(s.File + "|" + s.Column + "|" + string(info.datenum));
            if ~isKey(cache, key)
                [fHz, g, ~, rl] = readReferenceGainFile(s.File, s.Column);
                cache(key) = struct('FrequencyMHz', fHz / 1e6, 'GaindBi', g, 'ReturnLossdB', rl);
            end
            c = cache(key);
            [~, n, e] = fileparts(s.File);
            refs(end + 1) = struct('Label', sprintf("Port %d: %s, %s", s.Port, string(n) + string(e), s.Column), ...
                'FrequencyMHz', c.FrequencyMHz, 'GaindBi', c.GaindBi, 'ReturnLossdB', c.ReturnLossdB); %#ok<AGROW>
        catch
            % Unreadable / moved file: leave it off the plot.
        end
    end
end
