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
    % TODO:
    %   - Verify if gate PSU data is saved to results table in individual PSU channel columns
    %
    % INPUT:
    %   app  - Application object containing hardware interfaces, user settings, and UI components.
    %
    % OUTPUT:
    %   None   (Results are saved to the user's machine and updated in the application UI).
    %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

    % Check if minimum needed instruments are connected
    connectedSA = ~isempty(app.OutputSignalAnalyzer) | (~isempty(app.OutputSignalAnalyzer) & ~isempty(app.InputSignalAnalyzer));
    connectedSG = ~isempty(app.SignalGenerator);
    if ~(connectedSA & connectedSG)
        error('Required instruments not connected.')
    end
    if app.StimulusDropDown.Value == "Modulated" && app.SpanValueField.Value < app.ChannelBandwidthValueField
        error('Span smaller than channel bandwidth.');
    end
    % Initialize tables for parameters and results.
    exitFlag = 0;
    parametersTable = createPAParametersTable(app);
    totalMeasurements = height(parametersTable);
    resultsTable = createPAResultsTable(app, totalMeasurements);
    Gain = NaN; averageGain = NaN;

try
    % Configure the signal analyzer settings.
    if ~isempty(app.OutputSignalAnalyzer)
        writeline(app.OutputSignalAnalyzer, sprintf('*RST'));
        writeline(app.OutputSignalAnalyzer, sprintf(':SENSe:SWEep:POINts %d', app.SweepPointsValueField.Value));
        writeline(app.OutputSignalAnalyzer, sprintf(':SENSe:FREQuency:SPAN %g', app.SpanValueField.Value * 1E6));
        writeline(app.OutputSignalAnalyzer, sprintf(':DISPlay:WINDow:TRACe:Y:SCALe:RLEVel %g', app.ReferenceLevelValueField.Value));
        writeline(app.OutputSignalAnalyzer, sprintf(':FORMat:TRACe:DATA %s,%d', 'REAL', 64));
        writeline(app.OutputSignalAnalyzer, sprintf(':FORMat:BORDer %s', 'SWAPped'));
        if app.StimulusDropDown.Value == "Modulated"
            % Set span for Occupied Bandwidth measurement
            writeline(app.OutputSignalAnalyzer, sprintf(':SENSe:OBWidth:FREQuency:SPAN %g', app.SpanValueField.Value * 1E6));

            % Turn trace averaging on for trace 1
            writeline(app.OutputSignalAnalyzer, sprintf(':SENSe:AVERage:STATe %d', 1));
            writeline(app.OutputSignalAnalyzer, sprintf(':SENSe:AVERage:COUNt %d', 100)); % Samples to average

            % Add max hold trace
            writeline(app.OutputSignalAnalyzer, sprintf(':TRACe2:MODE %s', 'MAXHold'));
        end
    end
    if ~isempty(app.InputSignalAnalyzer)
        if app.CalibrationModeDropDown.Value ~= "In-Situ Couplers"
                uialert(app.UIFigure, "An input signal analyzer was specified without selecting In-Situ Couplers calibration.", 'Application Error', 'Icon', 'error');
                exitFlag = 1;
        end

        writeline(app.InputSignalAnalyzer, sprintf('*RST'));
        writeline(app.InputSignalAnalyzer, sprintf(':SENSe:SWEep:POINts %d', app.SweepPointsValueField.Value));
        writeline(app.InputSignalAnalyzer, sprintf(':SENSe:FREQuency:SPAN %g', app.SpanValueField.Value * 1E6));
        writeline(app.InputSignalAnalyzer, sprintf(':DISPlay:WINDow:TRACe:Y:SCALe:RLEVel %g', app.ReferenceLevelValueField.Value));
        writeline(app.InputSignalAnalyzer, sprintf(':FORMat:TRACe:DATA %s,%d', 'REAL', 64));
        writeline(app.InputSignalAnalyzer, sprintf(':FORMat:BORDer %s', 'SWAPped'));
        if app.StimulusDropDown.Value == "Modulated"
            % Set span for Occupied Bandwidth measurement
            writeline(app.InputSignalAnalyzer, sprintf(':SENSe:OBWidth:FREQuency:SPAN %g', app.SpanValueField.Value * 1E6));

            % Turn trace averaging on for trace 1
            writeline(app.InputSignalAnalyzer, sprintf(':SENSe:AVERage:STATe %d', 1));
            writeline(app.InputSignalAnalyzer, sprintf(':SENSe:AVERage:COUNt %d', 100)); % Samples to average

            % Add max hold trace
            writeline(app.InputSignalAnalyzer, sprintf(':TRACe2:MODE %s', 'MAXHold'));
        end
    end

    % Set modulation in the signal generator.
    if app.StimulusDropDown.Value == "CW"
        writeline(app.SignalGenerator, sprintf(':OUTPut:MODulation:STATe %d', 0)); % Enable modulated output signal
    elseif app.StimulusDropDown.Value == "Modulated"
        writeline(app.SignalGenerator, sprintf(':SOURce1:RADio:DMODulation:ARB:MODulation:TYPE %s', app.ModulationTypeDropDown.Value)); % Set modulation type
        writeline(app.SignalGenerator, sprintf(':SOURce:RADio:DMODulation:ARB:SRATe %d MSPS', app.SymbolRateValueField.Value)); % Set modulation type
        writeline(app.SignalGenerator, sprintf(':SOURce1:RADio:DMODulation:ARB:STATe %d', 1)); % Turn digital modulation on
        waitForInstrument(app, app.SignalGenerator);
        writeline(app.SignalGenerator, sprintf(':OUTPut:MODulation:STATe %d', 1)); % Enable modulated output signal
    end

    % Power sweep summary to count points per power sweep
    groupVars = setdiff(parametersTable.Properties.VariableNames, 'RF Input Power', 'stable'); % Get all variables except input power
    [G, sweeps] = findgroups(parametersTable(:, groupVars));  % group by all groupVars
    counts = splitapply(@numel, parametersTable.("RF Input Power"), G); % Count the number of input power points per sweep
    sweepSummary = [sweeps, table(counts, 'VariableNames', {'NumPowerPoints'})]; % Build summary table
    numPowerSweeps = height(sweepSummary); % Get number of power sweeps
    
    nPowerSweep = 1; % Initialize sweep counter
    cooldownAvgTime = app.CooldownTimeSpinner.Value; % Initialize average cooldown time 
    delayAvgPSU = app.PSUDelaySpinner.Value; % Initialize PSU Delay time

    % Create a progress dialog to inform the user of the progress.
    d = uiprogressdlg(app.UIFigure, 'Title', 'Measurement Progress', 'Cancelable', 'on');
    measurementStartTime = datetime('now');
    tic; lastTime = toc; totalTime = 0;
    i = 1;
    statePSU = false; % Flag for PSU output enable
    safetyFlag = false; % Flag to stop remaining power sweep
    while i <= height(parametersTable) & ~exitFlag
        % Update timing info.
        now = toc;
        elapsedTime = now - lastTime;
        lastTime = now;
        totalTime = totalTime + elapsedTime;

        % Calculate progress and time estimates.
        progress = (i - 1) / totalMeasurements;
        avgTime = (totalTime - (cooldownAvgTime + logical(1-i)*delayAvgPSU)*(nPowerSweep - 1))/i;
        remainingTime = avgTime * (totalMeasurements - i + 1) + (cooldownAvgTime + logical(numPowerSweeps - nPowerSweep)*delayAvgPSU)*(numPowerSweeps - nPowerSweep + 1);

        % Update the progress dialog window.
        d.Value = progress;
        d.CancelText = 'Stop Test';
        d.Message = sprintf("Measurement Progress: %d%%\nElapsed Time: %s\nRemaining Time: %s", ...
            round(100 * progress), ...
            string(duration(0, 0, round(totalTime))), ...
            string(duration(0, 0, round(remainingTime))));


        if d.CancelRequested || exitFlag
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

        % Get indices for current power sweep
        sweepVars = setdiff(parametersTable.Properties.VariableNames, {'RF Input Power'}); % Get all variable names except RF Input Power
        powerSweepMask = ismember(parametersTable(:,sweepVars), parametersTable(i,sweepVars), 'rows'); % Get rows with similar sweep variable values
        idxPowerSweep = find(powerSweepMask); % Get the indices

        % Loop RF parameters.
        RFInputPower = parametersTable.('RF Input Power')(i);
        frequency = parametersTable.Frequency(i);

        % Set target frequency in the signal generator.
        writeline(app.SignalGenerator, sprintf(':SOURce1:FREQuency:CW %d', frequency));

        % Set center frequency in the signal analyzer.
        if ~isempty(app.OutputSignalAnalyzer)
            writeline(app.OutputSignalAnalyzer, sprintf(':SENSe:FREQuency:CENTer %g', frequency));
        end
        if ~isempty(app.InputSignalAnalyzer)
            writeline(app.InputSignalAnalyzer, sprintf(':SENSe:FREQuency:CENTer %g', frequency));
        end

        % Set all active channel voltages and currents.
        for ch = 1:length(app.FilledPSUChannels)
            channelName = app.FilledPSUChannels{ch};
            voltage = parametersTable.(sprintf('Channel %d Voltage', ch))(i);
            current = parametersTable.(sprintf('Channel %d Current', ch))(i);
            setPSUChannels(app, channelName, voltage, current);
        end

        if ~statePSU 
            delayPSU = toc;
            if app.PSUMode ~= "No Supply"
                % When the PSU is switched back on use the PSU delay, save
                % quiescent current, and turn signal generator on 
    
                % Enable all channels.
                enablePSUChannels(app, app.FilledPSUChannels, true);
                statePSU = true;
                
                % Message for PSU delay
                d.Message = sprintf('%s\n%s', d.Message, 'PSU Startup Delay');

                % Longer delay to allow PA to settle.
                pause(app.PSUDelaySpinner.Value);
    
                % Measure quiescent current
                [~, ~, DCDrainQuiescentCurrent, DCGateQuiescentCurrent, ~, ~] = measureCW(app, RFInputPower, frequency);
        
                % Calculate total DC Current (A).
                TotalDCDrainQuiescentCurrent = sum(DCDrainQuiescentCurrent);
                TotalDCGateQuiescentCurrent = sum(DCGateQuiescentCurrent);
        
                % Save quiescent current data to results table
                % (in the first row of power sweep)
                resultsTable.("Total DC Drain Quiescent Current (A)")(i) = TotalDCDrainQuiescentCurrent;
                resultsTable.("Total DC Gate Quiescent Current (A)")(i) = TotalDCGateQuiescentCurrent;
                for ch = 1:length(app.FilledPSUChannels)
                    resultsTable.(sprintf('Channel %d DC Quiescent Current (A)', ch))(i) = DCDrainQuiescentCurrent(1, ch);
                end
            end
            % Remove PSU delay message
            lines = strsplit(d.Message, '\n');
            d.Message = strjoin(lines(1:end-1), '\n');

            % Turn on signal generator.
            writeline(app.SignalGenerator, sprintf(':OUTPut1:STATe %d', 1));
            pause(app.PAMeasurementDelayValueField.Value);

            delayPSU = toc - delayPSU; 
            delayAvgPSU = delayAvgPSU + (delayPSU - delayAvgPSU)/nPowerSweep; % Running average
        end

        % Small delay.
        pause(app.PAMeasurementDelayValueField.Value);

        % Measure RF Power, DC Current, and DC Power.
        if app.StimulusDropDown.Value == "CW"
            [RFInputPower, RFOutputPower, DCDrainCurrent, DCGateCurrent, DCDrainPower, DCGatePower] = measureCW(app, RFInputPower, frequency);

            % Calculate total DC Current (A).
            TotalDCDrainCurrent = sum(DCDrainCurrent);
            TotalDCGateCurrent = sum(DCGateCurrent);
    
            % Calculate total DC Power (W).
            TotalDCDrainPower = sum(DCDrainPower);
            TotalDCGatePower = sum(DCGatePower);
        
            % Calculate Gain, DE and PAE.
            [Gain, DE, PAE] = calculateGainEfficiency(RFInputPower, RFOutputPower, TotalDCDrainPower);
    
            % Add to results table
            resultsTable.("Frequency (MHz)")(i) = frequency/1e6;
            resultsTable.("RF Input Power (dBm)")(i) = RFInputPower;
            resultsTable.("RF Output Power (dBm)")(i) = RFOutputPower;
            resultsTable.Gain(i) = Gain;
            if app.PSUMode ~= "No Supply"
                resultsTable.("Total DC Drain Current (A)")(i) = TotalDCDrainCurrent;
                resultsTable.("Total DC Gate Current (A)")(i) = TotalDCGateCurrent;
                resultsTable.("Total DC Drain Power (W)")(i) = TotalDCDrainPower;
                resultsTable.("Total DC Gate Power (W)")(i) = TotalDCGatePower;
            end
            resultsTable.("DE (%)")(i) = DE;
            resultsTable.("PAE (%)")(i) = PAE;
    
            for ch = 1:length(app.FilledPSUChannels)
                resultsTable.(sprintf('Channel %d Voltages (V)', ch))(i) = parametersTable.(sprintf('Channel %d Voltage', ch))(i);
                resultsTable.(sprintf('Channel %d DC Current (A)', ch))(i) = DCDrainCurrent(1, ch);
                resultsTable.(sprintf('Channel %d DC Power (W)', ch))(i) = DCDrainPower(1, ch);
            end
        end
        if app.StimulusDropDown.Value == "Modulated"
            [inputSpectrum, outputSpectrum, inputOBW, outputOBW, inputChannelPower, outputChannelPower, inputACPR, outputACPR, ...
                ModDCDrainCurrent, ModDCGateCurrent, ModDCDrainPower, ModDCGatePower] = measureModulated(app, RFInputPower, frequency);
            
            % Calculate total DC Current (A).
            ModTotalDCDrainCurrent = sum(ModDCDrainCurrent);
            ModTotalDCGateCurrent = sum(ModDCGateCurrent);
    
            % Calculate total DC Power (W).
            ModTotalDCDrainPower = sum(ModDCDrainPower);
            ModTotalDCGatePower = sum(ModDCGatePower);
    
            % Calculate Gain and Efficiency
            [averageGain, averageDE, averagePAE] = calculateGainEfficiency(inputChannelPower, outputChannelPower, ModTotalDCDrainPower);

            % Preprocess table and array results as strings
            inputSpectrum = table2string(inputSpectrum);
            outputSpectrum = table2string(outputSpectrum);
            inputACPR = table2string(array2table(inputACPR));
            outputACPR = table2string(array2table(outputACPR));

            % Add to results table
            resultsTable.("Frequency (MHz)")(i) = frequency/1e6;
            resultsTable.("RF Input Power (dBm)")(i) = RFInputPower;
            resultsTable.("RF Input Channel Power (dBm)")(i) = inputChannelPower;
            resultsTable.("RF Output Channel Power (dBm)")(i) = outputChannelPower;
            resultsTable.("Input Occupied Bandwidth (MHz)")(i) = inputOBW/1e6;
            resultsTable.("Output Occupied Bandwidth (MHz)")(i) = outputOBW/1e6;
            if app.PSUMode ~= "No Supply"
                resultsTable.("Total DC Drain Current Modulated (A)")(i) = ModTotalDCDrainCurrent;
                resultsTable.("Total DC Gate Current Modulated (A)")(i) = ModTotalDCGateCurrent;
                resultsTable.("Total DC Drain Power Modulated (W)")(i) = ModTotalDCDrainPower;
                resultsTable.("Total DC Gate Power Modulated (W)")(i) = ModTotalDCGatePower;
            end
            for ch = 1:length(app.FilledPSUChannels)
                resultsTable.(sprintf('Channel %d Voltages (V)', ch))(i) = parametersTable.(sprintf('Channel %d Voltage', ch))(i);
                resultsTable.(sprintf('Channel %d DC Current Modulated (A)', ch))(i) = ModDCDrainCurrent(1, ch);
                resultsTable.(sprintf('Channel %d DC Power Modulated (W)', ch))(i) = ModDCDrainPower(1, ch);
            end
            resultsTable.("Average Gain (dB)")(i) = averageGain;
            resultsTable.("Average DE (%)")(i) = averageDE;
            resultsTable.("Average PAE (%)")(i) = averagePAE;
            resultsTable.("Input ACPR {Lower;Upper} (dBc)")(i) = inputACPR;
            resultsTable.("Output ACPR {Lower;Upper} (dBc)")(i) = outputACPR;
            resultsTable.("RF Input Power Spectrum {Frequency;Average;Maximum} (dBm)")(i) = inputSpectrum;
            resultsTable.("RF Output Power Spectrum {Frequency;Average;Maximum} (dBm)")(i) = outputSpectrum;
        end

        %% Test safety options
        % Minimum Gain: Skip remaining power sweep when below threshold
        if app.MinimumGainSafetyState % Only if safety option is active
            if Gain < app.MinimumGainSpinner.Value || averageGain < app.MinimumGainSpinner.Value
                safetyFlag = true;
                
                % Message gain flag triggered
                d.Message = sprintf('%s\n%s', d.Message, 'Minimum gain safety flag triggered');
            end
        end

        % Exceed Occupied Bandwidth: Skip remaining power sweep when above threshold
        if app.OccupiedBandwidthSafetyState && app.StimulusDropDown.Value == "Modulated" % Only if safety option is active
            if outputOBW/1e6 > app.ChannelBandwidthValueField.Value + app.OccupiedBandwidthSpinner.Value
                safetyFlag = true;
                
                % Message for exceeded occupied bandwidth flag triggered
                d.Message = sprintf('%s\n%s', d.Message, 'Excessive occupied bandwidth safety flag trigerred');
            end
        end

        % Power sweep completion and cooldown
        if i == idxPowerSweep(end) | safetyFlag
            % Turn off signal generator.
            writeline(app.SignalGenerator, sprintf(':OUTPut1:STATe %d', 0));

            % Disable all channels.
            enablePSUChannels(app, app.FilledPSUChannels, false);
            statePSU = false;

            cooldownTime = toc; 

            % Plot at current sweep  
            combinedData = resultsTable;
            
            try
                % Remove zero rows that may be left empty during safety checks
                combinedData(all(resultsTable.("Frequency (MHz)") == 0, 2), :) = [];
            
                % Save table as a variable in the app
                app.PAMeasurementsTable = combinedData;
    
                % Remove spaces and special characters from the variable names.
                combinedData.Properties.VariableNames = regexprep(combinedData.Properties.VariableNames, ' ', '');
                combinedData.Properties.VariableNames = regexprep(combinedData.Properties.VariableNames, '(', '');
                combinedData.Properties.VariableNames = regexprep(combinedData.Properties.VariableNames, ')', '');
                combinedData.Properties.VariableNames = regexprep(combinedData.Properties.VariableNames, '%', '');
                combinedData.Properties.VariableNames = regexprep(combinedData.Properties.VariableNames, '[{};]', '');
                
                % Process data
                processPAData(app, combinedData);
                
                % Index the data for the current frequency and power supply values
                app.FrequencySingleDropDown.Value = string(frequency/1e6);
                for ch = 1:length(app.PA_PSU_Channels)
                    app.PA_PSU_SelectedVoltages(ch) = resultsTable.(sprintf('Channel %d Voltages (V)', ch))(i);
                end    

                % Plot with updated dropdown values.
                mode = detectPAMeasurementType(app.PA_DataTable.Properties.VariableNames);
                if mode == "CW"
                    % Plot with updated dropdown values.
                    plotPASingleMeasurement(app);
                    plotPASweepMeasurement(app);
                    plotPADCMeasurement(app);
                elseif mode == "Modulated"
                    plotPAModulatedMeasurement(app);
                    plotPADCMeasurement(app);
                elseif mode == "Unknown"
                    app.displayError("Unknown PA data format which not contains the expected columns.")
                end
            catch ME
                % Silent catch
                disp(ME)
            end

            nPowerSweep = nPowerSweep + 1; % Increase power sweep index
            
            % Message for PSU delay
            d.Message = sprintf('%s\n%s', d.Message, 'Cooldown time delay');

            % Pause for cooldown in last power sweep row
            pause(app.CooldownTimeSpinner.Value)

            
            lines = strsplit(d.Message, '\n');
            if safetyFlag
                % Skip remaining power sweep if gain is below threshold
                i = idxPowerSweep(end);
                safetyFlag = false; % Flag to stop remaining power sweep
                d.Message = strjoin(lines(1:end-2), '\n'); % Remove cooldown and safety messages
            else
                d.Message = strjoin(lines(1:end-1), '\n'); % Remove cooldown messages
            end

            if i == totalMeasurements
                break;
            end

            cooldownTime = now - cooldownTime;
            cooldownAvgTime = (cooldownTime + cooldownAvgTime)/nPowerSweep;
        end

        i = i+1;
    end

    % Turn off the signal generator.
    writeline(app.SignalGenerator, sprintf(':SOURce1:POWer:LEVel:IMMediate:AMPLitude %d', -135));
    writeline(app.SignalGenerator, sprintf(':OUTPut1:STATe %d', 0));

    % Disable the channels.
    enablePSUChannels(app, app.FilledPSUChannels, false);

    % Close progress dialog.
    close(d);

    measurementEndTime = datetime('now');
    measurementDuration = measurementEndTime - measurementStartTime;


    % Log measurement completion time to the user path.
    logMeasurementTime(app, 'PA', measurementStartTime, measurementEndTime, measurementDuration, totalMeasurements);

    % Set signal analyzer to continous trigger
    if ~isempty(app.OutputSignalAnalyzer)
        writeline(app.OutputSignalAnalyzer, sprintf(':INITiate:CONTinuous %d', 1));
    end
    if ~isempty(app.InputSignalAnalyzer)
        writeline(app.InputSignalAnalyzer, sprintf(':INITiate:CONTinuous %d', 1));
    end

    % Remove zero rows that may be left empty during safety checks
    resultsTable(all(resultsTable.("Frequency (MHz)") == 0, 2), :) = [];

    % Save table as a variable in the app
    app.PAMeasurementsTable = resultsTable;

    % Save the complete measurement data.
    if height(app.PAMeasurementsTable) > 0
        fullFilename = saveData(app.PAMeasurementsTable);
        loadData(app, 'PA', fullFilename);
    end
catch ME
    % If an error occurs during the PA test measurement, then
    % for safety reasons the instruments will be turned off.
    writeline(app.SignalGenerator, sprintf(':OUTPut1:STATe %d', 0));
    writeline(app.SignalGenerator, sprintf(':SOURce1:POWer:LEVel:IMMediate:AMPLitude %d', -135));
    enablePSUChannels(app, app.FilledPSUChannels, false);
    app.displayError(ME);
end
end