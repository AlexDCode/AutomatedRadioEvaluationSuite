function runPAMeasurement(app)
    %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
    % DESCRIPTION:
    % This function performs a full RF Power Amplifier (PA) measurement sweep. On error, the instruments are safely
    % turned off, and the error message is displayed in the app and logged to the user path. The function process 
    % includes:
    %
    %   - Generating test parameter combinations and initializing the output results table.
    %   - Configuring the signal analyzer and initializing the measurement loop.
    %   - For each test point:
    %     -- Sets frequency and signal levels
    %     -- Configures PSU voltages and currents
    %     -- Measures RF output power and DC power
    %     -- Applies calibration factors (de-embedding)
    %     -- Calculates Gain, DE (Drain Efficiency), and PAE (Power Added Efficiency)
    %     -- Stores results in a structured table
    %   - Providing a progress UI dialog with estimated time updates.
    %   - Saving the results and loading them back into the application.
    %
    % INPUT:
    %   app  - Application object containing hardware interfaces, user settings, and UI components.
    %
    % OUTPUT:
    %   None   (Results are saved to the user's machine and updated in the application UI).
    %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

    try
        % Initialize tables for parameters and results.
        parametersTable = createPAParametersTable(app);
        totalMeasurements = height(parametersTable);
        resultsTable = createPAResultsTable(app, totalMeasurements);
        
        % Configure the signal analyzer settings.
        writeline(app.SpectrumAnalyzer, sprintf(':SENSe:SWEep:POINts %d', app.SweepPointsValueField.Value));
        writeline(app.SpectrumAnalyzer, sprintf(':SENSe:FREQuency:SPAN %g', app.SpanValueField.Value * 1E6));
        writeline(app.SpectrumAnalyzer, sprintf(':DISPlay:WINDow:TRACe:Y:SCALe:RLEVel %g', app.ReferenceLevelValueField.Value));
        writeline(app.SpectrumAnalyzer, sprintf(':FORMat:TRACe:DATA %s,%d', 'REAL', 64));
        writeline(app.SpectrumAnalyzer, sprintf(':FORMat:BORDer %s', 'SWAPped'));
        
        % Create a progress dialog to inform the user of the progress.
        d = uiprogressdlg(app.UIFigure, 'Title', 'Measurement Progress', 'Cancelable', 'on');
        measurementStartTime = datetime('now');
        tic; runTime = 0;

        for i = 1:totalMeasurements
            runTime = runTime + toc;

            % Average measurement time.
            avgRunTime = (runTime) / i;     

            % Remaining test time.
            remainingTime = (totalMeasurements - i) * avgRunTime;        
            elapsedTime = string(duration(round(runTime/3600), round(runTime/60), round(runTime)));
            estimatedTime = string(duration(round(remainingTime/3600), round(remainingTime/60), round(remainingTime)));

            % Update the progress dialog window.
            d.Value = i / totalMeasurements;
            d.CancelText = 'Stop Test';
            d.Message = sprintf("Measurement Progress: %d%% \nElapsed Time: %s \nRemaining Time: %s",...
                                round(d.Value*100),...
                                elapsedTime,...
                                estimatedTime);

            if d.CancelRequested
                % If the user stops the PA test measurement, then for
                % safety reasons the instruments will be turned off.
                enablePSUChannels(app, app.FilledPSUChannels, false);
                writeline(app.SignalGenerator, sprintf(':SOURce1:POWer:LEVel:IMMediate:AMPLitude %d', -135));
                writeline(app.SignalGenerator, sprintf(':OUTPut1:STATe %d', 0));

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
                            loadData(app, 'PA', fullFilename);
                        end
                    end
                end
                
                % Close progress dialog.
                close(d);
                return;
            end

            % Loop RF parameters.
            RFInputPower = parametersTable.('RF Input Power')(i);
            frequency = parametersTable.Frequency(i);

            % Set target frequency in the signal generator.
            writeline(app.SignalGenerator, sprintf(':SOURce1:FREQuency:CW %d', frequency));
            % Set center frequency in the signal analyzer.
            writeline(app.SpectrumAnalyzer, sprintf(':SENSe:FREQuency:CENTer %g', frequency));

            % Set all active channel voltages and currents.
            for ch = 1:length(app.FilledPSUChannels)
                channelName = app.FilledPSUChannels{ch};
                voltage = parametersTable.(sprintf('Channel %d Voltage', ch))(i);
                current = parametersTable.(sprintf('Channel %d Current', ch))(i);
                setPSUChannels(app, channelName, voltage, current);
            end

            if i == 1
                % For the first measurement:
                % Enable all channels.
                enablePSUChannels(app, app.FilledPSUChannels, true);

                % Longer delay to allow PA to settle.
                pause(app.PAMeasurementDelayValueField.Value * 10); 

                % Turn on signal generator.
                writeline(app.SignalGenerator, sprintf(':OUTPut1:STATe %d', 1));
            end

            % Small delay.
            pause(app.PAMeasurementDelayValueField.Value);

            % Measure RF and DC Power.
            [RFOutputPower, DCDrainPower, DCGatePower] = measureRFOutputandDCPower(app, RFInputPower, frequency);
            
            % Apply de-embedding calibration based on user
            % selected calibration mode.
            [inCal, outCal] = deembedPA(app, frequency, RFInputPower);
            % 
            % Subtract inCal to get actual PA input power.
            correctedRFInputPower = RFInputPower - inCal;  
            
            % Add outCal to get actual PA output power.
            correctedRFOutputPower = RFOutputPower + outCal;
            
            % Calculate total DC Power.
            TotalDCDrainPower = sum(DCDrainPower);
            TotalDCGatePower = sum(DCGatePower);
            
            % Calculate Gain.
            Gain = correctedRFOutputPower - correctedRFInputPower;
             
            % Calculate DE and PAE.
            if TotalDCDrainPower == 0
                DE = 0;
                PAE = 0;
            else
                [~, DE, PAE] = measureRFParameters(correctedRFInputPower, correctedRFOutputPower, TotalDCDrainPower);
            end
            
            % Add to results table
            resultsTable.("Frequency (MHz)")(i) = frequency/1e6;
            resultsTable.("RF Input Power (dBm)")(i) = correctedRFInputPower;
            resultsTable.("RF Output Power (dBm)")(i) = correctedRFOutputPower;
            resultsTable.Gain(i) = Gain;
            resultsTable.("Total DC Drain Power (W)")(i) = TotalDCDrainPower;
            resultsTable.("DE (%)")(i) = DE;
            resultsTable.("PAE (%)")(i) = PAE;   
            
            for ch = 1:length(app.FilledPSUChannels)
                % TODO: Add channel current (A) to results
                resultsTable.(sprintf('Channel %d Voltages (V)', ch))(i) = parametersTable.(sprintf('Channel %d Voltage', ch))(i);
                resultsTable.(sprintf('Channel %d DC Power (W)', ch))(i) = DCDrainPower(1, ch);
            end
        end

        % Close progress dialog.
        close(d);

        measurementEndTime = datetime('now');
        measurementDuration = measurementEndTime - measurementStartTime;


        % Log measurement completion time to the user path.
        logMeasurementTime(app, 'PA', measurementStartTime, measurementEndTime, measurementDuration, totalMeasurements);
        
        % Turn off the signal generator.
        writeline(app.SignalGenerator, sprintf(':SOURce1:POWer:LEVel:IMMediate:AMPLitude %d', -135));
        writeline(app.SignalGenerator, sprintf(':OUTPut1:STATe %d', 0));
        
        % Disable the channels.
        enablePSUChannels(app, app.FilledPSUChannels, false);
        
        % Set spectrum analyzer to continous trigger
        writeline(app.SpectrumAnalyzer, sprintf(':INITiate:CONTinuous %d', 1));

        % Save table as a variable in the app
        % TEST IF NEEDED
        app.PAMeasurementsTable = resultsTable;

        % Save the complete measurement data.
        fullFilename = saveData(resultsTable);
        loadData(app, 'PA', fullFilename);
                
        % Update dropdown values to match the data.
        updatePAPlotDropdowns(app);
        
        % Plot with updated dropdown values.
        plotPASingleMeasurement(app);
        plotPASweepMeasurement(app);
    catch ME
        % If an error occurs during the PA test measurement, then
        % for safety reasons the instruments will be turned off.
        enablePSUChannels(app, app.FilledPSUChannels, false);
        writeline(app.SignalGenerator, sprintf(':SOURce1:POWer:LEVel:IMMediate:AMPLitude %d', -135));
        writeline(app.SignalGenerator, sprintf(':OUTPut1:STATe %d', 0));
        app.displayError(ME);
    end
end