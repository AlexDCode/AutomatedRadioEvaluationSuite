classdef (Abstract) ITransport < handle
    %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
    % ITransport
    %
    % DESCRIPTION:
    % Abstract transport interface for all ARES instrument I/O. This is the
    % seam that separates "what command to send" (driver classes) from "how
    % bytes move" (VISA, raw TCP, or simulation).
    %
    % Why this exists (paper goal: "bypassing VISA drivers when virtually
    % testing"): by programming every driver against this interface instead
    % of against visadev/tcpclient directly, any instrument can be backed by:
    %
    %   VisaTransport - real hardware over VISA (GPIB / LAN / USB)
    %   TcpTransport  - real hardware over a raw TCP socket (EMCenter slider)
    %   SimTransport  - no hardware at all; scripted/synthetic responses
    %
    % Swapping a transport requires zero changes to driver or measurement
    % code. Simulation stops being an `if obj.Simulate` special case inside
    % every method and becomes just another transport implementation.
    %
    % CONTRACT (all concrete transports must implement):
    %   open()                  - establish the link (idempotent)
    %   close()                 - release the link and the underlying handle
    %   writeLine(cmd)          - send one terminated ASCII command
    %   s = readLine()          - read one terminated ASCII response (trimmed)
    %   d = readBinaryBlock(t)  - read an IEEE 488.2 definite-length binary
    %                             block (equivalent of readbinblock); required
    %                             for VNA / signal-analyzer trace transfers
    %   flush()                 - discard any unread input
    %   tf = isOpen()           - true if the link is currently usable
    %
    % PROVIDED (concrete convenience methods built on the contract):
    %   s = writeRead(cmd)      - writeLine followed by readLine
    %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

    properties (SetAccess = protected)
        % Human-readable description of the endpoint (for logs and errors).
        Description (1,1) string = ""
    end

    methods (Abstract)
        open(obj)
        close(obj)
        writeLine(obj, cmd)
        s = readLine(obj)
        d = readBinaryBlock(obj, datatype)
        flush(obj)
        tf = isOpen(obj)
    end

    methods
        function s = writeRead(obj, cmd)
            % WRITEREAD  Send a command and read one line back.
            obj.writeLine(cmd);
            s = obj.readLine();
        end

        function delete(obj)
            % Destructor: make sure the link is released when the transport
            % object goes out of scope, so handles never leak.
            try
                obj.close();
            catch
                % Never throw from a destructor.
            end
        end
    end
end
