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
