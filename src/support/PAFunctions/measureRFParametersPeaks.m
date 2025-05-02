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

    % Get the max output RF power per frequency.
    Psat = groupsummary(app.PA_DataTable(idx,:),'FrequencyMHz','max','RFOutputPowerdBm');
    Psat.GroupCount = zeros(height(Psat),1); % Reset column to be used for gain
    Psat.Properties.VariableNames = {'FrequencyMHz','Gain','RFOutputPowerdBm'}; % Rename
    Psat = Psat(:,{'FrequencyMHz','RFOutputPowerdBm','Gain'}); % Reorder
    for i = 1:height(Psat)      
        Psat_DataTable = app.PA_DataTable(idx,:);
        idx_Psat = (Psat_DataTable.RFOutputPowerdBm == Psat.RFOutputPowerdBm(i));
        Psat(i,"Gain") = array2table(Psat_DataTable(idx_Psat,:).Gain);
    end

    % Get the max drain efficiency per frequency.
    peakDE = groupsummary(app.PA_DataTable,'FrequencyMHz','max','DE');
    peakDE.GroupCount = []; % Drop GroupCount column
   
    % Get the max power-added efficiency per frequency.
    peakPAE = groupsummary(app.PA_DataTable,'FrequencyMHz','max','PAE');
    peakPAE.GroupCount = []; % Drop GroupCount column

    peakGain = groupsummary(app.PA_DataTable,'FrequencyMHz','max','Gain');
    peakGain.GroupCount = []; % Drop GroupCount column

    % Get the compression points
    compression1dB = array2table(zeros(0,3),'VariableNames',[{'FrequencyMHz'},{'RFOutputPowerdBm'},{'Gain'}]);
    compression3dB = compression1dB;
    freqs = unique(app.PA_DataTable(idx,"FrequencyMHz")); % Iterate by frequency
    for i = 1:height(freqs)
        % Get temporary subtable for each frequency
        freq_DataTable = app.PA_DataTable(idx,:);
        freq_DataTable = freq_DataTable(freq_DataTable.FrequencyMHz == freqs.FrequencyMHz(i),:);
        
        % Select the peak gain corresponding to this frequency
        peakGain_i = table2array(peakGain(peakGain.FrequencyMHz == freqs.FrequencyMHz(i,:),"max_Gain"));

        % Get the compression points
        compression1dB_i = freq_DataTable(freq_DataTable.Gain <= (peakGain_i - 1),["FrequencyMHz","RFOutputPowerdBm","Gain"]);
        compression3dB_i = freq_DataTable(freq_DataTable.Gain <= (peakGain_i - 3),["FrequencyMHz","RFOutputPowerdBm","Gain"]);
        if height(compression1dB_i) > 1
            compression1dB(i,:) = compression1dB_i(1,:);
        end
        if height(compression3dB_i) > 1
            compression3dB(i,:) = compression3dB_i(1,:);
        end
    end
end
