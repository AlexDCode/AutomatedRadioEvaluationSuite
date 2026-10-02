function results = computePathGains(freqHz, S, portMap, spacing, refGains)
    %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
    % DESCRIPTION:
    % Computes antenna gain for every GAIN path declared by a PortMap: a
    % Transmitter -> Receiver path whose two ends cross the AUT <-> Reference
    % boundary. Gain is computed for the AUT end from the transmission
    % S_{Rx,Tx} using the reference end's known gain (comparison method,
    % reusing measureAntennaGain: Gain = |S| - FSPL - Gain_ref).
    %
    % Transmit->receive paths that do NOT cross AUT<->Reference (AUT->AUT
    % through paths, Reference->Reference) are not gain measurements and are
    % skipped here; their raw transmission is still recorded as insertion loss
    % by computeNPortQuantities.
    %
    % INPUT:
    %   freqHz   - sweep frequencies (Hz), vector.
    %   S        - containers.Map "Sij" -> complex vector (measureComplexByName).
    %   portMap  - PortMap describing Transmitter/Receiver + AUT/Reference.
    %   spacing  - antenna separation (m), scalar.
    %   refGains - containers.Map (double key = PORT) -> struct(freqHz,gaindBi),
    %              one entry per reference port (from readReferenceGainFile).
    %
    % OUTPUT:
    %   results - struct array, one per gain path, with fields:
    %             TxPort, RxPort, RefPort, AUTPort, SParam (forward label) and
    %             GaindBi.
    %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

    freqHz = freqHz(:);
    paths  = portMap.paths();
    results = struct('TxPort', {}, 'RxPort', {}, 'RefPort', {}, ...
                     'AUTPort', {}, 'SParam', {}, 'GaindBi', {});

    for k = 1:numel(paths)
        p = paths(k);
        if ~p.IsGainPath
            continue;
        end

        if ~isKey(refGains, p.RefPort)
            continue;   % reference has no gain file -> no absolute gain for
                        % this path (its insertion loss is still recorded)
        end
        rg = refGains(p.RefPort);

        c   = getSParam(S, p.SParamFwd);        % S_{Rx,Tx}
        sdB = 20 * log10(abs(c));
        gain = measureAntennaGain(freqHz, sdB, spacing, rg.gaindBi(:), rg.freqHz(:));

        entry.TxPort  = p.TxPort;
        entry.RxPort  = p.RxPort;
        entry.RefPort = p.RefPort;
        entry.AUTPort = p.AUTPort;
        entry.SParam  = p.SParamFwd;
        entry.GaindBi = gain(:);
        results(end + 1) = entry; %#ok<AGROW>
    end
end
