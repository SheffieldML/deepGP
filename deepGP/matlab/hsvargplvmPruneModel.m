% HSVARGPLVMPRUNEMODEL Prune a shared var-GPLVM model.
% FORMAT
% DESC prunes a Shared VAR-GPLVM model by removing some fields which can later be
% reconstructed based on what is being kept. Used when storing a model.
% ARG model: the model to be pruned
% ARG onlyData: only prune the data parts. Useful when saving a model which
% is updated after predictions.
% RETURN model : the shared variational GP-LVM model after being pruned
%
% COPYRIGHT: Andreas Damianou, 2011
%
% SEEALSO : vargplvmPruneModel, svargplvmRestorePrunedModel

% SVARGPLVM

function model = hsvargplvmPruneModel(model, onlyData)

if nargin == 1
    onlyData = 0;
end

for h=1:model.H
    for i=1:model.layer{h}.M
        model.layer{h}.comp{i} = vargplvmPruneModel(model.layer{h}.comp{i}, onlyData);
    end
end

model.isPruned = true;