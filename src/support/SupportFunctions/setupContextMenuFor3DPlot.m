function setupContextMenuFor3DPlot(app)
    %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
    % DESCRIPTION:
    % This function sets up a right-click context menu for the 3D radiation pattern plot, allowing the user to 
    % export the visualization to image formats (PNG and JPG). This is particularly useful because plots rendered
    % using the Antenna Toolbox may have limited export options or reduced visual quality by default.
    %
    % INPUT:
    %   app - Application object containing the 3D plot handle and export logic.
    %
    % OUTPUT:
    %   None
    %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
   
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
