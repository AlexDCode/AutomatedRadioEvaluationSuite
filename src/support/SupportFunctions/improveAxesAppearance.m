function improveAxesAppearance(axesObj, varargin)
    %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
    % DESCRIPTION:
    % This function improves the appearance of UIAxes in MATLAB App Designer. It supports enhancing single or dual
    % Y-axis (yyaxis) plots.
    %
    % INPUT:
    %   axesObj        - Handle to the UIAxes object.
    %   'YYAxis'       - Logical (true/false), if the plot uses yyaxis.
    %   'LineThickness'- Scalar > 0, sets line thickness for plotted lines.
    % 
    % OUTPUT:
    % None
    %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

    % Default settings.
    defaultYYAxis = false;
    defaultLineThickness = 1.5;

    % Parse inputs.
    p = inputParser;
    addRequired(p, 'axesObj');
    addParameter(p, 'YYAxis', defaultYYAxis, @(x) islogical(x) || isnumeric(x));
    addParameter(p, 'LineThickness', defaultLineThickness, @(x) isnumeric(x) && isscalar(x) && x > 0);
    parse(p, axesObj, varargin{:});

    useYYAxis = logical(p.Results.YYAxis);
    lineThickness = p.Results.LineThickness;

    % Apply general axes formatting.
    axesObj.FontSize = 12;
    axesObj.TitleFontSizeMultiplier = 1.2;
    axesObj.LabelFontSizeMultiplier = 1.1;
    axesObj.Box = 'on';
    axesObj.LineWidth = 1.5;

    % Grid styling.
    axesObj.GridLineStyle = ':';
    axesObj.GridAlpha = 0.3;
    axesObj.GridColor = [0.5, 0.5, 0.5];

    % Axis label styling.
    axesObj.XLabel.FontWeight = 'bold';
    axesObj.YLabel.FontWeight = 'bold';

    % Enhance legend if present.
    if isgraphics(axesObj.Legend)
        axesObj.Legend.FontSize = 10;
        axesObj.Legend.Location = 'best';
        axesObj.Legend.Box = 'on';
    end

    % Adjust line thickness (handle yyaxis if enabled).
    if useYYAxis
        yyaxis(axesObj, 'left');
        adjustLineWidths(axesObj, lineThickness);
        yyaxis(axesObj, 'right');
        adjustLineWidths(axesObj, lineThickness);
    else
        adjustLineWidths(axesObj, lineThickness);
    end
end

function adjustLineWidths(ax, thickness)
    % Helper function to set line thickness.
    for i = 1:numel(ax.Children)
        child = ax.Children(i);
        if isprop(child, 'LineWidth')
            child.LineWidth = thickness;
        end
    end
end
