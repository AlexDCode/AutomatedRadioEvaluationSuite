classdef HandleTransport < ITransport
    %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
    % HandleTransport
    %
    % DESCRIPTION:
    % ITransport implementation that wraps an ALREADY-OPEN instrument handle
    % (a visadev or tcpclient) that is owned by someone else — typically the
    % ARES app, which stores raw handles in app.VNA, app.EMCenter, etc.
    %
    % It lets a measurement function wrap a handle the app already holds (via
    % aresInstrument) and call high-level driver methods on it, while the app
    % keeps owning and closing the underlying handle exactly as before.
    %
    % NOTES:
    % This transport does not own the handle. open() and close() are no-ops,
    % so wrapping or unwrapping never opens or closes the app's connection.
    % Whatever created the handle stays responsible for its lifetime.
    %
    % USAGE:
    % Normally reached through aresInstrument rather than constructed here:
    %   t   = HandleTransport(app.VNA);     % app.VNA is a live visadev
    %   vna = VNAInstCtrl("auto","auto","wrapped","Transport",t);
    %   vna.connect();                      % open() is a no-op; just *IDN?
    %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

    properties (Access = private)
        Handle   % visadev or tcpclient, owned elsewhere
    end

    methods
        function obj = HandleTransport(handle)
            % HANDLETRANSPORT  Wrap an existing open instrument handle.
            obj.Handle = handle;
            obj.Description = "wrapped " + string(class(handle));
        end

        function open(~)
            % No-op: the handle is already open and owned elsewhere.
        end

        function close(~)
            % No-op: never release a handle this object does not own.
            % (Closing here would kill app.VNA et al. out from under ARES.)
        end

        function tf = isOpen(obj)
            tf = ~isempty(obj.Handle) && isvalid(obj.Handle);
        end

        function writeLine(obj, cmd)
            writeline(obj.Handle, cmd);
        end

        function s = readLine(obj)
            s = string(strip(readline(obj.Handle)));
        end

        function d = readBinaryBlock(obj, datatype)
            if nargin < 2, datatype = "double"; end
            d = readbinblock(obj.Handle, datatype);
        end

        function flush(obj)
            flush(obj.Handle);
        end
    end
end
