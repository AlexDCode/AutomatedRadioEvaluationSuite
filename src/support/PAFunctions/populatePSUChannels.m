function populatePSUChannels(app)
    %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
    % DESCRIPTION:
    % This function evaluates the configuration of power supply channels and identifies which channels are "filled,"
    % meaning they have complete user-defined parameters (voltage, current, etc.) and are ready for use. These filled
    % channels are stored in the app object for future processing or interaction with the PSU units.
    %
    % INPUT:
    %   app   - The application object containing the channel configurations and channel-to-device mapping.
    %
    % OUTPUT:
    %   None
    %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
    
    filledChannels = {};
    channelNames = fieldnames(app.ChannelNames); 

    for channelName = channelNames'
        channel = app.ChannelNames.(channelName{1});
        
        % Check if the channel is "filled" based on its mode and user input.
        if strcmp(channel.Mode, 'Single') && all([channel.Current, channel.Start] ~= 0)
            % "Single" mode channels require non-zero current and start voltage.
            filledChannels{end + 1} = channelName{1}; %#ok<AGROW>

        elseif strcmp(channel.Mode, 'Sweep') && all([channel.Current, channel.Start, channel.Stop, channel.Step] ~= 0)
            % "Sweep" mode channels require non-zero current, start, stop, and step values.
            filledChannels{end + 1} = channelName{1}; %#ok<AGROW>
            
        end
    end

    % Store the list of filled channels in the app object.
    app.FilledPSUChannels = filledChannels;
end