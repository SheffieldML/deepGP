%----------------------------------
% hsvargplvmTestPrior.m
% This script demonstrates how to test the effect of a prior on the parameters. 
% The focus of this script is on the noise parameter beta which can cause
% low SNR problems when it becomes too small. This script demonstrates how
% one can add a Gamma prior on this parameter, to bias its values during
% optimisation to be large. How large beta needs to be and how strong the
% effect of the prior will be can be explored manually as shown in this
% script. 
%
% In general, SNR is defined as variance_of_data * beta. We want SNR to be
% larger than e.g. 10, ideally larger than 100, that is, explain 100 times
% more signal than noise. 
%
% You can use the diagnostics of this demo for adding priors in your model,
% but to get a feeling of what is a good calibration of the prior (with
% respect to the diagnostics' curves), you are advised to first run this
% demo as is (with the included optional model).
%-----------------------------------------------



%% --- Create small model [OPTIONAL]
%-- Change with your own setting ---
clear; close all; experimentNo=404;
dynamicKern = {'lin','white','bias'};
initVardistIters = 0;  itNo = 0;
H=2; initSNR = {100,200};
toyType='hierGpsNEW';Ntr=25; Dtoy=10;K=25;Q=8;initX='inputsOutputs';
runGP=0; runVGPDS=0; doPredictions=0;
demToyRegressionOld;
%---

% Optimise a little with fixed SNR
model = hsvargplvmOptimiseModel(model, 0, 0, [], {1500, 0});

% Needed for comparisons later
modelOld = model;
gOld =modelLogLikeGradients(modelOld);

%% ----- ADD PRIOR

%--- Config: where and what prior to add
h=2;                                 % Which layer to receive the prior
meanSNR = 150;                       % Where I want the expected value of my inv gamma if it was on SNR
priorName = 'invgamma';              % What type of prior
scale = model.layer{1}.comp{1}.N;    % 'strength' of prior.
%----

varData = var(model.layer{h}.comp{1}.mOrig(:));
meanB = meanSNR./varData;
a=0.08;%1.0001; % Relatively large right-tail
b=meanB*(a+1); % Because mode = b/(a-1)
try
    % Remove existing prior if in place
    model.layer{h}.comp{1} = rmfield(model.layer{h}.comp{1},'paramPriors');
end

% Add the prior on parameter 'beta'. The prior is specified by its name
% (priorName) and its parameters ([a,b])
model = hsvargplvmAddParamPrior(model, h, 1, 'beta', priorName, [a b]);

% Add a scale to the prior ("strength") and save this version of the model.
modelPriorScaled = model;  
modelPriorScaled.layer{h}.comp{1}.paramPriors{1}.prior.scale = scale;


%% -----   Plots

% extract prior
prior = model.layer{h}.comp{1}.paramPriors{1}.prior; % TODO: Check if index is correct for deep GP

close all
% For a range of different SNRs plot the likelihood and the gradient of the
% parameter beta (on which we put the prior). We expect to see the
% likelihood to take its maximum value close to a "good" value for the SNR
% (close to the meanB set above).
SNR_range = 2:2:1000;
ll = zeros(length(SNR_range),1);
gg = zeros(length(SNR_range),1);
for j=1:length(SNR_range)
    beta_cur = SNR_range(j) ./ varData;
    ll(j,:) = priorLogProb(prior, beta_cur); % Distribution for beta
    gg(j,:) = priorGradient(prior, beta_cur);
end
subplot(1,3,1)
plot(SNR_range, exp(ll)) ; title('distribution for beta prior')
subplot(1,3,2)
plot(SNR_range, gg); title('gradients');

[params, names] = modelExtractParam(model);
c=0;
for i=1:h-1
    c=c+model.layer{i}.nParams;
end
for i=c+1:c+length(names(c+1:end))
    if strcmp(names{i},'Beta 1')
        index = i;
    end
end
subplot(1,3,3)
g=modelLogLikeGradients(model);
% Plot the gradients for different beta values divided by the gradients for
% the current beta value. If very close to 1, it means that the prior doesn't
% have such a strong effect. Of course, we want the strong effect of the
% prior only in areas with "bad SNR", ie low SNR.
plot(SNR_range, gg./g(index)); title('gradients/lik.grad') % Close to 1 means they're in the same scale

%% --- Another plot: This ignores the likelihood part of the model, and
% just makes the plots as above but only for the prior part of the model
% (since we can write the objective as F = F_likelihood + F_prior.

ca
SNR_range = 10:10:1000;
ll = zeros(length(SNR_range),1);
ll2 = zeros(length(SNR_range),1);
gg = zeros(length(SNR_range),1);
gg2 = zeros(length(SNR_range),1);
for j=1:length(SNR_range)
    % PLot the gradient of the model for different beta (SNR) choices
    beta_cur =  SNR_range(j) ./ varData;
    model.layer{h}.comp{1}.beta = beta_cur;
    params = hsvargplvmExtractParam(model);
    model = hsvargplvmExpandParam(model, params);
    ll(j,:) = hsvargplvmLogLikelihood(model);
    g=hsvargplvmLogLikeGradients(model);
    gg(j,:) = g(index);
    
    % As above, but ONLY consider the gradient of the prior
    ggg=zeros(size(g));
    c=1;
    for h=1:model.H
        ind_cur = c:c+model.layer{h}.nParams-1;
        c=c+length(ind_cur);
        if model.layer{h}.M > 1
            error('Not implemented M > 1 yet!');
        end
        ggg(ind_cur) = ggg(ind_cur) + vargplvmParamPriorGradients(model.layer{h}.comp{1}, length(ggg(ind_cur)));
        ll2(j,:) = ll2(j,:) + vargplvmParamPriorLogProb(model.layer{h}.comp{1});
    end
    gg2(j,:) = ggg(index);
end
subplot(2,2,1)
plot(SNR_range, ll) ; title('distribution for beta prior');xlabel('SNR');ylabel('Log Likelihood')
subplot(2,2,2)
plot(SNR_range, gg); title('gradients');xlabel('SNR');ylabel('gradients')
subplot(2,2,3)
plot(SNR_range, ll2); title('Log likelihood (only prior)');xlabel('SNR');ylabel('Log likelihood (only prior)')
subplot(2,2,4)
plot(SNR_range, gg2); title('gradients (only prior)');xlabel('SNR');ylabel('gradients (only prior)')

%% ----- See if it works during optimisation
itNo = 300;
mPrior   = hsvargplvmOptimiseModel(model, 0, 0, [], {0, itNo});  % This should have better SNR than the next one!
mPriorSc = hsvargplvmOptimiseModel(modelPriorScaled, 0, 0, [], {0, itNo});  % This should have better SNR than the next one!
mNoPrior = hsvargplvmOptimiseModel(modelOld, 0, 0, [], {0, itNo});
sPrior=hsvargplvmShowSNR(mPrior,[],0);
snrPrior=[]; for i=1:length(sPrior), snrPrior = [snrPrior ' | ' num2str(sPrior{i})]; end
sPriorSc=hsvargplvmShowSNR(mPriorSc,[],0);
snrPriorSc=[]; for i=1:length(sPriorSc), snrPriorSc = [snrPriorSc ' | ' num2str(sPriorSc{i})]; end
sNoPrior=hsvargplvmShowSNR(mNoPrior,[],0);
snrNoPrior=[]; for i=1:length(sPrior), snrNoPrior = [snrNoPrior ' | ' num2str(sNoPrior{i})]; end

fprintf('# SNR with         prior on top layer: %s\n', snrPrior);
fprintf('# SNR with scaled  prior on top layer: %s\n', snrPriorSc);
fprintf('# SNR with NO      prior on top layer: %s\n', snrNoPrior);