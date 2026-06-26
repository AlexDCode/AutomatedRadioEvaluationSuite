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
    % Extended from the prototype with serialization — the paper's
    % reproducibility goal ("settings can be saved alongside
    % measurement data and later reloaded to repeat or modify experiments"):
    %
    %   cfg.saveToJSON("run42_config.json")        % alongside the results
    %   cfg = AntennaMeasurementConfig.loadFromJSON("run42_config.json")
    %
    % UNITS / CONVENTIONS:
    %   - Frequencies in consistent units across start/end (ARES uses MHz)
    %   - Angles in degrees; Theta = turntable, Phi = tower
    %   - Modes are "Sweep" or "Single"
    %
    % TYPICAL USAGE (App callback):
    %   cfg = AntennaMeasurementConfig.fromApp(app);
    %   if ~cfg.validate(app.UIFigure), return; end
    %   runAntennaMeasurementOO(app, cfg, ...);
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

        % Tower (phi) scan settings (deg)
        TowerStartAngle (1,1) double = NaN
        TowerStepAngle  (1,1) double = NaN
        TowerEndAngle   (1,1) double = NaN
        TowerSpeed      (1,1) double = NaN       % tower speed preset
        PhiMode         (1,1) string = "Sweep"   % "Sweep" | "Single"
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

            AntennaMeasurementConfig.setIfFinite_(app.TowerStartAngle,    obj.TowerStartAngle);
            AntennaMeasurementConfig.setIfFinite_(app.TowerStepAngle,     obj.TowerStepAngle);
            AntennaMeasurementConfig.setIfFinite_(app.TowerEndAngle,      obj.TowerEndAngle);
            AntennaMeasurementConfig.setIfFinite_(app.TowerSpeedSlider,   obj.TowerSpeed);
            app.PhiSingleSweepSwitch.Value   = char(obj.PhiMode);
        end

        %% Serialization (reproducibility)
        function s = toStruct(obj)
            % TOSTRUCT  Plain struct of all settings (for saving/logging).
            props = properties(obj);
            s = struct();
            for k = 1:numel(props)
                v = obj.(props{k});
                if isstring(v), v = char(v); end   % friendlier JSON
                s.(props{k}) = v;
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

            obj.TowerStartAngle = n(app.TowerStartAngle.Value);
            obj.TowerStepAngle  = n(app.TowerStepAngle.Value);
            obj.TowerEndAngle   = n(app.TowerEndAngle.Value);
            obj.TowerSpeed      = n(app.TowerSpeedSlider.Value);
            obj.PhiMode         = string(app.PhiSingleSweepSwitch.Value);
        end

        function obj = fromStruct(s)
            % FROMSTRUCT  Rebuild a config from a struct (see toStruct).
            obj = AntennaMeasurementConfig();
            props = properties(obj);
            for k = 1:numel(props)
                if isfield(s, props{k})
                    v = s.(props{k});
                    % jsonencode writes NaN as null, which decodes to [];
                    % map it back so scalar properties stay assignable.
                    if isempty(v), v = NaN; end
                    if ischar(v), v = string(v); end
                    obj.(props{k}) = v;
                end
            end
        end

        function obj = loadFromJSON(path)
            % LOADFROMJSON  Rebuild a config from a saved JSON file.
            obj = AntennaMeasurementConfig.fromStruct(jsondecode(fileread(path)));
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

            % Frequency sweep
            if ~isfinite(obj.StartFrequency) || ~isfinite(obj.EndFrequency)
                isValid = false;
                title = "Invalid Frequency Settings";
                msg = "Start and end frequencies must be set (finite numbers).";
                return;
            end
            if obj.StartFrequency == obj.EndFrequency
                isValid = false;
                title = "Invalid Frequency Settings";
                msg = "Start and end frequencies must be different.";
                return;
            end
            if obj.EndFrequency < obj.StartFrequency
                isValid = false;
                title = "Invalid Frequency Settings";
                msg = "End frequency must be greater than start frequency.";
                return;
            end

            % Sweep / smoothing points
            if ~isfinite(obj.SweepPoints) || obj.SweepPoints < 2 ...
                    || floor(obj.SweepPoints) ~= obj.SweepPoints
                isValid = false;
                title = "Invalid Sweep Points";
                msg = "Number of sweep points must be an integer >= 2.";
                return;
            end
            if ~isfinite(obj.SmoothingPoints) || obj.SmoothingPoints < 0 ...
                    || floor(obj.SmoothingPoints) ~= obj.SmoothingPoints
                isValid = false;
                title = "Invalid Smoothing Points";
                msg = "Smoothing points must be an integer >= 0.";
                return;
            end
            if obj.SmoothingPoints / obj.SweepPoints > 0.25
                isValid = false;
                title = "Invalid Smoothing Points";
                msg = "Smoothing points must be <= 25% of sweep points.";
                return;
            end

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

            isValid = true;
            title = "";
            msg = "";
        end
    end
end
