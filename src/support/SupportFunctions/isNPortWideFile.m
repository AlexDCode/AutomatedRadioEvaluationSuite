function tf = isNPortWideFile(filename)
    %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
    % DESCRIPTION:
    % Detects the compact two-header-row n-port results format so loadData can
    % route it through nportReadWide instead of readtable. Signature: the
    % SECOND line carries the key names (Theta.../Frequency...) while the FIRST
    % line (the S-parameter name row) does not. Legacy wide and the older long
    % single-header format both carry the keys on the FIRST line, so they read
    % false. A metadata block ending in a DATA line (readMeasurementHeader) is
    % skipped first, so the two header rows are the ones after DATA.
    %
    % INPUT:
    %   filename - path to a candidate results file.
    %
    % OUTPUT:
    %   tf - true if the file is the two-header-row n-port format.
    %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

    tf = false;
    try
        [~, k, lines] = readMeasurementHeader(filename);
    catch
        return;
    end
    if numel(lines) < k + 2, return; end

    l1 = lines(k + 1);
    l2 = lines(k + 2);
    tf = contains(l2, "Theta") && contains(l2, "Frequency") && ~contains(l1, "Theta");
end
