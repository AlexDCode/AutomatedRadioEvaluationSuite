function spacing_m = checkReferenceSpacing(app, file)
    %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
    % DESCRIPTION:
    % Reads the antenna spacing a reference gain file was measured at (the "Antenna Spacing (m)" line of its
    % ARES file header, see buildMeasurementHeader) and tells the user when it differs from the current setup
    % spacing by more than 1 cm. Files saved before the header existed have no spacing, so nothing is shown.
    %
    % INPUT:
    %   app  - ARES application object (uses setupSpacing and UIFigure).
    %   file - path of the reference gain file.
    %
    % OUTPUT:
    %   spacing_m - spacing recorded in the reference file (m), or NaN if none.
    %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

    spacing_m = NaN;
    try
        meta = readMeasurementHeader(char(file));
    catch
        return;
    end
    if ~isfield(meta, 'AntennaSpacingm') || ~isnumeric(meta.AntennaSpacingm), return; end
    spacing_m = meta.AntennaSpacingm;

    current = app.setupSpacing;
    if isempty(current) || ~isfinite(current) || ~isfinite(spacing_m), return; end
    if abs(current - spacing_m) <= 0.01, return; end

    [~, n, e] = fileparts(char(file));
    uialert(app.UIFigure, sprintf(['%s was measured with the antennas %.3f m apart. The current setup ' ...
        'spacing is %.3f m. Gain uses the current spacing; check the linear slider if the reference ' ...
        'should be measured at the same distance.'], [n e], spacing_m, current), ...
        'Reference Spacing', 'Icon', 'info');
end
