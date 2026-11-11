function plotReferenceAntenna(app)
    %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
    % DESCRIPTION:
    % Plots the reference antennas' gain and return loss versus frequency, serving as a baseline for comparison
    % with DUT (Device Under Test) measurements. The references are the Browse Reference file and every
    % reference port's own gain file from the VNA tab's port map (see referenceAntennaCurves). The
    % ReferenceViewDropDown picks one of them or "All (overlay)". The function:
    %
    %   - Clears existing plots for gain and return loss.
    %   - Refreshes the dropdown with the references currently loaded.
    %   - Plots gain (dBi) and return loss (dB) vs frequency (MHz) for the selected reference(s).
    %   - Enhances visual appearance of plots using standardized formatting.
    %
    % INPUT:
    %   app - Application object containing the reference antenna measurement data and associated plot handles.
    %
    % OUTPUT:
    %   None
    %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

    % Clear current plots.
    cla(app.GainvsFrequencyBoresight);
    cla(app.ReturnLossBoresight);
    legend(app.GainvsFrequencyBoresight, 'off');
    legend(app.ReturnLossBoresight, 'off');

    refs = referenceAntennaCurves(app);
    show = refs;

    % Keep the reference picker in step with what is loaded.
    if isprop(app, 'ReferenceViewDropDown')
        if isempty(refs)
            items = "No reference loaded";
        elseif isscalar(refs)
            items = refs.Label;
        else
            items = ["All (overlay)", refs.Label];
        end
        current = string(app.ReferenceViewDropDown.Value);
        app.ReferenceViewDropDown.Items = cellstr(items);
        if ~any(items == current), current = items(1); end
        app.ReferenceViewDropDown.Value = char(current);
        if ~isempty(refs) && current ~= "All (overlay)"
            show = refs([refs.Label] == current);
        end
    end
    if isempty(show), return; end

    % Plot the parameters onto the plots.
    hold(app.GainvsFrequencyBoresight, 'on');
    hold(app.ReturnLossBoresight, 'on');
    for k = 1:numel(show)
        plot(app.GainvsFrequencyBoresight, show(k).FrequencyMHz, show(k).GaindBi, 'DisplayName', show(k).Label);
        plot(app.ReturnLossBoresight, show(k).FrequencyMHz, show(k).ReturnLossdB, 'DisplayName', show(k).Label);
    end
    hold(app.GainvsFrequencyBoresight, 'off');
    hold(app.ReturnLossBoresight, 'off');
    if numel(show) > 1
        legend(app.GainvsFrequencyBoresight, 'Location', 'best', 'Interpreter', 'none');
        legend(app.ReturnLossBoresight, 'Location', 'best', 'Interpreter', 'none');
    end

    xlabel(app.GainvsFrequencyBoresight, 'Frequency (MHz)');
    ylabel(app.GainvsFrequencyBoresight, 'Gain (dBi)');
    axis(app.GainvsFrequencyBoresight, 'tight');

    xlabel(app.ReturnLossBoresight, 'Frequency (MHz)');
    ylabel(app.ReturnLossBoresight, 'RL (dB)');
    axis(app.ReturnLossBoresight, 'tight');

    % Improves the plot appeareance, line thickness can be modified.
    improveAxesAppearance(app, app.GainvsFrequencyBoresight, 'LineThickness', 2);
    improveAxesAppearance(app, app.ReturnLossBoresight, 'LineThickness', 2);
    updateColorOrder(app);
    updateColormap(app);
end
