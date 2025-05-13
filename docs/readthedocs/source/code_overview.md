# Source Code Overview

---

The full source code for ARES is organized within the **[src](https://github.com/AlexDCode/AutomatedRadioEvaluationSuite/tree/main/src)** directory. This section provides a high-level overview of the directory structure and key components.

## Main Application

`ARES.mlapp`

The main application file contains the graphical user interface (GUI) and core app logic. This main file defines:

* A tab-based interface layout.
* Laboratory instrument connection workflows.
* Measurement test execution for both antenna and PA modules
* Plotting, exporting, and data handling behavior.

`instrument_address_history.txt`

A simple text file that logs laboratory instrument addresses (VISA resource strings).

* ARES reads this file upon startup to populate instrument dropdowns with addresses.
* You can edit or manage this list via the in-app Instrument Database interface.

## Support Modules

Located in the **[src/support](https://github.com/AlexDCode/AutomatedRadioEvaluationSuite/tree/main/src/support)** directory, the following submodules contain reusable measurement and processing logic:

### **[Antenna Functions](https://github.com/AlexDCode/AutomatedRadioEvaluationSuite/tree/main/src/support/AntennaFunctions)**

Functions focused on antenna measurements, including:

* Gain calculations (Comparison & Transfer methods)
* S-parameter acquisition and interpretation
* Radiation pattern plotting (2D & 3D)
* Linear slider and rotator control
* Enabling and validating the antenna test setup
* Main measurement function for parametric sweeps, data collection, and result plotting

### **[PA Functions](https://github.com/AlexDCode/AutomatedRadioEvaluationSuite/tree/main/src/support/PAFunctions)**

Functions focused on power amplifier (PA) characterization:

* Measuring DC power, RF power, gain, and efficiency
* DC power supply control
* Enabling and validating power supply unit channels
* Peak gain, peak efficiency, compression points, and saturation analysis
* PA deembedding
* Main measurement function for parametric sweeps, data collection, and result plotting

### **[Support Functions](https://github.com/AlexDCode/AutomatedRadioEvaluationSuite/tree/main/src/support/SupportFunctions)**

Shared utility functions used by both measurement modules:

* Unit conversions (e.g., dBm ↔ Watts, linear ↔ dB)
* Measurement data saving/loading
* UI and axes formatting
* Instrument wait timing

## Sample Data

Located in the **[data](https://github.com/AlexDCode/AutomatedRadioEvaluationSuite/tree/main/data)** folder, this directory provides example measurement results you can load directly into ARES for visualization or testing.

**[Antenna Data](https://github.com/AlexDCode/AutomatedRadioEvaluationSuite/tree/main/data/Antenna)**:
- Contains sample data specific to antenna measurements. Includes example gain, return loss, and radiation pattern datasets.

**[PA Data](https://github.com/AlexDCode/AutomatedRadioEvaluationSuite/tree/main/data/PA)**:
- Contains sample data related to power amplifier measurements. Includes example gain, efficiency, compression analysis, DC current, and DC power analysis.

You can reference these files and directories to build custom scripts or adapt the existing functionality to suit your specific needs.
