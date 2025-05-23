function plotPASingleMeasurement(app)
    %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
    % DESCRIPTION:
    % This function plots gain, drain efficiency (DE), and power-added efficiency (PAE) versus RF output power for
    % a single frequency measurement. Also overlays peak values such as Psat, -1 dB and -3 dB compression points.
    % This function generates a dual y-axis plot:
    % 
    %   - Left Y axis: Gain (dB) 
    %   -- Green X: Psat (saturation output power)
    %   -- Red X: -1 dB gain compression point 
    %   -- Blue X: -3 dB gain compression point
    %   - Right Y axis: DE and PAE (%)
    %
    % INPUT:
    %   app  - Application object containing PA measurement data, user-selected frequency, supply voltages, and plotting handles.
    %
    % OUTPUT:
    %   None
    %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

    ax = app.SingleFrequencyPAPlot;
    cla(ax, "reset");
    clear legendEntries legendHandles;
    
    % Index the plot for the selected supply voltages.
    idx = true(height(app.PA_DataTable), 1);
    for i = 1:length(app.PA_PSU_SelectedVoltages)
        idx_i = app.PA_DataTable.(sprintf('Channel%dVoltagesV', app.PA_PSU_Channels(i))) == app.PA_PSU_SelectedVoltages(i);
        idx = idx & idx_i;
    end

    % Index the plot for the selected frequency
    idx_freq = (app.PA_DataTable.FrequencyMHz == str2double(app.FrequencySingleDropDown.Value));
    idx = idx & idx_freq;

    % Filtered PA data using the index.
    PATable = app.PA_DataTable(idx, :);

    % Shared plot settings.
    title(ax, sprintf('Gain and Efficiency at %s MHz', app.FrequencySingleDropDown.Value), 'FontWeight', 'bold');
    xlabel(ax, 'Output Power (dBm)', 'FontWeight', 'bold');
    
    % Plot DE and PAE on the right y-axis.
    yyaxis(ax, 'right');
    h1 = plot(ax, PATable.RFOutputPowerdBm, PATable.DE, 'b-');
    hold(ax, 'on');
    h2 = plot(ax, PATable.RFOutputPowerdBm, PATable.PAE, 'r--');
    ylabel(ax, 'Efficiency (%)', 'FontWeight', 'bold');

    % Plot Gain on the left y-axis.
    yyaxis(ax, 'left');
    h3 = plot(ax, PATable.RFOutputPowerdBm, PATable.Gain, 'k-');
    ylabel(ax, 'Gain (dB)', 'FontWeight', 'bold');

    % Initialize legend entries.
    legendEntries = {'DE', 'PAE', 'Gain'};
    legendHandles = [h1, h2, h3];
    
    % Get the peak values.
    [Psat, ~, ~, ~, compression1dB, compression3dB] = measureRFParametersPeaks(app,idx);

    % Plot Psat as a green X.
    [legendHandles, legendEntries] = plotPeakMarkers(ax, Psat, 'gx', 'P_{sat}', legendHandles, legendEntries);
    % Plot -1dB point as a red X.
    [legendHandles, legendEntries] = plotPeakMarkers(ax, compression1dB, 'rx', 'P_{-1 dB}', legendHandles, legendEntries);
    % Plot -3dB point as a blue X.
    [legendHandles, legendEntries] = plotPeakMarkers(ax, compression3dB, 'bx', 'P_{-3 dB}', legendHandles, legendEntries);

    % Tighten and improve the axes appearance.
    axis(ax,'tight')
    improveAxesAppearance(ax, 'YYAxis', true, 'LineThickness', 2);

    if numel(legendHandles) == numel(legendEntries)
        lgd = legend(ax, legendHandles, legendEntries, 'Location', 'west');
        lgd.Box = 'on';
        lgd.FontSize = 12;
    else
        error('Mismatch between legend handles and entries.');
    end
end

% Helper function to plot peak markers (Psat, compression points).
function [legendHandles, legendEntries] = plotPeakMarkers(ax, peakData, markerStyle, label, legendHandles, legendEntries)
    for i = 1:height(peakData)
        h = plot(ax, peakData(i,:).RFOutputPowerdBm, peakData(i,:).Gain, markerStyle, 'MarkerSize', 8, 'LineWidth', 2);
        legendHandles(end+1) = h; %#ok<AGROW>
        legendEntries{end+1} = label; %#ok<AGROW>
    end
end
