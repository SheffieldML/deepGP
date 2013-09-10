function [Yall, dataSetNames, Z] = hsvargplvmCreateToyData2(toyType, N, D, numSharedDims, numHierDims, noiseLevel,hierSignalStrength)
% HSVARGPLVMCRETETOYDATA2 Create toy data for unsupervised learning
% DESC Create toy data for unsupervised learning.
% Give [] as an argument if the default value is to be
% used for the corresponding parameter.
%
% Note: This is like hsvargplvmCreateToyData.m but the noise and the
% mapping to higher dimensions is added in the end only once (same effect,
% simple code)
%
% COPYRIGHT: Andreas C. Damianou, 2013
%
% DEEPGP


% TODO: fix numSharedDims, numHierDims, numPrivSignalDims to add more than
% one dimension for each signal category.

% Fix seeds
randn('seed', 1e4);
rand('seed', 1e4);

if nargin < 7 || isempty(hierSignalStrength),     hierSignalStrength = 0.6;  end
if nargin < 6 || isempty(noiseLevel),             noiseLevel = 0.1;  end
% This cannot be controled in the current version
if nargin < 5 || isempty(numHierDims),            numHierDims = 1;   end
% This cannot be controled in the current version
if nargin < 4 || isempty(numSharedDims),          numSharedDims = 5; end
if nargin < 3 || isempty(D),                      D = 10;            end
if nargin < 2 || isempty(N),                      N = 100;           end
if nargin < 1 || isempty(toyType),                   toyType = 'fols';     end

alpha = linspace(0,4*pi,N);
privSignalInd = [1 2];
sharedSignalInd = 3;
hierSignalInd = 4;

