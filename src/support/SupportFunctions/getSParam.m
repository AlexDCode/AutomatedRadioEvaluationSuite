function c = getSParam(S, name)
    %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
    % DESCRIPTION:
    % Look up one complex S-parameter vector in a name->complex map, with a
    % clear error if it is missing. Used by the n-port antenna computations
    % (gain, reciprocity, efficiency) which index S-parameters by "Sij" label.
    %
    % INPUT:
    %   S    - containers.Map from "Sij" (char) to a complex vector, as
    %          returned by VNAInstCtrl.measureComplexByName.
    %   name - the S-parameter label to fetch, e.g. "S31" (case-insensitive).
    %
    % OUTPUT:
    %   c    - the complex column vector for that S-parameter.
    %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

    key = char(upper(string(name)));
    if ~isKey(S, key)
        error("getSParam:MissingSParam", ...
            "S-parameter %s is not present. Available: %s", ...
            key, strjoin(string(keys(S)), ", "));
    end
    c = S(key);
    c = c(:);
end
