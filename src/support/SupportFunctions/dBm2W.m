function P = dBm2W(PdBm)
    %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
    % dBm2mag Converts dBm to W
    %
    % INPUT PARAMETERS
    %   PdBm: Power in (dBm)
    %
    % OUTPUT PARAMETERS
    %   P:    Power in (W)
    %
    % Credit: Alex D. Santiago Vargas, PhD
    %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
    P = 10.^((PdBm-30)/10);
end