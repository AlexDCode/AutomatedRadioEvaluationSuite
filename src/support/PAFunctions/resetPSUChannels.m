function resetPSUChannels(app)
    %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
    % DESCRIPTION:
    % This function resets all power supply unit (PSU) channels to their default settings, including setting voltage
    % and current values to 0 and configuring each channel to 'Single' mode. It also refreshes the GUI to reflect 
    % these changes and ensures the PA side of the application returns to its initial state.
    %
    % INPUT:
    %   app   - The application object containing the channel configurations.
    %
    % OUTPUT:
    %   None
    %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

    % Loop through all the channels and set the default values.
    channels = fieldnames(app.ChannelNames);
    for i = 1:length(channels)
        app.ChannelNames.(channels{i}) = struct( ...
            'Current', 0, ...
            'Start', 0, ...
            'Stop', 0, ...
            'Step', 0, ...
            'Mode', 'Single' ...
        );
    end

    % To invalidate the channel once its reset.
    populatePSUChannels(app); 

    % Reset all GUI values and elements to default.
    app.SupplyCurrentValueField.Value = 0;
    app.SupplyVoltageStartValueField.Value = 0;
    app.SupplyVoltageStopValueField.Value = 0;
    app.SupplyVoltageStepValueField.Value = 0;
    app.SingleSweepSwitch.Value = 'Single';

    % Hide the voltage stop/step fields.
    app.SupplyVoltageStopValueField.Visible = 'off';
    app.SupplyVoltageStepValueField.Visible = 'off';
end