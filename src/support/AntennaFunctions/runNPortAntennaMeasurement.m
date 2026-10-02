function runNPortAntennaMeasurement(app, cfg)
    %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
    % DESCRIPTION:
    % General n-port (e.g. 4-port) antenna measurement sweep. Dispatched from
    % runAntennaMeasurement whenever the configured PortMap is not the legacy
    % 2-port shape. For each angular position it reads the complex
    % S-parameters the PortMap needs, computes per-path gain, non-reciprocity
    % and radiation efficiency, and accumulates them into the long/tidy results
    % table (createNPortResultsTable). Data is saved and reloaded into the app.
    %
    % The per-position measurement + math lives in tested, hardware-free
    % helpers (measureComplexByName, computeNPortQuantities, appendNPortRows);
    % this function is the app-coupled orchestration (positioner, progress
    % dialog, save/load) around them.
    %
    % INPUT:
    %   app - ARES application object (hardware handles, UI, settings).
    %   cfg - AntennaMeasurementConfig snapshot whose PortMapping describes the
    %         AUT / Reference port assignment.
    %
    % OUTPUT:
    %   None (results saved to disk and loaded into the app).
    %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

    portMap = cfg.PortMapping;
    spacing = app.setupSpacing;

    % Opt-in trace auto-creation (off unless a UI toggle exists and is set).
    autoCreate = false;
    if isprop(app, 'PortMapAutoCreateTraces')
        autoCreate = logical(app.PortMapAutoCreateTraces.Value);
    end

    % Angular grid (reuse the shared position-table builder).
    tableAngles = cfg.tableAngles();
    towerAngles = cfg.towerAngles();
    parametersTable = createAntennaParametersTable(tableAngles, towerAngles);
    if ~any(parametersTable.("Theta (deg)") == 0 & parametersTable.("Phi (deg)") == 0)
        zeroRef = table(0, 0, 'VariableNames', ["Theta (deg)", "Phi (deg)"]);
        parametersTable = [zeroRef; parametersTable];
    end
    totalPositions = height(parametersTable);

    % Which S-parameters the map needs, and the reference gain curves.
    names    = portMap.sparamsNeeded();
    refGains = loadReferenceGains_(portMap);

    resultsTable = createNPortResultsTable();

    try
        vna = aresInstrument(app.VNA, "VNA");
        pos = AntennaPositioner(aresInstrument(app.EMCenter, "Chamber"));
        pos.PollDelaySec = app.AntennaMeasurementDelayValueField.Value;
        pos.TimeoutSec   = 600;
        pos.setSpeeds(app.TableSpeedSlider.Value, app.TowerSpeedSlider.Value);

        d = uiprogressdlg(app.UIFigure, 'Title', 'Measurement Progress', 'Cancelable', 'on');
        measurementStartTime = datetime('now');
        tic; lastTime = toc; totalTime = 0;

        for i = 1:totalPositions
            now = toc; totalTime = totalTime + (now - lastTime); lastTime = now;
            progress = i / totalPositions;
            avgTime = totalTime / i;
            remainingTime = avgTime * (totalPositions - i);

            d.Value = progress;
            d.CancelText = 'Stop Test';
            d.Message = sprintf("Measurement Progress: %d%%\nElapsed Time: %s\nRemaining Time: %s", ...
                round(100 * progress), ...
                string(duration(0, 0, round(totalTime))), ...
                string(duration(0, 0, round(remainingTime))));

            adjustedTheta = mod(parametersTable.("Theta (deg)")(i), 360);
            adjustedPhi   = parametersTable.("Phi (deg)")(i);

            pos.moveTo(adjustedTheta, adjustedPhi);
            pos.waitUntilStill('CancelFcn', @() d.CancelRequested, 'OnPoll', @() drawnow);

            if d.CancelRequested
                if height(resultsTable) > 0
                    choice = uiconfirm(app.UIFigure, 'Do you want to save collected data?', ...
                        'Stop Test', 'Options', {'Yes', 'No'}, 'DefaultOption', 1);
                    if strcmp(choice, 'Yes')
                        saveAndLoad_(app, resultsTable);
                    end
                end
                break;
            end

            pause(app.AntennaMeasurementDelayValueField.Value);

            % Measure the needed complex S-parameters and derive all quantities.
            [freqHz, S] = vna.measureComplexByName(names, 'AutoCreate', autoCreate);
            q = computeNPortQuantities(freqHz, S, portMap, spacing, refGains);
            resultsTable = appendNPortRows(resultsTable, ...
                parametersTable.("Theta (deg)")(i), parametersTable.("Phi (deg)")(i), q);
        end

        pos.moveTo(0, 0);

        if ~d.CancelRequested
            measurementEndTime = datetime('now');
            logMeasurementTime(app, 'Antenna', measurementStartTime, measurementEndTime, ...
                measurementEndTime - measurementStartTime, totalPositions);
            saveAndLoad_(app, resultsTable);
        end

        close(d);
        vna.setContinuous(true);
    catch ME
        app.displayError(ME);
    end
end

function refGains = loadReferenceGains_(portMap)
    % Build a reference-PORT -> struct(freqHz, gaindBi) map from the gain
    % files/columns declared on the port map's reference ports.
    refGains = containers.Map('KeyType', 'double', 'ValueType', 'any');
    for p = portMap.referencePorts()
        [file, col] = portMap.gainSourceAtPort(p);
        if strlength(file) == 0
            continue;   % reference without a gain file -> no absolute gain
        end
        [fHz, g] = readReferenceGainFile(file, col);
        refGains(p) = struct('freqHz', fHz, 'gaindBi', g);
    end
end

function saveAndLoad_(app, resultsTable)
    % Save the long results table and reload it into the app (schema-aware
    % processAntennaData stores it without applying the legacy field check).
    sorted = sortrows(resultsTable, ["Theta (deg)", "Phi (deg)", "Frequency (MHz)"]);
    fullFilename = saveData(sorted);
    if ~isempty(fullFilename)
        loadData(app, 'Antenna', fullFilename);
        updateNPortPlotDropdowns(app);   % populate selectors from the data
        plotNPortAntenna(app);           % draw the default view
    end
end
