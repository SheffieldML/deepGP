% Initialise options. If the field name of 'defaults' already exists as a
% variable, the globalOpt will take this value, otherwise the default one.

% hvargplvm_init

if ~exist('globalOpt')
    svargplvm_init 
    defaults = globalOpt;
    clear globalOpt
    
 
    %-------------------------------------------- Extra for hsvargplvm-----
    
    %%%%%%%%%%%%%%%%%%%%%% GRAPHICAL MODEL %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
    % This is one entry, being replicated in all models, all layers.
    defaults.mappingKern = 'rbfardjit';
    
    % For multvargplvm: This has to be as big as the number of submodels
    % (horizontally in the graphical model X -> [Y_1, ..., Y_K])
    % For hsvargplvm it should be a cell array in 2 dimensions, where e.g.
    % {{'K1','K2'}, {K3}} means that bottom layer has kernels K1 and K2 and
    % upper layer has kernel K3 (the order goes bottom - up).
    % For hsvargplvm, this is also allowed to just be a single string, in
    % which case it is replicated (it acts like defaults.mappingKern).
    defaults.baseKern = 'rbfardjit';
    
    
    % The number of latent space layers
    defaults.H = 2;
    
       
    % The number of inducing points for each layer. If this is a single
    % number, then the same number is replicated in all models, all layers.
    % Otherwise it should be a cell array in 2 dimensions, where e.g.
    % {{'K1','K2'}, {K3}} means that bottom layer has number K1 and K2 and
    % upper layer has number K3 (the order goes bottom - up). The entry 
    % -1 means that K == N.
    defaults.K = -1;
    
    %%%%%%%%%%%%%%%%%%%%% VARIOUS %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
    defaults.displayIters = true;
    
    % If we are fixing beta or sigmaf, we will do so only for the following
    % layers (1 is only leaves)
        %defaults.initVardistLayers = 1;
    defaults.initVardistLayers = 1:defaults.H;
    
    % If true, then the layer h takes a CENTERED version of the X of layer
    % h-1. That might not be correct because the expectation in the bound
    % is computed disregarding biases. The scaleData that centers the means
    % if this option is on, is in the create and updateStats functions
    defaults.centerMeans = false;
    
    % If == 1, then there will be one leaf model per input dimension (only
    % if the corresponding demo checks and takes this action)
    % If == 2, then the multOutput setting will also be carried in the
    % second layer (i.e. one model per latent dimension). And so on.
    % Maximum number allowed for this value is H-1.
    defaults.multOutput = 0;
    
    defaults.fixInducing = 0;
    %%%%%%%%%%%%%%%%%%%%%%%%%%%   LATENT SPACE %%%%%%%%%%%%%%%%%%%%%%%%%
       
    % The dimensionality of each latent space layer. If it's a cell array, then
    % it defines the dimensinality of each layer separately and needs to be
    % in the same size as H. !!! Attention: if Q is a cell array, the entry
    % Q{h} < Q{h-1} ! Otherwise the initialisation will not work...(we'll
    % have more latent dimensions than outputs)
    defaults.Q = 10;
    
    
    % How to initialise the latent space in level h based on the data of
    % level h-1. This can either be a signle entry (replicated in all
    % levels) or it can be a cell array of length H, i.e. different
    % initialisation for each level.
    % The values of this field are either strings, so that [@initX 'Embed']
    % is called, or it can be a matrix of an a priori computed latent space.
    % Other options for embedding:
    % 'pca','isomap2','vargplvm','fgplvm','outputs'. The last requires that
    % Q==D and initialises X=Y where the data is scaled so that it's 0 mean
    % 1 variance
    defaults.initX = 'ppca';
    
    % How to initialise the latent space of level h in case there are more than one
    % "modalities" in level h-1. This can either be a cell array of length
    % H or a single entry replicated in all layers, or
    % it is disregarded if there is only 1 modality per layer.
    % The allowed values in this field are:
    % 'concatenated', 'separately', 'custom'. 
    % 'separately', means apply the initX function to each
    % of the datasets and then concatenate. 'concatenated', means first concatenate
    % the datasets and then apply the 'initX' function. 'custom' is like the
    % "separately", but it implies that latentDimPerModel is a cell specifying
    % how many dimensions to use for each submodel.
    defaults.initial_X = 'concatenated';
    
    % !! The latent space dimensionality in case there are several
    % modalities arises as follows:
    % If initial_X is 'concatenated', then it is the corresponding Q
    % parameter set above. If it is 'separately', then the latent
    % dimensionality per model will be ceil(Q/num.Modalities).
    % 'custom' is not yet supported
    
    
    %{
        % In case initial_X is 'separately', this says how many dimensions to
        % set per modality. This can either be a cell array of length
        % H or a single entry replicated in all layers, or
        % it is disregarded if  initial_X is 'concatenated' (see below)
        defaults.latentDimPerModel = {8};
    
    
        % In case initial_X is 'concatenated', this says how many dimensions to
        % keep in total for layer h. This can either be a cell array of length
        % H or a single entry replicated in all layers, or
        % it is disregarded if  initial_X is 'separately' or 'custom' (see above)
        defaults.latentDim = 15;
    %}
    %-
    
    fnames = fieldnames(defaults);
    for i=1:length(fnames)
        if ~exist(fnames{i})
            globalOpt.(fnames{i}) = defaults.(fnames{i});
        else
            globalOpt.(fnames{i}) = eval(fnames{i});
        end
    end
    
    %----- Further interactions between fields ----------------
    % Some fields take their initial values after we decide on the model
    % structure, ie H and M.
    %
    % The default initVardistLayers is depending on the H, if given. If
    % explicitely a different initVardistLayers value is given, then use
    % that one.
    if exist('H') && ~exist('initVardistLayers') 
        globalOpt.initVardistLayers = 1:H;
    end  
    
    clear('defaults', 'fnames');
   
    % Check for inconsistencies
    if globalOpt.multOutput && ~strcmp(globalOpt.initial_X,'concatenated')
        warning('MultipleOutputs option is on but the initial latent space is not initialised with concatenation as recommended!')
    end
end