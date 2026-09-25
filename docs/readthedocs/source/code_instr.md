# Instrument Factory

---

## AntennaMeasurementConfig.m
`Path: src\support\InstrumentControl\AntennaMeasurementConfig.m`

**Description:**

AntennaMeasurementConfig Snapshot + validation object for antenna measurement settings. Captures the dozens of individual ARES UI inputs as one plain data object so measurement code consumes a config instead of UI handles, and validation rules live (and are testable) in one place. A config serializes to JSON, so settings can be saved alongside the measurement data and reloaded later to repeat or modify an experiment.

**Conventions**

- Frequencies in consistent units across start/end (ARES uses MHz)
- Angles in degrees; Theta = turntable, Phi = tower
- Modes are "Sweep" or "Single"

**Usage**

From an app callback:

```matlab
cfg = AntennaMeasurementConfig.fromApp(app);
if ~cfg.validate(app.UIFigure), return; end
runAntennaMeasurementOO(app, cfg, ...);
cfg.saveToJSON("run42_config.json");       % alongside the results
cfg = AntennaMeasurementConfig.loadFromJSON("run42_config.json");
```

---

## AntennaPositioner.m
`Path: src\support\InstrumentControl\AntennaPositioner.m`

**Description:**

AntennaPositioner Wrapper for the ETS-Lindgren EMCenter dual-axis antenna positioner (turntable = theta, tower = phi) used in ARES antenna measurements. Hides axis naming ("1A"/"1B") and command formatting from measurement code, which then reads as physical intent: pos.setSpeeds(tableSpeed, towerSpeed); pos.moveTo(theta, phi); pos.waitUntilStill();

**Notes**

- waitUntilStill accepts a CancelFcn so an operator can stop a sweep from the progress dialog. The wait loop polls that function and stops both axes if it returns true.
- The underlying EMCenter object must expose scpi(), meaning it is a SCPIInstrument or a subclass. Because SCPIInstrument is transport-backed, this positioner is simulatable without changes.

---

## EmCenterSlider.m
`Path: src\support\InstrumentControl\EmCenterSlider.m`

**Description:**

EmCenterSlider Driver for the ETS-Lindgren EMCenter linear slider axis controller (raw TCP, default 192.168.0.100:1206). Manages a persistent connection so the slider is connected once at app startup and reused for every move — no reconnect churn per call.

**Behavior**

- Transport-backed. I/O goes through TcpTransport, so the slider is simulatable by injecting a SimTransport ("Transport" name-value).
- Move timeout. Blocking moves abort with AXIS:STOP and a clear error after TimeoutSec, default 120 s, since a full-rail move at the slowest preset takes about 90 s.
- Fault checking. home() checks AXIS:ERR? before and after the procedure, and getError() translates fault codes to readable text.
- Homing. The wait loop polls *OPC? and sends nothing else, because sending AXIS:ZERO mid-home corrupts the position reference.
- Position tolerance. "Already at target" uses a 0.5 cm tolerance rather than exact float equality.
- Cleanup. disconnect() releases the socket through the transport.

**Coordinate frames**

- Device:   centimeters along the rail, as reported by AXIS:CP?. Physical: meters in the chamber frame, physical_m = DirectionSign*(device_cm/100) + Offset_m Offset_m defaults to 0.8062 m (Purdue chamber geometry, formerly hard-coded in ARES.mlapp).

**Usage**

```matlab
s = EmCenterSlider("192.168.0.100", 1206, 1);
s.setSpeedPreset(4);
s.moveTo(120);                      % device cm, blocks until done
p = s.getPhysicalPosition_m();
s.disconnect();
```

**Simulation**

- t = SimTransport(); t.setResponse("AXIS1:LL?", "0"); t.setResponse("AXIS1:UL?", "200"); s = EmCenterSlider("sim", 0, 1, "Transport", t);

---

## HandleTransport.m
`Path: src\support\InstrumentControl\HandleTransport.m`

**Description:**

