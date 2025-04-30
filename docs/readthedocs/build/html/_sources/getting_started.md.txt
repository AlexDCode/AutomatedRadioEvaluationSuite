# Getting Started

## Requirements

To run the app, you will need:

- [MATLAB](https://www.mathworks.com/products/matlab.html) R2023b or above.
- [MATLAB Instrument Control Toolbox](https://www.mathworks.com/products/instrument.html) (for VISA control functions)
- [MATLAB RF Toolbox](https://www.mathworks.com/products/rftoolbox.html) (to read and analyze S-parameter data)
- [Keysight Connection Expert](https://www.keysight.com/us/en/lib/software-detail/computer-software/io-libraries-suite-downloads-2175637.html) (for VISA drivers; Install the pre-requisite first, then the main installer)

## Download and Install

- Download the latest release of the Automated Radio Evaluation Suite from [releases](https://github.com/bolanosv/AutomatedRadioEvaluationSuite/releases).
  - **For the MATLAB App**: Follow the instructions in the [Packaging and Installing MATLAB Apps Guide](https://www.mathworks.com/videos/packaging-and-installing-matlab-apps-70404.html).


## Network Configuration

If the app is only being used to plot, this can be skipped. If it will be usead for measurement, it is required.

1. **WiFi or Ethernet**: Connect to the same network as the devices.
2. **IP Configuration**: Ensure your device’s IP address is set up with the following network settings to connect to the instruments within the ARES Lab:
   - **IPV4 Address**: 192.168.0.XXX (where XXX is between 2 and 255).
   - **Gateway**: 192.168.1.1
   - **Subnet Mask**: 255.255.0.0 (This enables accessing instruments with IP addresses in 192.168.XXX.XXX)
   - **DNS Servers**: Primary: 128.210.11.5, Alternate: 128.210.11.57.

To test the network, ping the IP address of the intended instrument in the command window. If this is successful for the desired instruments the network settings are appropiate.

## Compatibility

The app has been tested and is compatible with the following instruments:

- **Keysight PNA-L N5235B** 4-Port Network Analyzer
- **Keysight E36233A/E36234A** Dual Output DC Power Supply
- **Keysight CXA** Signal Analyzer
- **Keysight PXA** Signal Analyzer
- **Agilent E3634A** DC Power Supply
- **Rohde & Schwarz SMW200A** Signal Generator
- **Hewlett-Packard E4433B** Signal Generator
- **ETS Lindgren EMCenter** Position Controller
- **ETS Lindgren Linear Slider**

Other instruments may be compatible given that they use the same SCPI commands as the listed devices.