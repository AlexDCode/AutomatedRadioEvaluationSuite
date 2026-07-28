function [inputSpectrum, outputSpectrum, inputOBW, outputOBW, inputChannelPower, outputChannelPower, inputACPR, ...
    outputACPR, DCDrainCurrent, DCGateCurrent, DCDrainPower, DCGatePower] = measureModulated(app, inputRFPower, frequency)
    %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
    % DESCRIPTION:
    % This function measures the RF power spectrum, DC drain power, and DC gate power based on the specified input
    % RF power and test frequency. Calls the de-embedding function to get corrected input and output RF power
    %
    % INPUT:
    %   app            - The application object containing instrument configurations.
    %   inputRFPower   - The input RF power to the signal generator (dBm).
    %   frequency      - The test frequency for measurement.
    %
    % OUTPUT:
    %   inputSpectrum      - The corrected average and maximum input RF power sent or mesured in-situ at the test frequency (dBm)
    %   outputSpectrum     - The corrected average and maximum output RF power measured at the test frequency (dBm).
    %   inputOBW           - The input occupied bandwidth (Hz)
    %   outputOBW          - The output occupied bandwidth (Hz)
    %   inputChannelPower  - The input channel RMS power (dBm)
    %   outputChannelPower - The output channel RMS power (dBm)
    %   inputACPR          - The input adjacent channel power ratios [lower, upper] (dBc)
    %   outputACPR         - The output adjacent channel power ratios [lower, upper] (dBc)
    %   DCDrainCurrent     - The DC current delivered to the drain from each PSU (A)
    %   DCGateCurrent      - The DC current delivered to the gate from each PSU (A)
    %   DCDrainPower       - The DC power delivered to the drain (W).
    %   DCGatePower        - The DC power delivered to the gate (W).
    %
    % TODO:
    %   - The calibration for channel power measurements assumes a narrowband device where the losses of
    %   the signal bandwidth can be approximated to the center frequency
    %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

    %% Get the calibration mode
    calMode = app.CalibrationModeDropDown.Value;
    
    %% Configure the Signal Generator
    % Set the power of the signal generator.
    % Driver method, not raw SCPI: the power command differs per model
    % (the VXT has no ":SOURce1" node), so it must come from the instrument's
    % CommandSets/<Model>.json dialect.
    app.SignalGenerator.setPower(inputRFPower);
    waitForInstrument(app, app.SignalGenerator);

    %% Get the occupied bandwidth and channel power
    % Driver methods, not raw SCPI: every analyzer command in this function is
    % a registered entry in the command set, so CommandSets/<Model>.json can
    % re-dialect it without editing the measurement.
    if ~isempty(app.OutputSignalAnalyzer)
        outputOBW = measureOBW_(app, app.OutputSignalAnalyzer);
    end
    if ~isempty(app.InputSignalAnalyzer)
        inputOBW = measureOBW_(app, app.InputSignalAnalyzer);
    else
        inputOBW = NaN;
    end

    %% Get the output RF Power Spectrum
    startSpectrum_(app.OutputSignalAnalyzer, app.ReferenceLevelValueField.Value);

    % Trigger input RF Power Spectrum simultaneously
    if strcmp(calMode, 'In-Situ Couplers') & ~isempty(app.InputSignalAnalyzer)
        startSpectrum_(app.InputSignalAnalyzer, app.ReferenceLevelValueField.Value);
    end

    % Wait until the output signal analyzer is ready.
    app.OutputSignalAnalyzer.scpi('wai');
    waitForInstrument(app, app.OutputSignalAnalyzer);

    % Frequency axis, then the average (trace 1) and max-hold (trace 2) traces.
    freqs    = app.OutputSignalAnalyzer.getFrequencyAxis();
    avgPower = app.OutputSignalAnalyzer.readTraceNamed('TRACe1');
    maxPower = app.OutputSignalAnalyzer.readTraceNamed('TRACe2');

    % Create output power vs. frequency table
    MeasuredOutputRFPower = array2table([freqs, avgPower', maxPower'], 'VariableNames', {'Frequency','AveragePowerdBm', 'MaxPowerdBm'});

    % Clear the status register of the output signal analyzer.
    app.OutputSignalAnalyzer.scpi('cls');

    %% Get the input RF power
    if strcmp(calMode, 'In-Situ Couplers')
        % Wait until the input signal analyzer is ready.
        app.InputSignalAnalyzer.scpi('wai');
        waitForInstrument(app, app.InputSignalAnalyzer);

        % Fetch the trace data.
        avgPower = app.InputSignalAnalyzer.readTraceNamed('TRACe1');
        maxPower = app.InputSignalAnalyzer.readTraceNamed('TRACe2');

        % Frequency axis from this analyzer's own centre/span/points.
        freqs = app.InputSignalAnalyzer.getFrequencyAxis();

        MeasuredInputRFPower = array2table([freqs, avgPower', maxPower'], 'VariableNames', {'Frequency','AveragePowerdBm', 'MaxPowerdBm'});

        % Clear the status register of the input signal analyzer.
        app.InputSignalAnalyzer.scpi('cls');
    else
        % Use the signal generator configured power
        avgPower = inputRFPower.*ones(length(freqs),1)';
        maxPower = inputRFPower.*ones(length(freqs),1)';
        MeasuredInputRFPower = array2table([freqs, avgPower', maxPower'], 'VariableNames', {'Frequency','AveragePowerdBm', 'MaxPowerdBm'});
    end

    %% Correct the input and output power for the seleted calibration method
    % Apply de-embedding calibration based on user selected calibration mode.
    if MeasuredInputRFPower.Frequency == MeasuredOutputRFPower.Frequency
        % If both frequencies are the same, the interpolated calibration
        % factors will use the same set of test frequencies
        [inCal, outCal] = deembedPA(app, MeasuredOutputRFPower.Frequency, inputRFPower);
    else
        % Otherwise, each calibration factor will be obtained from the
        % respective test frequencies
        [inCal, ~] = deembedPA(app, MeasuredInputRFPower.Frequency, inputRFPower);
        [~, outCal] = deembedPA(app, MeasuredOutputRFPower.Frequency, inputRFPower);
    end

    
    % Subtract inCal to get actual PA input power.
    MeasuredInputRFPower.AveragePowerdBm = MeasuredInputRFPower.AveragePowerdBm - inCal;
    MeasuredInputRFPower.MaxPowerdBm = MeasuredInputRFPower.MaxPowerdBm - inCal;
    inputSpectrum = MeasuredInputRFPower;

    % Add outCal to get actual PA output power.
    MeasuredOutputRFPower.AveragePowerdBm = MeasuredOutputRFPower.AveragePowerdBm + outCal;
    MeasuredOutputRFPower.MaxPowerdBm = MeasuredOutputRFPower.MaxPowerdBm + outCal;
    outputSpectrum = MeasuredOutputRFPower;
    
    %% Measure the DC power
    % Measure DC Current and initalize outputs.
    DCDrainCurrent = zeros(1, length(app.FilledPSUChannels));
    DCGateCurrent = zeros(1, length(app.FilledPSUChannels));

    % Measure DC Power and intialize outputs.
    DCDrainPower = zeros(1, length(app.FilledPSUChannels)); 
    DCGatePower = zeros(1, length(app.FilledPSUChannels));   

    drainIndex = 1;
    gateIndex = 1;

    % Read voltage and current from all active channels.
    for i = 1:length(app.FilledPSUChannels)
        channel = app.FilledPSUChannels{i};
        [deviceChannel, psuName] = strtok(app.ChannelToDeviceMap(channel), ',');
        psuName = psuName(2:end);

        % Select PSU.
        if strcmp(psuName, 'PSUA')
            psu = app.PowerSupplyA;
        else
            psu = app.PowerSupplyB;
        end

        % Read Voltage and Current from the PSU through the driver, so the
        % measurement forms come from CommandSets/<Model>.json rather than
        % being hardcoded to the E36233A.
        ch = PSUInstCtrl.channelNumber(deviceChannel);
        DCVoltage = psu.measureVoltage(ch);
        DCCurrent = psu.measureCurrent(ch);
        % Calculate DC Power.
        channelPower = DCVoltage * DCCurrent;

        % Store the current and power based on channel designation.
        if ismember(channel, app.DrainChannels)
            DCDrainCurrent(drainIndex) = DCCurrent;
            DCDrainPower(drainIndex) = channelPower;
            drainIndex = drainIndex + 1;
        elseif ismember(channel, app.GateChannels)
            DCGateCurrent(gateIndex) = DCCurrent;
            DCGatePower(gateIndex) = channelPower;
            gateIndex = gateIndex + 1;
        end
    end

    %% Get ACPR
    % Set measurement noise bandwidth (channel bandwidth) to the max measured
    % occupied bandwidth
    channelBW = app.ChannelBandwidthValueField.Value*1e6;
    
    % Confgigure the signal analyzer ACP mode
    configureACP_(app, app.OutputSignalAnalyzer, channelBW);

    if ~isempty(app.InputSignalAnalyzer)
        configureACP_(app, app.InputSignalAnalyzer, channelBW);

        % Capture data
        app.InputSignalAnalyzer.setContinuous(false);
        app.InputSignalAnalyzer.scpi('init_imm');
    end

    % Capture data
    app.OutputSignalAnalyzer.setContinuous(false);
    app.OutputSignalAnalyzer.scpi('init_imm');

    % Wait until the output signal analyzer is ready.
    app.OutputSignalAnalyzer.scpi('wai');
    waitForInstrument(app, app.OutputSignalAnalyzer);

    % Get the calibration factors at the center frequency and assume a
    % small bandwidth
    [inCal, outCal] = deembedPA(app, frequency, inputRFPower);

    data = app.OutputSignalAnalyzer.readACP();
    outputChannelPower = data(1) + outCal; % [dBm] Channel Power
    outputACPR = data(2:3);       % [dBc] Lower and Upper Adjacent Channel Power

    if ~isempty(app.InputSignalAnalyzer)
        % Wait until the output signal analyzer is ready.
        app.InputSignalAnalyzer.scpi('wai');
        waitForInstrument(app, app.InputSignalAnalyzer);

        data = app.InputSignalAnalyzer.readACP();
        inputChannelPower = data(1) - inCal; % [dBm] Channel Power
        inputACPR = data(2:3);       % [dBc] Lower and Upper Adjacent Channel Power
    else
        inputChannelPower = inputRFPower;
        inputACPR = NaN;
    end
