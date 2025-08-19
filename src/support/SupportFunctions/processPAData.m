function combinedData = processPAData(app, combinedData)
    %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
    % DESCRIPTION:
    % Processes Power Amplifier (PA) measurement data by storing it in the app, extracting PSU channel information,
    % updating voltage selections, and refreshing relevant UI elements. Based on the detected measurement type 
    % (CW, Modulated, or Unknown), the function automatically triggers the appropriate plotting routines or 
    % displays an error message if the data format is unrecognized.
    %
    % Example usage:
    %
    %   - combinedData = processPAData(app, combinedData)
    %
    % INPUT:
    %   app          - Handle to the app instance containing UI components and data tables.
    %   combinedData - Table containing PA measurement data. If empty, no processing is performed.
    %
    % OUTPUT:
    %   combinedData - Same as input, returned for consistency.
    %
    % Notes:
    %   - Updates app.PA_DataTable with the provided data.
    %   - Extracts PSU channel numbers and corresponding voltage values from variable names.
    %   - Initializes and updates dropdown selections in the UI.
    %   - Determines PA measurement mode using detectPAMeasurementType and calls the appropriate plotting functions:
    %       * "CW"        → plotPASingleMeasurement, plotPASweepMeasurement, plotPADCMeasurement
    %       * "Modulated" → plotPAModulatedMeasurement, plotPADCMeasurement
    %       * "Unknown"   → Displays error message in UI.
    %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%


    if ~isempty(combinedData)  
        % Remove spaces and special characters from the variable names.
        combinedData.Properties.VariableNames = regexprep(combinedData.Properties.VariableNames, ' ', '');
        combinedData.Properties.VariableNames = regexprep(combinedData.Properties.VariableNames, '(', '');
        combinedData.Properties.VariableNames = regexprep(combinedData.Properties.VariableNames, ')', '');
        combinedData.Properties.VariableNames = regexprep(combinedData.Properties.VariableNames, '%', '');
        combinedData.Properties.VariableNames = regexprep(combinedData.Properties.VariableNames, '[{};]', '');

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

        mode = detectPAMeasurementType(varNames);
        
        if mode == "CW"
            % Plot with updated dropdown values.
            plotPASingleMeasurement(app);
            plotPASweepMeasurement(app);
            plotPADCMeasurement(app);
        elseif mode == "Modulated"
            plotPAModulatedMeasurement(app);
            plotPADCMeasurement(app);
        elseif mode == "Unknown"
            app.displayError("Unknown PA data format which not contains the expected columns.")
        end
    end
end