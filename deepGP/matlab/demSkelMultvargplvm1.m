%{

 % Demo to try a second layer on an already trained model
 demoType = 'trainedX';
 dataOptions.prevModel = 'mats/demDecomposeSkel2.mat';
 latentDim = 8;
 initVardistIters = 500;
 itNo = [1000 2000];
%}


if exist('diaryFile'),  diary(diaryFile);  end
if ~exist('saveModel'), saveModel = false; end
%if ~exist('experimentNo'), experimentNo = 404; end

% Fix seeds
randn('seed', 1e5);
rand('seed', 1e5);

multvargplvm_init; % hsvargplvm_init;



%---- LOAD DATA
if ~exist('Y')
    [Y,lbls] = multvargplvmPrepareData(globalOpt.demoType, globalOpt.dataOptions);
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

if globalOpt.enableParallelism
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

if saveModel
    prunedModel = svargplvmPruneModel(model);
    vargplvmWriteResult(prunedModel);
end

return 

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
%htree = linkage(allScalesMat,'single');
%clu = cluster(htree, 12);
clu = kmeans(allScalesMat,10);
imagesc(clu')


%{
for i=1:model.numModels
    bar(allScales{i})
    title(num2str(i))
    pause
end
%}


%%
hsvargplvmAnalyseResults;


