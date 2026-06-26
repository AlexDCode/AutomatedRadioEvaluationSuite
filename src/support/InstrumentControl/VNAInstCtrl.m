classdef VNAInstCtrl < SCPIInstrument
    %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
    % VNAInstCtrl
    %
    % DESCRIPTION:
    % Driver for the vector network analyzers used in ARES antenna
    % measurements (Keysight N5232B PNA-L, Agilent E5072A ENA). This is the
    % concrete VNA controller that was missing from the prototype framework
    % (only the TemplateInstCtrl placeholder existed).
    %
    % It absorbs all VNA SCPI from the legacy
    % support/AntennaFunctions/measureSParameters.m, including the
    % binary-block trace transfers that the prototype base class could not
    % perform.
    %
    % DIALECT:
    % Default registered commands use the Keysight PNA/ENA syntax that ARES
    % currently runs on hardware. A different VNA model can re-dialect any
    % of them by dropping CommandSets/<Model>.json next to the framework —
    % no edits to this class (see SCPIInstrument header, feature 3).
    %
    % ASSUMED TRACE LAYOUT (matches the legacy ARES VNA state file):
    %   trace 1: S11 mag   trace 2: S11 phase
    %   trace 3: S21 mag   trace 4: S21 phase
    %   trace 5: S22 mag   trace 6: S22 phase
    %
    % TYPICAL USAGE:
    %   vna = VNAInstCtrl("Keysight", "N5232B", "TCPIP0::...::inst0::INSTR");
    %   vna.connect();
    %   [sdB, sPhase, freqs] = vna.measureSParameters(smoothingPoints);
    %   vna.setContinuous(true);   % restore live sweeping for the operator
    %   vna.disconnect();
    %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

    properties
        % Max time to wait for a single sweep to finish (s). A sweep can take
        % much longer than the default I/O timeout (many points / narrow IF
        % bandwidth / averaging), so it is waited on by polling *OPC? rather
        % than by a single blocking read.
        SweepTimeoutSec (1,1) double = 60
    end

    methods
        function obj = VNAInstCtrl(man, model, address, varargin)
            % VNAINSTCTRL  Construct a VNA controller.
            % Arguments are forwarded to SCPIInstrument; InstType is forced
            % to "VNA". The I/O timeout defaults to 30 s (VNAs are slow to
            % respond mid-sweep); override by passing 'TimeoutSec',N.
            if ~any(strcmpi('TimeoutSec', varargin))
                varargin = [varargin, {'TimeoutSec', 30}];
            end
            obj@SCPIInstrument(man, model, address, ...
                'InstType', "VNA", varargin{:});
            obj.registerVNACommands_();
            % Re-apply the per-model dialect so CommandSets/<model>.json
            % overrides the Keysight defaults just registered above (the base
            % constructor loaded it BEFORE those defaults existed, so they
            % clobbered it). Without this a non-Keysight VNA — e.g. the Copper
            % Mountain CMT808U — silently runs Keysight SCPI and times out on
            % the first binary-block trace read.
            obj.tryLoadModelCommandSet_(model);
        end

        %% Sweep control
        function triggerSingleSweep(obj)
            % TRIGGERSINGLESWEEP  Start one sweep and wait for it to finish.
            %
            % Waits by polling *OPC? (up to SweepTimeoutSec) instead of the
            % legacy bare *WAI followed by a blocking data read. This turns a
            % slow sweep into a clear, bounded "sweep timeout" error rather
            % than an opaque I/O timeout buried inside a binary-block read.
            obj.scpi('sweep_single');
            if ~obj.opcWait(obj.SweepTimeoutSec)
                error("VNAInstCtrl:SweepTimeout", ...
                    "Single sweep did not complete within %g s. Increase SweepTimeoutSec, or check sweep points / IF bandwidth / averaging.", ...
                    obj.SweepTimeoutSec);
            end
        end

        function setContinuous(obj, on)
            % SETCONTINUOUS  Restore (true) or stop (false) free-running
            % sweeps. ARES restores continuous mode after a measurement so
            % the operator sees a live display.
            if nargin < 2, on = true; end
            if on
                obj.scpi('sweep_continuous');
            else
                obj.scpi('sweep_hold');
            end
        end

        %% Trace access
        function selectTrace(obj, n)
            % SELECTTRACE  Make measurement trace n the active trace.
            obj.scpi('select_trace', n);
        end

        function d = readFormattedTrace(obj)
            % READFORMATTEDTRACE  Read the active trace's formatted
            % (display-format, e.g. dB or degrees) data as a double vector.
            d = obj.scpi('trace_fdata');
        end

        function c = readComplexTrace(obj)
            % READCOMPLEXTRACE  Read the active trace's underlying complex
            % S-parameter data. The instrument interleaves re/im; this
            % returns a complex vector.
            d = obj.scpi('trace_sdata');
            if mod(numel(d), 2) ~= 0
                error("VNAInstCtrl:BadComplexTrace", ...
                    "Complex trace has odd length %d; expected interleaved re/im pairs.", ...
                    numel(d));
            end
            c = d(1:2:end) + 1i * d(2:2:end);
        end

        function f = getFrequencyAxis(obj)
            % GETFREQUENCYAXIS  Read the sweep frequency values (Hz).
            f = obj.scpi('freq_axis');
        end

        %% Data transfer format
        function configureBinaryTransfer(obj)
            % CONFIGUREBINARYTRANSFER  Set 64-bit binary data transfer with
            % a byte order matching the I/O layer.
            %
            % FORM:DATA REAL,64 -> trace data as 64-bit IEEE floats, read by
            %   readbinblock(...,'double').
            % FORM:BORD SWAP    -> little-endian, matching the visadev
            %   ByteOrder set by VisaTransport. Without the matching byte
            %   order the values come back byte-swapped (wrong numbers, not a
            %   timeout). Override either in CommandSets/<Model>.json.
            obj.scpi('set_format');
            obj.scpi('set_byte_order');
        end

        %% High-level measurement (ports legacy measureSParameters.m)
        function [sParamdB, sParamPhase, freqValues] = measureSParameters(obj, smoothingPoints)
            % MEASURESPARAMETERS  Measure S11/S21/S22 magnitude and phase.
            %
            % INPUT:
            %   smoothingPoints - smoothing applied on the instrument.
            %                     > 1  : read the smoothed, formatted traces
            %                     == 1 : read raw complex data and compute
            %                            magnitude/phase locally
            %
            % OUTPUT:
            %   sParamdB    - 1x3 cell {S11, S21, S22} magnitude (dB)
            %   sParamPhase - 1x3 cell {S11, S21, S22} phase (deg)
            %   freqValues  - sweep frequencies (Hz)
            %
            % Behavior is a 1:1 port of the legacy function so migrated and
            % legacy paths produce identical data during the staged rollout.
            if nargin < 2, smoothingPoints = 1; end

            obj.flush();
            obj.scpi('cls');

            % Put the VNA into 64-bit binary transfer before any binblock
            % read. Without this the instrument may be in ASCII mode, in
            % which case readbinblock waits forever for a binary header
            % (the observed test2 "timeout").
            obj.configureBinaryTransfer();

            numMeasurements = 3;   % S11, S21, S22
            sParamdB    = cell(1, numMeasurements);
            sParamPhase = cell(1, numMeasurements);

            obj.triggerSingleSweep();

            traceIndex = 1;
            for i = 1:numMeasurements
                if smoothingPoints ~= 1
                    % Smoothed path: formatted data is already mag/phase.
                    obj.selectTrace(traceIndex);
                    sParamdB{i} = obj.readFormattedTrace();

                    traceIndex = traceIndex + 1;
                    obj.selectTrace(traceIndex);
                    sParamPhase{i} = obj.readFormattedTrace();
                else
                    % Raw path: complex data, compute mag/phase locally.
                    obj.selectTrace(traceIndex);
                    c = obj.readComplexTrace();
                    sParamdB{i} = 20 * log10(abs(c));

                    traceIndex = traceIndex + 1;
                    obj.selectTrace(traceIndex);
                    c = obj.readComplexTrace();
                    sParamPhase{i} = rad2deg(angle(c));
                end
                traceIndex = traceIndex + 1;
            end

            freqValues = obj.getFrequencyAxis();
        end

        %% General multi-trace read (any port count, any setup)
        function [freqHz, traceData, paramNames] = measureAllTraces(obj)
            % MEASUREALLTRACES  Read EVERY measurement trace currently set up
            % on the VNA, whatever they are (S11, S22, S33, S44, S21, ...).
            %
            % Unlike measureSParameters (which assumes a fixed 2-port,
            % 6-trace S11/S21/S22 mag+phase layout), this makes no assumption
            % about how many traces exist or what they are — so it works for a
            % 4-port antenna setup where you have configured, say, S11/S22/
            % S33/S44 return loss plus isolation terms on the instrument.
            %
            % Whatever display FORMAT each trace is in on the VNA (dB log mag,
            % VSWR, phase, ...) is what you get back in that column.
            %
            % OUTPUT:
            %   freqHz     - sweep frequencies (Hz), column vector [npts x 1]
            %   traceData  - [npts x nTraces] formatted data, one column/trace
            %   paramNames - 1 x nTraces string array of S-parameter labels
            %
            % WORKFLOW: set up the traces you want ON THE VNA (front panel or
            % SCPI) and CALIBRATE first, then call this to capture them.
            obj.flush();
            obj.scpi('cls');
            obj.configureBinaryTransfer();      % REAL,64 binary transfer
            obj.triggerSingleSweep();           % one sweep + *OPC? wait

            nTraces = round(str2double(obj.scpi('trace_count?')));
            if ~isfinite(nTraces) || nTraces < 1
                error("VNAInstCtrl:NoTraces", ...
                    "No measurement traces are configured on the VNA.");
            end

            freqHz    = obj.getFrequencyAxis();
            freqHz    = freqHz(:);
            npts      = numel(freqHz);
            traceData = zeros(npts, nTraces);

            for i = 1:nTraces
                obj.selectTrace(i);
                d = obj.readFormattedTrace();
                traceData(:, i) = d(:);
            end

            paramNames = obj.parseCatalogNames_(nTraces);
        end
    end

    methods (Access = private)
        function registerVNACommands_(obj)
            % Keysight PNA/ENA dialect used by the ARES N5232B and E5072A.
            % Any entry can be overridden per-model via CommandSets JSON.
            obj.registerCommand('sweep_single',     'SENS1:SWE:MODE SING', 'write');
            obj.registerCommand('sweep_continuous', 'SENS1:SWE:MODE CONT', 'write');
            obj.registerCommand('sweep_hold',       'SENS1:SWE:MODE HOLD', 'write');
            obj.registerCommand('set_format',       'FORM:DATA REAL,64',   'write');
            obj.registerCommand('set_byte_order',   'FORM:BORD SWAP',      'write');
            obj.registerCommand('format?',          'FORM:DATA?',          'query');
            obj.registerCommand('select_trace',     'CALC1:PAR:MNUM %d',   'write');
            obj.registerCommand('trace_fdata',      'CALC1:DATA? FDATA',   'query', 'binblock:double');
            obj.registerCommand('trace_sdata',      'CALC1:DATA? SDATA',   'query', 'binblock:double');
            obj.registerCommand('freq_axis',        ':SENSe:X:VALues?',    'query', 'binblock:double');
            % Multi-trace / 4-port support.
            obj.registerCommand('trace_count?',     'CALC1:PAR:COUN?',     'query');
            obj.registerCommand('trace_catalog?',   'CALC1:PAR:CAT:EXT?',  'query');
        end

        function names = parseCatalogNames_(obj, n)
            % Parse the S-parameter names from CALC1:PAR:CAT:EXT?, which
            % returns "name1,Sxy,name2,Sxy,...". Returns an n-element string
            % array of the Sxy labels; falls back to "Trace k" on any miss.
            names = "Trace " + string(1:n);
            try
                raw = strtrim(obj.scpi('trace_catalog?'));
                raw = erase(raw, '"');
                parts = strtrim(split(raw, ","));
                params = parts(2:2:end);          % every 2nd token is the Sxy
                for k = 1:min(n, numel(params))
                    if strlength(params(k)) > 0
                        names(k) = params(k);
                    end
                end
            catch
                % keep the generic fallback names
            end
        end
    end
end
