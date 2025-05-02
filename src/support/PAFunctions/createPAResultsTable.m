function ResultsTable = createPAResultsTable(app, totalMeasurements)
    %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
    % DESCRIPTION:
    % This function initializes an empty results table for Power Amplifier (PA) measurements, with columns 
    % dynamically generated based on the number of active PSU channels configured in the application. 
    % The table is pre-allocated to the specified number of measurements and channels. For n channels:
    %
    %   - Frequency (MHz)
    %   - Channel 1 Voltage (V) (if n = 1)
    %   - ...
    %   - Channel n Voltages (V)
    %   - RF Input Power (dBm)
    %   - RF Output Power (dBm)
    %   - Gain
    %   - Channel 1 DC Power (W) (if n = 1)
    %   - ...
    %   - Channel n DC Power (W)
    %   - Total DC Drain Power (W)
    %   - Total DC Gate Power (W)
    %   - DE (%)
    %   - PAE (%)
    %
    % INPUT:
    %   app               - The app object containing configuration details, including active PSU channels.
    %   totalMeasurements - Total number of rows to preallocate in the results table.
    %
    % OUTPUT:
    %   ResultsTable      - An empty table with predefined variable names and types for storing PA test results.
    %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

    % Add frequency column.
    varNames = {'Frequency (MHz)'};
    
    % Number of channels that will be used.
    numChannels = length(app.FilledPSUChannels);

    % Add voltage columns based on the number of active channels.
    for i = 1:numChannels
        varNames{end+1} = sprintf('Channel %d Voltages (V)', i); %#ok<AGROW>
    end
    
    % Add measurement columns independent of active channels.
    varNames = [varNames, 'RF Input Power (dBm)', 'RF Output Power (dBm)', 'Gain'];
    
    % Add DC power coumns based on the number of active channels.
    for i = 1:numChannels
        varNames{end+1} = sprintf('Channel %d DC Power (W)', i); %#ok<AGROW>
    end
    
    % Add total DC drain power if there are multiple channels.
    if numChannels > 1
        varNames{end+1} = 'Total DC Drain Power (W)';
        varNames{end+1} = 'Total DC Gate Power (W)';
    end
        
    % Add efficiency columns independent of active channels.
    varNames = [varNames, 'DE (%)', 'PAE (%)'];
    varTypes = repmat({'double'}, 1, length(varNames));
    
    % Create the PA results table.
    ResultsTable = table('Size', [totalMeasurements, length(varNames)], ...
                         'VariableTypes', varTypes, ...
                         'VariableNames', varNames);
end
