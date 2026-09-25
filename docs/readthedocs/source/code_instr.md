# Instrument Factory

---

## AntennaMeasurementConfig.m
`Path: src\support\InstrumentControl\AntennaMeasurementConfig.m`

**Description:**

AntennaMeasurementConfig Snapshot + validation object for antenna measurement settings. Captures the dozens of individual ARES UI inputs as one plain data object so measurement code consumes a config instead of UI handles, and validation rules live (and are testable) in one place. Extended from the prototype with serialization — the paper's reproducibility goal ("settings can be saved alongside measurement data and later reloaded to repeat or modify experiments"): cfg.saveToJSON("run42_config.json")        % alongside the results cfg = AntennaMeasurementConfig.loadFromJSON("run42_config.json") UNITS / CONVENTIONS: TYPICAL USAGE (App callback): cfg = AntennaMeasurementConfig.fromApp(app); if ~cfg.validate(app.UIFigure), return; end runAntennaMeasurementOO(app, cfg, ...); Documentation for AntennaMeasurementConfig doc AntennaMeasurementConfig

- Frequencies in consistent units across start/end (ARES uses MHz)
- Angles in degrees; Theta = turntable, Phi = tower
- Modes are "Sweep" or "Single"

---

## AntennaPositioner.m
`Path: src\support\InstrumentControl\AntennaPositioner.m`

**Description:**

AntennaPositioner Wrapper for the ETS-Lindgren EMCenter dual-axis antenna positioner (turntable = theta, tower = phi) used in ARES antenna measurements. Hides axis naming ("1A"/"1B") and command formatting from measurement code, which then reads as physical intent: pos.setSpeeds(tableSpeed, towerSpeed); pos.moveTo(theta, phi); pos.waitUntilStill(); Adapted from paper's prototype with two integration changes: 1. CANCEL SUPPORT. waitUntilStill accepts a CancelFcn. ARES lets the operator stop a sweep from the progress dialog (d.CancelRequested in runAntennaMeasurement.m); the wait loop polls that function and stops both axes if it returns true. 2. SIMPLIFIED CONSTRUCTOR. An arguments block replaces the positional/name-value juggling in the prototype. The underlying EMCenter object must expose scpi() — i.e. be a SCPIInstrument (or subclass). Because SCPIInstrument is transport-backed, this positioner is automatically simulatable. Documentation for AntennaPositioner doc AntennaPositioner

---

## EmCenterSlider.m
`Path: src\support\InstrumentControl\EmCenterSlider.m`

**Description:**

