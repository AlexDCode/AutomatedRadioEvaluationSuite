function ResultsTable = createAntennaResultsTable(totalMeasurements)
    %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
    % DESCRIPTION:
    % This function initializes and preallocates a results table for storing antenna test measurements. The results 
    % table is designed to hold various antenna parameters for a given number of measurements. It contains the 
    % following columns:
    %
    %   - Theta (deg): The theta angle in degrees.
    %   - Phi (deg): The phi angle in degrees.
    %   - Frequency (MHz): The frequency in MHz.
    %   - Gain (dBi): The gain in decibels isotropic (dBi).
    %   - Return Loss (dB): The return loss in decibels.
    %   - Return Loss (deg): The return loss in degrees.
    %   - Return Loss Reference (dB): The reference return loss in decibels.
    %   - Return Loss Reference (deg): The reference return loss in degrees.
    %   - Path Loss (dB): The path loss in decibels.
    %   - Path Loss (deg): The path loss in degrees.
    %
    % INPUT:
    %   totalMeasurements - The total number of measurements (rows) to allocate in the results table. 
    %
    % OUTPUT:
    %   ResultsTable      - The preallocated table.
    %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

    % Add measurements columns.
    varNames = {'Theta (deg)',...
                'Phi (deg)',...
                'Frequency (MHz)',...
            	'Gain (dBi)',...
                'Return Loss (dB)',...
                'Return Loss (deg)',...
                'Return Loss Reference (dB)',...
                'Return Loss Reference (deg)',...
                'Path Loss (dB)',...
                'Path Loss (deg)'
    };
    
    varTypes = repmat({'double'}, 1, length(varNames));
    
    % Create the Antenna results table.
    ResultsTable = table('Size', [totalMeasurements, length(varNames)], ...
                         'VariableTypes', varTypes, ...
                         'VariableNames', varNames);
end
