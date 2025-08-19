function plotPAModulatedMeasurement(app)
    %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
    % DESCRIPTION:
    % This function plots results of modulated power amplifier (PA) measurements at a selected frequency and supply
    % voltages. The function generates multiple plots in the app interface to visualize gain, efficiency, output 
    % spectrum, occupied bandwidth, and adjacent channel power ratio (ACPR). Specifically:
    %
    %   - Average Gain and Efficiency Plot:
    %       - Left Y axis: Average Gain (dB)
    %       - Right Y axis: Average Drain Efficiency (DE) and Power Added Efficiency (PAE) (%)
    %
    %   - Output Spectrum Plot:
    %       - Frequency offset (MHz) versus Power Spectral Density (dBm/Hz)
    %       - Plots averaged power spectrum for each channel output power
    %
    %   - Occupied Bandwidth Plot:
    %       - Channel Power (dBm) versus Input/Output Occupied Bandwidth (MHz)
    %
    %   - Channel Power and ACPR Plot:
    %       - Channel Power (dBm) versus ACPR (dBc)
    %       - Plots both input and output ACPR for all channels
    %
    % INPUT:
    %   app  - Application object containing PA measurement data, user-selected frequency, supply voltages, and plotting handles.
    %
    % OUTPUT:
    %   None
    %
    % NOTES:
    %   - Clears existing axes before plotting.
    %   - Filters measurement data based on selected frequency and supply voltages.
    %   - Uses local helper function `assignACPRVariables` to standardize ACPR table column names.
    %   - Automatically adjusts legends and axis appearance using `improveAxesAppearance`.
    %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

    cla(app.AverageGainEfficiencyPlot, "reset");
    cla(app.OutputSpectrumPlot, "reset");
    cla(app.OccupiedBandwidthPlot, "reset");
    cla(app.ChannelPowerACPRPlot, "reset");

    %% Index the selected frequency and supply voltages
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
        %% Average Gain and Efficiency
        ax = app.AverageGainEfficiencyPlot;

        % Shared plot settings.
        title(ax, 'Average Gain and Efficiency', 'FontWeight', 'bold');
        xlabel(ax, 'Channel Power (dBm)', 'FontWeight', 'bold');

        yyaxis(ax, 'right');
        plot(ax, PATable.RFOutputChannelPowerdBm, PATable.AverageDE, 'DisplayName','Average DE');
        hold(ax, 'on');
        plot(ax, PATable.RFOutputChannelPowerdBm, PATable.AveragePAE, '--', 'DisplayName','Average PAE');
        ylabel(ax, 'Efficiency (%)', 'FontWeight', 'bold');

        yyaxis(ax, 'left');
        ThemeStatus = regexp(app.CurrentThemeLabel.Text, '(light|dark)', 'match');
        if strcmp(ThemeStatus{1}, 'light')
            plot(ax, PATable.RFOutputChannelPowerdBm, PATable.AverageGaindB, '-k', 'DisplayName','Channel Gain');
        elseif strcmp(ThemeStatus{1}, 'dark')
            plot(ax, PATable.RFOutputChannelPowerdBm, PATable.AverageGaindB, '-w', 'DisplayName','Channel Gain');
        else
            plot(ax, PATable.RFOutputChannelPowerdBm, PATable.AverageGaindB, 'DisplayName','Gain');
        end
        ylabel(ax, 'Gain (dB)', 'FontWeight', 'bold');

        hold(ax, 'off');
        lgd = legend(ax);
        lgd.Title.Visible = 'on';
        lgd.Title.String = 'Channel Power (dBm)';
        enableLegendToggle(lgd);
        
        axis(ax, "tight");
        improveAxesAppearance(app, ax,'LineThickness', 2, 'YYAxis', true);

        %% Spectrum Plot
        ax = app.OutputSpectrumPlot;
        hold(ax, 'on');

        % Shared plot settings.
        title(ax, sprintf('Output Spectrum at %s MHz', app.FrequencySingleDropDown.Value), 'FontWeight', 'bold');
        xlabel(ax, 'Frequency Offset (MHz)', 'FontWeight', 'bold');
        ylabel(ax, 'Power Spectral Density (dBm/Hz)', 'FontWeight', 'bold');

        h = gobjects(height(PATable), 1);           % Preallocate graphics object array
        for i = 1:height(PATable)
            PSD = string2table(PATable.RFOutputPowerSpectrumFrequencyAverageMaximumdBm(i));
            channelBW = PATable.OutputOccupiedBandwidthMHz(i)*1e6;

            PSD.Properties.VariableNames = {'FrequencyHz','AveragedBm','MaximumdBm'};
            keyName = string(round(PATable.RFOutputChannelPowerdBm(i), 2));

            h(i) = plot(ax, (PSD.FrequencyHz/1e6 - str2double(app.FrequencySingleDropDown.Value)), ...
                PSD.AveragedBm - 10*log10(channelBW), 'DisplayName',keyName);
        end
        hold(ax, 'off');
        lgd = legend(ax,Location="bestoutside");
        lgd.Title.Visible = 'on';
        lgd.Title.String = 'Channel Power (dBm)';
        enableLegendToggle(lgd);
        addLineAndLegendContextMenu(h, lgd);
        
        axis(ax, "tight");
        improveAxesAppearance(app, ax);

        %% Occupied Bandwidth
        ax = app.OccupiedBandwidthPlot;
        hold(ax, 'on');

        % Shared plot settings.
        title(ax, 'Occupied Bandwidth', 'FontWeight', 'bold');
        xlabel(ax, 'Channel Power (dBm)', 'FontWeight', 'bold');
        ylabel(ax, 'Channel Bandwidth (MHz)', 'FontWeight', 'bold');

        if ~all(isnan(PATable.OutputOccupiedBandwidthMHz))
            plot(ax, PATable.RFOutputChannelPowerdBm, PATable.OutputOccupiedBandwidthMHz, 'DisplayName','Output')
        end
        if ~all(isnan(PATable.InputOccupiedBandwidthMHz))
            plot(ax, PATable.RFOutputChannelPowerdBm, PATable.InputOccupiedBandwidthMHz, 'DisplayName','Input')
        end
        hold(ax, 'off');
        lgd = legend(ax);
        lgd.Title.Visible = 'on';
        lgd.Title.String = 'Channel Power (dBm)';
        enableLegendToggle(lgd);
        
        axis(ax, "tight");
        improveAxesAppearance(app, ax,'LineThickness', 2);

        %% ACPR
        ax = app.ChannelPowerACPRPlot;
        hold(ax, 'on');

        % Shared plot settings.
        title(ax, sprintf('Channel Power and ACPR at %d MHz', str2double(app.FrequencySingleDropDown.Value)), 'FontWeight', 'bold');
        xlabel(ax, 'Channel Power (dBm)', 'FontWeight', 'bold');
        ylabel(ax, 'ACPR (dBc)', 'FontWeight', 'bold');
        
        % Load ACPR data and assign variable names
        inputACPR = string2table(PATable.InputACPRLowerUpperdBc);
        outputACPR = string2table(PATable.OutputACPRLowerUpperdBc);
        inputACPR = assignACPRVariables(inputACPR);
        outputACPR = assignACPRVariables(outputACPR);
        
        % Add test frequency to the table
        if ~all(string(table2cell(inputACPR)) == "NaN", 'all')
            inputACPR = [table(PATable.RFOutputChannelPowerdBm, 'VariableNames', {'RFOutputChannelPowerdBm'}) inputACPR];

            for i = 2:width(inputACPR)
                plot(ax, inputACPR.RFOutputChannelPowerdBm, table2array(inputACPR(:,i)), ...
                    'DisplayName', sprintf('Input %s' ,string(inputACPR(:,i).Properties.VariableNames)))
            end
        end
        if ~all(string(table2cell(outputACPR)) == "NaN", 'all')
            outputACPR = [table(PATable.RFOutputChannelPowerdBm, 'VariableNames', {'RFOutputChannelPowerdBm'}) outputACPR];

            for i = 2:width(outputACPR)
                plot(ax, outputACPR.RFOutputChannelPowerdBm, table2array(outputACPR(:,i)), ...
                    'DisplayName', sprintf('Output %s' ,string(outputACPR(:,i).Properties.VariableNames)))
            end
        end
        
        lgd = legend(ax);
        lgd.Title.Visible = 'on';
        enableLegendToggle(lgd);

        axis(ax, "tight");
        improveAxesAppearance(app, ax,'LineThickness', 2);
       
    end