EmCenterSlider Driver for the ETS-Lindgren EMCenter linear slider axis controller (raw TCP, default 192.168.0.100:1206). Manages a persistent connection so the slider is connected once at app startup and reused for every move — no reconnect churn per call. This is the paper's prototype folded onto the shared ITransport seam and merged with the hardened standalone slider work already in ARES (support/AntennaFunctions/setLinearSlider.m / homeLinearSlider.m): simulatable by injecting a SimTransport ("Transport" name-value). Functionality on real hardware is unchanged: same commands, same line protocol, same socket. error after TimeoutSec (default 120 s — full-rail at slowest preset takes ~90 s). The prototype could poll forever. procedure; getError() translates fault codes to readable text. else (the legacy script's mid-home AXIS:ZERO corrupted state). not exact float equality. (the prototype's `clear obj.Client` was a no-op leak). COORDINATE FRAMES: Device:   centimeters along the rail, as reported by AXIS:CP?. Physical: meters in the chamber frame, physical_m = DirectionSign*(device_cm/100) + Offset_m Offset_m defaults to 0.8062 m (Purdue chamber geometry, formerly hard-coded in ARES.mlapp). TYPICAL USAGE: s = EmCenterSlider("192.168.0.100", 1206, 1); s.setSpeedPreset(4); s.moveTo(120);                      % device cm, blocks until done p = s.getPhysicalPosition_m(); s.disconnect(); SIMULATION: t = SimTransport(); t.setResponse("AXIS1:LL?", "0"); t.setResponse("AXIS1:UL?", "200"); s = EmCenterSlider("sim", 0, 1, "Transport", t); Documentation for EmCenterSlider doc EmCenterSlider

- TRANSPORTBACKED. I/O goes through TcpTransport, so the slider is
- MOVE TIMEOUT. Blocking moves abort with AXIS:STOP and a clear
- FAULT CHECKING. home() checks AXIS:ERR? before and after the
- HOME WAITS CORRECTLY. The wait loop polls *OPC? and sends nothing
- POSITION TOLERANCE. "Already at target" uses a 0.5 cm tolerance,
- FIXED CLEANUP. Disconnect releases the socket via the transport

---

## HandleTransport.m
`Path: src\support\InstrumentControl\HandleTransport.m`

**Description:**

HandleTransport ITransport implementation that wraps an ALREADY-OPEN instrument handle (a visadev or tcpclient) that is owned by someone else — typically the ARES app, which stores raw handles in app.VNA, app.EMCenter, etc. This is the bridge that lets the migration happen incrementally without touching ARES.mlapp first: a measurement function can wrap app.VNA in a driver (via aresInstrument) and call high-level OO methods, while the app keeps owning and closing the underlying handle exactly as before. KEY PROPERTY: it does NOT own the handle. open() and close() are no-ops so wrapping/unwrapping never opens or closes the app's connection. Only the app (or whatever created the handle) is responsible for its life. USAGE (normally via aresInstrument, not directly): t   = HandleTransport(app.VNA);     % app.VNA is a live visadev vna = VNAInstCtrl("auto","auto","wrapped","Transport",t); vna.connect();                      % open() is a no-op; just *IDN? Documentation for HandleTransport doc HandleTransport

---

## HardwareLinkedSlider.m
`Path: src\support\InstrumentControl\HardwareLinkedSlider.m`

**Description:**

HardwareLinkedSlider UI slider subclass directly linked to a hardware linear slider (EmCenterSlider). Dragging the GUI control commands the physical hardware to the same position, keeping the "UI -> hardware" binding in one reusable class instead of per-callback glue in the App. Hardened from the prototype (which was marked WIP): no longer kills the App: the error is caught, the control reverts to its previous value, and the failure is reported via uialert. user cannot queue conflicting motion commands. USAGE (App startup): app.SliderHW = EmCenterSlider("192.168.0.100", 1206, 1); [ll, ul] = app.SliderHW.getLimits(); app.DistanceSlider = HardwareLinkedSlider( ... 'Parent', app.UIFigure, ... 'Limits', [ll, ul], ... 'Value',  app.SliderHW.getPosition()); app.DistanceSlider.Hardware = app.SliderHW; Units are device centimeters by default (set Limits/Value accordingly). Documentation for HardwareLinkedSlider doc HardwareLinkedSlider

- A hardware failure during the move (fault, timeout, outofrange)
- The control is disabled while a blocking move is in flight so the

---

## ITransport.m
`Path: src\support\InstrumentControl\ITransport.m`

**Description:**

ITransport Abstract transport interface for all ARES instrument I/O. This is the seam that separates "what command to send" (driver classes) from "how bytes move" (VISA, raw TCP, or simulation). Why this exists (paper goal: "bypassing VISA drivers when virtually testing"): by programming every driver against this interface instead of against visadev/tcpclient directly, any instrument can be backed by: VisaTransport - real hardware over VISA (GPIB / LAN / USB) TcpTransport  - real hardware over a raw TCP socket (EMCenter slider) SimTransport  - no hardware at all; scripted/synthetic responses Swapping a transport requires zero changes to driver or measurement code. Simulation stops being an `if obj.Simulate` special case inside every method and becomes just another transport implementation. CONTRACT (all concrete transports must implement): open()                  - establish the link (idempotent) close()                 - release the link and the underlying handle writeLine(cmd)          - send one terminated ASCII command s = readLine()          - read one terminated ASCII response (trimmed) d = readBinaryBlock(t)  - read an IEEE 488.2 definite-length binary block (equivalent of readbinblock); required for VNA / signal-analyzer trace transfers flush()                 - discard any unread input tf = isOpen()           - true if the link is currently usable PROVIDED (concrete convenience methods built on the contract): s = writeRead(cmd)      - writeLine followed by readLine Documentation for ITransport doc ITransport

---

## InstrumentFactory.m
`Path: src\support\InstrumentControl\InstrumentFactory.m`

**Description:**

InstrumentFactory Data-driven construction of instrument controllers from the ARES instrument database (instrumentAddresses.csv). Realizes the paper's §VIII.A design: "adding support for new hardware becomes primarily a data-entry task." CSV SCHEMA: "Keysight Technologies N5232B"). The model is taken as the last whitespace-separated token, which also selects the CommandSets/<Model>.json dialect file. Address     - VISA resource or "TCPIP::host::port::SOCKET" string. Type        - functional type label: VNA, PSU, Generator, Analyzer, Chamber, Slider. If absent/empty it is inferred from the Class       - controller class to instantiate. If absent/empty it is derived from Type via classForType(). Adding a new instrument to ARES is then: 1. one row in instrumentAddresses.csv 2. (only if its SCPI dialect differs) one JSON file in CommandSets/ No MATLAB code changes. TYPICAL USAGE (App startup): tbl = InstrumentFactory.readDatabase("instrumentAddresses.csv"); vna = InstrumentFactory.createFromRow(tbl(contains(tbl.Description,"N5232B"),:)); vna.connect(); Everything at once, simulated (headless dev / regression tests): instruments = InstrumentFactory.createAll(csvPath, "Simulate", true); Documentation for InstrumentFactory doc InstrumentFactory

---

## PSUInstCtrl.m
`Path: src\support\InstrumentControl\PSUInstCtrl.m`

**Description:**

PSUInstCtrl Driver for the DC power supplies used in ARES power-amplifier measurements (Keysight E36233A, dual-channel). DIALECT CORRECTION vs. THE PROTOTYPE: The prototype emitted "VOLT <V>,(@ch)" / "MEAS:VOLT? (@ch)". ARES's E36233A path — validated on hardware — uses the :APPLy and :MEAS:SCAL:* forms (see legacy setPSUChannels.m / measureCW.m / enablePSUChannels.m). This class registers the hardware-validated forms as its defaults; other supplies can re-dialect via CommandSets/<Model>.json without touching this class. SAFETY (bias sequencing): PA devices are sequenced gate-before-drain on enable and drain-before-gate on disable (so the FET is never drained without its gate bias). That ordering logic lives in the measurement layer (enablePSUChannels), which knows the gate/drain role of each logical channel; this driver deliberately exposes only per-supply primitives. TYPICAL USAGE: psu = PSUInstCtrl("Keysight", "E36233A", addr); psu.connect(); psu.apply(1, 28.0, 2.0);          % CH1: 28 V, 2 A limit psu.setOutputState([1 2], true);  % both channels on v = psu.measureVoltage(1); i = psu.measureCurrent(1); psu.setOutputState([1 2], false); psu.disconnect(); Documentation for PSUInstCtrl doc PSUInstCtrl

---

## SCPIInstrument.m
`Path: src\support\InstrumentControl\SCPIInstrument.m`

**Description:**

SCPIInstrument Base class for all ARES SCPI instruments. Adapted from "Object-Oriented MATLAB Framework for Instrument Control Within the ARES Platform") with the changes required for integration into the production ARES App: 1. TRANSPORT SEAM. I/O goes through an ITransport (VisaTransport, TcpTransport, or SimTransport) instead of a hardwired visadev. Simulation is now "just another transport" rather than an if-Simulate branch in every method. 2. BINARY-BLOCK TRANSFERS. The command registry and scpi() dispatcher understand `read: "binblock:double"` specs, and queryBinary() exposes raw binary reads. Required for VNA / signal-analyzer trace transfers (legacy readbinblock usage) — without this no VNA could be migrated. 3. JSON COMMAND DIALECTS. On construction, the class auto-loads CommandSets/<Model>.json (next to this file) if it exists. Adding support for a new instrument model is therefore a data-entry task: drop a JSON file, no class edits ("drop-in support of new instrument command sets without invasive code changes"). 4. LEGACY COMPATIBILITY SHIMS. writeline(obj,cmd), readline(obj), writeread(obj,cmd), readbinblock(obj,type), and flush(obj) are provided as methods. MATLAB dispatches function-call syntax to methods, so existing ARES helper functions like writeline(app.VNA, 'SENS1:SWE:MODE SING') keep working unchanged when app.VNA becomes a driver object. This is the staged-migration mechanism from paper §VII: legacy code paths remain available while workflows migrate one at a time. 5. FIXED DISCONNECT. The prototype's `clear obj.io` was a no-op that leaked connections; release now happens in the transport. TYPICAL USAGE: vna = VNAInstCtrl("Keysight", "N5232B", "TCPIP0::...::inst0::INSTR"); vna.connect(); [sdB, sPh, f] = vna.measureSParameters(1); vna.disconnect(); SIMULATION: vna = VNAInstCtrl("Keysight", "N5232B", "SIM", "Simulate", true); vna.connect();          % no hardware touched; SimTransport underneath Documentation for SCPIInstrument doc SCPIInstrument

