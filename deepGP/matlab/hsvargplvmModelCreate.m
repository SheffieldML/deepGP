function [hmodel, options, globalOpt, optionsDyn] = hsvargplvmModelCreate(Ytr, options, globalOpt, initXOptions, optionsDyn)

if nargin < 5, optionsDyn = []; end

if nargin < 4 || isempty(initXOptions)
    % These options are passed to the function that initialises X. If it's
    % pca or isomap it's empty, but there is also the possibility that e.g.
    % the model is optimised with stacked vargplvm, so this struct has any
    % options for vargplvmEmbed (that is, the options structure of
    % vargplvm)
    for h=1:globalOpt.H
        initXOptions{h} = {};
    end
end


% ################  Fix the structure of the model #################-%

if ~iscell(options.Q)
    Q = options.Q;
    options = rmfield(options, 'Q');
    for h=1:options.H
        options.Q{h} = Q;
    end
end


if ~iscell(globalOpt.initX) && strcmp(globalOpt.initX, 'inputsOutputs')
    inpX = optionsDyn.t;
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

YtrOrig = Ytr;
% This variable only matters when h > 1. In that case, if e.g.
% prevLatentIndices={[1 2],[3 4]} it means that the
% model.layer{h}.comp{1}.y = model.layer{h-1}.vardist.means(:,[1 2])
% and similarly for the comp{2}.
prevLatentIndices = {};
for h = 1:options.H
    clear('m','mAll','initX','initial_X','curX');
    % The following variable might be nonempty if it's set in the previous
    % round. 
    if ~isempty(prevLatentIndices)
        if length(Ytr) > 1, error('Something went wrong!'); 
        end
        YY = Ytr{1}; Ytr = cell(1, length(prevLatentIndices));
        for j=1:length(prevLatentIndices)
            Ytr{j} = YY(:, prevLatentIndices{j});
        end
    end
    
    % Number of models in leaves layer
    M = 1;
    if iscell(Ytr), 
        M = length(Ytr); 
    else
        % The program assumes that data are stored in cells, even if it's a
        % single dataset it has to be in a cell
        Ytr = {Ytr};
    end
    Q = options.Q{h};
    
    %------------- Latent space ---------------------------------------------
    mAll = [];
    for i = 1:M
       % m{i} = scaleData(Ytr{i}, options.scale2var1); %%%????????? !!!!!!!!!!!!!!!!
       if h == 1 || globalOpt.centerMeans
           m{i} = scaleData(Ytr{i}, options.scale2var1); 
       else
           m{i} = Ytr{i};
       end
        mAll = [mAll m{i}];
    end
    % The following option is usually used for regression, and normally
    % we'd set options.extraInit = model.layer{end}.dynamics.t, ie the
    % inputs to the regression task. Then, if this initialisation is
    % activated, the latent space X_1 will be learned from the
    % concatenation of the outputs and the whole input space (if its
    % dimensionality is smaller than this of the outputs, otherwise it'll
    % be projected to a smaller space with pca) and then a projection of
    % this given extraInit matrix to ceil(Q/2) dimensions will be repeated
    % in every layer, ie layer X_2 will be initialised e.g. with pca on
    % [X_1 ppcaEmbed(options.extraInit, ceil(Q/2)]. The intuition is that
    % the inputs have to somehow be reflected in the latent space, and
    % Duvenaud et al. showed that it might be good to repeat it in every
    % layer to avoid heavy tailed gradients.
    if isfield(options, 'extraInit') && ~isempty(options.extraInit)
        if h == 1
            fprintf('# Taking extra information for initialisation in every layer!\n')
            assert(size(options.extraInit,1) == size(mAll,1));
            if size(options.extraInit,2) > size(mAll,2)
                tmp = ppcaEmbed(options.extraInit, size(mAll,2));
            end
        else
            % Can be avoided if previous Q is also same size
            tmp = ppcaEmbed(options.extraInit, ceil(Q/2));
        end
        mAll = [mAll tmp];
    end

    
    if iscell(options.initX)
        initX = options.initX{h};
    else
        initX = options.initX;
    end
    
    if M == 1
         % Initialise in the vargplvm style
        if isstr(initX)
            fprintf('# Initialising level %d with %s\n',h, initX)
            initFunc = str2func([initX 'Embed']);
            if strcmp(initX, 'leafOutputs')
                % In this case we initialise with the leaf outputs, rather
                % than with the outputs of the current layer.
                if Q ~= size(hmodel.layer{1}.comp{1}.m,2)
                    warning(['Q for layer ' num2str(h) ' was not set to leaf output dim, but leafOutput initialisation was selected! Fixing Q appropriately...'])
                    Q = size(hmodel.layer{1}.comp{1}.m,2);
                end
                curX = outputsEmbed(hmodel.layer{1}.comp{1}.m, Q, initXOptions{h}{:});
            else
                curX  = initFunc(mAll, Q, initXOptions{h}{:});
            end
        else
            fprintf('# Initialising level %d with given initial X\n',h)
            curX = initX;
        end
    else % M > 1
        % Initialise in the svargplvm style
        if iscell(options.initial_X)
            initial_X = options.initial_X{h};
        else
            initial_X = options.initial_X;
        end
        
        initFunc = str2func([initX 'Embed']);
        if strcmp(initial_X,'concatenated')
            fprintf('# Initialising level %d  with concatenation and %s\n',h, initX)
            curX  = initFunc(mAll, Q, initXOptions{h}{:});
        elseif strcmp(initial_X,'separately')
            fprintf('# Initialising level %d separately with %s\n', h,initX)
            Q1 = ceil(Q / M);
            curX = [];
            for i = 1:M
                curX = [curX initFunc(m{i}, Q1, initXOptions{h}{:})];
            end
            Q = Q1 * M;
            options.Q{h} = Q;
        else
            error([initialX ' is unknown'])
        end
    end
    
    %------------- Vargplvm sub-models ---------------------------------------------
    for i = 1:M
        if ~iscell(options.K)
            K = options.K;
        else
            K = options.K{h}{i};
        end
        if K == -1 || (options.fixInducing && h ~= options.H) %%% NEW (the second part is because we haven't implemented fixing inducing for the parent)
            K = size(Ytr{i},1);
        end
                
        opt = options;
        % DOn't allow the D >> N trick for layers > 1
        if h~=1
            if isfield(opt, 'enableDgtN')
                opt.enableDgtN = false;
            end
        end
        opt.latentDim = Q;
        opt.numActive = K;
        opt.initX = curX;
        
        if iscell(options.baseKern) && iscell(options.baseKern{1})
            opt.kern = globalOpt.baseKern{h}{i}; %{'rbfard2', 'bias', 'white'};
        else
            opt.kern = globalOpt.baseKern;
        end
        
        
        model{i} = vargplvmCreate(Q, size(Ytr{i},2), Ytr{i}, opt); 
        
        % Init vargplvm model
        %model{i}.X = curX; 
        model{i}.vardist.means = curX;
        if iscell(globalOpt.initSNR)
            optInit.initSNR = globalOpt.initSNR{h};
        else
            optInit.initSNR = globalOpt.initSNR;
        end
        model{i} = vargplvmParamInit(model{i}, m{i}, curX, optInit);
        %model{i}.X = curX;
        model{i}.vardist.means = curX;
        
        if isfield(globalOpt, 'inputScales') && ~isempty(globalOpt.inputScales)
            inpScales = globalOpt.inputScales;
        else
            inpScales = globalOpt.inverseWidthMult./(((max(curX)-min(curX))).^2); % Default 5
            %inpScales(:) = max(inpScales); % Optional!!!!!
        end
        if ~isfield(model{i}.kern, 'comp')
             model{i}.kern.inputScales = inpScales;
        else
             model{i}.kern.comp{1}.inputScales = inpScales;
        end
        
        %params = vargplvmExtractParam(model{i}); % !!!
        %model{i} = vargplvmExpandParam(model{i}, params); % !!!
        model{i}.vardist.covars = 0.5*ones(size(model{i}.vardist.covars)) + 0.001*randn(size(model{i}.vardist.covars));
        
        % This tells us which indices of the previous latent space this
        % model is responsible for. It can be empty if it's for the full
        % latent space.
        if ~isempty(prevLatentIndices)
            model{i}.latentIndices = prevLatentIndices{i};
        else
            model{i}.latentIndices = {}; % empty means "all"
        end
    end
    prevLatentIndices = {};
     
    
    %---- Fix the structure of the big model
    hmodel.layer{h}.vardist = model{1}.vardist;
    %hmodel.layer{h}.X = model{1}.X;
    hmodel.layer{h}.N = model{1}.N;
    hmodel.layer{h}.q = model{1}.q;
    hmodel.layer{h}.M = M;
    
    for i=1:M
        hmodel.layer{h}.comp{i} = model{i};
        % Remove model.vardist and model.X (which is shared)
        hmodel.layer{h}.comp{i} = rmfield(hmodel.layer{h}.comp{i}, 'vardist');
        hmodel.layer{h}.comp{i} = rmfield(hmodel.layer{h}.comp{i}, 'X');
        
        % No need to keep hmodel.layer.comp{..}.y, apart from the very first
        % model which has the actual observed data. For the rest, y in layer h
        % is X in layer h-1.
        if h ~= 1
             hmodel.layer{h}.comp{i} = rmfield(hmodel.layer{h}.comp{i}, 'y');
        end
    
    end
    
    
    % CHANGE Ytr for next iteration to be equal to current X
    if h ~= options.H
        clear Ytr;
        %Ytr{1} = hmodel.layer{h}.X; % TODO!!! Allow multiple models here
        

        if options.multOutput < h+1
            % !!!? Scaling is not needed here, because it is done internally in
            % vargplvmCreate
            Ytr{1} = hmodel.layer{h}.vardist.means; 
        else
            % If we reach here, we have to create one model per dimension
            % of the previous latent space. See also: updateStats
            for qq = 1:size(hmodel.layer{h}.vardist.means,2)
                %%Ytr{qq} = hmodel.layer{h}.vardist.means(:,qq);
                prevLatentIndices{qq}=qq;
            end
            Ytr{1} = hmodel.layer{h}.vardist.means;
        end
    end
end

if isfield(options, 'optimiser')
    hmodel.optimiser = options.optimiser;
end
hmodel.multOutput = options.multOutput;
hmodel.centerMeans = globalOpt.centerMeans;
hmodel.date = date;
hmodel.info = ' Layers are indexed bottom-up. The bottom ones, i.e. layer{1}.comp{:} are the observed data.';
hmodel.info = [hmodel.info sprintf('\n The top layer is the parent latent space.')];
hmodel.H = options.H;
hmodel.options = options;
hmodel.type = 'hsvargplvm';
hmodel.parallel = globalOpt.enableParallelism;
hmodel.checkSNR = globalOpt.checkSNR;
hmodel.globalOpt = globalOpt;
