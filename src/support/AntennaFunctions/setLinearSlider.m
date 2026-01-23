function setLinearSlider(speedPreset, targetPosition)
    %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
    % DESCRIPTION:
    % This function controls the movement of the EMCenter linear slider by setting its speed preset and moving it to 
    % a user-specified target position. Once the speed is set, the slider will move smoothly to the specified target
    % position, ensuring precise control over the motion.
    %
    % INPUT:
    %   speedPreset    - An integer between 1 (slowest) and 8 (fastest) that sets the speed of the linear slider.
    %   targetPosition - Target position in cm (0 - 200 cm) for the slider to move to.
    %
    % OUTPUT:
    %   None
    %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

    % Connect to the device.
    LinearSlider = tcpclient('192.168.0.100', 1206);
    LinearSlider.ByteOrder = 'little-endian';

    % Get identification from device.
    writeline(LinearSlider, '*IDN?');
    response = readline(LinearSlider);
    disp(response);

    % Get the upper and lower mechanical limits.
    LowerLimit = str2double(writeread(LinearSlider, 'AXIS1:LL?'));
    UpperLimit = str2double(writeread(LinearSlider, 'AXIS1:UL?'));

    % Get the current position of the device.
    currentPosition = str2double(writeread(LinearSlider, 'AXIS1:CP?'));

    % Set the speed of the device.
    writeline(LinearSlider, sprintf('AXIS1:S%d', speedPreset));

    % Go to the target position.
    if (targetPosition < LowerLimit) || (targetPosition > UpperLimit)
        fprintf('Target Position Outside of Device Bounds.')
    elseif (targetPosition == currentPosition)
        fprintf('Linear Slider Already at Target Position.')
    else
        writeline(LinearSlider, sprintf('AXIS1:SK %d', targetPosition));
        motion = writeread(LinearSlider, 'AXIS1:DIR?');
        while strcmp(motion, '+1') || strcmp(motion, '-1')
            motion = writeread(LinearSlider, 'AXIS1:DIR?');
            cp = str2double(writeread(LinearSlider, 'AXIS1:CP?'));
            disp(cp);
        end
        fprintf('Linear Slider Moved to Target Position.')
    end

    % To manually stop the linear slider use the following
    % writeline(LinearSlider, 'AXIS1:STOP')

    % Delete and clear the connection to the device.
    delete(LinearSlider);
    clear LinearSlider;
end


%% Commands
% Show errors: error = str2double(writeread(LinearSlider, 'AXIS1:ERR?'))
%    Error Codes:
%    1 – Controller board Flash memory malfunction
%    2 – Axis not moving
%    3 – Motor not stopping
%    4 – Motor moving on wrong direction
%    5 – Hardware Limit hit
%    6 – Polarization limit violation
%    7 – Lost communication
%    9 – Encoder failure
%    10 – Trigger failure
%    11 – Motor overheat
%    12 – Relay failure,
%    13 – Position out of bounds
%    14 – Trying to move a locked axis
%    32 – Motor driver fault
%    100-399 – Command syntax error
%    400-499 – Home procedure failure
%    500-599 – Trigger command malformed
%    1000 – Firmware upgrade failure
% Home: writeline(LinearSlider, 'AXIS1:HOME')
% Zero: writeline(LinearSlider, 'AXIS1:ZERO')
%% Reset
% Restart and move back from the front limit
% writeline(LinearSlider, 'AXIS1:CR'); % Turn CR mode on to disable soft limits
% writeline(LinearSlider, 'AXIS1:CC'); % Move backwards
% writeline(LinearSlider, 'AXIS1:ST'); % STOP 
% writeline(LinearSlider, 'AXIS1:NCR'); % Turn NCR mode on to enable soft limits
% writeline(LinearSlider, 'AXIS1:HOME')
% writeread(LinearSlider, 'AXIS1:*OPC?')