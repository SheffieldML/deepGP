[Testmeans Testcovars] = vargplvmPredictPoint(model.layer{end}.dynamics, Xstar);
%[mu, varsigma]
%mu = hsvargplvmPosteriorMeanVar(model, Testmeans2, Testcovars2, model.H, 1, -1);
[mu, varsigma] = hsvargplvmPosteriorMeanVarSimple(model, Testmeans, Testcovars);

[TestmeansIn TestcovarsIn] = vargplvmPredictPoint(modelInitVardist.layer{end}.dynamics, Xstar);
[muIn, varsigmaIn] = hsvargplvmPosteriorMeanVarSimple(model, TestmeansIn, TestcovarsIn);

errorDeepGP = sum(mean(abs(mu-Yts{1}),1));
errorDeepGPNoCovars = sum(mean(abs(hsvargplvmPosteriorMeanVarSimple(model, Testmeans)-Yts{1}),1));
errorDeepGPIn = sum(mean(abs(muIn-Yts{1}), 1));

errorMean = sum(mean(abs(repmat(mean(Ytr{1}),size(Yts{1},1),1) - Yts{1}),1));

for dd=1:size(Ytr{1},2)
    [p, ErrorEst] = polyfit(inpX,Ytr{1}(:,dd),2);
    yLinReg(:,dd)=polyval(p,Xstar);
end
errorLinReg = sum(mean(abs(yLinReg - Yts{1}),1));


%{
muAll = 0;
for i=1:140
    [muCur varsigmaCur] = hsvargplvmPosteriorMeanVarSimple(model, Testmeans);%, Testcovars);
    muAll = muAll + gaussianSample(muCur, varsigmaCur)  ;
end
muAll = muAll ./ 140;
sum(mean(abs(muAll-Yts{1}),1))
%}

[TestmeansTr TestcovarsTr] = vargplvmPredictPoint(model.layer{end}.dynamics, inpX);
errorRecDeepGP = sum(mean(abs(hsvargplvmPosteriorMeanVarSimple(model, TestmeansTr, TestcovarsTr)-Ytr{1}),1));
errorRecDeepGPNoCovars = sum(mean(abs(hsvargplvmPosteriorMeanVarSimple(model, TestmeansTr)-Ytr{1}),1));

fprintf('\n\n#### ERRORS:\n')
try
    fprintf('# Error GP pred      : %.4f\n', errorGP);
    fprintf('# Error GPfitc pred  : %.4f\n', errorGPfitc);
end
fprintf('# Error DeepGP pred      : %.4f / %.4f (with/without covars)\n', errorDeepGP, errorDeepGPNoCovars);
fprintf('# Error DeepGPInitPred   : %.4f\n',errorDeepGPIn);
if runVGPDS
    fprintf('# Error VGPDS pred       : %.4f\n', errorVGPDS);
    fprintf('# Error VGPDSInVpred     : %.4f\n', errorVGPDSIn);
end
fprintf('\n')
fprintf('# Error Mean             : %.4f\n', errorMean);
fprintf('# Error LinReg           : %.4f\n', errorLinReg);
try, fprintf('# Error GP rec      : %.4f\n', errorRecGP);end
fprintf('# Error DeepGP rec       : %.4f / %.4f (with/without covars)\n', errorRecDeepGP, errorRecDeepGPNoCovars);
if runVGPDS
    fprintf('# Error VGPDS rec        : %.4f\n', errorRecVGPDS);
end
%%
%{

close
for d=1:size(Yts{1},2)
    plot(Yts{1}(:,d), '.-');
    hold on
    plot(muGP(:,d), 'x:g');
    plot(mu(:,d), 'o--r');
    legend('orig', 'gp','gplvm');
    pause
    hold off
end

%}