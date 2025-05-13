# Getting Started

## Requirements

---

To run the Automated Radio Evaluation Suite (ARES), ensure the following software is installed:

- [MATLAB](https://www.mathworks.com/products/matlab.html) R2023b or above.
- [MATLAB Instrument Control Toolbox](https://www.mathworks.com/products/instrument.html) (for VISA communication)
- [MATLAB RF Toolbox](https://www.mathworks.com/products/rftoolbox.html) (for S-parameter analysis)
- [MATLAB Antenna Toolbox](https://www.mathworks.com/products/antenna.html) (for 3D radiation pattern visualization)
- [Keysight Connection Expert](https://www.keysight.com/us/en/lib/software-detail/computer-software/io-libraries-suite-downloads-2175637.html) (for VISA drivers; Install the pre-requisite first, then the main installer)

## Download and Install

---

1. Download the latest release of the Automated Radio Evaluation Suite from [releases](https://github.com/bolanosv/AutomatedRadioEvaluationSuite/releases).
2. **If using the MATLAB App installer**: Follow the instructions in the [Packaging and Installing MATLAB Apps Guide](https://www.mathworks.com/videos/packaging-and-installing-matlab-apps-70404.html).


## Network Configuration

---

Skip this section if you only intend to use the app for plotting previously collected data.

Skip this section if you're using USB or GPIB. No additional configuration is needed when using USB or GPIB connections.

For LAN-based communication, ensure the PC is on the same network as your instruments and apply the following manual network settings:
1. **Connect via Wi-Fi or Ethernet** to the same local network as your lab instruments.
2. **Set the following IPV4 configuration**: Ensure your device’s IP address is set up with the following network settings to connect to the instruments within the ARES Lab:
   - **IP Address**: `192.168.0.XXX` (where `XXX` is between 2 and 255).
   - **Default Gateway**: `192.168.1.1`
   - **Subnet Mask**: `255.255.0.0` (This enables accessing instruments with IP addresses in `192.168.XXX.XXX`)
   - **DNS Servers**:
     - Primary: `128.210.11.5`
     - Alternate: `128.210.11.57`

To verify connectivity, open a terminal or command prompt and `ping` the IP address of the intended instrument in the command window. If this is successful for the desired instrument, the network settings are appropriate.

## Compatibility

---

ARES has been tested and is compatible with the following instruments:

- **Keysight PNA-L N5235B** — 4-Port Network Analyzer
- **Keysight E36233A/E36234A** — Dual Output DC Power Supplies
- **Keysight CXA** — Signal Analyzer
- **Keysight PXA** — Signal Analyzer
- **Rohde & Schwarz SMW200A** — Signal Generator
- **Hewlett-Packard E4433B** — Signal Generator
- **ETS Lindgren EMCenter** — Position Controller
- **ETS Lindgren Linear Slider** — Slider Controller

Other SCPI-compatible instruments may also work, provided they support the same command set as those listed.
