if strcmp(toyType, 'simulatedSound')
    % TODO %%%%
    %%
    X = linspace(1,8*pi,Ntoy)'; % period of kernel is 2*pi
    X = scaleData(X, 1); % Make them zero-mean unit variance (useful (?) when initialising latent spaces

    kkern = kernCreate(X, {'rbfperiodic', 'white'});
    kkern.comp{1}.inverseWidth = 10;
    kkern.comp{2}.variance = 0.0001;
    KK = kernCompute(kkern, X);
    Y1 = gsamp(zeros(1, size(KK, 1)), KK, 1)';        Yorig1 = Y1;
    close; plot(Y1)
    %%
    kkern = kernCreate(Y1, {'rbf','white'});
    kkern.comp{1}.inverseWidth = 16;
    kkern.comp{1}.lengthScale = sqrt(1/kkern.comp{1}.inverseWidth);
    kkern.comp{2}.variance = 0.000001;
    KK = kernCompute(kkern, Y1);
    Y = gsamp(zeros(1, size(KK, 1)), KK, Dtoy)';
    
    %Y = Y + 0.05.*randn(size(Y));
    
    Ytr{1} = Y;
    
    
    %--- PLOTS
  %  close; subplot(2,2,1); plot(X,Y1); subplot(2,2,2); subplot(2,2,3); plot(X,Y);%plot(X,YTmp); 
  %  pause; subplot(2,2,4);
  %  for d=1:size(Y,2), plot(X,Y(:,d)); pause; end
elseif strcmp(toyType, 'hierGpsNEW')
    X = linspace(1,2*pi,Ntoy)';
    X = scaleData(X, 1); % Make them zero-mean unit variance (useful (?) when initialising latent spaces

    kkern = kernCreate(X, {'rbf','lin', 'white'});
    kkern.comp{1}.inverseWidth = 4;
    kkern.comp{3}.variance = 0.000001;
    KK = kernCompute(kkern, X);
    Y1 = gsamp(zeros(1, size(KK, 1)), KK, 1)';        Yorig1 = Y1;
    
    
    kkern = kernCreate(Y1, {'rbf','white'});
    kkern.comp{1}.inverseWidth = 16;
    kkern.comp{1}.lengthScale = sqrt(1/kkern.comp{1}.inverseWidth);
    kkern.comp{2}.variance = 0.000001;
    KK = kernCompute(kkern, Y1);
    Y = gsamp(zeros(1, size(KK, 1)), KK, Dtoy)';
    
    %Y = Y + 0.05.*randn(size(Y));
    
    Ytr{1} = Y;
    
    
    %--- PLOTS
    %{
    kkernTmp = kernCreate(X, {'rbf','white'});
    kkernTmp.comp{1}.inverseWidth = kkern.comp{1}.inverseWidth;
    kkernTmp.comp{1}.lengthScale = 1/kkernTmp.comp{1}.inverseWidth;
    kkernTmp.comp{2}.variance = kkern.comp{2}.variance;
    KKTmp = kernCompute(kkern, X);
    YTmp = gsamp(zeros(1, size(KKTmp, 1)), KKTmp, ceil(Dtoy/3))';
    %}
    
  %  close; subplot(2,2,1); plot(X,Y1); subplot(2,2,2); subplot(2,2,3); plot(X,Y);%plot(X,YTmp); 
  %  pause; subplot(2,2,4);
  %  for d=1:size(Y,2), plot(X,Y(:,d)); pause; end
elseif strcmp(toyType, 'nonstationaryPlusGP') || strcmp(toyType, 'nonstationaryPlusGP2')
    %%
    X = linspace(1,2*pi,Ntoy)';
    kkern = kernCreate(X, {'rbf','white'});
    kkern.comp{1}.inverseWidth = 5; % big inverseWidth -> rougher curves
    kkern.comp{2}.variance = 0.001;
    params = kernExtractParam(kkern);
    kkern = kernExpandParam(kkern, params);
    KK = kernCompute(kkern, X);
    Y1 = gsamp(zeros(1, size(KK, 1)), KK, Dtoy)';
    Yorig1 = Y1;
    
    kkern = kernCreate(X, {'rbf','white'});              kkernTmp = kernCreate(X, {'matern32','white'});
    kkern.comp{1}.inverseWidth = 2;                            kkernTmp.comp{1}.inverseWidth = kkern.comp{1}.inverseWidth;
    kkern.comp{1}.lengthScale = 1/kkern.comp{1}.inverseWidth;  kkernTmp.comp{1}.lengthScale = 1/kkernTmp.comp{1}.inverseWidth;
    kkern.comp{2}.variance = 0.001;                             kkernTmp.comp{2}.variance = kkern.comp{2}.variance;
    params = kernExtractParam(kkern);
    kkern = kernExpandParam(kkern, params);
    KK = kernCompute(kkern, X);                               KKTmp = kernCompute(kkern, X);
    Y2 = gsamp(zeros(1, size(KK, 1)), KK, 1)';               YTmp = gsamp(zeros(1, size(KKTmp, 1)), KKTmp, ceil(Dtoy/3))';
    Y2 = repmat(Y2,1,size(Y1,2));
    Y = Y1 + (trendEffect .* Y2);
    if strcmp(toyType, 'nonstationaryPlusGP2')
        nn = linspace(0.005,0.35, size(Y,1))';
        nn = repmat(nn, 1,size(Y,2));
        %
        %Y = Y + 0.1.*randn(size(Y));
        Y = Y + nn.*randn(size(Y));
    else
        Y = Y + 0.05.*randn(size(Y));
    end
    
    Ytr{1} = Y;
    
    
    close; subplot(2,2,1); plot(Y1); subplot(2,2,2); plot(Y2); subplot(2,2,3); plot(Y);
    pause; subplot(2,2,4);
    for d=1:size(Y,2), plot(Y(:,d)); pause; end
elseif strcmp(toyType, 'hierGps2')
    %%
    X = linspace(1,2*pi,Ntoy)';
    kkern = kernCreate(X, {'rbf','white'});
    kkern.comp{1}.inverseWidth = 5; % big inverseWidth -> rougher curves
    kkern.comp{2}.variance = 0.001;
    params = kernExtractParam(kkern);
    kkern = kernExpandParam(kkern, params);
    KK = kernCompute(kkern, X);
    Y1 = zeros(Ntoy, Dtoy);
    for d=1:size(Y1,2);
        Y1(:,d) = gsamp(zeros(1, size(KK,1)), KK, 1)';
    end
    Yorig1 = Y1;
    kkern = kernCreate(Y1, {'matern32','white'});              kkernTmp = kernCreate(X, {'matern32','white'});
    kkern.comp{1}.inverseWidth = 2;                            kkernTmp.comp{1}.inverseWidth = kkern.comp{1}.inverseWidth;
    kkern.comp{1}.lengthScale = 1/kkern.comp{1}.inverseWidth;  kkernTmp.comp{1}.lengthScale = 1/kkernTmp.comp{1}.inverseWidth;
    kkern.comp{2}.variance = 0.001;                             kkernTmp.comp{2}.variance = kkern.comp{2}.variance;
    params = kernExtractParam(kkern);
    kkern = kernExpandParam(kkern, params);
    Y = zeros(size(Y1));
    for d=1:size(Y,2)
        KK = kernCompute(kkern, Y1(:,d));                               KKTmp = kernCompute(kkern, X);
        Y(:,d) = gsamp(zeros(1, size(KK, 1)), KK, 1)';               YTmp = gsamp(zeros(1, size(KKTmp, 1)), KKTmp, ceil(Dtoy/3))';
    end
    
    Y = Y + 0.05.*randn(size(Y));
    
    Ytr{1} = Y;
    
    close; subplot(2,2,1); plot(Y1); subplot(2,2,2); plot(YTmp); subplot(2,2,3); plot(Y);
    pause; subplot(2,2,4);
    for d=1:size(Y,2), plot(Y(:,d)); pause; end
elseif strcmp(toyType, 'hierGps') || strcmp(toyType, 'hierGpsNonstat')
    %%
    X = linspace(1,2*pi,Ntoy)';
    kkern = kernCreate(X, {'rbf','white'});
    kkern.comp{1}.inverseWidth = 5; % big inverseWidth -> rougher curves
    kkern.comp{2}.variance = 0.001;
    params = kernExtractParam(kkern);
    kkern = kernExpandParam(kkern, params);
    KK = kernCompute(kkern, X);
    Y1 = gsamp(zeros(1, size(KK, 1)), KK, ceil(Dtoy/2))';
    Yorig1 = Y1;
    kkern = kernCreate(Y1, {'matern32','white'});              kkernTmp = kernCreate(X, {'matern32','white'});
    kkern.comp{1}.inverseWidth = 2;                            kkernTmp.comp{1}.inverseWidth = kkern.comp{1}.inverseWidth;
    kkern.comp{1}.lengthScale = 1/kkern.comp{1}.inverseWidth;  kkernTmp.comp{1}.lengthScale = 1/kkernTmp.comp{1}.inverseWidth;
    kkern.comp{2}.variance = 0.001;                             kkernTmp.comp{2}.variance = kkern.comp{2}.variance;
    params = kernExtractParam(kkern);
    kkern = kernExpandParam(kkern, params);
    KK = kernCompute(kkern, Y1);                               KKTmp = kernCompute(kkern, X);
    Y = gsamp(zeros(1, size(KK, 1)), KK, Dtoy)';               YTmp = gsamp(zeros(1, size(KKTmp, 1)), KKTmp, ceil(Dtoy/3))';
    
    if strcmp(toyType, 'hierGpsNonstat')
        %add nonstationarity
        %trend = linspace(min(min(Y)), max(max(Y))*trendEffect, size(Y,1))';
        trend = trendEffect.*cos(linspace(0,2*pi, size(Y,1)))'.*((max(max(Y))-min(min(Y)))/2); % cos has amplitude 2... make it amplitude of Y
        %trend = trend.^2;
        Y = Y + repmat(trend, 1,size(Y,2));
        % NEW:
        nn = linspace(0.005,0.35, size(Y,1))';
        nn = repmat(nn, 1,size(Y,2));
        %
        %Y = Y + 0.1.*randn(size(Y));
        Y = Y + nn.*randn(size(Y));
    else
        Y = Y + 0.05.*randn(size(Y));
    end
    
    Ytr{1} = Y;
    
    
    close; subplot(2,2,1); plot(Y1); subplot(2,2,2); plot(YTmp); subplot(2,2,3); plot(Y);
    pause; subplot(2,2,4);
    for d=1:size(Y,2), plot(Y(:,d)); pause; end
elseif strcmp(toyType, 'nonstationaryLog')
    X = linspace(1,2*pi,Ntoy)';
    Xlog = log(X);
    %kkern = kernCreate(Y, {'matern32','white'});
    %kkern.comp{1}.lengthScale = 0.5;
    kkern = kernCreate(Xlog, {'rbf','white'});
    kkern.comp{1}.inverseWidth = 100;
    kkern.comp{1}.lengthScale = 1/kkern.comp{1}.inverseWidth;
    kkern.comp{2}.variance = 0.01;
    params = kernExtractParam(kkern);
    kkern = kernExpandParam(kkern, params);
    KK = kernCompute(kkern, Xlog);
    Y = gsamp(zeros(1, size(KK, 1)), KK, Dtoy)'; Yorig = Y;
    nn = linspace(0.005,0.35, size(Y,1))';
    nn = repmat(nn, 1,size(Y,2));
    Y = Y + nn.*randn(size(Y));
    %Y = Y + 0.1.*randn(size(Y));
    
    Ytr{1} = Y;
elseif strcmp(toyType, 'nonstationary')
    X = linspace(1,2*pi,Ntoy)';
    %kkern = kernCreate(Y, {'matern32','white'});
    %kkern.comp{1}.lengthScale = 0.5;
    kkern = kernCreate(X, {'rbf','white'});
    kkern.comp{1}.inverseWidth = 20;
    kkern.comp{2}.variance = 0.001;
    params = kernExtractParam(kkern);
    kkern = kernExpandParam(kkern, params);
    KK = kernCompute(kkern, X);
    Y = gsamp(zeros(1, size(KK, 1)), KK, Dtoy)'; Yorig = Y;
    %add nonstationarity
    %trend = linspace(min(min(Y)), max(max(Y))*trendEffect, size(Y,1))';
    trend = trendEffect.*cos(linspace(0,2*pi, size(Y,1)))'.*((max(max(Y))-min(min(Y)))/2); % cos has amplitude 2... make it amplitude of Y
    %trend = trend.^2;
    Y = Y + repmat(trend, 1,size(Y,2));
    % NEW:
    nn = linspace(0.005,0.35, size(Y,1))';
    nn = repmat(nn, 1,size(Y,2));
    %
    %Y = Y + 0.1.*randn(size(Y));
    Y = Y + nn.*randn(size(Y));
    Ytr{1} = Y;
elseif strcmp(toyType, 'hgplvmSample2')
    %addpath('../../../hgplvm/matlab/')
    load hgplvmSampleModel2
    Ytr{1} = Y; X = Xall{end};
    Ntoy = size(Y,1);
end
globalOpt.K = min(globalOpt.K, Ntr);

%{
[Ytr, dataSetNames, Z] = hsvargplvmCreateToyData2(toyType,Ntoy,Dtoy,numSharedDims,numHierDims, noiseLevel,hierSignalStrength);

if globalOpt.multOutput
    Ynew = [Ytr{1} Ytr{2}];
    Ytr = cell(1,size(Ynew,2));
    for i=1:size(Ynew,2)
        Ytr{i} = Ynew(:,i);
    end
end
%}


