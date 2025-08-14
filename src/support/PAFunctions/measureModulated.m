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
    %   - The calibration assumes a narrowband device where the losses of
    %   the signal bandwidth can be approximated to the center frequency
    %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

    %% Get the calibration mode
    calMode = app.CalibrationModeDropDown.Value;
    
    %% Configure the Signal Generator
    % Set the power of the signal generator.
    writeline(app.SignalGenerator, sprintf(':SOURce1:POWer:LEVel:IMMediate:AMPLitude %g', inputRFPower));
    waitForInstrument(app, app.SignalGenerator);

    %% Get the occupied bandwidth and channel power
    if ~isempty(app.OutputSignalAnalyzer)
        writeline(app.OutputSignalAnalyzer, sprintf(':INITiate:OBWidth'));
        writeline(app.OutputSignalAnalyzer, sprintf(':DISPlay:OBWidth:VIEW:WINDow:TRACe:Y:SCALe:RLEVel %d', app.ReferenceLevelValueField.Value));

        % Wait until the input signal analyzer is ready.
        writeline(app.OutputSignalAnalyzer, '*WAI');
        waitForInstrument(app, app.OutputSignalAnalyzer);

        writeline(app.OutputSignalAnalyzer, sprintf(':READ:OBWidth?'));
        data = readbinblock(app.OutputSignalAnalyzer, 'double'); % Read binary data

        outputOBW = data(1);
    end
    if ~isempty(app.InputSignalAnalyzer)
        writeline(app.InputSignalAnalyzer, sprintf(':INITiate:OBWidth'))
        writeline(app.InputSignalAnalyzer, sprintf(':DISPlay:OBWidth:VIEW:WINDow:TRACe:Y:SCALe:RLEVel %d', app.ReferenceLevelValueField.Value));

        % Wait until the input signal analyzer is ready.
        writeline(app.InputSignalAnalyzer, '*WAI');
        waitForInstrument(app, app.InputSignalAnalyzer); 
        
        writeline(app.InputSignalAnalyzer, sprintf(':READ:OBWidth?'));
        data = readbinblock(app.InputSignalAnalyzer, 'double');
        inputOBW = data(1);
    else
        inputOBW = NaN;
    end

    %% Get the output RF Power Spectrum
    writeline(app.OutputSignalAnalyzer, sprintf(':INITiate:SANalyzer'));
    writeline(app.OutputSignalAnalyzer, sprintf(':DISPlay:WINDow:TRACe:Y:SCALe:RLEVel %d', app.ReferenceLevelValueField.Value));
    writeline(app.OutputSignalAnalyzer, sprintf(':INITiate:CONTinuous %d', 0));
    writeline(app.OutputSignalAnalyzer, ':INITiate:IMMediate');

    % Trigger input RF Power Spectrum simultaneously
    if strcmp(calMode, 'In-Situ Couplers') & ~isempty(app.InputSignalAnalyzer)
        writeline(app.InputSignalAnalyzer, sprintf(':INITiate:SANalyzer'));
        writeline(app.InputSignalAnalyzer, sprintf(':DISPlay:WINDow:TRACe:Y:SCALe:RLEVel %d', app.ReferenceLevelValueField.Value));
        writeline(app.InputSignalAnalyzer, sprintf(':INITiate:CONTinuous %d', 0));
        writeline(app.InputSignalAnalyzer, ':INITiate:IMMediate');
    end

    % Wait until the output signal analyzer is ready.
    writeline(app.OutputSignalAnalyzer, '*WAI');
    waitForInstrument(app, app.OutputSignalAnalyzer); 

    % Get center frequency, span, and sweep points to select measured frequency index 
    fc = double(writeread(app.OutputSignalAnalyzer, sprintf(':FREQ:RF:CENT?')));
    span = double(writeread(app.OutputSignalAnalyzer, sprintf(':FREQ:SPAN?')));
    N = double(writeread(app.OutputSignalAnalyzer, sprintf(':SWE:POIN?')));

    % Generate frequency axis based on center frequency, span, and number of points.
    freqs = linspace(fc - span/2, fc + span/2, N)';
    
    % Fetch the trace data.
    writeline(app.OutputSignalAnalyzer, sprintf(':TRACe:DATA? %s', 'TRACe1'));
    avgPower = readbinblock(app.OutputSignalAnalyzer, 'double');
    writeline(app.OutputSignalAnalyzer, sprintf(':TRACe:DATA? %s', 'TRACe2'));
    maxPower = readbinblock(app.OutputSignalAnalyzer, 'double');
    
    % Create output power vs. frequency table
    MeasuredOutputRFPower = array2table([freqs, avgPower', maxPower'], 'VariableNames', {'Frequency','AveragePowerdBm', 'MaxPowerdBm'});

    % Clear the status register of the output signal analyzer.
    writeline(app.OutputSignalAnalyzer, '*CLS');

    %% Get the input RF power
    if strcmp(calMode, 'In-Situ Couplers')
        % Wait until the input signal analyzer is ready.
        writeline(app.InputSignalAnalyzer, '*WAI');
        waitForInstrument(app, app.InputSignalAnalyzer); 

        % Fetch the trace data.
        writeline(app.InputSignalAnalyzer, sprintf(':TRACe:DATA? %s', 'TRACe1'));
        avgPower = readbinblock(app.InputSignalAnalyzer, 'double');
        writeline(app.InputSignalAnalyzer, sprintf(':TRACe:DATA? %s', 'TRACe2'));
        maxPower = readbinblock(app.InputSignalAnalyzer, 'double');
        
        % Get center frequency, span, and sweep points to select measured frequency index 
        fc = double(writeread(app.InputSignalAnalyzer, sprintf(':FREQ:RF:CENT?')));
        span = double(writeread(app.InputSignalAnalyzer, sprintf(':FREQ:SPAN?')));
        N = double(writeread(app.InputSignalAnalyzer, sprintf(':SWE:POIN?')));

        % Generate frequency axis based on center frequency, span, and number of points.
        freqs = linspace(fc - span/2, fc + span/2, N)';

        MeasuredInputRFPower = array2table([freqs, avgPower', maxPower'], 'VariableNames', {'Frequency','AveragePowerdBm', 'MaxPowerdBm'});

        % Clear the status register of the input signal analyzer.
        writeline(app.InputSignalAnalyzer, '*CLS');
    else
        % Use the signal generator configured power
        avgPower = inputRFPower.*ones(length(freqs),1)';
        maxPower = inputRFPower.*ones(length(freqs),1)';
        MeasuredInputRFPower = array2table([freqs, avgPower', maxPower'], 'VariableNames', {'Frequency','AveragePowerdBm', 'MaxPowerdBm'});
    end

    %% Correct the input and output power for the seleted calibration method
    % Apply de-embedding calibration based on user selected calibration mode.
    % TODO: This assumes a narrowband device by approximating the
    % calibration from the center frequency around the signal bandwidth
    [inCal, outCal] = deembedPA(app, frequency, inputRFPower);
    
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

        % Read Voltage from PSU.
        DCVoltage = str2double(writeread(psu, sprintf(':MEASure:SCALar:VOLTage:DC? %s', deviceChannel)));
        % Read Current from PSU
        DCCurrent = str2double(writeread(psu, sprintf(':MEASure:SCALar:CURRent:DC? %s', deviceChannel)));
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
    systemOBW = max(inputOBW, outputOBW);
    
    % Confgigure the signal analyzer ACP mode
    writeline(app.OutputSignalAnalyzer, sprintf(':INITiate:ACP'));
    writeline(app.OutputSignalAnalyzer, sprintf(':SENSe:MCPower:CARRier:LIST:BANDwidth:INTegration %d', systemOBW)); % Carrier bandwidth
    writeline(app.OutputSignalAnalyzer, sprintf(':SENSe:ACPower:FREQuency:SPAN %d', app.SpanValueField.Value*1e6)); % Measurement span
    writeline(app.OutputSignalAnalyzer, sprintf(':DISPlay:ACPower:VIEW:WINDow:TRACe:Y:SCALe:RLEVel %d', app.ReferenceLevelValueField.Value)); % Reference Level
    writeline(app.OutputSignalAnalyzer, sprintf(':SENSe:ACPower:OFFSet:OUTer:LIST:BANDwidth:INTegration %d', systemOBW)); % Adjacent channel bandwidth
    writeline(app.OutputSignalAnalyzer, sprintf(':SENSe:ACPower:OFFSet:OUTer:LIST:FREQuency %d', app.ChannelOffsetValueField.Value*1e6 + systemOBW)); % Adjacent channel offset
        
    if ~isempty(app.InputSignalAnalyzer)
        writeline(app.InputSignalAnalyzer, sprintf(':INITiate:ACP'));
        writeline(app.InputSignalAnalyzer, sprintf(':SENSe:MCPower:CARRier:LIST:BANDwidth:INTegration %d', systemOBW)); % Carrier bandwidth
        writeline(app.InputSignalAnalyzer, sprintf(':SENSe:ACPower:FREQuency:SPAN %d', app.SpanValueField.Value*1e6)); % Measurement span
        writeline(app.InputSignalAnalyzer, sprintf(':DISPlay:ACPower:VIEW:WINDow:TRACe:Y:SCALe:RLEVel %d', app.ReferenceLevelValueField.Value)); % Reference Level
        writeline(app.InputSignalAnalyzer, sprintf(':SENSe:ACPower:OFFSet:OUTer:LIST:BANDwidth:INTegration %d', systemOBW)); % Adjacent channel bandwidth
        writeline(app.InputSignalAnalyzer, sprintf(':SENSe:ACPower:OFFSet:OUTer:LIST:FREQuency %d', app.ChannelOffsetValueField.Value*1e6 + systemOBW)); % Adjacent channel offset
        
        % Capture data
        writeline(app.InputSignalAnalyzer, sprintf(':INITiate:CONTinuous %d', 0));
        writeline(app.InputSignalAnalyzer, ':INITiate:IMMediate');
    end

    % Capture data
    writeline(app.OutputSignalAnalyzer, sprintf(':INITiate:CONTinuous %d', 0));
    writeline(app.OutputSignalAnalyzer, ':INITiate:IMMediate');
    
    % Wait until the output signal analyzer is ready.
    writeline(app.OutputSignalAnalyzer, '*WAI');
    waitForInstrument(app, app.OutputSignalAnalyzer); 

    writeline(app.OutputSignalAnalyzer, sprintf(':READ:ACP?')); % Read ACPR data
    data = readbinblock(app.OutputSignalAnalyzer, 'double');
    outputChannelPower = data(1) + outCal; % [dBm] Channel Power
    outputACPR = data(2:3);       % [dBc] Lower and Upper Adjacent Channel Power

    if ~isempty(app.InputSignalAnalyzer)
        % Wait until the output signal analyzer is ready.
        writeline(app.InputSignalAnalyzer, '*WAI');
        waitForInstrument(app, app.InputSignalAnalyzer); 

        writeline(app.InputSignalAnalyzer, sprintf(':READ:ACP?')); % Read ACPR data
        data = readbinblock(app.InputSignalAnalyzer, 'double');
        inputChannelPower = data(1) - inCal; % [dBm] Channel Power
        inputACPR = data(2:3);       % [dBc] Lower and Upper Adjacent Channel Power
    else
        inputChannelPower = inputRFPower;
        inputACPR = NaN;
    end
end