function [freqHz, gaindBi, columns] = readReferenceGainFile(fileName, columnName)
    %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
    % DESCRIPTION:
    % Reads a reference-antenna gain curve from an ARES measurement CSV (the
    % same format ARES writes when measuring). Because one file may hold
    % several gain columns (e.g. Gain (dBi) and Absolute Gain (dBi), or several
    % antennas), the caller selects WHICH column is the reference gain.
    %
    % The gain is taken at boresight (Theta = 0, Phi = 0) when angle columns
    % are present, and returned as a function of frequency.
    %
    % INPUT:
    %   fileName   - path to the ARES CSV.
    %   columnName - (optional) which gain column to use, e.g. "Gain (dBi)".
    %                Matched case-insensitively and ignoring spaces/parentheses
    %                (so "Gain (dBi)" and "GaindBi" are equivalent). If omitted,
    %                gaindBi is returned empty and `columns` lists the choices
    %                so a UI can offer them.
    %
    % OUTPUT:
    %   freqHz  - reference frequencies (Hz), column vector.
    %   gaindBi - selected reference gain (dBi), column vector ([] if no column
    %             was requested).
    %   columns - string array of the selectable gain-column names in the file.
    %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

    if nargin < 2, columnName = ""; end

    w = warning('off', 'MATLAB:table:ModifiedAndSavedVarnames');
    T = readtable(fileName, 'Delimiter', ',');
    warning(w);

    % Normalize variable names to a compact, comparable form (strip spaces,
    % parentheses, underscores) so "Frequency (MHz)" -> "FrequencyMHz" etc.
    raw  = string(T.Properties.VariableNames);
    norm = regexprep(raw, '[^0-9A-Za-z]', '');
    T.Properties.VariableNames = matlab.lang.makeUniqueStrings(cellstr(norm));
    norm = string(T.Properties.VariableNames);

    % Boresight filter, if angle columns exist.
    hasTheta = any(strcmpi(norm, "Thetadeg"));
    hasPhi   = any(strcmpi(norm, "Phideg"));
    if hasTheta && hasPhi
        theta = T.(char(norm(strcmpi(norm, "Thetadeg"))));
        phi   = T.(char(norm(strcmpi(norm, "Phideg"))));
        mask  = theta == 0 & phi == 0;
        if any(mask)
            T = T(mask, :);
        end
    end

    % Frequency column (MHz -> Hz).
    fIdx = find(strcmpi(norm, "FrequencyMHz"), 1);
    if isempty(fIdx)
        error("readReferenceGainFile:NoFrequency", ...
            "The reference file has no 'Frequency (MHz)' column.");
    end
    freqHz = double(T.(char(norm(fIdx)))) * 1e6;
    freqHz = freqHz(:);

    % Candidate gain columns: numeric columns whose name contains "Gain".
    isGain = contains(norm, "Gain", "IgnoreCase", true);
    isNum  = varfun(@isnumeric, T, 'OutputFormat', 'uniform');
    gainMask = isGain(:)' & isNum(:)';
    columns = raw(gainMask);      % report ORIGINAL (readable) names

    gaindBi = [];
    if strlength(string(columnName)) == 0
        return;                    % caller just wants the column list
    end

    % Resolve the requested column against the normalized names.
    wantNorm = regexprep(string(columnName), '[^0-9A-Za-z]', '');
    hit = find(strcmpi(norm, wantNorm) & gainMask, 1);
    if isempty(hit)
        error("readReferenceGainFile:NoSuchColumn", ...
            "Gain column '%s' not found. Available: %s", ...
            string(columnName), strjoin(columns, ", "));
    end
    gaindBi = double(T.(char(norm(hit))));
    gaindBi = gaindBi(:);

    % Sort by frequency so downstream interpolation is well behaved.
    [freqHz, order] = sort(freqHz);
    gaindBi = gaindBi(order);
end