HandleTransport ITransport implementation that wraps an ALREADY-OPEN instrument handle (a visadev or tcpclient) that is owned by someone else — typically the ARES app, which stores raw handles in app.VNA, app.EMCenter, etc. It lets a measurement function wrap a handle the app already holds (via aresInstrument) and call high-level driver methods on it, while the app keeps owning and closing the underlying handle exactly as before.

**Notes**

- This transport does not own the handle. open() and close() are no-ops, so wrapping or unwrapping never opens or closes the app's connection. Whatever created the handle stays responsible for its lifetime.

**Usage**

Normally reached through aresInstrument rather than constructed here:

```matlab
t   = HandleTransport(app.VNA);     % app.VNA is a live visadev
vna = VNAInstCtrl("auto","auto","wrapped","Transport",t);
vna.connect();                      % open() is a no-op; just *IDN?
```

---

## HardwareLinkedSlider.m
`Path: src\support\InstrumentControl\HardwareLinkedSlider.m`

**Description:**

HardwareLinkedSlider UI slider subclass directly linked to a hardware linear slider (EmCenterSlider). Dragging the GUI control commands the physical hardware to the same position, keeping the "UI -> hardware" binding in one reusable class instead of per-callback glue in the App.

**Behavior**

- A hardware failure during the move, whether a fault, a timeout or an out-of-range target, does not kill the app. The error is caught, the control reverts to its previous value, and the failure is reported through uialert.
- The control is disabled while a blocking move is in flight, so the user cannot queue conflicting motion commands.

**Usage**

At app startup:

```matlab
app.SliderHW = EmCenterSlider("192.168.0.100", 1206, 1);
[ll, ul] = app.SliderHW.getLimits();
app.DistanceSlider = HardwareLinkedSlider( ...
'Parent', app.UIFigure, ...
'Limits', [ll, ul], ...
'Value',  app.SliderHW.getPosition());
app.DistanceSlider.Hardware = app.SliderHW;
Units are device centimeters by default (set Limits/Value accordingly).
```

---

## ITransport.m
`Path: src\support\InstrumentControl\ITransport.m`

**Description:**

ITransport Abstract transport interface for all ARES instrument I/O. This is the seam that separates "what command to send" (driver classes) from "how bytes move" (VISA, raw TCP, or simulation). Every driver is written against this interface rather than against visadev or tcpclient directly, so any instrument can be backed by: VisaTransport - real hardware over VISA (GPIB / LAN / USB) TcpTransport  - real hardware over a raw TCP socket (EMCenter slider) SimTransport  - no hardware at all; scripted or synthetic responses Swapping a transport requires no changes to driver or measurement code, which makes simulation another transport rather than a special case inside every method.

**Contract**

- Every concrete transport must implement:
- open()                  - establish the link (idempotent)
- close()                 - release the link and the underlying handle
- writeLine(cmd)          - send one terminated ASCII command
- s = readLine()          - read one terminated ASCII response (trimmed)
- d = readBinaryBlock(t)  - read an IEEE 488.2 definite-length binary block (equivalent of readbinblock); required for VNA / signal-analyzer trace transfers
- flush()                 - discard any unread input
- tf = isOpen()           - true if the link is currently usable

**Provided methods**

- Built on the contract above, available to every transport:
- s = writeRead(cmd)      - writeLine followed by readLine

---

## InstrumentFactory.m
`Path: src\support\InstrumentControl\InstrumentFactory.m`

**Description:**

InstrumentFactory Data-driven construction of instrument controllers from the ARES instrument database (instrumentAddresses.csv), so that supporting new hardware is primarily a data-entry task.

**CSV schema**

- Description, Address, Type[, Class]
- Description - human-readable "Manufacturer Model" (e.g. "Keysight Technologies N5232B"). The model is taken as the last whitespace-separated token, which also selects the CommandSets/<Model>.json dialect file.
- Address     - VISA resource or "TCPIP::host::port::SOCKET" string.
- Type        - functional type label: VNA, PSU, Generator, Analyzer, Chamber, Slider. If absent/empty it is inferred from the Description (SCPIInstrument.guessTypeFromModelOrRole).
- Class       - controller class to instantiate. If absent/empty it is derived from Type via classForType(). Adding a new instrument then takes no MATLAB code changes: 1. one row in instrumentAddresses.csv 2. one JSON file in CommandSets/, only if its SCPI dialect differs

