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

    % This function has been migrated to the object-oriented framework. The
    % S-parameter acquisition logic now lives in VNAInstCtrl.measureSParameters
    % (support/InstrumentControl). This thin wrapper preserves the original
    % signature so existing callers keep working: it adapts whatever VNA
    % handle it is given (raw visadev or a VNAInstCtrl) into a driver and
    % delegates. New code should call vna.measureSParameters(...) directly.
    vna = aresInstrument(VNA, "VNA");
    [sParamdB, sParamPhase, freqValues] = vna.measureSParameters(smoothingPoints);
end
