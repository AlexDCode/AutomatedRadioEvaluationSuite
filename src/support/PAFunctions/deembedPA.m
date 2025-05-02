function [inCal, outCal] = deembedPA(app, testFrequency, RFInputPower)
    %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
    % DESCRIPTION:
    % This function de-embeds Power Amplifier (PA) measurements by removing the effects of passive and active devices.
    % It generates calibration factors for both the input and output of the PA, which are applied to the measured RF
    % power values in order to obtain the corrected PA input and output RF power. The calibration factors are computed
    % based on the selected calibration mode and available data on the app. The function supports the following 
    % calibration modes:
    %
    %   - **None**: No calibration is applied, and both input and output calibration factors are set to 0.
    %   - **Fixed Attenuation**: The function directly applies the attenuation values set in the application for both input and output.
    %   - **Small Signal**: Uses fixed attenuation values combined with interpolated S-parameters from the provided S-parameter file for both input and output.
    %   - **Small + Large Signal**: Same behavior as **Small Signal** but also integrates driver gain data. The driver gain is interpolated based on both the test frequency and RF input power, which is then subtracted from the input calibration factor.
    %
    % INPUT:
    %   app            - The application object containing configuration settings and attenuation values for the PA setup.
    %   testFrequency  - The measurement frequency (Hz) at which the calibration and de-embedding should be performed.
    %   RFInputPower   - The measured RF input power (dBm) at the specified frequency.
    %
    % OUTPUT:
    %   inCal          - The input attenuation calibration factor (dB). Subtracts this from the input RF power to obtain the corrected PA input power.
    %   outCal         - The output attenuation calibration factor (dB). Adds this to the measured output power to get the corrected PA output power.
    %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

    calMode = app.CalibrationModeDropDown.Value;

    switch calMode
        case 'None'
            % Calibration factors are 0.
            inCal = 0;
            outCal = 0;

        case 'Fixed Attenuation'
            % Calibration factors are the fixed attenuation in dB.
            inCal = app.InputAttenuationValueField.Value;
            outCal = app.OutputAttenuationValueField.Value;

        case 'Small Signal'
            % Calibration factors add the fixed attenuation and the
            % interpolated S parameters from the given filenames.
            SnP_in = sparameters(app.InputSpFile);
            SnP_out = sparameters(app.OutputSpFile);
            
            % Interpolate the attenuation at the measurement frequency.
            Att_in = -interp1(SnP_in.Frequencies, A2dB(squeeze(abs(SnP_in.Parameters(2,1,:)))), testFrequency, 'spline');
            Att_out = -interp1(SnP_out.Frequencies, A2dB(squeeze(abs(SnP_out.Parameters(2,1,:)))), testFrequency, 'spline');
    
            % Add the attenuations.
            inCal = app.InputAttenuationValueField.Value + Att_in;
            outCal = app.OutputAttenuationValueField.Value + Att_out;

        case 'Small + Large Signal'
            % Combines fixed attenuation, S parameters, and driver response.
            SnP_in = sparameters(app.InputSpFile);
            SnP_out = sparameters(app.OutputSpFile);
    
            % Interpolate the attenuation at the measurement frequency.
            Att_in = -interp1(SnP_in.Frequencies, A2dB(squeeze(abs(SnP_in.Parameters(2,1,:)))), testFrequency, 'spline');
            Att_out = -interp1(SnP_out.Frequencies, A2dB(squeeze(abs(SnP_out.Parameters(2,1,:)))), testFrequency, 'spline');
    
            % Add the attenuations.
            inCal = app.InputAttenuationValueField.Value + Att_in;
            outCal = app.OutputAttenuationValueField.Value + Att_out;
    
            % Get the driver output power for the current input power.
            driver = readtable(app.DriverFile, 'VariableNamingRule', 'preserve');
    
            % Get measured driver frequencies and input powers.
            driverFreq = unique(driver.('Frequency (MHz)')) * 1E6;
            driverPower = unique(driver.('RF Input Power (dBm)'));
            
            % Interpolate the measurement frequency with driver data.
            driverFreq = interp1(driverFreq, driverFreq, testFrequency, 'nearest', 'extrap');
    
            % Interpolate the measurement RF input power with driver data.
            driverPower = interp1(driverPower, driverPower, RFInputPower - inCal, 'nearest', 'extrap');

            % Find rows matching the frequency and input power criteria.
            freqMatch = driver.('Frequency (MHz)') == driverFreq/1E6;
            powerMatch = driver.('RF Input Power (dBm)') == driverPower;
            matchingRows = freqMatch & powerMatch; 

            % Get the driver gain from the matching row(s).
            if any(matchingRows)
                driverGain = driver.Gain(matchingRows);
                
                % For safety if there are multiple values (unlikely), we 
                % take the first one.
                if length(driverGain) > 1
                    driverGain = driverGain(1);
                end
            else
                error('No matching driver data found for frequency %.2f MHz and power %.2f dBm', driverFreq/1E6, driverPower);
            end
            
            % Recalculate inCal to include driver gain.
            inCal = app.InputAttenuationValueField.Value + Att_in - driverGain;
    end
end