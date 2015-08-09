% Regression demo with Deep GPs on toy data.
% This demo is kept minimal. See tutorial.m for a more complete demo.
% Andreas Damianou, 2015

clear

rand('seed', 2)
randn('seed', 2)

% ----- Configuration
Ntr=25;   % Number of training data
K=10;     % Number of inducing points
Q=6;      % Dimensionality of hidden (latent) layers
H=2;                    % Number of layers
dynamicKern = {'lin','white','bias'};  % The kernel to be used in the uppermost level which "sees" the inputs
baseKern = 'rbfardjit';                % The kernel to be used in the intermediate levels
initX = 'inputsOutputs';

% This is called "dynamics" and "time" for historical reasons.. What it actually
% means is that the inputs in the uppermost layer are treated as coupled.
dynamicsConstrainType = {'time'};

% Number of interations to perform for initialising the variational
% distribution (initVardistIters) and for normal optimisation. By passing
% vectors instead of single numbers we manage a sort of "annealing"
% optimisation schedule, e.g. itNo = [100 100] means that after 100
% optimistion steps the optimiser will restart (sometimes this helps
% avoiding local optima).
if ~exist('initVardistIters','var'), initVardistIters = [repmat(500,1,5)];   end
if ~exist('itNo','var'), itNo = [1000 1000]; end
if ~exist('initSNR','var'), initSNR = {150, 350}; end  % Initial Signal To Noise ration per layer

% Initialise script based on the above variables. This returns a struct
% "globalOpt" which contains all configuration options
hsvargplvm_init;
% Automatically calibrate initial variational covariances
globalOpt.vardistCovarsMult = [];
globalOpt.dataSetName = 'toyRegression';

% Create toy data. After the following three lines are called, we will
% have the following: 
%  inpX / Ytr: the training inputs / outputs
% Xstar / Yts: the test outputs
Ntoy = 150; Dtoy=15; toyType='hierGpsNEW';
demToyDynamicsCreateData
demToyDynamicsSplitDataset % Split into training and test set

%% ----- Run a normal GP to compare

fprintf('# ----- Training a fitc GP... \n')
optionsGP = gpOptions('fitc');
optionsGP.numActive = globalOpt.K; %size(inpX,1);

modelGPfitc = gpCreate(size(inpX,2), size(Ytr{1},2), inpX, Ytr{1}, optionsGP);
modelGPfitc = gpOptimise(modelGPfitc, 1, 500);
[muGPfitc, varSigmaGPfitc] = gpPosteriorMeanVar(modelGPfitc, Xstar);
errorGPfitc = sum(mean(abs(muGPfitc-Yts{1}),1));
errorRecGPfitc = sum(mean(abs(gpPosteriorMeanVar(modelGPfitc, inpX)-Ytr{1}),1));

%% ------ Now run a deep GP

[options, optionsDyn] = hsvargplvmOptions(globalOpt, inpX);

% Create the deep GP based on the model options, global options
% (configuration) and options for initialising the latent spaces X
[model, options, globalOpt, optionsDyn] = hsvargplvmModelCreate(Ytr, options, globalOpt, [], optionsDyn);

% Since we do regression, we need to add a GP on the parent node. This GP
% couples the inputs and is parametrised by options in a struct "optionsDyn".
model = hsvargplvmAddParentPrior(model, globalOpt, optionsDyn);

% This just ensures model parameters are up-to-date
params = hsvargplvmExtractParam(model); model = hsvargplvmExpandParam(model, params);

% Complain if SNR is too low
model.throwSNRError = true; model.SNRErrorLimit = 3;

% Add a prior on the beta parameter, to avoid low SNR problems.
model = hsvargplvmControlSNR(model);

fprintf('# Scales after init. latent space:\n')
hsvargplvmShowScales(model,false);

% Optimisation
modelInitVardist = hsvargplvmOptimiseModel(model, 0, 0, [], {globalOpt.initVardistIters, 0});
model = hsvargplvmOptimiseModel(modelInitVardist, 1, 1, [], {0, globalOpt.itNo});

%% ------------ Predictions and Errors

% Prediction from the deep GP
[Testmeans Testcovars] = vargplvmPredictPoint(model.layer{end}.dynamics, Xstar);
[mu, varsigma] = hsvargplvmPosteriorMeanVarSimple(model, Testmeans, Testcovars);
errorDeepGP = sum(mean(abs(mu-Yts{1}),1));
errorDeepGPNoCovars = sum(mean(abs(hsvargplvmPosteriorMeanVarSimple(model, Testmeans)-Yts{1}),1));

% Mean predictor's error
errorMean = sum(mean(abs(repmat(mean(Ytr{1}),size(Yts{1},1),1) - Yts{1}),1));

% Linear regression's error
for dd=1:size(Ytr{1},2)
    [p, ErrorEst] = polyfit(inpX,Ytr{1}(:,dd),2);
    yLinReg(:,dd)=polyval(p,Xstar);
end
errorLinReg = sum(mean(abs(yLinReg - Yts{1}),1));

% Print all
fprintf('\n\n#### ERRORS:\n')
fprintf('# Error GPfitc pred      : %.4f\n', errorGPfitc);
fprintf('# Error DeepGP pred      : %.4f / %.4f (with/without covars)\n', errorDeepGP, errorDeepGPNoCovars);
fprintf('# Error Mean             : %.4f\n', errorMean);
fprintf('# Error LinReg           : %.4f\n', errorLinReg);
