function [sParamdB, sParamPhase, freqValues] = measureSParameters(VNA, smoothingPoints)
    %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
    % DESCRIPTION:
    % This function measures 2-port S-parameters (S11, S21, S22) with magnitude in dB and phase in degrees using a 
    % Vector Network Analyzer (VNA). Depending on the `smoothingPoints` input, the function reads either smoothed or raw measurement data.
    %
    %   - **Smoothed Data**: If smoothing is enabled (smoothingPoints > 1), the function retrieves the smoothed magnitude and phase data.
    %   - **Raw Data**: If smoothing is disabled (smoothingPoints = 1), the function retrieves raw data in the form of complex S Parameters and calculates the magnitude and phase from the complex data.
    %
    % INPUT:
    %   VNA                 - The instrument object for the VNA, used for communication and measurement control.
    %   smoothingPoints     - The number of smoothing applied to the S-parameters data.  Has to be less than 25% the number of sweep points
    %
    % OUTPUT:
    %   sParamdB            - A cell array containing the magnitude data (in dB) for each S-parameter. 
    %   sParamPhase         - A cell array containing the phase data (in degrees) for each S-parameter. 
    %   freqValues          - A vector containing the frequency sweep values (in Hz) corresponding to the S-parameters.
    %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

    % Clear buffer and status.
    flush(VNA);
    writeline(VNA, '*CLS');

    % Define S-parameter labels.
    measLabels = {'S11', 'S21', 'S22'};
    numMeasurements = length(measLabels);

    % Initialize output arrays.
    sParamdB = cell(1, numMeasurements);
    sParamPhase = cell(1, numMeasurements);

    % Perform a single continuos sweep and wait for the VNA to finish.
    writeline(VNA, 'SENS1:SWE:MODE SING');
    writeline(VNA, '*WAI');

    traceIndex = 1;
        
    if smoothingPoints ~= 1
        % Read smoothed data (magnitude + phase)
        for i = 1:numMeasurements
            % Magnitude
            writeline(VNA, sprintf('CALC1:PAR:MNUM %d', traceIndex));
            writeline(VNA, 'CALC1:DATA? FDATA');
            sParamdB{i} = readbinblock(VNA, 'double');
            flush(VNA);
    
            % Phase
            traceIndex = traceIndex + 1;
            writeline(VNA, sprintf('CALC:PAR:MNUM %d', traceIndex));
            writeline(VNA, 'CALC1:DATA? FDATA');
            sParamPhase{i} = readbinblock(VNA, 'double');
            flush(VNA);

            % Next magnitude/phase pair.
            traceIndex = traceIndex + 1;
        end
    else
        % Read raw data (magnitude + phase)
        for i = 1:numMeasurements
            % Magnitude
            writeline(VNA, sprintf('CALC:PAR:MNUM %d', traceIndex)); 
            writeline(VNA, 'CALC1:DATA? SDATA');
            data = readbinblock(VNA, 'double');
            complexData = data(1:2:end) + 1i * data(2:2:end);
            sParamdB{i} = 20 * log10(abs(complexData));
            flush(VNA);

            % Phase
            traceIndex = traceIndex + 1;  % Move to next trace number
            writeline(VNA, sprintf('CALC:PAR:MNUM %d', traceIndex));
            writeline(VNA, 'CALC1:DATA? SDATA');
            data = readbinblock(VNA, 'double');
            complexData = data(1:2:end) + 1i * data(2:2:end);
            sParamPhase{i} = rad2deg(angle(complexData));
            flush(VNA);

            % Next magnitude/phase pair.
            traceIndex = traceIndex + 1;
        end
    end

    % Get sweep frequency values
    writeline(VNA, ':SENSe:X:VALues?');
    freqValues = readbinblock(VNA, 'double');
    flush(VNA);
end