---

## SignalAnalyzerInstCtrl.m
`Path: src\support\InstrumentControl\SignalAnalyzerInstCtrl.m`

**Description:**

SignalAnalyzerInstCtrl Driver for the signal/spectrum analyzers used in ARES power-amplifier measurements (Keysight N9000B CXA). ARES uses one as the output analyzer and, in "In-Situ Couplers" calibration mode, a second as the

```{admonition} Input Parameters
:class: tip
- prototype framework.
- Absorbs the analyzer SCPI from support/PAFunctions/measureCW.m,
- measureModulated.m, and runPAMeasurement.m: single-shot acquisition,
- frequency-axis reconstruction from center/span/points, and
- binary-block trace fetches.
- TYPICAL USAGE:
- sa = SignalAnalyzerInstCtrl("Keysight", "N9000B", addr);
- sa.connect();
- sa.setCenterFrequency(3.5e9);
- p = sa.measurePowerAt(3.5e9);     % dBm at the carrier
- sa.disconnect();
- Documentation for SignalAnalyzerInstCtrl
- doc SignalAnalyzerInstCtrl
```

---

## SignalGeneratorInstCtrl.m
`Path: src\support\InstrumentControl\SignalGeneratorInstCtrl.m`

**Description:**

SignalGeneratorInstCtrl Driver for the RF signal generators used in ARES power-amplifier measurements (Rohde & Schwarz SMW200A; HP/Agilent E4433B for legacy GPIB setups). Concrete controller that was missing from the prototype framework. Absorbs the generator SCPI currently embedded in support/PAFunctions/measureCW.m, measureModulated.m, and runPAMeasurement.m: CW power/frequency, RF output enable, and the digital-modulation (ARB) bring-up sequence. SAFETY: safeShutdown() reproduces the ARES safe-state idiom (power to -135 dBm AND RF output off) used before/after every PA sweep and in every error path. Keeping it as one named method means no error handler can forget half of the sequence. TYPICAL USAGE: sg = SignalGeneratorInstCtrl("Rohde & Schwarz", "SMW200A", addr); sg.connect(); sg.setFrequencyCW(3.5e9); sg.setPower(-10); sg.setOutputState(true); ... sweep ... sg.safeShutdown(); sg.disconnect(); Documentation for SignalGeneratorInstCtrl doc SignalGeneratorInstCtrl

