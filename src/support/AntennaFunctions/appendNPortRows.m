function T = appendNPortRows(T, theta, phi, q)
    %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
    % DESCRIPTION:
    % Flattens the per-position quantities from computeNPortQuantities into the
    % long/tidy results schema (createNPortResultsTable) and appends them to T,
    % one row per (frequency, quantity) at the given (theta, phi).
    %
    % INPUT:
    %   T     - the accumulating long results table.
    %   theta - turntable angle (deg) for this position.
    %   phi   - tower angle (deg) for this position.
    %   q     - struct from computeNPortQuantities.
    %
    % OUTPUT:
    %   T     - the table with this position's rows appended.
    %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

    freqMHz = q.freqHz(:) / 1e6;
    blocks  = {};

    % Gain per AUT<->Reference path (Driven = Tx, Receive = Rx).
    for k = 1:numel(q.pathGains)
        g = q.pathGains(k);
        blocks{end+1} = block_(theta, phi, freqMHz, ...
            g.TxPort, g.RxPort, g.SParam, "Gain (dBi)", g.GaindBi); %#ok<AGROW>
    end

    % Insertion loss (mag + phase) per Transmitter -> Receiver transmission.
    for k = 1:numel(q.insertionLoss)
        il = q.insertionLoss(k);
        blocks{end+1} = block_(theta, phi, freqMHz, ...
            il.TxPort, il.RxPort, il.SParam, ...
            "Insertion Loss (dB)", il.InsertionLossdB);               %#ok<AGROW>
        blocks{end+1} = block_(theta, phi, freqMHz, ...
            il.TxPort, il.RxPort, il.SParam, ...
            "Insertion Loss (deg)", il.InsertionLossdeg);             %#ok<AGROW>
    end

    % Return loss (mag + phase) per used port.
    for k = 1:numel(q.returnLoss)
        r  = q.returnLoss(k);
        nm = PortMap.sparamName(r.Port, r.Port);
        blocks{end+1} = block_(theta, phi, freqMHz, ...
            r.Port, r.Port, nm, "Return Loss (dB)", r.ReturnLossdB);   %#ok<AGROW>
        blocks{end+1} = block_(theta, phi, freqMHz, ...
            r.Port, r.Port, nm, "Return Loss (deg)", r.ReturnLossdeg); %#ok<AGROW>
    end

    % Reciprocity (mag + phase delta) per Transmitter/Receiver pair.
    for k = 1:numel(q.reciprocity)
        rc = q.reciprocity(k);
        blocks{end+1} = block_(theta, phi, freqMHz, ...
            rc.PortA, rc.PortB, rc.SParamFwd, ...
            "Reciprocity Mag Delta (dB)", rc.MagDeltadB);              %#ok<AGROW>
        blocks{end+1} = block_(theta, phi, freqMHz, ...
            rc.PortA, rc.PortB, rc.SParamFwd, ...
            "Reciprocity Phase Delta (deg)", rc.PhaseDeltadeg);        %#ok<AGROW>
    end

    % Radiation efficiency per Transmitter (no single receive port).
    for k = 1:numel(q.efficiency)
        e = q.efficiency(k);
        blocks{end+1} = block_(theta, phi, freqMHz, ...
            e.TxPort, NaN, "", ...
            "Radiation Efficiency", e.EfficiencyLinear);              %#ok<AGROW>
    end

    if ~isempty(blocks)
        T = [T; vertcat(blocks{:})];
    end
end

function B = block_(theta, phi, freqMHz, drivenPort, receivePort, ...
                    sparam, quantity, value)
    % Build one n-rows block for a single (path, quantity) series.
    n = numel(freqMHz);
    B = table( ...
        repmat(theta, n, 1), ...
        repmat(phi, n, 1), ...
        freqMHz(:), ...
        repmat(double(drivenPort), n, 1), ...
        repmat(double(receivePort), n, 1), ...
        repmat(string(sparam), n, 1), ...
        repmat(string(quantity), n, 1), ...
        value(:), ...
        'VariableNames', {'Theta (deg)', 'Phi (deg)', 'Frequency (MHz)', ...
                          'Driven Port', 'Receive Port', ...
                          'S-Parameter', 'Quantity', 'Value'});
end
