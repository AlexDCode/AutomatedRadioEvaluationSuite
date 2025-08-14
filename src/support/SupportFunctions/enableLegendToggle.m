%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
% DESCRIPTION:
% This function enables interactive toggling of plot visibility through the figure legend. When enabled, clicking
% on any legend entry will hide or show the corresponding plot object (line, patch, or other graphics). This feature 
% improves the user experience by allowing selective visualization of traces without removing them from the plot.
%
% The function sets the `ItemHitFcn` callback for the legend to toggle the `Visible` property of the plot object.
%
% INPUT:
%   lgd  - Legend handle created for the target plot. Must be a valid legend object returned by the `legend()` function.
%
% OUTPUT:
%   None
%
% USAGE:
%   figure;
%   plot(x, y1, 'LineWidth', 2); hold on;
%   plot(x, y2, 'LineWidth', 2);
%   lgd = legend('Trace 1', 'Trace 2');
%   enableLegendToggle(lgd);
%
% NOTES:
%   - Requires MATLAB R2016a or newer (support for `ItemHitFcn`).
%   - Works with lines, patches, and most common plot objects.
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
function enableLegendToggle(lgd)
    % Validate input
    if ~isa(lgd, 'matlab.graphics.illustration.Legend')
        error('Input must be a valid legend handle.');
    end

    % Set callback for interactive toggling
    lgd.ItemHitFcn = @(src, event) toggleVisibility(event);
end

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
% DESCRIPTION:
% This internal helper function toggles the visibility of the plot object linked to a clicked legend entry.
%
% INPUT:
%   event - Event data structure provided by MATLAB when a legend item is clicked. The `Peer` field contains the
%           associated plot object.
%
% OUTPUT:
%   None
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
function toggleVisibility(event)
    obj = event.Peer;
    if strcmp(obj.Visible, 'on')
        obj.Visible = 'off';
    else
        obj.Visible = 'on';
    end
end
