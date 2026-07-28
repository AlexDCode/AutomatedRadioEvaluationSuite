function setLinearSlider(speedPreset, targetPosition)
    %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
    % DESCRIPTION:
    % Moves the EMCenter linear slider to a target position at the requested speed preset.
    % Bench/operator convenience wrapper: opens its own connection, moves, and closes.
    %
    % This is now a thin wrapper over the EmCenterSlider driver. The bounds checking,
    % already-at-target tolerance, DIR? poll loop, timeout-then-STOP behaviour and socket
    % cleanup that used to be written out here all live in EmCenterSlider.moveTo(), so the
    % bench script and the app's antenna measurements drive the hardware through exactly
    % one implementation instead of two copies that can drift.
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
    %     - targetPosition is outside the mechanical limits  (EmCenterSlider:TargetOutOfRange)
    %     - Motion does not complete within the timeout      (EmCenterSlider:MoveTimeout)
    %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

    SLIDER_IP   = "192.168.0.100";
    SLIDER_PORT = 1206;
    POS_TOL     = 0.1;   % cm — treat positions within this tolerance as "already at target"

    % Validate the speed preset before opening the connection, so an obvious
    % typo does not cost a TCP round trip. (The driver validates it too.)
    if ~isnumeric(speedPreset) || ~isscalar(speedPreset) || ...
       speedPreset < 1 || speedPreset > 8 || floor(speedPreset) ~= speedPreset
        error('setLinearSlider:invalidSpeed', ...
              'speedPreset must be an integer between 1 and 8 (got %g).', speedPreset);
    end

    % The constructor connects and caches the mechanical limits. onCleanup
    % guarantees the socket is released on any exit path, including an error
    % thrown from inside moveTo().
    slider = EmCenterSlider(SLIDER_IP, SLIDER_PORT, 1, ...
        "PositionTolerance_cm", POS_TOL, "Verbose", true);
    cleanupObj = onCleanup(@() delete(slider));

    fprintf('Connected to: %s\n', strtrim(slider.idn()));

    slider.setSpeedPreset(speedPreset);
    slider.moveTo(targetPosition);

    fprintf('Slider at %.2f cm.\n', slider.getPosition());
    % cleanupObj closes the connection here.
end


%% Manual stop
% To stop the slider mid-move from the command line:
%   s = EmCenterSlider();   % defaults to 192.168.0.100:1206, axis 1
%   s.stop();
%   delete(s);

%% Error codes
% See EmCenterSlider.faultDescription(code) for the decoded table.