**Usage**

At app startup:

```matlab
tbl = InstrumentFactory.readDatabase("instrumentAddresses.csv");
vna = InstrumentFactory.createFromRow(tbl(contains(tbl.Description,"N5232B"),:));
vna.connect();
Everything at once, simulated (headless dev / regression tests):
instruments = InstrumentFactory.createAll(csvPath, "Simulate", true);
```

---

## PSUInstCtrl.m
`Path: src\support\InstrumentControl\PSUInstCtrl.m`

**Description:**

PSUInstCtrl Driver for the DC power supplies used in ARES power-amplifier measurements (Keysight E36233A, dual-channel).

**Dialect**

- The registered defaults are the :APPLy and :MEAS:SCAL:* forms, which are the ones validated against the E36233A on hardware. Supplies that expect a different syntax, such as the "VOLT <V>,(@ch)" and "MEAS:VOLT? (@ch)" forms, can be re-dialected through CommandSets/<Model>.json without touching this class.

**Safety**

- PA devices are sequenced gate-before-drain on enable and drain-before-gate on disable (so the FET is never drained without its gate bias). That ordering logic lives in the measurement layer (enablePSUChannels), which knows the gate/drain role of each logical channel; this driver deliberately exposes only per-supply primitives.

**Usage**

```matlab
psu = PSUInstCtrl("Keysight", "E36233A", addr);
psu.connect();
psu.apply(1, 28.0, 2.0);          % CH1: 28 V, 2 A limit
psu.setOutputState([1 2], true);  % both channels on
v = psu.measureVoltage(1);
i = psu.measureCurrent(1);
psu.setOutputState([1 2], false);
psu.disconnect();
```

---

## SCPIInstrument.m
`Path: src\support\InstrumentControl\SCPIInstrument.m`

**Description:**

SCPIInstrument Base class for all ARES SCPI instruments. It owns the command registry, the transport, and the shared connect/query/error handling that every driver builds on.

**Behavior**

- Transport seam. I/O goes through an ITransport (VisaTransport, TcpTransport, or SimTransport) instead of a hardwired visadev, so simulation is another transport rather than an if-Simulate branch in every method.
- Binary-block transfers. The command registry and the scpi() dispatcher understand `read: "binblock:double"` specs, and queryBinary() exposes raw binary reads. These are required for VNA and signal-analyzer trace transfers.
- JSON command dialects. On construction the class auto-loads CommandSets/<Model>.json, next to this file, if it exists. Adding support for a new instrument model is therefore a data-entry task: drop in a JSON file, with no class edits.
- Compatibility shims. writeline(obj,cmd), readline(obj), writeread(obj,cmd), readbinblock(obj,type) and flush(obj) are provided as methods. MATLAB dispatches function-call syntax to methods, so a helper written as writeline(app.VNA, 'SENS1:SWE:MODE SING') keeps working when app.VNA becomes a driver object.
- Disconnect releases the connection through the transport, rather than leaking it.

**Usage**

```matlab
vna = VNAInstCtrl("Keysight", "N5232B", "TCPIP0::...::inst0::INSTR");
vna.connect();
[sdB, sPh, f] = vna.measureSParameters(1);
vna.disconnect();
```

**Simulation**

- vna = VNAInstCtrl("Keysight", "N5232B", "SIM", "Simulate", true); vna.connect();          % no hardware touched; SimTransport underneath

---

## SignalAnalyzerInstCtrl.m
`Path: src\support\InstrumentControl\SignalAnalyzerInstCtrl.m`

**Description:**

SignalAnalyzerInstCtrl Driver for the signal/spectrum analyzers used in ARES power-amplifier measurements (Keysight N9000B CXA). ARES uses one as the output analyzer and, in "In-Situ Couplers" calibration mode, a second as the input analyzer. It owns the analyzer SCPI used by the PA measurement path: single-shot acquisition, frequency-axis reconstruction from center, span and points, and binary-block trace fetches.

