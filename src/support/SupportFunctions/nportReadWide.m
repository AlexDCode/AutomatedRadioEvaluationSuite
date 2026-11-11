function T = nportReadWide(filename)
    %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
    % DESCRIPTION:
    % Reads the compact two-header-row n-port results format (written by
    % nportLongToWide / saveData) back into the LONG/tidy table the rest of
    % ARES consumes, so loading is transparent to the plots and selectors.
    %
    % Any metadata block above a DATA line is skipped (readMeasurementHeader).
    % Row 1 of the table names each column's S-parameter (blank for the
    % Theta/Phi/Frequency keys, "Port<n>" for radiation efficiency); row 2
    % names the quantity. Each data column is expanded back into long rows,
    % reconstructing Driven/Receive port and S-parameter from the column name.
    %
    % INPUT:
    %   filename - path to a two-header-row n-port CSV/XLSX.
    %
    % OUTPUT:
    %   T - long table: Thetadeg, Phideg, FrequencyMHz, DrivenPort,
    %       ReceivePort, SParameter, Quantity, Value.
    %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

    % Skip the metadata block (through its DATA line) if the file has one.
    [~, k, lines] = readMeasurementHeader(filename);
    if numel(lines) < k + 2
        error("nportReadWide:FileError", "%s has no two-row n-port header.", filename);
    end

    nameRow = string(strsplit(lines(k + 1), ',', 'CollapseDelimiters', false));
    qtyRow  = string(strsplit(lines(k + 2), ',', 'CollapseDelimiters', false));

    M  = readmatrix(filename, 'NumHeaderLines', k + 2);   % empty cells -> NaN
    th = M(:, 1);  ph = M(:, 2);  fr = M(:, 3);
    nR = numel(th);

    blocks = {};
    for c = 4:numel(qtyRow)
        qt = strtrim(qtyRow(c));
        if strlength(qt) == 0, continue; end
        nm = strtrim(nameRow(c));
        [spName, drv, rcv] = parseColName_(nm);
        vals = M(:, c);
        blocks{end+1} = table(th, ph, fr, ...
            repmat(drv, nR, 1), repmat(rcv, nR, 1), ...
            repmat(spName, nR, 1), repmat(qt, nR, 1), vals, ...
            'VariableNames', {'Thetadeg', 'Phideg', 'FrequencyMHz', ...
                'DrivenPort', 'ReceivePort', 'SParameter', 'Quantity', 'Value'}); %#ok<AGROW>
    end
    T = vertcat(blocks{:});
end

function [sp, drv, rcv] = parseColName_(nm)
    % "Sij" -> S-param, receive=i, drive=j ; "Port<n>" -> efficiency (drive=n);
    % anything else -> keep the name, ports unknown.
    nm = string(nm);
    tok = regexp(nm, '^S(\d)(\d)$', 'tokens', 'once');
    if ~isempty(tok)
        sp = nm;  rcv = str2double(tok{1});  drv = str2double(tok{2});  return;
    end
    tokP = regexp(nm, '^Port(\d+)$', 'tokens', 'once');
    if ~isempty(tokP)
        sp = "";  drv = str2double(tokP{1});  rcv = NaN;  return;
    end
    sp = nm;  drv = NaN;  rcv = NaN;
end
