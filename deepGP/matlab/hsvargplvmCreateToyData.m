% Create toy data. Give [] as an argument if the default value is to be
% used for the corresponding parameter.

function [Yall, dataSetNames, Z] = hsvargplvmCreateToyData(type, N, D, numSharedDims, numHierDims, noiseLevel, hierSignalStrength)

if nargin < 7 || isempty(hierSignalStrength),     hierSignalStrength = 0.6;  end
if nargin < 6 || isempty(noiseLevel),             noiseLevel = 0.1;  end
if nargin < 5 || isempty(numHierDims),            numHierDims = 1;   end
if nargin < 4 || isempty(numSharedDims),          numSharedDims = 5; end
if nargin < 3 || isempty(D),                      D = 10;            end
if nargin < 2 || isempty(N),                      N = 100;           end
if nargin < 1 || isempty(type),                   type = 'fols';     end


switch type
    case 'fols'
        alpha = linspace(0,4*pi,N);
        privSignalInd = [1 2];
        sharedSignalInd = 3;
        hierSignalInd = 4;
        
        
        Z{1} = cos(alpha)';
        Z{2} = sin(alpha)';
        
        Z{3}= (cos(alpha)').^2;
        Z{4} = heaviside(linspace(-10,10,N))'; % Step function
       % Z{3} = heaviside(Z{3}); % This turns the signal into a step function
       % Z{3} = 2*cos(2*alpha)' + 2*sin(2*alpha)' ; %
        
        
        % Scale and center data
        for i=1:length(Z)
            bias_Z{i} = mean(Z{i});
            Z{i} = Z{i} - repmat(bias_Z{i},size(Z{i},1),1);
            scale_Z{i} = max(max(abs(Z{i})));
            Z{i} = Z{i} ./scale_Z{i};
        end
        
        % Do the following only for the private signals
        for i=privSignalInd
            % Map 1-Dim to D-Dim and add some noise
            Zp{i} = Z{i}*rand(1,D-numSharedDims);
            Zp{i} = Zp{i} + noiseLevel.*randn(size(Zp{i}));
        end
        
        % This is the shared signal
        i = sharedSignalInd;
        Zp{i} = Z{i}*rand(1,numSharedDims);
        Zp{i} = Zp{i} + noiseLevel.*randn(size(Zp{i}));
        
        % This is the high-level signal
        i = hierSignalInd;
        %Zp{i} = Z{i}*rand(1,D);
        Zp{i} = Z{i}*ones(1,D);
        Zp{i} = Zp{i} + noiseLevel.*randn(size(Zp{i}));
        
        
        % pca(Zp{2}) % This shows that it is actually a 1-D dataset
        
        % Y = [Zp{1} Zp{2}];
        % We like the numer of latent dims to be 2+numSharedDims, ideally 3. With
        % vargplvm we set Q=6 and expect the other 3 or 4 to be switched off.
        % [U,V] = pca(Y,6);
        % Xp = Y*V;
        % pca(Xp)
        
        %---
        allPr = []; allPr1 = [];
        for i=privSignalInd
            Zp{i} = [Zp{i} Zp{sharedSignalInd}];
            allPr1 = [allPr1 Zp{i}]; %%%%% DEBUG
            Yall1{i} = Zp{i};        %%%%% DEBUG
        end
        
        for i=privSignalInd
            % Apply the high-level signal to the private ones
           % Zp{i} = Zp{i} .* Zp{hierSignalInd}; % ORIGINAL
            Zp{i} = Zp{i} + hierSignalStrength*Zp{hierSignalInd}; %
            allPr = [allPr Zp{i}];
            Yall{i} = Zp{i};
        end
       
        
        bar(pca(allPr))
        % return
        %---

        dataSetNames={'fols_cos', 'fols_sin'};
        
        for i=privSignalInd
            figure
            title(['model ' num2str(i)])
            subplot(2,1,1)
            plot(Z{i}), hold on
            plot(Z{sharedSignalInd}, 'r')
            plot(pcaEmbed(Yall{i},1), 'm')
            legend('Orig.','Shared','Final')
            subplot(2,1,2)
            plot(Z{hierSignalInd});
            legend('Hier.')
        end
end

%%
for i=length(privSignalInd)
    ZZ{i} = [Z{privSignalInd(i)} Z{sharedSignalInd}]+repmat(Z{hierSignalInd},1,size([Z{privSignalInd(i)} Z{sharedSignalInd}],2)).*0.6;
end
%%