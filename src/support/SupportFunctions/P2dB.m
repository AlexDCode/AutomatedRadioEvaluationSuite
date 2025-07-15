function PdB = P2dB(P)
    %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
    % DESCRIPTION:
    % The function P2dB converts magnitudes (power) to dB.
    %
    % INPUT:
    %   P    - Magnitude (power) in linear scale
    %
    % OUTPUT:
    %   PdB  - Magnitude in decibels (dB)
    %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

    PdB = 10 * log10(P);
end