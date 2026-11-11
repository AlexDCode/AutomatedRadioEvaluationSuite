function ParametersTable = createAntennaParametersTable(Theta, Phi, ThetaRange)
    %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
    % DESCRIPTION:
    % This function generates a table of all possible combinations of θ and φ angles for antenna testing. The
    % function ensures that the input angles are properly processed and sorted for efficient use in antenna measurements:
    % one φ cut at a time, θ ascending in the turntable's own angle range within each cut.
    %
    % INPUT:
    %   Theta      - A vector of theta angles (in degrees). The angles can range from -180 to 180.
    %   Phi        - A vector of phi angles (in degrees). The angles can range from -180 to 180.
    %   ThetaRange - (Optional) The turntable's angle range, "-180to180" (default) or "0to360". Positions are
    %                sorted by the angle actually sent to the turntable so it sweeps in one direction.
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

    % Measure one phi cut at a time (the tower turns only between cuts, not
    % at every theta step), and within a cut sort by the angle sent to the
    % turntable so it sweeps in one direction without wrapping through the
    % cable stop.
    if nargin < 3, ThetaRange = "-180to180"; end
    movementAngle = AntennaPositioner.thetaCommandAngle(ParametersTable.("Theta (deg)"), ThetaRange);
    [~, idx] = sortrows([ParametersTable.("Phi (deg)"), movementAngle]);
    ParametersTable = ParametersTable(idx, :);
end