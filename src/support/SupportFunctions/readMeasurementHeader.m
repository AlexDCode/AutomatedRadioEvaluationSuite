function [meta, nHeaderLines, lines] = readMeasurementHeader(filename)
    %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
    % DESCRIPTION:
    % Reads the metadata block at the top of an ARES results file (written by saveData from
    % buildMeasurementHeader). The block ends at a line whose first field is exactly "DATA"; the measurement
    % table starts on the next line. Files without a DATA line (everything saved before the header existed)
    % return nHeaderLines = 0 and load exactly as before.
    %
    % INPUT:
    %   filename     - path to a .csv / .xls / .xlsx results file.
    %
    % OUTPUT:
    %   meta         - struct of the header settings, keyed by a valid-name form of each label (e.g.
    %                  meta.AntennaSpacingm), with numbers converted where possible. meta.PortMap is the
    %                  PortMap rebuilt from the PORT MAP rows ([] if none). Empty struct if no header.
    %   nHeaderLines - number of lines before the table, including the DATA line (0 = no header).
    %   lines        - the first lines of the file as strings (CSV fields joined by commas for
    %                  spreadsheets), so callers can read the table's own header rows without reopening.
    %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

    MAX_SCAN = 300;   % the header is short; never scan a whole data file
    meta = struct();
    nHeaderLines = 0;
    lines = firstLines_(filename, MAX_SCAN);

    dataIdx = find(arrayfun(@(l) firstField_(l) == "DATA", lines), 1);
    if isempty(dataIdx)
        return;
    end
    nHeaderLines = dataIdx;

    ports = []; dirs = strings(0, 1); roles = strings(0, 1);
    gainFiles = strings(0, 1); gainCols = strings(0, 1);
    inPortMap = false;
    for k = 1:dataIdx - 1
        f = splitCSVLine_(lines(k));
        key = strtrim(f(1));
        if strlength(key) == 0, continue; end

        if upper(key) == "PORT MAP"
            inPortMap = true;
            continue;
        end
        if inPortMap
            if key == "Port", continue; end      % the port-map column titles
            f(end+1:5) = "";
            ports(end+1, 1)     = str2double(key); %#ok<AGROW>
            dirs(end+1, 1)      = strtrim(f(2));   %#ok<AGROW>
            roles(end+1, 1)     = strtrim(f(3));   %#ok<AGROW>
            gainFiles(end+1, 1) = strtrim(f(4));   %#ok<AGROW>
            gainCols(end+1, 1)  = strtrim(f(5));   %#ok<AGROW>
            continue;
        end

        if numel(f) < 2 || strlength(strtrim(f(2))) == 0
            continue;   % title line or blank setting
        end
        val = strtrim(f(2));
        num = str2double(val);
        % Same compact naming ARES uses for columns: "Antenna Spacing (m)" -> AntennaSpacingm.
        name = matlab.lang.makeValidName(regexprep(char(key), '[^0-9A-Za-z]', ''));
        if ~isnan(num)
            meta.(name) = num;
        else
            meta.(name) = val;
        end
    end

    meta.PortMap = [];
    if ~isempty(ports)
        roles(roles == "") = "AUT";
        meta.PortMap = PortMap.fromPortRows(ports, dirs, roles, gainFiles, gainCols);
        meta.PortMap.NumPorts = max(meta.PortMap.NumPorts, max(ports));
    end
end

function lines = firstLines_(filename, n)
    % First n lines as strings. Spreadsheets are read as cells and joined
    % with commas so the same parsing works for both.
    [~, ~, ext] = fileparts(filename);
    lines = strings(0, 1);
    if any(strcmpi(ext, {'.xls', '.xlsx', '.xlsm'}))
        C = readcell(filename, 'Range', sprintf('A1:Z%d', n));
        for r = 1:size(C, 1)
            row = C(r, :);
            txt = strings(1, numel(row));
            for c = 1:numel(row)
                v = row{c};
                if isa(v, 'missing')
                    txt(c) = "";
                elseif isnumeric(v) || islogical(v)
                    txt(c) = string(num2str(v, 15));
                else
                    txt(c) = csvQuote_(string(v));
                end
            end
            lines(end+1, 1) = strjoin(txt, ","); %#ok<AGROW>
        end
        return;
    end

    fid = fopen(filename, 'r');
    if fid == -1
        error("readMeasurementHeader:FileError", "Could not open %s.", filename);
    end
    cleaner = onCleanup(@() fclose(fid));
    for k = 1:n
        l = fgetl(fid);
        if ~ischar(l), break; end
        lines(end+1, 1) = string(l); %#ok<AGROW>
    end
end

function s = firstField_(line)
    f = splitCSVLine_(line);
    s = strtrim(f(1));
end

function f = splitCSVLine_(line)
    % Split one CSV line into fields, honoring "quoted, fields" and "" escapes
    % (gain-file paths can contain commas).
    line = char(line);
    f = strings(1, 0);
    cur = '';
    inQ = false;
    k = 1;
    while k <= numel(line)
        ch = line(k);
        if inQ
            if ch == '"'
                if k < numel(line) && line(k+1) == '"'
                    cur(end+1) = '"'; k = k + 1; %#ok<AGROW>
                else
                    inQ = false;
                end
            else
                cur(end+1) = ch; %#ok<AGROW>
            end
        elseif ch == '"'
            inQ = true;
        elseif ch == ','
            f(end+1) = string(cur); %#ok<AGROW>
            cur = '';
        else
            cur(end+1) = ch; %#ok<AGROW>
        end
        k = k + 1;
    end
    f(end+1) = string(cur);
end

function s = csvQuote_(s)
    if contains(s, [",", """"])
        s = """" + replace(s, """", """""") + """";
    end
end
