function items = instrumentDropdownItems(dataTable, type)
    %INSTRUMENTDROPDOWNITEMS  Dropdown entries for one instrument type.
    %
    % Returns a cellstr suitable for a dropdown's Items property, containing
    % only the instruments whose Type column matches `type` — so the VNA
    % dropdown lists only VNAs, the PSU dropdown only PSUs, etc. This prevents
    % connecting the wrong kind of instrument to a slot (e.g. an EMCenter
    % where a VNA belongs).
    %
    % Each entry is "Description: Address", sorted, with 'NA: None' first
    % (matching the app's existing dropdown format).
    %
    % INPUT:
    %   dataTable - the instrument table read from instrumentAddresses.csv
    %               (must have Description and Address columns; Type optional)
    %   type      - instrument type to keep: "VNA","PSU","Generator",
    %               "Analyzer","Chamber","Slider". Pass "" or "all" for every
    %               instrument (legacy, unfiltered behavior).
    %
    % OUTPUT:
    %   items - cellstr, e.g. {'NA: None'; 'Keysight Technologies N5232B: TCPIP0::...'}
    %
    % USAGE (in the app's loadInstrumentAddressestoApp):
    %   app.VNADropDown.Items = instrumentDropdownItems(dataTable, "VNA");

    if nargin < 2, type = ""; end

    % Always drop blank/placeholder rows (the CSV has trailing empty rows).
    keep = strlength(strtrim(string(dataTable.Description))) > 0;

    % Filter by Type unless asked for everything or there is no Type column.
    wantAll = strlength(strtrim(string(type))) == 0 || lower(string(type)) == "all";
    hasType = ismember("Type", string(dataTable.Properties.VariableNames));
    if ~wantAll && hasType
        keep = keep & strcmpi(strtrim(string(dataTable.Type)), strtrim(string(type)));
    end

    rows = dataTable(keep, :);
    entries = sort(strcat(string(rows.Description), ": ", string(rows.Address)));
    items = [{'NA: None'}; cellstr(entries)];
end
