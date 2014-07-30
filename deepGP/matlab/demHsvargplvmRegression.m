% DEMTOYREGRESSION A script to run deep GP regression on toy data.
% DEEPGP


%--- Mandatory configurations
if ~exist('Ytr', 'var'), error('You need to specify your outputs in Ytr{1}=...'); end
if ~exist('inpX', 'var'), error('You need to specify your inputs in inpX=...'); end

%--- Optional configurations: Whatever configuration variable is not already set (ie does not exist
% as a variable in the workspace) is set to a default value.
if ~exist('experimentNo'), experimentNo = 404; end
if ~exist('K'), K = 30; end
if ~exist('Q'), Q = 6; end
if ~exist('baseKern'), baseKern = 'rbfardjit'; end % {'rbfard2','white','bias'}; end
% This is called "dynamics" and "time" for historical reasons.. It actually refers to a coupling GP in the uppermost level
if ~exist('dynamicsConstrainType'), dynamicsConstrainType = {'time'}; end
stackedOpt = [];
if exist('stackedInitVardistIters', 'var'), stackedOpt.stackedInitVardistIters=stackedInitVardistIters; end
if exist('stackedInitIters', 'var'), stackedOpt.stackedInitIters=stackedInitIters; end
if exist('stackedInitSNR', 'var'), stackedOpt.stackedInitSNR=stackedInitSNR; end
if exist('stackedInitK', 'var'), stackedOpt.stackedInitK=stackedInitK; end
if ~exist('initXOptions', 'var'), initXOptions = []; end

% Initialise script based on the above variables. This returns a struct
% "globalOpt" which contains all configuration options
hsvargplvm_init;

% Automatically calibrate initial variational covariances - better to not change that
globalOpt.vardistCovarsMult = [];

[options, optionsDyn] = hsvargplvmOptions(globalOpt, inpX);

% Initialise latent spaces, unless the user already did that
if ~(iscell(options.initX) && prod(size(options.initX{1})) > 1)
    [globalOpt, options, optionsDyn, initXOptions] = hsvargplvmRegressionInitX(globalOpt, options, optionsDyn, inpX, Ytr, stackedOpt);
end


% Create the deep GP based on the model options, global options
% (configuration) and options for initialising the latent spaces X
model = hsvargplvmModelCreate(Ytr, options, globalOpt, initXOptions);

% Since we do regression, we need to add a GP on the parent node. This GP
% couples the inputs and is parametrised by options in a struct "optionsDyn".
model = hsvargplvmAddParentPrior(model, globalOpt, optionsDyn);


%-- We have the option to not learn the inducing points and/or fix them to
% the given inputs.
% Learn inducing points? (that's different to fixInducing, ie tie them
% to X's, if learnInducing is false they will stay in their original
% values, ie they won't constitute parameters of the model).
if exist('learnInducing') && ~learnInducing
    model = hsvargplvmPropagateField(model, 'learnInducing', false);
end
%--

if globalOpt.fixInducing && globalOpt.fixInducing
    model = hsvargplvmPropagateField(model, 'fixInducing', true);
    for m=1:model.layer{end}.M % Not implemented yet for parent node
        model.layer{end}.comp{m}.fixInducing = false;
    end
end

params = hsvargplvmExtractParam(model);
model = hsvargplvmExpandParam(model, params);
model.globalOpt = globalOpt;
% Computations can be made in parallel, if option is activated
model.parallel = globalOpt.enableParallelism;

fprintf('# Scales after init. latent space:\n')
hsvargplvmShowScales(model,false);
%% OPTIMISATION
[model,modelPruned, modelInitVardist] = hsvargplvmOptimiseModel(model, true, true);

% If you decide to train for further iterations...
% modelOld = model; [model,modelPruned, ~] = hsvargplvmOptimiseModel(model, true, true, [], {0, [100]});


