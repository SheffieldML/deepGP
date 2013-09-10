% DEMTOYHSVARGPLVM1 A simple script to run deep GPs on simple hierarchical toy data for
% unsupervised learning.
%
% DESC A simple script to run deep GPs on simple hierarchical toy data for
% unsupervised learning.
%
% COPYRIGHT: Andreas C. Damianou, 2013
%
% SEE ALSO: demMultvargplvmStackToy1.m, demToyRegression.,
%
% DEEPGP

% Fix seeds
randn('seed', 1e5);
rand('seed', 1e5);

% Whatever configuration variables are not set, are taken here a default
% value
if ~exist('experimentNo'), experimentNo = 404; end
if ~exist('initial_X'), initial_X = 'separately'; end
if ~exist('baseKern'), baseKern = {'linard2','white','bias'}; end
if ~exist('itNo'), itNo = 500; end
if ~exist('initVardistIters'), initVardistIters = []; end
if ~exist('multVargplvm'), multVargplvm = false; end

% That's for the ToyData2 function:
if ~exist('toyType'), toyType = ''; end % Other options: 'fols','gps'
if ~exist('hierSignalStrength'), hierSignalStrength = 1;  end
if ~exist('noiseLevel'), noiseLevel = 0.05;  end
if ~exist('numHierDims'), numHierDims = 1;   end
if ~exist('numSharedDims'), numSharedDims = 5; end
if ~exist('Dtoy'), Dtoy = 10;            end
if ~exist('Ntoy'), Ntoy = 100;           end

hsvargplvm_init;

if exist('Yall')
    Ytr = Yall;
else
    [Ytr, dataSetNames, Z] = hsvargplvmCreateToyData2(toyType,Ntoy,Dtoy,numSharedDims,numHierDims, noiseLevel,hierSignalStrength);
end

globalOpt.dataSetName = ['toy_' toyType];

% This code allows for having multipled modalities (conditional
% independencies) in the layers.
% Skip this if you want multOutput only in 2nd layer
% If this option is active, then instead of having one modality for each
% signal, we'll have one modality per dimension of the concatenated signal
if globalOpt.multOutput
    fprintf('### Mult - hsvargplvm!! \n ###')
    initial_X = 'concatenated';
    Ynew=[];
    for i=1:length(Ytr)
        Ynew = [Ynew Ytr{i}];
    end
    clear Ytr
    for d=1:size(Ynew,2)
        Ytr{d} = Ynew(:,d);
    end
    clear Ynew
end
%%
options = hsvargplvmOptions(globalOpt);
options.optimiser = 'scg2';

%--- Here we have the option of using Bayesian GPLVM or GPLVM for
% initialising the latent spaces. If this is the case, train the
% corresponding models
optionsAll = hsvargplvmCreateOptions(Ytr, options, globalOpt);
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
        if exist('stackedInitVardistIters'),  initXOptions{h}{2} = stackedInitVardistIters;   end
        if exist('stackedInitIters'), initXOptions{h}{3} = stackedInitIters;   end
        if exist('stackedInitSNR'), initXOptions{h}{1}.initSNR = stackedInitSNR; end
        if exist('stackedInitK'), initXOptions{h}{1}.numActive = stackedInitK; end
    else
        initXOptions{h} = {};
    end
end
%---

% Create a deepGP model, parametrized by its local options, global options
% and options that say how to initialise the latent spaces X
model = hsvargplvmModelCreate(Ytr, options, globalOpt, initXOptions);
params = hsvargplvmExtractParam(model);
model = hsvargplvmExpandParam(model, params);

%% Optimise deep GP model
model.globalOpt = globalOpt;
[model,modelPruned, modelInitVardist] = hsvargplvmOptimiseModel(model, true, true);

% Uncomment if you decide to train for more iterations later...
%modelOld = model;
%model = hsvargplvmOptimiseModel(model, true, true, [], {0, [1000 1000 1000]});
