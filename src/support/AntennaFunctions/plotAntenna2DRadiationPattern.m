function plotAntenna2DRadiationPattern(app)
    %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
    % DESCRIPTION:
    % This function generates and displays several 2D plots related to antenna measurements. It extracts the relevant
    % antenna data based on user-selected θ, φ, and frequency values. It updates four axes in the application UI to 
    % display the following plots:
    %
    %   - Gain vs. Frequency at a fixed θ/φ angle.
    %   - Gain vs. Angle (θ and φ cuts) at a fixed frequency.
    %   - Return Loss vs. Frequency at a fixed θ/φ angle.
    %   - Polar Radiation Pattern (θ and φ cuts).
    %
    % INPUT:
    %   app  - Application object containing the antenna measurement data and plot handles.
    %
    % OUTPUT:
    %   None
    %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

    try
        % Clear current plots.
        cla(app.GainvsFrequency2DPattern);
        cla(app.ReturnLoss2DPattern);
        cla(app.GainvsAngle2DPattern);
        cla(app.RadiationPlot2DPattern);
    
        % Specified angle and frequency plotting index.
        idx_theta = (app.Antenna_Data.Thetadeg==str2double(app.PlotThetaDropDown.Value));
        idx_phi = (app.Antenna_Data.Phideg==str2double(app.PlotPhiDropDown.Value));
        idx_freq = (app.Antenna_Data.FrequencyMHz==str2double(app.PlotFrequencyMHzDropDown.Value));
        idx_angle = idx_theta & idx_phi; 
     
        % 1) Antenna Gain vs. Frequency, at specified angle
        plot(app.GainvsFrequency2DPattern, app.Antenna_Data(idx_angle,:).FrequencyMHz, app.Antenna_Data(idx_angle,:).GaindBi);
        title(app.GainvsFrequency2DPattern, sprintf('Gain vs. Frequency at \\Phi = %s^{\\circ} and \\theta = %s^{\\circ}', app.PlotPhiDropDown.Value,app.PlotThetaDropDown.Value));
        xlabel(app.GainvsFrequency2DPattern, 'Frequency (MHz)');
        ylabel(app.GainvsFrequency2DPattern, 'Gain (dBi)');
        axis(app.GainvsFrequency2DPattern, 'tight');

        % 2) Return Loss (dB) Plot
        plot(app.ReturnLoss2DPattern, app.Antenna_Data(idx_angle,:).FrequencyMHz, app.Antenna_Data(idx_angle,:).ReturnLossdB);
        title(app.ReturnLoss2DPattern, sprintf('Return Loss at \\Phi = %s^{\\circ} and \\theta = %s^{\\circ}', app.PlotPhiDropDown.Value,app.PlotThetaDropDown.Value));
        xlabel(app.ReturnLoss2DPattern, 'Frequency (MHz)');
        ylabel(app.ReturnLoss2DPattern, 'RL (dB)');
        axis(app.ReturnLoss2DPattern, 'tight');

        % Prepare the polar data correctly.
        % For phi cut: theta varies, phi is fixed
        phiCutAngles = app.Antenna_Data(idx_phi & idx_freq,:).Thetadeg;
        phiCutGain = app.Antenna_Data(idx_phi & idx_freq,:).GaindBi;
        
        % For theta cut: phi varies, theta is fixed
        thetaCutAngles = app.Antenna_Data(idx_theta & idx_freq,:).Phideg;
        thetaCutGain = app.Antenna_Data(idx_theta & idx_freq,:).GaindBi;

        % Extra sorting for old data recorded prior to the new sorted
        % results table changes.
        [phiCutAngles, sortIdx] = sort(phiCutAngles);
        phiCutGain = phiCutGain(sortIdx);
        [thetaCutAngles, sortIdx] = sort(thetaCutAngles);
        thetaCutGain = thetaCutGain(sortIdx);

        % Check if we need to add a point at -180 to match a point at 180
        if any(phiCutAngles == 180) && ~any(phiCutAngles == -180)
            % Find gain at 180 degrees
            idx180 = phiCutAngles == 180;
            gain180 = phiCutGain(idx180);
            
            % Add a point at -180 with the same gain as 180
            phiCutAngles = [-180; phiCutAngles];
            phiCutGain = [gain180; phiCutGain];
        end

        % Do the same check for theta cut
        if any(thetaCutAngles == 180) && ~any(thetaCutAngles == -180)
            idx180 = thetaCutAngles == 180;
            gain180 = thetaCutGain(idx180);
            
            thetaCutAngles = [-180; thetaCutAngles];
            thetaCutGain = [gain180; thetaCutGain];
        end

        % For polar plots, we need to add the first point at the end to close the circle
        phiCutAnglesPolar = phiCutAngles;
        phiCutGainPolar = phiCutGain;
        thetaCutAnglesPolar = thetaCutAngles;
        thetaCutGainPolar = thetaCutGain;
        
        if ~isempty(phiCutAnglesPolar)
            phiCutAnglesPolar = [phiCutAnglesPolar; phiCutAnglesPolar(1)];
            phiCutGainPolar = [phiCutGainPolar; phiCutGainPolar(1)];
        end
        
        if ~isempty(thetaCutAnglesPolar)
            thetaCutAnglesPolar = [thetaCutAnglesPolar; thetaCutAnglesPolar(1)];
            thetaCutGainPolar = [thetaCutGainPolar; thetaCutGainPolar(1)];
        end

        % 3) Antenna Gains vs. Angles, at specified frequency
        h_phi = plot(app.GainvsAngle2DPattern, phiCutAngles, phiCutGain);
        hold(app.GainvsAngle2DPattern,'on');
        h_theta = plot(app.GainvsAngle2DPattern, thetaCutAngles, thetaCutGain);
        hold(app.GainvsAngle2DPattern,'off');
        title(app.GainvsAngle2DPattern, sprintf('Gain vs. Angle at %s MHz', app.PlotFrequencyMHzDropDown.Value));
        xlabel(app.GainvsAngle2DPattern, 'Angle (degrees)');
        ylabel(app.GainvsAngle2DPattern, 'Gain (dBi)');
        lgd = legend(app.GainvsAngle2DPattern, [h_phi,h_theta], {"\Phi Cut", "\theta Cut"}, 'Location', 'best');
        axis(app.GainvsAngle2DPattern, 'tight');
        
        % 4) 2D Radiation Pattern Polar Plot 
        h_phi = polarplot(app.RadiationPlot2DPattern, deg2rad(phiCutAnglesPolar), phiCutGainPolar);
        hold(app.RadiationPlot2DPattern,'on');
        h_theta = polarplot(app.RadiationPlot2DPattern, deg2rad(thetaCutAnglesPolar), thetaCutGainPolar);
        hold(app.RadiationPlot2DPattern,'off');
        title(app.RadiationPlot2DPattern, sprintf('Radiation Pattern at %s MHz', app.PlotFrequencyMHzDropDown.Value));
        axis(app.RadiationPlot2DPattern, 'tight');
        lgd = legend(app.RadiationPlot2DPattern, [h_phi,h_theta], {"\Phi Cut", "\theta Cut"}, 'Location', 'best');
    
        % Improves the plot appearance, line thickness can be modified.
        improveAxesAppearance(app.GainvsFrequency2DPattern, 'LineThickness', 2);
        improveAxesAppearance(app.ReturnLoss2DPattern, 'LineThickness', 2);
        improveAxesAppearance(app.GainvsAngle2DPattern, 'LineThickness', 2);
        h = findobj(app.RadiationPlot2DPattern, 'Type', 'line');
        
        for i = 1:numel(h)
            h(i).LineWidth = 2;
        end

    catch ME
        app.displayError(ME);
    end
end