function updateNPortPlotDropdowns(app)
    %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
    % DESCRIPTION:
    % Populates the n-port plot quantity dropdown from the loaded n-port
    % results in app.Antenna_Data (the quantities actually present). Safe to
    % call for legacy (2-port) data or before the UI exists: it no-ops unless
    % the data is in the n-port long format and the dropdown is present.
    %
    % INPUT:
    %   app - ARES application object.
    %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

    if ~isprop(app, 'Antenna_Data') || isempty(app.Antenna_Data), return; end
    T  = app.Antenna_Data;
    vn = string(T.Properties.VariableNames);
    if ~any(strcmpi(vn, "Quantity")), return; end     % not n-port data

    if isprop(app, 'NPortQuantityDropDown')
        qcol = char(vn(find(strcmpi(vn, "Quantity"), 1)));
        q = unique(string(T.(qcol)), 'stable');
        app.NPortQuantityDropDown.Items = cellstr(q);
    end
end
