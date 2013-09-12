function [model, modelPruned, modelInitVardist] = hsvargplvmOptimiseModel(model, varargin)
% HSVARGPLVMOPTIMIEMODEL High-level optimiser of a deep GP model.
% FORMAT (SHORT): model, pruneModel, saveModel, globalOpt, {initVardistIters, itNo} 
% FORMAT:
% ARG model: the initial model to be optimised
% (the last two arguments override the globalOpt values)
% varargin (all optional) can be:
% ARG pruneModel: prune model before saving it, if set to true (saves
% space), if also saveModel is true
% ARG saveModel: whether to save the optimised model between runs
% ARG globalOpt: The structure of global experiment options as configured
% by hsvargplvm_init. 
% ARG {initVardistIters, itNo}: how many iterations to train the model for
% initialising the variational distribution (first cell) and for normal
% iterations. These values are normally present to globalOpt (if provided),
% but if they are also given here as arguments, they overried the
% aforementioned.
%
% RETURN: The optimised model, the pruned model and the model obtained
% after initialising the variational distribution
%
% See also: hsvargplvmOptimise.m, hsvargplvm_init.m, tutorial.m
%
% COPYRIGHT: Andreas C. Damianou, 2013
%
% DEEPGP

modelPruned = [];
modelInitVardist = [];
pruneModel = true;
saveModel = true;

if isfield(model, 'saveName')
    if strcmp(model.saveName, 'noSave')
        saveModel = false;
    end
end

if isfield(model, 'globalOpt')
    globalOpt = model.globalOpt;
else
    globalOpt = varargin{3};
end


if nargin > 2
    pruneModel = varargin{1};
    if length(varargin) > 1
        saveModel = varargin{2};
    end

    if length(varargin) > 3
        globalOpt.initVardistIters = varargin{4}{1};
        globalOpt.itNo = varargin{4}{2};
    end
end

if ~isfield(model, 'optim'), model.optim = []; end
if ~isfield(model.optim, 'iters'),  model.optim.iters=0; end
if ~isfield(model.optim, 'initVardistIters'),  model.optim.initVardistIters = 0; end
% Number of evaluatiosn of the gradient
if ~isfield(model.optim, 'gradEvaluations'), model.optim.gradEvaluations = 0; end
% Number of evaluations of the objective (including line searches)
if ~isfield(model.optim, 'objEvaluations'), model.optim.objEvaluations = 0; end


display = 1;


i=1;
while ~isempty(globalOpt.initVardistIters(i:end)) || ~isempty(globalOpt.itNo(i:end))
    % do not learn beta for few iterations for intitilization
    if  ~isempty(globalOpt.initVardistIters(i:end)) && globalOpt.initVardistIters(i)
        %model.initVardist = 1; model.learnSigmaf = 0;
        model = hsvargplvmPropagateField(model,'initVardist', true, globalOpt.initVardistLayers);
        model = hsvargplvmPropagateField(model,'learnSigmaf', false, globalOpt.initVardistLayers);
        fprintf(1,'# Intitiliazing the variational distribution for %d iterations...\n', globalOpt.initVardistIters(i));
        [model, gradEvaluations, objEvaluations] = hsvargplvmOptimise(model, display, globalOpt.initVardistIters(i)); % Default: 20
        %SNR = hsvargplvmShowSNR(model,[2:model.H]);
        %hsvargplvmCheckSNR(SNR);
        model.optim.initVardistIters = model.optim.initVardistIters + globalOpt.initVardistIters(i);
        model.optim.gradEvaluations = model.optim.gradEvaluations + gradEvaluations;
        model.optim.objEvaluations = model.optim.objEvaluations + objEvaluations;
        if saveModel
            if pruneModel
                modelPruned = hsvargplvmPruneModel(model);
                fileName=vargplvmWriteResult(modelPruned, modelPruned.type, globalOpt.dataSetName, globalOpt.experimentNo);
            else
                fileName=vargplvmWriteResult(model, model.type, globalOpt.dataSetName, globalOpt.experimentNo);
            end
            fprintf('# Saved model %s after optimising beta for %d iterations...\n\n', fileName,globalOpt.initVardistIters(i))

        end
        modelInitVardist=model;
    end

    hsvargplvmShowScales(model, false);
    
    % Optimise the model.

    model.date = date;
    if  ~isempty(globalOpt.itNo(i:end)) && globalOpt.itNo(i)
        model = hsvargplvmPropagateField(model,'initVardist', false, globalOpt.initVardistLayers);
        model = hsvargplvmPropagateField(model,'learnSigmaf', true, globalOpt.initVardistLayers);

        iters = globalOpt.itNo(i); % Default: 1000
        fprintf(1,'# Optimising the model for %d iterations (session %d)...\n',iters,i);
        [model, gradEvaluations, objEvaluations] = hsvargplvmOptimise(model, display, iters);
        model.optim.iters = model.optim.iters + iters;
        model.optim.gradEvaluations = model.optim.gradEvaluations + gradEvaluations;
        model.optim.objEvaluations = model.optim.objEvaluations + objEvaluations;
        % Save the results.
        if saveModel
            if pruneModel
                modelPruned = hsvargplvmPruneModel(model);
                fileName=vargplvmWriteResult(modelPruned, modelPruned.type, globalOpt.dataSetName, globalOpt.experimentNo);
            else
                fileName=vargplvmWriteResult(model, model.type, globalOpt.dataSetName, globalOpt.experimentNo);
            end
             fprintf(1,'# Saved model %s after doing %d iterations\n\n',fileName,iters)
        end
    end
    i = i+1;
end

