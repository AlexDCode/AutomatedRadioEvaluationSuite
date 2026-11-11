classdef AntennaMeasurementConfig < handle
    %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
    % AntennaMeasurementConfig
    %
    % DESCRIPTION:
    % Snapshot + validation object for antenna measurement settings.
    % Captures the dozens of individual ARES UI inputs as one plain data
    % object so measurement code consumes a config instead of UI handles,
    % and validation rules live (and are testable) in one place.
    %
    % A config serializes to JSON, so settings can be saved alongside the
    % measurement data and reloaded later to repeat or modify an experiment.
    %
    % CONVENTIONS:
    %   - Frequencies in consistent units across start/end (ARES uses MHz)
    %   - Angles in degrees; Theta = turntable, Phi = tower
    %   - Modes are "Sweep" or "Single"
    %
    % USAGE:
    % From an app callback:
    %
    %   cfg = AntennaMeasurementConfig.fromApp(app);
    %   if ~cfg.validate(app.UIFigure), return; end
    %   runAntennaMeasurementOO(app, cfg, ...);
    %
    %   cfg.saveToJSON("run42_config.json");       % alongside the results
    %   cfg = AntennaMeasurementConfig.loadFromJSON("run42_config.json");
    %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

    properties
        % Frequency sweep
        StartFrequency  (1,1) double = NaN
        EndFrequency    (1,1) double = NaN
        SweepPoints     (1,1) double = NaN
        SmoothingPoints (1,1) double = NaN

        % Antenna geometry
        AntennaSize     (1,1) double = NaN

        % Turntable (theta) scan settings (deg)
        TableStartAngle (1,1) double = NaN
        TableStepAngle  (1,1) double = NaN
        TableEndAngle   (1,1) double = NaN
        TableSpeed      (1,1) double = NaN       % turntable speed preset
        ThetaMode       (1,1) string = "Sweep"   % "Sweep" | "Single"
        % Range the turntable controller counts in (see AntennaPositioner).
        ThetaRange      (1,1) string {mustBeMember(ThetaRange, ["-180to180", "0to360"])} = "-180to180"

        % Tower (phi) scan settings (deg)
        TowerStartAngle (1,1) double = NaN
        TowerStepAngle  (1,1) double = NaN
        TowerEndAngle   (1,1) double = NaN
        TowerSpeed      (1,1) double = NaN       % tower speed preset
        PhiMode         (1,1) string = "Sweep"   % "Sweep" | "Single"

        % Port / role assignment for n-port (4-port) measurements. Empty on a
        % config that predates the port map; fromApp() falls back to
        % PortMap.legacyTwoPort() so the historical 2-port behavior is kept.
        PortMapping     PortMap
    end

    methods
        %% Validation
        function isValid = validate(obj, uiFig)
            % VALIDATE  Check the configuration.
            %
            % If uiFig (an App Designer UIFigure) is provided, failures are
            % shown in a uialert; otherwise the method just returns false.
            if nargin < 2, uiFig = []; end

            [isValid, title, msg] = obj.validateCore_();
            if ~isValid && ~isempty(uiFig)
                uialert(uiFig, msg, title);
            end
        end

        %% Derived values
        function angles = tableAngles(obj)
            % TABLEANGLES  Theta scan vector implied by the settings.
            if obj.ThetaMode == "Sweep"
                angles = obj.TableStartAngle : obj.TableStepAngle : obj.TableEndAngle;
            else
                angles = obj.TableStartAngle;
            end
        end

        function angles = towerAngles(obj)
            % TOWERANGLES  Phi scan vector implied by the settings.
            if obj.PhiMode == "Sweep"
                angles = obj.TowerStartAngle : obj.TowerStepAngle : obj.TowerEndAngle;
            else
                angles = obj.TowerStartAngle;
            end
        end

        %% Push settings back into the ARES UI (inverse of fromApp)
        function applyToApp(obj, app)
            % APPLYTOAPP  Write this configuration's values into the ARES
            % antenna UI fields. Exact inverse of the static fromApp().
            %
            % Numeric fields are written only when the stored value is finite,
            % so an unset/NaN parameter (e.g. step/end angle in Single mode)
            % does not clobber whatever is already in the field. The two mode
            % switches are always written.
            %
            % NOTE: setting a switch's Value programmatically does NOT fire its
            % ValueChangedFcn, so any show/hide behavior tied to Sweep/Single
            % won't auto-update on load — the values are correct regardless,
            % and toggling the switch once refreshes the layout.
            AntennaMeasurementConfig.setIfFinite_(app.VNAStartFrequency,  obj.StartFrequency);
            AntennaMeasurementConfig.setIfFinite_(app.VNAEndFrequency,    obj.EndFrequency);
            AntennaMeasurementConfig.setIfFinite_(app.VNASweepPoints,     obj.SweepPoints);
            AntennaMeasurementConfig.setIfFinite_(app.SmoothingPoints,    obj.SmoothingPoints);
            AntennaMeasurementConfig.setIfFinite_(app.AntennaPhysicalSize,obj.AntennaSize);

            AntennaMeasurementConfig.setIfFinite_(app.TableStartAngle,    obj.TableStartAngle);
            AntennaMeasurementConfig.setIfFinite_(app.TableStepAngle,     obj.TableStepAngle);
            AntennaMeasurementConfig.setIfFinite_(app.TableEndAngle,      obj.TableEndAngle);
            AntennaMeasurementConfig.setIfFinite_(app.TableSpeedSlider,   obj.TableSpeed);
            app.ThetaSingleSweepSwitch.Value = char(obj.ThetaMode);
            if isprop(app, "ThetaRangeDropDown")
                app.ThetaRangeDropDown.Value = char(replace(obj.ThetaRange, "to", " to "));
            end

            AntennaMeasurementConfig.setIfFinite_(app.TowerStartAngle,    obj.TowerStartAngle);
            AntennaMeasurementConfig.setIfFinite_(app.TowerStepAngle,     obj.TowerStepAngle);
            AntennaMeasurementConfig.setIfFinite_(app.TowerEndAngle,      obj.TowerEndAngle);
            AntennaMeasurementConfig.setIfFinite_(app.TowerSpeedSlider,   obj.TowerSpeed);
            app.PhiSingleSweepSwitch.Value   = char(obj.PhiMode);

            % Restore the port / role table if both the map and the UI exist.
            if ~isempty(obj.PortMapping) && isprop(app, "PortMapTable")
                setPortMapTable(app, obj.PortMapping);
            end
        end

        %% Serialization (reproducibility)
        function s = toStruct(obj)
            % TOSTRUCT  Plain struct of all settings (for saving/logging).
            % The PortMapping object is handled separately (below) so it is
            % serialized through PortMap.toStruct rather than as a raw handle.
            props = properties(obj);
            s = struct();
            for k = 1:numel(props)
                if strcmp(props{k}, "PortMapping"), continue; end
                v = obj.(props{k});
                if isstring(v), v = char(v); end   % friendlier JSON
                s.(props{k}) = v;
            end
            if ~isempty(obj.PortMapping)
                s.PortMap = obj.PortMapping.toStruct();
            end
        end

        function saveToJSON(obj, path)
            % SAVETOJSON  Write the configuration to a JSON file so it can
            % be stored alongside measurement data and replayed later.
            txt = jsonencode(obj.toStruct(), "PrettyPrint", true);
            fid = fopen(path, "w");
            if fid == -1
                error("AntennaMeasurementConfig:FileError", ...
                    "Could not open %s for writing.", path);
            end
            cleaner = onCleanup(@() fclose(fid));
            fwrite(fid, txt, "char");
        end
    end

    methods (Static)
        function obj = fromApp(app)
            % FROMAPP  Snapshot the current ARES UI state into a config.
            % One-time snapshot: later UI changes do not affect this object.
            %
            % Numeric fields are read through numOrNaN_ so a BLANK field
            % (an empty numeric edit field returns [], not a number) becomes
            % NaN instead of throwing when assigned to a (1,1) double — e.g.
            % the step/end angle boxes are blank in Single mode.
            n = @AntennaMeasurementConfig.numOrNaN_;
            obj = AntennaMeasurementConfig();

            obj.StartFrequency  = n(app.VNAStartFrequency.Value);
            obj.EndFrequency    = n(app.VNAEndFrequency.Value);
            obj.SweepPoints     = n(app.VNASweepPoints.Value);
            obj.SmoothingPoints = n(app.SmoothingPoints.Value);

            obj.AntennaSize     = n(app.AntennaPhysicalSize.Value);

            obj.TableStartAngle = n(app.TableStartAngle.Value);
            obj.TableStepAngle  = n(app.TableStepAngle.Value);
            obj.TableEndAngle   = n(app.TableEndAngle.Value);
            obj.TableSpeed      = n(app.TableSpeedSlider.Value);
            obj.ThetaMode       = string(app.ThetaSingleSweepSwitch.Value);
            obj.ThetaRange      = AntennaMeasurementConfig.thetaRangeFromApp(app);

            obj.TowerStartAngle = n(app.TowerStartAngle.Value);
            obj.TowerStepAngle  = n(app.TowerStepAngle.Value);
            obj.TowerEndAngle   = n(app.TowerEndAngle.Value);
            obj.TowerSpeed      = n(app.TowerSpeedSlider.Value);
            obj.PhiMode         = string(app.PhiSingleSweepSwitch.Value);

            % Port map. Read the VNA-tab port table if that (advanced) UI
            % exists and is populated; otherwise fall back to the legacy 2-port
            % map so the app keeps working with the "More" panel collapsed.
            if isprop(app, "PortMapTable") && ~isempty(app.PortMapTable.Data)
                obj.PortMapping = portMapFromTable(app);
                AntennaMeasurementConfig.attachReferenceGain_(app, obj.PortMapping);
            else
                obj.PortMapping = PortMap.legacyTwoPort();
            end
        end

        function attachReferenceGain_(app, pm)
            % Merge the app's uploaded reference gain (a file + column stored
            % outside the port table) onto the map's reference port(s). Source,
            % in priority order:
            %   1. a dedicated NPortReferenceGainFile field, if the UI has one;
            %   2. otherwise ARES's existing reference upload -
            %      app.ReferenceGainFilePath (the "Load Reference Gain File"
            %      button), with the standard "Gain (dBi)" column.
            % Each reference port can carry its own gain file from the port
            % table; this upload is only the FALLBACK for reference ports left
            % blank there. No-op if nothing is uploaded.
            if isempty(pm) || isempty(pm.referencePorts()), return; end

            file = "";
            col  = "Gain (dBi)";
            if isprop(app, "NPortReferenceGainFile")
                file = string(app.NPortReferenceGainFile.Value);
                if isprop(app, "NPortReferenceGainColumn")
                    col = string(app.NPortReferenceGainColumn.Value);
                end
            elseif isprop(app, "ReferenceGainFilePath") && ~isempty(app.ReferenceGainFilePath)
                file = string(app.ReferenceGainFilePath);
            end
            if isempty(file) || strlength(file) == 0, return; end

            for rp = pm.referencePorts()
                [existingFile, ~] = pm.gainSourceAtPort(rp);
                if strlength(existingFile) > 0, continue; end   % table already set it
                pm.setPort(rp, pm.directionAtPort(rp), "Reference", file, col);
            end
        end

        function obj = fromStruct(s)
            % FROMSTRUCT  Rebuild a config from a struct (see toStruct).
            obj = AntennaMeasurementConfig();
            props = properties(obj);
            for k = 1:numel(props)
                if strcmp(props{k}, "PortMapping"), continue; end
                if isfield(s, props{k})
                    v = s.(props{k});
                    % jsonencode writes NaN as null, which decodes to [];
                    % map it back so scalar properties stay assignable.
                    if isempty(v), v = NaN; end
                    if ischar(v), v = string(v); end
                    obj.(props{k}) = v;
                end
            end
            if isfield(s, "PortMap") && ~isempty(s.PortMap)
                obj.PortMapping = PortMap.fromStruct(s.PortMap);
            end
        end

        function obj = loadFromJSON(path)
            % LOADFROMJSON  Rebuild a config from a saved JSON file.
            obj = AntennaMeasurementConfig.fromStruct(jsondecode(fileread(path)));
        end

        function [isValid, title, msg] = checkSweep(startFreq, endFreq, sweepPoints, smoothingPoints)
            % CHECKSWEEP  Frequency / sweep-point / smoothing rules, shared by
            % the config and the app's validateAntennaMeasurement.
            %
            %   - Start and end must be set, with end >= start. Equal start and
            %     end is a zero-span (single frequency) measurement.
            %   - Sweep points must be an integer >= 1.
            %   - Smoothing of 0 or 1 means OFF (the app spinner's minimum is
            %     1). Smoothing above 1 must be <= 25% of the sweep points, and
            %     is not allowed with a single sweep point.
            n = @AntennaMeasurementConfig.numOrNaN_;
            startFreq = n(startFreq);  endFreq = n(endFreq);
            sweepPoints = n(sweepPoints);  smoothingPoints = n(smoothingPoints);

            isValid = false;
            title = "Invalid Frequency Settings";
            if ~isfinite(startFreq) || ~isfinite(endFreq)
                msg = "Start and end frequencies must be set (finite numbers).";
                return;
            end
            if endFreq < startFreq
                msg = "End frequency must be greater than or equal to start frequency.";
                return;
            end

            title = "Invalid Sweep Points";
            if ~isfinite(sweepPoints) || sweepPoints < 1 || floor(sweepPoints) ~= sweepPoints
                msg = "Number of sweep points must be an integer >= 1.";
                return;
            end

            title = "Invalid Smoothing Points";
            if ~isfinite(smoothingPoints) || smoothingPoints < 0 ...
                    || floor(smoothingPoints) ~= smoothingPoints
                msg = "Smoothing points must be an integer >= 0.";
                return;
            end
            if AntennaMeasurementConfig.smoothingOn(smoothingPoints, sweepPoints) ...
                    && smoothingPoints / sweepPoints > 0.25
                msg = "Smoothing points must be <= 25% of sweep points (use 1 for no smoothing).";
                return;
            end

            isValid = true;  title = "";  msg = "";
        end

        function r = thetaRangeFromApp(app)
            % THETARANGEFROMAPP  The turntable range picked on the Table tab,
            % or the "-180to180" default if the app has no range dropdown.
            % The dropdown shows "-180 to 180" / "0 to 360"; drop the spaces.
            r = "-180to180";
            hasDropDown = isprop(app, "ThetaRangeDropDown") || ...
                (isstruct(app) && isfield(app, "ThetaRangeDropDown"));
            if hasDropDown && ~isempty(app.ThetaRangeDropDown.Value)
                r = erase(string(app.ThetaRangeDropDown.Value), " ");
            end
        end

        function tf = smoothingOn(smoothingPoints, sweepPoints)
            % SMOOTHINGON  True when VNA smoothing should actually be applied:
            % more than 1 smoothing point and more than 1 sweep point. A
            % single-point sweep always runs unsmoothed.
            tf = ~isempty(smoothingPoints) && smoothingPoints > 1 ...
              && ~isempty(sweepPoints) && sweepPoints > 1;
        end
    end

    methods (Static, Access = private)
        function setIfFinite_(field, value)
            % Write value into a UI numeric field, but only if it is finite,
            % so an unset/NaN parameter doesn't overwrite the current field.
            if isfinite(value)
                field.Value = value;
            end
        end

        function v = numOrNaN_(x)
            % Normalize a UI field value to a scalar double. A blank numeric
            % field returns [] (and a blank text field returns ''); both
            % become NaN so they can be stored in a (1,1) double property and
            % serialized without error.
            if isempty(x)
                v = NaN;
            elseif ischar(x) || isstring(x)
                v = str2double(x);
            else
                v = double(x);
            end
        end
    end

    methods (Access = private)
        function [isValid, title, msg] = validateCore_(obj)
            % Pure validation logic — no UI dependency, unit-testable.

            % Frequency sweep / smoothing (shared with validateAntennaMeasurement)
            [isValid, title, msg] = AntennaMeasurementConfig.checkSweep( ...
                obj.StartFrequency, obj.EndFrequency, obj.SweepPoints, obj.SmoothingPoints);
            if ~isValid, return; end

            % Antenna geometry
            if ~isfinite(obj.AntennaSize) || obj.AntennaSize <= 0
                isValid = false;
                title = "Invalid Antenna Size";
                msg = "Antenna physical size must be set to a positive value.";
                return;
            end

            % Theta (turntable)
            if ~isfinite(obj.TableStartAngle)
                isValid = false;
                title = "Invalid Table Start Angle";
                msg = "Turntable start angle must be set.";
                return;
            end
            if obj.ThetaMode == "Sweep"
                if ~isfinite(obj.TableStepAngle) || obj.TableStepAngle == 0
                    isValid = false;
                    title = "Invalid Turntable Sweep Settings";
                    msg = "Turntable step angle must be set and non-zero in Sweep mode.";
                    return;
                end
                if ~isfinite(obj.TableEndAngle)
                    isValid = false;
                    title = "Invalid Turntable Sweep Settings";
                    msg = "Turntable end angle must be set in Sweep mode.";
                    return;
                end
            end

            % Phi (tower)
            if ~isfinite(obj.TowerStartAngle)
                isValid = false;
                title = "Invalid Tower Start Angle";
                msg = "Tower start angle must be set.";
                return;
            end
            if obj.PhiMode == "Sweep"
                if ~isfinite(obj.TowerStepAngle) || obj.TowerStepAngle == 0
                    isValid = false;
                    title = "Invalid Tower Sweep Settings";
                    msg = "Tower step angle must be set and non-zero in Sweep mode.";
                    return;
                end
                if ~isfinite(obj.TowerEndAngle)
                    isValid = false;
                    title = "Invalid Tower Sweep Settings";
                    msg = "Tower end angle must be set in Sweep mode.";
                    return;
                end
            end

            % Port / role map (only when one has been assigned).
            if ~isempty(obj.PortMapping)
                [pmOk, pmTitle, pmMsg] = obj.PortMapping.check();
                if ~pmOk
                    isValid = false;
                    title = pmTitle;
                    msg = pmMsg;
                    return;
                end
            end

            isValid = true;
            title = "";
            msg = "";
        end
    end
end
