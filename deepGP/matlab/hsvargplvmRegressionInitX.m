function [globalOpt, options, optionsDyn, initXOptions] = ...
    hsvargplvmRegressionInitX(globalOpt, options, optionsDyn, inpX, Ytr, stackedOpt)

if nargin < 6 || isempty(stackedOpt)
    stackedOpt = [];
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
    if iscell(globalOpt.Q)
        oldQ = globalOpt.Q{end};
    else
        oldQ = globalOpt.Q;
    end
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


% Just rewrite all options into a struct of cells
optionsAll = hsvargplvmCreateOptions(Ytr, options, globalOpt);
% Don't mind the following for loop... it just gives the extra possibility
% of initialising the latent space with Bayesian GPLVM or GPLVM (see
% hsvargplvm_init on how to activate this). 
initXOptions = cell(1, options.H);
for h=1:options.H
    if strcmp(optionsAll.initX, 'vargplvm') | strcmp(optionsAll.initX, 'fgplvm')
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
        initXOptions{h}{1}.initSNR = 90;
        initXOptions{h}{1}.numActive = 50;
        initXOptions{h}{2} = 160;
        initXOptions{h}{3} = 30;
        if isfield(stackedOpt, 'stackedInitVardistIters'),  initXOptions{h}{2} = stackedOpt.stackedInitVardistIters;   end
        if isfield(stackedOpt, 'stackedInitIters'), initXOptions{h}{3} = stackedOpt.stackedInitIters;   end
        if isfield(stackedOpt, 'stackedInitSNR'), initXOptions{h}{1}.initSNR = stackedOpt.stackedInitSNR; end
        if isfield(stackedOpt, 'stackedInitK'), initXOptions{h}{1}.numActive = stackedOpt.stackedInitK; end
    else
        initXOptions{h} = {};
    end
end