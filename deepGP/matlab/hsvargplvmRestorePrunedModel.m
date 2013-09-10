function model = hsvargplvmRestorePrunedModel(model, Ytr, onlyData, options)
% SVARGPLVMRESTOREPRUNEDMODEL Restore a pruned shared var-GPLVM model.
% FORMAT
% DESC restores a svargplvm model which has been pruned and it brings it in
% the same state that it was before prunning.
% ARG model: the model to be restored
% ARG Ytr: the training data (it has to be a cell array of length equal to
% model.numModels)
% ARG onlyData: only pruned the data parts. Useful when saving a model which
% is updated after predictions.
% RETURN model : the variational GP-LVM model after being restored
%
% COPYRIGHT: Andreas Damianou,  2011
%
% SEEALSO : svargplvmPruneModel, vargplvmRestorePrunedModel

% SVARGPLVM

if nargin <3
    onlyData = 0;
end

if nargin <4
    options = [];
end


% FIrst, restore leaves
for i=1:model.layer{1}.M
    model.layer{1}.comp{i} = vargplvmRestorePrunedModel2(model.layer{1}.comp{i},Ytr{i}, onlyData, options);
end

% Now restore the rest
for h=2:model.H
    for i=1:model.layer{h}.M
        Ycur = model.layer{h-1}.vardist.means;
        model.layer{h}.comp{i} = vargplvmRestorePrunedModel2(model.layer{h}.comp{i},Ycur, onlyData, options);
        if h ~= 1
            model.layer{h}.comp{i} = rmfield(model.layer{h}.comp{i}, 'y');
        end
    end
end

if isfield(model, 'isPruned')
    model.isPruned = false;
end

params = hsvargplvmExtractParam(model);
model = hsvargplvmExpandParam(model, params);

end



% A variant of vargplvmRestorePrunedModel to fit the specific structure of
% hsvargplvm's model
function model = vargplvmRestorePrunedModel2(model, Ytr, onlyData, options)


if exist('onlyData') && onlyData
    %  model.mOrig = model.m;
    model.bias = mean(Ytr); % Default, has to be changed later if it was different
    
    if (nargin > 3) && ~isempty(options) && isfield(options,'scale2var1')
        if(options.scale2var1)
            model.scale = std(Ytr);
            model.scale(find(model.scale==0)) = 1;
            if(model.learnScales)
                warning('Both learn scales and scale2var1 set for GP');
            end
            if(isfield(options, 'scaleVal'))
                warning('Both scale2var1 and scaleVal set for GP');
            end
        end
    elseif  (nargin > 3) && ~isempty(options) && isfield(options, 'scaleVal')
        model.scale = repmat(options.scaleVal, 1, size(Ytr,2));
    else
        model.scale = ones(1,size(Ytr,2));
    end
end

model.y = Ytr;
model.m= gpComputeM(model);

if isfield(model, 'dynamics') && ~isempty(model.dynamics)
    model.dynamics.X = model.X;
end

if model.DgtN
    model.mOrig = model.m;
    YYT = model.m * model.m'; % NxN
    % Replace data with the cholesky of Y*Y'.Same effect, since Y only appears as Y*Y'.
    %%% model.m = chol(YYT, 'lower');  %%% Put a switch here!!!!
    [U S V]=svd(YYT);
    model.m=U*sqrt(abs(S));
    model.TrYY = sum(diag(YYT)); % scalar
else
    model.TrYY = sum(sum(model.m .* model.m));
end

if exist('onlyData') && onlyData
    try
        model.P = model.P1 * (model.Psi1' * model.m);
        model.B = model.P1' * model.P;
    catch e
        warning(e.message);
    end
    model = orderfields(model);
    return
end


model = orderfields(model);

end
