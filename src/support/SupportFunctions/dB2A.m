function dBA = dB2A(dB)
    %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
    % DESCRIPTION:
    % The function dB2A converts dB to magnitudes (voltage or current)
    %
    % INPUT:
    %   dB    - A scalar of vector of magnitudes in dB
    %
    % OUTPUT:
    %   dBA   - A scalar or vector of magnitudes (voltage or current) in linear scale
    %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

    dBA = 10.^(dB / 20);
end