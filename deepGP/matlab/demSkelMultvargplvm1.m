%{

 % Demo to try a second layer on an already trained model
 demoType = 'trainedX';
 dataOptions.prevModel = 'mats/demDecomposeSkel2.mat';
 latentDim = 8;
 initVardistIters = 500;
 itNo = [1000 2000];

 %%
 ca;clear;dataOptions={120,3,[]};indPoints=40;experimentNo=20;enableParallelism=1; demSkelMultvargplvm1
 % .mat save on folder demonstr
% TO load:
 ca;clear;dataOptions={120,3,[]};indPoints=40;experimentNo=20;trainModel=0; demSkelMultvargplvm1

%}

if ~exist('trainModel', 'var'), trainModel = true; end
if ~exist('demoType', 'var'), demoType = 'skelDecomposeAnkur'; end
if ~exist('dataOptions','var'), dataOptions = {}; end
if exist('diaryFile','var'),  diary(diaryFile);  end
if ~exist('saveModel','var'), saveModel = false; end
%if ~exist('experimentNo'), experimentNo = 404; end

% Fix seeds
randn('seed', 1e5);
rand('seed', 1e5);

%multvargplvm_init;
hsvargplvm_init;
globalOpt.dataSetName = 'skelDecompose';
globalOpt.demoType = demoType;
globalOpt.dataOptions = dataOptions;

%---- LOAD DATA
if ~exist('Y')
    [Y,lbls,padding,Z] = multvargplvmPrepareData(globalOpt.demoType, globalOpt.dataOptions);
end

for i=1:size(Y,2)
    Yall{i} = Y(:,i);
end

%-- Set up model
numberOfDatasets = length(Yall);
globalOpt.indPoints = min(globalOpt.indPoints, size(Yall{1},1));

%-- Load datasets
for i=1:numberOfDatasets
    Y = Yall{i};
    N{i} = size(Y,1);
    indTr = globalOpt.indTr;
    if indTr == -1
        indTr = 1:N{i};
    end
    if ~exist('Yts')
        indTs = setdiff(1:size(Y,1), indTr);
        Yts{i} = Y(indTs,:);
    end
    Ytr{i} = Y(indTr,:);
    
    t{i} = linspace(0, 2*pi, size(Y, 1)+1)'; t{i} = t{i}(1:end-1, 1);
    timeStampsTraining{i} = t{i}(indTr,1); %timeStampsTest = t(indTs,1);
end

for i=2:numberOfDatasets
    if N{i} ~= N{i-1}
        error('The number of observations in each dataset must be the same!');
    end
end

clear('Y','N')

%%

if trainModel
    options = svargplvmOptions(Ytr, globalOpt);
    
    if ~isempty(globalOpt.dynamicsConstrainType)
        for i=1:numberOfDatasets
            % Set up dynamcis (i.e. back-constraints) model
            optionsDyn{i}.type = 'vargpTime';
            optionsDyn{i}.inverseWidth=30;
            %   optionsDyn.vardistCovars = vardistCovarsMult;
            optionsDyn{i}.initX = globalOpt.initX;
            optionsDyn{i}.constrainType = globalOpt.dynamicsConstrainType;
            
            if exist('timeStampsTraining')
                optionsDyn{i}.t = timeStampsTraining;
            end
            if exist('labelsTrain') && ~isempty(labelsTrain)
                optionsDyn{i}.labels = labelsTrain;
            end
        end
    else
        optionsDyn= [];
    end
    
    
    model = multvargplvmCreate(Ytr, globalOpt, options, optionsDyn);
    if exist('diaryFile')
        model.diaryFile = diaryFile;
    end
    
    if globalOpt.enableParallelism % around 3x faster
        fprintf('# Parallel computations w.r.t the submodels!\n');
        model.parallel = 1;
        model = svargplvmPropagateField(model,'parallel', 1);
    end
    
    model.globalOpt = globalOpt;
    model.options = options;
    
    %%%% TEMP
    if exist('whiteVar')
        model.dynamics.kern.comp{2}.variance = whiteVar;
    end
    %%%%
    
    %model = svargplvmPropagateField(model, 'learnSigmaf',1);%%%%%
    % Force kernel computations
    params = svargplvmExtractParam(model);
    model = svargplvmExpandParam(model, params);
    
    
    if ~isfield(globalOpt, 'saveName') || isempty(globalOpt.saveName)
        globalOpt.saveName = vargplvmWriteResult([], 'multVargplvm', '', globalOpt.experimentNo);
    end
    model.saveName = globalOpt.saveName;
    
    
    %%
    %fprintf('# Median of vardist. covars: %d \n',median(median(model.vardist.covars)));
    %fprintf('# Min of vardist. covars: %d \n',min(min(model.vardist.covars)));
    %fprintf('# Max of vardist. covars: %d \n',max(max(model.vardist.covars)));
    tic
    if globalOpt.displayIters
        if strcmp(globalOpt.saveName, 'noSave')
            model = svargplvmOptimiseModel(model, true, false); % don't save the model
        else
            model = svargplvmOptimiseModel(model);
        end
    else
        if strcmp(globalOpt.saveName, 'noSave')
            model = svargplvmOptimiseModelNoDisplay(model,true,false); % don't save the model
        else
            model = svargplvmOptimiseModelNoDisplay(model);
        end
    end
    toc
    if saveModel
        prunedModel = svargplvmPruneModel(model);
        vargplvmWriteResult(prunedModel);
    end
