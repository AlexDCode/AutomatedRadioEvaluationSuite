function absoluteGain = calculateAbsoluteAntennaGain(realizedGain, returnLossdB)
    %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
    % DESCRIPTION:
    % This function calculates the absolute gain of a test antenna in 
    % decibels relative to an isotropic radiator (dBi). The gain is computed 
    % based on the input realized gain and the return loss.
    % 
    % INPUT:
    %   realizedGain    - A scalar or vector containing the realized antenna gain in dBi for the test antenna.
    %   sParameter_dB   - A scalar or vector of S22 values (in dB), representing the magnitude of return loss between two antennas.
    %
    % OUTPUT:
    %   absoluteGain    - A vector containing the calculated absolute antenna gain in dBi for the test antenna.
    %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
    
    % Convert Return Loss to linear scale
    returnLoss = dB2A(returnLossdB);

    % Convert gain to magnitude
    realizedGainMagnitude = dB2P(realizedGain);

    % Calculate the absolute gain
    absoluteGainMagnitude = realizedGainMagnitude ./ (1 - returnLoss.^2);
    absoluteGain = P2dB(absoluteGainMagnitude);
end