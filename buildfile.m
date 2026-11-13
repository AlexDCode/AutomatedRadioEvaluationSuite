function plan = buildfile
    import matlab.buildtool.tasks.*

    % Create build plan from local functions
    plan = buildplan(localfunctions);

    % Standard tasks
    plan("clean") = CleanTask;
    plan("check") = CodeIssuesTask;
    plan("test") = TestTask;

    % Default tasks: run Auto-Docs, then check and test
    plan.DefaultTasks = ["autodocs" "check" "test"];
end

%% -------------------------------------------------------------------
% Local function executed by Auto-Docs task
function autodocsTask(~)
    % Put this repo ahead of anything else on the path. Without it, an ARES
    % release installed as a MATLAB Add-On shadows src/, and the first few
    % extractDocs calls silently run the installed copy instead of this one.
    addpath(genpath('./src'));

    % Autodocument the code description
    extractDocs('./src/support/AntennaFunctions/', ...
                './docs/readthedocs/source/code_antenna.md', ...
                'Antenna Functions');
    extractDocs('./src/support/PAFunctions/', ...
                './docs/readthedocs/source/code_amp.md', ...
                'Power Amplifier Functions');
    extractDocs('./src/support/SupportFunctions/', ...
                './docs/readthedocs/source/code_support.md', ...
                'Supporting Functions', {'matlab2tikz'});
    extractDocs('./src/support/InstrumentControl/', ...
                './docs/readthedocs/source/code_instr.md', ...
                'Instrument Factory');

    % Autodocument the code TODOs
    extractTODOs(fullfile(pwd,'src'), ...
                 './docs/readthedocs/source/TODOs.md', ...
                 'TODO Items', {'matlab2tikz'});
end

%% -------------------------------------------------------------------
% Local function executed by Screenshots task
function screenshotsTask(~)
    % Capture every UI tab into a staging folder under the docs assets, for
    % refreshing the interface images in the documentation.
    %
    % Not a default task: exportapp captures a rendered on-screen window, so
    % this needs an interactive desktop session and cannot run headless.
    % Review the staged images and move the ones you want into assets/Ant,
    % assets/PA or assets/Settings.
    captureAppScreenshots('./docs/readthedocs/source/assets/auto');
end

%% -------------------------------------------------------------------
% Local function executed by Package task
function packageTask(~)
    % Build the installable toolbox, src/release/ARES.mltbx, from the src
    % folder. Run it with "buildtool package" when making a release, then
    % attach the file to the GitHub release.
    %
    % Not a default task. The version is read from the app (the <Version>
    % field in ARES.xml), so bump it in App Designer first.
    src = fullfile(pwd, 'src');

    % Same identifier as every earlier release, so installing a new version
    % replaces the old one instead of sitting beside it.
    opts = matlab.addons.toolbox.ToolboxOptions(src, "204ded41-db44-42c3-88fe-8420effa75da");
    opts.ToolboxName    = "Automated Radio Evaluation Suite";
    opts.ToolboxVersion = string(regexp(fileread(fullfile(src, 'ARES.xml')), ...
                              '(?<=<Version>)[^<]+', 'match', 'once'));
    opts.Summary        = "ARES";
    opts.Description    = "Automated RF measurements with SCPI commands sent by VISA";
    opts.AuthorName     = "Alex Santiago";

    % Leave out the tests, the previous package (so it is not packed inside
    % the new one) and the ignore list. Done here because R2026b does not
    % apply src/toolbox.ignore to these.
    leftOut = @(p) contains(p + filesep, filesep + ["tests", "release"] + filesep) ...
                   | endsWith(p, ".ignore");
    files = string(opts.ToolboxFiles);
    paths = string(opts.ToolboxMatlabPath);
    opts.ToolboxFiles      = files(~leftOut(files));
    opts.ToolboxMatlabPath = paths(~leftOut(paths));

    % The app is saved in the R2026b text format (ARES.m + ARES.xml).
    opts.MinimumMatlabRelease = "R2026b";
    opts.SupportedPlatforms.Win64        = true;
    opts.SupportedPlatforms.Glnxa64      = false;
    opts.SupportedPlatforms.Mac          = false;
    opts.SupportedPlatforms.MatlabOnline = true;

    % Show ARES in the Apps tab, as earlier releases did.
    opts.AppGalleryFiles  = fullfile(src, 'ARES.m');
    opts.ToolboxImageFile = fullfile(src, 'assets', 'ARES Icon.png');

    opts.OutputFile = fullfile(src, 'release', 'ARES.mltbx');
    matlab.addons.toolbox.packageToolbox(opts);
    fprintf('Packaged ARES %s -> %s\n', opts.ToolboxVersion, opts.OutputFile);
end