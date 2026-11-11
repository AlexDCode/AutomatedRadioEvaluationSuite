function [T, meta] = readMeasurementTable(filename)
    %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
    % DESCRIPTION:
    % Reads a single-header-row ARES results table (legacy 2-port antenna data, reference gain files), skipping
    % the metadata block and its DATA line if the file has one (see readMeasurementHeader). Files without a
    % header are read exactly as before: readtable(filename, 'Delimiter', ',').
    %
    % INPUT:
    %   filename - path to the results file.
    %
    % OUTPUT:
    %   T        - the measurement table (readtable's default variable naming).
    %   meta     - header settings from readMeasurementHeader (empty struct if none).
    %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

    [meta, k] = readMeasurementHeader(filename);
    if k == 0
        T = readtable(filename, 'Delimiter', ',');
        return;
    end

    [~, ~, ext] = fileparts(filename);
    if any(strcmpi(ext, {'.xls', '.xlsx', '.xlsm'}))
        opts = detectImportOptions(filename, 'Range', sprintf('A%d', k + 1));
        opts.VariableNamesRange = sprintf('A%d', k + 1);
        opts.DataRange = sprintf('A%d', k + 2);
    else
        opts = detectImportOptions(filename, 'Delimiter', ',', 'NumHeaderLines', k);
        opts.VariableNamesLine = k + 1;
        opts.DataLines = [k + 2, Inf];
    end
    T = readtable(filename, opts);
end
