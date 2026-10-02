function q = computeNPortQuantities(freqHz, S, portMap, spacing, refGains)
    %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
    % DESCRIPTION:
    % Per-position core of the n-port antenna measurement: given one sweep of
    % complex S-parameters, compute every derived quantity for the configured
    % PortMap. This is deliberately separated from the app/orchestration so it
    % can be verified headlessly.
    %
    % INPUT:
    %   freqHz   - sweep frequencies (Hz), vector.
    %   S        - containers.Map "Sij" -> complex vector (measureComplexByName).
    %   portMap  - PortMap.
    %   spacing  - antenna separation (m), scalar.
    %   refGains - containers.Map Reference-device-name -> struct(freqHz,gaindBi).
    %
    % OUTPUT:
    %   q - struct with fields:
    %       freqHz        - the frequency vector (column)
    %       pathGains     - computePathGains result (AUT<->Reference paths)
    %       insertionLoss - struct array per Tx->Rx path: TxPort, RxPort,
    %                       SParam, InsertionLossdB, InsertionLossdeg
    %       reciprocity   - calculateReciprocity result
    %       efficiency    - calculateRadiationEfficiency result
    %       returnLoss    - struct array per used port: Port, Direction,
    %                       ReturnLossdB, ReturnLossdeg
    %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

    q.freqHz      = freqHz(:);
    q.pathGains   = computePathGains(freqHz, S, portMap, spacing, refGains);
    q.reciprocity = calculateReciprocity(freqHz, S, portMap);
    q.efficiency  = calculateRadiationEfficiency(freqHz, S, portMap);

    % Insertion loss for every Transmitter -> Receiver transmission (raw |S|,
    % useful for general testing regardless of AUT/Reference roles).
    paths = portMap.paths();
    il = struct('TxPort', {}, 'RxPort', {}, 'SParam', {}, ...
                'InsertionLossdB', {}, 'InsertionLossdeg', {});
    for k = 1:numel(paths)
        c = getSParam(S, paths(k).SParamFwd);
        entry.TxPort           = paths(k).TxPort;
        entry.RxPort           = paths(k).RxPort;
        entry.SParam           = paths(k).SParamFwd;
        entry.InsertionLossdB  = 20 * log10(abs(c));
        entry.InsertionLossdeg = rad2deg(angle(c));
        il(end + 1) = entry; %#ok<AGROW>
    end
    q.insertionLoss = il;

    used = portMap.usedPorts();
    rl = struct('Port', {}, 'Direction', {}, ...
                'ReturnLossdB', {}, 'ReturnLossdeg', {});
    for p = used
        c = getSParam(S, PortMap.sparamName(p, p));
        entry2.Port          = p;
        entry2.Direction     = portMap.directionAtPort(p);
        entry2.ReturnLossdB  = 20 * log10(abs(c));
        entry2.ReturnLossdeg = rad2deg(angle(c));
        rl(end + 1) = entry2; %#ok<AGROW>
    end
    q.returnLoss = rl;
end
