function plotAntenna3DRadiationPattern(app)
    %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
    % DESCRIPTION:
    % This function generates a 3D radiation pattern plot for the antenna based on the specified frequency. It
    % creates a 3D visualization of the antenna's radiation characteristics using theta, phi, and gain values
    % from the application data. The function:
    % 
    %   - Extracts the antenna gain data for the selected frequency
    %   - Processes angle data for consistent representation
    %   - Creates a properly formatted gain matrix
    %   - Renders the 3D radiation pattern with appropriate visual elements
    %   - Displays appropriate error or warning messages if data is inconsistent or invalid.
    %
    % INPUT:
    %   app  - Application object containing the antenna measurement data and UI components.
    %
    % OUTPUT:
    %   None - The function updates the application's UI components directly.
    %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

    try
        % Clear current plot, and its associated colorbar.
        cla(app.RadiationPlot3DPattern);
        ax = app.RadiationPlot3DPattern;
        app.RadiationPlot3DLabel.Text = '';

        % Delete colorbar if it exists.
        cb = findobj(ax.Parent, 'Tag', 'Colorbar');
        if ~isempty(cb)
            delete(cb);
        end

        % Specified frequency plotting index.
        if ~isempty(app.PlotFrequencyMHzDropDown.Value)
            idx_freq = (app.Antenna_Data.FrequencyMHz==str2double(app.PlotFrequencyMHzDropDown.Value));
        else 
            return;
        end

        % Extract theta, phi, and gain values for specified frequency.
        thetaValues = app.Antenna_Data.Thetadeg(idx_freq);
        phiValues   = app.Antenna_Data.Phideg(idx_freq);
        gainValues  = app.Antenna_Data.GaindBi(idx_freq);

        % Ensure wrapped angles are consistent.
        if ismember(-180, thetaValues) && ismember(180, thetaValues)
            thetaValues(thetaValues == -180) = 180;
        end
        if ismember(-180, phiValues) && ismember(180, phiValues)
            phiValues(phiValues == -180) = 180;
        end
        
        % Get unique sorted angles.
        uniqueTheta = unique(thetaValues);
        uniquePhi   = unique(phiValues);
        
        % Initialize and fill the gain matrix, which will be passed onto 
        % the Antenna Toolbox plotting function.
        [~, thetaIdx] = ismember(thetaValues, uniqueTheta);
        [~, phiIdx]   = ismember(phiValues, uniquePhi);

        gainMatrix = NaN(numel(uniquePhi), numel(uniqueTheta));
        linearIdx = sub2ind(size(gainMatrix), phiIdx, thetaIdx);
        gainMatrix(linearIdx) = gainValues;

        % Check for NaN Values
        if any(isnan(gainMatrix(:)))
            app.RadiationPlot3DLabel.FontWeight = 'bold';
            app.RadiationPlot3DLabel.Text = 'Warning: The gain matrix contains invalid (NaN) values.';
            return;
        end
        % Check for Matrix Dimensions 
        % GAIN MATRIX NEEDS TO BE NXM where N,M is >= 2
        if size(gainMatrix, 1) < 2 || size(gainMatrix, 2) < 2
            app.RadiationPlot3DLabel.FontWeight = 'bold';
            app.RadiationPlot3DLabel.Text = 'Error: The gain matrix must have at least 2 rows and 2 columns.';
            return;
        end

        % 1) 3D Radiation Pattern Plot
        % Using the internal spherical renderer for true polar axes from 
        % Antenna Toolbox.
        pause(0.1); 
        makeAntenna3DRadiationPattern(ax, gainMatrix, uniqueTheta, uniquePhi);
        cb = colorbar('peer', ax);
        ylabel(cb, 'Gain (dBi)');
        axis(ax, 'tight');

        % Improves the plot appearance, line thickness can be modified.
        improveAxesAppearance(ax, 'LineThickness', 2);

        setupContextMenuFor3DPlot(app)
    catch ME
        app.displayError(ME);
    end
end