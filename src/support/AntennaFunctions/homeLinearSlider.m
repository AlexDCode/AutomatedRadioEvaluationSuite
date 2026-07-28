function homeLinearSlider()
    %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
    % DESCRIPTION:
    % Homes the EMCenter linear slider. Bench/operator convenience wrapper: opens its own
    % connection, homes, and closes.
    %
    % This is now a thin wrapper over the EmCenterSlider driver. The pre-home fault check,
    % the AXIS1:*OPC?-only wait loop, the timeout, the post-home fault check and the socket
    % cleanup all live in EmCenterSlider.home(). Notably the driver preserves the fix this
    % script originally introduced: the wait loop polls *OPC? and NOTHING else, because
    % sending AXIS:ZERO mid-move (as the pre-2026 script did) corrupts the controller's
    % position reference and makes HOME fail or hang.
    %
    % INPUT:
    %   None
    %
    % OUTPUT:
    %   None
    %
    % ERRORS:
    %   Throws an error (does NOT silently ignore) if:
    %     - The device reports a fault code before homing  (EmCenterSlider:PreHomeFault)
    %     - Homing does not complete within the timeout    (EmCenterSlider:HomeTimeout)
    %     - The device reports a fault code after homing   (EmCenterSlider:PostHomeFault)
    %
    % RECOVERY (slider stuck at a hardware limit):
    %   If the slider has tripped a hardware limit and HOME fails, run the following
    %   sequence manually before calling this function again:
    %
    %     s = EmCenterSlider();            % 192.168.0.100:1206, axis 1
    %     s.writeline('AXIS1:CR');         % disable soft limits
    %     s.writeline('AXIS1:CC');         % jog backwards (away from limit)
    %     s.writeline('AXIS1:ST');         % stop when clear of limit
    %     s.writeline('AXIS1:NCR');        % re-enable soft limits
    %     delete(s);
    %   Then call homeLinearSlider() normally.
    %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

    SLIDER_IP   = "192.168.0.100";
    SLIDER_PORT = 1206;

    % The constructor connects and caches the mechanical limits. onCleanup
    % guarantees the socket is released on any exit path, including an error
    % thrown from inside home().
    slider = EmCenterSlider(SLIDER_IP, SLIDER_PORT, 1);
    cleanupObj = onCleanup(@() delete(slider));

    fprintf('Connected to: %s\n', strtrim(slider.idn()));
    fprintf('Current position before homing: %.2f cm.\n', slider.getPosition());

    fprintf('HOME command sent. Waiting for completion...\n');
    slider.home();

    fprintf('Homing complete. Final position: %.2f cm.\n', slider.getPosition());
    % cleanupObj closes the connection here.
end