%%
switch toyType
    case {'fgplvmTwoModels' ,'fgplvmTwoModels2','fgplvmTwoModels3'}
        if strcmp(toyType, 'fgplvmTwoModels')
            [YA,YB,XA,XB] = fgplvmSampleModels();
        elseif strcmp(toyType, 'fgplvmTwoModels2')
            [YA,YB,XA,XB] = fgplvmSampleModels2(false);
        elseif strcmp(toyType, 'fgplvmTwoModels3')
            [YA,YB,XA,XB] = fgplvmSampleModels3(false);
        end
        %Yall{1} = YA; Yall{2} = YB;% 
        Yall{1} = [YA YB];
        Z = {XA,XB};
        dataSetNames = toyType;
        return
    case {'hgplvmSample', 'hgplvmSample2', 'hgplvmSample3', 'hgplvmSampleTr1', 'hgplvmSampleTr2'}
        if strcmp(toyType, 'hgplvmSample')
            load 'hgplvmSampleData.mat';
        elseif strcmp(toyType, 'hgplvmSample2')
            load 'hgplvmSampleData2.mat';
        elseif strcmp(toyType, 'hgplvmSample3')
            load 'hgplvmSampleData3.mat'; %%%NOT A GOOD DATASET
        elseif strcmp(toyType, 'hgplvmSampleTr1')
            load 'hgplvmSampleDataTr1.mat';
        elseif strcmp(toyType, 'hgplvmSampleTr2')
            load 'hgplvmSampleDataTr2.mat';
        end
        Yall{1} = YA; Yall{2} = YB;
        %{
        subplot(3,2,1)
        myPlot(X2,'X2',[],[],{3,8},0
        subplot(3,2,3)
        myPlot(XA,'XA',[],[],{3,8},0
        subplot(3,2,4)
        myPlot(XB,'XB',[],[],{3,8},0
        subplot(3,2,5)
        plot(YA,'x-'); title('YA');
        subplot(3,2,6)
        plot(YB,'x-'); title('YB');
        %}
        Z = {XA,XB,X2};
        dataSetNames = toyType;
        %{
        figure
        pcaXA = ppcaEmbed(YA, 2);
        pcaXB = ppcaEmbed(YB,2);
        pcaX2 = ppcaEmbed([pcaXA pcaXB],2); %%%%% Used to be: [XA XB]
        subplot(2,2,1)
        plot(pcaX2(:,1), pcaX2(:,2), 'x-'); title('pcaX2');
        subplot(2,2,3)
        plot(pcaXA(:,1), pcaXA(:,2), 'x-'); title('pcaXA');
        subplot(2,2,4)
        plot(pcaXB(:,1), pcaXB(:,2), 'x-'); title('pcaXB');
        
        figure
        isomapXA = isomap2Embed(YA, 2);
        isomapXB = isomap2Embed(YB,2);
        isomapX2 = isomap2Embed([isomapXA isomapXB],2); %%%%% Used to be: [XA XB]
        subplot(2,2,1)
        plot(isomapX2(:,1), isomapX2(:,2), 'x-'); title('isomapX2');
        subplot(2,2,3)
        plot(isomapXA(:,1),isomapXA(:,2), 'x-'); title('isomapXA');
        subplot(2,2,4)
        plot(isomapXB(:,1), isomapXB(:,2), 'x-'); title('isomapXB');
        %}
        return
    case {'hgplvmSampleShared','hgplvmSampleShared2','hgplvmSampleShared3'}
        if strcmp(toyType, 'hgplvmSample')
            load 'hgplvmSampleDataShared.mat';
        elseif strcmp(toyType, 'hgplvmSampleShared2')
            load 'hgplvmSampleShared2.mat';
        elseif strcmp(toyType, 'hgplvmSampleShared3')
            load 'hgplvmSampleShared3.mat';
        end
        Yall{1} = [YA YC]; Yall{2} = [YB YC];
        Z = {XA,XB,XC,X2};
        dataSetNames = 'hgplvmSampleShared';
        %{
subplot(3,3,2)
plot(X2(:,1),'x-'); title('X2')
subplot(3,3,4)
plot(XA(:,1)); title('XA')
subplot(3,3,5)
plot(XB(:,1)); title('XB')
subplot(3,3,6)
plot(XC(:,1)); title('XC')
subplot(3,3,7)
plot(Yall{1},'x-'); title('Yall1');
subplot(3,3,8)
plot(Yall{2},'x-'); title('Yall2');

 
figure
pcaXA = ppcaEmbed(Yall{1}, 3);
pcaXB = ppcaEmbed(Yall{2},3);
pcaX2 = ppcaEmbed([pcaXA pcaXB],1); %%%%%%%%%%% USED TO BE ppcaEmbed(X1,2)
subplot(1,3,1)
plot(pcaX2(:,1), 'x-'); title('pcaX2');
subplot(1,3,2)
plot(pcaXA(:,1), pcaXA(:,2), 'x-'); title('pcaXA');
subplot(1,3,3)
plot(pcaXB(:,1), pcaXB(:,2), 'x-'); title('pcaXB');

figure
isomapXA = isomap2Embed(Yall{1}, 3);
isomapXB = isomap2Embed(Yall{2}, 3);
isomapX2 = isomap2Embed([isomapXA isomapXB],1);
subplot(1,3,1)
plot(isomapX2(:,1), 'x-'); title('isomapX2');
subplot(1,3,2)
plot(isomapXA(:,1), isomapXA(:,2), 'x-'); title('isomapXA');
subplot(1,3,3)
plot(isomapXB(:,1), isomapXB(:,2), 'x-'); title('isomapXB');
        %}
        return
    case 'clusters'
        addpath('../../../other/dimRed/');
        randn('seed', 1e5);
        rand('seed', 1e5);
        pom = [25]; % points per mixture
        ppm = [pom pom pom pom];
        centers = [10 10;
            10 15;
            8 13;
            12 13];
        stdev = [0.001 1];
        [data1,labels1]=makegaussmixnd(centers,stdev,ppm);
        stdev = [1 0.001];
        [data2,labels2]=makegaussmixnd(centers,stdev,ppm);
        N = size(data1,1);
        dataNew = data1(1:N/2,:);
        labelsNew = labels1(1:N/2);
        dataNew = [dataNew; data2(N/2+1:end,:)];
        labelsNew = [labelsNew  labels2(N/2+1:end)];
        X1 = dataNew(1:N/2,:);
        X2 = dataNew(N/2+1:end,:);
        %{
% Rotation
theta = pi;
rotMapping = [cos(theta) -sin(theta); sin(theta) cos(theta)];
X1 = X1;
X2 = X2 * rotMapping;
% Translation both directions
X2 = X2 + 15*ones(size(X2));
X1 = X1 - 10*ones(size(X1));
% Translation x-axis
X2 = X2 - 5.*repmat([1 0], size(X2,1), 1);
        %}
        data = [X1; X2];
        data = data * rand(2,3)*10;
        data = data + 2 .* randn(size(data));
        data = scaleData(data);
        pcaX = pcaEmbed(data,2);
        
        isomapX = isomapEmbed2(data,2); close;
        subplot(1,3,1);
        plotcol(data, ppm, 'rgbk'); title('original');
        subplot(1,3,2);
        plotcol(pcaX, ppm ,'rgbk'); title('pca')
        subplot(1,3,3);
        plotcol(isomapX, ppm, 'rgbk'); title('isomap');
        Yall{1} = data;
        Z = {X1,X2};
        dataSetNames = 'clusters';
        return
        %%
    case 'fols3'
        %%
        dataSetNames={'fols3'};
        H = sin(alpha)'; % HIERARCHICAL SIGNAL
        XA = scaleData(sin(H).^3, true);
        XB = scaleData(H.^2-H, true);
        
        %bar(pca([XA XB H])); --> 2 scales
        Xshared = scaleData(cos(2*alpha)', true);
        X1 = [XA Xshared];
        X2 = [XB Xshared];
        % bar(pca([X1 X2])); % 3 scales. Hope that the hier. model will discover the fourth commonality in the higher level
        Yall{1} = X1 * rand(2,D);
        Yall{1}= Yall{1} + noiseLevel.*randn(size(Yall{1}));
        Yall{2} = X2 * rand(2,D);
        Yall{2} = Yall{2} + noiseLevel.*randn(size(Yall{2}));
        bar(pca([Yall{1} Yall{2}])); % 3 scales
        Z = {XA,XB,Xshared,H};
        %%
        return
    case 'fols2'
        %%
        dataSetNames={'fols2'};
        % H = [sin(alpha)', cos(alpha)']; % HIERARCHICAL SIGNAL (circle)
        Q2 = 1;
        H = sin(alpha)'; % N x Q2
        XA = 3*H + H.*linspace(-10, 10, size(H,1))'; % maybe omit H.*
        XB = -10*H - H.*linspace(-10,10,size(H,1))';
        %bar(pca([XA XB H])); --> 2 scales
        Xshared = scaleData(cos(2*alpha)'.*10);
        X1 = [XA Xshared];
        X2 = [XB Xshared];
        % bar(pca([X1 X2])); % 3 scales. Hope that the hier. model will discover the fourth commonality in the higher level
        Yall{1} = X1 * rand(2,D);
        Yall{1}= Yall{1} + noiseLevel.*randn(size(Yall{1}));
        Yall{2} = X2 * rand(2,D);
        Yall{2} = Yall{2} + noiseLevel.*randn(size(Yall{2}));
        bar(pca([Yall{1} Yall{2}])); % 3 scales
        Z = {XA,XB,Xshared,H};
        %%
        return
    case 'fols'
        dataSetNames={'fols_cos', 'fols_sin'};
        % private signals
        Z{1} = cos(alpha)';
        Z{2} = sin(alpha)';
        % Shared signal
        Z{3}= (cos(alpha)').^2;
        % Hierarchical signal
        Z{4} = heaviside(linspace(-10,10,N))'; % Step function
        % Z{3} = heaviside(Z{3}); % This turns the signal into a step function
        % Z{3} = 2*cos(2*alpha)' + 2*sin(2*alpha)' ; %
        
    case 'gps'
        dataSetNames={'gp_periodic', 'gp_matern32'};
        kern1 = kernCreate(alpha', 'rbfperiodic');
        K1 = kernCompute(kern1, alpha');
        Z{1} = gsamp(zeros(1, size(K1, 1)), K1, 1)';
        kern2 = kernCreate(alpha', 'matern32');
        K2 = kernCompute(kern2, alpha');
        Z{2} = gsamp(zeros(1, size(K2,1)), K2, 1)';
        % Shared signal
        Z{3}= (cos(alpha)').^2;
        % Hierarchical signal
        %Z{4} = heaviside(linspace(-10,10,N))'; % Step function      
        Z{4} = 0.2*(linspace(-10,10,N).^2)'; % Wide parabola  
end

% Scale and center data
for i=1:length(Z)
    bias_Z{i} = mean(Z{i});
    Z{i} = Z{i} - repmat(bias_Z{i},size(Z{i},1),1);
    scale_Z{i} = max(max(abs(Z{i})));
    Z{i} = Z{i} ./scale_Z{i};
end

% Attach the shared to the private signal after mapping to higher
% dimentions
if numSharedDims == 0 %% TEMP (hack)
    Z{sharedSignalInd} = [];
    for i=privSignalInd
        Zp{i} = [Z{i}*rand(1,ceil(D/2))];
    end
else
    for i=privSignalInd
        Zp{i} = [Z{i}*rand(1,ceil(D/2)) Z{sharedSignalInd}*rand(1,ceil(D/2))];
    end
end

% Map hier. signal to higher dimensions as well
Zp{hierSignalInd} = Z{hierSignalInd}*rand(1, size(Zp{privSignalInd(1)},2));

% Apply hier. signal and then apply noise.
for i=privSignalInd
    Zpp{i} = Zp{i} + hierSignalStrength.*Zp{hierSignalInd}; %
    Yall{i} = Zpp{i} + noiseLevel.*randn(size(Zpp{i})); % Add noise
end

% How many signals are there in the whole dataset?

bar(pca([Yall{1} Yall{2}]))
%---

for i=privSignalInd
    figure
    title(['model ' num2str(i)])
    subplot(2,1,1)
    plot(Z{i}), hold on
    plot(Z{sharedSignalInd}, 'r')
    plot(pcaEmbed(Yall{i},1), 'm')
    legend('Orig.','Shared','Final(PCA)')
    subplot(2,1,2)
    plot(Z{hierSignalInd});
    legend('Hier.')
end
end

%{
%This should return the original signals (in case there is no
%hierarchical signal)
[Yall, dataSetNames, Z] = hsvargplvmCreateToyData([],[],[],[],[],[],0);
close all;plot(pcaEmbed(Yall{1},2))
close all;plot(pcaEmbed(Yall{2},2))
%}

%%
%{
for i=length(privSignalInd)
    ZZ{i} = [Z{privSignalInd(i)} Z{sharedSignalInd}]+repmat(Z{hierSignalInd},1,size([Z{privSignalInd(i)} Z{sharedSignalInd}],2)).*0.6;
end
%}
%%