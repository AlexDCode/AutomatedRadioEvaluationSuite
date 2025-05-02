function extract_docs(folder_path, output_filename, headerStr, excludedFolders)
    %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
    %EXTRACT_DOCS Extracts help comments from all .m files in a folder.
    % extract_docs('path/to/your/folder', 'path/to/your/outputfile', 'Header String')

    % Example use for this project:
    % extract_docs('./src/support/AntennaFunctions/','./docs/readthedocs/source/code_antenna.md', 'Antenna Functions')
    % extract_docs('./src/support/PAFunctions/','./docs/readthedocs/source/code_amp.md', 'Power Amplifier Functions')
    % extract_docs('./src/support/SupportFunctions/','./docs/readthedocs/source/code_support.md', 'Supporting Functions')
    % extract_docs('./src/support/SupportFunctions/', './docs/readthedocs/source/code_support.md', 'Supporting Functions', {'matlab2tikz'})
    %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
    
    if nargin < 1
        folder_path = pwd;  % Default to current directory
    end
    if nargin < 2
        output_filename =  'documentation.md'; % Default filename
    end

    if nargin < 4
        excludedFolders = {};
    end
    
    % Get all .m files recursively
    files = dir(fullfile(folder_path, '**', '*.m'));
    fid_out = fopen(output_filename, 'w');

    if fid_out == -1
        error('Could not open markdown file for writing.');
    end

    if nargin == 3
        fprintf(fid_out, '# %s\n\n', headerStr);
    end

    
    % Add root folder and all subfolders to path temporarily
    addpath(genpath(folder_path));
    
    for k = 1:length(files)
        file = files(k);

        % Skip files inside excluded folders
        relativePath = strrep(fullfile(file.folder, file.name), [fullfile(pwd) filesep], '');
        shouldSkip = any(cellfun(@(folder) contains(relativePath, folder), excludedFolders));
        if shouldSkip
            continue;
        end

        try
            docString = help(file.name);
            if isempty(strtrim(docString))
                docString = 'No documentation provided.';
            end

            relPath = strrep(fullfile(file.folder, file.name), [fullfile(pwd) filesep], '');

            % Split docstring into lines
            lines = strsplit(docString, newline);

            % State machine to collect sections
            descriptionLines = {};
            inputLines = {};
            outputLines = {};
            section = "description";

            for i = 1:length(lines)
                line = strtrim(lines{i});

                % Skip comment-only decorations like %%%%%%%
                if isempty(line) || all(line == '%') || all(line == '%') || all(line == '-') || all(line == '*') || contains(line, '%%%')
                    continue;
                end

                % Strip leading `%` and whitespace
                if startsWith(line, '%')
                    %line = strtrim(regexprep(line, '^%+', ''));
                    line = regexprep(line, '^\s*%+\s?', '');
                end

                if startsWith(line, 'DESCRIPTION:', 'IgnoreCase', true)
                    section = "description";
                    continue;
                end
                
                if startsWith(line, 'INPUT:', 'IgnoreCase', true)
                    section = "input";
                    continue;
                elseif startsWith(line, 'OUTPUT:', 'IgnoreCase', true)
                    section = "output";
                    continue;
                end

                switch section
                    case "description"
                        descriptionLines{end+1} = line; %#ok<AGROW>
                    case "input"
                        inputLines{end+1} = line; %#ok<AGROW>
                    case "output"
                        outputLines{end+1} = line; %#ok<AGROW>
                end
            end

            % Write function name and file path
            fprintf(fid_out, '## %s\n`File path: %s`\n\n', file.name, relPath);

            % Helper to format lines into bullet points
            formatAsBullets = @(lines) strjoin(cellfun(@(l) ['- ', strtrim(l)], lines, 'UniformOutput', false), newline);
            
            % Write DESCRIPTION
            if ~isempty(descriptionLines)
                isBullet = startsWith(strtrim(descriptionLines), '-');
                bulletLines = descriptionLines(isBullet);
                narrativeLines = descriptionLines(~isBullet);

                fprintf(fid_out, '**DESCRIPTION:**\n\n');

                if ~isempty(narrativeLines)
                    fprintf(fid_out, '%s\n\n', strjoin(narrativeLines, ' '));
                end
                if ~isempty(bulletLines)
                    %formattedProcess = formatAsBullets(bulletLines);
                    fprintf(fid_out, '%s\n', bulletLines{:});
                    fprintf(fid_out, '\n');
                end
            end

            % Write INPUT PARAMETERS as bullet list in custom admonition
            if ~isempty(inputLines)
                formattedInputs = formatAsBullets(inputLines);
                fprintf(fid_out, '```{admonition} Input\n:class: note\n\n%s\n```\n\n', formattedInputs);
            end
            
            % Write OUTPUT PARAMETERS as bullet list in custom admonition
            if ~isempty(outputLines)
                formattedOutputs = formatAsBullets(outputLines);
                fprintf(fid_out, '```{admonition} Output\n:class: note\n\n%s\n```\n\n', formattedOutputs);
            end

        catch ME
            warning('Could not extract help from %s: %s', file.name, ME.message);
        end
    end
    
    fclose(fid_out);
    fprintf('Documentation saved to: %s\n', output_filename);
end