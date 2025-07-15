function P = dB2P(dB)
    %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
    % DESCRIPTION:
    % The function dB2P converts dB to magnitudes (power)
    %
    % INPUT:
    %   dB  - A scalar of vector of magnitudes in dB
    %
    % OUTPUT:
    %   P   - A scalar or vector of magnitudes (power) in linear scale
    %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

    P = 10.^(dB / 10);
end