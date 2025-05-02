function extract_docs(folder_path, output_filename, headerStr, excludedFolders)
    %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
    % DESCRIPTION:
    % Extracts documentation from .m files within a given folder and writes it to a Markdown file. Designed to 
    % support ReadTheDocs/Sphinx workflows.
    %
    % INPUT:
    %   folder_path      - Path to folder containing .m files (recursively searched)
    %   output_filename  - Path to output .md file
    %   headerStr        - Header/title for the generated Markdown file
    %   excludedFolders  - (Optional) Cell array of subfolders to exclude (by name)
    %
    % EXAMPLES:
    %   extract_docs('./src/support/AntennaFunctions/', 'docs/code_antenna.md', 'Antenna Functions')
    %   extract_docs('./src/support/PAFunctions/','./docs/readthedocs/source/code_amp.md', 'Power Amplifier Functions')
    %   extract_docs('./src/support/SupportFunctions/', 'docs/code_support.md', 'Support Functions', {'matlab2tikz'})
    %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

    if nargin < 1, folder_path = pwd; end
    if nargin < 2, output_filename = 'documentation.md'; end
    if nargin < 3, headerStr = 'Function Documentation'; end
    if nargin < 4, excludedFolders = {}; end

    % Collect all .m files.
    files = dir(fullfile(folder_path, '**', '*.m'));

    % Open output file.
    fid_out = fopen(output_filename, 'w');
    if fid_out == -1
        error('Failed to open output file: %s', output_filename);
    end

    fprintf(fid_out, '# %s\n\n', headerStr);

    % Add folder and subfolders to path temporarily.
    addpath(genpath(folder_path));

    for k = 1:length(files)
        file = files(k);
        fullFilePath = fullfile(file.folder, file.name);

        % Skip excluded folders.
        relativePath = erase(fullFilePath, [pwd filesep]);
        if any(contains(relativePath, excludedFolders))
            continue;
        end

        try
            docString = help(fullFilePath);
            if isempty(strtrim(docString))
                docString = 'No documentation provided.';
            end

            % Split and parse sections.
            lines = strsplit(docString, newline);
            descriptionLines = {};
            inputLines = {};
            outputLines = {};
            section = "description";

            for i = 1:numel(lines)
                line = strtrim(lines{i});

                % Ignore visual dividers.
                if isempty(line) || all(ismember(line, '%-*')) || contains(line, '%%%')
                    continue;
                end

                % Remove leading %.
                if startsWith(line, '%')
                    line = regexprep(line, '^\s*%+\s?', '');
                end

                % Detect section headers.
                if startsWith(line, 'INPUT', 'IgnoreCase', true)
                    section = "input"; continue;
                elseif startsWith(line, 'OUTPUT', 'IgnoreCase', true)
                    section = "output"; continue;
                elseif startsWith(line, 'DESCRIPTION', 'IgnoreCase', true)
                    section = "description"; continue;
                end

                switch section
                    case "description", descriptionLines{end+1} = line; %#ok<AGROW>
                    case "input",      inputLines{end+1} = line; %#ok<AGROW>
                    case "output",     outputLines{end+1} = line; %#ok<AGROW>
                end
            end

            % Write to Markdown.
            fprintf(fid_out, '---\n\n## %s\n`Path: %s`\n\n', file.name, relativePath);

            % Write DESCRIPTION
            if ~isempty(descriptionLines)
                fprintf(fid_out, '**Description:**\n\n');
            
                % Split into bullet and non-bullet lines
                isBullet = startsWith(strtrim(descriptionLines), '-');
                bulletLines = descriptionLines(isBullet);
                narrativeLines = descriptionLines(~isBullet);
            
                % Write narrative text as paragraph
                if ~isempty(narrativeLines)
                    fprintf(fid_out, '%s\n\n', strjoin(narrativeLines, ' '));
                end
            
                % Write bullet points properly
                if ~isempty(bulletLines)
                    formattedBullets = formatAsBullets(bulletLines);
                    fprintf(fid_out, '%s\n\n', formattedBullets);
                end
            end

            % Write INPUT PARAMETERS
            if ~isempty(inputLines)
                fprintf(fid_out, '```{admonition} Input Parameters\n:class: tip\n%s\n```\n\n', ...
                    formatAsBullets(inputLines));
            end

            % Write OUTPUT PARAMETERS
            if ~isempty(outputLines)
                fprintf(fid_out, '```{admonition} Output Parameters\n:class: tip\n%s\n```\n\n', ...
                    formatAsBullets(outputLines));
            end

        catch ME
            warning('Failed to process %s: %s', file.name, ME.message);
        end
    end

    fclose(fid_out);
    fprintf('Documentation saved to: %s\n', output_filename);
end

function out = formatAsBullets(lines)
    % Only add dash if the line doesn't already start with a dash
    out = strjoin(cellfun(@(l) formatLine(l), lines, 'UniformOutput', false), newline);
end

function lineOut = formatLine(line)
    line = strtrim(line);
    if startsWith(line, '-')
        lineOut = line;
    else
        lineOut = ['- ', line];
    end
end

