classdef TcpTransport < ITransport
    %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
    % TcpTransport
    %
    % DESCRIPTION:
    % ITransport implementation backed by a raw tcpclient socket. Used for
    % devices that speak line-oriented ASCII over plain TCP rather than full
    % VISA — in ARES that is the ETS-Lindgren EMCenter linear slider
    % (192.168.0.100:1206, "TCPIP::...::1206::SOCKET" in the instrument CSV).
    %
    % Folding the slider onto the same transport interface as the VISA
    % instruments means the EmCenterSlider driver gains, for free:
    %   - simulation support (back it with a SimTransport instead)
    %   - the corrected close/cleanup semantics (no leaked sockets)
    %   - uniform error behavior with every other instrument
    %
    % USAGE:
    %   t = TcpTransport("192.168.0.100", 1206);
    %   t.open();
    %   pos = t.writeRead("AXIS1:CP?");
    %   t.close();
    %
    %   % Or directly from a VISA-style socket resource string:
    %   t = TcpTransport.fromResource("TCPIP::192.168.0.100::1206::SOCKET");
    %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

    properties (SetAccess = private)
        Host       (1,1) string = ""
        Port       (1,1) double = NaN
        TimeoutSec (1,1) double = 5
    end

    properties (Access = private)
        Client   % tcpclient object, or [] when closed
    end

    methods
        function obj = TcpTransport(host, port, opts)
            % TCPTRANSPORT  Construct a TCP transport (does not open it).
            %
            % INPUT:
            %   host - IP address or hostname (string)
            %   port - TCP port number
            %
            % Name-Value:
            %   TimeoutSec - I/O timeout in seconds (default 5)
            arguments
                host (1,1) string
                port (1,1) double {mustBePositive, mustBeInteger}
                opts.TimeoutSec (1,1) double = 5
            end

            obj.Host        = host;
            obj.Port        = port;
            obj.TimeoutSec  = opts.TimeoutSec;
            obj.Description = sprintf("TCP %s:%d", host, port);
        end

        function open(obj)
            % OPEN  Connect the socket (idempotent).
            if obj.isOpen(), return; end
            obj.Client = tcpclient(char(obj.Host), obj.Port, ...
                                   "Timeout", obj.TimeoutSec);
            obj.Client.ByteOrder = "little-endian";
        end

        function close(obj)
            % CLOSE  Release the socket by dropping the last reference.
            % (Assigning [] is the documented way to destroy a tcpclient;
            % `clear obj.Client` inside a method is a no-op — that bug caused
            % the stale-connection failures in the legacy slider scripts.)
            obj.Client = [];
        end

        function tf = isOpen(obj)
            tf = ~isempty(obj.Client);
        end

        function writeLine(obj, cmd)
            obj.assertOpen_();
            writeline(obj.Client, cmd);
        end

        function s = readLine(obj)
            obj.assertOpen_();
            s = string(strip(readline(obj.Client)));
        end

        function d = readBinaryBlock(obj, datatype)
            % READBINARYBLOCK  Read an IEEE 488.2 binary block from the
            % socket. Rare for TCP devices, but supported so the interface
            % is uniform (readbinblock accepts tcpclient objects).
            obj.assertOpen_();
            if nargin < 2, datatype = "double"; end
            d = readbinblock(obj.Client, datatype);
        end

        function flush(obj)
            obj.assertOpen_();
            flush(obj.Client);
        end
    end

    methods (Static)
        function obj = fromResource(resource, opts)
            % FROMRESOURCE  Build a TcpTransport from a VISA-style socket
            % resource string, e.g. "TCPIP::192.168.0.100::1206::SOCKET".
            %
            % This lets the InstrumentFactory treat socket devices and VISA
            % devices uniformly from instrumentAddresses.csv.
            arguments
                resource (1,1) string
                opts.TimeoutSec (1,1) double = 5
            end

            tok = regexp(resource, ...
                "^TCPIP\d*::([^:]+)::(\d+)::SOCKET$", "tokens", "ignorecase");
            if isempty(tok)
                error("TcpTransport:BadResource", ...
                    "Not a TCP socket resource string: %s", resource);
            end
            host = string(tok{1}{1});
            port = str2double(tok{1}{2});
            obj  = TcpTransport(host, port, "TimeoutSec", opts.TimeoutSec);
        end

        function tf = isSocketResource(resource)
            % ISSOCKETRESOURCE  True if the resource string is a raw-socket
            % VISA resource ("TCPIP[n]::host::port::SOCKET").
            tf = ~isempty(regexp(string(resource), ...
                "^TCPIP\d*::[^:]+::\d+::SOCKET$", "once", "ignorecase"));
        end
    end

    methods (Access = private)
        function assertOpen_(obj)
            if ~obj.isOpen()
                error("TcpTransport:NotOpen", ...
                    "TCP transport to %s:%d is not open. Call open() first.", ...
                    obj.Host, obj.Port);
            end
        end
    end
end
