clc; clear; close all;

% Connect to the device.
LinearSlider = tcpclient('192.168.0.100', 1206);
LinearSlider.ByteOrder = 'little-endian';

% Get identification from device.
writeline(LinearSlider, '*IDN?');
response = readline(LinearSlider)

% Get the upper and lower mechanical limits.
% LowerLimit = str2double(writeread(LinearSlider, 'AXIS1:LL?'));
% UpperLimit = str2double(writeread(LinearSlider, 'AXIS1:UL?'));

% Get the current position of the device.
currentPosition = str2double(writeread(LinearSlider, 'AXIS1:CP?'))

% Set the speed of the device.
% speedPreset = str2double(writeread(LinearSlider, 'AXIS1:S?'));

err = writeread(LinearSlider, 'AXIS1:ERR?')
home= writeread(LinearSlider, 'AXIS1:HOME?')
% zero = writeread(LinearSlider, 'AXIS1:ZERO?')

% writeline(LinearSlider, 'AXIS1:ZERO')
writeline(LinearSlider, 'AXIS1:HOME')
while ~str2double(writeread(LinearSlider, 'AXIS1:*OPC?'))
    % writeline(LinearSlider, 'AXIS1:HOME')
    writeline(LinearSlider, 'AXIS1:ZERO')
end

% Delete and clear the connection to the device.
delete(LinearSlider);
clear LinearSlider;


%% Notes:
% Restart and move back from the front limit
% writeline(LinearSlider, 'AXIS1:CR'); % Turn CR mode on to disable soft limits
% writeline(LinearSlider, 'AXIS1:CC'); % Move backwards
% writeline(LinearSlider, 'AXIS1:ST'); % STOP 
% writeline(LinearSlider, 'AXIS1:NCR'); % Turn NCR mode on to enable soft limits
% writeline(LinearSlider, 'AXIS1:HOME')
% writeread(LinearSlider, 'AXIS1:*OPC?')