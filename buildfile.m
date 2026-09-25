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