function str = table2string(T)
    %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
    % DESCRIPTION:
    % This function converts a MATLAB table of any size (N-by-M) into a single formatted string representation. 
    % Each row of the table is enclosed in curly braces `{}` and the elements within a row are separated by 
    % semicolons `;`. The rows are concatenated together without spaces. This format is useful for serializing 
    % table data into a compact, structured string that can be stored, transmitted, or embedded into text-based 
    % files or databases.
    %
    % The function works with both numeric and string data types. All elements are converted to string form 
    % internally. Mixed data types are preserved as text in the output string. The function uses vectorized 
    % operations for efficiency and scales well for large tables.
    %
    % INPUT:
    %   T  - MATLAB table of size N-by-M containing numeric, string, or mixed data types. There is no restriction 
    %        on the number of rows (N) or columns (M).
    %
    % OUTPUT:
    %   str - A single string representing the entire table. Each row of the table is formatted as:
    %         {col1;col2;col3;...;colM}, and all rows are concatenated together as:
    %         {row1}{row2}{row3}...{rowN}
    %
    % EXAMPLE:
    %   T = table([1;2], [3;4], {'A';'B'}, 'VariableNames', {'X','Y','Z'});
    %   s = tableToString(T);
    %   % s = '{1;3;A}{2;4;B}'
    %
    % NOTES:
    %   - Handles arbitrary table sizes.
    %   - Preserves original data as strings.
    %   - Optimized for speed using column-wise and vectorized operations.
    %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

    % Validate input
    if ~istable(T)
        error('Input must be a table.');
    end
    
    % Convert table to cell array (N x M)
    C = table2cell(T);
    
    % Convert each element to string using arrayfun
    C = cellfun(@(x) num2str(x), C, 'UniformOutput', false);
    
    % Join columns with semicolons row-wise
    rowStrings = cellfun(@(r) ['{' strjoin(r, ';') '}'], num2cell(C, 2), 'UniformOutput', false);
    
    % Combine all rows into one string
    str = string(strjoin(rowStrings, ''));
end
