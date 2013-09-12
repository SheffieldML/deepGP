% DEMTOYUNSUPERVISED A script to run unsupervised deep GP on toy hierarchical data.
%
% DESC A script to run unsupervised deep GP on toy hierarchical data. The script provides
% the option of parametrising the model and initialisation in many many
% different ways... but the core of the demo (define a deep GP and train
% it) is actually not that big, if you decide to use the default options.
%
% COPYRIGHT: Andreas C. Damianou, 2013
%
% SEE ALSO: demToyRegression.m
%
% DEEPGP


experimentNo = 1;
toyType = 'hgplvmSampleTr1';
baseKern='rbfardjit'; % The mapping kernel between the layers
Q = {6,4}; % Dimensionality of the latent space in each layer
initSNR = {100, 50}; % Initial Signal to Noise ration per layer
% How to initialise X when multiple output modalities are present. See
% hsvargplvm_init for details
initial_X = 'separately';
% How to initialise X (more specifically, means of q(X)) for each layer.
% The selected method (potentially
% different per layer) will be applied in a sequential fashion, eg if we
% use PCA we obtain X_1 from PCA on Y, then X_2 from PCA on X_1 etc. Deep
% GPs are completely different than a stacked method, since X's will be
% integrated out (the initial X's above are actually the initial means of the var.
% distribution) and everythin will be optimised jointly.
% Here we opt for a Bayesian GPLVM that  gives the initial X.
% See hsvargplvm_init for other options (eg pca).
initX = 'vargplvm';
%- options for the BayesianGPLVM used to initialise the variational means
stackedInitIters = 200;
stackedInitVardistIters = 100;
stackedInitSNR = 100;
initVardistIters = 100;
demToyHsvargplvm1; % Run the actual demo

%% --- Plot true data
subplot(3,2,1)
myPlot(Z{3},'X2',[],[],{3,8},0)
subplot(3,2,3)
myPlot(Z{1},'XA',[],[],{3,8},0)
subplot(3,2,4)
myPlot(Z{2},'XB',[],[],{3,8},0)
subplot(3,2,5)
plot(Ytr{1},'x-'); title('YA');
subplot(3,2,6)
plot(Ytr{2},'x-'); title('YB');

%% -- Plot spaces discovered by deep GPs (two most dominant dimensions for
%% top layer and similarly for each of the two modalities of layer 1)
figure
hsvargplvmShowScales(model);

s2 = sort(vargplvmRetainedScales(model.layer{2}.comp{1}));
sA =  sort(vargplvmRetainedScales(model.layer{1}.comp{1}));
sB =  sort(vargplvmRetainedScales(model.layer{1}.comp{2}));

figure
subplot(2,2,1)
myPlot(model.layer{2}.vardist.means(:,s2(1:2)),'deepGP_X2',[],[],{3,8},0)
subplot(2,2,3)
myPlot(model.layer{1}.vardist.means(:,sA(1:2)),'deepGP_XA',[],[],{3,8},0)
subplot(2,2,4)
myPlot(model.layer{1}.vardist.means(:,sB(1:2)),'deepGP_XB',[],[],{3,8},0)


%% --- Compare with stacked Bayesian GP-LVM % TODO
%[XA, s, WA, modelA] = vargplvmEmbed(Ytr{1}, 5, initXOptions{1}{:});
%[XB, s, WB, modelB] = vargplvmEmbed(Ytr{2}, 5, initXOptions{1}{:});
%[X2, s, W2, model2]  = vargplvmEmbed([XA XB], 5, initXOptions{2}{:});

%% --- Compare with stacked PCA and isomap

figure
pcaXA = ppcaEmbed(Ytr{1}, 2);
pcaXB = ppcaEmbed(Ytr{2},2);
pcaX2 = ppcaEmbed([pcaXA pcaXB],2);
subplot(2,2,1)
myPlot(pcaX2,'pcaX2',[],[],{3,8},0)
subplot(2,2,3)
myPlot(pcaXA,'pcaXA',[],[],{3,8},0)
subplot(2,2,4)
myPlot(pcaXB,'pcaXB',[],[],{3,8},0)

figure
isomapXA = isomap2Embed(Ytr{1}, 2);
isomapXB = isomap2Embed(Ytr{2},2);
isomapX2 = isomap2Embed([isomapXA isomapXB],2);
subplot(2,2,1)
myPlot(isomapX2,'isomapX2',[],[],{3,8},0)
subplot(2,2,3)
myPlot(isomapXA,'isomapXA',[],[],{3,8},0)
subplot(2,2,4)
myPlot(isomapXB,'isomapXB',[],[],{3,8},0)
