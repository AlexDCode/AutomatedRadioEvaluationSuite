<p align="center">
  <img src="./src/support/ARES%20Icon.png" width="480"/>
<p \>
<h1 align="center">Automated Radio Evaluation Suite
</h1>

![Latest Release](https://img.shields.io/github/v/release/AlexDCode/AutomatedRadioEvaluationSuite?label=Latest%20Release)
[![Documentation Status](https://readthedocs.org/projects/aresapp/badge/?version=latest)](https://aresapp.readthedocs.io/en/latest/?badge=latest)
[![Star on GitHub](https://img.shields.io/github/stars/AlexDCode/AutomatedRadioEvaluationSuite?style=social)](https://github.com/AlexDCode/AutomatedRadioEvaluationSuite/stargazers)
[![GitHub Forks](https://img.shields.io/github/forks/AlexDCode/AutomatedRadioEvaluationSuite?style=social)](https://github.com/AlexDCode/AutomatedRadioEvaluationSuite/network/members)
[![GitHub Issues](https://img.shields.io/github/issues/AlexDCode/AutomatedRadioEvaluationSuite)](https://github.com/AlexDCode/AutomatedRadioEvaluationSuite/issues)
[![GitHub Pull Requests](https://img.shields.io/github/issues-pr/AlexDCode/AutomatedRadioEvaluationSuite)](https://github.com/AlexDCode/AutomatedRadioEvaluationSuite/pulls)
![Contributors](https://img.shields.io/github/contributors/AlexDCode/AutomatedRadioEvaluationSuite)
[![License](https://img.shields.io/github/license/AlexDCode/AutomatedRadioEvaluationSuite)](https://github.com/AlexDCode/AutomatedRadioEvaluationSuite/blob/main/LICENSE.txt)


The **Automated Radio Evaluation Suite (ARES)** enables automated RF measurements for power amplifiers and antennas interfacing seamlessly with existing laboratory equipment using standard communication protocols and offering a comprehensive and user-friendly interface. Unlike commercial software, this app is open-source, customizable, and free. Download the [latest release](https://github.com/AlexDCode/AutomatedRadioEvaluationSuite/releases) and follow the [Getting Started](https://aresapp.readthedocs.io/latest/getting_started.html) guide to learn how to use it. Tutorials for [Instrument Database](https://aresapp.readthedocs.io/latest/tutorial_instr.html), [Antenna Measurement](https://aresapp.readthedocs.io/latest/tutorial_ant.html), and [PA Measurements](https://aresapp.readthedocs.io/latest/tutorial_PA.html) are available. All the documentation is hosted on [Read the Docs](https://aresapp.readthedocs.io/).

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

- VISA Instrument Control for multiple Keysight and ETS-Lindgren instruments by GPIB and LAN
- Measure RF power amplifier Figures of Merit (FoM) over one or multiple frequencies
  - Gain
  - Output Power
  - Drain Efficiency
  - Power Added Efficiency
- Measure antenna gain characteristics by:
  - Gain Comparison Method (i.e., Two-Antenna Method)
  - Gain Transfer Method (i.e., Comparison Antenna Method) using a reference measurement
- Measure antenna return loss (magnitude and phase).
- Save and recall measurements in standardized file formats for data analysis.
- Plot measurement results within the app for quick visualization.
- Export plots in standard formats (PDF, PNG, JPEG) and TikZ for publication (TikZ export is unsupported for polar plots)

## TODO

- **How It Works**: Provide an overview of the app's inner workings, explaining how it communicates with instruments, processes measurements, and the general workflow.
- **Update PA Documentation Images**: Showing new UI and plotting options.
- **Advanced Features**: Save and load test parameters with custom configurations and unique app settings with a JSON file. Add MATLAB-style toolbar and resizable panels.
- **Antenna Measurements**: Add capabilities to measure antenna directivity, efficiency, and polarization. Enable measurement of circular polarized antennas.
- **Over the Air Testing (OTA)**: Measure RF transceivers (PAs, Antennas, LNAs, etc.) with modulated signals and plot the results. Enable measurements with the presence of interferers.
- **Instrument Type Filter**: Filter the instrument address dropdown by instrument type and only display the instruments pertaining relevant category and 'Others'.
- **Known Limitation**: The linear slider range and offset are hard coded in the app. The default values are for the Purdue's Anechoic Chamber setup (2m slider range and offset 0.8062m). You can modify the `LINEAR_SLIDER_RANGE` and `offsetSpacing` variables in ARES.MLAPP to fit a different setup. This could be added to instrument database properties.


## Usage

### [Installing ARES](https://aresapp.readthedocs.io/latest/getting_started.html)

### [Instrumnet Database Tutorial](https://aresapp.readthedocs.io/latest/tutorial_instr.html)

### [PA Measurement Tutorial](https://aresapp.readthedocs.io/latest/tutorial_PA.html)

### [Antenna Measurement Tutorial](https://aresapp.readthedocs.io/latest/tutorial_ant.html)


## Contributions

<p align="center">
  <img src="./docs/assets/ARES_logo.jpg" width="240"/>
<p \>
  
- Author: José Abraham Bolaños Vargas ([@bolanosv](http://github.com/bolanosv))
- Mentor: Alex David Santiago Vargas ([@AlexDCode](http://github.com/AlexDCode), [Google Scholar](https://scholar.google.com/citations?user=n_pFUoEAAAAJ&hl=en))
- PI: Dimitrios Peroulis ([Google Scholar](https://scholar.google.com/citations?user=agc3kMMAAAAJ&hl=en&oi=ao))
- Adaptive Radio Electronics and Sensors Group
- Purdue University
