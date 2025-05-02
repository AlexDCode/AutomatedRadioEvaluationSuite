function waitForInstrument(app, Instrument)
    %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
    % DESCRIPTION:
    % The function waits for a connected instrument to complete its current operation by polling its status using 
    % the `*OPC?` SCPI query. This ensures that subsequent operations only proceed once the instrument is ready. The
    % function enforces a timeout (default 15 seconds). The function:
    %
    %   - Starts a timer.
    %   - Continuously queries instrument status via '*OPC?'.
    %   - Waits between queries using app-defined delay.
    %   - Exits if instrument reports ready (status == 1) or timeout is exceeded.
    %
    % INPUT:
    %   app        - Application object that provides the delay setting between polls.
    %   Instrument - VISA-compatible instrument object supporting '*OPC?' queries.
    %
    % OUTPUT:
    %   None
    %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

    % Adjust the timeout duration as needed.
    timeout = 15; % seconds
    polldelay = app.PAMeasurementDelayValueField.Value;
    startTime = tic; 

    while true
        try
            % Query the instrument for its operation status.
            status = sscanf(writeread(Instrument, '*OPC?'), '%d');
        catch 
            break;
        end

        % Check if the instrument is ready (status == 1).
        if status == 1
            break;
        end

        % Check if the timeout has been exceeded.
        if toc(startTime) > timeout
            break;
        end

        % Pause the execution of the function for a duration specified by 
        % timeout value stored in the application (default 0.1 seconds).
        pause(polldelay); 
    end
end