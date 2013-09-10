% Here, a single layer is passed as a model
function [clu, clu2, clu3] = hsvargplvmClusterScales(model, noClusters, labelType, exclDims)

if nargin < 4
    exclDims = [];
end

if nargin < 3
    labelType = [];
end

if nargin < 2 || isempty(noClusters), noClusters = 2; end

% for compatibility with svargplvm
if ~isfield(model, 'type')  || ~strcmp(model.type, 'svargplvm')
    model.numModels = model.M;
end

allScales = svargplvmScales('get',model);
%  thresh = max(model.comp{obsMod}.kern.comp{1}.inputScales) * 0.001;
thresh = 0.01; % 0.005
binaryScales = zeros(model.numModels, model.q);
allScalesMat = zeros(model.numModels, model.q);
allScalesMat2 = zeros(model.numModels, model.q);
for i=1:model.numModels
    % Normalise values between 0 and 1
    allScales{i} = allScales{i} / max(allScales{i});
    retainedScales{i} = find(allScales{i} > thresh);
    allScalesMat(i,:) = allScales{i};
    allScalesMat2(i,:) = allScalesMat(i,:);
    allScalesMat2(i, retainedScales{i}) = 0; %%% Scales too smal are set to 0 for better clustering
    binaryScales(i,retainedScales{i}) = 1;
end
% sharedDims = intersect(retainedScales{obsMod}, retainedScales{infMod});
%imagesc(binaryScales')
%htree = linkage(allScalesMat,'single');
%clu = cluster(htree, 12);
clu = kmeans(allScalesMat,noClusters, 'emptyact', 'drop','distance','sqeuclidean');
clu(exclDims) = 0; %%% These submodels are excluded, taken the value 0 which, therefore, constitutes a new cluster marking irrelevant dims.
clu3 = kmeans(allScalesMat2,noClusters, 'emptyact', 'drop','distance','sqeuclidean');
clu3(exclDims) = 0; %%% These submodels are excluded, taken the value 0 which, therefore, constitutes a new cluster marking irrelevant dims.
clu2 = kmeans(binaryScales, noClusters,  'emptyact', 'drop','distance','sqeuclidean');
clu2(exclDims) = 0; %%% These submodels are excluded, taken the value 0 which, therefore, constitutes a new cluster marking irrelevant dims.
%%
scrsz = get(0,'ScreenSize');
figure('Position',[scrsz(3)/4.86 scrsz(4)/1 1.2*scrsz(3)/1.6457 0.6*scrsz(4)/3.4682])

imagesc(clu'); title('Clustering scales')
cl = caxis; 
if ~isempty(labelType) && strcmp(labelType,'skel59dim')
    Xt = [1 8 15 24 33 42 51 53 54 55 56 57 58]; 
    Xl = [0 60]; %[1 59]; % limit
    myLbls = {'Lleg';'Rleg';'Torso';'Head';'Lhand';'Rhand';'Nothing?';'MoveInY';'MoveInX';'MoveInZ';'Rotation?';'UpsDown?';'Nothing?' };
    textAxes(Xt, Xl, myLbls);
end
figure('Position',[scrsz(3)/4.86 scrsz(4)/3 1.2*scrsz(3)/1.6457 0.6*scrsz(4)/3.4682])
imagesc(clu3'); title('Clustering scales2'); caxis(cl);
if ~isempty(labelType) && strcmp(labelType,'skel59dim')
    Xt = [1 8 15 24 33 42 51 53 54 55 56 57 58]; 
    Xl = [0 60]; %[1 59]; % limit
    myLbls = {'Lleg';'Rleg';'Torso';'Head';'Lhand';'Rhand';'Nothing?';'MoveInY';'MoveInX';'MoveInZ';'Rotation?';'UpsDown?';'Nothing?' };
    textAxes(Xt, Xl, myLbls);
end
figure('Position',[scrsz(3)/4.86 scrsz(4)/10 1.2*scrsz(3)/1.6457 0.6*scrsz(4)/3.4682])
imagesc(clu2'); title('Clustering binary scales'); caxis(cl);
if ~isempty(labelType) && strcmp(labelType,'skel59dim') 
    textAxes(Xt, Xl, myLbls);
end

%{
for i=1:model.numModels
    bar(allScales{i})
    title(num2str(i))
    pause
end
%}


function textAxes(Xt, Xl, myLbls)
    pos = get(gca,'Position');
    set(gca,'Position',[pos(1), .2, pos(3) .65])

    set(gca,'XTick',Xt,'XLim',Xl);
    set(gca,'XGrid','on')
  
    ax = axis; % Current axis limits
    axis(axis); % Set the axis limit modes (e.g. XLimMode) to manual
    Yl = ax(3:4); % Y-axis limits
    
    % Place the text labels
    t = text(Xt,Yl(1)*ones(1,length(Xt)),myLbls);
    % Due to rotation, hor. alignment is actually vertical and vice versa
    set(t,'HorizontalAlignment','right','VerticalAlignment','top', ... % v.alignment: also: middle
    'Rotation',90, 'Color', 'w','FontWeight', 'bold');

    %set(gca,'XTickLabel','')     % Remove the default labels
 
