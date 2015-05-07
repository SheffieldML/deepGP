% HSVARGPLVMFEATURECLASSIFICATION Use a deepGP features to perform
% discriminative classification with log. regression.
%
% Andreas C. Damianou, 2015
% SEEALSO: vargplvmFeatureClassification.m

function [LogRegError, LogRegErrorExt, LogRegErrorExtOut] = hsvargplvmFeatureClassification(model, data, options)

% Train classifiers from X to labels
labels = transformLabels(data.lbls)';
labelsTs = transformLabels(data.lblsTs)';

lOut = options.lOut;
samplesPerObserved = options.samplesPerObserved;
samplesPerOutput = options.samplesPerOutput;
% Use only SOME dimensions as features (e.g. the ones with best ARD wight)
if ~isfield(options, 'dims') || isempty(options.dims)
    dims = 1:model.layer{lOut}.q;
else
    dims = options.dims;
end

% Populate training set
%--- Take variance into account by sampling new data from the distribution
% Init sizes
Xnew = nan(size(model.layer{lOut}.vardist.means,1)*samplesPerObserved, size(model.layer{lOut}.vardist.means,2));
labelsNew = nan(size(Xnew,1), size(labels,2));
k=1;
% Take samples
for n=1:size(model.layer{lOut}.vardist.means,1)
    for kk = 1:samplesPerObserved
        Xnew(k,:) = model.layer{lOut}.vardist.means(n,:) + randn(size(model.layer{lOut}.vardist.means(n,:))).*sqrt(model.layer{lOut}.vardist.covars(n,:));
        labelsNew(k,:) = labels(n,:);
        k = k + 1;
    end
end
% Augment set with samples
Xext = [model.layer{lOut}.vardist.means; Xnew];
labelsExt = [labels; labelsNew];
clear 'Xnew' 'labelsNew';


% If we need to predict from top layer, we need to GP conditional to
% predict q(x*) from the coupled q(X) = \prod_q q(x_q).
if ~isfield(data, 'X_pred') || isempty(data.X_pred)
    [X_Hpred, varX_Hpred] = vargplvmPredictPoint(model.layer{end}.dynamics, data.Yts);
    if lOut == model.H
        X_pred = X_Hpred;
        varX_pred = varX_Hpred;
    else
        [X_pred, varX_pred] = hsvargplvmPosteriorMeanVar(model, X_Hpred, varX_Hpred, model.H, lOut+1);
    end
else
    X_pred = data.X_pred;
    varX_pred = data.varX_pred;
end


% CHECK ALSO: mnrfit and mnrval

% Training of logistic regression classifier. One for each label
% separately.
nClasses = length(unique(labels));
clear 'B' 'BExt'
for i=1:nClasses
    fprintf('\n # LogReg training for class # %d\n', i)
    lb = zeros(size(model.layer{lOut}.vardist.means(:,dims),1),1);
    lbExt = zeros(size(Xext(:,dims),1),1);
    lb(labels == i) = 1;
    lbExt(labelsExt == i) = 1;
    B{i} = glmfitWrapper(model.layer{lOut}.vardist.means(:,dims), lb,'binomial','logit',[],[],[],[],1000); % Logistic regression
    %BExt{i} = glmfit(Xext, lbExt,'binomial','logit'); % Logistic regression
    BExt{i} = glmfitWrapper(Xext(:,dims), lbExt,'binomial','logit',[],[],[],[],1000); % Logistic regression
end

svmmodel    = svmtrain(labels,                 model.layer{options.lOut}.vardist.means(:,dims),'-q');
%svmmodelExt = svmtrain(transformLabels(lbExt), model.layer{options.lOut}.vardist.means(:,dims),'-q');

[~, acc,~]    = svmpredict(labelsTs, X_pred(:,dims), svmmodel,'-q');
%[~, accExt] = svmpredict(labelsTs',data.X_pred, svmmodelExt);

% Prediction of each binary classifier
Ypred_logReg = zeros(size(data.lblsTs));
Ypred_logRegExtOut = zeros(size(data.lblsTs));
Ypred_logRegExt = zeros(size(data.lblsTs));
for i=1:nClasses
    for k=1:samplesPerOutput
        % Sample from the OUTPUT distribution, and then average predictions
        Xsamp = X_pred + randn(size(X_pred)).*sqrt(varX_pred);
        Ypred_logRegExtOut(:,i) = Ypred_logRegExtOut(:,i)+1/samplesPerOutput*glmval(BExt{i}, Xsamp(:,dims), 'logit');
    end
    Ypred_logReg(:,i) = glmval(B{i}, X_pred(:,dims), 'logit')';
    Ypred_logRegExt(:,i) = glmval(BExt{i}, X_pred(:,dims), 'logit')';
end
% Replace predictions with maximum probability (ie, make a decision)
[~,ind]=max(Ypred_logReg');
[~,indExt]=max(Ypred_logRegExt');
[~,indExtOut]=max(Ypred_logRegExtOut');
LogRegError = 0;
LogRegErrorExt = 0;
LogRegErrorExtOut = 0;
for i=1:size(X_pred,1)
    LogRegError = LogRegError + (ind(i) ~= labelsTs(i));
    LogRegErrorExt = LogRegErrorExt + (indExt(i) ~= labelsTs(i));
    LogRegErrorExtOut = LogRegErrorExtOut + (indExtOut(i) ~= labelsTs(i));
end

N = size(X_pred,1);
fprintf('\n========================== REPORT ===========================\n')
fprintf('# Used features of layer                               : %d\n',lOut);
fprintf('# Acc Reg:                                             : %.2f%%\n', (N-LogRegError)/N * 100);
fprintf('# Acc Reg: with %d samp. PerObserved                    : %.2f%%\n', samplesPerObserved,(N-LogRegErrorExt)/N*100);
fprintf('# Acc Reg: with %d samp. PerObserved, %d samp.PerOutput : %.2f%%\n', samplesPerObserved, samplesPerOutput,(N-LogRegErrorExtOut)/N*100);
fprintf('# Acc SVM:                                             : %.2f%%\n', acc(1));
%fprintf('# Acc SVM: with % samp. PerObserved                    : %.2f%%\n', samplesPerObserved,accExt(1));
fprintf('----------------------------------------------------------------\n\n');