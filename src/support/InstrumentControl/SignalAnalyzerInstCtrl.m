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
        end
    end
end
