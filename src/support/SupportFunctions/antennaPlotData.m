function d = antennaPlotData(app)
    %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
    % DESCRIPTION:
    % Returns antenna measurement data in the legacy WIDE shape used by the
    % 2D/3D radiation-pattern plots. If app.Antenna_Data is the n-port long/tidy
    % format, it is pivoted (nportToWideAntenna) for the selected gain-path
    % S-parameter; legacy wide data is returned unchanged. This lets the
    % existing radiation plots work for both data formats.
    %
    % The gain path is taken from app.NPortSParameterDropDown if that component
    % exists; otherwise the first gain path in the data is used.
    %
    % INPUT:
    %   app - ARES application object.
    %
    % OUTPUT:
    %   d - a wide-format antenna table.
    %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

    d = app.Antenna_Data;
    if isempty(d) || ~istable(d), return; end
    if ~any(strcmpi(d.Properties.VariableNames, 'Quantity'))
        return;   % already legacy wide format
    end

    sparam = "";
    if isprop(app, 'NPortSParameterDropDown') && ~isempty(app.NPortSParameterDropDown.Value)
        sparam = string(app.NPortSParameterDropDown.Value);
    end
    d = nportToWideAntenna(d, sparam);
end
