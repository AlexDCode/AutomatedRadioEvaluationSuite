function isValid = validatePSUChannels(app)
    %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
    % DESCRIPTION:
    % This function validates PSU channel configuration based on the selected mode. It checks:
    %
    %   - That devices are connected.
    %   - That the mode matches available devices.
    %   - That enough channels are configured.
    %   - That channel count does not exceed mode limits.
    %
    % INPUT:
    %   app     - App object with mode, device, and channel info
    %
    % OUTPUT:
    %   isValid - True if configuration is valid; otherwise false
    %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

    % Initialize variables.
    isValid = false;
    filledChannels = app.FilledPSUChannels;
    numChannels  = numel(filledChannels);
    currentMode = resolvePSUMode(app.PSUMode);

    %% Validation Checks
    % Check if no power supplies are connected.
    if isempty(app.PowerSupplyA) && isempty(app.PowerSupplyB)
        uialert(app.UIFigure, 'No power supplies connected. Please connect at least one power supply before proceeding.', 'No Devices Connected');
        return;
    end

    % Check if quad supply mode is selected but less than two power supplies are connected.
    if strcmp(currentMode, 'Quad Supply') && (isempty(app.PowerSupplyA) || isempty(app.PowerSupplyB))
        uialert(app.UIFigure, 'Quad Supply mode requires both PSUA and PSUB to be connected.', 'Invalid Configuration');
        return;
    end

    % Check for minimum channel configuration
    requiredChannels = modeChannelRequirement(currentMode);

    if numChannels < requiredChannels
        uialert(app.UIFigure, sprintf('At least %d channel(s) must be configured for %s mode.', requiredChannels, currentMode), 'Insufficient Channels');
        return;
    end

    % Check if too many channels are selected for the chosen mode.
    if numChannels > requiredChannels
        message = sprintf(['%s mode allows a maximum of %d channel(s).\n\n' ...
                           'Currently configured: %s\n\nWhat would you like to do?'], ...
                           currentMode, requiredChannels, strjoin(filledChannels, ', '));

        choice = uiconfirm(app.UIFigure, message, 'Channel Configuration', ...
            'Options', {'Clear All Channels', 'Change Mode', 'Cancel'});

        switch choice
            case 'Clear All Channels'
                resetPSUChannels(app);
            case 'Change Mode'
                validModes = getValidModes(numChannels);
                [idx, tf] = listdlg('PromptString', 'Select new PSU mode:', ...
                                    'ListString', validModes, ...
                                    'SelectionMode', 'single', ...
                                    'ListSize', [200 100]);
                if tf
                    app.PowerSupplyModeDropDown.Value = validModes{idx};
                    app.PSUChangeModeHandle();
                end
            otherwise
                % Cancelled
        end
        return;
    end

    % All validation checks passed.
    isValid = true;
end

%% Modular Helper Functions
function mode = resolvePSUMode(value)
    if isnumeric(value)
        options = {'Single Supply', 'Dual Supply', 'Quad Supply'};
        mode = options{value};
    else
        mode = char(value);
    end
end

function n = modeChannelRequirement(mode)
    switch mode
        case 'Single Supply', n = 1;
        case 'Dual Supply',   n = 2;
        case 'Quad Supply',   n = 4;
        otherwise,            n = 0;
    end
end

function modes = getValidModes(channelCount)
    allModes = {'Single Supply', 'Dual Supply', 'Quad Supply'};
    limits = [1, 2, 4];
    modes = allModes(channelCount <= limits);
end
