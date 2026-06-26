function homeLinearSlider()
    %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
    % DESCRIPTION:
    % Homes the EMCenter linear slider by sending the AXIS1:HOME command and waiting until
    % the operation completes or a timeout is reached. Device errors are checked before and
    % after the home procedure. The TCP connection is always closed on exit.
    %
    % This function replaces the original homeLinearSlider script. Key differences:
    %
    %   - Correct wait loop: polls AXIS1:*OPC? only — does NOT send AXIS1:ZERO mid-move.
    %     The original script sent ZERO inside the wait loop, which corrupted the position
    %     reference while the axis was moving and caused the HOME procedure to fail or hang.
    %   - Timeout: exits with an error if homing does not complete within TIMEOUT_S seconds.
    %   - Error checking: reads AXIS1:ERR? before and after homing and throws if non-zero.
    %   - Guaranteed cleanup: onCleanup closes the TCP socket on any exit path, preventing
    %     the stale-connection errors that required restarting MATLAB between attempts.
    %
    % INPUT:
    %   None
    %
    % OUTPUT:
    %   None
    %
    % ERRORS:
    %   Throws an error (does NOT silently ignore) if:
    %     - The device reports a fault code before homing
    %     - Homing does not complete within TIMEOUT_S seconds
    %     - The device reports a fault code after homing
    %
    % RECOVERY (slider stuck at a hardware limit):
    %   If the slider has tripped a hardware limit and HOME fails, run the following
    %   sequence manually before calling this function again:
    %
    %     slider = tcpclient('192.168.0.100', 1206);
    %     writeline(slider, 'AXIS1:CR');   % disable soft limits
    %     writeline(slider, 'AXIS1:CC');   % jog backwards (away from limit)
    %     writeline(slider, 'AXIS1:ST');   % stop when clear of limit
    %     writeline(slider, 'AXIS1:NCR');  % re-enable soft limits
    %     delete(slider);
    %   Then call homeLinearSlider() normally.
    %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

    SLIDER_IP   = '192.168.0.100';
    SLIDER_PORT = 1206;
    TIMEOUT_S   = 120;   % homing a 200 cm rail at speed 1 can take ~90 s
    POLL_DELAY  = 0.25;  % seconds between OPC? polls

    % Open connection. onCleanup guarantees delete() runs on any exit path —
    % normal return, error, or Ctrl-C — so the socket never leaks.
    slider = tcpclient(SLIDER_IP, SLIDER_PORT);
    slider.ByteOrder = 'little-endian';
    cleanupObj = onCleanup(@() delete(slider)); 

    % Confirm device identity.
    writeline(slider, '*IDN?');
    fprintf('Connected to: %s\n', strtrim(readline(slider)));

    % Read current position for the operator's reference.
    cp = str2double(writeread(slider, 'AXIS1:CP?'));
    fprintf('Current position before homing: %.2f cm.\n', cp);

    % Check for pre-existing faults. Attempting to home with an active error
    % will cause the HOME procedure to fail immediately (error codes 400–499).
    errCode = str2double(writeread(slider, 'AXIS1:ERR?'));
    if errCode ~= 0
        error('homeLinearSlider:preFault', ...
              'Slider reports fault code %d before homing. Resolve the fault first.\n%s', ...
              errCode, faultDescription(errCode));
    end

    % Send the HOME command.
    writeline(slider, 'AXIS1:HOME');
    fprintf('HOME command sent. Waiting for completion...\n');

    % Poll OPC? until the operation is complete or the timeout expires.
    % DO NOT send any other commands (e.g. ZERO) inside this loop — doing so
    % interrupts the HOME procedure and corrupts the controller state.
    startTime = tic;
    while true
        opc = str2double(writeread(slider, 'AXIS1:*OPC?'));

        if opc == 1
            break;
        end

        if toc(startTime) > TIMEOUT_S
            error('homeLinearSlider:timeout', ...
                  'HOME did not complete within %d s. Check for a limit fault or mechanical obstruction.', ...
                  TIMEOUT_S);
        end

        pause(POLL_DELAY);
    end

    % Check for faults introduced during homing.
    errCode = str2double(writeread(slider, 'AXIS1:ERR?'));
    if errCode ~= 0
        error('homeLinearSlider:postFault', ...
              'Slider reports fault code %d after homing.\n%s', ...
              errCode, faultDescription(errCode));
    end

    cp = str2double(writeread(slider, 'AXIS1:CP?'));
    fprintf('Homing complete. Final position: %.2f cm.\n', cp);
    % cleanupObj deletes the TCP connection here.
end


function msg = faultDescription(code)
    % Return a human-readable description for known EMSlider fault codes.
    lookup = { ...
        1,  'Controller board Flash memory malfunction'; ...
        2,  'Axis not moving'; ...
        3,  'Motor not stopping'; ...
        4,  'Motor moving in wrong direction'; ...
        5,  'Hardware limit hit'; ...
        6,  'Polarization limit violation'; ...
        7,  'Lost communication'; ...
        9,  'Encoder failure'; ...
        10, 'Trigger failure'; ...
        11, 'Motor overheat'; ...
        12, 'Relay failure'; ...
        13, 'Position out of bounds'; ...
        14, 'Trying to move a locked axis'; ...
        32, 'Motor driver fault'; ...
    };
    idx = find([lookup{:,1}] == code, 1);
    if ~isempty(idx)
        msg = lookup{idx, 2};
    elseif code >= 100 && code <= 399
        msg = 'Command syntax error';
    elseif code >= 400 && code <= 499
        msg = 'Home procedure failure';
    elseif code >= 500 && code <= 599
        msg = 'Trigger command malformed';
    elseif code == 1000
        msg = 'Firmware upgrade failure';
    else
        msg = 'Unknown fault code';
    end
end
