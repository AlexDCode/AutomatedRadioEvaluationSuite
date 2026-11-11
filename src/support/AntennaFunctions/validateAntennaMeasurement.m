function isValid = validateAntennaMeasurement(app)
    %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
    % DESCRIPTION:
    % This function performs the following validation checks on the antenna test setup.
    %
    %   - Whether the VNA, EMCenter, and EMSlider are connected.
    %   - Whether the start and end frequencies are specified (end >= start; equal means a single frequency).
    %   - Whether the number of sweep points and smoothing points are valid.
    %   - Whether the antenna's physical size is specified.
    %   - Whether the turntable scan settings (mode, start angle, step angle, end angle) are configured.
    %   - Whether the tower scan settings (mode, start angle, step angle, end angle) are configured.
    % 
    % If any condition is not met, the function displays an appropriate message and prompts the user to correct the configuration.
    %
    % INPUT:
    %   app     - Application object containing the antenna setup configuration.
    %
    % OUTPUT:
    %   isValid - Logical value. `true` if the configuration is valid; otherwise, `false`.
    %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

    % Initialize variables.
    startFrequency = app.VNAStartFrequency.Value;
    endFrequency = app.VNAEndFrequency.Value;
    sweepPoints = app.VNASweepPoints.Value;
    antennaSize = app.AntennaPhysicalSize.Value;
    tableStartAngle = app.TableStartAngle.Value;
    tableStepAngle = app.TableStepAngle.Value;
    tableEndAngle = app.TableEndAngle.Value;
    ThetaSwitch = app.ThetaSingleSweepSwitch.Value;
    towerStartAngle = app.TowerStartAngle.Value;
    towerStepAngle = app.TowerStepAngle.Value;
    towerEndAngle = app.TowerEndAngle.Value;
    PhiSwitch = app.PhiSingleSweepSwitch.Value;

    %% Validation Checks
    % Check if antenna relevant instruments are connected.
    if isempty(app.VNA) && isempty(app.EMCenter) && isempty(app.EMSlider)
        uialert(app.UIFigure, 'No antenna relevant instruments connected. Please connect them before proceeding.', 'No Devices Connected');
        isValid = false;
        return;
    end

    % Check the frequencies, sweep points and smoothing points. Start and end
    % may be equal (single frequency), and a 1-point sweep runs unsmoothed.
    [sweepOk, sweepTitle, sweepMsg] = AntennaMeasurementConfig.checkSweep( ...
        startFrequency, endFrequency, sweepPoints, app.SmoothingPoints.Value);
    if ~sweepOk
        uialert(app.UIFigure, sweepMsg, sweepTitle);
        isValid = false;
        return;
    end
    
    % Check if the antenna physical size is specified.
    if isempty(antennaSize)
        uialert(app.UIFigure, 'Antenna physical size is not set.', 'Invalid Antenna Size');
        isValid = false;
        return;
    end

    % Check if turntable settings are properly configured.
    if isempty(tableStartAngle) 
        uialert(app.UIFigure, 'Turntable start angle cannot be empty.', 'Invalid Table Start Angle');
        isValid = false;
        return;
    elseif isempty(tableStepAngle) && strcmp(ThetaSwitch, 'Sweep')
        uialert(app.UIFigure, 'Turntable step angle cannot be empty when the sweep mode is active.', 'Invalid Turntable Sweep Settings');
        isValid = false;
        return;
    elseif isempty(tableEndAngle) && strcmp(ThetaSwitch, 'Sweep')
        uialert(app.UIFigure, 'Turntable end angle cannot be empty when the sweep mode is active.', 'Invalid Turntable Sweep Settings');
        isValid = false;
        return;
    end

    % Check if tower settings are properly configured.
    if isempty(towerStartAngle) 
        uialert(app.UIFigure, 'Tower start angle cannot be empty.', 'Invalid Tower Start Angle');
        isValid = false;
        return;
    elseif isempty(towerStepAngle) && strcmp(PhiSwitch, 'Sweep')
        uialert(app.UIFigure, 'Tower step angle cannot be empty when the sweep mode is active.', 'Invalid Tower Sweep Settings');
        isValid = false;
        return;
    elseif isempty(towerEndAngle) && strcmp(PhiSwitch, 'Sweep')
        uialert(app.UIFigure, 'Tower end angle cannot be empty when the sweep mode is active.', 'Invalid Tower Sweep Settings');
        isValid = false;
        return;
    end

    % All validation checks passed.
    isValid = true;
end