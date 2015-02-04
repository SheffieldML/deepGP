randn('seed', 1e4);
rand('seed', 1e4);

if ~exist('dynamicsConstrainType', 'var'), dynamicsConstrainType = {'time'}; end
if ~exist('dynamicKern', 'var'), dynamicKern = {'rbf','white','bias'}; end
if ~exist('initX', 'var'), initX = 'ppca'; end
% This allows to take the inputs (or even other matrices) into account when
% initialising the latent spaces. Check hsvargplvmModelCreate.m.
if ~exist('doExtraInit','var'), doExtraInit = false; end
vardistCovarsMult = [];

hsvargplvm_init;

assert(exist('inpX','var') && exist('Ytr','var'), 'Inputs inpX and outputs Ytr must be already in the workspace.');

[options, optionsDyn] = hsvargplvmOptions(globalOpt, inpX);

if doExtraInit
    options.extraInit = inpX;
end

% ---- Potential special initialisations for X -----
if ~iscell(globalOpt.initX) && strcmp(globalOpt.initX, 'inputs')
    options = rmfield(options, 'initX');
    for i=1:options.H
        options.initX{i} = inpX;
    end
    optionsDyn.initX = inpX;
    globalOpt.initX = options.initX;
end

% Initialise half of the latent spaces with inputs, half with PCA on outputs
if ~iscell(globalOpt.initX) && strcmp(globalOpt.initX, 'inputsOutputs')
    options = rmfield(options, 'initX');
    oldQ = Q; clear Q
    for i=options.H:-1:floor(options.H/2)+1
        options.initX{i} = inpX;
        Q{i} = size(inpX,2);
    end
    optionsDyn.initX = inpX;

    YtrScaled = scaleData(Ytr{1}, options.scale2var1); 
    Xpca  = ppcaEmbed(YtrScaled, oldQ);
    for i=1:floor(options.H/2)
        options.initX{i} = Xpca;
        Q{i} = oldQ;
    end
    options.Q = Q;
    globalOpt.Q = Q;
    globalOpt.initX = options.initX;
end

options.optimiser = 'scg2';

% Just rewrite all options into a struct of cells
optionsAll = hsvargplvmCreateOptions(Ytr, options, globalOpt);
% Don't mind the following for loop... it just gives the extra possibility
% of initialising the latent space with Bayesian GPLVM or GPLVM (see
% hsvargplvm_init on how to activate this). 
initXOptions = cell(1, options.H);
for h=1:options.H
    if strcmp(optionsAll.initX{h}, 'vargplvm') | strcmp(optionsAll.initX{h}, 'fgplvm')
        initXOptions{h}{1} = optionsAll;
        % DOn't allow the D >> N trick for layers > 1
        if h~=1
            if isfield(initXOptions{h}{1}, 'enableDgtN')
                initXOptions{h}{1}.enableDgtN = false;
            end
        end
        initXOptions{h}{1}.latentDim = optionsAll.Q{h};
        initXOptions{h}{1}.numActive = optionsAll.K{h}{1};
        initXOptions{h}{1}.kern = optionsAll.kern{h}{1};
        initXOptions{h}{1}.initX = 'ppca';
        initXOptions{h}{1}.initSNR = 100;
        initXOptions{h}{1}.numActive = min(50, size(inpX,1));
        initXOptions{h}{2} = 100;
        initXOptions{h}{3} = 200;
        if exist('stackedInitVardistIters'),  initXOptions{h}{2} = stackedInitVardistIters;   end
        if exist('stackedInitIters'), initXOptions{h}{3} = stackedInitIters;   end
        if exist('stackedInitSNR'), initXOptions{h}{1}.initSNR = stackedInitSNR; end
        if exist('stackedInitK'), initXOptions{h}{1}.numActive = stackedInitK; end
    else
        initXOptions{h} = {};
    end
end
%---

% Create the deep GP based on the model options, global options
% (configuration) and options for initialising the latent spaces X
model = hsvargplvmModelCreate(Ytr, options, globalOpt, initXOptions);
optionsDyn.initX = model.layer{end}.vardist.means;
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
    % If we initialise X with the inputs (for regression) then fix the
    % inducing points to these inputs (that's not necessarily good, check
    % also without this option).
%    for h=1:options.H
%        if ~ischar(options.initX{h})
%            for m=1:model.layer{h}.M
%                model.layer{h}.comp{m}.X_u = inpX;
%            end
%        end
%    end
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
%%
if exist('doGradchek') && doGradchek
    %model = hsvargplvmOptimise(model, true, itNo);
    if isfield(model.layer{end}, 'dynamics')
        model.layer{end}.dynamics.learnVariance = 1; % For the gradchek to pass
    end
    model = hsvargplvmOptimise(model, true, itNo, 'gradcheck', true);
else
    [model,modelPruned, modelInitVardist] = hsvargplvmOptimiseModel(model, true, true);
end

% If you decide to train for further iterations...
% modelOld = model; [model,modelPruned, ~] = hsvargplvmOptimiseModel(model, true, true, [], {0, [100]});


 
