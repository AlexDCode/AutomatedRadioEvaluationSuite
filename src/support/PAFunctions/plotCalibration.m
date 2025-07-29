function plotCalibration(app)
%plotCalibration Plots the Input and Output Calibration
%   Detailed explanation goes here

    cla(app.InputCalibrationPlot, "reset");
    cla(app.OutputCalibrationPlot, "reset");

    try
    switch app.CalibrationModeDropDown.Value
        case "Fixed Attenuation"
            if app.MeasurementTypeDropDown.Value == "Single Frequency"
                freq = [app.StartFrequency.Value];
            elseif app.MeasurementTypeDropDown.Value == "Sweep Frequencies"
                freq = (app.StartFrequency.Value:app.StepFrequency.Value:app.EndFrequency.Value);
            end

            Att_in = app.InputAttenuationValueField.Value * ones(size(freq,2),1);
            Att_out = app.OutputAttenuationValueField.Value * ones(size(freq,2),1);

            % Plot input attenuation
            ax = app.InputCalibrationPlot;
            plot(ax, freq, Att_in, 'DisplayName', 'Input Attenuation');
            xlabel(ax, 'Frequency (MHz)');
            ylabel(ax, 'Attenuation (dB)');
            title(ax, 'Input Calibration');
        
            % Tighten and improve the axes appearance.
            axis(ax,'tight')
            improveAxesAppearance(ax, 'LineThickness', 2);
            updateColorOrder(app);
            updateColormap(app);

            % Plot output attenuation
            ax = app.OutputCalibrationPlot;
            plot(ax, freq, Att_out, 'DisplayName', 'Output Attenuation');
            xlabel(ax, 'Frequency (MHz)');
            ylabel(ax, 'Attenuation (dB)');
            title(ax, 'Output Calibration');

            % Tighten and improve the axes appearance.
            axis(ax,'tight')
            improveAxesAppearance(ax, 'LineThickness', 2);
            updateColorOrder(app);
            updateColormap(app);

        case "Small Signal"
            % Load response
            if app.InputSpFile
                SnP_in = sparameters(app.InputSpFile);

                % Interpolate the attenuation at the measurement frequency.
                Att_in = -A2dB(squeeze(abs(SnP_in.Parameters(2,1,:))));

                % Combine fixed attenuation, lossed and coupling
                inCal = -app.InputAttenuationValueField.Value - Att_in;
    
                % Plot input attenuation
                ax = app.InputCalibrationPlot;
                plot(ax, SnP_in.Frequencies/1e6, A2dB(squeeze(abs(SnP_in.Parameters(1,1,:)))), 'DisplayName', 'S(1,1)');
                hold(ax, 'on');
                plot(ax, SnP_in.Frequencies/1e6, A2dB(squeeze(abs(SnP_in.Parameters(2,2,:)))), 'DisplayName', 'S(2,2)');
                plot(ax, SnP_in.Frequencies/1e6, A2dB(squeeze(abs(SnP_in.Parameters(2,1,:)))), 'DisplayName', 'Insertion Loss');
                plot(ax, SnP_in.Frequencies/1e6, inCal, 'DisplayName', 'Calibration');
            else
                if app.MeasurementTypeDropDown.Value == "Single Frequency"
                freq = [app.StartFrequency.Value];
                elseif app.MeasurementTypeDropDown.Value == "Sweep Frequencies"
                    freq = (app.StartFrequency.Value:app.StepFrequency.Value:app.EndFrequency.Value);
                end
    
                Att_in = app.InputAttenuationValueField.Value * ones(size(freq,2),1);
    
                % Plot input attenuation
                ax = app.InputCalibrationPlot;
                plot(ax, freq, Att_in, 'DisplayName', 'Input Attenuation');
            end

            xlabel(ax, 'Frequency (MHz)');
            ylabel(ax, 'Attenuation (dB)');
            title(ax, 'Input Calibration');
            legend(ax);
        
            % Tighten and improve the axes appearance.
            axis(ax,'tight')
            improveAxesAppearance(ax, 'LineThickness', 2);
            updateColorOrder(app);
            updateColormap(app);

            if app.OutputSpFile
                SnP_out = sparameters(app.OutputSpFile);

                % Interpolate the coupling at the measurement frequency.
                Att_out = -A2dB(squeeze(abs(SnP_out.Parameters(2,1,:))));
    
                % Combine fixed attenuation, lossed and coupling
                outCal = -app.OutputAttenuationValueField.Value - Att_out;
    
                % Plot output attenuation
                ax = app.OutputCalibrationPlot;
                hold(ax, 'on');
                plot(ax, SnP_out.Frequencies/1e6, A2dB(squeeze(abs(SnP_out.Parameters(1,1,:)))), 'DisplayName', 'S(1,1)');
                plot(ax, SnP_out.Frequencies/1e6, A2dB(squeeze(abs(SnP_out.Parameters(2,2,:)))), 'DisplayName', 'S(2,2)');
                plot(ax, SnP_out.Frequencies/1e6, A2dB(squeeze(abs(SnP_out.Parameters(2,1,:)))), 'DisplayName', 'Insertion Loss');
                plot(ax, SnP_out.Frequencies/1e6, outCal, 'DisplayName', 'Calibration');
            else
                if app.MeasurementTypeDropDown.Value == "Single Frequency"
                freq = [app.StartFrequency.Value];
                elseif app.MeasurementTypeDropDown.Value == "Sweep Frequencies"
                    freq = (app.StartFrequency.Value:app.StepFrequency.Value:app.EndFrequency.Value);
                end
    
                Att_out = app.OutputAttenuationValueField.Value * ones(size(freq,2),1);
    
                % Plot input attenuation
                ax = app.OutputCalibrationPlot;
                plot(ax, freq, Att_out, 'DisplayName', 'Input Attenuation');
            end
    
            xlabel(ax, 'Frequency (MHz)');
            ylabel(ax, 'Attenuation (dB)');
            title(ax, 'Output Calibration');
            legend(ax);

            % Tighten and improve the axes appearance.
            axis(ax,'tight')
            improveAxesAppearance(ax, 'LineThickness', 2);
            updateColorOrder(app);
            updateColormap(app);
        case "Small + Large Signal"
            % Load response
            if app.InputSpFile
                SnP_in = sparameters(app.InputSpFile);

                % Interpolate the attenuation at the measurement frequency.
                Att_in = -A2dB(squeeze(abs(SnP_in.Parameters(2,1,:))));

                % Combine fixed attenuation, lossed and coupling
                inCal = -app.InputAttenuationValueField.Value - Att_in;
    
                % Plot input attenuation
                ax = app.InputCalibrationPlot;
                plot(ax, SnP_in.Frequencies/1e6, A2dB(squeeze(abs(SnP_in.Parameters(1,1,:)))), 'DisplayName', 'S(1,1)');
                hold(ax, 'on');
                plot(ax, SnP_in.Frequencies/1e6, A2dB(squeeze(abs(SnP_in.Parameters(2,2,:)))), 'DisplayName', 'S(2,2)');
                plot(ax, SnP_in.Frequencies/1e6, A2dB(squeeze(abs(SnP_in.Parameters(2,1,:)))), 'DisplayName', 'Insertion Loss');
                plot(ax, SnP_in.Frequencies/1e6, inCal, 'DisplayName', 'Calibration');
            else
                if app.MeasurementTypeDropDown.Value == "Single Frequency"
                freq = [app.StartFrequency.Value];
                elseif app.MeasurementTypeDropDown.Value == "Sweep Frequencies"
                    freq = (app.StartFrequency.Value:app.StepFrequency.Value:app.EndFrequency.Value);
                end
    
                Att_in = app.InputAttenuationValueField.Value * ones(size(freq,2),1);
    
                % Plot input attenuation
                ax = app.InputCalibrationPlot;
                plot(ax, freq, Att_in, 'DisplayName', 'Input Attenuation');
            end

            xlabel(ax, 'Frequency (MHz)');
            ylabel(ax, 'Attenuation (dB)');
            title(ax, 'Small Signal Input Calibration');
            legend(ax);
        
            % Tighten and improve the axes appearance.
            axis(ax,'tight')
            improveAxesAppearance(ax, 'LineThickness', 2);
            updateColorOrder(app);
            updateColormap(app);

            if app.OutputSpFile
                SnP_out = sparameters(app.OutputSpFile);

                % Interpolate the coupling at the measurement frequency.
                Att_out = -A2dB(squeeze(abs(SnP_out.Parameters(2,1,:))));
    
                % Combine fixed attenuation, lossed and coupling
                outCal = -app.OutputAttenuationValueField.Value - Att_out;
    
                % Plot output attenuation
                ax = app.OutputCalibrationPlot;
                hold(ax, 'on');
                plot(ax, SnP_out.Frequencies/1e6, A2dB(squeeze(abs(SnP_out.Parameters(1,1,:)))), 'DisplayName', 'S(1,1)');
                plot(ax, SnP_out.Frequencies/1e6, A2dB(squeeze(abs(SnP_out.Parameters(2,2,:)))), 'DisplayName', 'S(2,2)');
                plot(ax, SnP_out.Frequencies/1e6, A2dB(squeeze(abs(SnP_out.Parameters(2,1,:)))), 'DisplayName', 'Insertion Loss');
                plot(ax, SnP_out.Frequencies/1e6, outCal, 'DisplayName', 'Calibration');
            else
                if app.MeasurementTypeDropDown.Value == "Single Frequency"
                freq = [app.StartFrequency.Value];
                elseif app.MeasurementTypeDropDown.Value == "Sweep Frequencies"
                    freq = (app.StartFrequency.Value:app.StepFrequency.Value:app.EndFrequency.Value);
                end
    
                Att_out = app.OutputAttenuationValueField.Value * ones(size(freq,2),1);
    
                % Plot input attenuation
                ax = app.OutputCalibrationPlot;
                plot(ax, freq, Att_out, 'DisplayName', 'Input Attenuation');
            end
    
            xlabel(ax, 'Frequency (MHz)');
            ylabel(ax, 'Attenuation (dB)');
            title(ax, 'Small Signal Output Calibration');
            legend(ax);

            % Tighten and improve the axes appearance.
            axis(ax,'tight')
            improveAxesAppearance(ax, 'LineThickness', 2);
            updateColorOrder(app);
            updateColormap(app);
        case "In-Situ Couplers"
            % Load response
            if app.InputSpFile
                SnP_in = sparameters(app.InputSpFile);

                % Interpolate the attenuation at the measurement frequency.
                if SnP_in.NumPorts > 2
                    % If given an S3P or S4P file, port 2 is treated as output
                    Att_in = -A2dB(squeeze(abs(SnP_in.Parameters(2,1,:))));
                else
                    % If given an S2P, port 2 is treated as coupled port and assumed lossless
                    Att_in = 0;
                end
                % Interpolate the coupling at the measurement frequency.
                if SnP_in.NumPorts > 2
                    % Treat port 3 as coupled port if given S3P or S4P file
                    C_in = A2dB(squeeze(abs(SnP_in.Parameters(3,1,:))));
                else
                    % Treat port 2 as coupled if given S2P file
                    C_in = A2dB(squeeze(abs(SnP_in.Parameters(2,1,:))));
                end


                % Combine fixed attenuation, lossed and coupling
                inCal = -app.InputAttenuationValueField.Value - Att_in + C_in;
    
    
                % Plot input attenuation
                ax = app.InputCalibrationPlot;
                plot(ax, SnP_in.Frequencies/1e6, A2dB(squeeze(abs(SnP_in.Parameters(1,1,:)))), 'DisplayName', 'S(1,1)');
                hold(ax, 'on');
                plot(ax, SnP_in.Frequencies/1e6, A2dB(squeeze(abs(SnP_in.Parameters(2,2,:)))), 'DisplayName', 'S(2,2)');
                if SnP_in.NumPorts >= 3
                    plot(ax, SnP_in.Frequencies/1e6, A2dB(squeeze(abs(SnP_in.Parameters(3,3,:)))), 'DisplayName', 'S(3,3)');
                    plot(ax, SnP_in.Frequencies/1e6, A2dB(squeeze(abs(SnP_in.Parameters(2,1,:)))), 'DisplayName', 'Insertion Loss');
                    plot(ax, SnP_in.Frequencies/1e6, A2dB(squeeze(abs(SnP_in.Parameters(3,1,:)))), 'DisplayName', 'Coupling Loss');
                elseif SnP_in.NumPorts == 4
                    plot(ax, SnP_in.Frequencies/1e6, A2dB(squeeze(abs(SnP_in.Parameters(4,4,:)))), 'DisplayName', 'S(4,4)');
                    plot(ax, SnP_in.Frequencies/1e6, A2dB(squeeze(abs(SnP_in.Parameters(4,1,:)))), 'DisplayName', 'Coupling Loss');
                end
                plot(ax, SnP_in.Frequencies/1e6, inCal, 'DisplayName', 'Calibration');
            else
                if app.MeasurementTypeDropDown.Value == "Single Frequency"
                freq = [app.StartFrequency.Value];
                elseif app.MeasurementTypeDropDown.Value == "Sweep Frequencies"
                    freq = (app.StartFrequency.Value:app.StepFrequency.Value:app.EndFrequency.Value);
                end
    
                Att_in = app.InputAttenuationValueField.Value * ones(size(freq,2),1);
    
                % Plot input attenuation
                ax = app.InputCalibrationPlot;
                plot(ax, freq, Att_in, 'DisplayName', 'Input Attenuation');
            end

            xlabel(ax, 'Frequency (MHz)');
            ylabel(ax, 'Attenuation (dB)');
            title(ax, 'Input Calibration');
            legend(ax);
        
            % Tighten and improve the axes appearance.
            axis(ax,'tight')
            improveAxesAppearance(ax, 'LineThickness', 2);
            updateColorOrder(app);
            updateColormap(app);

            if app.OutputSpFile
                SnP_out = sparameters(app.OutputSpFile);

                % Interpolate the coupling at the measurement frequency.
                if SnP_out.NumPorts > 2
                    % Treat port 3 as coupled port if given S3P or S4P file
                    C_out = A2dB(squeeze(abs(SnP_out.Parameters(3,1,:))));
                else
                    % Treat port 2 as coupled if given S2P file
                    C_out = A2dB(squeeze(abs(SnP_out.Parameters(2,1,:))));
                end
    
                % Combine fixed attenuation, lossed and coupling
                outCal = -app.OutputAttenuationValueField.Value + C_out;
    
                % Plot output attenuation
                ax = app.OutputCalibrationPlot;
                hold(ax, 'on');
                plot(ax, SnP_out.Frequencies/1e6, A2dB(squeeze(abs(SnP_out.Parameters(1,1,:)))), 'DisplayName', 'S(1,1)');
                plot(ax, SnP_out.Frequencies/1e6, A2dB(squeeze(abs(SnP_out.Parameters(2,2,:)))), 'DisplayName', 'S(2,2)');
                if SnP_out.NumPorts >= 3
                    plot(ax, SnP_out.Frequencies/1e6, A2dB(squeeze(abs(SnP_out.Parameters(3,3,:)))), 'DisplayName', 'S(3,3)');
                    plot(ax, SnP_out.Frequencies/1e6, A2dB(squeeze(abs(SnP_out.Parameters(2,1,:)))), 'DisplayName', 'Insertion Loss');
                    plot(ax, SnP_out.Frequencies/1e6, A2dB(squeeze(abs(SnP_out.Parameters(3,1,:)))), 'DisplayName', 'Coupling Loss');
                elseif SnP_out.NumPorts == 4
                    plot(ax, SnP_out.Frequencies/1e6, A2dB(squeeze(abs(SnP_out.Parameters(4,4,:)))), 'DisplayName', 'S(4,4)');
                    plot(ax, SnP_out.Frequencies/1e6, A2dB(squeeze(abs(SnP_out.Parameters(4,1,:)))), 'DisplayName', 'Isolation Loss');
                end
                plot(ax, SnP_out.Frequencies/1e6, outCal, 'DisplayName', 'Calibration');
            else
                if app.MeasurementTypeDropDown.Value == "Single Frequency"
                freq = [app.StartFrequency.Value];
                elseif app.MeasurementTypeDropDown.Value == "Sweep Frequencies"
                    freq = (app.StartFrequency.Value:app.StepFrequency.Value:app.EndFrequency.Value);
                end
    
                Att_out = app.OutputAttenuationValueField.Value * ones(size(freq,2),1);
    
                % Plot input attenuation
                ax = app.OutputCalibrationPlot;
                plot(ax, freq, Att_out, 'DisplayName', 'Input Attenuation');
            end
    
            xlabel(ax, 'Frequency (MHz)');
            ylabel(ax, 'Attenuation (dB)');
            title(ax, 'Output Calibration');
            legend(ax);

            % Tighten and improve the axes appearance.
            axis(ax,'tight')
            improveAxesAppearance(ax, 'LineThickness', 2);
            updateColorOrder(app);
            updateColormap(app);
    end
    catch ME
        app.displayError(ME);
    end
end