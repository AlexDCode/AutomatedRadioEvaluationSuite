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


The **Automated Radio Evaluation Suite (ARES)** enables automated RF measurements for power amplifiers and antennas. Unlike commercial software, this app is open-source, customizable, and free. Download the [latest release](https://github.com/AlexDCode/AutomatedRadioEvaluationSuite/releases) and follow the [Getting Started](https://aresapp.readthedocs.io/latest/getting_started.html) guide to learn how to use it. Please note that the app is still in development, and some features may not be available in this release. All the documentation is hosted on [Read the Docs](https://aresapp.readthedocs.io/).

## Table of Contents

- [Table of Contents](#table-of-contents)
- [Features](#features)
- [TODO](#todo)
- [Install](#install)
  - [Download](#download)
  - [Requirements](#requirements)
- [Usage](#usage)
  - [PA Measurement Tutorial](#pa-measurement-tutorial)
  - [Antenna Measurement Tutorial](#antenna-measurement-tutorial)
- [Contributions](#contributions)

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
- Export plots in standard formats (PDF, PNG, JPEG) and TikZ for publication (TikZ export currently unsupported for polar plots)
- Plot measurement results within the app for quick visualization.

## TODO

- **Detailed Tutorials**: Improve the tutorials for each app functionality.
- **How It Works**: Provide an overview of the app's inner workings, explaining how it communicates with instruments, processes measurements, and the general workflow.
- **Advanced Features**: Save and load test parameters with custom configurations and unique app settings with JSON file. Add MATLAB style toolbar and resizable pannels.
- **FAQ**: Add a Frequently Asked Questions (FAQ) section to address common user inquiries and troubleshooting common difficulties.

## Install

[Getting Started Guide](https://aresapp.readthedocs.io/latest/getting_started.html) is available in the documentation.

### Download

- Download the latest release of the Automated Radio Evaluation Suite from [releases](https://github.com/bolanosv/AutomatedRadioEvaluationSuite/releases).
  - **For the MATLAB App**: Follow the instructions in the [Packaging and Installing MATLAB Apps Guide](https://www.mathworks.com/videos/packaging-and-installing-matlab-apps-70404.html).

### Requirements

To run the app, you will need:

- [MATLAB](https://www.mathworks.com/products/matlab.html)
- [MATLAB Instrument Control Toolbox](https://www.mathworks.com/products/instrument.html) (for VISA control functions)
- [MATLAB RF Toolbox](https://www.mathworks.com/products/rftoolbox.html) (to read and analyze S-parameter data)
- [Keysight Connection Expert](https://www.keysight.com/us/en/lib/software-detail/computer-software/io-libraries-suite-downloads-2175637.html) (for VISA drivers; Install the pre-requisite first, then the main installer)

## Usage

### [PA Measurement Tutorial](https://aresapp.readthedocs.io/latest/tutorial_PA.html)

### [Antenna Measurement Tutorial](https://aresapp.readthedocs.io/latest/tutorial_ant.html)

You can find the detailed tutorial for performing antenna measurements using ARES [here](docs/assets/Tutorials/Antenna%20Tutorial.pdf).

## Contributions

<p align="center">
  <img src="./docs/assets/ARES_logo.jpg" width="240"/>
<p \>
  
- Author: José Abraham Bolaños Vargas ([@bolanosv](http://github.com/bolanosv))
- Mentor: Alex David Santiago Vargas ([@AlexDCode](http://github.com/AlexDCode), [Google Scholar](https://scholar.google.com/citations?user=n_pFUoEAAAAJ&hl=en))
- PI: Dimitrios Peroulis ([Google Scholar](https://scholar.google.com/citations?user=agc3kMMAAAAJ&hl=en&oi=ao))
- Adaptive Radio Electronics and Sensors Group
- Purdue University
