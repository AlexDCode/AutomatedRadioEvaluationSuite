classdef PSUInstCtrl < SCPIInstrument
    %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
    % PSUInstCtrl
    %
    % DESCRIPTION:
    % Driver for the DC power supplies used in ARES power-amplifier
    % measurements (Keysight E36233A, dual-channel).
    %
    % DIALECT CORRECTION vs. THE PROTOTYPE:
    % The prototype emitted "VOLT <V>,(@ch)" / "MEAS:VOLT? (@ch)". ARES's
    % E36233A path — validated on hardware — uses the :APPLy and
    % :MEAS:SCAL:* forms (see legacy setPSUChannels.m / measureCW.m /
    % enablePSUChannels.m). This class registers the hardware-validated
    % forms as its defaults; other supplies can re-dialect via
    % CommandSets/<Model>.json without touching this class.
    %
    % SAFETY (bias sequencing):
    % PA devices are sequenced gate-before-drain on enable and
    % drain-before-gate on disable (so the FET is never drained without its
    % gate bias). That ordering logic lives in the measurement layer
    % (enablePSUChannels), which knows the gate/drain role of each logical
    % channel; this driver deliberately exposes only per-supply primitives.
    %
    % TYPICAL USAGE:
    %   psu = PSUInstCtrl("Keysight", "E36233A", addr);
    %   psu.connect();
    %   psu.apply(1, 28.0, 2.0);          % CH1: 28 V, 2 A limit
    %   psu.setOutputState([1 2], true);  % both channels on
    %   v = psu.measureVoltage(1);
    %   i = psu.measureCurrent(1);
    %   psu.setOutputState([1 2], false);
    %   psu.disconnect();
    %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

    methods
        function obj = PSUInstCtrl(man, model, address, varargin)
            % PSUINSTCTRL  Construct a PSU controller (InstType forced "PSU").
            obj@SCPIInstrument(man, model, address, ...
                'InstType', "PSU", varargin{:});
            obj.registerPSUCommands_();
            % Re-apply the per-model dialect so CommandSets/<model>.json
            % overrides the defaults just registered above (the base
            % constructor loaded it before those defaults existed). For the
            % E36233A this is a no-op — its JSON equals these defaults — but it
            % lets a different supply re-dialect safely. SAFETY: a re-dialected
            % PSU changes bias commands, so validate any non-E36233A supply's
            % JSON on hardware before use.
            obj.tryLoadModelCommandSet_(model);
        end

        %% Configuration
        function apply(obj, ch, voltage, current)
            % APPLY  Set a channel's voltage and current limit in one
            % command — the form ARES uses on the E36233A:
            %   ":APPLy CH<n>,<V>,<I>"
            validateattributes(ch, {'numeric'}, {'scalar','integer','positive'});
            obj.scpi('apply', ch, voltage, current);
        end

        function setVoltage(obj, ch, V)
            % SETVOLTAGE  Set output voltage on a channel.
            validateattributes(ch, {'numeric'}, {'scalar','integer','positive'});
            obj.scpi('set_volt', V, ch);
        end

        function setCurrent(obj, ch, I)
            % SETCURRENT  Set current limit on a channel.
            validateattributes(ch, {'numeric'}, {'scalar','integer','positive'});
            obj.scpi('set_curr', I, ch);
        end

        %% Output state
        function setOutputState(obj, channels, state)
            % SETOUTPUTSTATE  Enable/disable one or more channels.
            %
            % INPUT:
            %   channels - scalar or vector of channel indices, e.g. 1 or [1 2]
            %   state    - logical / 0/1 / "on"-style string
            %
            % Emits the legacy form ":OUTPut:STATe <0/1>,(@1)" or "(@1,2)".
            validateattributes(channels, {'numeric'}, {'vector','integer','positive'});
            on = PSUInstCtrl.normalizeState_(state);
            chanList = strjoin(string(channels), ",");
            obj.scpi('output_state', on, char(chanList));
        end

        function tf = getOutputState(obj, ch)
            % GETOUTPUTSTATE  Query whether a channel's output is on.
            validateattributes(ch, {'numeric'}, {'scalar','integer','positive'});
            s = upper(strtrim(obj.scpi('output_state?', ch)));
            tf = (s == "1" || s == "ON");
        end

        %% Measurement
        function v = measureVoltage(obj, ch)
            % MEASUREVOLTAGE  Measured (readback) DC voltage on a channel (V).
            validateattributes(ch, {'numeric'}, {'scalar','integer','positive'});
            v = str2double(obj.scpi('meas_volt?', ch));
        end

        function i = measureCurrent(obj, ch)
            % MEASURECURRENT  Measured (readback) DC current on a channel (A).
            validateattributes(ch, {'numeric'}, {'scalar','integer','positive'});
            i = str2double(obj.scpi('meas_curr?', ch));
        end

        function info = getChannel(obj, ch)
            % GETCHANNEL  Read back voltage, current, power, and output
            % state for a channel.
            %
            % OUTPUT (struct):
            %   .Channel  - channel index
            %   .Voltage  - measured volts
            %   .Current  - measured amps
            %   .Power    - V*I watts (the quantity measureCW.m computes)
            %   .OutputOn - logical
            v  = obj.measureVoltage(ch);
            i  = obj.measureCurrent(ch);
            on = obj.getOutputState(ch);
            info = struct('Channel', ch, 'Voltage', v, 'Current', i, ...
                          'Power', v * i, 'OutputOn', on);
        end

        %% Safety
        function safeShutdown(obj)
            % SAFESHUTDOWN  Turn off all outputs and zero both channels.
            % Per-supply safe state; gate/drain ORDERING across supplies is
            % the measurement layer's responsibility.
            obj.setOutputState([1 2], false);
            obj.apply(1, 0, 0);
            obj.apply(2, 0, 0);
        end
    end

    methods (Access = private)
        function registerPSUCommands_(obj)
            % Keysight E36233A dialect — the hardware-validated ARES forms.
            obj.registerCommand('apply',         ':APPLy CH%d,%g,%g',                   'write');
            obj.registerCommand('set_volt',      ':SOURce:VOLTage %g,(@%d)',            'write');
            obj.registerCommand('set_curr',      ':SOURce:CURRent %g,(@%d)',            'write');
            obj.registerCommand('output_state',  ':OUTPut:STATe %d,(@%s)',              'write');
            obj.registerCommand('output_state?', ':OUTPut:STATe? (@%d)',                'query');
            obj.registerCommand('meas_volt?',    ':MEASure:SCALar:VOLTage:DC? CH%d',    'query');
            obj.registerCommand('meas_curr?',    ':MEASure:SCALar:CURRent:DC? CH%d',    'query');
        end
    end

    methods (Static, Access = private)
        function v = normalizeState_(state)
            if islogical(state) || isnumeric(state)
                v = double(state ~= 0);
            else
                s = lower(string(state));
                v = double(any(s == ["on","1","true","enable","enabled"]));
            end
        end
    end
end
