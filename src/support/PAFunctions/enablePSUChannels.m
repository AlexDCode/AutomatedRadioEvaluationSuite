function enablePSUChannels(app, channels, state)
    %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
    % DESCRIPTION:
    % This function enables or disables the specified channels on two power supply units (PSU A and PSU B) based on
    % the provided state (1 for enabling, 0 for disabling). Channels are grouped by PSU (PSU A or PSU B) and then 
    % enabled or disabled accordingly. The order in which the channels are processed depends on the state: gate biases
    % are controlled before drain supplies when enabling, and drain supplies are turned off before gate biases 
    % when disabling. Examples:
    % 
    %  - enablePSUChannels(app, {'CH1', 'CH2'}, 1); Enable channels CH1 and CH2.
    %  - enablePSUChannels(app, {'CH1'}, 0);        Disable channel CH1.
    % 
    % INPUT:
    %   app:      - The application object containing the power supplies and the channel-to-device mapping.
    %   channels  - A cell array of channel names (e.g., {'CH1', 'CH2'}).
    %   state     - Channel state (1 for enable, 0 for disable).
    %
    % OUTPUT:
    %   None
    %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
    
    if state == 1
        % Turn on all gate biases first, then all drain supplies
        channelModes = [app.GateChannels,app.DrainChannels];
    else
        % Turn off all drain supplies first, then all gate biases
        channelModes = [app.DrainChannels,app.GateChannels];
    end

    % Initialize containers for PSU channels.
    psuAChannels = {};
    psuBChannels = {};

    for channelMode = channelModes
        for i = 1:length(channels)
            if ismember(channels{i},channelMode)
                % Extract the channel information.
                [deviceChannel, psuName] = strtok(app.ChannelToDeviceMap(channels{i}), ',');
                psuName = psuName(2:end);
        
                % Map channel name to channel index (CH1 -> @1).
                switch deviceChannel
                    case 'CH1'
                        channelIndex = '@1';
                    case 'CH2'
                        channelIndex = '@2';
                end
                
                if strcmp(psuName, 'PSUA')
                    psuAChannels{end + 1} = channelIndex;
                else
                    psuBChannels{end + 1} = channelIndex;
                end
            end
        
            % Enable channels on PSU A
            if ~isempty(psuAChannels)
                if isscalar(psuAChannels)
                    % Single channel needs to be enabled.
                    channelList = psuAChannels{1};
                else
                    % Both channels need to be enabled.
                    channelList = '@1,2'; 
                end
                writeline(app.PowerSupplyA, sprintf(':OUTPut:STATe %d,(%s)', state, channelList));
            end
        
            % Enable channels on PSU B
            if ~isempty(psuBChannels)
                if isscalar(psuBChannels)
                    % Single channel needs to be enabled.
                    channelList = psuBChannels{1}; 
                else
                    % Both channels need to be enabled.
                    channelList = '@1,2';
                end
                writeline(app.PowerSupplyB, sprintf(':OUTPut:STATe %d,(%s)', state, channelList));
            end
        end
    end
end