# Instrument Database Tutorial

ARES maintains a user-defined instrument database stored as a `.csv` file within the ARES directory in your MATLAB user path. This database enables persistent tracking of instrument configurations across app sessions.

If the database does not exist, ARES automatically creates one by copying a default template from the source directory.

-------------------

## Database Format

The instrument database is a simple `.csv` file with the following structure:

|**Manufacturer**      |**Model** |**Address**                         |
|----------------------|----------|------------------------------------|
|Agilent Technologies  |E5072A    |TCPIP0::192.168.3.95::inst0::INSTR  |
|ETS Lindgren          |EMCenter  |TCPIP0::192.168.2.150::inst0::INSTR |
|Hewlett-Packard       |E4433B    |GPIB0::19::INSTR                    |
|Keysight Technologies |E36233A   |TCPIP0::192.168.2.16::5025::SOCKET  |

- **Manufacturer**: The name of the equipment vendor.

- **Model**: The specific model number.

- **Address**: The VISA resource string used to connect (supports LAN, GPIB, or socket-based communication).

## Managing Instruments
To manage instruments in the app:

1. Click **New Instrument** to add a new entry.
2. Fill in the required fields: **Manufacturer**, **Model**, and **Address**.
3. Added instruments will appear in the **Instruments** tab of each measurement module.
4. To remove an instrument, select its row and click **Delete Instrument**.
5. After making changes, click **Save Changes** to update your local database.

```{image} ./assets/Settings/instrument_database.png
:alt: Instrument Database
:class: bg-primary
:width: 100%
:align: center
```

For more technical details, explore the [Instrument Interfacing Section](https://aresapp.readthedocs.io/latest/instr_interface.html) which explains how ARES uses VISA protocols to communicate with connected instruments.

## Manual Editing (Optional)
Although the app provides a user-friendly interface for managing instruments, users can also edit the instrument database file directly using a text editor or spreadsheet software (e.g., Excel, VS Code, etc.).

### File Location
The database file is located in your **MATLAB user path**, under the ARES directory:

```none
<userpath>/ARES/instrument_database.csv
```

To check your user path, run the following command in the MATLAB command window:

```none
userpath
```

### Editing Guidelines
- Open the `.csv` file with a CSV-compatible editor to avoid corrupting the format.
- Do not modify the header row (`Manufacturer`, `Model`, `Address`).
- Each row must contain exactly three fields:
`Manufacturer`, `Model`, and a valid VISA `Address`.
