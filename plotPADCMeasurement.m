function plotPADCMeasurement(app)
    %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
    % DESCRIPTION:
    % This function plots DC performance metrics from a frequency sweep Power Amplifier (PA) measurement, including
    % drain currents (IDD) and drain DC power. It filters the PA dataset using user-selected supply voltages and 
    % generates the plots with styled axes and markers for clarity:
    %
    %   - Supply Current vs. Output Power for each frequency
    %   - DC Supply Power vs. Output Power for each frequency
    %   - Peak Drain Current vs. Frequency
    %   - Peak DC Supply Power vs. Frequency
    %
    % INPUT:
    %   app  - Application object containing PA measurement data and plotting components.
    %
    % OUTPUT:
    %   None
    %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

    % Clear existing plots.
    cla(app.PASupplyCurrentPlot, "reset");
    cla(app.PASupplyPowerPlot, "reset");
    cla(app.PAPeakSupplyCurrentPlot, "reset");
    cla(app.PAPeakSupplyPowerPlot, "reset");
    clear legendEntries legendHandles;

    % Index the plot for the selected supply voltages.
    idx = true(height(app.PA_DataTable), 1);
    for i = 1:length(app.PA_PSU_SelectedVoltages)
        idx_i = app.PA_DataTable.(sprintf('Channel%dVoltagesV', app.PA_PSU_Channels(i))) == app.PA_PSU_SelectedVoltages(i);
        idx = idx & idx_i;
    end

    % Index the plot for the selected frequency
    idx_freq = (app.PA_DataTable.FrequencyMHz == str2double(app.FrequencySingleDropDown.Value));
    
    % Frequencies to iterate over.
    freqs = unique(app.PA_DataTable(idx, "FrequencyMHz"));


    % 1) Plot Drain Current vs. Output Power
    hold(app.PASupplyCurrentPlot, 'on');

    for i = 1:length(app.PA_PSU_SelectedVoltages)
        idxPSU = app.PA_DataTable.(sprintf('Channel%dVoltagesV', app.PA_PSU_Channels(i))) == app.PA_PSU_SelectedVoltages(i);
        plot(app.PASupplyCurrentPlot, app.PA_DataTable(idx & idx_freq & idxPSU,:).RFOutputPowerdBm, ...
             app.PA_DataTable(idx & idx_freq & idxPSU,:).(sprintf('Channel%dDCCurrentA', app.PA_PSU_Channels(i))), ...
             'DisplayName',  sprintf('Channel %d', app.PA_PSU_Channels(i))); 
    end

    plot(app.PASupplyCurrentPlot, app.PA_DataTable(idx & idx_freq & idxPSU,:).RFOutputPowerdBm, app.PA_DataTable(idx & idx_freq & idxPSU,:).TotalDCDrainCurrentA, ...
        'DisplayName', 'Total Drain'); 
    plot(app.PASupplyCurrentPlot, app.PA_DataTable(idx & idx_freq & idxPSU,:).RFOutputPowerdBm, app.PA_DataTable(idx & idx_freq & idxPSU,:).TotalDCGateCurrentA, ...
        'DisplayName', 'Total Gate'); 
    legend(app.PASupplyCurrentPlot,'Location','best');

    % Labels
    hold(app.PASupplyCurrentPlot, 'off');
    title(app.PASupplyCurrentPlot, 'DC Supply Current');
    xlabel(app.PASupplyCurrentPlot, 'Output Power (dBm)');
    ylabel(app.PASupplyCurrentPlot, 'DC Current (A)');
    axis(app.PASupplyCurrentPlot,'tight')

    % 2) Plot Supply Power vs. Output Power
    hold(app.PASupplyPowerPlot, 'on'); 

    for i = 1:length(app.PA_PSU_SelectedVoltages)
        idxPSU = app.PA_DataTable.(sprintf('Channel%dVoltagesV', app.PA_PSU_Channels(i))) == app.PA_PSU_SelectedVoltages(i);
        plot(app.PASupplyPowerPlot, app.PA_DataTable(idx & idx_freq & idxPSU,:).RFOutputPowerdBm, ...
             app.PA_DataTable(idx & idx_freq & idxPSU,:).(sprintf('Channel%dDCPowerW', app.PA_PSU_Channels(i))), ...
             'DisplayName',  sprintf('Channel %d', app.PA_PSU_Channels(i))); 
    end

    plot(app.PASupplyPowerPlot, app.PA_DataTable(idx & idx_freq & idxPSU,:).RFOutputPowerdBm, app.PA_DataTable(idx & idx_freq & idxPSU,:).TotalDCDrainPowerW, ...
        'DisplayName', 'Total Drain'); 
    plot(app.PASupplyPowerPlot, app.PA_DataTable(idx & idx_freq & idxPSU,:).RFOutputPowerdBm, app.PA_DataTable(idx & idx_freq & idxPSU,:).TotalDCGatePowerW, ...
        'DisplayName', 'Total Gate'); 
    legend(app.PASupplyPowerPlot,'Location','best');

    % Labels
    hold(app.PASupplyPowerPlot, 'off');
    title(app.PASupplyPowerPlot, 'DC Supply Power');
    xlabel(app.PASupplyPowerPlot, 'Output Power (dBm)');
    ylabel(app.PASupplyPowerPlot, 'DC Power (W)');
    axis(app.PASupplyPowerPlot,'tight')

    % 3) Plot Peak Curent vs. Frequency
    hold(app.PAPeakSupplyCurrentPlot, 'on');

    PeakSupply = array2table(zeros(height(freqs),1), "VariableNames",{'FrequencyMHz'});
    for i = 1:height(freqs)
        % Get temporary subtable for each frequency.
        idx_freq = app.PA_DataTable.FrequencyMHz == freqs.FrequencyMHz(i);
        PeakSupply.FrequencyMHz(i) = freqs.FrequencyMHz(i);
        PeakSupply.(sprintf("Drain"))(i) = max(app.PA_DataTable(idx & idx_freq, :).TotalDCDrainCurrentA);
        PeakSupply.(sprintf("Gate"))(i) = max(app.PA_DataTable(idx & idx_freq, :).TotalDCGateCurrentA);
        for j = 1:length(app.PA_PSU_SelectedVoltages)
            idxPSU = app.PA_DataTable.(sprintf('Channel%dVoltagesV', app.PA_PSU_Channels(j))) == app.PA_PSU_SelectedVoltages(j);
            PeakSupply.(sprintf('Channel %d', app.PA_PSU_Channels(j)))(i) = max(app.PA_DataTable(idxPSU & idx_freq,:).(sprintf('Channel%dDCCurrentA', app.PA_PSU_Channels(j))));
        end
    end

    for i = 2:width(PeakSupply)
        plot(app.PAPeakSupplyCurrentPlot, PeakSupply.FrequencyMHz, PeakSupply(:,i).Variables, 'DisplayName', string(PeakSupply(:,i).Properties.VariableNames));
    end
    
    % Labels
    hold(app.PAPeakSupplyCurrentPlot, 'off');
    title(app.PAPeakSupplyCurrentPlot, 'Peak DC Supply Current');
    xlabel(app.PAPeakSupplyCurrentPlot, 'Frequency (MHz)');
    ylabel(app.PAPeakSupplyCurrentPlot, 'DC Current (A)');
    axis(app.PAPeakSupplyCurrentPlot,'tight');
    legend(app.PAPeakSupplyCurrentPlot,'Location','best');

    % 4) Plot Peak Supply Power vs. Frequency
    hold(app.PAPeakSupplyPowerPlot, 'on'); 

    PeakSupply = array2table(zeros(height(freqs),1), "VariableNames",{'FrequencyMHz'});
    for i = 1:height(freqs)
        % Get temporary subtable for each frequency.
        idx_freq = app.PA_DataTable.FrequencyMHz == freqs.FrequencyMHz(i);
        PeakSupply.FrequencyMHz(i) = freqs.FrequencyMHz(i);
        PeakSupply.(sprintf("Drain"))(i) = max(app.PA_DataTable(idx & idx_freq, :).TotalDCDrainPowerW);
        PeakSupply.(sprintf("Gate"))(i) = max(app.PA_DataTable(idx & idx_freq, :).TotalDCGatePowerW);
        for j = 1:length(app.PA_PSU_SelectedVoltages)
            idxPSU = app.PA_DataTable.(sprintf('Channel%dVoltagesV', app.PA_PSU_Channels(j))) == app.PA_PSU_SelectedVoltages(j);
            PeakSupply.(sprintf('Channel %d', app.PA_PSU_Channels(j)))(i) = max(app.PA_DataTable(idxPSU & idx_freq,:).(sprintf('Channel%dDCPowerW', app.PA_PSU_Channels(j))));
        end
    end

    for i = 2:width(PeakSupply)
        plot(app.PAPeakSupplyPowerPlot, PeakSupply.FrequencyMHz, PeakSupply(:,i).Variables, 'DisplayName', string(PeakSupply(:,i).Properties.VariableNames));
    end

    % Labels
    hold(app.PAPeakSupplyPowerPlot, 'off');
    title(app.PAPeakSupplyPowerPlot, 'Peak DC Supply Power');
    xlabel(app.PAPeakSupplyPowerPlot, 'Frequency (MHz)');
    ylabel(app.PAPeakSupplyPowerPlot, 'DC Power (W)');
    axis(app.PAPeakSupplyPowerPlot,'tight');
    legend(app.PAPeakSupplyPowerPlot,'Location','best');

    % Improves the appearance of each plot, can adjust the line thickness/width as desired.
    improveAxesAppearance(app.PASupplyCurrentPlot, 'LineThickness', 2);
    improveAxesAppearance(app.PASupplyPowerPlot, 'LineThickness', 2);
    improveAxesAppearance(app.PAPeakSupplyCurrentPlot, 'LineThickness', 2);
    improveAxesAppearance(app.PAPeakSupplyPowerPlot, 'LineThickness', 2);
end