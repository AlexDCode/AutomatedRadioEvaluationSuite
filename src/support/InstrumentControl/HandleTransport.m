classdef HandleTransport < ITransport
    %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
    % HandleTransport
    %
    % DESCRIPTION:
    % ITransport implementation that wraps an ALREADY-OPEN instrument handle
    % (a visadev or tcpclient) that is owned by someone else — typically the
    % ARES app, which stores raw handles in app.VNA, app.EMCenter, etc.
    %
    % This is the bridge that lets the migration happen incrementally without
    % touching ARES.mlapp first: a measurement function can wrap app.VNA in a
    % driver (via aresInstrument) and call high-level OO methods, while the
    % app keeps owning and closing the underlying handle exactly as before.
    %
    % KEY PROPERTY: it does NOT own the handle. open() and close() are no-ops
    % so wrapping/unwrapping never opens or closes the app's connection. Only
    % the app (or whatever created the handle) is responsible for its life.
    %
    % USAGE (normally via aresInstrument, not directly):
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
