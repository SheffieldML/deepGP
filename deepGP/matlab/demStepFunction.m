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


%%

% Fix seeds
randn('seed', 1e5);
rand('seed', 1e5);


%-------------------
experimentNo = 1;
toyType = 'step';
baseKern='rbfardjit'; % The mapping kernel between the layers
Q = {1, 1, 1}; % Dimensionality of the latent space in each layer
H = 3;
initSNR = {100, 100, 100}; % Initial Signal to Noise ration per layer

initX = 'ppca';
% initX = 'vargplvm';
%initX = 'fgplvm';

% %- options for the BayesianGPLVM used to initialise the variational means
stackedInitIters = 150;
stackedInitVardistIters = 100;
stackedInitSNR = 100;


initVardistIters = 200;
itNo = 1000;
N = 40;
K = 15; 

%_-------------------------

% Whatever configuration variables are not set, are taken here a default
% value
if ~exist('experimentNo'), experimentNo = 404; end
if ~exist('initial_X'), initial_X = 'concatenated'; end
if ~exist('baseKern'), baseKern = {'linard2','white','bias'}; end
if ~exist('itNo'), itNo = 100; end
if ~exist('initVardistIters'), initVardistIters = []; end
if ~exist('multVargplvm'), multVargplvm = false; end
if ~exist('dynamicsConstrainType'), dynamicsConstrainType = {'time'}; end

hsvargplvm_init;
% Automatically calibrate initial variational covariances
globalOpt.vardistCovarsMult = [];

a = -1; b = 0;
inpX = a + (b-a).*rand(floor(N/2),1);
Ytr = zeros(floor(N/2), 1) + 0.005.*randn(floor(N/2),1);
a = 0.0000001; b = 1;
inpX = [inpX; a + (b-a).*rand(floor(N/2),1)];
Ytr = [Ytr; ones(floor(N/2), 1) + 0.005.*randn(floor(N/2),1)];

globalOpt.dataSetName = toyType;

[options, optionsDyn] = hsvargplvmOptions(globalOpt, inpX);


% ---- Potential special initialisations for X -----
if ~iscell(globalOpt.initX) && strcmp(globalOpt.initX, 'inputs')
    options = rmfield(options, 'initX');
    for i=1:options.H
        options.initX{i} = inpX;
    end
    optionsDyn.initX = inpX;
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

% Create the deep GP based on the model options, global options
% (configuration) and options for initialising the latent spaces X
model = hsvargplvmModelCreate(Ytr, options, globalOpt, initXOptions);

% Since we do regression, we need to add a GP on the parent node. This GP
% couples the inputs and is parametrised by options in a struct "optionsDyn".
model = hsvargplvmAddParentPrior(model, globalOpt, optionsDyn);


params = hsvargplvmExtractParam(model);
model = hsvargplvmExpandParam(model, params);
model.globalOpt = globalOpt;

fprintf('# Scales after init. latent space:\n')
hsvargplvmShowScales(model,false);
%%
[model,modelPruned, modelInitVardist] = hsvargplvmOptimiseModel(model, true, true);
