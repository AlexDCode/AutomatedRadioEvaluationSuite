function series = selectNPortSeries(data, quantity, atBoresight)
    %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
    % DESCRIPTION:
    % Selects plottable series from an n-port long/tidy results table
    % (createNPortResultsTable). Filters by quantity, optionally restricts to
    % boresight (Theta=0, Phi=0), and splits the result into one series per
    % (Driven Port, Receive Port) so each can be drawn as its own line of Value
    % vs Frequency, labelled by its S-parameter.
    %
    % Column names are matched against BOTH the readable form ("Frequency
    % (MHz)") and the compact post-load form ("FrequencyMHz"), so it works
    % whether the table came straight from the measurement or was reloaded from
    % a saved CSV.
    %
    % INPUT:
    %   data        - the long results table (or struct with those fields).
    %   quantity    - quantity to plot, e.g. "Gain (dBi)".
    %   atBoresight - (optional, default true) restrict to Theta=0 & Phi=0.
    %
    % OUTPUT:
    %   series - struct array, one per line, with fields:
    %            Label (legend text), FreqMHz (vector), Value (vector),
    %            DrivenPort, ReceivePort.
    %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

    if nargin < 3, atBoresight = true; end

    T = data;
    col = @(varargin) pickVar_(T, varargin);   % resolve a column by aliases

    quantityCol = col("Quantity");
    valueCol    = col("Value");
    freqCol     = col("Frequency (MHz)", "FrequencyMHz", "Frequency_MHz_");
    drvCol      = col("Driven Port", "DrivenPort", "Driven_Port_");
    rcvCol      = col("Receive Port", "ReceivePort", "Receive_Port_");
    thetaCol    = col("Theta (deg)", "Thetadeg", "Theta_deg_");
    phiCol      = col("Phi (deg)", "Phideg", "Phi_deg_");

    mask = string(T.(quantityCol)) == string(quantity);
    if atBoresight && ~isempty(thetaCol) && ~isempty(phiCol)
        mask = mask & T.(thetaCol) == 0 & T.(phiCol) == 0;
    end

    T = T(mask, :);
    series = struct('Label', {}, 'FreqMHz', {}, 'Value', {}, ...
                    'DrivenPort', {}, 'ReceivePort', {});
    if isempty(T), return; end

    drv = T.(drvCol);
    rcv = T.(rcvCol);
    % NaN ports stringify to <missing>, which unique treats as all-distinct;
    % map them to a literal so identical series group together.
    drvS = string(drv);  drvS(ismissing(drvS)) = "NaN";
    rcvS = string(rcv);  rcvS(ismissing(rcvS)) = "NaN";
    keyStr = drvS + "|" + rcvS;
    [~, ia, ic] = unique(keyStr, 'stable');

    for g = 1:numel(ia)
        rows = ic == g;
        [fMHz, order] = sort(T.(freqCol)(rows));
        vals = T.(valueCol)(rows);
        vals = vals(order);

        entry.DrivenPort  = drv(ia(g));
        entry.ReceivePort = rcv(ia(g));
        entry.FreqMHz     = fMHz(:);
        entry.Value       = vals(:);
        entry.Label       = makeLabel_(entry);
        series(end + 1) = entry; %#ok<AGROW>
    end
end

function name = pickVar_(T, aliases)
    % Return the first table variable name matching any alias (case-insensitive).
    name = '';
    vn = string(T.Properties.VariableNames);
    for k = 1:numel(aliases)
        hit = find(strcmpi(vn, string(aliases{k})), 1);
        if ~isempty(hit), name = char(vn(hit)); return; end
    end
end

function s = makeLabel_(entry)
    % Legend label: the S-parameter (Sxy) for a path/return-loss series, or the
    % transmit port for a per-transmitter series (e.g. efficiency).
    if ~isnan(entry.DrivenPort) && ~isnan(entry.ReceivePort)
        s = "S" + string(entry.ReceivePort) + string(entry.DrivenPort);
    elseif ~isnan(entry.DrivenPort)
        s = "Port " + string(entry.DrivenPort);
    else
        s = "series";
    end
end
