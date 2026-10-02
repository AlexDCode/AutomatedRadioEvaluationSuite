function plotNPortAntenna(app)
    %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
    % DESCRIPTION:
    % Plots the currently selected n-port quantity from app.Antenna_Data (the
    % long/tidy results table) onto the app's n-port axes, one line per
    % (device, port/path) series versus frequency at boresight.
    %
    % Reads these app components (all optional — the function no-ops on any that
    % are missing, so it is safe to add before the App Designer UI exists):
    %   app.NPortPlot             - uiaxes to draw on (REQUIRED to draw)
    %   app.NPortQuantityDropDown - which Quantity to show (default Gain (dBi))
    %
    % INPUT:
    %   app - ARES application object.
    %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

    if ~isprop(app, 'Antenna_Data') || isempty(app.Antenna_Data), return; end
    if ~isprop(app, 'NPortPlot'), return; end

    quantity = "Gain (dBi)";
    if isprop(app, 'NPortQuantityDropDown') && ~isempty(app.NPortQuantityDropDown.Value)
        quantity = string(app.NPortQuantityDropDown.Value);
    end

    series = selectNPortSeries(app.Antenna_Data, quantity);

    ax = app.NPortPlot;
    cla(ax);
    hold(ax, 'on');
    labels = strings(1, numel(series));
    for k = 1:numel(series)
        plot(ax, series(k).FreqMHz, series(k).Value);
        labels(k) = series(k).Label;
    end
    hold(ax, 'off');

    xlabel(ax, 'Frequency (MHz)');
    ylabel(ax, quantity);
    title(ax, quantity);
    if ~isempty(series)
        legend(ax, labels, 'Location', 'best');
    else
        legend(ax, 'off');
    end
end
