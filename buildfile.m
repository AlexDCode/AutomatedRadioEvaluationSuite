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

    % Autodocument the code TODOs
    extractTODOs(fullfile(pwd,'src'), ...
                 './docs/readthedocs/source/TODOs.md');
end