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
% *TODO:* Verify if gate PSU data is saved to results table in individual PSU channel columns
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

    % Check if minimum needed instruments are connected
    connectedSA = ~isempty(app.OutputSignalAnalyzer.ResourceName) | (~isempty(app.OutputSignalAnalyzer.ResourceName) & ~isempty(app.InputSignalAnalyzer.ResourceName));
    connectedSG = ~isempty(app.SignalGenerator.ResourceName);
    if ~(connectedSA & connectedSG)
        error('Required instruments not connected.')
    end

    % Configure the signal analyzer settings.
    if ~isempty(app.OutputSignalAnalyzer.ResourceName)
        writeline(app.OutputSignalAnalyzer, sprintf(':SENSe:SWEep:POINts %d', app.SweepPointsValueField.Value));
        writeline(app.OutputSignalAnalyzer, sprintf(':SENSe:FREQuency:SPAN %g', app.SpanValueField.Value * 1E6));
        writeline(app.OutputSignalAnalyzer, sprintf(':DISPlay:WINDow:TRACe:Y:SCALe:RLEVel %g', app.ReferenceLevelValueField.Value));
        writeline(app.OutputSignalAnalyzer, sprintf(':FORMat:TRACe:DATA %s,%d', 'REAL', 64));
        writeline(app.OutputSignalAnalyzer, sprintf(':FORMat:BORDer %s', 'SWAPped'));
    end
    if ~isempty(app.InputSignalAnalyzer.ResourceName)
        writeline(app.InputSignalAnalyzer, sprintf(':SENSe:SWEep:POINts %d', app.SweepPointsValueField.Value));
        writeline(app.InputSignalAnalyzer, sprintf(':SENSe:FREQuency:SPAN %g', app.SpanValueField.Value * 1E6));
        writeline(app.InputSignalAnalyzer, sprintf(':DISPlay:WINDow:TRACe:Y:SCALe:RLEVel %g', app.ReferenceLevelValueField.Value));
        writeline(app.InputSignalAnalyzer, sprintf(':FORMat:TRACe:DATA %s,%d', 'REAL', 64));
        writeline(app.InputSignalAnalyzer, sprintf(':FORMat:BORDer %s', 'SWAPped'));
    end

    % Create a progress dialog to inform the user of the progress.
    d = uiprogressdlg(app.UIFigure, 'Title', 'Measurement Progress', 'Cancelable', 'on');
    measurementStartTime = datetime('now');
    tic; lastTime = toc; totalTime = 0;

    i = 1;
    statePSU = false; % Flag for PSU output enable
    while i <= height(parametersTable)
        % Update timing info.
        now = toc;
        elapsedTime = now - lastTime;
        totalTime = totalTime + elapsedTime;
        lastTime = now;

        % Calculate progress and time estimates.
        progress = i / totalMeasurements;
        avgTime = totalTime / i;
        remainingTime = avgTime * (totalMeasurements - i);

        % Update the progress dialog window.
        d.Value = progress;
        d.CancelText = 'Stop Test';
        d.Message = sprintf("Measurement Progress: %d%%\nElapsed Time: %s\nRemaining Time: %s", ...
            round(100 * progress), ...
            string(duration(0, 0, round(totalTime))), ...
            string(duration(0, 0, round(remainingTime))));


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
        if ~isempty(app.OutputSignalAnalyzer.ResourceName)
            writeline(app.OutputSignalAnalyzer, sprintf(':SENSe:FREQuency:CENTer %g', frequency));
        end
        if ~isempty(app.InputSignalAnalyzer.ResourceName)
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
            % When the PSU is switched back on use the PSU delay, save
            % quiescent current, and turn signal generator on 

            % Enable all channels.
            enablePSUChannels(app, app.FilledPSUChannels, true);
            statePSU = true;
            
            % Longer delay to allow PA to settle.
            pause(app.PSUDelaySpinner.Value);

            % Measure quiescent current
            [~, ~, DCDrainQuiescentCurrent, DCGateQuiescentCurrent, ~, ~] = measureRFOutputandDCPower(app, RFInputPower, frequency);
    
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

            % Turn on signal generator.
            writeline(app.SignalGenerator, sprintf(':OUTPut1:STATe %d', 1));
            pause(app.PAMeasurementDelayValueField.Value);
        end

        % Small delay.
        pause(app.PAMeasurementDelayValueField.Value);

        % Measure RF Power, DC Current, and DC Power.
        [RFInputPower, RFOutputPower, DCDrainCurrent, DCGateCurrent, DCDrainPower, DCGatePower] = measureRFOutputandDCPower(app, RFInputPower, frequency);

        % Calculate total DC Current (A).
        TotalDCDrainCurrent = sum(DCDrainCurrent);
        TotalDCGateCurrent = sum(DCGateCurrent);

        % Calculate total DC Power (W).
        TotalDCDrainPower = sum(DCDrainPower);
        TotalDCGatePower = sum(DCGatePower);

        % Calculate Gain.
        Gain = RFOutputPower - RFInputPower;

        % Calculate DE and PAE.
        if TotalDCDrainPower == 0
            DE = 0;
            PAE = 0;
        else
            [~, DE, PAE] = measureRFParameters(RFInputPower, RFOutputPower, TotalDCDrainPower);
        end

        % Add to results table
        resultsTable.("Frequency (MHz)")(i) = frequency/1e6;
        resultsTable.("RF Input Power (dBm)")(i) = RFInputPower;
        resultsTable.("RF Output Power (dBm)")(i) = RFOutputPower;
        resultsTable.Gain(i) = Gain;
        resultsTable.("Total DC Drain Current (A)")(i) = TotalDCDrainCurrent;
        resultsTable.("Total DC Gate Current (A)")(i) = TotalDCGateCurrent;
        resultsTable.("Total DC Drain Power (W)")(i) = TotalDCDrainPower;
        resultsTable.("Total DC Gate Power (W)")(i) = TotalDCGatePower;
        resultsTable.("DE (%)")(i) = DE;
        resultsTable.("PAE (%)")(i) = PAE;

        for ch = 1:length(app.FilledPSUChannels)
            resultsTable.(sprintf('Channel %d Voltages (V)', ch))(i) = parametersTable.(sprintf('Channel %d Voltage', ch))(i);
            resultsTable.(sprintf('Channel %d DC Current (A)', ch))(i) = DCDrainCurrent(1, ch);
            resultsTable.(sprintf('Channel %d DC Power (W)', ch))(i) = DCDrainPower(1, ch);
        end


        %% Test safety options
        % Minimum Gain: Skip remaining power sweep when below threshold
        if app.MinimumGainSafetyState % Only if safety option is active
            if Gain < app.MinimumGainSpinner.Value
                % Turn off signal generator.
                writeline(app.SignalGenerator, sprintf(':OUTPut1:STATe %d', 0));
        
                % Disable all channels.
                enablePSUChannels(app, app.FilledPSUChannels, false);
                statePSU = false;

                % Plot at current sweep  
                combinedData = resultsTable;
    
                % Remove spaces and parenthesis from the variable names.
                combinedData.Properties.VariableNames = regexprep(combinedData.Properties.VariableNames, ' ', '');
                combinedData.Properties.VariableNames = regexprep(combinedData.Properties.VariableNames, '(', '');
                combinedData.Properties.VariableNames = regexprep(combinedData.Properties.VariableNames, ')', '');
                combinedData.Properties.VariableNames = regexprep(combinedData.Properties.VariableNames, '%', '');
    
                % Process data
                processPAData(app, combinedData);
                
                % Index the data for the current frequency and power supply values
                app.FrequencySingleDropDown.Value = string(combinedData.FrequencyMHz(i));
                for ch = 1:length(app.PA_PSU_Channels)
                    app.PA_PSU_SelectedVoltages(ch) = resultsTable.(sprintf('Channel %d Voltages (V)', ch))(i);
                end
    
                % Plot with updated dropdown values.
                plotPASingleMeasurement(app);
                plotPASweepMeasurement(app);
                plotPADCMeasurement(app);

                % Pause for cooldown
                pause(app.CooldownTimeSpinner.Value)

                % Skip remaining power sweep if gain is below threshold
                i = idxPowerSweep(end)+1;
            end
        end

        % Cooldown Time: Wait between power sweeps for each parameter combination
        if i == idxPowerSweep(end)
            if i == totalMeasurements
                break;
            end
            % Turn off signal generator.
            writeline(app.SignalGenerator, sprintf(':OUTPut1:STATe %d', 0));

            % Disable all channels.
            enablePSUChannels(app, app.FilledPSUChannels, false);
            statePSU = false;


            % Plot at current sweep  
            combinedData = resultsTable;

            % Remove spaces and parenthesis from the variable names.
            combinedData.Properties.VariableNames = regexprep(combinedData.Properties.VariableNames, ' ', '');
            combinedData.Properties.VariableNames = regexprep(combinedData.Properties.VariableNames, '(', '');
            combinedData.Properties.VariableNames = regexprep(combinedData.Properties.VariableNames, ')', '');
            combinedData.Properties.VariableNames = regexprep(combinedData.Properties.VariableNames, '%', '');

            % Process data
            processPAData(app, combinedData);
            
            % Index the data for the current frequency and power supply values
            app.FrequencySingleDropDown.Value = string(combinedData.FrequencyMHz(i));
            for ch = 1:length(app.PA_PSU_Channels)
                app.PA_PSU_SelectedVoltages(ch) = resultsTable.(sprintf('Channel %d Voltages (V)', ch))(i);
            end

            % Plot with updated dropdown values.
            plotPASingleMeasurement(app);
            plotPASweepMeasurement(app);
            plotPADCMeasurement(app);

            % Pause for cooldown in last power sweep row
            pause(app.CooldownTimeSpinner.Value)
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
    if ~isempty(app.OutputSignalAnalyzer.ResourceName)
        writeline(app.OutputSignalAnalyzer, sprintf(':INITiate:CONTinuous %d', 1));
    end
    if ~isempty(app.InputSignalAnalyzer.ResourceName)
        writeline(app.InputSignalAnalyzer, sprintf(':INITiate:CONTinuous %d', 1));
    end

    % Remove zero rows that may be left empty during safety checks
    resultsTable(all(resultsTable{:,:} == 0, 2), :) = [];

    % Save table as a variable in the app
    app.PAMeasurementsTable = resultsTable;

    % Save the complete measurement data.
    fullFilename = saveData(resultsTable);
    loadData(app, 'PA', fullFilename);

catch ME
    % If an error occurs during the PA test measurement, then
    % for safety reasons the instruments will be turned off.
    writeline(app.SignalGenerator, sprintf(':OUTPut1:STATe %d', 0));
    writeline(app.SignalGenerator, sprintf(':SOURce1:POWer:LEVel:IMMediate:AMPLitude %d', -135));
    enablePSUChannels(app, app.FilledPSUChannels, false);
    app.displayError(ME);
end
end