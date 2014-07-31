% DEMHSVARGPLVMCLASSIFICATION Classification demo for deepGP demo, where
% data are put as inputs and labels correspond the outputs.
%
% This is a generic demo. You can replace the data used here with your own
% data and run it (ie Ytr{1} has to be the observed data and inpX has to be
% your observed labels).
%
% To configure the deepGP used here, do the following:
%   1. If any of the fields you want to change appear in this demo in the
%   "configuring the deep gp" section, they change it directly there.
%   2. If the field you're looking for is not there, then check the available
%    configuration options in hsvargplvm_init.m. The way this works, is that
%    you just need to overwrite the corresponding workspace variables.
%    e.g. if in hsvargplvm_init.m you see a field "fixInducing", you can
%    overwrite this field by just calling this demo as:
%    >> fixInducing = true; demHsvargplvmClassification
%   3. If the field you're looking for is not in hsvargplvm_init.m, then
%   check (in this order) svargplvm_init.m and vargplvm_init.m, again
%   overwritting the configuration by specifying the variable to exist, as
%   above.
%    
% demHsvargplvmRegression.m
%
% COPYRIGHT: Andreas Damianou, 2014

%% -- Loading the data. Replace this with your own data if you want
[Y, lbls] = vargplvmLoadData('oil100');
%-- Sort data according to labels (without loss of generality
labels = transformLabels(lbls);
[~,ss] = sort(labels);
Y = Y(ss,:);
lbls = lbls(ss,:);
labels = transformLabels(lbls);
%-------

% GEt a subset of the data for training, one for test
perm = randperm(size(Y,1));
indTr = perm(1:50);
indTs = perm(51:100);

inpX = Y(indTr,:);
Ytr{1} = lbls(indTr,:);

inpXtest = Y(indTs,:);
Ytest{1} = lbls(indTs,:);

%% ---- Configuring the DEEP GP ---

% For the kernel that models the input data, we are not constrained to use
% tractable for the Psi statistics... we can use whatever kernel!
dynamicKern = {'rbf','white','bias'};
% Number of iterations performed for initialising the variational
% distribution, and number of training iterations
initVardistIters = 100;  itNo = [50 50];
H=2;  % Number of layers
initSNR = 100; % Initial Signal To Noise ration per layer
K=25; % Number of inducing points to use
Q=5; % Dimensionality of latent space (can potentially be different per layer)

% Since both Y and initX are observed, how are we supposed to initialise
% the latent spaces? One option is to do stacked PCA, but in the case where
% the rich information is in the inputs we do that in the inputs, instead
% of the standard initialisation from the outputs.
initX={};
curX = inpX;
for h=H:-1:1
    if isscalar(Q), curQ = Q; else curQ = Q{h}; end
    curX = ppcaEmbed(curX, curQ);
    initX{h} = curX;
end

%% --- RUN THE ACTUAL DEMO
demHsvargplvmRegression

%% --- INSPECTION
layer = 2; % Change this to plot another layer
hsvargplvmPlotX(model, layer, [],[], [], [], transformLabels(Ytr{1}));

%% --- PREDICTIONS
[Testmeans Testcovars] = vargplvmPredictPoint(model.layer{end}.dynamics, inpXtest);
[mu, varsigma] = hsvargplvmPosteriorMeanVarSimple(model, Testmeans, Testcovars);
threshold = 0.5;
mu(mu>0.5) = 1;
mu(mu<=0.5) = 0;
figure
% Errors made
imagesc(abs(mu - Ytest{1}))

