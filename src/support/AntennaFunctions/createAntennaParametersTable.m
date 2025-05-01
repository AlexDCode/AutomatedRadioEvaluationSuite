function ParametersTable = createAntennaParametersTable(Theta, Phi)
    %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
    % DESCRIPTION:
    % This function generates a table of all possible combinations of θ and φ angles for antenna testing. The
    % function ensures that the input angles are properly processed and sorted for efficient use in antenna measurements.
    %
    % INPUT:
    %   Theta      - A vector of theta angles (in degrees). The angles can range from -180 to 180.
    %   Phi        - A vector of phi angles (in degrees). The angles can range from -180 to 180.
    %
    % OUTPUT:
    %   ParametersTable - A table containing all combinations of Theta in (degrees) and Phi in (degrees).
    %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

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
    ParametersTable = combinations(Theta, Phi);
    ParametersTable.Properties.VariableNames = varNames;

    % Movement angles for sorting (-180/180) range to (0-360 range).
    ParametersTable.MovementAngle = mod(ParametersTable.("Theta (deg)"), 360);

    % Sort by movement angle for efficient turntable rotation.
    [~, idx] = sort(ParametersTable.MovementAngle);
    ParametersTable = ParametersTable(idx, :);
     
    % Remove the temporary movement angles column used for sorting.
    ParametersTable.MovementAngle = [];
end