function mode = detectPAMeasurementType(varNames)
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
        mode = 'Modulated';
    elseif hasCW
        mode = 'CW';
    else
        mode = 'Unknown';
    end
end