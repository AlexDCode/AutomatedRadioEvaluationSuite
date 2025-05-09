function combinedData = loadData(app, RFcomponent, FileName)
    %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
    % DESCRIPTION:
    % This function loads data from a CSV or Excel file containing a single or sweep PA test measurement, or an 
    % Antenna test measurement. 
    %
    % INPUT:
    %   RFcomponent  - Either 'PA', 'Antenna', or 'AntennaReference' depending on which type of measurement is being loaded.
    %   FileName     - The name of the file that will be loaded into the application.
    %
    % OUTPUT:
    %   combinedData - A struct containing all the data from each column of the loaded file. 
    %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
    
    combinedData = struct();
    
    if nargin < 3
        [file, path, ~] = uigetfile({'*.csv;*.xls;*.xlsx', 'Data Files (*.csv, *.xls, *.xlsx)'});
        
        % Check if the user cancel the file selection
        if isequal(file, 0) || isequal(path, 0)
            return;
        end

        FileName = fullfile(path, file);
    end 

    % Store the file path in the base workspace, so user can acces it if needed.
    assignin('base', 'loadedFilePath', FileName);

    try
        % Suppress warning about variable names being modified.
        w = warning('off','MATLAB:table:ModifiedAndSavedVarnames');    

        % Load the table from the file.
        combinedData = readtable(FileName);

        % Reset warning level.
        warning(w);       

        % Remove underscores from the variable names.
        combinedData.Properties.VariableNames = regexprep(combinedData.Properties.VariableNames, '_', '');

        % Proceed based on RFcomponent type.
        switch RFcomponent
            case 'PA'
                combinedData = processPAData(app, combinedData);

            case 'Antenna'
                combinedData = processAntennaData(app, combinedData);

            case 'AntennaReference'
                combinedData = processAntennaReferenceData(app, combinedData, FileName);

            otherwise
                error('Unknown RFComponent type. Valid options are ''PA'', ''Antenna'', or ''AntennaReference''.');
        end
    catch ME
        app.displayError(ME);
    end
end

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
                
        % Plot with updated dropdown values.
        plotPASingleMeasurement(app);
        plotPASweepMeasurement(app);
        plotPADCMeasurement(app);
    end
end

% Modular function to handle Antenna Data
function combinedData = processAntennaData(app, combinedData)
    if ~isempty(combinedData)  
         app.Antenna_Data = combinedData;

         % Check each required field and add to the list if missing.
         expectedVars = {'Thetadeg', 'Phideg', 'FrequencyMHz', 'GaindBi', 'ReturnLossdB', 'ReturnLossdeg'};
         missingFields = setdiff(expectedVars, app.Antenna_Data.Properties.VariableNames);
 
         % Raise an error if any fields are missing. 
         if ~isempty(missingFields)
             error(['The antenna gain file is missing the following required field(s): ', strjoin(missingFields, ', ')]);
         end
    end
end

% Modular function to handle Antenna Reference Data
function combinedData = processAntennaReferenceData(app, combinedData, FileName)
     if ~isempty(combinedData) 
         % Extract antenna measurement parameters from the file.
         idx = (combinedData.Thetadeg==0) & (combinedData.Phideg==0);

         if ~any(idx)
             error('Boresight Gain is not available in the file (Theta=0 and Phi=0)')
         else
             combinedData = combinedData(idx,:);
             app.ReferenceGainFile = combinedData;
             app.ReferenceGainFilePath = FileName;
             
             % Check each required field and add to the list if missing.
             expectedVars = {'Thetadeg', 'Phideg', 'FrequencyMHz', 'GaindBi', 'ReturnLossdB', 'ReturnLossdeg'};
             missingFields = setdiff(expectedVars, app.ReferenceGainFile.Properties.VariableNames);

            % Raise an error if any fields are missing.
            if ~isempty(missingFields)
                error(['The antenna gain file is missing the following required field(s): ', strjoin(missingFields, ', ')]);
            end
         end
     end
end