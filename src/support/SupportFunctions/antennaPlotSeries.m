function series = antennaPlotSeries(data)
    %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
    % DESCRIPTION:
    % Lists every gain pattern in loaded antenna results that the 2D/3D radiation plots can show, so the user
    % picks one (or overlays them) from the Plot tab's Gain dropdown:
    %
    %   - Legacy 2-port (wide) files: each column with "gain" in its name that holds data, e.g. "Gain (dBi)" and
    %     "Absolute Gain (dBi)".
    %   - n-port (long) files: the gain of each AUT <-> reference path, e.g. "S31 Gain (dBi)" and
    %     "S32 Gain (dBi)" when two reference horns were used.
    %
    % With no gain data at all (no reference gain file), the insertion loss is offered instead as a RELATIVE
    % pattern (its label says so), since its shape is still the antenna's pattern.
    %
    % INPUT:
    %   data   - app.Antenna_Data (legacy wide table or n-port long table).
    %
    % OUTPUT:
    %   series - struct array, one per pattern, with fields:
    %            Label    - dropdown / legend text
    %            YLabel   - axis label (unit included)
    %            Relative - true when it is insertion loss rather than gain
    %            Data     - table with Thetadeg, Phideg, FrequencyMHz, Value, ReturnLossdB
    %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

    series = struct('Label', {}, 'YLabel', {}, 'Relative', {}, 'Data', {});
    if isempty(data) || ~istable(data), return; end
    vn = string(data.Properties.VariableNames);

    if any(strcmpi(vn, "Quantity"))
        series = nportSeries_(data, vn);
    else
        series = legacySeries_(data, vn);
    end
end

function series = legacySeries_(T, vn)
    series = struct('Label', {}, 'YLabel', {}, 'Relative', {}, 'Data', {});
    rl = nan(height(T), 1);
    if any(vn == "ReturnLossdB"), rl = T.ReturnLossdB; end

    % Every numeric column with "gain" in its name that holds data.
    for name = vn(contains(vn, "gain", 'IgnoreCase', true))
        v = T.(name);
        if ~isnumeric(v) || ~any(isfinite(real(v))), continue; end
        label = prettyName_(name);
        series(end + 1) = entry_(label, label, false, T, real(v), rl); %#ok<AGROW>
    end

    % No gain data (no reference file): show the insertion loss as a relative pattern.
    if isempty(series) && any(vn == "InsertionLossdB")
        series = entry_("Insertion Loss (dB), relative", "Relative Pattern (dB)", true, ...
            T, T.InsertionLossdB, rl);
    end
end

function series = nportSeries_(T, vn)
    series = struct('Label', {}, 'YLabel', {}, 'Relative', {}, 'Data', {});
    q  = string(T.(col_(vn, "Quantity")));
    sp = string(T.(col_(vn, ["SParameter", "S-Parameter", "S_Parameter_"])));

    relative = ~any(q == "Gain (dBi)");
    qty = "Gain (dBi)";
    if relative, qty = "Insertion Loss (dB)"; end

    for s = unique(sp(q == qty), 'stable')'
        W = nportToWideAntenna(T, s);
        if isempty(W), continue; end
        if relative
            series(end + 1) = entry_(s + " Insertion Loss (dB), relative", "Relative Pattern (dB)", true, ...
                W, W.GaindBi, W.ReturnLossdB); %#ok<AGROW>
        else
            series(end + 1) = entry_(s + " Gain (dBi)", "Gain (dBi)", false, ...
                W, W.GaindBi, W.ReturnLossdB); %#ok<AGROW>
        end
    end
end

function e = entry_(label, ylab, relative, T, value, rl)
    e.Label    = string(label);
    e.YLabel   = string(ylab);
    e.Relative = relative;
    e.Data     = table(T.Thetadeg, T.Phideg, T.FrequencyMHz, value(:), rl(:), ...
        'VariableNames', {'Thetadeg', 'Phideg', 'FrequencyMHz', 'Value', 'ReturnLossdB'});
end

function s = prettyName_(name)
    % Compact column name back to readable form: "AbsoluteGaindBi" -> "Absolute Gain (dBi)".
    name = char(name);
    unit = regexp(name, '(dBi|dB)$', 'match', 'once');
    base = regexprep(name(1:end - numel(unit)), '([a-z])([A-Z])', '$1 $2');
    s = string(strtrim(base));
    if ~isempty(unit), s = s + " (" + unit + ")"; end
end

function name = col_(vn, aliases)
    name = '';
    for a = aliases
        hit = find(strcmpi(vn, a), 1);
        if ~isempty(hit), name = char(vn(hit)); return; end
    end
end
