%{
clear; experimentNo=1; baseKern = 'rbfardjit'; initial_X = 'separately'; tic; demHsvargplvmHighFive1; toc
%}

% Fix seeds
randn('seed', 1e5);
rand('seed', 1e5);


if ~exist('experimentNo'), experimentNo = 404; end
if ~exist('baseKern'), baseKern = 'rbfardjit'; end %baseKern = {'linard2','white','bias'};
if ~exist('initial_X'), initial_X = 'separately'; end

dataSetName = 'highFive';


hsvargplvm_init;

% ------- LOAD DATASET
YA = vargplvmLoadData('hierarchical/demHighFiveHgplvm1',[],[],'YA');
YB = vargplvmLoadData('hierarchical/demHighFiveHgplvm1',[],[],'YB');



if globalOpt.multOutput
    mergeData = 'horConcat';
    %if ~exist('mergeData') || ~mergeData
    %    warning('Mult.Output selected but operating on separate datasets..!')
    %end
    if ~globalOpt.enableParallelism
        warning('Mult. Output option selected but without parallelism.!')
    end
    %------- REMOVE dims with very small var (then when sampling outputs, we
    % can replace these dimensions with the mean)
    vA = find(var(YA) < 1e-7);
    meanRedundantDimA = mean(YA(:, vA));
    dmsA = setdiff(1:size(YA,2), vA);
    YA = YA(:,dmsA);
    
    vB = find(var(YB) < 1e-7);
    meanRedundantDimB = mean(YB(:, vB));
    dmsB = setdiff(1:size(YB,2), vB);
    YB = YB(:,dmsB);
    %---
end

Yall{1} = YA; Yall{2} = YB;

if exist('mergeData')
    switch mergeData
        % Horizontally concatenated the two motions and present them as a
        % single dataset which will have multiple outputs
        case 'horConcat'
            Ynew = [Yall{1} Yall{2}];
            % Subsample
			if exist('subsample') && subsample
				 Ynew = Ynew(1:2:end,:); %%%%%%%%%%
			end
            clear Yall;
            for d=1:length(Ynew)
                Yall{d} = Ynew(:,d);
            end
    end
end

%%

options = hsvargplvmOptions(globalOpt);
options.optimiser = 'scg2';



%--- in case vargplvmEmbed is used for init,, the latent spaces...
optionsAll = hsvargplvmCreateOptions(Yall, options, globalOpt);
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


model = hsvargplvmModelCreate(Yall, options, globalOpt, initXOptions);


params = hsvargplvmExtractParam(model);
model = hsvargplvmExpandParam(model, params);
modelInit = model;

%%
model.globalOpt = globalOpt; 

[model, prunedModel, modelInitVardist] = hsvargplvmOptimiseModel(model, true, true);

% For more iters...
%modelOld = model;
%model = hsvargplvmOptimiseModel(model, true, true, [], {0, [1000]});


return
%%%%%%%%%%%%%%%%%%%%%%% VISUALISATION %%%%%%%%%%%%%%%%%%%%%%%%
% Now call:

%% %--- Scales
if globalOpt.multOutput
    close all
    SNR = hsvargplvmShowSNR(model,[],false);
    exclDim = find(SNR{1} < 6); % Exclude from the computations the dimensions that were learned with very low SNR
    [clu, clu2]= hsvargplvmClusterScales(model.layer{1}, 4,[],exclDim);
    scales = hsvargplvmRetainedScales(model);
    imagesc(clu(1:56)'); title('Scales model A')
    cl = caxis; 
    figure;
    imagesc(clu(57:end)'); caxis(cl); title('Scales model B')
    
    figure
    imagesc(clu2(1:56)'); cl = caxis; title('Bin. Scales model A')
    figure
    imagesc(clu2(57:end)');cl = caxis; title('Bin. Scales model B')
end

%% % --- Skeleton
%% 
% Now call:
%hsvargplvmShowSkel(model);

%hsvargplvmShowSkel2(model); %%% BETTER