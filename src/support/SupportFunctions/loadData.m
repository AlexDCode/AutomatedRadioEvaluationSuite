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

        % Metadata block above a DATA line (setup + port map), if the file has one.
        header = readMeasurementHeader(FileName);
        assignin('base', 'loadedFileHeader', header);

        if isNPortWideFile(FileName)
            % Compact two-header-row n-port format -> melt back to the long/tidy
            % table the rest of ARES consumes (already compact-named).
            combinedData = nportReadWide(FileName);
        else
            % Load the table from the file (skipping any metadata header).
            combinedData = readMeasurementTable(FileName);

            % Remove underscores from the variable names.
            combinedData.Properties.VariableNames = regexprep(combinedData.Properties.VariableNames, '_', '');
        end

        % Reset warning level.
        warning(w);

        % Show the port map an n-port antenna file was measured with.
        if strcmp(RFcomponent, 'Antenna')
            restorePortMap_(app, header);
        end

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

function restorePortMap_(app, header)
    % Put the file's port map into the VNA-tab port table. Legacy 2-port files
    % are left alone (that run used no port table), and the table keeps its
    % current number of rows so a 4-port table stays 4 rows.
    if ~isfield(header, 'PortMap') || isempty(header.PortMap), return; end
    pm = header.PortMap;
    if pm.isLegacyTwoPort() || ~isprop(app, 'PortMapTable'), return; end

    nRows = pm.NumPorts;
    if istable(app.PortMapTable.Data)
        nRows = max(nRows, height(app.PortMapTable.Data));
    end
    shown = PortMap(nRows);
    for e = pm.Ports
        shown.setPort(e.Port, e.Direction, e.Role, e.GainFile, e.GainColumn);
    end
    setPortMapTable(app, shown);

    % The next run uses this table, so make sure it is on screen.
    if isprop(app, 'PortMapPanel'), app.PortMapPanel.Visible = 'on'; end
    if isprop(app, 'AdvancedSetupButton'), app.AdvancedSetupButton.Text = 'Hide Advanced Setup'; end
end
