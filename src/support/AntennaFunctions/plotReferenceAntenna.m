function plotReferenceAntenna(app)
    %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
    % DESCRIPTION:
    % Plots the reference antenna's gain and return loss versus frequency, serving as a baseline for comparison
    % with DUT (Device Under Test) measurements. The function:
    %
    %   - Clears existing plots for gain and return loss.
    %   - Plots gain (dBi) vs frequency (MHz).
    %   - Plots return loss (dB) vs frequency (MHz).
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

    % Plot the parameters onto the plots.
    plot(app.GainvsFrequencyBoresight, app.ReferenceGainFile.FrequencyMHz, app.ReferenceGainFile.GaindBi);
    xlabel(app.GainvsFrequencyBoresight, 'Frequency (MHz)');
    ylabel(app.GainvsFrequencyBoresight, 'Gain (dBi)');
    axis(app.GainvsFrequencyBoresight, 'tight');

    plot(app.ReturnLossBoresight, app.ReferenceGainFile.FrequencyMHz, app.ReferenceGainFile.ReturnLossdB);
    xlabel(app.ReturnLossBoresight, 'Frequency (MHz)');
    ylabel(app.ReturnLossBoresight, 'RL (dB)');
    axis(app.ReturnLossBoresight, 'tight');

    % Improves the plot appeareance, line thickness can be modified.
    improveAxesAppearance(app.GainvsFrequencyBoresight, 'LineThickness', 2);
    improveAxesAppearance(app.ReturnLossBoresight, 'LineThickness', 2);
end