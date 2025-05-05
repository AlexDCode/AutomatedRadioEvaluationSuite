# Home

[![Latest Release](https://img.shields.io/github/v/release/AlexDCode/AutomatedRadioEvaluationSuite?label=Latest%20Release)](https://github.com/AlexDCode/AutomatedRadioEvaluationSuite/releases)
[![Star on GitHub](https://img.shields.io/github/stars/AlexDCode/AutomatedRadioEvaluationSuite?style=social)](https://github.com/AlexDCode/AutomatedRadioEvaluationSuite/stargazers)
[![GitHub Forks](https://img.shields.io/github/forks/AlexDCode/AutomatedRadioEvaluationSuite?style=social)](https://github.com/AlexDCode/AutomatedRadioEvaluationSuite/network/members)
[![GitHub Issues](https://img.shields.io/github/issues/AlexDCode/AutomatedRadioEvaluationSuite)](https://github.com/AlexDCode/AutomatedRadioEvaluationSuite/issues)
[![GitHub Pull Requests](https://img.shields.io/github/issues-pr/AlexDCode/AutomatedRadioEvaluationSuite)](https://github.com/AlexDCode/AutomatedRadioEvaluationSuite/pulls)
[![Contributors](https://img.shields.io/github/contributors/AlexDCode/AutomatedRadioEvaluationSuite)](https://github.com/AlexDCode/AutomatedRadioEvaluationSuite/graphs/contributors)
[![License](https://img.shields.io/badge/License-MIT-yellow.svg)](https://github.com/AlexDCode/AutomatedRadioEvaluationSuite/blob/main/LICENSE.txt)


The **Automated Radio Evaluation Suite (ARES)** enables automated RF measurements for power amplifiers and antennas, interfacing seamlessly with existing laboratory equipment using standard communication protocols and offering a comprehensive and user-friendly interface. Unlike commercial software, this app is open-source, customizable, and free. Download the [latest release](https://github.com/AlexDCode/AutomatedRadioEvaluationSuite/releases) and follow the [Getting Started](https://aresapp.readthedocs.io/latest/getting_started.html) guide to learn how to use it. Tutorials for [Instrument Database](https://aresapp.readthedocs.io/latest/tutorial_instr.html), [Antenna Measurement](https://aresapp.readthedocs.io/latest/tutorial_ant.html), and [PA Measurements](https://aresapp.readthedocs.io/latest/tutorial_PA.html) are available. All the documentation is hosted on [Read the Docs](https://aresapp.readthedocs.io/).

## Features

- VISA Instrument Control for multiple Keysight and ETS-Lindgren instruments by GPIB, USB, and LAN.
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
- Export plots in standard formats (PDF, PNG, JPEG) and TikZ for publication (TikZ export is unsupported for polar plots).

## Contributors

```{image} ./../../../docs/assets/ARES_logo.jpg
:alt: ARES Lab Logo
:class: bg-primary
:width: 240px
:align: center
```


- Author: José Abraham Bolaños Vargas ([@bolanosv](http://github.com/bolanosv))
- Mentor: Alex David Santiago Vargas ([@AlexDCode](http://github.com/AlexDCode), [Google Scholar](https://scholar.google.com/citations?user=n_pFUoEAAAAJ&hl=en))
- PI: Dimitrios Peroulis ([Google Scholar](https://scholar.google.com/citations?user=agc3kMMAAAAJ&hl=en&oi=ao))
- Adaptive Radio Electronics and Sensors Group
- Purdue University

## Acknowledgments

This project makes use of several open-source tools. The authors acknowledge the following 

- **[matlab2tikz](https://github.com/matlab2tikz/matlab2tikz)** for enabling high-quality $\LaTeX$-compatible plot exports. Copyright (c) 2008--2016 Nico Schlömer All rights reserved.
> E. Geerardyn, N. Schlömer, et. al. (2025). "[matlab2tikz: Version 1.1.0](https://github.com/matlab2tikz/matlab2tikz)". Zenodo, Oct. 20, 2016. doi: 10.5281/zenodo.162246.
