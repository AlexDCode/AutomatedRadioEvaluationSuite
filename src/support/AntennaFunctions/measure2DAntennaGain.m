function measure2DAntennaGain(app) 
    %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
    % This function executes a full 2D antenna gain measurement sweep by 
    % controlling a dual-axis positioner (Theta and Phi) and capturing RF 
    % gain and return loss data from a VNA across a defined frequency 
    % range.
    %
    % INPUT PARAMETERS:
    %   app:  Application object containing: hardware interfaces,
    %   user-defined settings, UI components, and other setup parameters.
    %
    % PROCESS OVERVIEW:
    %   1. Initializes sweep parameters based on UI input:
    %       - Frequency range and sweep points
    %       - Theta and Phi angle vectors
    %   2. Generates a parameter sweep table for all Theta/Phi 
    %      combinations.
    %   3. For each test position:
    %       - Rotates the table and tower to the specified angles
    %       - Waits for motors to finish moving
    %       - Checks for user stop request
    %       - Measures S-parameters using the VNA
    %       - Calculates antenna gain
    %       - Stores results: frequency, gain, return loss, path loss
    %   4. Returns the positioners to 0°.
    %   5. If not stopped by the user:
    %       - Saves results to disk
    %       - Loads data back into the app
    %       - Plots the 2D antenna gain measurement
    %
    % OUTPUT PARAMETERS:
    %   None 
    %
    % ERROR HANDLING:
    %   Any error is caught and displayed via the app interface. 
    %   Positioners are stopped safely on user interruption or error.
    %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

    % Initialize variables from the application.
    smoothingPercentage = app.SmoothingPercentage.Value;
    sweepPoints = app.VNASweepPoints.Value;

    if ~isempty(app.ReferenceGainFile)
        ReferenceFreqs = app.ReferenceGainFile.FrequencyMHz * 1E6;
        ReferenceGain = app.ReferenceGainFile.GaindBi;
    end
    
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
    
    % Create the parameters table to hold the measurement parameters and
    % create the results table to hold the saved measurement data.
    parametersTable = createAntennaParametersTable(tableAngles, towerAngles);
    totalPositions = height(parametersTable);
    totalMeasurements = totalPositions * sweepPoints;
    resultsTable = createAntennaResultsTable(totalMeasurements);

    try
        % Set speed of the turntable and tower.
        writeline(app.EMCenter, sprintf('1A:SPEED %d', tableSpeed));
        writeline(app.EMCenter, sprintf('1B:SPEED %d', towerSpeed));

        % Create a progress dialog to inform the user of the progress.
        d = uiprogressdlg(app.UIFigure, 'Title', 'Measurement Progress', 'Cancelable', 'on');
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
            
            % Move the turntable and tower to specified position.
            writeline(app.EMCenter, sprintf('1A:SK %d', adjustedTheta));
            writeline(app.EMCenter, sprintf('1B:SK %d', adjustedPhi));
            moving = 0;

            while ~moving
                drawnow;
                pause(app.AntennaMeasurementDelayValueField.Value);

                % Check if the user requested the test measurement to stop
                if d.CancelRequested  
                    writeline(app.EMCenter, '1A:ST');
                    writeline(app.EMCenter, '1B:ST');
                    break;
                end

                statusA = str2double(writeread(app.EMCenter,"1A:*OPC?"));
                statusB = str2double(writeread(app.EMCenter,"1B:*OPC?"));
                moving = (statusA == 1) & (statusB == 1);
            end

            % Exit the outer loop as well if stop was requested
            if d.CancelRequested
                % Check if any data results have been recorded in the 
                % measurement.
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
            [SParameters_dB, SParameters_Phase, VNAFrequencies] = measureSParameters(app.VNA, smoothingPercentage);

            if ~isempty(app.ReferenceGainFile)
                Gain_dBi = measureAntennaGain(VNAFrequencies, SParameters_dB{2}, app.setupSpacing, ReferenceGain, ReferenceFreqs);
            else
                Gain_dBi = measureAntennaGain(VNAFrequencies, SParameters_dB{2}, app.setupSpacing);
            end

            resultsTable(dataPts, "Theta (deg)") = array2table(parametersTable.("Theta (deg)")(i)*ones(numel(dataPts),1));
            resultsTable(dataPts, "Phi (deg)") = array2table(parametersTable.("Phi (deg)")(i)*ones(numel(dataPts),1));
            resultsTable(dataPts, "Frequency (MHz)") = array2table(VNAFrequencies' / 1E6);
            resultsTable(dataPts, "Gain (dBi)") = array2table(Gain_dBi');
            resultsTable(dataPts, "Return Loss (dB)") = array2table(SParameters_dB{3}');
            resultsTable(dataPts, "Return Loss (deg)") = array2table(SParameters_Phase{3}');
            resultsTable(dataPts, "Return Loss Reference (dB)") = array2table(SParameters_dB{1}');
            resultsTable(dataPts, "Return Loss Reference (deg)") = array2table(SParameters_Phase{1}');
            resultsTable(dataPts, "Path Loss (dB)") = array2table(SParameters_dB{2}');
            resultsTable(dataPts, "Path Loss (deg)") = array2table(SParameters_Phase{2}');
        end

        % Return turntable and tower to starting position.
        writeline(app.EMCenter, sprintf('1A:SK %d', 0));
        writeline(app.EMCenter, sprintf('1B:SK %d', 0));

        % If the measurement was not canceled.
        if ~d.CancelRequested
            % Save the complete measurement data.
            fullFilename = saveData(resultsTable);

            if ~isempty(fullFilename)
                loadData(app, 'Antenna', fullFilename);
                
                % Update dropdown values to match the new data.
                updateAntennaPlotDropdowns(app);

                % Plot for regular antenna data.
                plotAntenna2DRadiationPattern(app);
            end
        end

        % Close progress dialog.
        close(d);
    catch ME
        app.displayError(ME);
    end
end
