function proceed = confirmRunWithoutGain(app)
    %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
    % DESCRIPTION:
    % Asks the user to confirm an antenna run that has no reference gain data, before anything moves. Such a run
    % still saves the S-parameters and insertion loss (plotted as a relative pattern), but no gain, which is easy
    % to miss until a long sweep has finished. Cancel is the default answer.
    %
    % INPUT:
    %   app     - ARES application object (uses UIFigure).
    %
    % OUTPUT:
    %   proceed - true if the user chose Continue.
    %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

    choice = uiconfirm(app.UIFigure, ...
        ['No reference gain file is loaded. This run will save S-parameters and insertion loss ' ...
         '(shown as a relative pattern), but no gain.'], ...
        'No Reference Gain', 'Options', {'Continue', 'Cancel'}, ...
        'DefaultOption', 2, 'CancelOption', 2, 'Icon', 'warning');
    proceed = strcmp(choice, 'Continue');
end
