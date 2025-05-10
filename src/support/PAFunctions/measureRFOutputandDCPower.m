function [OutputRFPower, DCDrainCurrent, DCGateCurrent, DCDrainPower, DCGatePower] = measureRFOutputandDCPower(app, inputRFPower, frequency)
    %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
    % DESCRIPTION:
    % This function measures the output RF power, DC drain power, and DC gate power based on the specified input
    % RF power and test frequency.
    %
    % INPUT:
    %   app            - The application object containing instrument configurations.
    %   inputRFPower   - The input RF power to the signal generator (dBm).
    %   frequency      - The test frequency for measurement.
    %
    % OUTPUT:
    %   OutputRFPower  - The maximum output RF power measured at the test frequency (dB).
    %   DCDrainPower   - The DC power delivered to the drain (W).
    %   DCGatePower    - The DC power delivered to the gate (W).
    %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

    % Set the power of the signal generator.
    writeline(app.SignalGenerator, sprintf(':SOURce1:POWer:LEVel:IMMediate:AMPLitude %g', inputRFPower));
    waitForInstrument(app, app.SignalGenerator);

    % Turn on the signal generator.
    writeline(app.SignalGenerator, sprintf(':OUTPut1:STATe %d', 1));

    % Initiate the measurement process in the spectrum analyzer.
    writeline(app.SpectrumAnalyzer, sprintf(':INITiate:CONTinuous %d', 0));
    writeline(app.SpectrumAnalyzer, ':INITiate:IMMediate');

    % Wait until the spectrum analyzer is ready.
    writeline(app.SpectrumAnalyzer, '*WAI');
    waitForInstrument(app, app.SpectrumAnalyzer); 

    % Get center frequency, span, and sweep points to select measured frequency index 
    fc = double(writeread(app.SpectrumAnalyzer, sprintf(':FREQ:RF:CENT?')));
    span = double(writeread(app.SpectrumAnalyzer, sprintf(':FREQ:SPAN?')));
    N = double(writeread(app.SpectrumAnalyzer, sprintf(':SWE:POIN?')));

    % Generate frequency axis based on center frequency, span, and number of points.
    freqs = linspace(fc - span/2, fc + span/2, N)';
    
    % Fetch the trace data.
    writeline(app.SpectrumAnalyzer, sprintf(':TRACe:DATA? %s', 'TRACe1'));
    trace_data = readbinblock(app.SpectrumAnalyzer, 'double');

    data = array2table([freqs, trace_data'], 'VariableNames', {'Freq','Pout'});
    
    % Extract output power at the specified frequency.
    OutputRFPower = data(data.Freq==frequency, :).Pout;

    % Clear the status register of the spectrum analyzer.
    writeline(app.SpectrumAnalyzer, '*CLS');

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