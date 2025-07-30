% Modular function to handle Antenna Reference Data
function combinedData = processAntennaReferenceData(app, combinedData, FileName)
     if ~isempty(combinedData) 
         % Extract antenna measurement parameters from the file.
         idx = (combinedData.Thetadeg==0) & (combinedData.Phideg==0);

         if ~any(idx)
             error('Boresight Gain is not available in the file (Theta=0 and Phi=0)')
         else
             combinedData = combinedData(idx,:);
             app.ReferenceGainFile = combinedData;
             app.ReferenceGainFilePath = FileName;
             
             % Check each required field and add to the list if missing.
             expectedVars = {'Thetadeg', 'Phideg', 'FrequencyMHz', 'GaindBi', 'ReturnLossdB', 'ReturnLossdeg', 'AbsoluteGaindBi'};
             missingFields = setdiff(expectedVars, app.ReferenceGainFile.Properties.VariableNames);

            % Raise an error if any fields are missing.
            if ~isempty(missingFields)
                error(['The antenna gain file is missing the following required field(s): ', strjoin(missingFields, ', ')]);
            end
         end
     end
end