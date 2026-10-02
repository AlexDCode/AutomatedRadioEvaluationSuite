% Modular function to handle Antenna Data
function combinedData = processAntennaData(app, combinedData)
    if ~isempty(combinedData)
         app.Antenna_Data = combinedData;

         vn = app.Antenna_Data.Properties.VariableNames;

         % n-port long/tidy format: recognised by its Quantity/Value columns.
         % It has a different (per-row-tagged) schema, so the legacy fixed-field
         % check does not apply.
         if all(ismember({'Quantity', 'Value'}, vn))
             return;
         end

         % Legacy 2-port wide format: check each required field.
         expectedVars = {'Thetadeg', 'Phideg', 'FrequencyMHz', 'GaindBi', 'ReturnLossdB', 'ReturnLossdeg', 'AbsoluteGaindBi'};
         missingFields = setdiff(expectedVars, vn);

         % Raise an error if any fields are missing.
         if ~isempty(missingFields)
             error(['The antenna gain file is missing the following required field(s): ', strjoin(missingFields, ', ')]);
         end
    end
end
