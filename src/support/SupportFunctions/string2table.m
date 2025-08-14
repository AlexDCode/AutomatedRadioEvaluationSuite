function T = string2table(str)
    %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
    % DESCRIPTION:
    % This function reconstructs a MATLAB table from a string formatted by the `tableToString` function. The input 
    % string contains rows enclosed in curly braces `{}` with elements separated by semicolons `;`. The function 
    % parses this string, splits it into rows and columns, and returns a MATLAB table. 
    %
    % If all elements of the parsed data are numeric, they are converted to numeric values; otherwise, the output 
    % remains as text. Generic column names (`Col1`, `Col2`, ..., `ColM`) are assigned automatically since the 
    % original variable names are not stored in the string.
    %
    % INPUT:
    %   str - A character array or string scalar representing table data in the format:
    %         {col11;col12;...;col1M}{col21;col22;...;col2M}...{colN1;colN2;...;colNM}
    %         where N is the number of rows and M is the number of columns.
    %
    % OUTPUT:
    %   T   - A MATLAB table reconstructed from the input string. Column names are automatically assigned as 
    %         'Col1', 'Col2', ..., 'ColM'. Data types are automatically detected and converted to numeric if all 
    %         values are numeric; otherwise, data is returned as text.
    %
    % EXAMPLE:
    %   s = '{1;3;A}{2;4;B}';
    %   T = string2table(s);
    %   % T =
    %   %   Col1    Col2    Col3
    %   %    1       3       'A'
    %   %    2       4       'B'
    %
    % NOTES:
    %   - The function does not preserve original variable names (can be extended if needed).
    %   - Handles arbitrary table sizes.
    %   - Optimized for performance using regular expressions and vectorized operations.
    %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

    % Validate input
    if class(str) == "cell"
        str = string(str);
    end

    if ~ischar(str) && ~isstring(str)
        error('Input must be a string or char array.');
    end
    
    % Split rows by finding patterns { ... }
    rowTokens = regexp(str, '\{([^}]*)\}', 'tokens');  % Extract content inside {}
    
    if isempty(rowTokens)
        error('Invalid format: no rows found.');
    end
    
    % Convert nested cell structure to a simple cell array of rows
    rows = cellfun(@(x) x{1}, rowTokens, 'UniformOutput', false);
    
    % Split each row by semicolon into columns
    data = cellfun(@(r) strsplit(r, ';'), rows, 'UniformOutput', false);
    
    % Convert to N x M cell array
    dataMatrix = vertcat(data{:});
    
    % Attempt to convert to numeric if possible
    numData = str2double(dataMatrix);
    if all(~isnan(numData(:)))
        dataMatrix = numData;  % All numeric
    end
    
    % Create table with generic column names
    numCols = size(dataMatrix, 2);
    varNames = strcat("Col", string(1:numCols));
    T = array2table(dataMatrix, 'VariableNames', cellstr(varNames));
end
