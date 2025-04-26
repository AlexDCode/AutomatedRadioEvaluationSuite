function setupContextMenuFor3DPlot(app)
    %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
    % This function sets up a context menu for the 3D radiation pattern
    % plot created using Antenna Toolbox's internal renderer.
    %
    % INPUT PARAMETERS:
    %   app: Application object containing plot handles and export logic.
    %
    % This function:
    %   - Creates a right-click context menu on the 3D radiation plot
    %   - Adds export options (PNG, JPG) to the context menu
    %   - Assigns the menu to the axes and all child graphics objects
    %   - Ensures export functionality works even with toolbox-rendered 
    %     plots
    %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
   
    cm = uicontextmenu(app.UIFigure);

    formats = {'png', 'jpg'};
    for f = 1:length(formats)
        uimenu(cm, 'Text', ['Export as ', upper(formats{f})], ...
            'MenuSelectedFcn', @(src, event) exportPlots(app, app.RadiationPlot3DPattern, formats{f}));
    end

    % Attach to the main axes.
    app.RadiationPlot3DPattern.ContextMenu = cm;

    % Attach it to all child graphics objects.
    children = app.RadiationPlot3DPattern.Children;
    for i = 1:numel(children)
        try
            children(i).UIContextMenu = cm;
        catch
            % Some children may not support this property.
        end
    end
end
