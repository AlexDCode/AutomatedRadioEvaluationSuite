# App Source Code Overview

The main application, instrument control code, and supporting functions are organized within the **[src](https://github.com/AlexDCode/AutomatedRadioEvaluationSuite/tree/main/src)** directory. Here’s an overview of the contents:

- **ARES.mlapp**: This is the main application file for ARES, where the graphical user interface (GUI) and core functionality reside.
- **instrument_address_history.txt**: This text file stores the names of instruments and their corresponding IP addresses (or other connection details, like USB addresses). The app reads this file each time it is loaded to display available instruments and their addresses in the instrument blocks. Users can add, modify, or remove instrument addresses either through the app interface or by directly editing the **instrument_address_history.txt** file. The app handles the `visadev` connections internally and requires only the correct addresses to connect to the instruments.

In the **[src/support](https://github.com/AlexDCode/AutomatedRadioEvaluationSuite/tree/main/src/support)** directory, you'll find three subdirectories, each containing functions relevant to specific parts of the app:

- **[AntennaFunctions](https://github.com/AlexDCode/AutomatedRadioEvaluationSuite/tree/main/src/support/AntennaFunctions)**: This directory contains functions related to antenna measurements, including the calculation of antenna gain using methods like gain comparison and gain transfer, S-parameters, and setting up necessary hardware like linear sliders. 

- **[PAFunctions](https://github.com/AlexDCode/AutomatedRadioEvaluationSuite/tree/main/src/support/PAFunctions)**: This directory contains functions specific to power amplifier (PA) testing. It includes functions for measuring RF output, Gain, and DC Power, controlling power supply units (PSUs), deembedding PA characteristics, and validating and configuring PSU channels.

- **[SupportFunctions](https://github.com/AlexDCode/AutomatedRadioEvaluationSuite/tree/main/src/support/SupportFunctions)**: This directory contains utility functions that are used across both antenna and PA modules. These include functions for data conversion, saving/loading measurement data, improving plot appearance, and ensuring smooth instrument communication, and other app-wide utilities that facilitate interaction with the system.

Additionally, sample measurement data for plotting is available in the **[data](https://github.com/AlexDCode/AutomatedRadioEvaluationSuite/tree/main/data)** directory, organized into two subdirectories:
- **[Antenna](https://github.com/AlexDCode/AutomatedRadioEvaluationSuite/tree/main/data/Antenna)**: Contains sample data specific to antenna measurements.
- **[PA](https://github.com/AlexDCode/AutomatedRadioEvaluationSuite/tree/main/data/PA)**: Contains sample data related to power amplifier measurements.

You can reference these files and directories to build custom scripts or adapt the existing functionality to suit your specific needs.
