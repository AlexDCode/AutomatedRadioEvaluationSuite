function plotPAModulatedMeasurement(app)
    %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
    % DESCRIPTION:
    % This function plots.....
    %
    % INPUT:
    %   app  - Application object containing PA measurement data, user-selected frequency, supply voltages, and plotting handles.
    %
    % OUTPUT:
    %   None
    %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

    cla(app.AverageGainEfficiencyPlot, "reset");
    cla(app.OutputSpectrumPlot, "reset");
    cla(app.OccupiedBandwidthPlot, "reset");
    cla(app.ChannelPowerACPRPlot, "reset");

    % Index the selected frequency and supply voltages
    if str2double(app.FrequencySingleDropDown.Value) > 0
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
    else
        PATable = NaN;
    end

    if height(PATable) > 0


        % Spectrum Plot
        ax = app.OutputSpectrumPlot;
        hold(ax, 'on');

        % Shared plot settings.
        title(ax, sprintf('Output Spectrum at %s MHz', app.FrequencySingleDropDown.Value), 'FontWeight', 'bold');
        xlabel(ax, 'Frequency Offset (MHz)', 'FontWeight', 'bold');
        ylabel(ax, 'Power Spectral Density (dBm/Hz)', 'FontWeight', 'bold');

        % Plot DE and PAE on the right y-axis.

        
        for i = 1:height(PATable)
            PSD = string2table(PATable.RFOutputPowerSpectrumFrequencyAverageMaximumdBm(i));
            channelBW = PATable.OutputOccupiedBandwidthMHz(i)*1e6;

            PSD.Properties.VariableNames = {'FrequencyHz','AveragedBm','MaximumdBm'};
            keyName = string(round(PATable.RFOutputChannelPowerdBm(i), 2));

            plot(ax, (PSD.FrequencyHz/1e6 - str2double(app.FrequencySingleDropDown.Value)), ...
                PSD.AveragedBm - 10*log10(channelBW), 'DisplayName',keyName);
        end
        hold(ax, 'off');
        lgd = legend(ax);
        lgd.Title.Visible = 'on';
        lgd.Title.String = 'Channel Power (dBm)';
        enableLegendToggle(lgd);

        improveAxesAppearance(app, ax);
    end
end