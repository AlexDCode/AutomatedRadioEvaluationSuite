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
    % Driver methods, not raw SCPI: every command issued below is a registered
    % entry in the analyzer's command set, so CommandSets/<Model>.json can
    % re-dialect it for a non-Keysight analyzer without editing this function.
    % The two analyzers share one bring-up helper so they cannot drift apart.
    % setupClean tracks whether every instrument accepted its configuration.
    % A rejected command is not fatal on its own, but the operator must be
    % told before a long sweep produces a table of quietly wrong numbers.
    setupClean = true;

    if ~isempty(app.OutputSignalAnalyzer)
        setupClean = configureAnalyzer_(app.OutputSignalAnalyzer, app) && setupClean;
    end
    if ~isempty(app.InputSignalAnalyzer)
        if app.CalibrationModeDropDown.Value ~= "In-Situ Couplers"
                uialert(app.UIFigure, "An input signal analyzer was specified without selecting In-Situ Couplers calibration.", 'Application Error', 'Icon', 'error');
                exitFlag = 1;
        end

        setupClean = configureAnalyzer_(app.InputSignalAnalyzer, app) && setupClean;
    end

    % Set modulation in the signal generator.
    % Driver methods, not raw SCPI: the ARB bring-up is the most
    % model-specific sequence in the whole sweep. The SMW200A synthesises the
    % signal from a modulation type + symbol rate; the Keysight VXT has no
    % :DMODulation subsystem at all and instead plays a stored waveform file.
    % Routing through the driver lets CommandSets/<Model>.json decide.
    app.SignalGenerator.clearErrors();
    if app.StimulusDropDown.Value == "CW"
        app.SignalGenerator.setModulationState(false);
    elseif app.StimulusDropDown.Value == "Modulated"
        app.SignalGenerator.configureDigitalModulation( ...
            app.ModulationTypeDropDown.Value, app.SymbolRateValueField.Value);
    end
    setupClean = app.SignalGenerator.reportErrors("signal generator setup") && setupClean;

    % Tell the operator BEFORE the sweep starts. A rejected setup command
    % does not stop the run — the instrument may still produce usable data —
    % but silently proceeding is how a bad dialect turns into a bad dataset.
    if ~setupClean
        uialert(app.UIFigure, ...
            ["One or more instruments rejected part of their setup, so those " + ...
             "settings were not applied. See the MATLAB console for the " + ...
             "specific commands."; ""; ...
             "If you just added this instrument, check its " + ...
             "CommandSets/<Model>.json dialect before trusting the results."], ...
            'Instrument Setup Warning', 'Icon', 'warning');
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
            app.SignalGenerator.safeShutdown();

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
        app.SignalGenerator.setFrequencyCW(frequency);

        % Set center frequency in the signal analyzer.
        if ~isempty(app.OutputSignalAnalyzer)
            app.OutputSignalAnalyzer.setCenterFrequency(frequency);
        end
        if ~isempty(app.InputSignalAnalyzer)
            app.InputSignalAnalyzer.setCenterFrequency(frequency);
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
            app.SignalGenerator.setOutputState(true);
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
            app.SignalGenerator.setOutputState(false);

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
    app.SignalGenerator.safeShutdown();

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
        app.OutputSignalAnalyzer.setContinuous(true);
    end
    if ~isempty(app.InputSignalAnalyzer)
        app.InputSignalAnalyzer.setContinuous(true);
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
    try
        app.SignalGenerator.safeShutdown();
    catch
        % A dead generator link must not stop the PSU from being turned off,
        % nor swallow the original error before it reaches the user. RF still
        % on is bad; RF on AND the DC rails still up is worse.
    end
    enablePSUChannels(app, app.FilledPSUChannels, false);
    app.displayError(ME);
end
end

function ok = configureAnalyzer_(sa, app)
    %CONFIGUREANALYZER_  Bring one signal analyzer up for a PA sweep.
    %
    % Shared by the output and input analyzers, which must be configured
    % identically — they were previously two copies of the same eleven lines,
    % which is how they drift.
    %
    % Emits exactly the SCPI the legacy inline block did, in the same order,
    % but through the driver's command registry so a re-dialected analyzer
    % (CommandSets/<Model>.json) picks up its own forms.
    %
    % OUTPUT:
    %   ok - false if the analyzer rejected any command here. The whole point
    %        of checking at this boundary: this is where a newly added
    %        instrument's dialect gets exercised for the first time, and an
    %        unreported rejection means the sweep runs with a setting that was
    %        never applied.
    sa.clearErrors();
    sa.scpi('rst');
    sa.setSweepPoints(app.SweepPointsValueField.Value);
    sa.setSpan(app.SpanValueField.Value * 1E6);
    sa.setReferenceLevel(app.ReferenceLevelValueField.Value);
    sa.setTraceFormat('REAL', 64);
    sa.setByteOrder('SWAPped');

    if app.StimulusDropDown.Value == "Modulated"
        % Span for the Occupied Bandwidth measurement.
        sa.setOBWSpan(app.SpanValueField.Value * 1E6);

        % Trace averaging on trace 1, plus a max-hold trace 2.
        sa.configureAveraging(true, 100);
        sa.setTraceMode(2, 'MAXHold');
    end

    ok = sa.reportErrors("signal analyzer setup");
end