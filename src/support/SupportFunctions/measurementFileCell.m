function [C, writeAsCell] = measurementFileCell(dataTable, header)
    %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
    % DESCRIPTION:
    % Builds what saveData writes with writecell: the optional metadata block, a line "DATA", then the table.
    % n-port long/tidy results (Quantity/Value columns) become the compact two-header-row wide layout
    % (nportLongToWide). A plain table with no header keeps saveData's writetable path (writeAsCell = false,
    % C empty), so files without a header are written exactly as before.
    %
    % INPUT:
    %   dataTable - results table.
    %   header    - (Optional) metadata rows from buildMeasurementHeader ({} for none).
    %
    % OUTPUT:
    %   C           - rectangular cell array to pass to writecell ({} when writeAsCell is false).
    %   writeAsCell - true when the file must be written with writecell.
    %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

    if nargin < 2, header = {}; end
    hasHeader = ~isempty(header);
    isNPort = istable(dataTable) && all(ismember({'Quantity', 'Value'}, dataTable.Properties.VariableNames));

    C = {};
    writeAsCell = isNPort || hasHeader;
    if ~writeAsCell, return; end

    if isNPort
        C = nportLongToWide(dataTable);
    else
        % A header can't go through writetable, so write the table as cells.
        C = [dataTable.Properties.VariableNames; table2cell(dataTable)];
    end

    if hasHeader
        % Pad every block to one width so writecell gets a rectangular array.
        nW = max(size(header, 2), size(C, 2));
        C = [padCols_(header, nW); padCols_({'DATA'}, nW); padCols_(C, nW)];
    end
end

function C = padCols_(C, n)
    % Widen a cell array to n columns with empty cells.
    if size(C, 2) < n
        C(:, end+1:n) = {[]};
    end
end
