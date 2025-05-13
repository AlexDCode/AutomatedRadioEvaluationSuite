# Automated Radio Evaluation Suite

[![Latest Release](https://img.shields.io/github/v/release/AlexDCode/AutomatedRadioEvaluationSuite?label=Latest%20Release)](https://github.com/AlexDCode/AutomatedRadioEvaluationSuite/releases)
[![Star on GitHub](https://img.shields.io/github/stars/AlexDCode/AutomatedRadioEvaluationSuite?style=social)](https://github.com/AlexDCode/AutomatedRadioEvaluationSuite/stargazers)
[![GitHub Forks](https://img.shields.io/github/forks/AlexDCode/AutomatedRadioEvaluationSuite?style=social)](https://github.com/AlexDCode/AutomatedRadioEvaluationSuite/network/members)
[![GitHub Issues](https://img.shields.io/github/issues/AlexDCode/AutomatedRadioEvaluationSuite)](https://github.com/AlexDCode/AutomatedRadioEvaluationSuite/issues)
[![GitHub Pull Requests](https://img.shields.io/github/issues-pr/AlexDCode/AutomatedRadioEvaluationSuite)](https://github.com/AlexDCode/AutomatedRadioEvaluationSuite/pulls)
[![Contributors](https://img.shields.io/github/contributors/AlexDCode/AutomatedRadioEvaluationSuite)](https://github.com/AlexDCode/AutomatedRadioEvaluationSuite/graphs/contributors)
[![License](https://img.shields.io/badge/License-MIT-yellow.svg)](https://github.com/AlexDCode/AutomatedRadioEvaluationSuite/blob/main/LICENSE.txt)

---

**ARES** is an open-source MATLAB-based platform for performing automated RF measurements on power amplifiers and antennas. It interfaces seamlessly with existing laboratory equipment via VISA (LAN, GPIB, USB), supporting streamlined data collection, visualization, and export, all within a graphical user interface. 

ARES is free, fully customizable, and actively maintained. It provides a cost-effective alternative to commercial measurement software and allows full transparency and control over your test flow. [Download the latest release.](https://github.com/AlexDCode/AutomatedRadioEvaluationSuite/releases) and [get started with the setup guide.](https://aresapp.readthedocs.io/latest/getting_started.html)

## Tutorials

---

Explore the functionality of ARES through guided documentation:

- [Instrument Database Tutorial](https://aresapp.readthedocs.io/latest/tutorial_instr.html)
- [Antenna Measurement Tutorial](https://aresapp.readthedocs.io/latest/tutorial_ant.html)
- [PA Measurement Tutorial](https://aresapp.readthedocs.io/latest/tutorial_PA.html) 

Full documentation is hosted on **[Read the Docs](https://aresapp.readthedocs.io/)**.

## Key Features

---

- VISA-based instrument control via **GPIB**, **LAN**, and **USB**
- Support for multiple ETS-Lindgren, Keysight, and Rohde & Schwarz instruments
- Built in deembedding support and DC power supply control
- PA FoM measurements:
  - Gain
  - Output Power
  - Drain Efficiency
  - Power Added Efficiency
- Antenna gain measurements:
  - Gain Comparison Method (i.e., Two-Antenna Method)
  - Gain Transfer Method (i.e., Comparison Antenna Method) using a reference measurement
  - Antenna return loss (magnitude & phase).
  - 2D/3D radiation pattern visualization
- Save/load test measurements in standardized file formats for data analysis.
- Plot test measurements within the app for quick visualization.
- Export plots to **PDF**, **PNG**, **JPEG**, and **TikZ** for publication

```{admonition} Export Tip
:class: note
TikZ export is supported for Cartesian 2D plots. Polar and 3D plots support PDF and image formats only.
```

## Contributors

---

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

---

This project makes use of several open-source tools. The authors acknowledge the following 

- **[matlab2tikz](https://github.com/matlab2tikz/matlab2tikz)** for enabling high-quality $\LaTeX$-compatible plot exports. Copyright (c) 2008--2016 Nico Schlömer All rights reserved.
> E. Geerardyn, N. Schlömer, et. al. (2025). "[matlab2tikz: Version 1.1.0](https://github.com/matlab2tikz/matlab2tikz)". Zenodo, Oct. 20, 2016. doi: 10.5281/zenodo.162246.
