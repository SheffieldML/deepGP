% HSVARGPLVMPROPAGATEFIELD Set the value for a (potentially not yet existing) field for every sub-model of the main hsvargplvm.
% DESC Set the value for a (potentially not yet existing) field for every sub-model of the main hsvargplvm.
% ARG model: the hsvargplvm model (containing the submodels) for which the
% we have to visit every submodel and set the given value to the specified
% field.
% ARG fieldName: the name of the field to set (with fieldValue) to every
% submodel.
% ARG fieldValue: the value for the fieldName
% ARG dynamics: if set to 1, then IN ADDITION to setting
%    model.comp{i}.fieldName = fieldValue
% the algorithm will ALSO set:
%   model.comp{i}.dymamics.fieldName = fieldValue.
% If dynamics is omitted, or if there is no field dynamics already,
% the argument dynamics takes the default falue FALSE.
% COPYRIGHT: Andreas C. Damianou,  2011
% SEEALSO : svargplvmModelCreate
%
% SVARGPLVM

function model = hsvargplvmPropagateField(model, fieldName, fieldValue, layers, dynamics)

if nargin < 5 || ~isfield(model, 'dynamics') || isempty(model.dynamics)
    dynamics = 0;
end

if nargin < 4 || isempty(layers)
    layers = 1:model.H;
end

for h=layers
    for i=1:model.layer{h}.M
        model.layer{h}.comp{i}.(fieldName) = fieldValue;
        if dynamics
            model.comp{i}.layer{h}.dynamics.(fieldName) = fieldValue;
        end
    end
end