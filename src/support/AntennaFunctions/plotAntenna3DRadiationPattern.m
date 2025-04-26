function plotAntenna3DRadiationPattern(app)
    %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
    % This function plots the 3D antenna radiation pattern for a given 
    % frequency:
    %   - 3D Radiation Pattern based on theta, phi, and magnitude values.
    %   - The plot uses the Antenna Toolbox's internal spherical renderer 
    %     for polar axes.
    %
    % INPUT PARAMETERS:
    %   app: Application object containing antenna data and plot handles.
    %
    % This function:
    %   - Extracts gain data based on the selected frequency
    %   - Ensures the angle data is consistent
    %   - Creates a 3D radiation pattern plot
    %   - Enhances axes visuals using helper formatting functions
    %   - Catches and displays errors using the app's error handler
    %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

    try
        % Clear current plot, and its associated colorbar.
        cla(app.RadiationPlot3DPattern);
        ax = app.RadiationPlot3DPattern;
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

        if any(isnan(gainMatrix(:)))
            uialert(app.UIFigure, 'Matrix has NaN values.', 'Data Error', 'Icon', 'error');
        end
        
        % 1) 3D Radiation Pattern Plot
        % Using the internal spherical renderer for true polar axes from 
        % Antenna Toolbox.
        pause(0.1); % Settling time for ax.
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