function tf = isNPortWideFile(filename)
    %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
    % DESCRIPTION:
    % Detects the compact two-header-row n-port results format so loadData can
    % route it through nportReadWide instead of readtable. Signature: the
    % SECOND line carries the key names (Theta.../Frequency...) while the FIRST
    % line (the S-parameter name row) does not. Legacy wide and the older long
    % single-header format both carry the keys on the FIRST line, so they read
    % false.
    %
    % INPUT:
    %   filename - path to a candidate results file.
    %
    % OUTPUT:
    %   tf - true if the file is the two-header-row n-port format.
    %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

    tf = false;
    fid = fopen(filename, 'r');
    if fid == -1, return; end
    l1 = fgetl(fid);
    l2 = fgetl(fid);
    fclose(fid);
    if ~ischar(l1) || ~ischar(l2), return; end

    l1 = string(l1);
    l2 = string(l2);
    tf = contains(l2, "Theta") && contains(l2, "Frequency") && ~contains(l1, "Theta");
end
