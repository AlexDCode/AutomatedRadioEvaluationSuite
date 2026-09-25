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
    % A section heading is a whole comment line of capitals, with an optional parenthetical, ending in a colon:
    % "INPUT:", "TYPICAL USAGE:", "CONTRACT (all concrete transports must implement):". Requiring the colon to end
    % the line is what keeps SCPI such as FORM:DATA or SYST:ERR? from being read as a heading.
    %
    % DESCRIPTION, INPUT and OUTPUT are rendered as the description paragraph and the two parameter admonitions.
    % Any other heading becomes its own labelled block, so a class that documents a CONTRACT or a SAFETY note keeps
    % that structure instead of having it flattened into the description. USAGE and EXAMPLE blocks are rendered as
    % MATLAB code fences. TODO sections are skipped here because extractTODOs gives them their own page.
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

            % Drop the "Documentation for X / doc X" footer that help()
            % appends for classdef files; it is boilerplate, not our text.
            docString = stripHelpFooter(docString);

            sections = parseSections(docString);

            % Write to Markdown.
            fprintf(fid_out, '---\n\n## %s\n`Path: %s`\n\n', file.name, relativePath);

            for s = 1:numel(sections)
                writeSection(fid_out, sections(s));
            end

        catch ME
            warning('Failed to process %s: %s', file.name, ME.message);
        end
    end

    fclose(fid_out);
    fprintf('Documentation saved to: %s\n', outFilename);
end

function sections = parseSections(docString)
    % Split a help string into an ordered list of {Name, Lines} sections.
    lines = strsplit(docString, newline);

    sections = struct('Name', {'DESCRIPTION'}, 'Lines', {{}});
    cur = 1;

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

        % Detect section headers (see the note in the file header).
        heading = regexp(strtrim(line), '^([A-Z][A-Z0-9 ]*(?:\([^)]*\))?)\s*:$', ...
            'tokens', 'once');
        if ~isempty(heading)
            name = strtrim(heading{1});
            idx  = find(strcmpi({sections.Name}, name), 1);
            if isempty(idx)
                sections(end+1) = struct('Name', name, 'Lines', {{}}); %#ok<AGROW>
                cur = numel(sections);
            else
                cur = idx;
            end
            continue;
        end

        sections(cur).Lines{end+1} = line;
    end
end

function writeSection(fid_out, section)
    body = section.Lines;
    if isempty(body)
        return;
    end

    % Route on the leading word(s), ignoring any parenthetical, so that
    % "OUTPUT (struct):" is still the output section.
    baseName = strtrim(regexprep(upper(section.Name), '\(.*$', ''));

    switch baseName
        case 'DESCRIPTION'
            writeDescription(fid_out, body);

        case 'INPUT'
            fprintf(fid_out, '```{admonition} Input Parameters\n:class: tip\n%s\n```\n\n', ...
                formatParams(body));

        case 'OUTPUT'
            fprintf(fid_out, '```{admonition} Output Parameters\n:class: tip\n%s\n```\n\n', ...
                formatParams(body));

        case 'TODO'
            % extractTODOs gives these their own page; skip them here.

        case {'USAGE', 'TYPICAL USAGE', 'EXAMPLE', 'EXAMPLES'}
            % A usage block often opens with a line of prose setting the
            % scene ("At app startup:"). Keep that out of the code fence.
            isCode = ~cellfun(@isempty, regexp(body, '[=();]', 'once'));
            firstCode = find(isCode, 1);
            if isempty(firstCode)
                prose = body;    code = {};
            else
                prose = body(1:firstCode-1);
                code  = body(firstCode:end);
            end

            fprintf(fid_out, '**%s**\n\n', headingText(section.Name));
            if ~isempty(prose)
                fprintf(fid_out, '%s\n\n', strjoin(prose, ' '));
            end
            if ~isempty(code)
                fprintf(fid_out, '```matlab\n%s\n```\n\n', strjoin(code, newline));
            end

        otherwise
            fprintf(fid_out, '**%s**\n\n%s\n\n', ...
                headingText(section.Name), formatParams(body));
    end
end

function writeDescription(fid_out, descriptionLines)
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
        fprintf(fid_out, '%s\n\n', formatAsBullets(bulletLines));
    end
end

function txt = headingText(name)
    % "CONTRACT (all concrete transports must implement)" reads better in the
    % rendered page as "Contract (all concrete transports must implement)".
    txt = regexprep(strtrim(name), '^([A-Z])([A-Z0-9 ]*)', ...
        '${[$1 lower($2)]}', 'once');

    % Put back acronyms that should not have been down-cased.
    acronyms = {'CSV', 'SCPI', 'JSON', 'VISA', 'VNA', 'PSU', 'TCP', 'RF', ...
        'PA', 'UI', 'API'};
    for i = 1:numel(acronyms)
        txt = regexprep(txt, ...
            ['(?<![A-Za-z])', lower(acronyms{i}), '(?![A-Za-z])'], ...
            acronyms{i}, 'ignorecase');
    end
end

function docString = stripHelpFooter(docString)
    % help() appends a trailer for classdef files. Cut from the first such
    % line to the end.
    lines = strsplit(docString, newline);
    markers = {'Documentation for ', 'Other uses of ', 'Other functions named ', ...
        'Other classes named '};
    for i = 1:numel(lines)
        if any(startsWith(strtrim(lines{i}), markers))
            lines = lines(1:i-1);
            break;
        end
    end
    docString = strjoin(lines, newline);
end

function out = formatParams(lines)
    % Bullet list where a wrapped continuation line stays attached to the
    % parameter above it instead of becoming its own bullet.
    items = {};
    for i = 1:numel(lines)
        l = strtrim(lines{i});
        if isempty(l)
            continue;
        end

        if startsWith(l, '--')
            items{end+1} = ['  - ', strtrim(erase(l, '--'))]; %#ok<AGROW>
        elseif startsWith(l, '-')
            items{end+1} = ['- ', strtrim(regexprep(l, '^-+', ''))]; %#ok<AGROW>
        elseif ~isempty(items) && isempty(regexp(l, '\s-\s', 'once'))
            % No " - " anywhere, so this is a wrapped continuation of the
            % entry above rather than a new one. Testing for the separator
            % itself also handles entries whose left side contains spaces,
            % such as "s = readLine()  - read one response".
            items{end} = [items{end}, ' ', l];
        else
            items{end+1} = ['- ', l]; %#ok<AGROW>
        end
    end
    out = strjoin(items, newline);
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
