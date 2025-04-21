function [sParameters_dB, sParameters_Phase, freqValues] = measureSParameters(VNA, smoothingPercentage)
    %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
    % Measure 2-port S-Parameters (Magnitude in dB and Phase in degrees)
    % Supports smoothed or raw measurements using FDATA/SDATA.
    %
    % INPUTS:
    %   VNA                - Instrument object for the VNA
    %   smoothingPercentage - Percentage smoothing aperture (0 = off)
    %
    % OUTPUTS:
    %   sParameters_dB     - Cell array of magnitude data (in dB)
    %   sParameters_Phase  - Cell array of phase data (in degrees)
    %   freqValues         - Frequency sweep values (Hz)
    %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

    % Clear buffer and status.
    flush(VNA);
    writeline(VNA, '*CLS');

    % Define S-parameter labels.
    measLabels = {'S11', 'S21', 'S22'};
    numMeasurements = length(measLabels);

    % Initialize output arrays.
    sParameters_dB = cell(1, numMeasurements);
    sParameters_Phase = cell(1, numMeasurements);

    % Perform a single continuos sweep and wait for the VNA to finish.
    writeline(VNA, 'SENS1:SWE:MODE SING');
    writeline(VNA, '*WAI');

    traceIndex = 1;
        
    if smoothingPercentage ~= 0
        % Read smoothed data (magnitude + phase)
        for i = 1:numMeasurements
            % Magnitude
            writeline(VNA, sprintf('CALC1:PAR:MNUM %d', traceIndex));
            writeline(VNA, 'CALC1:DATA? FDATA');
            sParameters_dB{i} = readbinblock(VNA, 'double');
            flush(VNA);
    
            % Phase
            traceIndex = traceIndex + 1;
            writeline(VNA, sprintf('CALC:PAR:MNUM %d', traceIndex));
            writeline(VNA, 'CALC1:DATA? FDATA');
            sParameters_Phase{i} = readbinblock(VNA, 'double');
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
            sParameters_dB{i} = 20 * log10(abs(complexData));
            flush(VNA);

            % Phase
            traceIndex = traceIndex + 1;  % Move to next trace number
            writeline(VNA, sprintf('CALC:PAR:MNUM %d', traceIndex));
            writeline(VNA, 'CALC1:DATA? SDATA');
            data = readbinblock(VNA, 'double');
            complexData = data(1:2:end) + 1i * data(2:2:end);
            sParameters_Phase{i} = rad2deg(angle(complexData));
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
