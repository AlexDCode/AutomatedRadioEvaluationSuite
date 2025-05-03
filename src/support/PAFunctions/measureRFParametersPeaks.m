function [Psat, peakGain, peakDE, peakPAE, compression1dB, compression3dB] = measureRFParametersPeaks(app, idx)
    %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
    % DESCRIPTION:
    % This function calculates peak RF performance metrics from power amplifier (PA) measurement data, including
    % saturation power, peak gain, peak drain efficiency (DE), peak power-added efficiency (PAE), and -1 dB 
    % and -3 dB compression points.
    %
    % INPUT:
    %   app     - The application object containing the PA measurement data table.
    %   idx     - Logical or numeric index used to filter the rows of the PA data table for analysis.
    %
    % OUTPUT:
    %   Psat            - Table containing the maximum RF output power (Psat) per frequency and corresponding gain.
    %   peakGain        - Table of peak small-signal gain values per frequency.
    %   peakDE          - Table of maximum drain efficiency per frequency.
    %   peakPAE         - Table of maximum power-added efficiency per frequency.
    %   compression1dB  - Table containing the -1 dB gain compression points per frequency.
    %   compression3dB  - Table containing the -3 dB gain compression points per frequency.
    %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

    % Filtered PA data using the index.
    PATable = app.PA_DataTable(idx, :);

    % Maximum RF Output Power (Psat) per frequency.
    Psat = groupsummary(PATable, 'FrequencyMHz', 'max', 'RFOutputPowerdBm');

    % Peak Gain, DE, and PAE per frequency.
    peakGain = groupsummary(PATable, 'FrequencyMHz', 'max', 'Gain');
    peakDE = groupsummary(PATable, 'FrequencyMHz', 'max', 'DE');
    peakPAE = groupsummary(PATable, 'FrequencyMHz', 'max', 'PAE');

    % maxPowerRows is a new table that has all columns from PATable, the
    % max_RFOutputPowerdBm column from Psat, and keeps rows where the 
    % FrequencyMHz matched between PATable and Psat.
    maxPowerRows = join(PATable, Psat(:,{'FrequencyMHz','max_RFOutputPowerdBm'}), 'Keys', 'FrequencyMHz');
    
    % Filter maxPowerRows to keep rows where RF Output Power matches PSat
    % for that frequency.
    maxPowerRows = maxPowerRows(maxPowerRows.RFOutputPowerdBm == maxPowerRows.max_RFOutputPowerdBm, :);
    
    % Get max gain at those points.
    gainAtMaxPower = groupsummary(maxPowerRows, 'FrequencyMHz', 'max', 'Gain');
    
    % Add gain information to Psat table and rename for clarity.
    Psat = join(Psat, gainAtMaxPower(:,{'FrequencyMHz','max_Gain'}), 'Keys', 'FrequencyMHz');
    Psat = renamevars(Psat, {'max_RFOutputPowerdBm', 'max_Gain'}, {'RFOutputPowerdBm', 'Gain'});

    % Unique frequencies to iterate over.
    uniqueFrequencies = unique(PATable.FrequencyMHz);
    numFreqs = length(uniqueFrequencies);
    
    % Pre-allocate compression point tables.
    compression1dB = array2table(zeros(numFreqs, 3), 'VariableNames', {'FrequencyMHz', 'RFOutputPowerdBm', 'Gain'});
    compression3dB = array2table(zeros(numFreqs, 3), 'VariableNames', {'FrequencyMHz', 'RFOutputPowerdBm', 'Gain'});

    for i = 1:numFreqs
        currentFreq = uniqueFrequencies(i);

        % Filter data for current frequency
        FrequencyTable = PATable(PATable.FrequencyMHz == currentFreq, :);
        
        % Sort by output power to ensure proper sequencing
        FrequencyTable = sortrows(FrequencyTable, 'RFOutputPowerdBm');

        % Get the peak gain for the current frequency
        currentPeakGain = peakGain.max_Gain(peakGain.FrequencyMHz == currentFreq);

        % Find the power level where peak gain occurs
        peakGainPower = max(FrequencyTable.RFOutputPowerdBm(FrequencyTable.Gain == currentPeakGain));

        % Find the compression points after the peak gain power level
        idxPostPeak = find(FrequencyTable.Gain <= (currentPeakGain - 1) & (FrequencyTable.RFOutputPowerdBm > peakGainPower));

        % -1 dB compression
        if ~isempty(idxPostPeak)
            compression1dB(i, :) = {currentFreq, FrequencyTable.RFOutputPowerdBm(idxPostPeak(1)), FrequencyTable.Gain(idxPostPeak(1))};
        else
            compression1dB(i, :) = {currentFreq, NaN, NaN};
        end

        % -3 dB compression
        idx_after_peak_3dB = find(FrequencyTable.Gain <= (currentPeakGain - 3) & (FrequencyTable.RFOutputPowerdBm > peakGainPower));
                                 
        if ~isempty(idx_after_peak_3dB)
            compression3dB(i, :) = {currentFreq, FrequencyTable.RFOutputPowerdBm(idx_after_peak_3dB(1)), FrequencyTable.Gain(idx_after_peak_3dB(1))};
        else
            compression3dB(i, :) = {currentFreq, NaN, NaN};
        end
    end
end
