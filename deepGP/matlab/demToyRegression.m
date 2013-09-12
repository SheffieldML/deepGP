% DEMTOYREGRESSION A script to run deep GP regression on toy data.
%
% DESC A script to run deep GP regression on toy data. The script provides
% the option of parametrising the model and initialisation in many many
% different ways... but the core of the demo (define a deep GP and train
% it) is actually not that big, if you decide to use the default options.
%
% COPYRIGHT: Andreas C. Damianou, 2013
%
% SEE ALSO: demMultvargplvmStackToy1.m
%
% DEEPGP


% Fix seeds
%randn('seed', 1e5);
%rand('seed', 1e5);

%--- Whatever configuration variable is not already set (ie does not exist
% as a variable in the workspace) is set to a default value.
if ~exist('experimentNo'), experimentNo = 404; end
if ~exist('K'), K = 30; end
if ~exist('Q'), Q = 6; end
if ~exist('initial_X'), initial_X = 'separately'; end
if ~exist('baseKern'), baseKern = 'rbfardjit'; end % {'rbfard2','white','bias'}; end
if ~exist('itNo'), itNo = 100; end
if ~exist('initVardistIters'), initVardistIters = []; end
if ~exist('H'), H = 2; end
if ~exist('multVargplvm'), multVargplvm = false; end
% This is called "dynamics" and "time" for historical reasons.. It actually
% refers to a coupling GP in the uppermost level
if ~exist('dynamicsConstrainType'), dynamicsConstrainType = {'time'}; end

% That's for the ToyData2 function that creates toy data:
if ~exist('toyType'), toyType = 'nonstationary'; end % Other options: 'gps'
if ~exist('hierSignalStrength'), hierSignalStrength = 1;  end
if ~exist('noiseLevel'), noiseLevel = 0.01;  end
if ~exist('numHierDims'), numHierDims = 2;   end
if ~exist('numSharedDims'), numSharedDims = 2; end
if ~exist('Dtoy'), Dtoy = 10;            end
if ~exist('Ntoy'), Ntoy = 120;           end
if ~exist('trendEffect'), trendEffect = 2;           end
if ~exist('vardistCovarsMult'), vardistCovarsMult = 1; end
if ~exist('runVGPDS'), runVGPDS = false; end

% Initialise script based on the above variables. This returns a struct
% "globalOpt" which contains all configuration options
hsvargplvm_init;

% Automatically calibrate initial variational covariances
globalOpt.vardistCovarsMult = [];


if ~exist('Ntr'), Ntr = ceil(Ntoy/2); end

globalOpt.dataSetName = 'toyDynamic';

%[X,Y,Yorig,t,model] = hgplvmSampleModel3(2, 4, 100,5,false);

demToyDynamicsCreateData
demToyDynamicsSplitDataset % Split into training and test set

%% Run a normal GP to compare
if ~(exist('runGP') && ~runGP)
    fprintf('# ----- Training a normal GP... \n')
    optionsGP = gpOptions('ftc');
    if ~strcmp(optionsGP.approx, 'ftc')
        optionsGP.numActive = size(inpX,1);
    end
    % Scale outputs to variance 1.
    %optionsGP.scale2var1 = true;
    modelGP = gpCreate(size(inpX,2), size(Ytr{1},2), inpX, Ytr{1}, optionsGP);
    modelGP = gpOptimise(modelGP, 1, 8000);
    [muGP, varSigmaGP] = gpPosteriorMeanVar(modelGP, Xstar);
    errorGP = sum(mean(abs(muGP-Yts{1}),1));
    errorRecGP = sum(mean(abs(gpPosteriorMeanVar(modelGP, inpX)-Ytr{1}),1));
    %{
    close
    for i=1:size(muGP,2)
        plot(muGP(:,i), 'x-'); hold on; plot(Yts{1}(:,i), 'ro-'); hold off; pause
    end
    %}
    
    % Run a sparse GP
    fprintf('# ----- Training a sparse GP... \n')
    optionsGP = gpOptions('fitc');
    optionsGP.numActive = size(inpX,1);
    % Scale outputs to variance 1.
    %optionsGP.scale2var1 = true;
    modelGPfitc = gpCreate(size(inpX,2), size(Ytr{1},2), inpX, Ytr{1}, optionsGP);
    modelGPfitc = gpOptimise(modelGPfitc, 1, 8000);
    [muGPfitc, varSigmaGPfitc] = gpPosteriorMeanVar(modelGPfitc, Xstar);
    errorGPfitc = sum(mean(abs(muGPfitc-Yts{1}),1));
    errorRecGPfitc = sum(mean(abs(gpPosteriorMeanVar(modelGPfitc, inpX)-Ytr{1}),1));
end
%% Now run a deep GP
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


%% ----- Run VGPDS
if runVGPDS
    % Temporary: just to print the hier.GPLVM (aka deep GP) and GP results before
    % training VGPDS
    runVGPDS = false;
    demToyDynamicsPredictions
    runVGPDS = true;

    optionsVGPDS = vargplvmOptions('dtcvar');
    optionsVGPDS.kern = 'rbfardjit';
    optionsVGPDS.numActive = globalOpt.K;
    optionsVGPDS.optimiser = 'scg2';
    optionsVGPDS.initSNR = 100;
    optionsVGPDS.fixInducing = 1;
    optionsVGPDS.fixIndices = 1:size(Ytr{1},1);
    
    if iscell(options.initX)
        optionsVGPDS.initX = options.initX{1};
    else
        optionsVGPDS.initX = options.initX;
    end
    
    fprintf('# ----- Training VGPDS... \n')
    if iscell(Q), Qvgpds=Q{1}; else Qvgpds = Q; end
    if ~exist('VGPDSinitVardistIters'), VGPDSinitVardistIters = 100; end
    if ~exist('VGPDSiters'), VGPDSiters = 220; end
    [XVGPDS, sigma2, W, modelVGPDS,modelInitVardistVGPDS] = vargplvmEmbed(Ytr{1}, Qvgpds, optionsVGPDS,VGPDSinitVardistIters,VGPDSiters,1,optionsDyn);
    [TestmeansVGPDS TestcovarsVGPDS] = vargplvmPredictPoint(modelVGPDS.dynamics, Xstar);
    [muVGPDS, varsigmaVGPDS] = vargplvmPosteriorMeanVar(modelVGPDS, TestmeansVGPDS, TestcovarsVGPDS);
    errorVGPDS = sum(mean(abs(muVGPDS-Yts{1}),1));

    [TestmeansVGPDSIn TestcovarsVGPDSIn] = vargplvmPredictPoint(modelInitVardistVGPDS.dynamics, Xstar);
    [muVGPDSIn, varsigmaVGPDSIn] = vargplvmPosteriorMeanVar(modelInitVardistVGPDS, TestmeansVGPDSIn, TestcovarsVGPDSIn);
    errorVGPDSIn = sum(mean(abs(muVGPDSIn-Yts{1}),1));
    
    [TestmeansTrVGPDS TestcovarsTrVGPDS] = vargplvmPredictPoint(modelVGPDS.dynamics, inpX);
    errorRecVGPDS = sum(mean(abs(vargplvmPosteriorMeanVar(modelVGPDS, TestmeansTrVGPDS, TestcovarsTrVGPDS)-Ytr{1}),1));
end

%% Predictions
demToyDynamicsPredictions

%% Sample from the trained model
% ...