function ResultsTable = createNPortResultsTable(numRows)
    %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
    % DESCRIPTION:
    % Creates the long/tidy results table used by n-port antenna measurements.
    % Unlike the fixed-column 2-port table (createAntennaResultsTable), this
    % schema scales to any number of devices, ports and derived quantities:
    % every value is one row tagged by position, frequency, the device/port it
    % belongs to, the S-parameter it came from, and which quantity it is.
    %
    % COLUMNS:
    %   Theta (deg), Phi (deg), Frequency (MHz),
    %   Driven Port, Receive Port, S-Parameter, Quantity, Value
    %
    % (Driven Port = transmitter, Receive Port = receiver for a path; both
    % equal the port for a return-loss row; Receive Port is NaN for a
    % per-transmitter efficiency row.)
    %
    % QUANTITY is one of: 'Gain (dBi)', 'Return Loss (dB)', 'Return Loss (deg)',
    %   'Reciprocity Mag Delta (dB)', 'Reciprocity Phase Delta (deg)',
    %   'Radiation Efficiency'. The presence of the Quantity/Value columns is
    %   how loadData/processAntennaData recognises the n-port format.
    %
    % INPUT:
    %   numRows - rows to preallocate (default 0 for an empty template).
    %
    % OUTPUT:
    %   ResultsTable - the typed (possibly empty) table.
    %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

    if nargin < 1, numRows = 0; end

    varNames = {'Theta (deg)', 'Phi (deg)', 'Frequency (MHz)', ...
                'Driven Port', 'Receive Port', ...
                'S-Parameter', 'Quantity', 'Value'};
    varTypes = {'double', 'double', 'double', ...
                'double', 'double', ...
                'string', 'string', 'double'};

    ResultsTable = table('Size', [numRows, numel(varNames)], ...
                         'VariableTypes', varTypes, ...
                         'VariableNames', varNames);
end
