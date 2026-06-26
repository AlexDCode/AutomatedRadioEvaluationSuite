function setLinearSlider(speedPreset, targetPosition)
    %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
    % DESCRIPTION:
    % Moves the EMCenter linear slider to a target position at the requested speed preset.
    % The function opens its own TCP connection, validates all inputs against the device's
    % mechanical limits, commands the move, and polls until motion is complete or a timeout
    % is reached. The TCP connection is always closed on exit, even if an error occurs.
    %
    % INPUT:
    %   speedPreset    - Integer between 1 (slowest) and 8 (fastest).
    %   targetPosition - Target position in cm. Must be within the device's mechanical limits.
    %
    % OUTPUT:
    %   None
    %
    % ERRORS:
    %   Throws an error (does NOT silently ignore) if:
    %     - speedPreset is outside [1, 8]
    %     - targetPosition is outside the mechanical limits
    %     - Motion does not complete within TIMEOUT_S seconds
    %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

    SLIDER_IP  = '192.168.0.100';
    SLIDER_PORT = 1206;
    TIMEOUT_S  = 120;   % seconds — homing across a 200 cm rail at speed 1 takes ~90 s
    POLL_DELAY = 0.25;  % seconds between DIR? polls; keeps traffic low without adding latency
    POS_TOL    = 0.1;   % cm — treat positions within this tolerance as "already at target"

    % Validate speed preset before opening the connection.
    if ~isnumeric(speedPreset) || ~isscalar(speedPreset) || ...
       speedPreset < 1 || speedPreset > 8 || floor(speedPreset) ~= speedPreset
        error('setLinearSlider:invalidSpeed', ...
              'speedPreset must be an integer between 1 and 8 (got %g).', speedPreset);
    end

    % Open connection. onCleanup guarantees delete() runs on any exit path —
    % normal return, early return, or uncaught error — so the socket never leaks.
    slider = tcpclient(SLIDER_IP, SLIDER_PORT);
    slider.ByteOrder = 'little-endian';
    cleanupObj = onCleanup(@() delete(slider)); 

    % Confirm device identity.
    writeline(slider, '*IDN?');
    fprintf('Connected to: %s\n', strtrim(readline(slider)));

    % Read mechanical limits from the device (do not assume 0–200 cm).
    lowerLimit = str2double(writeread(slider, 'AXIS1:LL?'));
    upperLimit = str2double(writeread(slider, 'AXIS1:UL?'));

    % Validate target against actual mechanical limits.
    if targetPosition < lowerLimit || targetPosition > upperLimit
        error('setLinearSlider:outOfBounds', ...
              'Target %.2f cm is outside mechanical limits [%.2f, %.2f] cm.', ...
              targetPosition, lowerLimit, upperLimit);
    end

    % Read current position.
    currentPosition = str2double(writeread(slider, 'AXIS1:CP?'));

    % Skip the move if the slider is already within tolerance of the target.
    % Exact floating-point equality is unreliable for device-reported positions.
    if abs(targetPosition - currentPosition) <= POS_TOL
        fprintf('Slider already at %.2f cm (target %.2f cm). No motion commanded.\n', ...
                currentPosition, targetPosition);
        return;
    end

    % Set speed.
    writeline(slider, sprintf('AXIS1:S%d', speedPreset));

    % Command the move.
    writeline(slider, sprintf('AXIS1:SK %d', targetPosition));

    % Poll DIR? until motion stops. A rate-limited loop (POLL_DELAY between queries)
    % prevents flooding the device's TCP stack, which can cause it to drop responses.
    startTime = tic;
    while true
        dir = strtrim(writeread(slider, 'AXIS1:DIR?'));

        if ~strcmp(dir, '+1') && ~strcmp(dir, '-1')
            break;  % DIR? returns 0 when the axis is stationary
        end

        if toc(startTime) > TIMEOUT_S
            writeline(slider, 'AXIS1:STOP');
            error('setLinearSlider:timeout', ...
                  'Motion to %.2f cm did not complete within %d s. STOP sent.', ...
                  targetPosition, TIMEOUT_S);
        end

        pause(POLL_DELAY);
    end

    cp = str2double(writeread(slider, 'AXIS1:CP?'));
    fprintf('Slider arrived at %.2f cm.\n', cp);
    % cleanupObj deletes the TCP connection here.
end


%% Manual stop
% To stop the slider mid-move from the command line:
%   slider = tcpclient('192.168.0.100', 1206);
%   writeline(slider, 'AXIS1:STOP');
%   delete(slider);

%% Error codes
%  1   Controller board Flash memory malfunction
%  2   Axis not moving
%  3   Motor not stopping
%  4   Motor moving in wrong direction
%  5   Hardware limit hit
%  6   Polarization limit violation
%  7   Lost communication
%  9   Encoder failure
%  10  Trigger failure
%  11  Motor overheat
%  12  Relay failure
%  13  Position out of bounds
%  14  Trying to move a locked axis
%  32  Motor driver fault
%  100–399  Command syntax error
%  400–499  Home procedure failure
%  500–599  Trigger command malformed
%  1000     Firmware upgrade failure