end

function obw = measureOBW_(app, sa)
    %MEASUREOBW_  Select and read the Occupied Bandwidth measurement on one
    % analyzer. Same command order the two inline copies used.
    sa.selectOBW();
    sa.setReferenceLevel(app.ReferenceLevelValueField.Value, "obw");

    % Wait until the analyzer is ready.
    sa.scpi('wai');
    waitForInstrument(app, sa);

    data = sa.readOBW();
    obw  = data(1);
end

function startSpectrum_(sa, refLeveldBm)
    %STARTSPECTRUM_  Select Swept SA, set the reference level, and trigger a
    % single acquisition without blocking — the caller waits, so the output
    % and input analyzers can be triggered back to back.
    sa.selectSweptSA();
    sa.setReferenceLevel(refLeveldBm);
    sa.setContinuous(false);
    sa.scpi('init_imm');
end

function configureACP_(app, sa, channelBWHz)
    %CONFIGUREACP_  Select the ACP measurement and configure it, in the order
    % ARES uses: carrier bandwidth, span, reference level, adjacent-channel
    % bandwidth, adjacent-channel offset.
    %
    % The error check matters here specifically: these six commands are sent
    % nowhere else, so the analyzer bring-up check in runPAMeasurement cannot
    % catch a dialect problem in them. An unnoticed rejection here means every
    % ACPR number in the run is measured with the wrong channel bandwidth or
    % offset. It costs two extra commands per point on a healthy instrument.
    sa.clearErrors();
    sa.selectACP();
    sa.configureACP(channelBWHz, ...
        app.SpanValueField.Value * 1e6, ...
        app.ReferenceLevelValueField.Value, ...
        app.ChannelOffsetValueField.Value * 1e6 + channelBWHz);
    sa.reportErrors("ACP setup");
end