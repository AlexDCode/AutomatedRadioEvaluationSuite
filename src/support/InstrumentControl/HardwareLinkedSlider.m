classdef HardwareLinkedSlider < matlab.ui.control.Slider
    %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
    % HardwareLinkedSlider
    %
    % DESCRIPTION:
    % UI slider subclass directly linked to a hardware linear slider
    % (EmCenterSlider). Dragging the GUI control commands the physical
    % hardware to the same position, keeping the "UI -> hardware" binding in
    % one reusable class instead of per-callback glue in the App.
    %
    % Hardened from the prototype (which was marked WIP):
    %   - A hardware failure during the move (fault, timeout, out-of-range)
    %     no longer kills the App: the error is caught, the control reverts
    %     to its previous value, and the failure is reported via uialert.
    %   - The control is disabled while a blocking move is in flight so the
    %     user cannot queue conflicting motion commands.
    %
    % USAGE (App startup):
    %   app.SliderHW = EmCenterSlider("192.168.0.100", 1206, 1);
    %   [ll, ul] = app.SliderHW.getLimits();
    %   app.DistanceSlider = HardwareLinkedSlider( ...
    %       'Parent', app.UIFigure, ...
    %       'Limits', [ll, ul], ...
    %       'Value',  app.SliderHW.getPosition());
    %   app.DistanceSlider.Hardware = app.SliderHW;
    %
    % Units are device centimeters by default (set Limits/Value accordingly).
    %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

    properties
        % Handle to an EmCenterSlider (or any object exposing moveTo(value)).
        % If empty, moving the GUI slider does nothing.
        Hardware
    end

    methods
        function obj = HardwareLinkedSlider(varargin)
            % HARDWARELINKEDSLIDER  Construct the control. All Name/Value
            % arguments are forwarded to matlab.ui.control.Slider.
            obj@matlab.ui.control.Slider(varargin{:});
            obj.ValueChangedFcn = @(src, evt) obj.onValueChanged(evt);
        end

        function onValueChanged(obj, evt)
            % ONVALUECHANGED  Drive the hardware to the new slider value.
            % On failure: revert the control, re-enable it, and surface the
            % error to the user without crashing the App.
            if isempty(obj.Hardware)
                return;
            end

            obj.Enable = "off";   % no queued moves while one is in flight
            try
                obj.Hardware.moveTo(evt.Value);
            catch ME
                obj.Value = evt.PreviousValue;   % reflect reality
                obj.Enable = "on";
                fig = ancestor(obj, "figure");
                if ~isempty(fig)
                    uialert(fig, ME.message, "Slider Move Failed");
                end
                return;
            end
            obj.Enable = "on";
        end
    end
end
