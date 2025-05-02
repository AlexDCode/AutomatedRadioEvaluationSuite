function [Gain, DE, PAE] = measureRFParameters(inputRFPower, outputRFPower, DCDrainPower)
    %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
    % This function calculates the RF Gain, the Drain Efficiency (DE), and 
    % the Power Added Efficiency (PAE) based on the input/output RF power, 
    % and the DC power input.
    %
    % INPUT PARAMETERS
    %   inputRFPowerdBm: Input RF power in (dBm).
    %   outputRFPower:   Output RF power in (dBm).
    %   DCPower:         DC power in (watts).
    %
    % OUTPUT PARAMETERS
    %   Gain:            RF Gain.
    %   DE:              Drain Efficiency (%).
    %   PAE:             Power Added Efficiency (%).
    %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
    
    % Calculate Gain in dB.
    Gain = outputRFPower - inputRFPower;

    % Convert the input and output power from dBm to watts.
    inputRFPowerW = dBm2W(inputRFPower);
    outputRFPowerW = dBm2W(outputRFPower);

    % Calculate the DE and the PAE.
    DE = (outputRFPowerW ./ DCDrainPower) * 100;
    PAE = ((outputRFPowerW - inputRFPowerW) ./ DCDrainPower) * 100;

    % Remove negative efficiencies as they occur when the PA is off (Class C)
    DE(DE<0) = NaN;
    PAE(PAE<0) = NaN;
end

