function extractTODOs(folderPath, outFilename, headerStr, excludedFolders)
    %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
    % 
    % DESCRIPTION:
    % Extracts TODO comments from .m files within a given folder and writes it to a Markdown file. Designed to 
    % support ReadTheDocs/Sphinx workflows. Example usage:
    %
    %   - extractTODOs(pwd+"\src", "./docs/readthedocs/source/TODOs.md")
    %
    % INPUT:
    %   folderPath      - Path to folder containing .m files (recursively searched)
    %   outFilename     - Path to output .md file
    %   excludedFolders - (Optional) Cell array of subfolders to exclude (by name)
    %
    % OUTPUT:
    %   None
    %
    % extractTODOs.m: IGNORE
    %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

    if nargin < 1, folderPath = pwd; end
    if nargin < 2, outFilename = 'TODOs.md'; end
    if nargin < 3, headerStr = 'TODO Items'; end
    if nargin < 4, excludedFolders = {}; end

    % Keywords to exclude from TODO output
    excludeKeywords = {'DESCRIPTION', 'INPUT', 'OUTPUT', 'NOTES', 'EXAMPLE'};

    % Collect all .m files recursively
    files = dir(fullfile(folderPath, '**', '*.m'));

    % Open output file
    fid_out = fopen(outFilename, 'w');
    if fid_out == -1
        error('Failed to open output file: %s', outFilename);
    end

    % Print header
    fprintf(fid_out, '# %s\n\n', headerStr);

    for k = 1:length(files)
        file = files(k);
        fullFilePath = fullfile(file.folder, file.name);

        % Skip excluded folders
        relativePath = erase(fullFilePath, [pwd filesep]);
        if any(contains(relativePath, excludedFolders))
            continue;
        end

        % Read file contents
        fid = fopen(fullFilePath, 'r');
        if fid == -1, continue; end
        lines = textscan(fid, '%s', 'Delimiter', '\n', 'Whitespace', '');
        fclose(fid);
        lines = lines{1};

        % Check first block comment for IGNORE
        ignoreFile = false;
        for i = 1:numel(lines)
            line = strtrim(lines{i});
            if startsWith(line, '%')
                if contains(line, 'extractTODOs.m: IGNORE')
                    ignoreFile = true;
                end
            else
                % Stop at second non-comment line
                if i > 1, break; end
            end
        end
        if ignoreFile
            continue;
        end
        % Extract TODO blocks
        todoBlocks = {};      % Stores all TODO blocks for this file
        insideTodo = false;   % Flag to indicate if we're currently inside a TODO block
        blockLines = {};      % Temporary storage for lines of the current TODO block
        
        for i = 1:numel(lines)
            line = strtrim(lines{i});                  % Remove leading/trailing whitespace
            isComment = startsWith(line, '%');        % Check if the line is a comment
            containsTodo = contains(line, 'TODO');    % Check if the line contains "TODO"
        
            % Start a new TODO block if "TODO" is found
            if containsTodo
                insideTodo = true;
            end
        
            if insideTodo
                if isComment
                    % Remove the leading '%' and any surrounding spaces
                    cleanLine = regexprep(line, '^\s*%\s*', '');
        
                    % Skip lines containing excluded keywords (DESCRIPTION, INPUT, OUTPUT, NOTES, EXAMPLE)
                    skipLine = any(contains(cleanLine, excludeKeywords));
                    if skipLine
                        continue;
                    end
        
                    % Remove special characters except letters, numbers, spaces, colon, and parentheses
                    cleanLine = regexprep(cleanLine, '[^a-zA-Z0-9\s:()]', '');
        
                    % Collapse multiple spaces into a single space
                    cleanLine = regexprep(cleanLine, '\s+', ' ');
        
                    % Trim again in case of extra spaces at ends
                    cleanLine = strtrim(cleanLine);
        
                    % Store the cleaned line in the current TODO block
                    if ~isempty(cleanLine)
                        blockLines{end+1} = cleanLine; %#ok<AGROW>
                    end
                else
                    % End of TODO block: first non-comment line after a TODO section
                    if ~isempty(blockLines)
                        todoBlocks{end+1} = strjoin(blockLines, ' '); %#ok<AGROW>
                        blockLines = {};   % Reset for next TODO block
                    end
                    insideTodo = false;   % No longer inside a TODO block
                end
            end
        end
        
        % Catch any TODO block that extends to the end of the file
        if ~isempty(blockLines)
            todoBlocks{end+1} = strjoin(blockLines, ' ');
        end
        
        % Write all TODO blocks for this file to the output Markdown file
        if ~isempty(todoBlocks)
            fprintf(fid_out, '---\n\n## %s\n`Path: %s`\n\n', file.name, relativePath);
            for b = 1:numel(todoBlocks)
                fprintf(fid_out, '- %s\n', todoBlocks{b});
            end
            fprintf(fid_out, '\n');
        end
    end
    fclose(fid_out);
    fprintf('TODO list saved to: %s\n', outFilename);
end
