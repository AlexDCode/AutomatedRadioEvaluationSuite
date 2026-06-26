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

    % Impedance-mismatch de-embedding (realized -> absolute gain) is only
    % defined for a reflection magnitude below unity. On an uncalibrated or
    % unterminated port |Gamma| can sit at or above 1, making (1 - |Gamma|^2)
    % zero or negative; P2dB would then take 10*log10 of a non-positive value
    % and return Inf or COMPLEX gains. Those complex values propagate into the
    % saved results and later make plot/polarplot warn "Imaginary parts of
    % complex X and/or Y arguments ignored". Guard the non-physical points to
    % NaN so the result stays real (they render as gaps, flagging where a
    % proper match/calibration is needed). For valid data (|Gamma| < 1) this is
    % identical to the original calculation.
    mismatchFactor = 1 - returnLoss.^2;
    mismatchFactor(mismatchFactor <= 0) = NaN;

    % Calculate the absolute gain.
    absoluteGainMagnitude = realizedGainMagnitude ./ mismatchFactor;
    absoluteGain = P2dB(absoluteGainMagnitude);
end