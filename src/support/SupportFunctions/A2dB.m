function AdB = A2dB(A)
    %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
    % A2dB Converts magnitudes (voltage or current) to dB.
    %
    % INPUT PARAMETERS:
    %   A:   Magnitude (voltage or current) in linear scale
    %
    % OUTPUT PARAMETERS:
    %   AdB: Magnitude in decibels (dB)
    %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
    AdB = 20*log10(A);
end