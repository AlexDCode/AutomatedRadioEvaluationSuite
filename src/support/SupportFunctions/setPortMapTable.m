function setPortMapTable(app, pm)
    %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
    % DESCRIPTION:
    % Shows a PortMap in the VNA-tab port table. The table is narrow, so it shows Port | Direction | Role |
    % Gain File with only the gain file's NAME; the full path and the chosen gain column for each reference
    % port are kept in PortMapTable.UserData (struct array Port/File/Column). portMapFromTable reads both back.
    %
    % INPUT:
    %   app - ARES application object (needs PortMapTable).
    %   pm  - PortMap to show.
    %
    % OUTPUT:
    %   None (updates app.PortMapTable and the gain summary under it).
    %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

    rows  = pm.toPortRows();
    store = struct('Port', {}, 'File', {}, 'Column', {});
    names = strings(height(rows), 1);
    for k = 1:height(rows)
        file = rows.GainFile(k);
        if strlength(file) > 0
            [~, n, e] = fileparts(file);
            names(k) = n + e;
            store(end + 1) = struct('Port', rows.Port(k), 'File', file, 'Column', rows.GainColumn(k)); %#ok<AGROW>
        end
    end

    T = rows(:, {'Port', 'Direction', 'Role'});
    T.GainFile = names;
    app.PortMapTable.Data = T;
    app.PortMapTable.UserData = store;
    app.PortMapTable.ColumnEditable = [false true true false];
    updatePortMapGainSummary(app);
end
