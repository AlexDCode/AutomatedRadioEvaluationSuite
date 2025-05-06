function extractDocs(folderPath, outFilename, headerStr, excludedFolders)
    %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
    % DESCRIPTION:
    % Extracts documentation from .m files within a given folder and writes it to a Markdown file. Designed to 
    % support ReadTheDocs/Sphinx workflows. Example usage:
    %
    %   - extractDocs('./src/support/AntennaFunctions/', './docs/readthedocs/source/code_antenna.md', 'Antenna Functions')
    %   - extractDocs('./src/support/PAFunctions/', './docs/readthedocs/source/code_amp.md', 'Power Amplifier Functions')
    %   - extractDocs('./src/support/SupportFunctions/', './docs/readthedocs/source/code_support.md', 'Supporting Functions', {'matlab2tikz'})
    %
    % INPUT:
    %   folderPath      - Path to folder containing .m files (recursively searched)
    %   outFilename     - Path to output .md file
    %   headerStr       - (Optional) Header/title for the generated Markdown file
    %   excludedFolders - (Optional) Cell array of subfolders to exclude (by name)
    %
    % OUTPUT:
    %   None
    %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

    if nargin < 1, folderPath = pwd; end
    if nargin < 2, outFilename = 'documentation.md'; end
    if nargin < 3, headerStr = 'Function Documentation'; end
    if nargin < 4, excludedFolders = {}; end

    % Collect all .m files.
    files = dir(fullfile(folderPath, '**', '*.m'));

    % Open output file.
    fid_out = fopen(outFilename, 'w');
    if fid_out == -1
        error('Failed to open output file: %s', outFilename);
    end

    fprintf(fid_out, '# %s\n\n', headerStr);

    % Add folder and subfolders to path temporarily.
    addpath(genpath(folderPath));

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

                % Convert Greek letters to LaTeX math format
                line = convertGreekLettersToLatex(line);

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
    fprintf('Documentation saved to: %s\n', outFilename);
end

function out = formatAsBullets(lines)
    out = strjoin(cellfun(@(l) formatLine(l), lines, 'UniformOutput', false), newline);
end

function lineOut = formatLine(line)
    line = strtrim(line);
    if startsWith(line, '--')
        lineOut = ['  - ', strtrim(erase(line, '--'))];  % Indented sub-bullet
    elseif startsWith(line, '-')
        lineOut = ['- ', strtrim(erase(line, '-'))];     % Regular bullet
    else
        lineOut = ['- ', line];                          % Default to regular bullet
    end
end

function text = convertGreekLettersToLatex(text)
    % Define a mapping of Greek letters to their LaTeX math equivalents
    greekMap = containers.Map();
    
    % Lowercase Greek letters
    greekMap('α') = '$\alpha$';
    greekMap('β') = '$\beta$';
    greekMap('γ') = '$\gamma$';
    greekMap('δ') = '$\delta$';
    greekMap('ε') = '$\epsilon$';
    greekMap('ζ') = '$\zeta$';
    greekMap('η') = '$\eta$';
    greekMap('θ') = '$\theta$';
    greekMap('ι') = '$\iota$';
    greekMap('κ') = '$\kappa$';
    greekMap('λ') = '$\lambda$';
    greekMap('μ') = '$\mu$';
    greekMap('ν') = '$\nu$';
    greekMap('ξ') = '$\xi$';
    greekMap('ο') = '$\omicron$';
    greekMap('π') = '$\pi$';
    greekMap('ρ') = '$\rho$';
    greekMap('σ') = '$\sigma$';
    greekMap('τ') = '$\tau$';
    greekMap('υ') = '$\upsilon$';
    greekMap('φ') = '$\phi$';
    greekMap('χ') = '$\chi$';
    greekMap('ψ') = '$\psi$';
    greekMap('ω') = '$\omega$';
    
    % Uppercase Greek letters
    greekMap('Α') = '$\Alpha$';
    greekMap('Β') = '$\Beta$';
    greekMap('Γ') = '$\Gamma$';
    greekMap('Δ') = '$\Delta$';
    greekMap('Ε') = '$\Epsilon$';
    greekMap('Ζ') = '$\Zeta$';
    greekMap('Η') = '$\Eta$';
    greekMap('Θ') = '$\Theta$';
    greekMap('Ι') = '$\Iota$';
    greekMap('Κ') = '$\Kappa$';
    greekMap('Λ') = '$\Lambda$';
    greekMap('Μ') = '$\Mu$';
    greekMap('Ν') = '$\Nu$';
    greekMap('Ξ') = '$\Xi$';
    greekMap('Ο') = '$\Omicron$';
    greekMap('Π') = '$\Pi$';
    greekMap('Ρ') = '$\Rho$';
    greekMap('Σ') = '$\Sigma$';
    greekMap('Τ') = '$\Tau$';
    greekMap('Υ') = '$\Upsilon$';
    greekMap('Φ') = '$\Phi$';
    greekMap('Χ') = '$\Chi$';
    greekMap('Ψ') = '$\Psi$';
    greekMap('Ω') = '$\Omega$';

    % Common variant forms and symbols
    greekMap('ϕ') = '$\phi$';  % Variant of phi
    greekMap('ϑ') = '$\vartheta$';  % Variant of theta
    greekMap('ϵ') = '$\varepsilon$';  % Variant of epsilon
    greekMap('±') = '$\pm$';  % Plus-minus
    greekMap('∑') = '$\sum$';  % Summation
    greekMap('∏') = '$\prod$';  % Product
    greekMap('∫') = '$\int$';  % Integral
    greekMap('≈') = '$\approx$';  % Approximately
    greekMap('≤') = '$\leq$';  % Less than or equal
    greekMap('≥') = '$\geq$';  % Greater than or equal
    greekMap('≠') = '$\neq$';  % Not equal
    greekMap('∞') = '$\infty$';  % Infinity
    
    % Replace each Greek letter with its LaTeX equivalent
    keys = greekMap.keys();
    for i = 1:length(keys)
        key = keys{i};
        text = strrep(text, key, greekMap(key));
    end
end