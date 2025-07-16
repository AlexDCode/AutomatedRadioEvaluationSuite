function [InputRFPower, OutputRFPower, DCDrainCurrent, DCGateCurrent, DCDrainPower, DCGatePower] = measureRFOutputandDCPower(app, inputRFPower, frequency)
    %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
    % DESCRIPTION:
    % This function measures the output RF power, DC drain power, and DC gate power based on the specified input
    % RF power and test frequency. Calls the de-embedding function to get corrected input and output RF power
    %
    % INPUT:
    %   app            - The application object containing instrument configurations.
    %   inputRFPower   - The input RF power to the signal generator (dBm).
    %   frequency      - The test frequency for measurement.
    %
    % OUTPUT:
    %   InputRFPower   - The corrected input RF power sent or mesured in-situ at the test frequency (dBm)
    %   OutputRFPower  - The corrected output RF power measured at the test frequency (dBm).
    %   DCDrainPower   - The DC power delivered to the drain (W).
    %   DCGatePower    - The DC power delivered to the gate (W).
    %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

    %% Get the calibration mode
    calMode = app.CalibrationModeDropDown.Value;
    
    %% Configure the Signal Generator
    % Set the power of the signal generator.
    writeline(app.SignalGenerator, sprintf(':SOURce1:POWer:LEVel:IMMediate:AMPLitude %g', inputRFPower));
    waitForInstrument(app, app.SignalGenerator);

    % Turn on the signal generator.
    writeline(app.SignalGenerator, sprintf(':OUTPut1:STATe %d', 1));

    %% Get the input RF power
    if strcmp(calMode, 'In-Situ Couplers')
        % Measure the input power with in-situ coupler
        % Initiate the measurement process in the input signal analyzer.
        writeline(app.InputSignalAnalyzer, sprintf(':INITiate:CONTinuous %d', 0));
        writeline(app.InputSignalAnalyzer, ':INITiate:IMMediate');
    
        % Wait until the input signal analyzer is ready.
        writeline(app.InputSignalAnalyzer, '*WAI');
        waitForInstrument(app, app.InputSignalAnalyzer); 
    
        % Get center frequency, span, and sweep points to select measured frequency index 
        fc = double(writeread(app.InputSignalAnalyzer, sprintf(':FREQ:RF:CENT?')));
        span = double(writeread(app.InputSignalAnalyzer, sprintf(':FREQ:SPAN?')));
        N = double(writeread(app.InputSignalAnalyzer, sprintf(':SWE:POIN?')));
    
        % Generate frequency axis based on center frequency, span, and number of points.
        freqs = linspace(fc - span/2, fc + span/2, N)';
        
        % Fetch the trace data.
        writeline(app.InputSignalAnalyzer, sprintf(':TRACe:DATA? %s', 'TRACe1'));
        trace_data = readbinblock(app.InputSignalAnalyzer, 'double');
    
        data = array2table([freqs, trace_data'], 'VariableNames', {'Freq','Pout'});
        
        % Extract output power at the specified frequency.
        MeasuredInputRFPower = data(data.Freq==frequency, :).Pout;
        
        % Clear the status register of the input signal analyzer.
        writeline(app.InputSignalAnalyzer, '*CLS');

    else
        % Use the signal generator configured power
        MeasuredInputRFPower = inputRFPower;
    end

    %% Get the output RF power
    % Initiate the measurement process in the output signal analyzer.
    writeline(app.OutputSignalAnalyzer, sprintf(':INITiate:CONTinuous %d', 0));
    writeline(app.OutputSignalAnalyzer, ':INITiate:IMMediate');

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
    trace_data = readbinblock(app.OutputSignalAnalyzer, 'double');

    data = array2table([freqs, trace_data'], 'VariableNames', {'Freq','Pout'});
    
    % Extract output power at the specified frequency.
    MeasuredOutputRFPower = data(data.Freq==frequency, :).Pout;

    % Clear the status register of the output signal analyzer.
    writeline(app.OutputSignalAnalyzer, '*CLS');

    %% Correct the input and output power for the seleted calibration method
    % Apply de-embedding calibration based on user selected calibration mode.
    [inCal, outCal] = deembedPA(app, frequency, MeasuredInputRFPower);
    
    % Subtract inCal to get actual PA input power.
    InputRFPower = MeasuredInputRFPower - inCal;

    % Add outCal to get actual PA output power.
    OutputRFPower = MeasuredOutputRFPower + outCal;

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
end