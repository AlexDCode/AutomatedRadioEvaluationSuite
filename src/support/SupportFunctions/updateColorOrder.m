function updateColorOrder(app)
    %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
    % DESCRIPTION:
    % This function updates the colororder of UIAxes in MATLAB App Designer.
    % Color order is primarily used on line plots (rectangular and polar axes)
    %
    % INPUT:
    %   app             - MATLAB app which contains the UIAxes
    %
    % OUTPUT:
    % None
    %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

    % Find axes
    axList = [findall(app.UIFigure, 'Type', 'axes'); ...
              findall(app.UIFigure, 'Type', 'polaraxes')];

    try
        cmap = app.ColorOrderDropDown.Value;
        if strcmp(cmap, 'default')
            cmap = 'gem';
        end
        for i = 1:length(axList)
            ax = axList(i);
            % Make sure it's an Axes object
            colororder(ax, cmap);
        end
    catch ME
        app.displayError(ME);
    end
end