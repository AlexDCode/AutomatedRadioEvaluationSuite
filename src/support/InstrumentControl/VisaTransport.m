classdef VisaTransport < ITransport
    %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
    % VisaTransport
    %
    % DESCRIPTION:
    % ITransport implementation backed by a MATLAB visadev object. Used for
    % every VISA-addressable ARES instrument (VNA, signal generator, signal
    % analyzers, PSUs, EMCenter positioner) over GPIB, LAN, or USB.
    %
    % This class owns the visadev handle exclusively. Driver classes never
    % see it, which is what makes drivers transport-agnostic and simulatable.
    %
    % NOTE ON CLEANUP:
    % The original prototype framework called `clear obj.Device` to release
    % the handle. That is a silent no-op in MATLAB (it clears a *variable*
    % named "obj.Device", which doesn't exist) and the property kept the
    % connection alive — the same stale-connection leak ARES suffered from
    % in the legacy slider scripts. The correct release is to drop the last
    % reference by assigning [] (done in close()).
    %
    % USAGE:
    %   t = VisaTransport("TCPIP0::192.168.1.161::inst0::INSTR");
    %   t.open();
    %   idn = t.writeRead("*IDN?");
    %   t.close();
    %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

    properties (SetAccess = private)
        Address     (1,1) string = ""     % VISA resource string
        TimeoutSec  (1,1) double = 5      % I/O timeout (seconds)
        Termination (1,1) string = "LF"   % "LF" | "CR" | "CR/LF" | "none"
        ByteOrder   (1,1) string = "little-endian"
    end

    properties (Access = private)
        Device   % visadev object, or [] when closed
    end

    methods
        function obj = VisaTransport(address, opts)
            % VISATRANSPORT  Construct a VISA transport (does not open it).
            %
            % INPUT:
            %   address - VISA resource string, e.g. "TCPIP0::...::inst0::INSTR"
            %             or "GPIB0::19::INSTR".
            %
            % Name-Value:
            %   TimeoutSec  - I/O timeout in seconds (default 5)
            %   Termination - line terminator (default "LF")
            %   ByteOrder   - "little-endian" (default) or "big-endian"
            arguments
                address (1,1) string
                opts.TimeoutSec  (1,1) double = 5
                opts.Termination (1,1) string = "LF"
                opts.ByteOrder   (1,1) string = "little-endian"
            end

            obj.Address     = address;
            obj.TimeoutSec  = opts.TimeoutSec;
            obj.Termination = opts.Termination;
            obj.ByteOrder   = opts.ByteOrder;
            obj.Description = "VISA " + address;
        end

        function open(obj)
            % OPEN  Create and configure the visadev connection (idempotent).
            if obj.isOpen(), return; end

            obj.Device = visadev(obj.Address);
            obj.Device.Timeout   = obj.TimeoutSec;
            obj.Device.ByteOrder = obj.ByteOrder;

            switch upper(obj.Termination)
                case "LF",    configureTerminator(obj.Device, "LF");
                case "CR",    configureTerminator(obj.Device, "CR");
                case "CR/LF", configureTerminator(obj.Device, "CR/LF");
                otherwise     % "none": leave the visadev default in place
            end
        end

        function close(obj)
            % CLOSE  Release the visadev handle.
            %
            % Dropping the last reference destroys the underlying connection.
            % (See class header: `clear obj.Device` does NOT do this.)
            obj.Device = [];
        end

        function tf = isOpen(obj)
            tf = ~isempty(obj.Device) && isvalid(obj.Device);
        end

        function writeLine(obj, cmd)
            obj.assertOpen_();
            writeline(obj.Device, cmd);
        end

        function s = readLine(obj)
            obj.assertOpen_();
            s = string(strip(readline(obj.Device)));
        end

        function d = readBinaryBlock(obj, datatype)
            % READBINARYBLOCK  Read an IEEE 488.2 binary block (e.g. a VNA
            % trace requested with "CALC1:DATA? FDATA"). Returns a numeric
            % row vector of the requested datatype ("double", "single", ...).
            obj.assertOpen_();
            if nargin < 2, datatype = "double"; end
            d = readbinblock(obj.Device, datatype);
        end

        function flush(obj)
            obj.assertOpen_();
            flush(obj.Device);
        end
    end

    methods (Access = private)
        function assertOpen_(obj)
            if ~obj.isOpen()
                error("VisaTransport:NotOpen", ...
                    "VISA transport to %s is not open. Call open() first.", obj.Address);
            end
        end
    end
end
