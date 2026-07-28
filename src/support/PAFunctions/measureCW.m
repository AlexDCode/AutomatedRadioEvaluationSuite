function [InputRFPower, OutputRFPower, DCDrainCurrent, DCGateCurrent, DCDrainPower, DCGatePower] = measureCW(app, inputRFPower, frequency)
    %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
    % DESCRIPTION:
    % This function measures the RF power, DC drain power, and DC gate power based on the specified input
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
    % Driver method, not raw SCPI: the power command differs per model
    % (the VXT has no ":SOURce1" node), so it must come from the instrument's
    % CommandSets/<Model>.json dialect.
    app.SignalGenerator.setPower(inputRFPower);
    waitForInstrument(app, app.SignalGenerator);

    %% Get the input RF power
    if strcmp(calMode, 'In-Situ Couplers')
        % Measure the input power with in-situ coupler.
        % measurePowerAt performs the same sequence this function used to
        % inline (INIT:CONT 0, INIT:IMM, *WAI, OPC poll, centre/span/points,
        % trace fetch, *CLS) and emits the same SCPI, but through the command
        % registry so the analyzer's dialect governs it.
        %
        % NOTE: it selects the trace bin NEAREST the requested frequency and
        % warns if that is more than one bin away. The inline version used an
        % exact floating-point == match, which silently returned empty
        % whenever the test frequency did not land precisely on the bin grid.
        MeasuredInputRFPower = app.InputSignalAnalyzer.measurePowerAt(frequency);
    else
        % Use the signal generator configured power
        MeasuredInputRFPower = inputRFPower;
    end

    %% Get the output RF power
    % Same single-shot acquisition + nearest-bin read as the input path above.
    MeasuredOutputRFPower = app.OutputSignalAnalyzer.measurePowerAt(frequency);

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
end