function runAntennaMeasurement(app) 
    %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
    % DESCRIPTION:
    % This function executes a 2D antenna gain measurement sweep using a dual-axis positioner (Theta and Phi) and a
    % VNA. The function automates rotation, measurement, data logging, and visualization of antenna radiation patterns.
    % The sweep is performed across a user-defined frequency range and angular grid, capturing S-parameters 
    % and calculating gain, return loss, and path loss. Data is saved to the disk and loaded into the app for plotting.
    % Additionally the user is able to manually stop the test run from within the application. If an error occurs:
    %
    %   - The errors are caught, reported via the app interface, and saved to the error log.
    %   - Positioners are safely stopped in case of interruption or failure.
    %
    % INPUT:
    %   app - Application object that holds hardware interfaces, user settings, UI elements, and measurement parameters.
    %
    % OUTPUT:
    %   None  (Results are saved to the user's machine and updated in the application UI).
    %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

    % Initialize variables from the application.
    smoothingPoints = app.SmoothingPoints.Value;
    sweepPoints = app.VNASweepPoints.Value;

    % Get table speed and theta angles.
    tableSpeed = app.TableSpeedSlider.Value;
    if strcmp(app.ThetaSingleSweepSwitch.Value,'Sweep')
        tableAngles = app.TableStartAngle.Value : app.TableStepAngle.Value : app.TableEndAngle.Value;
    else
        tableAngles = app.TableStartAngle.Value;
    end

    % Get tower speed and phi angles.
    towerSpeed = app.TowerSpeedSlider.Value;
    if strcmp(app.PhiSingleSweepSwitch.Value,'Sweep')
        towerAngles = app.TowerStartAngle.Value : app.TowerStepAngle.Value : app.TowerEndAngle.Value;
    else
        towerAngles = app.TowerStartAngle.Value;
    end
    
    % Create the parameters table to hold the measurement parameters.
    parametersTable = createAntennaParametersTable(tableAngles, towerAngles);

    % Add the boresight gain reference point (0,0) if not included.
    if ~any(parametersTable.("Theta (deg)") == 0 & parametersTable.("Phi (deg)") == 0)
        zeroRef = table(0, 0, 'VariableNames', ["Theta (deg)", "Phi (deg)"]);
        parametersTable = [zeroRef; parametersTable];
    end

    % Create the results table to hold the saved measurement data.
    totalPositions = height(parametersTable);
    totalMeasurements = totalPositions * sweepPoints;
    resultsTable = createAntennaResultsTable(totalMeasurements);

    try
        % Object-oriented instrument drivers. aresInstrument() returns the
        % right driver whether app.VNA / app.EMCenter are still raw visadev
        % handles or already migrated driver objects, so this works before
        % and after the ARES.mlapp connection layer is migrated.
        vna = aresInstrument(app.VNA, "VNA");
        pos = AntennaPositioner(aresInstrument(app.EMCenter, "Chamber"));
        pos.PollDelaySec = app.AntennaMeasurementDelayValueField.Value;
        pos.TimeoutSec   = 600;   % generous: a full-range rotation is slow

        % Set speed of the turntable and tower.
        pos.setSpeeds(tableSpeed, towerSpeed);

        % Create a progress dialog to inform the user of the progress.
        d = uiprogressdlg(app.UIFigure, 'Title', 'Measurement Progress', 'Cancelable', 'on');
        measurementStartTime = datetime('now'); 
        tic; lastTime = toc; totalTime = 0;

        for i = 1:totalPositions
            % Update timing info.
            now = toc; 
            elapsedTime = now - lastTime; 
            totalTime = totalTime + elapsedTime; 
            lastTime = now;
            
            % Calculate progress and time estimates.
            progress = i / totalPositions;
            avgTime = totalTime / i;
            remainingTime = avgTime * (totalPositions - i);
            
            % Update dialog progress message.
            d.Value = progress;
            d.CancelText = 'Stop Test';
            d.Message = sprintf("Measurement Progress: %d%%\nElapsed Time: %s\nRemaining Time: %s", ...
                        round(100 * progress), ...
                        string(duration(0, 0, round(totalTime))), ...
                        string(duration(0, 0, round(remainingTime))));

            dataPts = (i - 1) * sweepPoints + (1:sweepPoints);

            % Get measurement corrected angles for (0,360) range
            adjustedTheta = mod(parametersTable.("Theta (deg)")(i), 360); 
            adjustedPhi = parametersTable.("Phi (deg)")(i);
            
            % Move the turntable and tower to specified position, then block
            % until both axes finish. waitUntilStill polls *OPC? on both axes,
            % keeps the dialog responsive (OnPoll = drawnow), and stops both
            % axes if the user clicks Stop (CancelFcn). It honors the same
            % per-poll delay as before via pos.PollDelaySec.
            pos.moveTo(adjustedTheta, adjustedPhi);
            pos.waitUntilStill('CancelFcn', @() d.CancelRequested, ...
                               'OnPoll',    @() drawnow);

            % Exit the outer loop as well if stop was requested
            if d.CancelRequested
                % Clear the reference data.
                if isempty(app.ReferenceGainFileField.Value)
                    app.ReferenceGainFile.GaindBi = [];
                    app.ReferenceGainFile.FrequencyMHz = [];
                end

                % Check if any data has been recorded in the measurement.
                validIndices = resultsTable.("Frequency (MHz)") > 0;
                filteredResults = resultsTable(validIndices, :);

                % Save any data that might have been recorded.
                if height(filteredResults) > 0
                    % Ask the user if they want to save the collected data.
                    question = 'Do you want to save collected data?';
                    choice = uiconfirm(app.UIFigure, question, 'Stop Test', 'Options', {'Yes', 'No'}, 'DefaultOption', 1);

                    if strcmp(choice, 'Yes')
                        % Save the partial data
                        fullFilename = saveData(filteredResults);

                        % Load the saved data into the application.
                        if ~isempty(fullFilename)
                            loadData(app, 'Antenna', fullFilename);
                            
                            % Update dropdown values to match the data.
                            updateAntennaPlotDropdowns(app);
                            
                            % Plot with updated dropdown values.
                            plotAntenna2DRadiationPattern(app);
                        end
                    end
                end
                break;
            end

            % Small delay.
            pause(app.AntennaMeasurementDelayValueField.Value);

            % Get S-Parameters and Frequencies from VNA
            [SParameters_dB, SParameters_Phase, VNAFrequencies] = vna.measureSParameters(smoothingPoints);

            % Calculate gain.
            if isempty(app.ReferenceGainFile)
                % Two-Antenna Method.
                Gain_dBi = measureAntennaGain(VNAFrequencies, SParameters_dB{2}, app.setupSpacing);
                AbsoluteGain_dBi = calculateAbsoluteAntennaGain(Gain_dBi, SParameters_dB{3});
                app.ReferenceGainFile.GaindBi = Gain_dBi;
                app.ReferenceGainFile.FrequencyMHz = VNAFrequencies/1E6;
                app.ReferenceGainFile.ReturnLossdB = SParameters_dB{1};
                app.ReferenceGainFile.ReturnLossdeg = SParameters_Phase{1};

                plotReferenceAntenna(app);
            else
                % Comparison-Antenna Method.
                Gain_dBi = measureAntennaGain(VNAFrequencies, SParameters_dB{2}, app.setupSpacing, app.ReferenceGainFile.GaindBi, app.ReferenceGainFile.FrequencyMHz*1E6);
                AbsoluteGain_dBi = calculateAbsoluteAntennaGain(Gain_dBi, SParameters_dB{3});
            end

            resultsTable(dataPts, "Theta (deg)") = array2table(parametersTable.("Theta (deg)")(i)*ones(numel(dataPts),1));
            resultsTable(dataPts, "Phi (deg)") = array2table(parametersTable.("Phi (deg)")(i)*ones(numel(dataPts),1));
            resultsTable(dataPts, "Frequency (MHz)") = array2table(VNAFrequencies' / 1E6);
            resultsTable(dataPts, "Gain (dBi)") = array2table(Gain_dBi');
            resultsTable(dataPts, "Return Loss (dB)") = array2table(SParameters_dB{3}');
            resultsTable(dataPts, "Return Loss (deg)") = array2table(SParameters_Phase{3}');
            resultsTable(dataPts, "Return Loss Reference (dB)") = array2table(SParameters_dB{1}');
            resultsTable(dataPts, "Return Loss Reference (deg)") = array2table(SParameters_Phase{1}');
            resultsTable(dataPts, "Insertion Loss (dB)") = array2table(SParameters_dB{2}');
            resultsTable(dataPts, "Insertion (deg)") = array2table(SParameters_Phase{2}');
            resultsTable(dataPts, "Absolute Gain (dBi)") = array2table(AbsoluteGain_dBi');
        end

        % Return turntable and tower to starting position.
        pos.moveTo(0, 0);

        % If the measurement was not canceled.
        if ~d.CancelRequested
            measurementEndTime = datetime('now');
            measurementDuration = measurementEndTime - measurementStartTime;
            
            % Log measurement completion time.
            logMeasurementTime(app, 'Antenna', measurementStartTime, measurementEndTime, measurementDuration, totalPositions);

            % Sort table by Theta, Phi, and Frequency before saving.
            sortedResults = sortrows(resultsTable, ["Theta (deg)", "Phi (deg)", "Frequency (MHz)"]);
            
            % Save the complete sorted measurement data.
            fullFilename = saveData(sortedResults);

            if ~isempty(fullFilename)
                loadData(app, 'Antenna', fullFilename);
                
                % Update dropdown values to match the new data.
                updateAntennaPlotDropdowns(app);

                % Plot for regular antenna data.
                plotAntenna2DRadiationPattern(app);
            end
        end

        % Close the progress dialog.
        close(d);

        % Return the VNA windows to continuous mode.
        vna.setContinuous(true);

        % Clear the reference data if running two-antenna method.
        if isempty(app.ReferenceGainFileField.Value)
            app.ReferenceGainFile.GaindBi = [];
            app.ReferenceGainFile.FrequencyMHz = [];
            app.ReferenceGainFile.ReturnLossdB = [];
            app.ReferenceGainFile.ReturnLossdeg = [];
        end
    catch ME
        app.displayError(ME);
    end
end