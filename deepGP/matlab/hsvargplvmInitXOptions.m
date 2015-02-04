function [initXOptions, optionsAll] = hsvargplvmInitXOptions(Ytr, options, globalOpt)

stackedOpt = globalOpt.stackedInitOpt;

%--- Here we have the option of using Bayesian GPLVM or GPLVM for
% initialising the latent spaces. If this is the case, train the
% corresponding models
optionsAll = hsvargplvmCreateOptions(Ytr, options, globalOpt);
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
        initXOptions{h}{1}.initSNR = 90;
        initXOptions{h}{1}.numActive = 50;
        initXOptions{h}{2} = 160;
        initXOptions{h}{3} = 30;
        if ~isempty(stackedOpt)
            if isfield(stackedOpt, 'stackedInitVardistIters') && ~isempty(stackedOpt.stackedInitVardistIters)
                initXOptions{h}{2} = stackedOpt.stackedInitVardistIters;
            end
            if isfield(stackedOpt, 'stackedInitIters') && ~isempty(stackedOpt.stackedInitIters)
                initXOptions{h}{3} = stackedOpt.stackedInitIters;
            end
            if isfield(stackedOpt, 'stackedInitSNR') && ~isempty(stackedOpt.stackedInitSNR)
                initXOptions{h}{1}.initSNR = stackedOpt.stackedInitSNR;
            end
            if isfield(stackedOpt, 'stackedInitK') && ~isempty(stackedOpt.stackedInitK)
                initXOptions{h}{1}.numActive = stackedInitK;
            end
        end
    elseif ~isempty(stackedOpt) && (iscell(stackedOpt) && ~isempty(stackedOpt{h}))
        initXOptions{h} = stackedOpt{h};
    else
        initXOptions{h} = {};
    end
end