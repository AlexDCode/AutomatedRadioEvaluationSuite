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


