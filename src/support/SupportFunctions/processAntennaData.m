% Modular function to handle Antenna Data
function combinedData = processAntennaData(app, combinedData)
    if ~isempty(combinedData)  
         app.Antenna_Data = combinedData;

         % Check each required field and add to the list if missing.
         expectedVars = {'Thetadeg', 'Phideg', 'FrequencyMHz', 'GaindBi', 'ReturnLossdB', 'ReturnLossdeg', 'AbsoluteGaindBi'};
         missingFields = setdiff(expectedVars, app.Antenna_Data.Properties.VariableNames);
 
         % Raise an error if any fields are missing. 
         if ~isempty(missingFields)
             error(['The antenna gain file is missing the following required field(s): ', strjoin(missingFields, ', ')]);
         end
    end
end
