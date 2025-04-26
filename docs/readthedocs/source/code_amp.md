# Power Amplifier Functions


`src\support\PAFunctions\createPAParametersTable.m`
 %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
  This function creates a parameter sweep table for power amplifier 
  (PA) testing, generating all possible combinations of frequency, 
  RF input power, voltage, and current based on the configured sweep 
  settings for each PSU channel.
 
  INPUT PARAMETERS
    app:  The application object containing frequency, power, and 
        voltage/current sweep configurations.
 
  OUTPUT PARAMETERS
    paramTable:  The PA test paramaters table containing all 
                 combinations of frequencies in (Hz), RF input power 
                 in (dBm), voltages in (V), and currents in (A) for 
                 each active PSU channel.
 %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%


`src\support\PAFunctions\createPAResultsTable.m`
 %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
  This function creates a results table for power amplifier (PA)
  measurements, dynamically adjusting the column headers based on the 
  number of active power supply channels.
 
  INPUT PARAMETERS
    app:               The application object containing configuration
                       details, including the active PSU channels.
    totalMeasurements: Total number of measurements to be recorded in
                       the table.
 
  OUTPUT PARAMETERS
    ResultsTable:      PA results table initialized with appropriate 
                       columns for storing frequency, voltage, RF 
                       power, DC power, gain, and efficiency metrics.
 %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%


`src\support\PAFunctions\deembedPA.m`
 %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
  This function de-embeds PA measurements by removing the effects of 
  passive and active devices. It generates calibration factors in dB 
  to correct the PA input and output RF power.
 
  INPUT PARAMETERS
    app:           The application object containing calibration 
                   settings and attenuation values.
    testFreq:      Measurement frequency [Hz].
    RFInputPower:  RF input power [dBm].
 
  OUTPUT PARAMETERS
    inCal:    Input attenuation calibration factor [dB].
              Subtract this from the input RF power to obtain the 
              corrected PA input power.
    outCal:   Output attenuation calibration factor [dB].
              Add this to the measured output power to get the PA 
              output power.
 %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%


`src\support\PAFunctions\enablePSUChannels.m`
 %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
  This function enables or disables channels on two power supply units 
  (PSU A and PSU B) based on the provided state. The channels are 
  grouped by PSU and then enabled or disabled accordingly.
  
  INSTRUMENTS
    DC Power Supplies A/B: E36233A / E336234A
  
  INPUT PARAMETERS
    app:       The application object containing the power supplies and 
             the channel-to-device mapping.
    channels:  A cell array of channel names (e.g., {'CH1', 'CH2'}).
    state:     Channel state (1 for enable, 0 for disable).
 
  OUTPUT PARAMETERS
    None
 %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%


`src\support\PAFunctions\measureRFOutputandDCPower.m`
 %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
  This function measures the output RF power, the DC drain power, and 
  the DC gate power.
  
  INSTRUMENTS
    Spectrum Analyzer: N9000B
    Signal Generator:  SMW200A
    DC Power Supply:   E36233A / E336234A
 
  INPUT PARAMETERS
    app:           The application object containing the instruments 
                   and the settings.
    inputRFPower:  The input RF power to the signal generator (in dB).
 
  OUTPUT PARAMETERS
    OutputRFPower: The maximum output RF power in (dB).
    DCDrainPower:  The DC power delivered to the drain in (watts).
    DCGatePower:   The DC power delivered to the gate in (watts).
 %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%


`src\support\PAFunctions\measureRFParameters.m`
 %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
  This function calculates the RF Gain, the Drain Efficiency (DE), and 
  the Power Added Efficiency (PAE) based on the input/output RF power, 
  and the DC power input.
 
  INPUT PARAMETERS
    inputRFPowerdBm: Input RF power in (dBm).
    outputRFPower:   Output RF power in (dBm).
    DCPower:         DC power in (watts).
 
  OUTPUT PARAMETERS
    Gain:            RF Gain.
    DE:              Drain Efficiency (%).
    PAE:             Power Added Efficiency (%).
 %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%


`src\support\PAFunctions\measureRFParametersPeaks.m`
 %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
  This function calculates peak RF performance metrics from power 
  amplifier (PA) measurement data, including saturation power, 
  peak gain, drain efficiency (DE), power-added efficiency (PAE), and 
  -1 dB and -3 dB compression points.
 
  INPUT PARAMETERS:
    app:            Application object containing the PA measurement 
                    data table.
    idx:            Logical or numeric index used to filter the rows 
                    of the PA_DataTable for analysis.
 
  OUTPUT PARAMETERS:
    Psat:            Table containing the maximum RF output power 
                     (Psat) per frequency and corresponding gain.
    peakGain:        Table of peak small-signal gain values per 
                     frequency.
    peakDE:          Table of maximum drain efficiency per frequency.
    peakPAE:         Table of maximum power-added efficiency per 
                     frequency.
    compression1dB:  Table containing the -1 dB gain compression 
                     points per frequency.
    compression3dB:  Table containing the -3 dB gain compression  
                     points per frequency.
 %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%


`src\support\PAFunctions\plotPASingleMeasurement.m`
 %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
  This function plots gain, drain efficiency (DE), and 
  power-added efficiency (PAE) versus RF output power for a single 
  frequency measurement. Also overlays peak values such as Psat, 
  -1 dB and -3 dB compression points.
 
  INPUT PARAMETERS:
    app:  Application object containing PA measurement data, 
          user-selected frequency, supply voltages, and plotting 
          handles.
 
  The function automatically filters the data for the selected 
  frequency and voltage settings, and generates a dual y-axis plot:
    - Left Y-axis: Gain [dB]
    - Right Y-axis: DE and PAE [%]
 
  Overlaid Markers:
    - Green X: Psat (saturation output power)
    - Red X:   -1 dB and -3 dB gain compression points
 %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%


