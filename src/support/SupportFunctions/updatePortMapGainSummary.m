function updatePortMapGainSummary(app)
    %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
    % DESCRIPTION:
    % Keeps the port table's gain files in step with its Role column and refreshes the summary under the
    % table. A gain file only belongs to a Reference port, so files on rows that are no longer Reference are
    % dropped. The summary lists every reference port's full gain source, since the table only has room for
    % the file name.
    %
    % INPUT:
    %   app - ARES application object (PortMapTable, and PortMapGainLabel if the app has it).
    %
    % OUTPUT:
    %   None.
    %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

    T = app.PortMapTable.Data;
    if ~istable(T) || isempty(T), return; end
    store = app.PortMapTable.UserData;
    if ~isstruct(store), store = struct('Port', {}, 'File', {}, 'Column', {}); end

    isRef = string(T.Role) == "Reference";
    keep = arrayfun(@(s) any(T.Port(isRef) == s.Port), store);
    store = store(keep);
    if ismember('GainFile', T.Properties.VariableNames)
        T.GainFile(~isRef) = "";
        app.PortMapTable.Data = T;
    end
    app.PortMapTable.UserData = store;

    % The Reference Antenna tab plots these files too.
    if isprop(app, 'GainvsFrequencyBoresight')
        plotReferenceAntenna(app);
    end

    if ~isprop(app, 'PortMapGainLabel'), return; end
    lines = strings(0, 1);
    for p = T.Port(isRef)'
        s = store([store.Port] == p);
        if isempty(s)
            lines(end + 1) = sprintf("Port %d gain: file on the Reference Antenna tab", p); %#ok<AGROW>
        else
            [~, n, e] = fileparts(s.File);
            lines(end + 1) = sprintf("Port %d gain: %s, %s", p, n + e, s.Column); %#ok<AGROW>
        end
    end
    app.PortMapGainLabel.Text = lines;
    app.PortMapGainLabel.Visible = matlab.lang.OnOffSwitchState(~isempty(lines));
end
