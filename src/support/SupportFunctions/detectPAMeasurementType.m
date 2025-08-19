function mode = detectPAMeasurementType(varNames)
    %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
    % DESCRIPTION:
    % Detects the type of Power Amplifier (PA) measurement based on the presence of specific variable names in a 
    % dataset. The function checks for Continuous Wave (CW) or Modulated measurement indicators and returns the 
    % corresponding measurement mode. If no matching variables are found, the mode is classified as "Unknown".
    %
    % Example usage:
    %
    %   - mode = detectPAMeasurementType(app.PA_DataTable.Properties.VariableNames);
    %
    % INPUT:
    %   varNames - Cell array of variable names to analyze.
    %
    % OUTPUT:
    %   mode - String indicating the detected measurement type:
    %                 "CW"        - Continuous Wave measurement
    %                 "Modulated" - Modulated signal measurement
    %                 "Unknown"   - No matching pattern detected
    %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

    % Define keyword groups
    cwKeywords = {'RFOutputPowerdBm', 'DE', 'PAE'};
    modulatedKeywords = {'AverageGaindB', 'RFInputChannelPowerdBm', 'RFOutputChannelPowerdBm', ...
        'InputOccupiedBandwidth', 'OutputOccupiedBandwidth', 'AverageDE', 'AveragePAE', ...
        'InputACPRLowerUpperdBc' ,'OutputACPRLowerUpperdBc',...
        'RFInputPowerSpectrumFrequencyAverageMaximumdBm', ...
        'RFOutputPowerSpectrumFrequencyAverageMaximumdBm'};

    % Check presence in variable names
    hasCW = any(ismember(cwKeywords, varNames));
    hasModulated = any(ismember(modulatedKeywords, varNames));

    % Set mode
    if hasModulated
        mode = "Modulated";
    elseif hasCW
        mode = "CW";
    else
        mode = "Unknown";
    end
end