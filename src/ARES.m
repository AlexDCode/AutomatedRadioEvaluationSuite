classdef ARES < matlab.apps.App
    %ARES Automated Radio Evaluation Suite
    %   Performs automated RF measurements of power amplifiers and antennas
    %   using VISA SCPI commands.

    % Used to locate and load the app's XML configuration file
    properties (Access = public, Constant)
        AppConfigFilename = './ARES.xml'; % File path to the app configuration file containing component layout and settings
    end

    % Properties that correspond to app components
    properties (Access = public)
        UIFigure                        matlab.ui.Figure
        MainGrid                        matlab.ui.container.GridLayout
        MainTabs                        matlab.ui.container.TabGroup
        InfoTab                         matlab.ui.container.Tab
        InfoGridLayout                  matlab.ui.container.GridLayout
        Repo                            matlab.ui.control.Image
        Docs                            matlab.ui.control.Image
        Author                          matlab.ui.control.Label
        AppName                         matlab.ui.control.Label
        Logo                            matlab.ui.control.Image
        PowerAmplifierTab               matlab.ui.container.Tab
        PAGridLayout                    matlab.ui.container.GridLayout
        PATestSettingsPanel             matlab.ui.container.Panel
        GridLayout15                    matlab.ui.container.GridLayout
        LoadPAData                      matlab.ui.control.Button
        StartPAMeasurement              matlab.ui.control.Button
        PAResultsTabs                   matlab.ui.container.TabGroup
        CWTab                           matlab.ui.container.Tab
        GridLayout14                    matlab.ui.container.GridLayout
        SingleFrequencyPAPlot           matlab.ui.control.UIAxes
        PeakGainPlot                    matlab.ui.control.UIAxes
        PeakDEPAEPlot                   matlab.ui.control.UIAxes
        CompressionPointsPlot           matlab.ui.control.UIAxes
        MODTab                          matlab.ui.container.Tab
        GridLayout23                    matlab.ui.container.GridLayout
        AverageGainEfficiencyPlot       matlab.ui.control.UIAxes
        OutputSpectrumPlot              matlab.ui.control.UIAxes
        OccupiedBandwidthPlot           matlab.ui.control.UIAxes
        ChannelPowerACPRPlot            matlab.ui.control.UIAxes
        DCTab                           matlab.ui.container.Tab
        PADCGridLayout                  matlab.ui.container.GridLayout
        PASupplyCurrentPlot             matlab.ui.control.UIAxes
        PASupplyPowerPlot               matlab.ui.control.UIAxes
        PAPeakSupplyCurrentPlot         matlab.ui.control.UIAxes
        PAPeakSupplyPowerPlot           matlab.ui.control.UIAxes
        CALTab                          matlab.ui.container.Tab
        GridLayout21                    matlab.ui.container.GridLayout
        OutputCalibrationPlot           matlab.ui.control.UIAxes
        InputCalibrationPlot            matlab.ui.control.UIAxes
        PASettingsPanel                 matlab.ui.container.TabGroup
        PAInstrumentsTab                matlab.ui.container.Tab
        GridLayout19                    matlab.ui.container.GridLayout
        PADisconnectButton              matlab.ui.control.Button
        PAConnectButton                 matlab.ui.control.Button
        PAMeasurementDelayValueField    matlab.ui.control.NumericEditField
        MeasurementDelaysEditFieldLabel  matlab.ui.control.Label
        InputSignalAnalyzerDropDown     matlab.ui.control.DropDown
        InputSignalAnalyzerStatusLabel  matlab.ui.control.Label
        InputSignalAnalyzerDropDownLabel  matlab.ui.control.Label
        OutputSignalAnalyzerDropDown    matlab.ui.control.DropDown
        OutputSignalAnalyzerStatusLabel  matlab.ui.control.Label
        OutputSignalAnalyzerDropDownLabel  matlab.ui.control.Label
        SignalGeneratorDropDown         matlab.ui.control.DropDown
        SignalGeneratorStatusLabel      matlab.ui.control.Label
        SignalGeneratorLabel            matlab.ui.control.Label
        PowerSupplyBDropDown            matlab.ui.control.DropDown
        PowerSupplyBStatusLabel         matlab.ui.control.Label
        PowerSupplyBLabel               matlab.ui.control.Label
        PowerSupplyADropDown            matlab.ui.control.DropDown
        PowerSupplyAStatusLabel         matlab.ui.control.Label
        PowerSupplyALabel               matlab.ui.control.Label
        PowerSupplyTab                  matlab.ui.container.Tab
        GridLayout18                    matlab.ui.container.GridLayout
        StopVoltage                     matlab.ui.control.NumericEditField
        StopVoltageVEditFieldLabel      matlab.ui.control.Label
        StepVoltage                     matlab.ui.control.NumericEditField
        StepVoltageVEditFieldLabel      matlab.ui.control.Label
        StartVoltage                    matlab.ui.control.NumericEditField
        StartVoltageVEditFieldLabel     matlab.ui.control.Label
        SupplyCurrent                   matlab.ui.control.NumericEditField
        LimitingCurrentALabel           matlab.ui.control.Label
        SingleSweepSwitch               matlab.ui.control.Switch
        DrainGateSwitch                 matlab.ui.control.Switch
        PowerSupplyChannelDropDown      matlab.ui.control.DropDown
        SupplyChannelDropDownLabel      matlab.ui.control.Label
        PowerSupplyModeDropDown         matlab.ui.control.DropDown
        SupplyModeLabel                 matlab.ui.control.Label
        StimulusTab                     matlab.ui.container.Tab
        GridLayout17                    matlab.ui.container.GridLayout
        EndPower                        matlab.ui.control.NumericEditField
        EndPowerdBmEditFieldLabel       matlab.ui.control.Label
        PowerStep                       matlab.ui.control.NumericEditField
        PowerStepdBmEditField           matlab.ui.control.Label
        StartPower                      matlab.ui.control.NumericEditField
        StartPowerdBmEditFieldLabel     matlab.ui.control.Label
        EndFrequency                    matlab.ui.control.NumericEditField
        EndFrequencyMHzLabel            matlab.ui.control.Label
        StepFrequency                   matlab.ui.control.NumericEditField
        StepFrequencyMHzEditFieldLabel  matlab.ui.control.Label
        StartFrequency                  matlab.ui.control.NumericEditField
        StartFrequencyMHzLabel          matlab.ui.control.Label
        MeasurementTypeDropDown         matlab.ui.control.DropDown
        MeasurementTypeDropDownLabel    matlab.ui.control.Label
        ChannelOffsetValueField         matlab.ui.control.NumericEditField
        ChannelOffsetNameField          matlab.ui.control.Label
        ChannelBandwidthValueField      matlab.ui.control.NumericEditField
        ChannelOffsetNameField_2        matlab.ui.control.Label
        SymbolRateValueField            matlab.ui.control.NumericEditField
        SymbolRateNameField             matlab.ui.control.Label
        ModulationTypeDropDown          matlab.ui.control.DropDown
        ModulationTypeDropDownLabel     matlab.ui.control.Label
        StimulusDropDown                matlab.ui.control.DropDown
        StimulusDropDownLabel           matlab.ui.control.Label
        SignalAnalysisTab               matlab.ui.container.Tab
        GridLayout22                    matlab.ui.container.GridLayout
        ReferenceLevelValueField        matlab.ui.control.NumericEditField
        ReferenceLevelNameField         matlab.ui.control.Label
        SweepPointsValueField           matlab.ui.control.NumericEditField
        SweepPointsNameField            matlab.ui.control.Label
        SpanValueField                  matlab.ui.control.NumericEditField
        SpanNameField                   matlab.ui.control.Label
        SignalAnalyzerSettingsLabel     matlab.ui.control.Label
        CalibrationTab                  matlab.ui.container.Tab
        GridLayout16                    matlab.ui.container.GridLayout
        LargeSignalDriverResponseFilenameField  matlab.ui.control.EditField
        LoadLargeSignalDriverResponseButton  matlab.ui.control.Button
        DriverDeembeddingLabel          matlab.ui.control.Label
        OutputSmallSignalFilenameField  matlab.ui.control.EditField
        LoadOuputSmallSignalButton      matlab.ui.control.Button
        InputSmallSignalFilenameField   matlab.ui.control.EditField
        LoadInputSmallSignalButton      matlab.ui.control.Button
        SmallSignalResponseDeembeddingLabel  matlab.ui.control.Label
        OutputAttenuationValueField     matlab.ui.control.NumericEditField
        OutputAttenuationdBEditFieldLabel  matlab.ui.control.Label
        InputAttenuationValueField      matlab.ui.control.NumericEditField
        InputAttenuationdBLabel         matlab.ui.control.Label
        FixedDeembeddingLabel           matlab.ui.control.Label
        CalibrationModeDropDown         matlab.ui.control.DropDown
        CalibrationModeLabel            matlab.ui.control.Label
        SafetyTab                       matlab.ui.container.Tab
        GridLayout20                    matlab.ui.container.GridLayout
        OccupiedBandwidthSpinner        matlab.ui.control.Spinner
        OccupiedBandwidthButton         matlab.ui.control.Button
        MinimumGainSpinner              matlab.ui.control.Spinner
        MinimumGainButton               matlab.ui.control.Button
        SafetyTriggersLabel             matlab.ui.control.Label
        CooldownTimeSpinner             matlab.ui.control.Spinner
        CooldownTimesSpinnerLabel       matlab.ui.control.Label
        PSUDelaySpinner                 matlab.ui.control.Spinner
        PSUDelaysSpinnerLabel           matlab.ui.control.Label
        AdvancedDelaysLabel             matlab.ui.control.Label
        PAPlotTab                       matlab.ui.container.Tab
        GridLayout24                    matlab.ui.container.GridLayout
        ChannelPowerDropDown            matlab.ui.control.DropDown
        ChannelPowerdBmLabel            matlab.ui.control.Label
        ChannelVoltageDropDown          matlab.ui.control.DropDown
        ChannelVoltageDropDownLabel     matlab.ui.control.Label
        PSUChannelDropDown              matlab.ui.control.DropDown
        PSUChannelDropDownLabel         matlab.ui.control.Label
        FrequencySingleDropDown         matlab.ui.control.DropDown
        FrequencyMHzDropDownLabel       matlab.ui.control.Label
        AntennaTab                      matlab.ui.container.Tab
        AntennaGridLayout               matlab.ui.container.GridLayout
        AntTestSettingsPanel            matlab.ui.container.Panel
        AntTestSettingsGridLayout       matlab.ui.container.GridLayout
        LoadTestButton                  matlab.ui.control.Button
        StartTestButton                 matlab.ui.control.Button
        AntennaPattern                  matlab.ui.container.TabGroup
        ReferenceAntennaTab             matlab.ui.container.Tab
        RefAntGridLayout                matlab.ui.container.GridLayout
        ClearReferenceButton            matlab.ui.control.Button
        ReferenceGainFileField          matlab.ui.control.EditField
        BrowseReferenceButton           matlab.ui.control.Button
        GainvsFrequencyBoresight        matlab.ui.control.UIAxes
        ReturnLossBoresight             matlab.ui.control.UIAxes
        RadiationPatternTab             matlab.ui.container.Tab
        AntPatternGridLayout            matlab.ui.container.GridLayout
        GainvsFrequency2DPattern        matlab.ui.control.UIAxes
        GainvsAngle2DPattern            matlab.ui.control.UIAxes
        ReturnLoss2DPattern             matlab.ui.control.UIAxes
        RadiationPattern3DTab           matlab.ui.container.Tab
        Pattern3DGridLayout             matlab.ui.container.GridLayout
        RadiationPlot3DLabel            matlab.ui.control.Label
        RadiationPlot3DPattern          matlab.ui.control.UIAxes
        NPortResultsTab                 matlab.ui.container.Tab
        NPortPlot                       matlab.ui.control.UIAxes
        AntennaSettings                 matlab.ui.container.TabGroup
        AntInstrumentsTab               matlab.ui.container.Tab
        AntInstrumentsGridLayout        matlab.ui.container.GridLayout
        AntennaDisconnectButton         matlab.ui.control.Button
        AntennaConnectButton            matlab.ui.control.Button
        AntennaMeasurementDelayValueField  matlab.ui.control.NumericEditField
        MeasurementDelaysLabel          matlab.ui.control.Label
        EMSliderDropDown                matlab.ui.control.DropDown
        EMSliderStatusLabel             matlab.ui.control.Label
        LinearSliderLabel               matlab.ui.control.Label
        EMCenterDropDown                matlab.ui.control.DropDown
        EMCenterStatusLabel             matlab.ui.control.Label
        EMCenterLabel                   matlab.ui.control.Label
        VNADropDown                     matlab.ui.control.DropDown
        VNAStatusLabel                  matlab.ui.control.Label
        VNALabel                        matlab.ui.control.Label
        VNATab                          matlab.ui.container.Tab
        VNAGridLayout                   matlab.ui.container.GridLayout
        PortMapPanel                    matlab.ui.container.Panel
        PortMapTable                    matlab.ui.control.Table
        AdvancedSetupButton             matlab.ui.control.Button
        SmoothingPoints                 matlab.ui.control.Spinner
        SmoothingPointsLabel            matlab.ui.control.Label
        VNAEndFrequency                 matlab.ui.control.NumericEditField
        EndFrequencyMHzLabel_6          matlab.ui.control.Label
        VNAStartFrequency               matlab.ui.control.NumericEditField
        StartFrequectSpanMHzLabel_15    matlab.ui.control.Label
        VNASweepPoints                  matlab.ui.control.NumericEditField
        SweepPointsLabel                matlab.ui.control.Label
        Table                           matlab.ui.container.Tab
        TableGridLayout                 matlab.ui.container.GridLayout
        StopTableButton                 matlab.ui.control.Button
        TableNewAngle                   matlab.ui.control.NumericEditField
        MovetoAngleButton               matlab.ui.control.Button
        TableEndAngle                   matlab.ui.control.NumericEditField
        StartFrequectSpanMHzLabel_13    matlab.ui.control.Label
        TableStepAngle                  matlab.ui.control.NumericEditField
        StartFrequectSpanMHzLabel_12    matlab.ui.control.Label
        TableStartAngle                 matlab.ui.control.NumericEditField
        StartFrequectSpanMHzLabel_11    matlab.ui.control.Label
        ThetaSingleSweepSwitch          matlab.ui.control.Switch
        TableSpeedSliderLabel_2         matlab.ui.control.Label
        TableSpeedSlider                matlab.ui.control.Slider
        TableSpeedSliderLabel           matlab.ui.control.Label
        TowerTab                        matlab.ui.container.Tab
        TowerGridLayout                 matlab.ui.container.GridLayout
        StopTowerButton                 matlab.ui.control.Button
        TowerNewAngle                   matlab.ui.control.NumericEditField
        MoveTowertoAngleButton          matlab.ui.control.Button
        TowerEndAngle                   matlab.ui.control.NumericEditField
        StartFrequectSpanMHzLabel_18    matlab.ui.control.Label
        TowerStepAngle                  matlab.ui.control.NumericEditField
        StartFrequectSpanMHzLabel_17    matlab.ui.control.Label
        TowerStartAngle                 matlab.ui.control.NumericEditField
        StartFrequectSpanMHzLabel_16    matlab.ui.control.Label
        PhiSingleSweepSwitch            matlab.ui.control.Switch
        TableSpeedSliderLabel_3         matlab.ui.control.Label
        TowerSpeedSlider                matlab.ui.control.Slider
        TowerSpeedSliderLabel           matlab.ui.control.Label
        LinearSliderTab                 matlab.ui.container.Tab
        SliderGridLayout                matlab.ui.container.GridLayout
        StopLinearSliderButton          matlab.ui.control.Button
        SliderScan                      matlab.ui.control.Button
        SliderHoming                    matlab.ui.control.Button
        AntennaCurrentSpacing           matlab.ui.control.NumericEditField
        CurrentSpacingLabel             matlab.ui.control.Label
        LinearSliderNewPosition         matlab.ui.control.NumericEditField
        MovetoPositionButton            matlab.ui.control.Button
        LinearSliderCurrentPosition     matlab.ui.control.NumericEditField
        SliderPositioncmLabel           matlab.ui.control.Label
        SpeedPresetDropDown             matlab.ui.control.DropDown
        SpeedPresetDropDownLabel        matlab.ui.control.Label
        AntennaPhysicalSize             matlab.ui.control.NumericEditField
        AntennaOffsetLabel              matlab.ui.control.Label
        AntennaPlotTab                  matlab.ui.container.Tab
        GridLayout25                    matlab.ui.container.GridLayout
        NPortQuantityDropDown           matlab.ui.control.DropDown
        NportDropDownLabel              matlab.ui.control.Label
        PhiDropDown                     matlab.ui.control.DropDown
        PhiDropDownLabel                matlab.ui.control.Label
        ThetaDropDown                   matlab.ui.control.DropDown
        PlottingAngleLabel              matlab.ui.control.Label
        FrequencyMHzDropDown            matlab.ui.control.DropDown
        FrequencyMHzDropDownLabel_2     matlab.ui.control.Label
        GainTypeDropDown                matlab.ui.control.DropDown
        PlotTypeDropDownLabel           matlab.ui.control.Label
        SettingsTab                     matlab.ui.container.Tab
        SettingsGridLayout              matlab.ui.container.GridLayout
        TabGroup                        matlab.ui.container.TabGroup
        Instruments                     matlab.ui.container.Tab
        InstrumentSettingsGridLayout    matlab.ui.container.GridLayout
        SaveChangesButton               matlab.ui.control.Button
        DeleteInstrumentButton          matlab.ui.control.Button
        NewInstrumentButton             matlab.ui.control.Button
        InstrumentsTable                matlab.ui.control.Table
        UITab                           matlab.ui.container.Tab
        UIGridLayout                    matlab.ui.container.GridLayout
        UIColumnWidthSlider             matlab.ui.control.Slider
        UIColumnWidthSliderLabel        matlab.ui.control.Label
        ColorOrderDropDown              matlab.ui.control.DropDown
        ColorOrderDropDownLabel         matlab.ui.control.Label
        ColorMapsDropDown               matlab.ui.control.DropDown
        ColorMapsDropDownLabel          matlab.ui.control.Label
        CurrentThemeLabel               matlab.ui.control.Label
        ToogleThemeButton               matlab.ui.control.Button
        OpenLogsButton                  matlab.ui.control.Button
        ClearLogsButton                 matlab.ui.control.Button
        GridCurrentStatusLabel          matlab.ui.control.Label
        PlotGridOnOffButton             matlab.ui.control.Button
        LoadSaveConfigurationsTab       matlab.ui.container.Tab
        GridLayout26                    matlab.ui.container.GridLayout
        AntennaMeasurementConfigurationsLabel  matlab.ui.control.Label
        LoadConfigurationButton         matlab.ui.control.Button
        SaveConfigurationButton         matlab.ui.control.Button
    end


    properties (Access = private)
        %% App Specific Settings
        StoredAddresses = {};      % Cell array containing the IP adresses of the lab instruments.
        LINEAR_SLIDER_RANGE = 2    % Maximum linear slider movement range (2 meters)
        offsetSpacing = 0.8062;    % Spacing between antennas (m)
        linearSpacing              % Spacing added by linear slider (m)
        InstrumentTable            % Table storing all compatible instruments to use by the application. Users can add/remove instruments. 
    end

    properties (Access = public)
        %% Instrument Objects (For VISA SCPI commands)
        PowerSupplyA                % DC Power Supply A 
        PowerSupplyB                % DC Power Supply B
        SignalGenerator             % Signal Generator
        OutputSignalAnalyzer        % Output Signal Analyzer
        InputSignalAnalyzer         % Input Signal Analyzer
        VNA                         % Vector Network Analyzer
        EMCenter                    % Anechoic Chamber Control  
        EMSlider                    % Anechoic Chamber Linear Slider

        %% Power Amplifier Properties
        ChannelToDeviceMap          % A containers.Map linking logical channel names (e.g., 'A1') to PSU device channels (e.g., 'CH1,PSUA').
        PSUMode                     % Single, Dual, or Quad Supply Mode.
        PAFrequencyMeasurementMode  % Single frequency or sweep frequencies.
        ChannelNames                % Struct containing the names of the channels to be used by the PSU.
        FilledPSUChannels           % Cell array containing the names of the configured PSU channels that are ready for use.
        DrainChannels               % Cell array containing the channels designated as drains.
        GateChannels                % Cell array containing the channels designated as gates.
        InputSpFile                 % Path for the S2P file for input network de-embedding.
        OutputSpFile                % Path for the S2P file for output network de-embedding.
        DriverFile                  % Path for the driver configuration file containing a power amplifier characterization.
        PAMeasurementsTable         % Table storing the results of various measurements for the power amplifier.
        PA_DataTable                % Table storing the results of a test run for the power amplifier.
        PA_PSU_Channels             % Plotting property for the available PSU channels in the power amplifier test run. 
        PA_PSU_Voltages             % Plotting property for the available voltages in the power amplifier test run. 
        PA_PSU_SelectedVoltages     % Plotting property for the user selected voltages in the power amplifier test run.  
        MinimumGainSafetyState      % State of the minimum gain safety feature to cancel power sweep when gain is below threshold
        OccupiedBandwidthSafetyState% State of the excess bandwidth threshold to cancel the power sweep when the output occupied bandwidth is above the specified channel bandwidth by the given value

        %% Antenna Properties
        ReferenceGainFile           % Reference antenna boresight gain data file.
        ReferenceGainFilePath       % Reference antenna boresight gain data file path.
        Antenna_Data                % Antenna RF results data table.
        setupSpacing                % Total setup spacing between antennas accounting for linear slider and offset (m).
        RadiationPlot2DPattern      % Figure handle for the 2D radiation pattern polar plot.
    end

    methods (Access = public)
        function PSUChangeModeHandle(app)
            % Public handle function to execute callback.
            app.PSUChangeMode();
        end

        function displayError(app, ME)
            % If this function is triggered, due to a mistake ocurring in the app's code it
            % will display a simple error message to the user.
            
            if class(ME) == "MException"
                uialert(app.UIFigure, ME.message, 'Application Error', 'Icon', 'error');
            elseif class(ME) == "string"
                uialert(app.UIFigure, ME, 'Application Error', 'Icon', 'error');
            else
                disp(ME);
            end
            % Then it will log the more complex error information into an error log textfile.
            app.logError(ME)
        end

        function logError(~, ME)
            % This function is called by the displayError function. It takes in an MException 
            % object (ME), extracts the error details (message, type, stack trace, and timestamp), 
            % formats them into a readable string for the user and logs the whole error information
            % into an error log file.
            timestamp = datetime("now");
            errorLog = sprintf('[%s]\nError: %s\nIdentifier: %s\n\nStack Trace:\n', timestamp, ME.message, ME.identifier);

            for k = 1:numel(ME.stack)
                errorLog = sprintf('%sIn file: %s\nFunction: %s\nLine: %d\n\n', errorLog, ME.stack(k).file, ME.stack(k).name, ME.stack(k).line);
            end
            
            errorLog = sprintf('%s---------------------------------------------------------------------------\n', errorLog);
            
            % Define a directory called 'ARES' in the userpath.
            ARESDirectory = fullfile(userpath, 'ARES');
            errorLogFile = fullfile(ARESDirectory, 'ARES_Error_Log.txt');

            try
                % Create the ARES directory if it does not exist in the
                % user's machine.
                if ~exist(ARESDirectory, 'dir')
                    mkdir(ARESDirectory)
                end

                % Append Mode
                fileID = fopen(errorLogFile, 'a');
                if fileID == -1
                    % File cannot be accesed, create it.
                    fileID = fopen(errorLogFile, 'w');
                    if fileID == -1
                        % File cannot be opened.
                        return
                    end
                end

                fprintf(fileID, '%s', errorLog);
                fclose(fileID);
            catch
                % Silent Catch
            end
        end

        function logMeasurementTime(~, measurementType, startTime, endTime, duration, totalMeasurements)
            % This function logs the measurement time information of an RF device (PA, Antenna) to a 
            % log file. It records when the measurement started, ended, and how long it took.
           
            % Format the log entry
            logEntry = sprintf('%s Measurement Summary:\n', measurementType);
            logEntry = sprintf('%sStart Time: %s\nEnd Time: %s\n', logEntry, string(startTime), string(endTime));
            logEntry = sprintf('%sDuration: %s\n', logEntry, string(duration));

            if strcmp(measurementType, 'Antenna')
                logEntry = sprintf('%sTotal Positions Measured: %d\n', logEntry, totalMeasurements);
                logEntry = sprintf('%sAverage Time Per Position: %s\n', logEntry, string(duration/totalMeasurements));
            elseif strcmp(measurementType, 'PA')
                logEntry = sprintf('%sTotal Data Points Measured: %d\n', logEntry, totalMeasurements);
                logEntry = sprintf('%sAverage Time Per Data Point: %s\n', logEntry, string(duration/totalMeasurements));
            end

            logEntry = sprintf('%s---------------------------------------------------------------------------\n', logEntry);
            
            % Define a directory called 'ARES' in the userpath.
            ARESDirectory = fullfile(userpath, 'ARES');
            measurementLogFile = fullfile(ARESDirectory, 'ARES_Measurement_Log.txt');
            
            try
                % Create the ARES directory if it does not exist in the
                % user's machine.
                if ~exist(ARESDirectory, 'dir')
                    mkdir(ARESDirectory)
                end
                
                % Append Mode
                fileID = fopen(measurementLogFile, 'a');
                if fileID == -1
                    % File cannot be accessed, create it.
                    fileID = fopen(measurementLogFile, 'w');
                    if fileID == -1
                        % File cannot be opened.
                        return
                    end
                end
                
                fprintf(fileID, '%s', logEntry);
                fclose(fileID);
            catch
                % Silent Catch
            end
        end

        function updatePAPlotDropdowns(app)
            % This function updates the PSU channel, channel voltage, and frequency dropdowns in 
            % the GUI using the current PA data table. It extracts unique frequency values, channel
            % numbers, and voltage settings, and sets the default selections for each dropdown.
            try
                if ~isempty(app.PA_DataTable)
                    % Frequency data for the test measurement.
                    uniqueFreqs = unique(app.PA_DataTable.FrequencyMHz);
                    freqStrings = string(uniqueFreqs);
    
                    % Channels used in the PA test measurement.
                    channelStrings = string(app.PA_PSU_Channels);
                    if isempty(channelStrings)
                        channelStrings = {'None'};
                    end
                    % Update channel number dropdown.
                    app.PSUChannelDropDown.Items = channelStrings;
                    if ~isempty(channelStrings)
                        app.PSUChannelDropDown.Value = channelStrings(1);  
                    end
                    
                    % Voltage data for the selected PSU channel.
                    selectedChannel = str2double(app.PSUChannelDropDown.Value);
                    if ~isnan(selectedChannel)
                        voltages = app.PA_PSU_Voltages.(sprintf('Channel%dVoltagesV', selectedChannel));
                        voltageStrings = string(voltages); 
                    else
                        voltageStrings = {'None'};
                    end

                    % Update channel voltage dropdown.
                    app.ChannelVoltageDropDown.Items = voltageStrings;
                    app.ChannelVoltageDropDown.Value = voltageStrings(1);  

                    % Update frequency dropdown.
                    app.FrequencySingleDropDown.Items = freqStrings;
                    if ~isempty(freqStrings)
                        app.FrequencySingleDropDown.Value = freqStrings(1);
                    end
                end
            catch ME
                app.displayError(ME);
            end
        end

        function updatePSUChannelDropdowns(app)            
            % Update PSU Channel Dropdowns
            % Check which PSUs are connected
            hasPSUA = ~isempty(app.PowerSupplyA);
            hasPSUB = ~isempty(app.PowerSupplyB);

            if ~hasPSUA && ~hasPSUB
                items = {''};
                app.PowerSupplyChannelDropDown.Items = items;
                return;
            end

            items = {};
            if hasPSUA
                items = [items {'A1', 'A2'}];
            end
            if hasPSUB
                items = [items {'B1', 'B2'}];
            end

            currentValue = app.PowerSupplyChannelDropDown.Value;
            
            % Populate power supply dropdown with items
            app.PowerSupplyChannelDropDown.Items = items;
            
            % Make sure there's at least one item and set to first item if current is invalid
            if ~isempty(items)
                if isempty(currentValue) || ~ismember(currentValue, items)
                    app.PowerSupplyChannelDropDown.Value = items{1};
                else
                    app.PowerSupplyChannelDropDown.Value = currentValue;
                end
                % Change the channel if there is a valid selection
                if ~isempty(app.PowerSupplyChannelDropDown.Value)
                    PSUChangeChannel(app, []);
                end
            end
        end

        function changePSUChannelDropdown(app)            
            % Change PSU Channel
            selectedChannel = app.PowerSupplyChannelDropDown.Value;

            if isempty(selectedChannel) || ~ischar(selectedChannel)
                return;
            end

            % If the channel is new, initialize its values
            if ~isfield(app.ChannelNames, selectedChannel)
                app.ChannelNames.(selectedChannel) = struct('Current', 0, 'Start', 0, 'Stop', 0, 'Step', 0, 'Mode', 'Single');

                % New channel is drain by default
                if ~ismember(selectedChannel, [app.DrainChannels, app.GateChannels])
                    app.DrainChannels{end+1} = selectedChannel;
                    app.DrainGateSwitch.Value = 'Drain';
                end
            else
                % Set the mode switch based on saved channel mode
                if isfield(app.ChannelNames.(selectedChannel), 'Mode')
                    app.SingleSweepSwitch.Value = app.ChannelNames.(selectedChannel).Mode;
                else
                    app.SingleSweepSwitch.Value = 'Single';  % Default to single if mode not set
                    app.ChannelNames.(selectedChannel).Mode = 'Single';
                end

                % Update DrainGateSwitch based on channel designation
                if any(strcmp(selectedChannel, app.DrainChannels))
                    app.DrainGateSwitch.Value = 'Drain';
                elseif any(strcmp(selectedChannel, app.GateChannels))
                    app.DrainGateSwitch.Value = 'Gate';
                else
                    % Default to Drain if not in either list
                    app.DrainGateSwitch.Value = 'Drain';
                    app.DrainChannels{end+1} = selectedChannel;
                end

                % Call the SingleSweepSwitch function to update UI visibility
                PSUChangeSingleSweepVoltages(app, []);
            end

            % Load saved values into UI edit fields
            app.SupplyCurrent.Value = app.ChannelNames.(selectedChannel).Current;
            app.StartVoltage.Value = app.ChannelNames.(selectedChannel).Start;
            app.StopVoltage.Value = app.ChannelNames.(selectedChannel).Stop;


        end
        
        function updateAntennaPlotDropdowns(app)
            % This function updates the antenna plot dropdown menus in the GUI. It extracts the unique
            % frequency, theta, and phi values from the antenna data table and uses them to populate the 
            % corresponding dropdowns, setting the first item in each as the default selection.
            try
                if ~isempty(app.Antenna_Data)
                    % Get unique values from the data to fill in the 
                    % dropdown menus.
                    uniqueFreqs = unique(app.Antenna_Data.FrequencyMHz);
                    uniqueTheta = unique(app.Antenna_Data.Thetadeg);
                    uniquePhi = unique(app.Antenna_Data.Phideg);
                    
                    % Convert data parameters to string arrays.
                    freqStrings = string(uniqueFreqs);
                    thetaStrings = string(uniqueTheta);
                    phiStrings = string(uniquePhi);
                    
                    % Update the dropdown items and their values.
                    app.FrequencyMHzDropDown.Items = freqStrings;
                    app.FrequencyMHzDropDown.Value = freqStrings(1);
                    app.ThetaDropDown.Items = thetaStrings;
                    app.ThetaDropDown.Value = thetaStrings(1);
                    app.PhiDropDown.Items = phiStrings;
                    app.PhiDropDown.Value = phiStrings(1);
                end
            catch ME
                app.displayError(ME);
            end
        end

        function setupContextMenuForPlots(app)
            % Get all the axis in the ARES application.
            ARESAxes = matlab.ui.control.UIAxes.empty;
            appProps = properties(app);

            for i = 1:length(appProps)
                propVal = app.(appProps{i});
                if propVal == app.RadiationPlot3DPattern
                     continue;
                elseif isa(propVal, 'matlab.ui.control.UIAxes') || isa(propVal, 'matlab.graphics.axis.PolarAxes')
                    ARESAxes(end+1) = propVal; %#ok<AGROW>
                end
            end

            % Go through each axes and add context menus.
            for i = 1:length(ARESAxes)
                ax = ARESAxes(i);
                cm = uicontextmenu(app.UIFigure);
                ax.ContextMenu = cm;
        
                % Add export options
                formats = {'png', 'jpg', 'pdf'};
                for f = 1:length(formats)
                    uimenu(cm, 'Text', ['Export as ', upper(formats{f})], 'MenuSelectedFcn', @(src, event) exportPlots(app, ax, formats{f}));
                end
        
                % TikZ is only supported for non-PolarAxes.
                if ~isa(ax, 'matlab.graphics.axis.PolarAxes')
                    uimenu(cm, 'Text', 'Export as TikZ', 'MenuSelectedFcn', @(src, event) exportPlots(app, ax, 'tikz'));
                end
            end
        end

        function exportPlots(app, axesComponent, format)
            % This function exports a given plot (axes component) to a specified file format. Supported formats
            % include PNG, JPG, PDF, and TikZ. It opens a save dialog, exports the plot accordingly, and notifies
            % the user upon success. 

            switch format
                case 'png'
                    ext = '*.png';
                    title = 'Save Plot as PNG';
                case 'jpg'
                    ext = '*.jpg';
                    title = 'Save Plot as JPG';
                case 'pdf'
                    ext = '*.pdf';
                    title = 'Save Plot as PDF';
                case 'tikz'
                    ext = '*.tex';
                    title = 'Save Plot as TikZ';
                    if ~exist('matlab2tikz', 'file')
                        uialert(app.UIFigure, 'The matlab2tikz package is required but was not found.', 'Package Missing', 'Icon', 'warning');
                        return;
                    end
            end

            % Open save dialog
            [filename, pathname] = uiputfile(ext, title);
            if isequal(filename, 0) || isequal(pathname, 0)
                return;
            end

            fullpath = fullfile(pathname, filename);

            try
                % For non-tikz formats, use exportgraphics directly
                if ~strcmp(format, 'tikz')
                    if strcmp(format, 'pdf')
                        exportgraphics(axesComponent, fullpath, 'ContentType', 'vector');
                    else
                        exportgraphics(axesComponent, fullpath, 'Resolution', 300);
                    end
                else
                    % Check if it's a polar plot or unsupported for TikZ
                    if isa(axesComponent, 'matlab.graphics.axis.PolarAxes') || isequal(axesComponent, app.RadiationPlot2DPattern)
                        uialert(app.UIFigure, 'TikZ export is currently not supported for polar plots. Please select another format.', ...
                            'Unsupported Plot Type', 'Icon', 'warning');
                        return;
                    end
                
                    tempFigure = figure('Visible', 'off');
                    tempAxis = axes(tempFigure);
                    copyobj(axesComponent.Children, tempAxis);

                    tempAxis.XLabel.String = axesComponent.XLabel.String;
                    tempAxis.YLabel.String = axesComponent.YLabel.String;
                    tempAxis.Title.String = axesComponent.Title.String;
                    tempAxis.XLim = axesComponent.XLim;
                    tempAxis.YLim = axesComponent.YLim;

                    % Export to TikZ.
                    % matlab2tikz grabs the latest figure in this case
                    % tempAxis.
                    matlab2tikz('filename', fullpath, 'standalone', true, 'showInfo', false);
                    close(tempFigure);
                end

                uialert(app.UIFigure, ['Plot exported successfully as ', upper(format), '.'], 'Export Complete', 'Icon', 'success');
            catch ME
                app.displayError(ME);
            end
        end
    end
    

    methods (Access = private)
        function connectInstruments(app, instrumentNames, instrumentConnections)
            % This function establishes a connection to a set of instruments using their VISA resource names. It iterates through 
            % the provided instrument names and resources, checks if the instrument is enabled for connection, and attempts to connect 
            % using MATLAB’s visadev function. Upon successful connection, the function updates the UI with the connection status and 
            % device information; if the connection fails, it displays an error message.
            for i = 1:numel(instrumentNames)
                instrumentName = instrumentNames{i};
                instrumentResource = instrumentConnections{i};
                dropdownFieldName = strcat(instrumentName, 'DropDown');
                statusLabelField = strcat(instrumentName, 'StatusLabel'); 

                if strcmp(app.(dropdownFieldName).Enable, 'on')
                    if ~isempty(instrumentResource) && ~strcmp(instrumentResource, 'NA')
                        try
                            app.(instrumentName) = aresConnectInstrument(instrumentName, instrumentResource);
                            app.(dropdownFieldName).Enable = 'off';
                            idn = writeread(app.(instrumentName), '*IDN?');

                            % Update status label to show success.
                            if strcmp(instrumentName, 'EMCenter')
                                idnParts = split(idn, ' ');
                                app.(statusLabelField).Text = sprintf("Connected to %s", idnParts{3});
                            elseif strcmp(instrumentName, 'EMSlider')
                                app.(statusLabelField).Text = "Connected to EMSlider";
                            else
                                idnParts = split(idn, ",");  
                                app.(statusLabelField).Text = sprintf("Connected to %s", idnParts{2});
                            end
                        catch ME
                            % Update status label to show failure.
                            app.(statusLabelField).Text = "Failed";
                            if strcmp(ME.identifier,'instrument:interface:visa:unableToDetermineInterfaceType')
                                app.(statusLabelField).Text = "Instrument Unavailable";
                                uialert(app.UIFigure, 'Failed to connect. Check the network settings and selected addresses.', 'Error', 'Icon', 'warning');
                            else
                                app.displayError(ME);
                            end
                        end
                    else
                        % Update status label if "None: NA" is selected.
                        app.(statusLabelField).Text = "Not Connected";
                    end
                end
            end
        end

        function disconnectInstruments(app, instrumentNames, instrumentConnections)
            % This function disconnects a set of instruments. It follows the reverse logic of connectInstruments.
            % For each instrument, it checks if it exists, disconnects it, updates the UI status, and re-enables
            % the dropdown for future connections.

             for i = 1:numel(instrumentConnections)
                 instrumentName = instrumentNames{i};
                 dropdownFieldName = strcat(instrumentName, 'DropDown');
                 statusLabelField = strcat(instrumentName, 'StatusLabel');
                 
                 if ~isempty(app.(instrumentName))
                     try
                         % Clear the instrument app reference.
                        app.(instrumentName) = [];

                        % Flush the buffer before closing if applicable.
                        if ismethod(app.(instrumentName), 'flush')
                            flush(app.(instrumentName));
                        end
                          
                        % Now we re-enable the dropdowns for future connections.
                        app.(dropdownFieldName).Enable = 'on';

                        % And update the status label to let the user know
                        % the instrument was disconnected.
                        app.(statusLabelField).Text = "Disconnected";
                     catch ME
                         app.displayError(ME);
                     end
                 else
                     % Ensure dropdown is enabled even if an instrument was
                     % already disconnected.
                     app.(dropdownFieldName).Enable = 'on';
                     app.(statusLabelField).Text = "Not Connected";
                 end
             end                     
        end

        function loadInstrumentAddressestoApp(app)
            % Load from instrumentAddresses.csv which contains the lab 
            % instruments and their respective IP addresses.

            ARESDirectory = fullfile(userpath, 'ARES');
            filePath = fullfile(ARESDirectory, 'instrumentAddresses.csv');

            % Get the root directory of the project dynamically (assumes this script is in the root folder)
            projectRootDir = fileparts(mfilename('fullpath'));  % Get directory of the current script
            
            % Define the backup file path dynamically within the 'src/support' folder
            backupfilePath = fullfile(projectRootDir, 'support', 'instrumentAddresses.csv');

            % CHeck if the ARES directory exists.
            if ~exist(ARESDirectory, 'dir')
                mkdir(ARESDirectory);
            end

            % If not in startup, check the ARES directory for the file
            if ~exist(filePath, 'file')
                % If the file doesn't exist in the ARES directory, copy it from the backup
                if exist(backupfilePath, 'file')
                    copyfile(backupfilePath, filePath);
                else
                    % If backup file doesn't exist, alert the user
                    error('Backup instrumentAddresses.csv not found in the current directory.');
                end
            end

            dataTable = readtable(filePath, Delimiter= ',');
            app.InstrumentTable = dataTable;
        
            % Set data into the InstrumentsTable for user visualization 
            % and editing.
            app.InstrumentsTable.Data = sortrows(dataTable);
            
            % Populate each dropdown with ONLY the instruments whose Type matches that
            % slot (VNA dropdown shows only VNAs, etc.), preventing the wrong instrument
            % type from being connected to a slot.
            InstrumentDropdowns = { ...
                app.PowerSupplyADropDown,         "PSU"; ...
                app.PowerSupplyBDropDown,         "PSU"; ...
                app.SignalGeneratorDropDown,      "Generator"; ...
                app.OutputSignalAnalyzerDropDown, "Analyzer"; ...
                app.InputSignalAnalyzerDropDown,  "Analyzer"; ...
                app.VNADropDown,                  "VNA"; ...
                app.EMCenterDropDown,             "Chamber"; ...
                app.EMSliderDropDown,             "Slider"};

            for idx = 1:size(InstrumentDropdowns, 1)
                currentDropdown       = InstrumentDropdowns{idx, 1};
                currentDropdown.Items = instrumentDropdownItems(dataTable, InstrumentDropdowns{idx, 2});
                currentDropdown.Value = 'NA: None';
            end
        end
    end

    % Callbacks that handle component events
    methods

        % Code that executes after component creation
        function startupFcn(app)
            % Handle UI settings.
            % app.UIFigure.WindowState = 'maximized';
            % drawnow;
            
            % Add paths for application support functions.
            addpath(genpath(fileparts(which(class(app)))));

            % Load instrument addresses to text file.
            app.loadInstrumentAddressestoApp();

            % Set panel borders for panels.
            app.PATestSettingsPanel.BorderType = 'line';
            app.AntTestSettingsPanel.BorderType = 'line';

            % Initialize PA-specific settings.
            app.PSUMode = 'No Supply';
            app.PAChangeCalibrationMode();
            app.PAChangeFrequencyMeasurementMode();
            app.ChannelNames = struct();
            app.ChannelToDeviceMap = containers.Map({'A1', 'A2', 'B1', 'B2'}, {'CH1,PSUA', 'CH2,PSUA', 'CH1,PSUB', 'CH2,PSUB'});

            % Initialize Antenna-specific settings.
            app.RadiationPlot2DPattern = polaraxes(app.AntPatternGridLayout);
            app.RadiationPlot2DPattern.Units = "pixels";
            app.RadiationPlot2DPattern.Layout.Row = 2;
            app.RadiationPlot2DPattern.Layout.Column = 2;  
            app.RadiationPlot2DPattern.Title.String = '2D Radiation Pattern';

            % Load Colormaps
            % Default color order for line plots
            builtinColorOrders = {'default', 'gem', 'gem12', 'glow', 'glow12', 'sail', 'reef', 'meadow', 'dye', 'earth'};

            % Get colormap list for 3D surfaces
            try
                cmaps = colormaplist;
            catch
                cmaps = [];
            end
            cmaps = ['default'; cmaps];

            % Load Items into dropdowns
            app.ColorMapsDropDown.Items = cmaps;
            app.ColorOrderDropDown.Items = builtinColorOrders;

            % Setup context menu for plots.
            app.setupContextMenuForPlots();

            % Default Safety options
            app.MinimumGainSafetyState = true;
            app.OccupiedBandwidthSafetyState = true;

            % Update Label
            app.CurrentThemeLabel.Text = strcat("Current Theme: ", app.UIFigure.Theme.BaseColorStyle);

        end

        % Button pushed function: PAConnectButton
        function PAConnectInstruments(app, event)
            try
                % Names of instruments and their corresponding resource addresses.
                instrumentNames = {'PowerSupplyA', 'PowerSupplyB', 'SignalGenerator', 'OutputSignalAnalyzer', 'InputSignalAnalyzer'};
                instrumentResources = {app.PowerSupplyADropDown.Value,app.PowerSupplyBDropDown.Value, ...
                    app.SignalGeneratorDropDown.Value, app.OutputSignalAnalyzerDropDown.Value, app.InputSignalAnalyzerDropDown.Value};
                
                % Regular expression to extract the connection type (TCP, USB, GPIB).
                pattern = '(TCP|USB|GPIB)[^ ]*';
    
                % Extracts the connection address for each instrument.
                for i = 1:length(instrumentResources)
                    instrumentResources{i} = regexp(instrumentResources{i}, pattern, 'match', 'once');
                end
                
                app.connectInstruments(instrumentNames, instrumentResources);
            catch ME
                app.displayError(ME);
            end
        end

        % Button pushed function: PADisconnectButton
        function PADisconnectInstruments(app, event)
            try
                % Names of the instruments to disconnect.
                instrumentNames = {'PowerSupplyA', 'PowerSupplyB', 'SignalGenerator', 'OutputSignalAnalyzer', 'InputSignalAnalyzer'};
    
                % Current connections for each instrument.
                instrumentConnections = {app.PowerSupplyA, app.PowerSupplyB, app.SignalGenerator, app.OutputSignalAnalyzer, app.InputSignalAnalyzer};
    
                app.disconnectInstruments(instrumentNames, instrumentConnections)
            catch ME
                app.displayError(ME);
            end
        end

        % Value changed function: PowerSupplyModeDropDown
        function PSUChangeMode(app, event)
            newMode = app.PowerSupplyModeDropDown.Value; 

            % The default value of app.PSUMode is 'No Supply' for safety.
            if isempty(newMode)
                app.PSUMode = 'No Supply';
            else
                app.PSUMode = newMode;
            end

            % If the mode changes to 'No Supply' all input parameters to
            % the PSU are disabled to the user.
            switch newMode
                case 'No Supply'
                    app.SupplyCurrent.Enable = 'off';
                    app.StartVoltage.Enable = 'off';
                    app.StopVoltage.Enable = 'off';
                    app.StepVoltage.Enable = 'off';
                otherwise
                    app.SupplyCurrent.Enable = 'on';
                    app.StartVoltage.Enable = 'on';
                    app.StopVoltage.Enable = 'on';
                    app.StepVoltage.Enable = 'on';
            end

            app.PSUChannelDropDownOpening();


            updatePSUChannelDropdowns(app)
        end

        % Value changed function: PowerSupplyChannelDropDown
        function PSUChangeChannel(app, event)
            changePSUChannelDropdown(app)
        end

        % Drop down opening function: PowerSupplyChannelDropDown
        function PSUChannelDropDownOpening(app, event)
            updatePSUChannelDropdowns(app)
        end

        % Value changed function: SupplyCurrent
        function PSUSetLimitingCurrent(app, event)
            % Sets the limiting current for the selected power supply channel.

            selectedChannel = app.PowerSupplyChannelDropDown.Value;

            if isfield(app.ChannelNames, selectedChannel)
                app.ChannelNames.(selectedChannel).Current = app.SupplyCurrent.Value;
            end 

            populatePSUChannels(app);        
        end

        % Value changed function: StartVoltage
        function PSUSetStartVoltage(app, event)
            % Set the start voltage for the selected power supply channel.

            selectedChannel = app.PowerSupplyChannelDropDown.Value;

            if isfield(app.ChannelNames, selectedChannel)
                app.ChannelNames.(selectedChannel).Start = app.StartVoltage.Value;
            end   

            populatePSUChannels(app); 
        end

        % Value changed function: StepVoltage
        function PSUSetStepVoltage(app, event)
            % Set the step voltage for the selected power supply channel.

            selectedChannel = app.PowerSupplyChannelDropDown.Value;

            if isfield(app.ChannelNames, selectedChannel)
                app.ChannelNames.(selectedChannel).Step = app.StepVoltage.Value;
            end 

            populatePSUChannels(app);
        end

        % Value changed function: StopVoltage
        function PSUSetStopVoltage(app, event)
            % Set the stop voltage for the selected power supply channel.

            selectedChannel = app.PowerSupplyChannelDropDown.Value;

            if isfield(app.ChannelNames, selectedChannel)
                app.ChannelNames.(selectedChannel).Stop = app.StopVoltage.Value;
            end 

            populatePSUChannels(app);    
        end

        % Value changed function: SingleSweepSwitch
        function PSUChangeSingleSweepVoltages(app, event)
            channelFunction = app.SingleSweepSwitch.Value;
            selectedChannel = app.PowerSupplyChannelDropDown.Value;

            % Update GUI based on single PSU value or sweep PSU values.
            if strcmp(channelFunction, 'Single')
                app.SupplyCurrent.Visible = 'on';
                app.StartVoltage.Enable = 'on';
                app.StopVoltage.Enable = 'off';
                app.StepVoltage.Enable = 'off';
            elseif strcmp(channelFunction, 'Sweep')
                app.SupplyCurrent.Visible = 'on';
                app.StartVoltage.Enable = 'on';
                app.StopVoltage.Enable = 'on';
                app.StepVoltage.Enable = 'on';
            end
    
            % Check that the selected channel is filled otherwise do not
            % store the mode selection into the channel configuration.
            if isempty(selectedChannel)
                return;
            end
            
            % Store the mode selection into the channel configuration.
            if isfield(app.ChannelNames, selectedChannel)
                app.ChannelNames.(selectedChannel).Mode = channelFunction;
            end
        end

        % Value changed function: DrainGateSwitch
        function PSUChangeDrainGate(app, event)
            channelDesignation = app.DrainGateSwitch.Value;
            selectedChannel = app.PowerSupplyChannelDropDown.Value;

            if isempty(selectedChannel)
                return;
            end

            if strcmp(channelDesignation, 'Drain')
                app.DrainChannels = unique([app.DrainChannels, {selectedChannel}]);
                app.GateChannels = setdiff(app.GateChannels, {selectedChannel});
            elseif strcmp(channelDesignation, 'Gate')
                app.GateChannels = unique([app.GateChannels, {selectedChannel}]);
                app.DrainChannels = setdiff(app.DrainChannels, {selectedChannel});
            end
        end

        % Value changed function: MeasurementTypeDropDown
        function PAChangeFrequencyMeasurementMode(app, event)
            % Update the GUI based on what the user selects for the PA test
            % either: a single frequency or sweep frequencies test run. 

            if strcmp(app.MeasurementTypeDropDown.Value, 'Single Frequency')
                app.EndFrequency.Enable = 'off';
                app.EndFrequencyMHzLabel.Enable = 'off';
                app.StepFrequency.Enable = 'off';
                app.StepFrequencyMHzEditFieldLabel.Enable = 'off';
            elseif strcmp(app.MeasurementTypeDropDown.Value, 'Sweep Frequencies')
                app.EndFrequency.Enable = 'on';
                app.EndFrequencyMHzLabel.Enable = 'on';
                app.StepFrequency.Enable = 'on';
                app.StepFrequencyMHzEditFieldLabel.Enable = 'on';
            end

            app.PAFrequencyMeasurementMode = app.MeasurementTypeDropDown.Value;
        end

        % Value changed function: CalibrationModeDropDown
        function PAChangeCalibrationMode(app, event)
            % Updates GUI elements for the calibration panel in the PA
            % window based on the selected calibration mode.

            switch app.CalibrationModeDropDown.Value
                case 'None'
                    app.InputAttenuationValueField.Enable = 'off';
                    app.OutputAttenuationValueField.Enable = 'off';
                    app.LoadInputSmallSignalButton.Enable = 'off';
                    app.LoadOuputSmallSignalButton.Enable = 'off';
                    app.LoadLargeSignalDriverResponseButton.Enable = 'off';
                case 'Fixed Attenuation'
                    app.InputAttenuationValueField.Enable = 'on';
                    app.OutputAttenuationValueField.Enable = 'on';
                    app.LoadInputSmallSignalButton.Enable = 'off';
                    app.LoadOuputSmallSignalButton.Enable = 'off';
                    app.LoadLargeSignalDriverResponseButton.Enable = 'off';
                case 'Small Signal'
                    app.InputAttenuationValueField.Enable = 'on';
                    app.OutputAttenuationValueField.Enable = 'on';
                    app.LoadInputSmallSignalButton.Enable = 'on';
                    app.LoadOuputSmallSignalButton.Enable = 'on';
                    app.LoadLargeSignalDriverResponseButton.Enable = 'off';
                case 'Small + Large Signal'
                    app.InputAttenuationValueField.Enable = 'on';
                    app.OutputAttenuationValueField.Enable = 'on';
                    app.LoadInputSmallSignalButton.Enable = 'on';
                    app.LoadOuputSmallSignalButton.Enable = 'on';
                    app.LoadLargeSignalDriverResponseButton.Enable = 'on';
                case 'In-Situ Couplers'
                    app.InputAttenuationValueField.Enable = 'on';
                    app.OutputAttenuationValueField.Enable = 'on';
                    app.LoadInputSmallSignalButton.Enable = 'on';
                    app.LoadOuputSmallSignalButton.Enable = 'on';
                    app.LoadLargeSignalDriverResponseButton.Enable = 'off';

            end
        end

        % Button pushed function: LoadInputSmallSignalButton
        function LoadSmallSignalInputS2PFile(app, event)
            insituMode = strcmp(app.CalibrationModeDropDown.Value, 'In-Situ Couplers');
            
            if insituMode == false
                % Prompt the user to select an S2P file for input.
                [file, path] = uigetfile('*.s2p', 'Select Input S-Parameter File');
            elseif insituMode
                % Prompt the user to select an S2P, S3P, or S4P file for input.
                [file, path] = uigetfile({'*.s2p;*.s3p;*.s4p', 'Touchstone File (*.s2p, *.s3p, *.s4p)'}, 'Select Input Coupler S-Parameter File');
            end

            % Check if the user canceled the file selection.
            if isequal(file, 0)
                return;
            end

            filePath = fullfile(path, file);

            try
                % The app expects the S2P file to be in linear magnitude
                % format so we read the file and check the file header.
                fid = fopen(filePath, 'r');
                isLinMagFormat = false;

                for i = 1:20
                    if ~feof(fid)
                        line = fgetl(fid);
                        cleanLine = regexprep(line, '\s+', '');

                        if contains(upper(cleanLine), '#HZSMAR')
                            isLinMagFormat = true;
                            break;
                        end
                    else
                        break
                    end
                end
                fclose(fid);

                % For verification purposes we call sparameters().
                testFile = sparameters(filePath);

                % If the file is in dB format, then we convert it.
                if ~isLinMagFormat
                    % Creates a new filename to let the user know this is 
                    % the linear magnitude version. 
                    [~, basename] = fileparts(file);
                    linearFileName = fullfile(path, [basename '_linear.s2p']);

                    % With rfwrite we modify the format from 'DB' to 'MA'.
                    rfwrite(testFile, linearFileName, 'FrequencyUnit', 'Hz', 'Format', 'MA');
 
                    filePath = linearFileName;
                    file = [basename '_linear.s2p'];
                end

                % Store the file path in the app as a property.
                app.InputSpFile = filePath;

                % Display the selected or converted filename in the app.
                app.InputSmallSignalFilenameField.Value = file;

                plotCalibration(app);
            catch ME
                app.displayError(ME)
            end
        end

        % Button pushed function: LoadOuputSmallSignalButton
        function LoadSmallSignalOutputS2PFile(app, event)
            insituMode = strcmp(app.CalibrationModeDropDown.Value, 'In-Situ Couplers');
            
            if insituMode == false
                % Prompt the user to select an S2P file for input.
                [file, path] = uigetfile('*.s2p', 'Select Output S-Parameter File');
            elseif insituMode
                % Prompt the user to select an S2P, S3P, or S4P file for input.
                [file, path] = uigetfile({'*.s2p;*.s3p;*.s4p', 'Touchstone File (*.s2p, *.s3p, *.s4p)'}, 'Select Output Coupler S-Parameter File');
            end

            % Check if the user canceled the file selection.
            if isequal(file, 0)
                return;
            end

            filePath = fullfile(path, file);

            try
                % The app expects the S2P file to be in linear magnitude
                % format so we read the file and check the file header.
                fid = fopen(filePath, 'r');
                isLinMagFormat = false;

                for i = 1:20
                    if ~feof(fid)
                        line = fgetl(fid);
                        cleanLine = regexprep(line, '\s+', '');

                        if contains(upper(cleanLine), '#HZSMAR')
                            isLinMagFormat = true;
                            break;
                        end
                    else
                        break
                    end
                end
                fclose(fid);

                % For verification purposes we call sparameters().
                testFile = sparameters(filePath);

                % If the file is in dB format, then we convert it.
                if ~isLinMagFormat
                    % Creates a new filename to let the user know this is 
                    % the linear magnitude version. 
                    [~, basename] = fileparts(file);
                    linearFileName = fullfile(path, [basename '_linear.s2p']);

                    % With rfwrite we modify the format from 'DB' to 'MA'.
                    rfwrite(testFile, linearFileName, 'FrequencyUnit', 'Hz', 'Format', 'MA');
 
                    filePath = linearFileName;
                    file = [basename '_linear.s2p'];
                end

                % Store the file path in the app as a property.
                app.OutputSpFile = filePath;
                % Display the selected filename in the app.
                app.OutputSmallSignalFilenameField.Value = file;

                plotCalibration(app);
            catch ME
                app.displayError(ME)
            end
        end

        % Button pushed function: LoadLargeSignalDriverResponseButton
        function LoadLargeSignalDriverResponseFile(app, event)
            % Prompt the user to select an S2P file for input.
            [file, path] = uigetfile({'*.xlsx;*.xls;*.csv', 'Data Files (*.xlsx, *.xls, *.csv)'}, 'Select Driver File');

            % Check if the user canceled the file selection.
            if isequal(file, 0)
                return;
            end

            filePath = fullfile(path, file);

            try
                % For verification purposes we call readtable().
                driverData = readtable(filePath, 'VariableNamingRule', 'preserve');

                requiredColumns = {'Frequency (MHz)', 'RF Input Power (dBm)', 'Gain'};
                for i = 1:length(requiredColumns)
                    if ~any(strcmp(driverData.Properties.VariableNames, requiredColumns{i}))
                        error('Missing required column: %s', requiredColumns{i});
                    end
                end

                app.DriverFile = filePath;

                app.LargeSignalDriverResponseFilenameField.Value = file;
            catch ME
                app.displayError(ME)
            end
        end

        % Button pushed function: StartPAMeasurement
        function PAStartMeasurement(app, event)
            % This function validates the PA relevant settings for a test. The function then calls 
            % the runPAMeasurement function to start the antenna pattern measurement.
            
            try
                % Validate the channel configuration first.
                if ~validatePSUChannels(app)
                    return;
                end
    
                runPAMeasurement(app);
            catch ME
                app.displayError(ME);
            end
        end

        % Button pushed function: LoadPAData
        function PALoadData(app, event)
            % This function handles the loading of PA measurement data into the application. It expects the data to 
            % follow a specific format, and stores it internally in the app for plotting. If the file is not selected
            % or contains no data, the function exits.

            try
                % Load the PA data into the app.
                loadData(app, 'PA');

                % Check if the uploaded file is empty, or if the user
                % canceled the file selection.
                if isempty(app.PA_DataTable)
                    return;
                end
            catch ME
                app.displayError(ME);
            end
        end

        % Value changed function: PSUChannelDropDown
        function PSUChannelValueChanged(app, event)
            % This function is triggered when the user selects a different PSU channel from the dropdown. It updates the list of 
            % available voltages for the selected channel, and sets the dropdown to reflect the currently selected voltage for 
            % that channel.

            % Convert the selected channel number to a numeric value.
            ch = str2double(string(app.PSUChannelDropDown.Value));

            % Update the voltage dropdown items and set the voltage 
            % dropdown value to the current selection for that channel.
            app.ChannelVoltageDropDown.Items = string(app.PA_PSU_Voltages.(sprintf('Channel%dVoltagesV', ch)));
            app.ChannelVoltageDropDown.Value = string(app.PA_PSU_SelectedVoltages(ch));
        end

        % Value changed function: FrequencySingleDropDown
        function PASingleFrequencyValueChanged(app, event)
            % This function is triggered when the user selects a different frequency from the PA frequency dropdown.

            % It re-plots the single frequency PA measurement and the sweep
            % measurement related to the selected frequency.
            try
                mode = detectPAMeasurementType(app.PA_DataTable.Properties.VariableNames);
                if mode == "CW"
                    plotPASingleMeasurement(app);
                    plotPADCMeasurement(app);
                elseif mode == "Modulated"
                    plotPAModulatedMeasurement(app);
                    plotPADCMeasurement(app);
                elseif mode == "Unknown"
                    app.displayError("Unknown PA data format which not contains the expected columns.")
                end
            catch ME
                
                app.displayError(ME);
            end
        end

        % Value changed function: ChannelVoltageDropDown
        function PAChannelVoltageValueChanged(app, event)
            % This function is triggered when the user selects a different voltage for a PSU channel.

            % Convert the selected channel number to a numeric value.
            ch = str2double(string(app.PSUChannelDropDown.Value));

            % Update the selected voltage for the corresponding channel and
            % re-plot the measurement to reflect the voltage change.
            app.PA_PSU_SelectedVoltages(ch) = str2double(string(app.ChannelVoltageDropDown.Value));
            
            try
            mode = detectPAMeasurementType(app.PA_DataTable.Properties.VariableNames);
                if mode == "CW"                
                    plotPASingleMeasurement(app);
                    plotPASweepMeasurement(app);
                    plotPADCMeasurement(app);
                elseif mode == "Modulated"
                    plotPAModulatedMeasurement(app);
                    plotPADCMeasurement(app);
                elseif mode == "Unknown"
                    app.displayError("Unknown PA data format which not contains the expected columns.")
                end

            catch ME
                app.displayError(ME);
            end
        end

        % Button pushed function: AntennaConnectButton
        function AntennaConnectInstruments(app, event)
            % This function handles the connection of the application to the antenna measurement instruments
            % (Vector Network Analyzer (VNA) and EMCenter). The user selects the appropriate instrument addresses via a dropdown menu, 
            % and the function uses these selections to establish connections. If successful, the instruments are ready for subsequent 
            % commands and data acquisition.      
            
            %instrumentResources = {'TCPIP0::192.168.1.113::hislip0::INSTR', 'TCPIP0::192.168.2.150::inst0::INSTR'}; 
            instrumentNames = {'VNA', 'EMCenter', 'EMSlider'};
            instrumentResources = {app.VNADropDown.Value, app.EMCenterDropDown.Value, app.EMSliderDropDown.Value};
            
            pattern = '(TCP|USB)[^ ]*';
            
            for i = 1:length(instrumentResources)
                instrumentResources{i} = regexp(instrumentResources{i}, pattern, 'match', 'once');
            end
            
            app.connectInstruments(instrumentNames, instrumentResources);

            if ~isempty(app.VNA)
                app.VNAStartFrequency.Value = str2double(writeread(app.VNA, ':SENSe:FREQuency:STARt?')) / 1E6;
                app.VNAEndFrequency.Value = str2double(writeread(app.VNA, ':SENSe:FREQuency:STOP?')) / 1E6;
                app.VNASweepPoints.Value = str2double(writeread(app.VNA, ':SENSe:SWEep:POINts?'));

                % Delete any existing measurements on the VNA.
                writeline(app.VNA, 'CALC:PAR:DEL:ALL');
            
                % Create two windows on the VNA.
                writeline(app.VNA, 'DISP:WIND1:STATE ON');
                writeline(app.VNA, 'DISP:WIND2:STATE ON');
            
                measLabels = {'S11', 'S21', 'S22'};
                
                % Create and display magnitude and phase measurements in
                % the two windows.
                for i = 1:length(measLabels)
                    % Magnitude Measurements LogM (dB)
                    writeline(app.VNA, sprintf('CALC1:PAR:DEF:EXT "Meas%d",%s', i, measLabels{i}));
                    writeline(app.VNA, sprintf('DISP:WIND1:TRAC%d:FEED "Meas%d"', i, i));

                    % Phase Measurements (deg)
                    writeline(app.VNA, sprintf('CALC1:PAR:DEF:EXT "Phase%d",%s', i, measLabels{i}));
                    writeline(app.VNA, sprintf('DISP:WIND2:TRAC%d:FEED "Phase%d"', i, i));
                    writeline(app.VNA, sprintf('CALC1:PAR:SEL "Phase%d"', i));
                    writeline(app.VNA, 'CALC1:FORM PHAS');
                end
            end

            if ~isempty(app.EMSlider)
                % Get current position from Linear Slider.
                app.LinearSliderCurrentPosition.Value = str2double(writeread(app.EMSlider, 'AXIS1:CP?'));
                app.AntennaCurrentSpacing.Value = app.LINEAR_SLIDER_RANGE + app.offsetSpacing - app.LinearSliderCurrentPosition.Value/100;
                app.setupSpacing = app.AntennaCurrentSpacing.Value;

                % Enable Linear Slider GUI interface
                app.AntennaCurrentSpacing.Enable = 'on';
                app.LinearSliderCurrentPosition.Enable = 'on';
                app.SpeedPresetDropDown.Enable = 'on';
                app.LinearSliderNewPosition.Enable = 'on';
            end
        end

        % Button pushed function: AntennaDisconnectButton
        function AntennaDisconnectInstruments(app, event)
            % This function handles the disconnection of instruments (VNA, EMCenter, EMSlider) from the
            % app when user presses the disconnect button on the antenna instruments panel.

            instrumentNames = {'VNA', 'EMCenter', 'EMSlider'};
            instrumentConnections = {app.VNA, app.EMCenter, app.EMSlider};
            app.disconnectInstruments(instrumentNames, instrumentConnections)
        end

        % Value changed function: PhiSingleSweepSwitch
        function PhiChangeSingleSweepAngles(app, event)
            % This function is triggered when the user changes the value of the Phi Single/Sweep
            % Switch component. Based on the value, it enables or disables the Phi angle
            % controls for step and end angles.

            mode = app.PhiSingleSweepSwitch.Value;

            if strcmp(mode, 'Sweep')
                app.TowerStepAngle.Enable = "on";
                app.TowerEndAngle.Enable = "on";
            else
                app.TowerStepAngle.Enable = "off";
                app.TowerEndAngle.Enable = "off";
            end
        end

        % Value changed function: ThetaSingleSweepSwitch
        function ThetaChangeSingleSweepSwitchAngles(app, event)
            % This function is triggered when the user changes the value of the Theta Single/Sweep
            % Switch component. Based on the value, it enables or disables the Theta angle
            % controls for step and end angles.

            mode = app.ThetaSingleSweepSwitch.Value;

            if strcmp(mode, 'Sweep')
                app.TableStepAngle.Enable = "on";
                app.TableEndAngle.Enable = "on";
            else
                app.TableStepAngle.Enable = "off";
                app.TableEndAngle.Enable = "off";
            end

        end

        % Value changed function: SmoothingPoints
        function VNAChangeSmoothingPoints(app, event)
            % This function is triggered when the user changes the smoothing percentage value 
            % for the VNA in the app.

            app.SmoothingPoints.Value = app.SmoothingPoints.Value;
        end

        % Value changed function: SpeedPresetDropDown
        function LinearSliderChangeSpeed(app, event)
            % This function updates the movement speed of the linear slider by sending a speed
            % preset command to the hardware. The speed settings are predefined as presets, with
            % values ranging from 1 (slowest) to 8 (fastest). The selected speed preset is read 
            % from the application's dropdown menu and applied directly to the slider hardware.
            
            try 
                speedPreset = str2double(app.SpeedPresetDropDown.Value);
                writeline(app.EMSlider, sprintf('AXIS1:S%d', speedPreset));
            catch ME
                app.displayError(ME);
            end
        end

        % Button pushed function: MovetoPositionButton
        function LinearSliderChangePosition(app, event)
            % This function updates the position the linear slider and dynamically adjusts
            % associated parameters based on the slider's movement. It continuously monitors
            % the slider's status to ensure the desired position is reached and updates
            % the application's calculated spacing values in real-time.
            
            try
                if isempty(app.EMSlider)
                    return;
                else
                    % Send command to linear slider to move to the specified
                    % position.
                    writeline(app.EMSlider, sprintf('AXIS1:SK %d', app.LinearSliderNewPosition.Value));
                    motion = writeread(app.EMSlider, 'AXIS1:DIR?');
                    
                    % Continuously update the setup spacing until motion is
                    % complete.
                    while strcmp(motion, '+1') || strcmp(motion, '-1')
                        motion = writeread(app.EMSlider, 'AXIS1:DIR?');
                        app.LinearSliderCurrentPosition.Value = str2double(writeread(app.EMSlider, 'AXIS1:CP?'));
                        
                        sliderPosition = app.LinearSliderCurrentPosition.Value / 100; % Convert to meters.
                        baseSpacing = app.LINEAR_SLIDER_RANGE - sliderPosition;
                        totalSpacing = baseSpacing + app.offsetSpacing;
                        
                        % Subtract antenna physical size if provided.
                        if ~isempty(app.AntennaPhysicalSize.Value)
                            totalSpacing = totalSpacing - app.AntennaPhysicalSize.Value / 100; % Convert to meters.
                        end
                        
                        % Update the displayed spacing in the GUI.
                        app.AntennaCurrentSpacing.Value = totalSpacing;
                        
                        % Small delay to prevent overwhelming the system.
                        pause(0.1);
                    end
            
                    app.setupSpacing = app.AntennaCurrentSpacing.Value;
                end
            catch ME
                app.displayError(ME);
            end
        end

        % Button pushed function: SliderScan
        function LinearSliderScanMovement(app, event)
            % This function initiates the scan mode of the linear slider, causing it to move 
            % continuously between the soft limit positions.

            try
                if isempty(app.EMSlider)
                    return;
                else
                    writeline(app.EMSlider, 'AXIS1:SCAN')
                end
            catch ME
                app.displayError(ME);
            end
        end

        % Button pushed function: SliderHoming
        function LinearSliderHomingMovement(app, event)
            % This function performs a homing operation on the linear slider to calibrate its zero
            % position. It checks whether the slider has already been homed and, if not, initiates a homing
            % sequence by directing the slider to its home sensor for proper positional alignment.

            try
                if isempty(app.EMSlider)
                    return;
                else
                    % Query if axis has been homed.
                    if str2double(writeread(app.EMSlider, 'AXIS1:ZERO?')) == 0 
                        % Seek slider home sensor.
                        writeline(app.EMSlider, 'AXIS1:HOME') 
                    end

                    % Reset the slider's current position in the GUI only
                    % if the slider is actually at position 0 cm.
                    if str2double(writeread(app.EMSlider, 'AXIS1:CP?')) == 0
                        app.LinearSliderCurrentPosition.Value = 0;
                    end
                end
            catch ME
                app.displayError(ME);
            end
        end

        % Button pushed function: StopLinearSliderButton
        function LinearSliderStopMovement(app, event)
            % This function sends a stop command to halt the movement of the linear slider. It 
            % is triggered when the user presses the stop button in the linear slider settings menu. 

            try
                if isempty(app.EMSlider)
                    return;
                else
                    % Stop the slider's movement.
                    writeline(app.EMSlider, 'AXIS1:STOP');

                    % Read the current position of the slider after 
                    % stopping.
                    currentPosition = str2double(writeread(app.EMSlider, 'AXIS1:CP?'));
                    app.LinearSliderCurrentPosition.Value = currentPosition;
        
                    % Calculate and update spacing in the GUI.
                    sliderPosition = currentPosition / 100; % Convert to meters
                    baseSpacing = app.LINEAR_SLIDER_RANGE - sliderPosition;
                    totalSpacing = baseSpacing + app.offsetSpacing;
        
                    % Subtract the antenna physical size if it's set.
                    if ~isempty(app.AntennaPhysicalSize.Value)
                        totalSpacing = totalSpacing - app.AntennaPhysicalSize.Value / 100; % Convert to meters
                    end
        
                    % Update the GUI with calculated spacing.
                    app.AntennaCurrentSpacing.Value = totalSpacing;
                    app.setupSpacing = totalSpacing;
                end
            catch ME
                app.displayError(ME);
            end
        end

        % Value changed function: AntennaPhysicalSize
        function LinearSliderApplyAntennaPhysicalOffset(app, event)
            % This function recalculates and updates the antenna spacing based on the entered physical
            % size of the antenna. It factors in the current position of the linear slider and an offset 
            % value, subtracting the antenna's physical size to ensure accurate spacing for measurement 
            % or positioning purposes.

            try 
                AntennaPhysicalSizeOffset = app.AntennaPhysicalSize.Value;
    
                % Recalculate the current spacing.
                sliderPosition = app.LinearSliderCurrentPosition.Value / 100; % Convert to meters.
                baseSpacing = app.LINEAR_SLIDER_RANGE - sliderPosition;
                totalSpacing = baseSpacing + app.offsetSpacing;
                
                % Subtract antenna physical size offset.
                if ~isempty(AntennaPhysicalSizeOffset)
                    totalSpacing = totalSpacing - AntennaPhysicalSizeOffset / 100; % Convert to meters.
                end
                
                % Update the displayed spacing.
                app.AntennaCurrentSpacing.Value = totalSpacing;
                
                % Update the setup spacing.
                app.setupSpacing = totalSpacing;
            catch ME
                app.displayError(ME);
            end
        end

        % Value changed function: TableSpeedSlider
        function TableChangeSpeed(app, event)
           % This function updates the turntable speed value in the application when the user adjusts
           % the Table Speed Slider. This function does not directly update the speed of the hardware,
           % it ensures that the application's internal settings reflect the new speed. The updated 
           % value will be used in subsequent operations involving the turntable, allowing the user
           % to control the speed without immediate hardware changes.
 
            try
                app.TableSpeedSlider.Value = app.TableSpeedSlider.Value; 
            catch ME
                app.displayError(ME);
            end
        end

        % Button pushed function: MovetoAngleButton
        function TableChangeAngle(app, event)
            % This function initiates the process of changing the turntable angle to a new value.
            % The function sends a command to set the turntable's speed and a command to adjust the 
            % turntable's angle to the user requested value.
            
            try
                writeline(app.EMCenter, sprintf('1A:SPEED %d', app.TableSpeedSlider.Value));
                writeline(app.EMCenter, sprintf('1A:SK %d', app.TableNewAngle.Value));
                status = writeread(app.EMCenter,"1A:*OPC?");
                status = str2double(strtrim(status));

                while status ~= 1
                    drawnow;
                    status = writeread(app.EMCenter,'1A:*OPC?');
                    status = str2double(strtrim(status));
                end
            catch ME
                app.displayError(ME);
            end
        end

        % Button pushed function: StopTableButton
        function TableStopMovement(app, event)
            % This function is executed when the user requests to stop the turntable movement operation.
            % It sends a stop command to the turntable to halt any rotational operation. 

            try
                writeline(app.EMCenter, '1A:ST');
            catch ME
                app.displayError(ME);
            end
        end

        % Value changed function: TowerSpeedSlider
        function TowerChangeSpeed(app, event)
           % This function updates the tower speed value in the application when the user adjusts
           % the Tower Speed Slider. This function does not directly update the speed of the hardware,
           % it ensures that the application's internal settings reflect the new speed. The updated 
           % value will be used in subsequent operations involving the turntable, allowing the user to 
           % control the speed.
 
            try
                app.TowerSpeedSlider.Value = app.TowerSpeedSlider.Value; 
            catch ME
                app.displayError(ME);
            end
        end

        % Button pushed function: MoveTowertoAngleButton
        function TowerChangeAngle(app, event)
            % This function initiates the process of moving the tower to a new angle. The function
            % sends two commands, one that sets the tower's speed and one that moves the tower's 
            % angle to the user requested value entered in the GUI.
            
            try
                writeline(app.EMCenter, sprintf('1B:SPEED %d', app.TowerSpeedSlider.Value));
                writeline(app.EMCenter, sprintf('1B:SK %d', app.TowerNewAngle.Value));
                status = writeread(app.EMCenter, "1B:*OPC?");
                status = str2double(strtrim(status));
    
                while status ~= 1
                    drawnow;
                    status = writeread(app.EMCenter, '1B:*OPC?');
                    status = str2double(strtrim(status));
                end
            catch ME
                app.displayError(ME);
            end
        end

        % Button pushed function: StopTowerButton
        function TowerStopMovement(app, event)
            % This function is executed when the user requests to stop the tower movement operation. 
            % It sends a stop command to the tower to halt any rotational operation. 

            try
                writeline(app.EMCenter, '1B:ST');
            catch ME
                app.displayError(ME);
            end
        end

        % Button pushed function: StartTestButton
        function AntennaStartMeasurement(app, event)
            % This function validates that the start and end frequencies of the VNA are set and distinct, that 
            % the number of sweep points is specified, and that the antenna physical size is provided. The 
            % function then calls the runAntennaMeasurement function to start the antenna pattern measurement. 

            try
                % Validate the antenna setup configuration first.
                if ~validateAntennaMeasurement(app)
                    return;
                end 
                
                % Set the start and stop frequencies, and the number of 
                % sweep points on the VNA.
                writeline(app.VNA, sprintf('SENS1:FREQ:START %g', app.VNAStartFrequency.Value * 1E6));
                writeline(app.VNA, sprintf('SENS1:FREQ:STOP %g', app.VNAEndFrequency.Value * 1E6));
                writeline(app.VNA, sprintf('SENS1:SWE:POIN %d', app.VNASweepPoints.Value));

                measLabels = {'S11', 'S21', 'S22'};

                % Apply smoothing to both magnitude and phase traces.
                % Magnitude S11: Trace 1
                % Phase S11: Trace 2
                % Magnitude S21: Trace 3
                % Phase S21: Trace 4
                % Magnitude S22: Trace 5
                % Phase S22: Trace 6

                traceIndex = 1;  
                for i = 1:length(measLabels)
                    % Magnitude smoothing.
                    writeline(app.VNA, sprintf('CALC1:PAR:MNUM %d', traceIndex));

                    if app.SmoothingPoints.Value ~= 0
                        writeline(app.VNA, 'CALC1:SMO:STAT ON');
                        writeline(app.VNA, sprintf('CALC1:SMO:POIN %g', app.SmoothingPoints.Value));
                    else
                        writeline(app.VNA, 'CALC1:SMO:STAT OFF');
                    end
        
                    % Phase smoothing.
                    traceIndex = traceIndex + 1;
                    writeline(app.VNA, sprintf('CALC1:PAR:MNUM %d', traceIndex));

                    if app.SmoothingPoints.Value ~= 0
                        writeline(app.VNA, 'CALC1:SMO:STAT ON');
                        writeline(app.VNA, sprintf('CALC1:SMO:APER %g', app.SmoothingPoints.Value));
                    else
                        writeline(app.VNA, 'CALC1:SMO:STAT OFF');
                    end
        
                    traceIndex = traceIndex + 1;
                end               

                % Set the data format and border swap settings.
                writeline(app.VNA, 'FORM:BORD SWAP');
                writeline(app.VNA, 'FORM:DATA REAL,64');

                runAntennaMeasurement(app);
            catch ME
                app.displayError(ME);
            end
        end

        % Button pushed function: LoadTestButton
        function AntennaLoadData(app, event)
            % This function is responsible for loading an antenna gain file into the application. The file must 
            % adhere to the predefined column headers for antenna gain data, which include:
            %       - Theta (deg)
            %       - Phi (deg)
            %       - Frequency (MHz)
            %       - Gain (dBi)
            %       - Return Loss (dB)
            %       - Return Loss (deg)
            %       - Return Loss Reference (dB)
            %       - Return Loss Reference (deg)
            %       - Path Loss (dB)
            %       - Path Loss (deg)
            % Upon successful loading, the function extracts the data and populates the relevant fields within 
            % the application, such as dropdown menus for selecting specific angles (Theta, Phi) and
            % frequencies for plotting. The function also ensures that the dropdown menus are populated with 
            % unique values. After populating the dropdowns, an automatic replotting of the antenna's radiation
            % pattern is done.

            try 
                % Load the antenna gain file
                loadData(app, 'Antenna');

                % Check if the uploaded file is empty, or if the user
                % canceled the file selection.
                if isempty(app.Antenna_Data)
                    return;
                end
                
                % Populate dropdown menus, with the angles and frequencies
                % so user can select a specific values for plotting.
                app.ThetaDropDown.Items = string(unique(app.Antenna_Data.Thetadeg));
                app.PhiDropDown.Items = string(unique(app.Antenna_Data.Phideg));
                app.FrequencyMHzDropDown.Items = string(unique(app.Antenna_Data.FrequencyMHz));

                % Set default values for the angle and frequency.
                app.ThetaDropDown.Value = app.ThetaDropDown.Items(1);
                app.PhiDropDown.Value = app.PhiDropDown.Items(1);
                app.FrequencyMHzDropDown.Value = app.FrequencyMHzDropDown.Items(1);

                % Replot automatically.
                plotAntenna2DRadiationPattern(app);
                % Check if the Antenna Toolbox is installed
                if ~license('test', 'Antenna_Toolbox')
                    uialert(app.UIFigure, 'Antenna Toolbox is not installed.', 'Missing Toolbox', 'Icon', 'warning');
                else
                    plotAntenna3DRadiationPattern(app);
                end
               
            catch ME    
                app.displayError(ME);
            end
        end

        % Value changed function: ThetaDropDown
        function AntennaSelectedThetaValue(app, event)
            % This function automatically updates the antenna plots based on the user's selected 
            % theta angle from the dropdown menu. 
        
            % Replot automatically.
            plotAntenna2DRadiationPattern(app);
        end

        % Value changed function: PhiDropDown
        function AntennaSelectedPhiValue(app, event)
            % This function automatically updates the antenna plots based on the user's selected
            % phi angle from the dropdown menu. 
        
            % Replot automatically.
            plotAntenna2DRadiationPattern(app);
        end

        % Value changed function: FrequencyMHzDropDown
        function AntennaSelectedFrequencyValue(app, event)
            % This function automatically plots the antenna plots based on the user's selected frequency 
            % from the frequency dropdown menus.

            % Replot automatically.
            plotAntenna2DRadiationPattern(app);

            % Check if the Antenna Toolbox is installed
            if ~license('test', 'Antenna_Toolbox')
                uialert(app.UIFigure, 'Antenna Toolbox is not installed. Cannot generate 3D plot.', 'Missing Toolbox', 'Icon', 'warning');
            else
                plotAntenna3DRadiationPattern(app);
            end
        end

        % Button pushed function: BrowseReferenceButton
        function LoadReferenceGainFile(app, event)
            % This function handles the loading of a reference antenna gain file in the application. The file must 
            % conform to a specific column format, which includes the following columns:
            %       - Theta (deg)
            %       - Phi (deg)
            %       - Frequency (MHz)
            %       - Gain (dBi)
            %       - Return Loss (dB)
            %       - Return Loss (deg)
            % The function attempts to load the reference gain data, and if successful, it displays the loaded file's
            % path in the GUI. Additionally, it plots the reference antenna data.
            
            try 
                % Load the reference gain file.
                loadData(app, 'AntennaReference');

                % Check if the uploaded file is empty, or if the user
                % canceled the file selection.
                if isempty(app.ReferenceGainFile)
                    return;
                end

                % If the file presents no errors, the file path is loaded
                % into the file, and displayed to the user.
                [~, filename, ext] = fileparts(app.ReferenceGainFilePath);
                app.ReferenceGainFileField.Value = [filename, ext];
                plotReferenceAntenna(app);
            catch ME
                app.displayError(ME);
            end
        end

        % Button pushed function: ClearReferenceButton
        function ClearReferenceGainFile(app, event)
            % This function clears the loaded reference antenna gain file from the application. It resets the internal
            % data, the file path, and the corresponding GUI display field. Used when the user wants to remove the 
            % currently loaded file and start fresh. If there is no actual refernce file loaded the function does nothing.

            try
                % Only clear if values exist.
                cla(app.GainvsFrequencyBoresight);
                cla(app.ReturnLossBoresight);
                if ~isempty(app.ReferenceGainFile)
                    app.ReferenceGainFile = [];
                end

                if ~isempty(app.ReferenceGainFilePath)
                    app.ReferenceGainFilePath = [];
                end

                if ~strcmp(app.ReferenceGainFileField.Value, '')
                    app.ReferenceGainFileField.Value = '';
                end
            catch ME
                app.displayError(ME);
            end
        end

        % Button pushed function: NewInstrumentButton
        function InstrumentsCreateRow(app, event)
            % This function handles the creation of a new row in the Instruments table.
            % It appends an empty row to the existing table data. The new row is represented as
            % a cell array of empty strings, matching the table's current column format.

            currentData = app.InstrumentsTable.Data;
            newRow = {'' '' ''};
            currentData = [currentData; newRow];
            app.InstrumentsTable.Data = currentData;
        end

        % Button pushed function: DeleteInstrumentButton
        function InstrumentsDeleteRow(app, event)
            % This function handles the deletion of a selected row from the Instruments table.
            % If no row is selected, it will display an alert to notify the user.
            % If a row is selected, the row is removed from the table's data.

            selectedRow = app.InstrumentsTable.Selection;
    
            if isempty(selectedRow)
                uialert(app.UIFigure, 'No row selected.', 'Warning', 'Icon', 'warning');
                return;
            end
        
            currentData = app.InstrumentsTable.Data;
            currentData(selectedRow(1), :) = [];
            app.InstrumentsTable.Data = currentData;
        end

        % Button pushed function: SaveChangesButton
        function InstrumentsSaveChanges(app, event)
            % This function handles saving the current instrument address data from the Instruments table
            % into a CSV file. It ensures that a directory for the ARES application exists on the user's 
            % machine. If not, it creates the directory. Then, it saves the instrument data to a CSV file
            % and refreshes the dropdowns displaying the instrument addresses in the app.
            
            % Create the ARES directory if it does not exist in the
            % user's machine.
            ARESDirectory = fullfile(userpath, 'ARES');

            if ~exist(ARESDirectory, 'dir')
                mkdir(ARESDirectory);
            end
            
            % Full file path for saving.
            saveFilePath = fullfile(ARESDirectory, 'instrumentAddresses.csv');
            
            % Save to instrumentAddresses.csv
            writetable(app.InstrumentsTable.Data, saveFilePath);
            
            % Refresh the instrument dropdowns.
            app.loadInstrumentAddressestoApp();       
            uialert(app.UIFigure, 'Instrument addresses saved successfully.', 'Success', 'Icon','success');
        end

        % Close request function: UIFigure
        function closeupFcn(app, event)
            % This function handles the app's closure behavior. When the user attempts to close the app, the function 
            % prompts them with a confirmation dialog. If the user confirms the closure,the function will clean up by
            % closing all active instrument connections. If the user cancels the closure, the function returns the user
            % tpo the app.

            instrumentNames = {'PowerSupplyA',... 
                               'PowerSupplyB',...
                               'SignalGenerator',...
                               'InputSignalAnalyzer',...
                               'OutputSignalAnalyzer',...
                               'VNA',...
                               'EMCenter',...
                               'EMSlider'
            };
            question = 'Close ARES App?';
            choice = uiconfirm(app.UIFigure, question, 'Confirm Close', 'Options', {'Yes', 'No'});

            switch choice
                case 'Yes'
                    for i = 1:numel(instrumentNames)
                        instrumentName = instrumentNames{i};
                        if ~isempty(app.(instrumentName))
                            try
                                flush(app.(instrumentName));
                            catch ME
                                app.displayError(ME);
                            end
                            app.(instrumentName) = [];
                        end
                    end
                    app.delete
                case 'No'
            end
        end

        % Button pushed function: PlotGridOnOffButton
        function PlotGridOnOffButtonPushed(app, event)
            % This function is executed when the user presses the Plot Grid Button, in the UI panel of the Settings menu. 
            % It toggles the visibility of the grid on all plot axes in the app, except the 2D and 3D polar plots.
             % Suppress the specific warning for this function
                
            GridStatus = regexp(app.GridCurrentStatusLabel.Text, '(On|Off)', 'match');

            % axList = {app.SingleFrequencyPAPlot, app.PeakGainPlot, app.PeakDEPAEPlot, app.CompressionPointsPlot,... 
            %           app.PASupplyCurrentPlot, app.PASupplyPowerPlot, app.PAPeakSupplyCurrentPlot, app.PAPeakSupplyPowerPlot,...
            %           app.GainvsFrequencyBoresight, app.ReturnLossBoresight,...
            %           app.GainvsFrequency2DPattern, app.GainvsAngle2DPattern, app.ReturnLoss2DPattern};
            axList = [findall(app.UIFigure, 'Type', 'axes'); ...
                      findall(app.UIFigure, 'Type', 'polaraxes')];

            if strcmp(GridStatus{1}, 'On')
                for i = 1:length(axList)
                    has3D = any(strcmp(get(get(axList(i), 'Children'), 'Type'), 'surface'));
                    if ~has3D
                        grid(axList(i), 'off');
                    end
                end
                app.GridCurrentStatusLabel.Text = 'Current Status: Off';
            else
                for i = 1:length(axList)
                    has3D = any(strcmp(get(get(axList(i), 'Children'), 'Type'), 'surface'));
                    if ~has3D
                        grid(axList(i), 'on');
                    end
                end
                app.GridCurrentStatusLabel.Text = 'Current Status: On';
            end
        end

        % Button pushed function: ClearLogsButton
        function ClearLogsButtonPushed(app, event)
            
            % In case userpath has a trailing semicolon, clean it
            upath = strsplit(userpath, pathsep);
            upath = upath{1};
            upath = upath + "\ARES";
            
            % Define the target filenames
            targetFiles = {'ARES_Measurement_Log.txt', 'ARES_Error_Log.txt', 'measurement_backup.csv'};
            
            % Loop through each file
            for i = 1:length(targetFiles)
                filePath = fullfile(upath, targetFiles{i});
                if exist(filePath, 'file')
                    delete(filePath);
                end
            end
        end

        % Button pushed function: ToogleThemeButton
        function ToogleThemeButtonPushed(app, event)
            if app.UIFigure.Theme.BaseColorStyle == "light"
                app.UIFigure.Theme.BaseColorStyle = "dark";
            elseif app.UIFigure.Theme.BaseColorStyle == "dark"
                    app.UIFigure.Theme.BaseColorStyle = "light";
            end

            % Update Label
            app.CurrentThemeLabel.Text = strcat("Current Theme: ", app.UIFigure.Theme.BaseColorStyle);
        end

        % Value changed function: ColorMapsDropDown
        function ColorMapsDropDownValueChanged(app, event)
            updateColormap(app);
        end

        % Value changed function: GainTypeDropDown
        function AntennaSelectedPlotTypeValue(app, event)
            % This function automatically updates the antenna plots based on the user's selected 
            % plot type from the dropdown menu. 

            % Replot automatically.
            plotAntenna2DRadiationPattern(app);
            plotAntenna3DRadiationPattern(app);    
        end

        % Value changed function: ColorOrderDropDown
        function ColorOrderDropDownValueChanged(app, event)
            updateColorOrder(app);
        end

        % Button pushed function: MinimumGainButton
        function MinimumGainButtonPushed(app, event)
            if ~app.MinimumGainSafetyState
                app.MinimumGainSafetyState = true;
                app.MinimumGainSpinner.Enable = "on";
            else
                app.MinimumGainSafetyState = false;
                app.MinimumGainSpinner.Enable = "off";
            end
        end

        % Value changed function: InputAttenuationValueField
        function InputAttenuationValueFieldValueChanged(app, event)
                plotCalibration(app);
        end

        % Value changed function: OutputAttenuationValueField
        function OutputAttenuationValueFieldValueChanged(app, event)
            plotCalibration(app);
        end

        % Value changed function: StimulusDropDown
        function StimulusDropDownValueChanged(app, event)
            if app.StimulusDropDown.Value == "CW"
                app.ModulationTypeDropDown.Enable = "off";
                app.SymbolRateValueField.Enable = "off";
                app.ChannelOffsetValueField.Enable = "off";
                app.ChannelBandwidthValueField.Enable = "off";
            elseif app.StimulusDropDown.Value == "Modulated"
                app.ModulationTypeDropDown.Enable = "on";
                app.SymbolRateValueField.Enable = "on";
                app.ChannelOffsetValueField.Enable = "on";
                app.ChannelBandwidthValueField.Enable = "on";
            end
        end

        % Button pushed function: OpenLogsButton
        function OpenLogsButtonPushed(app, event)
            ARESDirectory = fullfile(userpath, 'ARES');
            errorLogFile = fullfile(ARESDirectory, 'ARES_Error_Log.txt');
            open(errorLogFile);
        end

        % Value changed function: UIColumnWidthSlider
        function UIColumnWidthSliderValueChanged(app, event)
            try
                % Get column widths
                a = max(app.UIColumnWidthSlider.Value,1);
                b = max(100 - app.UIColumnWidthSlider.Value,1);

                % Normalize
                b = b/a;
                a = 1;

                % Assign columm width
                colWidth = [cellstr(sprintf('%dx',a)), cellstr(sprintf('%dx',b))];
                app.PAGridLayout.ColumnWidth = colWidth;
                app.AntennaGridLayout.ColumnWidth = colWidth;
            catch ME
                app.displayError(ME);
            end
        end

        % Button pushed function: OccupiedBandwidthButton
        function OccupiedBandwidthButtonPushed(app, event)
            if ~app.OccupiedBandwidthSafetyState
                app.OccupiedBandwidthSafetyState = true;
                app.OccupiedBandwidthSpinner.Enable = "on";
            else
                app.OccupiedBandwidthSafetyState = false;
                app.OccupiedBandwidthSpinner.Enable = "off";
            end

        end

        % Button pushed function: LoadConfigurationButton
        function LoadConfigButtonPushed(app, event)
            [file, path] = uigetfile('*.json', 'Select an antenna measurement config');
            if isequal(file, 0), return; end                 % user cancelled
            try
                cfg = AntennaMeasurementConfig.loadFromJSON(fullfile(path, file));
                cfg.applyToApp(app);                          % populate the UI fields
                cfg.validate(app.UIFigure);                   % alert if the file is invalid
            catch ME
                uialert(app.UIFigure, ME.message, 'Config Load Failed');
            end
        end

        % Button pushed function: SaveConfigurationButton
        function saveConfigButtonPushed(app, event)
            [file, path] = uiputfile('*.json', 'Save config', 'antenna_config.json');
            if isequal(file, 0), return; end
            try
                cfg = AntennaMeasurementConfig.fromApp(app);  % snapshot current UI
                cfg.saveToJSON(fullfile(path, file));
            catch ME
                uialert(app.UIFigure, ME.message, 'Config Save Failed');
            end
        end

        % Button pushed function: AdvancedSetupButton
        function OpenPortMap(app, event)
            app.PortMapPanel.Visible = 'on';
            app.PortMapTable.Visible = 'on';
            if isempty(app.PortMapTable.Data)
                app.PortMapTable.Data = PortMap(4).toPortRows();   % 4 = your VNA's port count
                app.PortMapTable.ColumnEditable = [false true true];
            end
        end

        % Value changed function: NPortQuantityDropDown
        function NPortQuantityDropDownValueChanged(app, event)
            plotNPortAntenna(app);
        end
    end

    % App creation
    methods (Access = public)

        % Construct app
        function app = ARES(varargin)
            app = app@matlab.apps.App(varargin{:});

            if nargout == 0
                clear app
            end
        end
    end
end