`src\support\PAFunctions\plotPASweepMeasurement.m`
 %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
  This function plots performance metrics from a frequency 
  sweep power amplifier (PA) measurement, including gain, saturation 
  power, efficiency, and compression points.
 
  INPUT PARAMETERS:
    app:   Application object containing PA measurement data and UI 
           plotting components.
 
  This function filters the PA dataset based on user-selected supply 
  voltages, and generates four plots:
 
    1. Gain vs. Output Power for each frequency (GainvsOutputPowerPlot)
    2. Peak Gain vs. Frequency (PeakGainPlot)
    3. Peak Drain Efficiency (DE) and Power-Added Efficiency (PAE) vs. 
       Frequency (PeakDEPAEPlot)
    4. Psat and -1 dB / -3 dB compression points vs. Frequency 
       (CompressionPointsPlot)
 
  Data points are highlighted with markers for easier interpretation.
  All axes are styled for readability.
 %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%


`src\support\PAFunctions\populatePSUChannels.m`
 %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
  This function checks the modes and configurations of power supply 
  channels and determines which channels are "filled," meaning their 
  user-defined parameters are complete and ready for use. The filled 
  channels are stored in the app object for later processing or 
  interaction with the power supply units.
  
  INSTRUMENTS
    DC Power Supplies A/B: E36233A / E336234A
  
  INPUT PARAMETERS
    app:       The application object containing the channel 
             configurations and the channel-to-device mapping.
 
  OUTPUT PARAMETERS
    None
 %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%


`src\support\PAFunctions\resetPSUChannels.m`
 %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
  This function resets all power supply unit (PSU) channels to their
  default state, which includes setting current and voltage to 0 and 
  configuring each channel to 'Single' mode. It restores the default 
  settings for all channels and refreshes the GUI elements to reflect 
  these changes, ensuring the application returns to its initial 
  configuration.
 
  INSTRUMENTS
    DC Power Supplies A/B: E36233A / E336234A
 
  INPUT PARAMETERS
    app:       The application object containing the channel 
               configurations.
 
  OUTPUT PARAMETERS
    None
 %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%


`src\support\PAFunctions\runPAMeasurement.m`
 %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
  This function executes a full RF power amplifier (PA) measurement 
  sweep across defined power levels and frequencies, including:
    - Instrument control (PSU, Signal Generator, Signal Analyzer)
    - Calibration/de-embedding
    - Data acquisition and processing
    - PA figures of merit calculation
    - Real-time progress monitoring and visualization
 
  INPUT PARAMETERS:
    app:  Application object containing hardware interfaces, 
          user-defined settings, and UI components.
 
  PROCESS OVERVIEW:
    1. Generates test parameter combinations and initializes the 
       results table.
    2. Configures the spectrum analyzer and initializes the measurement
       loop.
    3. For each test point:
        - Sets frequency and signal level
        - Configures PSU voltages and currents
        - Measures RF output power and DC power
        - Applies calibration factors (de-embedding)
        - Calculates Gain, DE (Drain Efficiency), and 
          PAE (Power Added Efficiency)
        - Stores results in a structured table
    4. Provides a progress UI with estimated time updates.
    5. Saves the results and loads them back into the application.
 
  OUTPUT PARAMETERS
    None
 
  ERROR HANDLING:
    In case of an exception, instruments are safely turned off and 
    the error is displayed via the application interface.
 %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%


`src\support\PAFunctions\setPSUChannels.m`
 %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
  This function sets the voltage and current for a specified channel 
  on a power supply unit (PSU). It selects the appropriate PSU based 
  on the provided channel, and then applies the given voltage and 
  current values to that channel.
 
  INSTRUMENTS
    DC Power Supplies A/B: E36233A / E336234A
 
  INPUT PARAMETERS
    app:           The application object containing the power supply 
                   configurations and channel-to-device mapping.
    deviceChannel: The name of the channel (e.g., 'CH1', 'CH2').
    voltage:       The voltage to set for the specified channel, given 
                   as a numeric value or a string.
    current:       The current to set for the specified channel, given 
                   as a numeric value or a string.
 
  OUTPUT PARAMETERS
    None
 %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%


`src\support\PAFunctions\validatePSUChannels.m`
 %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
  This function validates the configuration of power supply unit (PSU) 
  channels based on the selected supply mode and the connected devices. 
 
  It checks for the following conditions:
    - Whether power supplies are connected.
    - Whether the selected supply mode is compatible with the number
      of connected power supplies.
    - Whether enough channels are configured for the selected mode.
    - Whether the number of configured channels exceeds the allowed 
      number for the selected mode.
 
  If any of these conditions fail, the function will display 
  appropriate messages and prompt the user to correct the 
  configuration.
 
  INSTRUMENTS
    DC Power Supplies A/B: E36233A / E336234A
 
  INPUT PARAMETERS
    app:     The application object containing the power supply 
             configurations, the current mode, and the list of filled 
             channels.
 
  OUTPUT PARAMETERS
    isValid: A boolean value indicating whether the PSU configuration 
             is valid (true) or not (false).
 %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
