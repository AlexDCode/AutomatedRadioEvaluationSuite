function results = calculateRadiationEfficiency(freqHz, S, portMap)
    %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
    % DESCRIPTION:
    % Estimates radiation efficiency for each AUT transmitter port from the
    % power that is neither reflected nor coupled into the AUT's OWN other
    % ports (power delivered to a reference antenna is radiated, so it is not
    % subtracted):
    %
    %   eta_t(f) = 1 - sum_{j in AUT ports} |S_{j,t}(f)|^2
    %
    % For a leaky-wave AUT driven at port 1 (through-port 2 also AUT) this is
    % eta = 1 - |S11|^2 - |S21|^2. Efficiency is reported only for transmitter
    % ports whose role is AUT.
    %
    % INPUT:
    %   freqHz  - sweep frequencies (Hz), vector (passed through for context).
    %   S       - containers.Map "Sij" -> complex vector (measureComplexByName).
    %   portMap - PortMap; uses AUT ports (role) and transmitter ports.
    %
    % OUTPUT:
    %   results - struct array with fields TxPort, EfficiencyLinear (vector,
    %             may be <0 if uncalibrated/noisy) and
    %             EfficiencydB = 10*log10(max(eta, eps)).
    %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

    freqHz  = freqHz(:); %#ok<NASGU>  % kept in the signature for caller context
    autPorts = portMap.autPorts();
    txPorts  = portMap.transmitPorts();
    results = struct('TxPort', {}, 'EfficiencyLinear', {}, 'EfficiencydB', {});

    for t = intersect(txPorts, autPorts)
        acc = [];
        for j = autPorts
            c = getSParam(S, PortMap.sparamName(j, t));   % Tx t -> AUT port j
            if isempty(acc), acc = zeros(size(c)); end
            acc = acc + abs(c).^2;
        end
        eta = 1 - acc;

        entry.TxPort           = t;
        entry.EfficiencyLinear = eta(:);
        entry.EfficiencydB     = 10 * log10(max(eta(:), eps));
        results(end + 1) = entry; %#ok<AGROW>
    end
end
