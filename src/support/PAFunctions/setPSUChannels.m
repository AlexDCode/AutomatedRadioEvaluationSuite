function setPSUChannels(app, deviceChannel, voltage, current)
    %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
    % DESCRIPTION:
    % This function sets the voltage and current for a specific power supply channel based on the application's 
    % channel-to-device mapping. It determines the correct physical channel and PSU (A or B), and applies the 
    % specified settings via SCPI commands. The function handles numeric or string inputs for voltage and current 
    % values, ensuring compatibility with SCPI command formatting.
    %
    % INPUT:
    %   app           - App object containing power supply configurations and the channel-to-device mapping.
    %   deviceChannel - Logical channel name (e.g., 'CH1') as defined in the mapping structure.
    %   voltage       - Desired voltage for the channel (numeric or string).
    %   current       - Desired current limit for the channel (numeric or string).
    %
    % OUTPUT:
    %   None
    %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

    % Get the correct PSU object and channel number.
    [physicalChannel, psuName] = strtok(app.ChannelToDeviceMap(deviceChannel), ',');
    psuName = psuName(2:end);  

    % Select the correct PSU object.
    switch upper(psuName)
        case 'PSUA'
            PSU = app.PowerSupplyA;
        case 'PSUB'
            PSU = app.PowerSupplyB;
    end

    % Convert voltage and current to strings if needed.
    voltageStr = num2str(voltage);
    currentStr = num2str(current);
    
    % Apply voltage and current values to the PSU channel.
    writeline(PSU, sprintf(':APPLy %s,%s,%s', physicalChannel, voltageStr, currentStr));
end