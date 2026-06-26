classdef SignalGeneratorInstCtrl < SCPIInstrument
    %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
    % SignalGeneratorInstCtrl
    %
    % DESCRIPTION:
    % Driver for the RF signal generators used in ARES power-amplifier
    % measurements (Rohde & Schwarz SMW200A; HP/Agilent E4433B for legacy
    % GPIB setups). Concrete controller that was missing from the prototype
    % framework.
    %
    % Absorbs the generator SCPI currently embedded in
    % support/PAFunctions/measureCW.m, measureModulated.m, and
    % runPAMeasurement.m: CW power/frequency, RF output enable, and the
    % digital-modulation (ARB) bring-up sequence.
    %
    % SAFETY:
    % safeShutdown() reproduces the ARES safe-state idiom (power to -135 dBm
    % AND RF output off) used before/after every PA sweep and in every error
    % path. Keeping it as one named method means no error handler can forget
    % half of the sequence.
    %
    % TYPICAL USAGE:
    %   sg = SignalGeneratorInstCtrl("Rohde & Schwarz", "SMW200A", addr);
    %   sg.connect();
    %   sg.setFrequencyCW(3.5e9);
    %   sg.setPower(-10);
    %   sg.setOutputState(true);
    %   ... sweep ...
    %   sg.safeShutdown();
    %   sg.disconnect();
    %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

    properties (Constant)
        % Power level ARES uses as "effectively off" (dBm).
        SafePowerdBm = -135
    end

    methods
        function obj = SignalGeneratorInstCtrl(man, model, address, varargin)
            % SIGNALGENERATORINSTCTRL  Construct a signal-generator controller.
            obj@SCPIInstrument(man, model, address, ...
                'InstType', "Generator", varargin{:});
            obj.registerGeneratorCommands_();
            % Re-apply the per-model dialect so CommandSets/<model>.json
            % overrides the defaults just registered above (the base
            % constructor loaded it before those defaults existed). No-op for
            % the SMW200A / E4433B (their JSONs equal these defaults); lets a
            % different generator re-dialect. SAFETY: a re-dialected generator
            % changes RF/power commands — validate its JSON on hardware first.
            obj.tryLoadModelCommandSet_(model);
        end

        %% CW control
        function setPower(obj, dBm)
            % SETPOWER  Set CW output power (dBm).
            obj.scpi('set_power', dBm);
        end

        function setFrequencyCW(obj, freqHz)
            % SETFREQUENCYCW  Set the CW carrier frequency (Hz).
            obj.scpi('set_freq_cw', freqHz);
        end

        function setOutputState(obj, on)
            % SETOUTPUTSTATE  Enable/disable the RF output.
            %
            %   on - logical, numeric 0/1, or "on"/"off" string
            obj.scpi('output_state', SignalGeneratorInstCtrl.normalizeState_(on));
        end

        %% Digital modulation (ARB) — sequence from runPAMeasurement.m
        function configureDigitalModulation(obj, modulationType, symbolRateMSPS)
            % CONFIGUREDIGITALMODULATION  Set up ARB digital modulation.
            %
            % INPUT:
            %   modulationType - modulation type string the instrument
            %                    accepts (e.g. "QAM16"), from the ARES
            %                    ModulationType dropdown
            %   symbolRateMSPS - symbol rate in MSPS
            %
            % Mirrors the legacy bring-up order exactly: modulation output
            % off, type, symbol rate, ARB on, then modulation output on.
            obj.scpi('mod_state', 0);
            obj.scpi('arb_mod_type', char(string(modulationType)));
            obj.scpi('arb_srate', symbolRateMSPS);
            obj.scpi('arb_state', 1);
            obj.opcWait();
            obj.scpi('mod_state', 1);
        end

        function setModulationState(obj, on)
            % SETMODULATIONSTATE  Enable/disable modulated output.
            obj.scpi('mod_state', SignalGeneratorInstCtrl.normalizeState_(on));
        end

        %% Safety
        function safeShutdown(obj)
            % SAFESHUTDOWN  Drive the generator to the ARES safe state:
            % minimum power AND RF output off. Call from every error path.
            obj.setPower(obj.SafePowerdBm);
            obj.setOutputState(false);
        end
    end

    methods (Access = private)
        function registerGeneratorCommands_(obj)
            % Dialect as used by ARES on the SMW200A / E4433B today.
            % Override per-model via CommandSets/<Model>.json if needed.
            obj.registerCommand('set_power',    ':SOURce1:POWer:LEVel:IMMediate:AMPLitude %g', 'write');
            obj.registerCommand('set_freq_cw',  ':SOURce1:FREQuency:CW %d',                    'write');
            obj.registerCommand('output_state', ':OUTPut1:STATe %d',                           'write');
            obj.registerCommand('mod_state',    ':OUTPut:MODulation:STATe %d',                 'write');
            obj.registerCommand('arb_mod_type', ':SOURce1:RADio:DMODulation:ARB:MODulation:TYPE %s', 'write');
            obj.registerCommand('arb_srate',    ':SOURce:RADio:DMODulation:ARB:SRATe %d MSPS', 'write');
            obj.registerCommand('arb_state',    ':SOURce1:RADio:DMODulation:ARB:STATe %d',     'write');
        end
    end

    methods (Static, Access = private)
        function v = normalizeState_(state)
            % Accept logical / numeric / "on"-style strings, return 0 or 1.
            if islogical(state) || isnumeric(state)
                v = double(state ~= 0);
            else
                s = lower(string(state));
                v = double(any(s == ["on","1","true","enable","enabled"]));
            end
        end
    end
end
