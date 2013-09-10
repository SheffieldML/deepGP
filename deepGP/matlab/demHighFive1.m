
% DEMHIGHFIVE1 Demonstration of hierarchical GP-LVM on walking and running data.
%
%	Description:
%

%	Copyright (c) 2007 Neil D. Lawrence
% 	demHighFive1.m version 1.1

if exist('diaryFile')
    diary(diaryFile)
end

% Fix seeds
randn('seed', 1e5);
rand('seed', 1e5);

hsvargplvm_init;



dataSetName = 'highFive';
capName = dataSetName;
capName(1) = upper(capName(1));
experimentNo = 1;
dirSep = filesep;
baseDir = datasetsDirectory;


%--- Load data
try
    load([baseDir 'dem' dataSetName]);
catch
    [void, errid] = lasterr;
    if strcmp(errid, 'MATLAB:load:couldNotReadFile');
        skelA = acclaimReadSkel([baseDir 'mocap' dirSep 'cmu' dirSep '20' dirSep '20.asf']);
        [YA, skelA] = acclaimLoadChannels([baseDir 'mocap' dirSep 'cmu' dirSep '20' dirSep '20_11.amc'], skelA);
        seqInd = [50:4:113 114:155 156:4:size(YA, 1)];
        YA = YA(seqInd, :);
        %    YA(:, [4:end]) = asind(sind(YA(:, [4:end])));
        skelB = acclaimReadSkel([baseDir 'mocap' dirSep 'cmu' dirSep '21' dirSep '21.asf']);
        [YB, skelB] = acclaimLoadChannels([baseDir 'mocap' dirSep 'cmu' dirSep '21' dirSep '21_11.amc'], skelB);
        YB = YB(seqInd, :);
        %    YB(:, [4:end]) = asind(sind(YB(:, [4:end])));
        save([baseDir 'dem' dataSetName], 'YA', 'YB', 'skelA', 'skelB', ...
            'seqInd');
    else
        error(lasterr);
    end
end

Yall{1} = YA;
Yall{2} = YB;
clear('YA','YB');

%-- Set up model
numberOfDatasets = length(Yall);
globalOpt.indPoints = min(globalOpt.indPoints, size(Yall{1},1));

%-- Load datasets
for i=1:numberOfDatasets
    Y = Yall{i};
    dims{i} = size(Y,2);
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



clear('Y')


%%--- Optimise %%--------- TO FIX (from this point and below) (this is now taken from svargplvm)
options = svargplvmOptions(Ytr, globalOpt, labelsTrain);



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




model = svargplvmModelCreate(Ytr, globalOpt, options, optionsDyn);
if exist('diaryFile')
    model.diaryFile = diaryFile;
end

model.globalOpt = globalOpt;
model.options = options;

%%%% TEMP
if exist('whiteVar')
    model.dynamics.kern.comp{2}.variance = whiteVar;
end
%%%%

% Force kernel computations
params = svargplvmExtractParam(model);
model = svargplvmExpandParam(model, params);

%%
%fprintf('# Median of vardist. covars: %d \n',median(median(model.vardist.covars)));
%fprintf('# Min of vardist. covars: %d \n',min(min(model.vardist.covars)));
%fprintf('# Max of vardist. covars: %d \n',max(max(model.vardist.covars)));

if displayIters
    model = svargplvmOptimiseModel(model);
else
    model = svargplvmOptimiseModelNoDisplay(model);
end

%--------




%%
colordef white
ax = hgplvmHierarchicalVisualise(model, visualiseNodes, [], [0.03 ...
    0.5 0.03 0.03])
tar = get(ax, 'cameratarget');
pos = get(ax, 'cameraposition');
newPos = tar + (rotationMatrix(0, -pi/8, 3*pi/2)*(pos - tar)')';
set(ax, 'cameraposition', newPos)
set(ax, 'xlim', [-20 25]);
set(ax, 'ylim', [-15 8])
set(ax, 'visible', 'off')



