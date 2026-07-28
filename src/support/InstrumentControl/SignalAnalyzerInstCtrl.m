classdef SignalAnalyzerInstCtrl < SCPIInstrument
    %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
    % SignalAnalyzerInstCtrl
    %
    % DESCRIPTION:
    % Driver for the signal/spectrum analyzers used in ARES power-amplifier
    % measurements (Keysight N9000B CXA). ARES uses one as the output
    % analyzer and, in "In-Situ Couplers" calibration mode, a second as the
    % input analyzer. Concrete controller that was missing from the
    % prototype framework.
    %
    % Absorbs the analyzer SCPI from support/PAFunctions/measureCW.m,
    % measureModulated.m, and runPAMeasurement.m: single-shot acquisition,
    % frequency-axis reconstruction from center/span/points, and
    % binary-block trace fetches.
    %
    % TYPICAL USAGE:
    %   sa = SignalAnalyzerInstCtrl("Keysight", "N9000B", addr);
    %   sa.connect();
    %   sa.setCenterFrequency(3.5e9);
    %   p = sa.measurePowerAt(3.5e9);     % dBm at the carrier
    %   sa.disconnect();
    %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

    methods
        function obj = SignalAnalyzerInstCtrl(man, model, address, varargin)
            % SIGNALANALYZERINSTCTRL  Construct a signal-analyzer controller.
            obj@SCPIInstrument(man, model, address, ...
                'InstType', "Analyzer", varargin{:});
            obj.registerAnalyzerCommands_();
            % Re-apply the per-model dialect so CommandSets/<model>.json
            % overrides the defaults just registered above (the base
            % constructor loaded it before those defaults existed). No-op for
            % the N9000B (its JSON equals these defaults); lets a different
            % analyzer re-dialect without editing this class.
            obj.tryLoadModelCommandSet_(model);
        end

        %% Acquisition control
        function initiateSingle(obj)
            % INITIATESINGLE  Switch to single-acquisition mode, trigger one
            % acquisition, and wait for it to complete. Reproduces the
            % legacy sequence: INIT:CONT 0, INIT:IMM, *WAI, then OPC poll.
            obj.scpi('init_cont', 0);
            obj.scpi('init_imm');
            obj.scpi('wai');
            obj.opcWait();
        end

        function setContinuous(obj, on)
            % SETCONTINUOUS  Restore (true) or stop (false) free-running
            % acquisition.
            if nargin < 2, on = true; end
            obj.scpi('init_cont', double(logical(on)));
        end

        %% Frequency configuration
        function setCenterFrequency(obj, freqHz)
            % SETCENTERFREQUENCY  Set the center frequency (Hz).
            obj.scpi('set_center_freq', freqHz);
        end

        function setSpan(obj, spanHz)
            % SETSPAN  Set the measurement span (Hz).
            obj.scpi('set_span', spanHz);
        end

        function fc = getCenterFrequency(obj)
            % GETCENTERFREQUENCY  Query the center frequency (Hz).
            fc = double(str2double(obj.scpi('center_freq?')));
        end

        function span = getSpan(obj)
            % GETSPAN  Query the measurement span (Hz).
            span = double(str2double(obj.scpi('span?')));
        end

        function n = getSweepPoints(obj)
            % GETSWEEPPOINTS  Query the number of sweep points.
            n = double(str2double(obj.scpi('sweep_points?')));
        end

        function freqs = getFrequencyAxis(obj)
            % GETFREQUENCYAXIS  Reconstruct the frequency axis (Hz, column
            % vector) from center/span/points — same arithmetic the legacy
            % measureCW.m used.
            fc   = obj.getCenterFrequency();
            span = obj.getSpan();
            n    = obj.getSweepPoints();
            freqs = linspace(fc - span/2, fc + span/2, n)';
        end

        %% Trace access
        function d = readTrace(obj)
            % READTRACE  Fetch TRACE1 as a double vector (binary block).
            d = obj.scpi('trace?');
        end

        function [power_dBm, freqs, trace] = measurePowerAt(obj, frequencyHz)
            % MEASUREPOWERAT  Single acquisition, then return the trace
            % power at the bin closest to frequencyHz.
            %
            % INPUT:
            %   frequencyHz - frequency of interest (Hz)
            %
            % OUTPUT:
            %   power_dBm - trace value at the nearest frequency bin
            %   freqs     - reconstructed frequency axis (Hz)
            %   trace     - full trace (dBm)
            %
            % NOTE: the legacy code selected the bin with an exact
            % floating-point == match, which silently returns empty when the
            % requested frequency is not exactly on the grid. This uses the
            % nearest bin instead and warns if it is more than one bin away.
            obj.initiateSingle();

            freqs = obj.getFrequencyAxis();
            trace = obj.readTrace();
            trace = trace(:);

            [df, idx] = min(abs(freqs - frequencyHz));
            binWidth = max(abs(diff(freqs)));
            if ~isempty(binWidth) && df > binWidth
                warning("SignalAnalyzerInstCtrl:OffGridFrequency", ...
                    "Requested %.6g Hz is %.6g Hz from the nearest trace bin.", ...
                    frequencyHz, df);
            end
            power_dBm = trace(idx);

            obj.scpi('cls');
        end

        %% Sweep, display, and trace setup
        function setSweepPoints(obj, n)
            % SETSWEEPPOINTS  Set the number of sweep points.
            obj.scpi('set_sweep_points', n);
        end

        function setReferenceLevel(obj, dBm, view)
            % SETREFERENCELEVEL  Set the Y-scale reference level (dBm).
            %
            %   view - "" (default, Swept SA window), "obw", or "acp" to
            %          target that measurement's own display window.
            if nargin < 3, view = ""; end
            switch lower(string(view))
                case "obw", obj.scpi('obw_ref_level', dBm);
                case "acp", obj.scpi('acp_ref_level', dBm);
                otherwise,  obj.scpi('set_ref_level', dBm);
            end
        end

        function setTraceFormat(obj, fmt, bits)
            % SETTRACEFORMAT  Set the trace transfer format, e.g. ("REAL", 64).
            if nargin < 2, fmt  = 'REAL'; end
            if nargin < 3, bits = 64;     end
            obj.scpi('trace_format', char(string(fmt)), bits);
        end

        function setByteOrder(obj, order)
            % SETBYTEORDER  Set binary byte order, e.g. "SWAPped".
            if nargin < 2, order = 'SWAPped'; end
            obj.scpi('byte_order', char(string(order)));
        end

        function configureAveraging(obj, on, count)
            % CONFIGUREAVERAGING  Enable/disable trace averaging and set the
            % averaging count.
            obj.scpi('average_state', double(logical(on)));
            if nargin >= 3 && ~isempty(count)
                obj.scpi('average_count', count);
            end
        end

        function setTraceMode(obj, traceNum, mode)
            % SETTRACEMODE  Set a trace's mode, e.g. (2, "MAXHold").
            obj.scpi('trace_mode', traceNum, char(string(mode)));
        end

        function d = readTraceNamed(obj, traceName)
            % READTRACENAMED  Fetch a named trace as a double vector.
            %
            %   d = sa.readTraceNamed("TRACe2")
            d = obj.scpi('trace_named?', char(string(traceName)));
        end

        %% Measurement selection and result reads
        function selectSweptSA(obj)
            % SELECTSWEPTSA  Select the Swept SA measurement.
            obj.scpi('init_sanalyzer');
        end

        function selectOBW(obj)
            % SELECTOBW  Select the Occupied Bandwidth measurement.
            obj.scpi('init_obw');
        end

        function d = readOBW(obj)
            % READOBW  Read the Occupied Bandwidth result block. Element 1 is
            % the occupied bandwidth in Hz.
            d = obj.scpi('read_obw?');
        end

        function selectACP(obj)
            % SELECTACP  Select the Adjacent Channel Power measurement.
            obj.scpi('init_acp');
        end

        function d = readACP(obj)
            % READACP  Read the ACP result block. Element 1 is channel power
            % (dBm); elements 2-3 are lower/upper adjacent power (dBc).
            d = obj.scpi('read_acp?');
        end

        function configureACP(obj, channelBWHz, spanHz, refLeveldBm, offsetHz)
            % CONFIGUREACP  Set up the ACP measurement in the order ARES uses:
            % carrier bandwidth, span, reference level, adjacent-channel
            % bandwidth, then adjacent-channel offset.
            obj.scpi('mcp_carrier_bw', channelBWHz);
            obj.scpi('acp_span',       spanHz);
            obj.scpi('acp_ref_level',  refLeveldBm);
            obj.scpi('acp_offset_bw',  channelBWHz);
            obj.scpi('acp_offset',     offsetHz);
        end

        %% Modulated-measurement configuration (from measureModulated.m)
        function setACPSpan(obj, spanHz)
            % SETACPSPAN  Set the adjacent-channel-power measurement span (Hz).
            obj.scpi('acp_span', spanHz);
        end

        function setACPOffset(obj, offsetHz)
            % SETACPOFFSET  Set the adjacent-channel outer offset (Hz).
            obj.scpi('acp_offset', offsetHz);
        end

        function setOBWSpan(obj, spanHz)
            % SETOBWSPAN  Set the occupied-bandwidth measurement span (Hz).
            obj.scpi('obw_span', spanHz);
        end
    end

    methods (Access = private)
        function registerAnalyzerCommands_(obj)
            % Keysight X-series (N9000B CXA) dialect as used by ARES today.
            % Note the legacy asymmetry preserved here: queries use the
            % short :FREQ:RF:CENT? form, sets use :SENSe:FREQuency:CENTer.
            obj.registerCommand('init_cont',       ':INITiate:CONTinuous %d', 'write');
            obj.registerCommand('init_imm',        ':INITiate:IMMediate',     'write');
            obj.registerCommand('center_freq?',    ':FREQ:RF:CENT?',          'query');
            obj.registerCommand('span?',           ':FREQ:SPAN?',             'query');
            obj.registerCommand('sweep_points?',   ':SWE:POIN?',              'query');
            obj.registerCommand('set_center_freq', ':SENSe:FREQuency:CENTer %g', 'write');
            obj.registerCommand('set_span',        ':SENSe:FREQuency:SPAN %g',   'write');
            obj.registerCommand('trace?',          ':TRACe:DATA? TRACe1',     'query', 'binblock:double');
            obj.registerCommand('acp_span',        ':SENSe:ACPower:FREQuency:SPAN %d', 'write');
            obj.registerCommand('acp_offset',      ':SENSe:ACPower:OFFSet:OUTer:LIST:FREQuency %d', 'write');
            obj.registerCommand('obw_span',        ':SENSe:OBWidth:FREQuency:SPAN %g', 'write');

            % Sweep / display / trace setup (absorbed from runPAMeasurement.m).
            obj.registerCommand('set_sweep_points', ':SENSe:SWEep:POINts %d',   'write');
            obj.registerCommand('trace_format',     ':FORMat:TRACe:DATA %s,%d', 'write');
            obj.registerCommand('byte_order',       ':FORMat:BORDer %s',        'write');
            obj.registerCommand('average_state',    ':SENSe:AVERage:STATe %d',  'write');
            obj.registerCommand('average_count',    ':SENSe:AVERage:COUNt %d',  'write');
            obj.registerCommand('trace_mode',       ':TRACe%d:MODE %s',         'write');
            obj.registerCommand('trace_named?',     ':TRACe:DATA? %s', 'query', 'binblock:double');

            % Reference level. The legacy code sent this with %d in
            % measureModulated.m and %g in runPAMeasurement.m for the same
            % setting; %d renders a fractional dBm as "1.050000e+01". %g is
            % used throughout here — identical bytes for the integer reference
            % levels ARES normally uses, correct for the fractional ones.
            obj.registerCommand('set_ref_level',   ':DISPlay:WINDow:TRACe:Y:SCALe:RLEVel %g', 'write');
            obj.registerCommand('obw_ref_level',   ':DISPlay:OBWidth:VIEW:WINDow:TRACe:Y:SCALe:RLEVel %g', 'write');
            obj.registerCommand('acp_ref_level',   ':DISPlay:ACPower:VIEW:WINDow:TRACe:Y:SCALe:RLEVel %g', 'write');

            % Measurement selection + result reads (from measureModulated.m).
            obj.registerCommand('init_sanalyzer',  ':INITiate:SANalyzer', 'write');
            obj.registerCommand('init_obw',        ':INITiate:OBWidth',   'write');
            obj.registerCommand('read_obw?',       ':READ:OBWidth?', 'query', 'binblock:double');
            obj.registerCommand('init_acp',        ':INITiate:ACP',       'write');
            obj.registerCommand('read_acp?',       ':READ:ACP?',     'query', 'binblock:double');
            obj.registerCommand('acp_offset_bw',   ':SENSe:ACPower:OFFSet:OUTer:LIST:BANDwidth:INTegration %d', 'write');
            obj.registerCommand('mcp_carrier_bw',  ':SENSe:MCPower:CARRier:LIST:BANDwidth:INTegration %d',      'write');
        end
    end
end
