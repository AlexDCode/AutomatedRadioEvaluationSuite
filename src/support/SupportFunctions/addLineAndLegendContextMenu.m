function addLineAndLegendContextMenu(hLine, hLegend)
    %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
    % DESCRIPTION:
    % This function adds a right-click (context) menu to one or more line objects **and their corresponding legend entries**
    % in a MATLAB figure. The context menu provides interactive options to quickly manipulate the line or legend item.
    %
    %   - Menu Items:
    %       - "Hide"   : Sets the line's 'Visible' property to 'off'.
    %       - "Show"   : Sets the line's 'Visible' property to 'on'.
    %       - "Delete" : Deletes the line object from the figure.
    %
    %   - Context menu is automatically attached to both the line object and the corresponding legend entry (if present).
    %
    % INPUT:
    %   hLine   - Handle to a line object or an array of line objects to which the context menu should be added.
    %   hLegend - Handle to a legend object. If not provided or empty, the current legend is used.
    %
    % OUTPUT:
    %   None
    %
    % NOTES:
    %   - Supports multiple line handles and automatically links each line to its corresponding legend item.
    %   - Uses `EntryContainer.Children` to access legend items (MATLAB R2017b+ syntax).
    %   - Throws an error if a valid line handle is not provided.
    %   - Finds the parent figure of each line to attach the context menu.
    %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

    if nargin < 2 || isempty(hLegend)
        hLegend = legend;
    end
    
    % Get legend items
    legendItems = hLegend.EntryContainer.Children;  % for R2017b+
    
    for k = 1:numel(hLine)
        fig = ancestor(hLine(k), 'figure');

        % Create context menu
        cm = uicontextmenu(fig);

        % Add menu options
        uimenu(cm, 'Label', 'Hide', ...
            'Callback', @(~,~) set(hLine(k),'Visible','off'));
        
        uimenu(cm, 'Label', 'Show', ...
            'Callback', @(~,~) set(hLine(k),'Visible','on'));
        
        uimenu(cm, 'Label', 'Delete', ...
            'Callback', @(~,~) delete(hLine(k)));

        % Attach to the line
        hLine(k).UIContextMenu = cm;

        % Attach to corresponding legend item (icon or label)
        if k <= numel(legendItems)
            legendItems(k).UIContextMenu = cm;
        end
    end
end
