function results = calculateReciprocity(freqHz, S, portMap)
    %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
    % DESCRIPTION:
    % Computes the forward/reverse asymmetry of every used-port pair, i.e. the
    % departure from reciprocity (S_ij ~= S_ji). For a normal reciprocal
    % network the deltas are ~0; a non-reciprocal ("self-circulating") device
    % shows a consistent one-sided magnitude/phase delta across frequency.
    %
    % Interpretation of the result (whether a given delta indicates
    % circulation, and any threshold) is left to the analyst; this function
    % just produces the raw comparison per pair.
    %
    % INPUT:
    %   freqHz  - sweep frequencies (Hz), vector (passed through for context).
    %   S       - containers.Map "Sij" -> complex vector (measureComplexByName).
    %   portMap - PortMap; reciprocityPairs() defines the pairs compared.
    %
    % OUTPUT:
    %   results - struct array, one element per used-port pair, with fields:
    %             PortA, PortB, SParamFwd (S_ba), SParamRev (S_ab),
    %             MagDeltadB     = |S_ba|dB - |S_ab|dB   (vector)
    %             PhaseDeltadeg  = angle(S_ba) - angle(S_ab), wrapped to +-180.
    %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

    freqHz = freqHz(:); %#ok<NASGU>  % kept in the signature for caller context
    pairs  = portMap.reciprocityPairs();
    results = struct('PortA', {}, 'PortB', {}, 'SParamFwd', {}, ...
                     'SParamRev', {}, 'MagDeltadB', {}, 'PhaseDeltadeg', {});

    for k = 1:numel(pairs)
        pr = pairs(k);
        cf = getSParam(S, pr.SParamFwd);
        cr = getSParam(S, pr.SParamRev);

        magDelta   = 20 * log10(abs(cf)) - 20 * log10(abs(cr));
        phaseDelta = rad2deg(angle(cf) - angle(cr));
        phaseDelta = mod(phaseDelta + 180, 360) - 180;   % wrap to [-180,180)

        entry.PortA         = pr.PortA;
        entry.PortB         = pr.PortB;
        entry.SParamFwd     = pr.SParamFwd;
        entry.SParamRev     = pr.SParamRev;
        entry.MagDeltadB    = magDelta(:);
        entry.PhaseDeltadeg = phaseDelta(:);
        results(end + 1) = entry; %#ok<AGROW>
    end
end
