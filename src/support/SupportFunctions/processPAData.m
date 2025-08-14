% Modular function to handle PA Data
function combinedData = processPAData(app, combinedData)
    if ~isempty(combinedData)  
        app.PA_DataTable = combinedData;

        % Find PSU channel numbers.
        varNames = app.PA_DataTable.Properties.VariableNames;
        matches = regexp(varNames, '^Channel(\d+)VoltagesV$', 'tokens');
    
        % Flatten the list and convert to numeric.
        app.PA_PSU_Channels = cellfun(@(x) str2double(x{1}), matches(~cellfun('isempty', matches)));
    
        % Get the voltages for each PSU.
        app.PA_PSU_SelectedVoltages = zeros(numel(app.PA_PSU_Channels),1);
        app.PA_PSU_Voltages = struct();
        for i = 1:numel(app.PA_PSU_Channels)
            chNum = app.PA_PSU_Channels(i);
            chName = sprintf('Channel%dVoltagesV', chNum);
            app.PA_PSU_Voltages.(chName) = unique(app.PA_DataTable.(chName));
            app.PA_PSU_SelectedVoltages(chNum) = app.PA_PSU_Voltages.(chName)(1);
        end

        % Update dropdown values to match the data.
        updatePAPlotDropdowns(app);

        mode = detectMeasurement(varNames);
        
        if mode == "CW"
            % Plot with updated dropdown values.
            plotPASingleMeasurement(app);
            plotPASweepMeasurement(app);
            plotPADCMeasurement(app);
        elseif mode == "Modulated"
            plotPAModulatedMeasurement(app);
        elseif mode == "Unknown"
            app.displayError("Unknown PA data format which not contains the expected columns.")
        end
    end
end

function mode = detectMeasurement(varNames)
    % Define keyword groups
    cwKeywords = {'RFOutputPowerdBm', 'DE', 'PAE'};
    modulatedKeywords = {'AverageGaindB', 'RFInputChannelPowerdBm', 'RFOutputChannelPowerdBm', ...
        'InputOccupiedBandwidth', 'OutputOccupiedBandwidth', 'AverageDE', 'AveragePAE', ...
        'InputACPRLowerUpperdBc' ,'OutputACPRLowerUpperdBc',...
        'RFInputPowerSpectrumFrequencyAverageMaximumdBm', ...
        'RFOutputPowerSpectrumFrequencyAverageMaximumdBm'};

    % Check presence in variable names
    hasCW = any(ismember(cwKeywords, varNames));
    hasModulated = any(ismember(modulatedKeywords, varNames));

    % Set mode
    if hasModulated
        mode = 'Modulated';
    elseif hasCW
        mode = 'CW';
    else
        mode = 'Unknown';
    end
end