---

## SimTransport.m
`Path: src\support\InstrumentControl\SimTransport.m`

**Description:**

SimTransport ITransport implementation with NO hardware behind it. Realizes the paper's goal of "simulated instruments, bypassing VISA drivers when virtually testing and debugging new features." Unlike the prototype's `Simulate` flag (which returned a fixed "SIM-RESPONSE" for everything), this transport is behavioral enough to run real ARES code paths headless: 1. Every command written is appended to CommandLog. This enables the regression strategy from paper §VII.B: run a measurement against SimTransport and diff the generated SCPI sequence against a known-good log captured from real hardware. 2. Responses are resolved in priority order: a. ResponseMap  - exact-match table you preload for the device (e.g. "AXIS1:LL?" -> "0", "AXIS1:UL?" -> "200") b. ResponseFcn  - your function handle f(cmd) -> string, for dynamic behavior (moving positions, sweeps) c. Built-in heuristics - *IDN? -> IdnString, *OPC? -> "1", SYST:ERR? -> '+0,"No error"', any other query -> "0" The defaults are chosen so wait loops terminate and parsers get parseable numbers, letting measurement code run to completion. 3. Binary-block queries (VNA/analyzer traces) are served by BinaryFcn if set, otherwise by zeros(1, DefaultTraceLength). USAGE: t = SimTransport("IdnString", "Keysight,N5232B,SIM,1.0"); t.setResponse("AXIS1:LL?", "0"); t.BinaryFcn = @(cmd, type) randn(1, 201);   % fake trace data ... disp(t.CommandLog)                          % audit what was sent Documentation for SimTransport doc SimTransport

