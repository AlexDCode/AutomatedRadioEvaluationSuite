function plotAntenna3DRadiationPattern(app)
    %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
    % DESCRIPTION:
    % This function generates a 3D radiation pattern plot for the antenna based on the specified frequency. It
    % uses the Antenna Toolbox's internal spherical renderer to plot a 3D radiation pattern based on theta, 
    % phi, and gain values in the application UI. The function:
    % 
    %   - Extracts the antenna gain data for the specified frequency.
    %   - Ensures consistency in angle data (handling edge cases like -180 and 180 degrees).
    %   - Creates and displays the 3D radiation pattern plot.
    %   - Displays appropriate error or warning messages if data is inconsistent or invalid.
    %
    % INPUT:
    %   app  - Application object containing the antenna measurement data and plot handles.
    %
    % OUTPUT:
    %   None
    %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

    try
        % Clear current plot, and its associated colorbar.
        cla(app.RadiationPlot3DPattern);
        ax = app.RadiationPlot3DPattern;
        app.RadiationPlot3DLabel.Text = '';
        colorbar(ax, 'delete');

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
        antennashared.internal.radiationpattern3D(ax, gainMatrix, uniqueTheta, uniquePhi, 'CurrentAxes', 1);
        ylabel(colorbar(ax), 'Gain (dBi)');
        axis(ax, 'tight');

        % Improves the plot appearance, line thickness can be modified.
        improveAxesAppearance(ax, 'LineThickness', 2);

        % Create and assign context menu to save the plot as a PNG or JPEG.
        setupContextMenuFor3DPlot(app);
    catch ME
        app.displayError(ME);
    end
end