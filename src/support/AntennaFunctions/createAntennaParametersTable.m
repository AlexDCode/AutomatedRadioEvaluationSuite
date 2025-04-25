function paramTable = createAntennaParametersTable(Theta, Phi)
    %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
    % This function creates a parameter sweep table for antenna testing,
    % generating all possible combinations of Theta and Phi.
    %
    % INPUT PARAMETERS:
    %   Theta:  Vector of theta angles (in degrees).
    %   Phi:    Vector of phi angles (in degrees).
    %
    % OUTPUT PARAMETERS:
    %   paramTable - A table containing all combinations of Theta in (deg)
    %                and Phi in (deg).
    %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

    % -180 maps to 180 in the EMCenter hardware we remove it from the list.
    if ismember(-180, Theta) && ismember(180, Theta)
        Theta = Theta(Theta ~= -180);
    end
    if ismember(-180, Phi) && ismember(180, Phi)
        Phi = Phi(Phi ~= -180);
    end

    % Set the column names for the table.
    varNames = {"Theta (deg)", "Phi (deg)"};
    varNames = horzcat(varNames{:});

    % Create the table with combinations of theta and phi.
    paramTable = combinations(Theta, Phi);
    paramTable.Properties.VariableNames = varNames;

    % Movement angles for sorting (-180/180) range to (0-360 range).
    paramTable.MovementAngle = mod(paramTable.("Theta (deg)"), 360);

    % Sort by movement angle for efficient turntable rotation.
    [~, idx] = sort(paramTable.MovementAngle);
    paramTable = paramTable(idx, :);
     
    % Remove the temporary movement angles column used for sorting.
    paramTable.MovementAngle = [];
end