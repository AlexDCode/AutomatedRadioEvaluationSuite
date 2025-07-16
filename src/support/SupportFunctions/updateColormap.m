function updateColormap(app)
    %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
    % DESCRIPTION:
    % This function updates the colormaps of UIAxes in MATLAB App Designer.
    % Colormaps are primarily used on 3D surfaces.
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
        cmap = app.ColorMapsDropDown.Value;
        if strcmp(cmap, 'default')
            cmap = 'parula';
        end

        for i = 1:length(axList)
            ax = axList(i);
            % Make sure it's an Axes object
            if ~isa(ax, 'matlab.graphics.axis.Axes')
                continue;
            end

            % Check if axis contains 3D surface (look for 'Surface' object)
            has3D = any(strcmp(get(get(ax, 'Children'), 'Type'), 'surface'));
            if has3D
                % Only apply colormaps
                colormap(ax, cmap);
            end
        end
    catch ME
        app.displayError(ME);
    end
end