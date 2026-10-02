function C = nportLongToWide(T)
    %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
    % DESCRIPTION:
    % Pivots the n-port long/tidy results table into a compact WIDE layout with
    % TWO header rows, returned as a cell array ready for writecell:
    %
    %   row 1 (name):     (blank x3)       S12         S12                  S11
    %   row 2 (quantity): Theta (deg) ...  Gain (dBi)  Insertion Loss (dB)  Return Loss (dB)
    %   row 3+ (data):    -177 0 500       ...         ...                  ...
    %
    % One row per (Theta, Phi, Frequency) point (instead of one row per
    % quantity), with each (S-parameter, quantity) as its own column. Row 1
    % names the S-parameter, row 2 the quantity + units. Radiation Efficiency
    % (which has no S-parameter) is named "Port<TxPort>".
    %
    % INPUT:
    %   T - long results table (createNPortResultsTable schema; readable or
    %       compact column names accepted).
    %
    % OUTPUT:
    %   C - cell array {2 header rows + N data rows} x M columns.
    %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

    th  = T.(pick_(T, {'Theta (deg)', 'Thetadeg', 'Theta_deg_'}));
    ph  = T.(pick_(T, {'Phi (deg)', 'Phideg', 'Phi_deg_'}));
    fr  = T.(pick_(T, {'Frequency (MHz)', 'FrequencyMHz', 'Frequency_MHz_'}));
    sp  = string(T.(pick_(T, {'S-Parameter', 'SParameter', 'S_Parameter_'})));
    qt  = string(T.(pick_(T, {'Quantity'})));
    val = T.(pick_(T, {'Value'}));
    drv = T.(pick_(T, {'Driven Port', 'DrivenPort', 'Driven_Port_'}));

    % Column "name" = S-parameter, or Port<TxPort> where there is no S-param
    % (radiation efficiency).
    name = sp;
    noSp = strlength(name) == 0;
    name(noSp) = "Port" + string(drv(noSp));

    % Row keys: unique (theta, phi, freq), sorted ascending.
    [keyMat, ~, kidx] = unique([th, ph, fr], 'rows');

    % Column keys: unique (name, quantity), in first-seen order.
    colKey = name + char(31) + qt;                 % unit-separated compound key
    [~, ia, cidx] = unique(colKey, 'stable');
    nameRow = name(ia);
    qtyRow  = qt(ia);

    nR = size(keyMat, 1);
    nC = numel(ia);
    M = nan(nR, nC);
    M(sub2ind([nR, nC], kidx, cidx)) = val;

    hdr1 = [{'', '', ''}, cellstr(nameRow(:)')];
    hdr2 = [{'Theta (deg)', 'Phi (deg)', 'Frequency (MHz)'}, cellstr(qtyRow(:)')];
    body = num2cell([keyMat, M]);
    C = [hdr1; hdr2; body];
end

function name = pick_(T, aliases)
    vn = string(T.Properties.VariableNames);
    for k = 1:numel(aliases)
        hit = find(strcmpi(vn, aliases{k}), 1);
        if ~isempty(hit), name = char(vn(hit)); return; end
    end
    error("nportLongToWide:MissingColumn", "Long table has no column matching %s.", strjoin(aliases, "/"));
end