---

## TcpTransport.m
`Path: src\support\InstrumentControl\TcpTransport.m`

**Description:**

TcpTransport ITransport implementation backed by a raw tcpclient socket. Used for devices that speak line-oriented ASCII over plain TCP rather than full VISA — in ARES that is the ETS-Lindgren EMCenter linear slider (192.168.0.100:1206, "TCPIP::...::1206::SOCKET" in the instrument CSV). Folding the slider onto the same transport interface as the VISA instruments means the EmCenterSlider driver gains, for free: USAGE: t = TcpTransport("192.168.0.100", 1206); t.open(); pos = t.writeRead("AXIS1:CP?"); t.close(); Or directly from a VISA-style socket resource string: t = TcpTransport.fromResource("TCPIP::192.168.0.100::1206::SOCKET"); Documentation for TcpTransport doc TcpTransport

- simulation support (back it with a SimTransport instead)
- the corrected close/cleanup semantics (no leaked sockets)
- uniform error behavior with every other instrument

---

## VNAInstCtrl.m
`Path: src\support\InstrumentControl\VNAInstCtrl.m`

**Description:**

VNAInstCtrl Driver for the vector network analyzers used in ARES antenna measurements (Keysight N5232B PNA-L, Agilent E5072A ENA). This is the concrete VNA controller that was missing from the prototype framework (only the TemplateInstCtrl placeholder existed). It absorbs all VNA SCPI from the legacy support/AntennaFunctions/measureSParameters.m, including the binary-block trace transfers that the prototype base class could not perform. DIALECT: Default registered commands use the Keysight PNA/ENA syntax that ARES currently runs on hardware. A different VNA model can re-dialect any of them by dropping CommandSets/<Model>.json next to the framework — no edits to this class (see SCPIInstrument header, feature 3). ASSUMED TRACE LAYOUT (matches the legacy ARES VNA state file): trace 1: S11 mag   trace 2: S11 phase trace 3: S21 mag   trace 4: S21 phase trace 5: S22 mag   trace 6: S22 phase TYPICAL USAGE: vna = VNAInstCtrl("Keysight", "N5232B", "TCPIP0::...::inst0::INSTR"); vna.connect(); [sdB, sPhase, freqs] = vna.measureSParameters(smoothingPoints); vna.setContinuous(true);   % restore live sweeping for the operator vna.disconnect(); Documentation for VNAInstCtrl doc VNAInstCtrl

---

## VisaTransport.m
`Path: src\support\InstrumentControl\VisaTransport.m`

**Description:**

