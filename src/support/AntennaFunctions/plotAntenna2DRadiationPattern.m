function plotAntenna2DRadiationPattern(app)
    %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
    % DESCRIPTION:
    % This function generates and displays several 2D plots related to antenna measurements. It extracts the relevant
    % antenna data based on user-selected θ, φ, gain, and frequency values. It updates four axes in the application UI
    % to display the following plots:
    %
    %   - Gain vs. Frequency at a fixed θ/φ angle.
    %   - Gain vs. Angle (θ and φ cuts) at a fixed frequency.
    %   - Return Loss vs. Frequency at a fixed θ/φ angle.
    %   - Polar Radiation Pattern (θ and φ cuts).
    %
    % The Gain dropdown picks which pattern to show (see antennaPlotSeries): a gain column of a 2-port file, the
    % gain of one AUT <-> reference path of an n-port file, or "All (overlay)" to draw every one together.
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

        series = selectedPlotSeries(app);
        if isempty(series), return; end
        overlay = numel(series) > 1;

        theta = str2double(app.ThetaDropDown.Value);
        phi   = str2double(app.PhiDropDown.Value);
        freq  = str2double(app.FrequencyMHzDropDown.Value);
        name  = series(1).Label;
        ylab  = series(1).YLabel;
        if overlay, name = "Gain"; end

        hold(app.GainvsFrequency2DPattern, 'on');
        hold(app.ReturnLoss2DPattern, 'on');
        hold(app.GainvsAngle2DPattern, 'on');
        hold(app.RadiationPlot2DPattern, 'on');
        cutLines = gobjects(0);  cutNames = strings(0);
        polarLines = gobjects(0);
        for k = 1:numel(series)
            data = series(k).Data;
            tag = "";
            if overlay, tag = series(k).Label + " "; end

            % Specified angle and frequency plotting index.
            idx_theta = data.Thetadeg == theta;
            idx_phi   = data.Phideg == phi;
            idx_freq  = data.FrequencyMHz == freq;
            idx_angle = idx_theta & idx_phi;

            % 1) Gain vs. Frequency, at specified angle
            f = data.FrequencyMHz(idx_angle);
            plot(app.GainvsFrequency2DPattern, f, data.Value(idx_angle), lineSpec_(f), ...
                'DisplayName', series(k).Label);

            % 2) Return Loss vs. Frequency, at specified angle
            plot(app.ReturnLoss2DPattern, f, data.ReturnLossdB(idx_angle), lineSpec_(f), ...
                'DisplayName', series(k).Label);

            % Phi cut: theta varies, phi fixed. Theta cut: phi varies, theta fixed.
            [phiCutAngles, phiCutGain]     = cut_(data.Thetadeg(idx_phi & idx_freq), data.Value(idx_phi & idx_freq));
            [thetaCutAngles, thetaCutGain] = cut_(data.Phideg(idx_theta & idx_freq), data.Value(idx_theta & idx_freq));

            % 3) Gain vs. Angle, at specified frequency
            cutLines(end + 1) = plot(app.GainvsAngle2DPattern, phiCutAngles, phiCutGain, lineSpec_(phiCutAngles)); %#ok<AGROW>
            cutLines(end + 1) = plot(app.GainvsAngle2DPattern, thetaCutAngles, thetaCutGain, lineSpec_(thetaCutAngles)); %#ok<AGROW>
            cutNames(end + (1:2)) = [tag + "\Phi Cut", tag + "\theta Cut"];

            % 4) Polar pattern: close each curve by repeating its first point.
            polarLines(end + 1) = polarplot(app.RadiationPlot2DPattern, ...
                deg2rad(closeLoop_(phiCutAngles)), closeLoop_(phiCutGain)); %#ok<AGROW>
            polarLines(end + 1) = polarplot(app.RadiationPlot2DPattern, ...
                deg2rad(closeLoop_(thetaCutAngles)), closeLoop_(thetaCutGain)); %#ok<AGROW>
        end
        hold(app.GainvsFrequency2DPattern, 'off');
        hold(app.ReturnLoss2DPattern, 'off');
        hold(app.GainvsAngle2DPattern, 'off');
        hold(app.RadiationPlot2DPattern, 'off');

        title(app.GainvsFrequency2DPattern, sprintf('%s vs. Frequency at \\Phi = %s^{\\circ} and \\theta = %s^{\\circ}', ...
            name, app.PhiDropDown.Value, app.ThetaDropDown.Value));
        ylabel(app.GainvsFrequency2DPattern, ylab);
        xlabel(app.GainvsFrequency2DPattern, 'Frequency (MHz)');
        axis(app.GainvsFrequency2DPattern, 'tight');

        title(app.ReturnLoss2DPattern, sprintf('Return Loss at \\Phi = %s^{\\circ} and \\theta = %s^{\\circ}', ...
            app.PhiDropDown.Value, app.ThetaDropDown.Value));
        xlabel(app.ReturnLoss2DPattern, 'Frequency (MHz)');
        ylabel(app.ReturnLoss2DPattern, 'RL (dB)');
        axis(app.ReturnLoss2DPattern, 'tight');
        if overlay
            legend(app.GainvsFrequency2DPattern, 'Location', 'best');
            legend(app.ReturnLoss2DPattern, 'Location', 'best');
        else
            legend(app.GainvsFrequency2DPattern, 'off');
            legend(app.ReturnLoss2DPattern, 'off');
        end

        title(app.GainvsAngle2DPattern, sprintf('%s vs. Angle at %s MHz', name, app.FrequencyMHzDropDown.Value));
        ylabel(app.GainvsAngle2DPattern, ylab);
        xlabel(app.GainvsAngle2DPattern, 'Angle (degrees)');
        lgd = legend(app.GainvsAngle2DPattern, cutLines, cellstr(cutNames), 'Location', 'best');
        enableLegendToggle(lgd);
        axis(app.GainvsAngle2DPattern, 'tight');

        title(app.RadiationPlot2DPattern, sprintf('Radiation Pattern at %s MHz', app.FrequencyMHzDropDown.Value));
        axis(app.RadiationPlot2DPattern, 'tight');
        lgd = legend(app.RadiationPlot2DPattern, polarLines, cellstr(cutNames), 'Location', 'best');
        enableLegendToggle(lgd);

        % Improves the plot appearance, line thickness can be modified.
        improveAxesAppearance(app, app.GainvsFrequency2DPattern, 'LineThickness', 2);
        improveAxesAppearance(app, app.ReturnLoss2DPattern, 'LineThickness', 2);
        improveAxesAppearance(app, app.GainvsAngle2DPattern, 'LineThickness', 2);
        updateColorOrder(app);
        updateColormap(app);

        h = findobj(app.RadiationPlot2DPattern, 'Type', 'line');
        for i = 1:numel(h)
            h(i).LineWidth = 2;
        end

    catch ME
        app.displayError(ME);
    end
end

function [angles, gain] = cut_(angles, gain)
    % Sort a cut by angle (older files were not saved sorted) and, if it has a
    % point at 180 but not -180, repeat it at -180 so the cut spans the circle.
    [angles, order] = sort(angles(:));
    gain = gain(order);
    gain = gain(:);
    if any(angles == 180) && ~any(angles == -180)
        angles = [-180; angles];
        gain = [gain(find(angles(2:end) == 180, 1)); gain];
    end
end

function v = closeLoop_(v)
    % Repeat the first point at the end so a polar curve closes.
    if ~isempty(v), v = [v; v(1)]; end
end

function s = lineSpec_(x)
    % A single sample would be an invisible zero-length line; show a marker.
    if isscalar(x)
        s = 'o';
    else
        s = '-';
    end
end