**Usage**

```matlab
sa = SignalAnalyzerInstCtrl("Keysight", "N9000B", addr);
sa.connect();
sa.setCenterFrequency(3.5e9);
p = sa.measurePowerAt(3.5e9);     % dBm at the carrier
sa.disconnect();
```

---

## SignalGeneratorInstCtrl.m
`Path: src\support\InstrumentControl\SignalGeneratorInstCtrl.m`

**Description:**

SignalGeneratorInstCtrl Driver for the RF signal generators used in ARES power-amplifier measurements (Rohde & Schwarz SMW200A, and HP/Agilent E4433B for GPIB setups). It owns the generator SCPI used by the PA measurement path: CW power and frequency, RF output enable, and the digital-modulation (ARB) bring-up sequence.

**Safety**

- safeShutdown() applies the safe state used before and after every PA sweep and in every error path: power to -135 dBm and RF output off. Keeping it as one named method means no error handler can forget half of the sequence.

**Usage**

```matlab
sg = SignalGeneratorInstCtrl("Rohde & Schwarz", "SMW200A", addr);
sg.connect();
sg.setFrequencyCW(3.5e9);
sg.setPower(-10);
sg.setOutputState(true);
... sweep ...
sg.safeShutdown();
sg.disconnect();
```

---

## SimTransport.m
`Path: src\support\InstrumentControl\SimTransport.m`

**Description:**

SimTransport ITransport implementation with no hardware behind it, used to test and debug measurement code without a bench. Responses are behavioral rather than fixed, so real ARES code paths run to completion headless: 1. Every command written is appended to CommandLog. A measurement can be run against SimTransport and the generated SCPI sequence diffed against a known-good log captured from real hardware. 2. Responses are resolved in priority order: a. ResponseMap  - exact-match table you preload for the device (e.g. "AXIS1:LL?" -> "0", "AXIS1:UL?" -> "200") b. ResponseFcn  - your function handle f(cmd) -> string, for dynamic behavior (moving positions, sweeps) c. Built-in heuristics - *IDN? -> IdnString, *OPC? -> "1", SYST:ERR? -> '+0,"No error"', any other query -> "0" The defaults are chosen so wait loops terminate and parsers get parseable numbers, letting measurement code run to completion. 3. Binary-block queries (VNA/analyzer traces) are served by BinaryFcn if set, otherwise by zeros(1, DefaultTraceLength).

**Usage**

```matlab
t = SimTransport("IdnString", "Keysight,N5232B,SIM,1.0");
t.setResponse("AXIS1:LL?", "0");
t.BinaryFcn = @(cmd, type) randn(1, 201);   % fake trace data
...
disp(t.CommandLog)                          % audit what was sent
```

---

## TcpTransport.m
`Path: src\support\InstrumentControl\TcpTransport.m`

**Description:**

TcpTransport ITransport implementation backed by a raw tcpclient socket. Used for devices that speak line-oriented ASCII over plain TCP rather than full VISA — in ARES that is the ETS-Lindgren EMCenter linear slider (192.168.0.100:1206, "TCPIP::...::1206::SOCKET" in the instrument CSV). Sharing the transport interface with the VISA instruments gives the EmCenterSlider driver:

- simulation support (back it with a SimTransport instead)
- the same close and cleanup semantics, with no leaked sockets
- uniform error behavior with every other instrument

**Usage**

```matlab
t = TcpTransport("192.168.0.100", 1206);
t.open();
pos = t.writeRead("AXIS1:CP?");
t.close();
Or directly from a VISA-style socket resource string:
t = TcpTransport.fromResource("TCPIP::192.168.0.100::1206::SOCKET");
```

---

## VNAInstCtrl.m
`Path: src\support\InstrumentControl\VNAInstCtrl.m`

**Description:**

VNAInstCtrl Driver for the vector network analyzers used in ARES antenna measurements (Keysight N5232B PNA-L, Agilent E5072A ENA). It owns all VNA SCPI used by the antenna measurement path, including the binary-block trace transfers that carry the S-parameter data.