VisaTransport ITransport implementation backed by a MATLAB visadev object. Used for every VISA-addressable ARES instrument (VNA, signal generator, signal analyzers, PSUs, EMCenter positioner) over GPIB, LAN, or USB. This class owns the visadev handle exclusively. Driver classes never see it, which is what makes drivers transport-agnostic and simulatable. NOTE ON CLEANUP: The original prototype framework called `clear obj.Device` to release the handle. That is a silent no-op in MATLAB (it clears a *variable* named "obj.Device", which doesn't exist) and the property kept the connection alive — the same stale-connection leak ARES suffered from in the legacy slider scripts. The correct release is to drop the last reference by assigning [] (done in close()). USAGE: t = VisaTransport("TCPIP0::192.168.1.161::inst0::INSTR"); t.open(); idn = t.writeRead("*IDN?"); t.close(); Documentation for VisaTransport doc VisaTransport

---

## aresConnectInstrument.m
`Path: src\support\InstrumentControl\aresConnectInstrument.m`

**Description:**

aresConnectInstrument Build, connect, and return the object-oriented driver for an ARES instrument, given the app's instrument property name and its VISA/socket resource string. This is the drop-in replacement for the legacy two lines in the ARES.mlapp connect callback: app.(instrumentName) = visadev(instrumentResource); app.(instrumentName).ByteOrder = 'little-endian'; which become, after migration, simply: app.(instrumentName) = aresConnectInstrument(instrumentName, instrumentResource); Every subsequent legacy call in the app and support functions (writeline/writeread/readbinblock/flush on app.(name)) keeps working because the returned drivers expose those as methods; new code can use the high-level driver methods instead.

```{admonition} Input Parameters
:class: tip
- instrumentName - app property name: "VNA", "SignalGenerator",
- "InputSignalAnalyzer", "OutputSignalAnalyzer",
- "PowerSupplyA", "PowerSupplyB", "EMCenter", "EMSlider"
- resource       - VISA resource or "TCPIP::host::port::SOCKET" string
```

```{admonition} Output Parameters
:class: tip
- inst - connected driver object
```

---

## aresInstrument.m
`Path: src\support\InstrumentControl\aresInstrument.m`

**Description:**

aresInstrument Adapter that returns an object-oriented driver for an ARES instrument, whether the app currently stores it as a RAW handle (visadev/tcpclient) or already as a framework driver object. This is the linchpin of the incremental migration. A measurement function can do: vna = aresInstrument(app.VNA, "VNA"); [sdB, sPh, f] = vna.measureSParameters(smoothing); and it works: wraps it in a non-owning HandleTransport (the app keeps owning the connection) and returns a VNAInstCtrl. this returns it unchanged (idempotent). Either way the app keeps working and nothing double-opens or double-closes the underlying connection.

- BEFORE ARES.mlapp is migrated: app.VNA is a raw visadev, so this
- AFTER ARES.mlapp is migrated: app.VNA is already a VNAInstCtrl, so

```{admonition} Input Parameters
:class: tip
- handle - a raw visadev/tcpclient OR an existing framework driver
- role   - "VNA" | "PSU" | "Generator" | "Analyzer" | "Chamber" |
- "Slider" (case-insensitive)
```

```{admonition} Output Parameters
:class: tip
- inst - the matching driver object, connected and ready
```

---

## instrumentDropdownItems.m
`Path: src\support\InstrumentControl\instrumentDropdownItems.m`

**Description:**

INSTRUMENTDROPDOWNITEMS  Dropdown entries for one instrument type. Returns a cellstr suitable for a dropdown's Items property, containing only the instruments whose Type column matches `type` — so the VNA dropdown lists only VNAs, the PSU dropdown only PSUs, etc. This prevents connecting the wrong kind of instrument to a slot (e.g. an EMCenter where a VNA belongs). Each entry is "Description: Address", sorted, with 'NA: None' first (matching the app's existing dropdown format).

```{admonition} Input Parameters
:class: tip
- dataTable - the instrument table read from instrumentAddresses.csv
- (must have Description and Address columns; Type optional)
- type      - instrument type to keep: "VNA","PSU","Generator",
- "Analyzer","Chamber","Slider". Pass "" or "all" for every
- instrument (legacy, unfiltered behavior).
```

```{admonition} Output Parameters
:class: tip
- items - cellstr, e.g. {'NA: None'; 'Keysight Technologies N5232B: TCPIP0::...'}
- USAGE (in the app's loadInstrumentAddressestoApp):
- app.VNADropDown.Items = instrumentDropdownItems(dataTable, "VNA");
```

