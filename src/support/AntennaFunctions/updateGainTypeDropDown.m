function updateGainTypeDropDown(app)
    %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
    % DESCRIPTION:
    % Fills the Plot tab's Gain dropdown with the gain patterns the loaded data actually has (see
    % antennaPlotSeries), plus "All (overlay)" when there is more than one. Keeps the current choice when it is
    % still available.
    %
    % INPUT:
    %   app - ARES application object.
    %
    % OUTPUT:
    %   None.
    %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

    series = antennaPlotSeries(app.Antenna_Data);
    items = strings(1, 0);
    if ~isempty(series), items = [series.Label]; end
    if numel(items) > 1
        items(end + 1) = "All (overlay)";
    end
    if isempty(items)
        items = "No gain data";
    end

    current = string(app.GainTypeDropDown.Value);
    app.GainTypeDropDown.Items = cellstr(items);
    if any(items == current)
        app.GainTypeDropDown.Value = char(current);
    else
        app.GainTypeDropDown.Value = char(items(1));
    end
end
