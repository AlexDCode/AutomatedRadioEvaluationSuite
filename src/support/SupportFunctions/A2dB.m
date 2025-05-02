function AdB = A2dB(A)
    %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
    % DESCRIPTION:
    % The function A2dB converts magnitudes (voltage or current) to dB.
    %
    % INPUT:
    %   A    - Magnitude (voltage or current) in linear scale
    %
    % OUTPUT:
    %   AdB  - Magnitude in decibels (dB)
    %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

    AdB = 20 * log10(A);
end