function antennaGain = measureAntennaGain(TestFrequency, sParameter_dB, Spacing, ReferenceGain, ReferenceFrequency)
    %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
    % DESCRIPTION:
    % This function calculates the gain of a test antenna in decibels relative to an isotropic radiator (dBi).
    % The gain is computed based on the input test frequency, S-parameters, and the spacing between the antennas.
    % The function calculates the antenna gain using one of two methods:
    %
    %   - **Comparison Antenna Method**: If reference gain and frequency values are provided, the antenna gain is calculated by interpolating the reference gain at the test frequencies.
    %   - **Two Antenna Method**: If no reference data is provided, the function assumes the test antennas are identical.
    %
    % INPUT:
    %   TestFrequency   - A scalar or vector of frequency values in Hz at which the antenna gain is measured.
    %   sParameter_dB   - A scalar or vector of S21 values (in dB), representing the magnitude of power transfer between two antennas.
    %   Spacing         - A scalar value representing the distance in meters between the two antennas being tested.
    %   ReferenceGain   - (Optional) A vector of reference antenna gain values (in dBi). Used for the Comparison Antenna Method.
    %   ReferenceFrequency - (Optional) A vector of frequencies (in Hz) corresponding to the reference antenna gain values. 
    %
    % OUTPUT:
    %   antennaGain     - A vector containing the calculated antenna gain in dBi for the test antenna, at the specified test frequencies.
    %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

    if nargin < 4
        ReferenceGain = [];
        ReferenceFrequency = [];
    end

    % Speed of light (m/s).
    c = 3E8;

    % Guard the spacing: a non-positive / non-finite separation makes the FSPL
    % term Inf/complex and silently poisons the gain. Return NaN instead so bad
    % setup (spacing unset or zero) is visible rather than producing a huge
    % bogus gain.
    if ~isscalar(Spacing) || ~isfinite(Spacing) || Spacing <= 0
        Spacing = NaN;
    end

    % Wavelength (m).
    lambda = c ./ TestFrequency;

    % Free Space Path Loss (dB).
    FSPL_dB = 20 * log10(lambda / (4*pi*Spacing));

    if ~isempty(ReferenceGain) && ~isempty(ReferenceFrequency)
        % Comparison Antenna Method: Use reference antenna data.
        % Use pchip (shape-preserving, no overshoot on a non-uniform reference
        % grid) and DO NOT extrapolate: test frequencies outside the reference
        % file's band return NaN, so a reference that does not cover the sweep
        % yields NaN gain (obvious "no data") instead of a wild extrapolated
        % value. (The old 'spline' extrapolated and could produce gains like
        % -50000 dBi when the reference band did not span the sweep.)
        interpolatedRefGain = interp1(ReferenceFrequency, ReferenceGain, TestFrequency, 'pchip', NaN);
        antennaGain = sParameter_dB - FSPL_dB - interpolatedRefGain;
    else
        % Two-Antenna Method: Assume test antennas are identical.
        antennaGain = (sParameter_dB - FSPL_dB) / 2;
    end
end
