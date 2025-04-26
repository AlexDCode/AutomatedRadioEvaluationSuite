function extract_docs(folder_path,output_filename)
    %EXTRACT_DOCS Extracts help comments from all .m files in a folder.
    %   extract_docs('path/to/your/folder')
    
    if nargin < 1
        folder_path = pwd;  % Default to current directory
    end
    if nargin < 2
        output_filename =  'documentation.md'; % Default filename
    end
    
    % Get all .m files recursively
    files = dir(fullfile(folder_path, '**', '*.m'));
    output_file = fullfile(folder_path, output_filename);
    fid_out = fopen(output_file, 'w');
    
    % Add root folder and all subfolders to path temporarily
    addpath(genpath(folder_path));
    
    for k = 1:length(files)
        file = files(k);

        try
            docString = help(file.name);
            if ~isempty(strtrim(docString))
                relPath = strrep(fullfile(file.folder, file.name), [folder_path filesep], '');
                fprintf(fid_out, '## %s\n%s\n\n', relPath, docString);
            end
        catch ME
            warning('Could not extract help from %s: %s', file.name, ME.message);
        end
    end
    
    fclose(fid_out);
    fprintf('Documentation saved to: %s\n', output_file);
end