% Takes a hsvargplvm model and adds a non-(standard normal) prior on the
% parent (see: addDynamics functions in the other vargplvm-related
% packages).

% See also: svargplvmAddDynamics.m

function model = hsvargplvmAddParentPrior(model, globalOpt, optionsDyn)

modelParent = model.layer{model.H};
modelParent.comp{1}.vardist = modelParent.vardist;
modelParent.comp{1}.X = modelParent.vardist.means;
% TODO: if center means....
if model.H > 1
    modelParent.comp{1}.y = model.layer{end-1}.vardist.means;
elseif length(model.layer{1}.comp) == 1
    modelParent.comp{1}.y = model.layer{1}.comp{1}.y;
else
    error('Not implemented!')
end

modelParent.comp{1} = svargplvmAddDynamics(modelParent.comp{1}, globalOpt, optionsDyn);


modelParent.vardist = modelParent.comp{1}.vardist;
modelParent.dynamics = modelParent.comp{1}.dynamics;
modelParent.comp{1} = rmfield(modelParent.comp{1}, 'vardist');
modelParent.comp{1} = rmfield(modelParent.comp{1}, 'dynamics');
modelParent.comp{1} = rmfield(modelParent.comp{1}, 'X');
modelParent.comp{1} = rmfield(modelParent.comp{1}, 'y');


model.layer{model.H} = modelParent;

%params = hsvargplvmExtractParam(model);
%model = hsvargplvmExpandParam(model, params);