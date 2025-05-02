function ParametersTable = createPAParametersTable(app)
    %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
    % DESCRIPTION:
    % This function generates a complete parameter sweep table for Power Amplifier (PA) testing. It creates all 
    % possible combinations of frequency, RF input power, voltage, and current based on the sweep settings 
    % defined in the application for each active PSU channel. The resulting table is used to drive automated PA 
    % characterization across various operating conditions, it contains the following columns:
    %
    %   - Frequency (Hz)
    %   - RF Input Power (dBm)
    %   - Voltage (V) and Current (A) per active PSU channel
    %
    % INPUT:
    %   app - App object containing configuration parameters for frequency, RF input power, and pwower supply settings.
    %
    % OUTPUT:
    %   ParametersTable - The resulting parameters table containing all combinations of PA test settings.
    %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

    % Frequency settings.
    if strcmp(app.PAFrequencyMeasurementMode, 'Sweep Frequencies')
        frequencies = app.StartFrequency.Value*1E6 : app.StepFrequency.Value*1E6 : app.EndFrequency.Value*1E6;
    else
        frequencies = app.StartFrequency.Value * 1E6;
    end

    % RF power settings.
    RFInputPower = app.StartPower.Value : app.PowerStep.Value : app.EndPower.Value;

    % Number of active PSU channels that will be used and voltage/current
    % containers.
    numChannels = length(app.FilledPSUChannels);
    voltageSets = cell(1, numChannels);
    currentSets = cell(1, numChannels); 
    
    % Build the variable names dynamically depnding on the number of
    % channels that will be used in the PA test.
    varNames = [{'Frequency', 'RF Input Power'},... 
               arrayfun(@(i) {sprintf('Channel %d Voltage', i), ...
                              sprintf('Channel %d Current', i) }, ...
               1:numChannels, 'UniformOutput', false)];
    varNames = horzcat(varNames{:});
    
    % Populate the voltage/current containers using the values set by the
    % user in the app.
    for i = 1:numChannels
        channel = app.FilledPSUChannels{i};
        settings = app.ChannelNames.(channel);
    
        if strcmp(settings.Mode, 'Sweep')
            voltageSets{i} = settings.Start : settings.Step : settings.Stop;
        else
            voltageSets{i} = settings.Start; 
        end
    
        currentSets{i} = settings.Current;
    end
    
    % Create the full test parameters grid.
    VCSets = reshape([voltageSets; currentSets], 1, []);
    gridInputs = [{RFInputPower, frequencies}, VCSets];
    grids = cell(1, numel(gridInputs));
    [grids{:}] = ndgrid(gridInputs{:});
    
    % Reshape into combinations: Frequency, Power, V1, C1, V2, C2, ...
    combinations = [grids{2}(:), grids{1}(:), cell2mat(cellfun(@(g) g(:), grids(3:end), 'UniformOutput', false))];
    
    % Create the PA parameters table.
    ParametersTable = array2table(combinations, 'VariableNames', varNames);
end