else
    load(vargplvmWriteResult([], 'multVargplvm', '', globalOpt.experimentNo));
    model = svargplvmRestorePrunedModel(model, Ytr);
end


%%
allScales = svargplvmScales('get',model);
%  thresh = max(model.comp{obsMod}.kern.comp{1}.inputScales) * 0.001;
thresh = 0.005;
binaryScales = zeros(model.numModels, model.q);
allScalesMat = zeros(model.numModels, model.q);
for i=1:model.numModels
    % Normalise values between 0 and 1
    allScales{i} = allScales{i} / max(allScales{i});
    retainedScales{i} = find(allScales{i} > thresh);
    allScalesMat(i,:) = allScales{i};
    binaryScales(i,retainedScales{i}) = 1;
end
% sharedDims = intersect(retainedScales{obsMod}, retainedScales{infMod});
%imagesc(binaryScales')
%htree = linkage(pdist(allScalesMat),'single');
%clu = cluster(htree, 12);

if ~exist('showResults','var'), showResults = 0; end

if ~showResults
    return
end


%%
if strcmp(globalOpt.demoType, 'skelDecomposeAnkur')
    visPoint = Z(1,:);
    % Move some joints a bit further apart for clearer plots
    visPoint([16 19])=visPoint([16 19])-2.5; % Right Shoulders and arms (further from center)
    visPoint([25])=visPoint([25])+2; % right hand (closer to center)
    visPoint([28 31 34 37])=visPoint([28 31 34 37])+3; % Left shoulders and arms (further from center)
    visPoint([61])=visPoint([61])+7; % Left toe away from center
    visPoint([52])=visPoint([52])+2; % Left knee away from center
    visPoint([43])=visPoint([43])-2; % Right ankle away from center
    visPoint([55])=visPoint([55])+4; % Left ankle away from center
    visPoint([46])=visPoint([46])-1.5; % Right ankle away from center
    visPoint([58])=visPoint([58])-8; % Right toe away from center
    visPoint([59])=visPoint([59])-1.5; % Right toe a bit up
    visPoint([56 62])=visPoint([56 62])-1.5; % Left ankle toe a bit up
    visPoint([11 14])=visPoint([11 14])-[1 2.5]; % Neck/Head a bit up
    
    %%
    fprintf(1',['\n\n',...
        '#  Clustering each of the 57 dimensions separately. \n',...
        '   Each color represents if the dimension corresponds to moving along the (x,y,z) axis\n',...
        '   and each symbol corresponds to a cluster id\']);
    ca
    K = 5;
    randn('seed', 10); rand('seed', 10);
    
    distMeasure = 'cityblock'; % sqEuclidean, cityblock, cosine, correlation
    [clu,centroids] = kmeans_matlab(allScalesMat,K, 'EmptyAction', 'singleton','Start','sample','MaxIter',500,'Distance',distMeasure);
    
    %htree = linkage(pdist(allScalesMat),'single');
    %clu = cluster(htree, K);
    
    imagesc(clu')
    
    for cc = 1:length(unique(clu))
        fprintf('Cluster %d: ',cc);
        % Add + 6, because the first 6 points are all not included in tr.
        % set (since they have variance 0, and also this means they get
        % allocated to their own cluster)
        fprintf('%d ',find(clu==cc)+6)
        fprintf('\n');
    end
    fprintf('\n');
    allSymb = getSymbols(K+1);
    % Create the set of symbols to be for a "Default" cluster, that has the
    % lower spine points that in the dataset are centerd and therefore have
    % variance 0 (ie they 're all the same)
    symb = {allSymb{end},allSymb{end},allSymb{end},allSymb{end},allSymb{end},allSymb{end}};
    for i=1:57
        symb{end+1} = allSymb{clu(i)};
    end
    handle = xyzankurVisualise(visPoint,1);view([90,0])
    xyzankurDrawColor(xyzankur2joint(visPoint), handle,symb,visPoint);
    fprintf('# Press any key to continue');    pause
    %%
    fprintf(1','\n\n# As above but scales are binarized first (ie to 0-1)');
    K=5;
    randn('seed', 10); rand('seed', 10);
    clu = kmeans_matlab(binaryScales,K, 'EmptyAction', 'singleton','Start','sample','MaxIter',500, 'Distance', 'Hamming');
    imagesc(clu')
    
    for cc = 1:length(unique(clu))
        fprintf('Cluster %d: ',cc);
        fprintf('%d ',find(clu==cc)+6)
        fprintf('\n');
    end
    fprintf('\n');
    
    allSymb = getSymbols(K+1);
    symb = {allSymb{end},allSymb{end},allSymb{end},allSymb{end},allSymb{end},allSymb{end}};
    for i=1:57
        symb{end+1} = allSymb{clu(i)};
    end
    
    handle = xyzankurVisualise(visPoint,1);view([90,0])
    xyzankurDrawColor(xyzankur2joint(visPoint), handle,symb,visPoint);
    fprintf('# Press any key to continue');    pause
    
    %% Do the same, but "merge" scales for x-y-z locations, ie dimension
    %% k,k+1 and k+2 correspond to the xyz loc. of joing k
    fprintf(1',['\n\n',...
        '#  Clustering each SET of dimensions, 1:3, 4:6, etc, \n',...
        '   ie grouping them by joint for all degrees of freedom (x,y,z). \n',...
        '   Each cluster id is represented with a separate combination of color/symbol\n']);
    allScalesMat_xyz=[];
    for i=1:3:length(allScales)
        allScalesMat_xyz = [allScalesMat_xyz; [allScales{i} allScales{i+1} allScales{i+2}]];
    end
    %%
    for kk=2:9
        K = kk; % Check K=5, randSeed=10,distMeasure='correlation', start='sample'
        ca
        randn('seed', 10); rand('seed', 10);
        
        distMeasure = 'sqEuclidean'; % sqEuclidean, cityblock, cosine, correlation
        [clu,centroids] = kmeans_matlab(allScalesMat_xyz,K, 'EmptyAction', 'singleton','Start','sample','MaxIter',500,'Distance',distMeasure);
        %imagesc(clu')
        for cc = 1:length(unique(clu))
            fprintf('Cluster %d: ',cc);
            fprintf('%d ',find(clu==cc)+6)
            fprintf('\n');
        end
        fprintf('\n');
        allSymb = getSymbols(K+1);
        if length(allSymb) > 2, allSymb{3}(1)='k'; end
        if length(allSymb) > 5, allSymb{6}(1)='b'; end
        % Create the set of symbols to be for a "Default" cluster, that has the
        % lower spine points that in the dataset are centerd and therefore have
        % variance 0 (ie they 're all the same)
        symb = {allSymb{end},allSymb{end}};
        for i=1:size(clu,1)
            symb{end+1} = allSymb{clu(i)};
        end
        handle = xyzankurVisualise(visPoint,1);view([90,0]); axis off;
        xyzankurDrawColor(xyzankur2joint(visPoint), handle,symb,visPoint,true);
        pause
    end
    fprintf('# Press any key to continue');    pause
%%  In the outputs directly   
    fprintf(1, ['\n\n# As above but cluster directly the outputs (after grouping by 3\n',...
                    '  i.e. [Y(:, 1:3), Y(:,4:6) ] etc.\n']);
    zz=[];
    for i=1:3:length(allScales)
        zz = [zz; [Z(:,i) Z(:,i+1) Z(:,i+2)]];
    end
    for kk=2:9
        K = kk; % Check K=5, randSeed=10,distMeasure='correlation', start='sample'
        ca
        randn('seed', 10); rand('seed', 10);
        
        distMeasure = 'correlation'; % sqEuclidean, cityblock, cosine, correlation
        [clu,centroids] = kmeans_matlab(allScalesMat_xyz,K, 'EmptyAction', 'singleton','Start','sample','MaxIter',500,'Distance',distMeasure);
        %imagesc(clu')
        for cc = 1:length(unique(clu))
            fprintf('Cluster %d: ',cc);
            fprintf('%d ',find(clu==cc)+6)
            fprintf('\n');
        end
        fprintf('\n');
        allSymb = getSymbols(K+1);
        if length(allSymb) > 2, allSymb{3}(1)='k'; end
        if length(allSymb) > 5, allSymb{6}(1)='b'; end
        % Create the set of symbols to be for a "Default" cluster, that has the
        % lower spine points that in the dataset are centerd and therefore have
        % variance 0 (ie they 're all the same)
        symb = {allSymb{end},allSymb{end}};
        for i=1:size(clu,1)
            symb{end+1} = allSymb{clu(i)};
        end
        handle = xyzankurVisualise(visPoint,1);view([90,0]); axis off;
        xyzankurDrawColor(xyzankur2joint(visPoint), handle,symb,visPoint,true);
        pause
    end
    %% What is each dim. doing? 1-6 are fixed (padding) - Only for globalOpt.demoType = skelDecomposeAnkur
    %{
mlt = ones(1,size(Z,2)).*1.4;
mlt(8)=8;
for dd=8:size(Z,2)
    pause
    dmin = min(Z(:,dd));
    dmax = max(Z(:,dd));
    r = abs(dmax-dmin);
    Ytmp = repmat(Z(102,:), 40,1);
    Ytmp(:,dd) = linspace(dmin-mlt(dd)*abs(r), dmax+mlt(dd)*abs(r), size(Ytmp,1))';
    clf
    grid on
    xyzankurAnim(Ytmp, 4,[' Dim: ' num2str(dd)]);
end
    %}
    %%
else
    hsvargplvmAnalyseResults;
end

