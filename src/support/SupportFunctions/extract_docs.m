function extract_docs(folder_path,output_filename, headerStr)
    %EXTRACT_DOCS Extracts help comments from all .m files in a folder.
    %   extract_docs('path/to/your/folder', 'path/to/your/outputfile','Header String')
    
    if nargin < 1
        folder_path = pwd;  % Default to current directory
    end
    if nargin < 2
        output_filename =  'documentation.md'; % Default filename
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

        try
            docString = help(file.name);
            if ~isempty(strtrim(docString))
                relPath = strrep(fullfile(file.folder, file.name), [folder_path filesep], '');
                fprintf(fid_out, '## %s\n`File path: %s`\n%s\n\n', file.name, relPath, docString);
            end
        catch ME
            warning('Could not extract help from %s: %s', file.name, ME.message);
        end
    end
    
    fclose(fid_out);
    fprintf('Documentation saved to: %s\n', output_filename);
end