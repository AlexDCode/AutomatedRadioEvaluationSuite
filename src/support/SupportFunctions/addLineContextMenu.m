function addLineContextMenu(hLine)
    %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
    % DESCRIPTION:
    % This function adds a right-click (context) menu to one or more line objects in a MATLAB figure. The context
    % menu provides quick interactive options to manipulate the line's visibility or delete it directly from the plot.
    %
    %   - Menu Items:
    %       - "Hide"   : Sets the line's 'Visible' property to 'off'.
    %       - "Show"   : Sets the line's 'Visible' property to 'on'.
    %       - "Delete" : Deletes the line object from the figure.
    %
    % INPUT:
    %   hLine - Handle to a line object or an array of line objects to which the context menu should be added.
    %
    % OUTPUT:
    %   None
    %
    % NOTES:
    %   - Throws an error if no valid line handle is provided.
    %   - Automatically finds the parent figure of each line to attach the context menu.
    %   - Supports multiple line handles at once.
    %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

    if nargin < 1 || isempty(hLine)
        error('You must provide a valid line handle.');
    end

    for k = 1:numel(hLine)
        % Find parent figure of the line
        fig = ancestor(hLine(k), 'figure');

        % Create context menu with correct parent
        cm = uicontextmenu(fig);

        % Create menu items
        uimenu(cm, 'Label', 'Hide', ...
            'Callback', @(src, evt) set(hLine(k), 'Visible', 'off'));
        
        uimenu(cm, 'Label', 'Show', ...
            'Callback', @(src, evt) set(hLine(k), 'Visible', 'on'));
        
        uimenu(cm, 'Label', 'Delete', ...
            'Callback', @(src, evt) delete(hLine(k)));

        % Attach context menu to line
        hLine(k).UIContextMenu = cm;
    end
end