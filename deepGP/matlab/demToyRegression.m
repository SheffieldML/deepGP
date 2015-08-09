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
% SEE ALSO: demToyRegression.m (same as this demo but with a few more
% options to calibrate the deep GP).
% 
% DEEPGP


%--- Whatever configuration variable is not already set (ie does not exist
% as a variable in the workspace) is set to a default value.


% Number of iterations performed for initialising the variational
% distribution, and number of training iterations

H=2;                    % Number of layers
toyType='hierGpsNEW';
initX='inputsOutputs';  % Initialise X with X0
learnInducing=1;        % Learning the inducing points
fixInducing = false;    % Do not tie inducing points to latent means
addBetaPrior=true;      % Add prior on beta parameter to avoid low SNR
priorScale = 25;        % Scale of prior
runGP=1; runVGPDS=0;    % Compare with GPs and/or VGPD
% Number of training data Ntr, dimensionality of outputs Dtoy, number
% of inducing points K and number of latent dimensions Q. K and Q can
% be different per layer if a cell array of length H is passed. Ntoy
% defines the number of test points (after removing Ntr training points
% randomly).
Ntr=35;  Dtoy=25; K=15; Q=8; Ntoy = 150;           
dynamicKern = {'lin','white','bias'};  % The kernel to be used in the uppermost level
baseKern = 'rbfardjit';                % The kernel to be used in the intermediate levels

% This is called "dynamics" and "time" for historical reasons.. It actually
% refers to a coupling GP in the uppermost level
dynamicsConstrainType = {'time'};
vardistCovarsMult = 1;                 % For internal calibration of initial variational covariances.
GPiters = 8000;                        % Number of optimisation iterations for GP comparisons

% Number of interations to perform for initialising the variational
% distribution (initVardistIters) and for normal optimisation. By passing
% vectors instead of single numbers we manage a sort of "annealing"
% optimisation schedule, e.g. itNo = [100 100] means that after 100
% optimistion steps the optimiser will restart (sometimes this helps
% avoiding local optima).
if ~exist('initVardistIters','var'), initVardistIters = [1100 1100 1100];   end
if ~exist('itNo','var'), itNo = [2000 repmat(1000, 1,13)]; end
if ~exist('initSNR','var'), initSNR = {150, 350}; end  % Initial Signal To Noise ration per layer

% Initialise script based on the above variables. This returns a struct
% "globalOpt" which contains all configuration options
hsvargplvm_init;
% Automatically calibrate initial variational covariances
globalOpt.vardistCovarsMult = [];
globalOpt.dataSetName = 'toyRegression';

demToyDynamicsCreateData
demToyDynamicsSplitDataset % Split into training and test set

%% Run a normal GP to compare
if ~(exist('runGP') && ~runGP)
    % Run a sparse GP
    fprintf('# ----- Training a fitc GP... \n')
    optionsGP = gpOptions('fitc');
    optionsGP.numActive = globalOpt.K; %size(inpX,1);
    if globalOpt.fixInducing
        optionsGP.fixInducing = true;
        optionsGP.fixIndices = 1:optionsGP.numActive;
    end
    % Scale outputs to variance 1.
    %optionsGP.scale2var1 = true;
    modelGPfitc = gpCreate(size(inpX,2), size(Ytr{1},2), inpX, Ytr{1}, optionsGP);
    modelGPfitc = gpOptimise(modelGPfitc, 1, GPiters);
    [muGPfitc, varSigmaGPfitc] = gpPosteriorMeanVar(modelGPfitc, Xstar);
    errorGPfitc = sum(mean(abs(muGPfitc-Yts{1}),1));
    errorRecGPfitc = sum(mean(abs(gpPosteriorMeanVar(modelGPfitc, inpX)-Ytr{1}),1));
end
%% Now run a deep GP
if ~(exist('runDeepGP') && ~runDeepGP)
    
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
        % Q will be changed, because in this initialisation the Q of the
        % top layer MUST be the same as the dimensionality of the inputs.
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
        Q = oldQ; % Restore Q to its original value
    end
    
    % Just rewrite all options into a struct of cells
    optionsAll = hsvargplvmCreateOptions(Ytr, options, globalOpt);

    
    %---
    
    % Create the deep GP based on the model options, global options
    % (configuration) and options for initialising the latent spaces X
    model = hsvargplvmModelCreate(Ytr, options, globalOpt);
    
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
    
    % Complain if SNR is too low
    model.throwSNRError = true;
    model.SNRErrorLimit = 3;
    
    % Add a prior on the beta parameter, to avoid low SNR problems.
    if exist('addBetaPrior','var') && addBetaPrior
        meanSNR = 150; % Where I want the expected value of my inv gamma if it was on SNR
        priorName = 'invgamma'; % What type of prior
        varData = var(model.layer{model.H}.comp{1}.mOrig(:));
        meanB = meanSNR./varData;
        a=0.08;%1.0001; % Relatively large right-tail
        b=meanB*(a+1); % Because mode = b/(a-1)
        model = hsvargplvmAddParamPrior(model, model.H, 1, 'beta', priorName, [a b]);
        if exist('priorScale','var')
            model.layer{model.H}.comp{1}.paramPriors{1}.prior.scale = priorScale;
        end
    end   
    
    fprintf('# Scales after init. latent space:\n')
    hsvargplvmShowScales(model,false);
    
    %--- OPTIMISATION
    if exist('doGradchek') && doGradchek
        %model = hsvargplvmOptimise(model, true, itNo);
        if isfield(model.layer{end}, 'dynamics')
            model.layer{end}.dynamics.learnVariance = 1; % For the gradchek to pass
        end
        model = hsvargplvmOptimise(model, true, itNo, 'gradcheck', true);
    else
        modelInitVardist     = hsvargplvmOptimiseModel(model, 0, 0, [], {globalOpt.initVardistIters, 0});
        [model, modelPruned] = hsvargplvmOptimiseModel(modelInitVardist, 1, 1, [], {0, globalOpt.itNo});
        %[model,modelPruned, modelInitVardist] = hsvargplvmOptimiseModel(model, true, true);
    end
    
    % If you decide to train for further iterations...
    % modelOld = model; [model,modelPruned, ~] = hsvargplvmOptimiseModel(model, true, true, [], {0, [100]});   
end


%% Predictions
if exist('doPredictions','var') && ~doPredictions
    return
end
demToyDynamicsPredictions

%% Sample from the trained model
% ...