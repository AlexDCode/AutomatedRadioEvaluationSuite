function fullFilename = saveData(combinedData, combinedNames)
    %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
    % DESCRIPTION:
    % This function saves test data to either a CSV or Excel (.xlsx) file, depending on size and user selection. If
    % the data exceeds Excel's row/column limits, only the CSV option is offered.
    %
    % INPUT:
    %   combinedData  - Either a table or a cell array of measurement vectors (e.g., {frequency, gain, ...}).
    %   combinedNames - Cell array of variable names corresponding to the data (e.g., {'Frequency (Hz)', 'Gain (dB)', ...}).
    %
    % OUTPUT:
    %   fullFilename  - Full path to the saved file, or an empty string if the user cancels the save dialog.
    %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
    
    % Set Excel format limits.
    EXCEL_MAX_ROWS = 1048576;  
    EXCEL_MAX_COLUMNS = 16384;

    % Handle missing second argument.
    if nargin < 2
        combinedNames = '';
    end
    
    % Convert input to table if needed.
    if istable(combinedData)
        dataTable = combinedData;
    else
        dataTable = array2table(combinedData, 'VariableNames', combinedNames);
    end

    % Check if data exceeds Excel limits.
    passedExcelLimit = height(dataTable) >= EXCEL_MAX_ROWS || width(dataTable) > EXCEL_MAX_COLUMNS;

    % Prompt user for save location.
    try
        if passedExcelLimit
            % Prompt the user to save the data into a CSV file
            [filename, path] = uiputfile({'*.csv', 'CSV Files (*.csv)';}, 'Save Data As');
        else
            % Prompt the user to save the data into a CSV or Excel file
            [filename, path] = uiputfile({'*.csv', 'CSV Files (*.csv)';'*.xlsx', 'Excel Files (*.xlsx)'}, 'Save Data As');
        end
    catch ME
        error('Save dialog was canceled.')
    end

    % Handle the user cancelling the saving prompt.
    if isequal(filename, 0) || isequal(path, 0)
        fullFilename = '';
        return;
    end

    % Build full path and save the data.
    fullFilename = fullfile(path, filename);
    writetable(dataTable, fullFilename);
    disp(['Data saved to: ', fullFilename]);
end