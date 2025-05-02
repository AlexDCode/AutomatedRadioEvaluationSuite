function [Gain, DE, PAE] = measureRFParameters(inputRFPower, outputRFPower, DCDrainPower)
    %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
    % DESCRIPTION:
    % This function calculates the RF Gain, Drain Efficiency (DE), and Power Added Efficiency (PAE) based on the 
    % specified input and output RF power and the DC power supplied to the drain.
    %
    % INPUT:
    %   inputRFPower    - Input RF power to the amplifier (in dBm).
    %   outputRFPower   - Output RF power from the amplifier (in dBm).
    %   DCDrainPower    - DC power supplied to the drain (in W).
    %
    % OUTPUT:
    %   Gain            - RF Gain (dB).
    %   DE              - Drain Efficiency (%).
    %   PAE             - Power Added Efficiency (%).
    %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
    
    % Calculate Gain in dB.
    Gain = outputRFPower - inputRFPower;

    % Convert the input and output power from dBm to watts.
    inputRFPowerW = dBm2W(inputRFPower);
    outputRFPowerW = dBm2W(outputRFPower);

    % Calculate Drain Efficiency (DE) as a percentage.
    DE = (outputRFPowerW ./ DCDrainPower) * 100;

    % Calculate Power Added Efficiency (PAE) as a percentage.
    PAE = ((outputRFPowerW - inputRFPowerW) ./ DCDrainPower) * 100;

    % Remove negative efficiencies as they occur when the PA is off (Class C).
    DE(DE<0) = NaN;
    PAE(PAE<0) = NaN;
end

