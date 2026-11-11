function pm = portMapFromTable(app)
    %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
    % DESCRIPTION:
    % Builds the PortMap the VNA-tab port table describes (inverse of setPortMapTable): Port / Direction / Role
    % from the table's Data, and each reference port's full gain file path + column from its UserData. A table
    % that still carries GainFile + GainColumn columns (the older layout) is read directly.
    %
    % INPUT:
    %   app - ARES application object (needs PortMapTable).
    %
    % OUTPUT:
    %   pm  - PortMap.
    %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

    T = app.PortMapTable.Data;
    vars = T.Properties.VariableNames;
    if all(ismember({'GainFile', 'GainColumn'}, vars))
        pm = PortMap.fromUITable(T);
        return;
    end

    pm = PortMap.fromUITable(T(:, intersect({'Port', 'Direction', 'Role'}, vars, 'stable')));
    store = app.PortMapTable.UserData;
    if ~isstruct(store), return; end
    for s = store(:)'
        if pm.isReferencePort(s.Port)
            pm.setPort(s.Port, pm.directionAtPort(s.Port), "Reference", s.File, s.Column);
        end
    end
end
