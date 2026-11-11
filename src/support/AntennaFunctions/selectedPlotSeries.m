function series = selectedPlotSeries(app)
    %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
    % DESCRIPTION:
    % The gain pattern(s) picked in the Plot tab's Gain dropdown: one series, or all of them for
    % "All (overlay)". Falls back to the first available series if the dropdown's choice is not in the data
    % (e.g. right after loading a different file).
    %
    % INPUT:
    %   app    - ARES application object.
    %
    % OUTPUT:
    %   series - struct array from antennaPlotSeries (empty if the data has nothing to plot).
    %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

    series = antennaPlotSeries(app.Antenna_Data);
    if isempty(series), return; end

    choice = string(app.GainTypeDropDown.Value);
    if choice == "All (overlay)"
        return;
    end
    pick = [series.Label] == choice;
    if any(pick)
        series = series(pick);
    else
        series = series(1);
    end
end
