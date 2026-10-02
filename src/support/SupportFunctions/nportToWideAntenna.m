function W = nportToWideAntenna(data, sparam)
    %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
    % DESCRIPTION:
    % Pivots an n-port long/tidy antenna results table (createNPortResultsTable)
    % into the legacy WIDE shape the 2D/3D radiation-pattern plots expect, for
    % ONE gain path (S-parameter). This lets the existing angle/frequency plots
    % render n-port data without rewriting them.
    %
    % Produced columns (compact legacy names): Thetadeg, Phideg, FrequencyMHz,
    % GaindBi (the pattern: Gain if a reference was present, else Insertion
    % Loss as a relative pattern), AbsoluteGaindBi (= GaindBi), ReturnLossdB
    % (the driven port's return loss for the chosen path).
    %
    % Input column names are matched against both the readable ("Frequency
    % (MHz)") and post-load compact ("FrequencyMHz") forms.
    %
    % INPUT:
    %   data   - the n-port long results table (or struct with those fields).
    %   sparam - (optional) which gain-path S-parameter to pivot, e.g. "S31".
    %            Omitted / "" => the first S-parameter that has Gain rows.
    %
    % OUTPUT:
    %   W - wide table (empty typed table if the quantity/path is absent).
    %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

    if nargin < 2, sparam = ""; end

    T  = data;
    vn = string(T.Properties.VariableNames);
    qCol   = colName_(vn, {'Quantity'});
    vCol   = colName_(vn, {'Value'});
    spCol  = colName_(vn, {'SParameter', 'S-Parameter', 'S_Parameter_'});
    thCol  = colName_(vn, {'Thetadeg', 'Theta (deg)', 'Theta_deg_'});
    phCol  = colName_(vn, {'Phideg', 'Phi (deg)', 'Phi_deg_'});
    fCol   = colName_(vn, {'FrequencyMHz', 'Frequency (MHz)', 'Frequency_MHz_'});
    drvCol = colName_(vn, {'DrivenPort', 'Driven Port', 'Driven_Port_'});

    if isempty(qCol) || isempty(vCol) || isempty(spCol)
        W = emptyWide_();
        return;
    end

    q  = string(T.(qCol));
    sp = string(T.(spCol));

    % Pattern quantity: use Gain if a reference produced any (calibrated,
    % absolute pattern); otherwise fall back to Insertion Loss -- the raw
    % transmission, which is the relative / uncalibrated radiation pattern
    % shape. This lets the 2D/3D pattern plots render even when no reference
    % antenna gain was available.
    if any(q == "Gain (dBi)")
        patternQty = "Gain (dBi)";
    else
        patternQty = "Insertion Loss (dB)";
    end

    % Choose the S-parameter to pivot (default: first one with pattern rows).
    if strlength(string(sparam)) == 0
        spList = unique(sp(q == patternQty), 'stable');
        if isempty(spList)
            W = emptyWide_();
            return;
        end
        sparam = spList(1);
    end
    sparam = string(sparam);

    gm = q == patternQty & sp == sparam;
    if ~any(gm)
        W = emptyWide_();
        return;
    end
    th   = T.(thCol)(gm);
    ph   = T.(phCol)(gm);
    fr   = T.(fCol)(gm);
    gain = T.(vCol)(gm);

    % Return loss of this path's driven port (Sii), joined on (theta,phi,freq).
    drv = T.(drvCol)(gm);
    rlName = "S" + string(drv(1)) + string(drv(1));
    rl = nan(numel(gain), 1);
    rm = q == "Return Loss (dB)" & sp == rlName;
    if any(rm)
        keyG = string(th) + "|" + string(ph) + "|" + string(fr);
        keyR = string(T.(thCol)(rm)) + "|" + string(T.(phCol)(rm)) + "|" + string(T.(fCol)(rm));
        rv   = T.(vCol)(rm);
        [tf, loc] = ismember(keyG, keyR);
        rl(tf) = rv(loc(tf));
    end

    % Fill BOTH gain columns with the pattern so either GainType toggle
    % ("Realized"/"Absolute") renders it (n-port has no separate absolute-gain
    % quantity).
    W = table(th(:), ph(:), fr(:), gain(:), gain(:), rl(:), ...
        'VariableNames', {'Thetadeg', 'Phideg', 'FrequencyMHz', ...
                          'GaindBi', 'AbsoluteGaindBi', 'ReturnLossdB'});
end

function W = emptyWide_()
    W = table('Size', [0 6], 'VariableTypes', repmat({'double'}, 1, 6), ...
        'VariableNames', {'Thetadeg', 'Phideg', 'FrequencyMHz', ...
                          'GaindBi', 'AbsoluteGaindBi', 'ReturnLossdB'});
end

function name = colName_(vn, aliases)
    % First variable name matching any alias (case-insensitive), else ''.
    name = '';
    for k = 1:numel(aliases)
        hit = find(strcmpi(vn, string(aliases{k})), 1);
        if ~isempty(hit), name = char(vn(hit)); return; end
    end
end