**Dialect**

- The registered defaults use the Keysight PNA/ENA syntax that ARES runs on hardware. A different VNA model can re-dialect any of them by dropping CommandSets/<Model>.json next to the framework, with no edits to this class.

**Trace layout**

- The default layout expected on the instrument: trace 1: S11 mag   trace 2: S11 phase trace 3: S21 mag   trace 4: S21 phase trace 5: S22 mag   trace 6: S22 phase

**Usage**

```matlab
vna = VNAInstCtrl("Keysight", "N5232B", "TCPIP0::...::inst0::INSTR");
vna.connect();
[sdB, sPhase, freqs] = vna.measureSParameters(smoothingPoints);
vna.setContinuous(true);   % restore live sweeping for the operator
vna.disconnect();
```

---

## VisaTransport.m
`Path: src\support\InstrumentControl\VisaTransport.m`

**Description:**

VisaTransport ITransport implementation backed by a MATLAB visadev object. Used for every VISA-addressable ARES instrument (VNA, signal generator, signal analyzers, PSUs, EMCenter positioner) over GPIB, LAN, or USB. This class owns the visadev handle exclusively. Driver classes never see it, which is what makes drivers transport-agnostic and simulatable.

**Notes**

- Releasing the handle requires dropping the last reference by assigning [], which close() does. Calling `clear obj.Device` instead is a silent no-op: it clears a variable of that name rather than the property, and the connection stays alive as a stale socket.

**Usage**

```matlab
t = VisaTransport("TCPIP0::192.168.1.161::inst0::INSTR");
t.open();
idn = t.writeRead("*IDN?");
t.close();
```

---

## aresConnectInstrument.m
`Path: src\support\InstrumentControl\aresConnectInstrument.m`

**Description:**

aresConnectInstrument Build, connect, and return the object-oriented driver for an ARES instrument, given the app's instrument property name and its VISA/socket resource string. It is the single call the app's connect callback needs: app.(instrumentName) = aresConnectInstrument(instrumentName, instrumentResource); Calls written against the raw handle API (writeline, writeread, readbinblock and flush on app.(name)) keep working, because the returned drivers expose those as methods. New code can use the high-level driver methods instead.

```{admonition} Input Parameters
:class: tip
- instrumentName - app property name: "VNA", "SignalGenerator", "InputSignalAnalyzer", "OutputSignalAnalyzer", "PowerSupplyA", "PowerSupplyB", "EMCenter", "EMSlider"
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

aresInstrument Adapter that returns an object-oriented driver for an ARES instrument, whether the app currently stores it as a RAW handle (visadev/tcpclient) or already as a framework driver object. A measurement function can write: vna = aresInstrument(app.VNA, "VNA"); [sdB, sPh, f] = vna.measureSParameters(smoothing); and it works either way: HandleTransport, leaving the app owning the connection, and returns a VNAInstCtrl. so the call is idempotent. Nothing double-opens or double-closes the underlying connection.

- If app.VNA is a raw visadev, this wraps it in a nonowning
- If app.VNA is already a VNAInstCtrl, this returns it unchanged,

```{admonition} Input Parameters
:class: tip
- handle - a raw visadev/tcpclient OR an existing framework driver
- role   - "VNA" | "PSU" | "Generator" | "Analyzer" | "Chamber" | "Slider" (case-insensitive)
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
- dataTable - the instrument table read from instrumentAddresses.csv (must have Description and Address columns; Type optional)
- type      - instrument type to keep: "VNA","PSU","Generator", "Analyzer","Chamber","Slider". Pass "" or "all" for every instrument (legacy, unfiltered behavior).
```

```{admonition} Output Parameters
:class: tip
- items - cellstr, e.g. {'NA: None'; 'Keysight Technologies N5232B: TCPIP0::...'}
```

**Usage**

In the app's loadInstrumentAddressestoApp:

```matlab
app.VNADropDown.Items = instrumentDropdownItems(dataTable, "VNA");
```

