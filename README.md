<p align="center">
  <img src="./src/support/ARES%20Icon.png" width="480"/>
<p \>
<h1 align="center">Automated Radio Evaluation Suite
</h1>

![Latest Release](https://img.shields.io/github/v/release/AlexDCode/AutomatedRadioEvaluationSuite?label=Latest%20Release)
[![File Exchange](https://www.mathworks.com/matlabcentral/images/matlab-file-exchange.svg)](https://www.mathworks.com/matlabcentral/fileexchange/181347-automated-radio-evaluation-suite)
[![Documentation Status](https://readthedocs.org/projects/aresapp/badge/?version=latest)](https://aresapp.readthedocs.io/latest/home.html)
[![Star on GitHub](https://img.shields.io/github/stars/AlexDCode/AutomatedRadioEvaluationSuite?style=social)](https://github.com/AlexDCode/AutomatedRadioEvaluationSuite/stargazers)
[![GitHub Forks](https://img.shields.io/github/forks/AlexDCode/AutomatedRadioEvaluationSuite?style=social)](https://github.com/AlexDCode/AutomatedRadioEvaluationSuite/network/members)
[![GitHub Issues](https://img.shields.io/github/issues/AlexDCode/AutomatedRadioEvaluationSuite)](https://github.com/AlexDCode/AutomatedRadioEvaluationSuite/issues)
[![GitHub Pull Requests](https://img.shields.io/github/issues-pr/AlexDCode/AutomatedRadioEvaluationSuite)](https://github.com/AlexDCode/AutomatedRadioEvaluationSuite/pulls)
![Contributors](https://img.shields.io/github/contributors/AlexDCode/AutomatedRadioEvaluationSuite)]
[![License](https://img.shields.io/github/license/AlexDCode/AutomatedRadioEvaluationSuite)](https://github.com/AlexDCode/AutomatedRadioEvaluationSuite/blob/main/LICENSE.txt)


The **Automated Radio Evaluation Suite (ARES)** enables automated RF measurements for power amplifiers and antennas, interfacing seamlessly with existing laboratory equipment using standard communication protocols and offering a comprehensive and user-friendly interface. Unlike commercial software, this app is open-source, customizable, and free. Download the [latest release](https://github.com/AlexDCode/AutomatedRadioEvaluationSuite/releases) and follow the [Getting Started](https://aresapp.readthedocs.io/latest/getting_started.html) guide to learn how to use it. Tutorials for [Instrument Database](https://aresapp.readthedocs.io/latest/tutorial_instr.html), [Antenna Measurement](https://aresapp.readthedocs.io/latest/tutorial_ant.html), and [PA Measurements](https://aresapp.readthedocs.io/latest/tutorial_PA.html) are available. All the documentation is hosted on [Read the Docs](https://aresapp.readthedocs.io/).

<!-- ## Table of Contents

- [Table of Contents](#table-of-contents)
- [Features](#features)
- [TODO](#todo)
- [Usage](#usage)
  - [Installing ARES](#installing-ares)
  - [PA Measurement Tutorial](#pa-measurement-tutorial)
  - [Antenna Measurement Tutorial](#antenna-measurement-tutorial)
- [Contributions](#contributions) -->

## Features

### General Capabiltiies
- VISA-based instrument control via **GPIB**, **LAN**, and **USB** with support for multiple instrument manufacturers.
- Save and recall measurement results in standardized file formats for data analysis.
- Plot measurement results within the app for quick visualization.
- Export plots to **PDF**, **PNG**, **JPEG**, and **TikZ** for publication (TikZ export is unsupported for polar plots).

### Power Amplifier Measurement Capabilities
- Measure RF power amplifier Figures of Merit (FoM) over one or multiple frequencies
  - Gain
  - Output Power
  - Drain Efficiency
  - Power Added Efficiency (PAE)
- CW and modulated drive signals
- Built in deembedding and calibration support with the following modes:
  - Fixed: Static loss entered manually corresponding to the input and output.
  - Small-signal: S-parameter measurement for the loss of the input and output network over frequency.
  - Large-signal: Amplifier measurement including compression characteristics over different frequencies and power levels.
  - In-Situ: Direct measurement of input and output power through directional couplers and passive deembedding of measurement network losses.

### Antenna Measurements
- Measure and visualize 2D/3D antenna realized and absolute gain characteristics by:
  - Gain Comparison Method (i.e., Two-Antenna Method).
  - Gain Transfer Method (i.e., Comparison Antenna Method) using a reference measurement.
- Measure antenna complex valued S-parameters (magnitude and phase).

## TODO

- **Update Documentation Images**: Showing new UI and plotting options. Create script to automatically capture screenshots.
- **PA Test Safety Features**: Add option to stop test if power supply is current limited (short circuit).
- **Over the Air Testing (OTA)**: Measure RF transceivers (PAs, Antennas, LNAs, etc.) with modulated signals and plot the results. Enable measurements with the presence of interferers.
- **Known Limitation**: The linear slider range and offset are hard-coded in the app. The default values are for Purdue's Anechoic Chamber setup (2m slider range and offset 0.8062m). You can modify the `LINEAR_SLIDER_RANGE` and `offsetSpacing` variables in ARES.MLAPP to fit a different setup. This could be added to the instrument database as properties.

### Being added for the upcoming update:
- **Object Oriented Instruments**: Configure a class for each instrument to execute the commands instead of hardcoding. This should allow different classes to be configured for specific command sets or special cases on particular instruments.
- **Instrument Type Filter**: Filter the instrument address dropdown by instrument type and only display the instruments pertaining relevant category and 'Others'.
- **Test Configuration**: Save and load test parameters with custom configurations and unique app settings with a JSON file.


## Usage

### [Installing ARES](https://aresapp.readthedocs.io/latest/getting_started.html)

### [Instrument Database Tutorial](https://aresapp.readthedocs.io/latest/tutorial_instr.html)

### [PA Measurement Tutorial](https://aresapp.readthedocs.io/latest/tutorial_PA.html)

### [Antenna Measurement Tutorial](https://aresapp.readthedocs.io/latest/tutorial_ant.html)


## Contributions

<p align="center">
  <img src="./docs/assets/ARES_logo.jpg" width="240"/>
<p \>
  
- Authors:
  - José Abraham Bolaños Vargas ([@bolanosv](http://github.com/bolanosv))
  - Jack Willard ([@Jack-Willard](https://github.com/Jack-Willard))
  - Joe Kritenbrink ([@joekritenbrink0-wq](https://github.com/joekritenbrink0-wq))
- Mentor: Alex David Santiago Vargas ([@AlexDCode](http://github.com/AlexDCode), [Google Scholar](https://scholar.google.com/citations?user=n_pFUoEAAAAJ&hl=en))
- PI: Dimitrios Peroulis ([Google Scholar](https://scholar.google.com/citations?user=agc3kMMAAAAJ&hl=en&oi=ao))
- Adaptive Radio Electronics and Sensors Group
- Purdue University

## Acknowledgments

### Funding
The authors acknowledge the funding provided by the Purdue **Summer Undergraduate Research Fellowship (SURF)**, the **Office of Undergraduate Research (OUR) Scholars** program, the **Elmore Family School of Electrical and Computer Engineering**, and the PI. Learn more about [SURF](https://engineering.purdue.edu/Engr/Research/EURO/students/about-SURF) and [Purdue ECE](http://engineering.purdue.edu/ECE).

### Open-Source Tools
- **[matlab2tikz](https://github.com/matlab2tikz/matlab2tikz)** for enabling high-quality $\LaTeX$-compatible plot exports. Copyright (c) 2008--2016 Nico Schlömer. All rights reserved.
> E. Geerardyn, N. Schlömer, et. al. (2025). "[matlab2tikz: Version 1.1.0](https://github.com/matlab2tikz/matlab2tikz)". Zenodo, Oct. 20, 2016. doi: 10.5281/zenodo.162246.