end

function tbl = assignACPRVariables(tbl)
    %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
    % DESCRIPTION:
    % This function renames the ACPR variables of a given table with a structured pattern:
    %
    %   - First half of columns: Lower N/2 down to Lower 1
    %   - Second half of columns: Upper 1 up to Upper N/2
    %
    % For example, if the table has 6 variables, the new names will be:
    %   {'Lower 3', 'Lower 2', 'Lower 1', 'Upper 1', 'Upper 2', 'Upper 3'}
    %
    % INPUT:
    %   tbl - A MATLAB table with an even number of variables (columns).
    %
    % OUTPUT:
    %   tbl - The input table with updated variable names following the described pattern.
    %
    % NOTES:
    %   - The function assumes the table has an **even number of variables**.
    %   - If the number of variables is odd, the function will throw an error.
    %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

    % Number of variables
    nVars = width(tbl);

    % Validate even number of variables
    if mod(nVars, 2) ~= 0 && nVars > 1
        error('The table must have an even number of variables.');
    end
    if nVars > 1
        % Compute half
        halfN = nVars / 2;
    
        % Create variable names
        lowerNames = arrayfun(@(k) sprintf('Lower %d', k), halfN:-1:1, 'UniformOutput', false);
        upperNames = arrayfun(@(k) sprintf('Upper %d', k), 1:halfN, 'UniformOutput', false);

        % Combine
        newNames = [lowerNames upperNames];
    elseif nVars == 1
        newNames = {'ACPR'};
    end

    % Assign to table
    tbl.Properties.VariableNames = newNames;
end