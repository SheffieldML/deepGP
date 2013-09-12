% DEMDIGITSDEMONTRATION A collection of demonstrations for the digits data
% with a pre-trained model
% 
% COPYRIGHT: Andreas C. Damianou, 2013
%
% DEEPGP

% Experiment number 19 is the deepest architecture (5 layers)
expNo = 19; % Other experiments: 10, 16

%load(['matFiles/demUsps3ClassHsvargplvm' num2str(expNo)]);
load(['demUsps3ClassHsvargplvm' num2str(expNo)]);
dataMerge = 'vercat2';

randn('seed', 1e5);
rand('seed', 1e5);

demDigitsDemonstrationInit;

fprintf('#--- Loaded a model with %d layers. See popup for learned scales.\n\n', model.H);

figure; hsvargplvmShowScales(model);

%% !!!!!!
% ---- The following seems to have problems with the GUI... If it's giving you a hard time
% check next code segment which does the same thing (sampling) but automatically

% From the parent or intermediate with outputs being in the 1st layer

% It's tricky to find a good starting point (initial drawn point) so as to demonstrate something
% interesting... Here's a suggestion for the 5-layer model (experiment number 19)
% (one starting point for each layer)..

disp('#--- Sampling the latent space manually (use the mouse).');
disp('    (If samples do not look like the ones of the next part -automatic sampling-')
disp('     check that this demo sees the lvmVisualise* funcitons of mltools)')
reply = input('# Do you want to skip this part? Y/N [N]: ', 's');
if isempty(reply)
    reply = 'N';
end


if strcmp(reply, 'N')
    startingPoints = [1, 79, 51];
    layersToVisualise = [1, 2, 5];
    dims = {{2,4}, {2,6}, {5 6}};
    h1 = figure; h2 = figure;
    for i=1:length(layersToVisualise)
        layer = layersToVisualise(i);
        fprintf('# Sampling from layer %d', layer)
        
        % Also check the scales to see interesting dimensions to sample from.
        % Interesting dimensions for the model of exp. number 19 (5 layers) are:
        % Layer 1 - dim. 2, Layer 2 - dim. 8, Layer 5 dim. 5 and 6
        %
        modelP = model;
        modelP.type = 'hsvargplvm';
        modelP.vardist = model.layer{layer}.vardist;
        modelP.X = modelP.vardist.means;
        modelP.q = size(modelP.X,2);
        
        modelP.d = size(Ytr{1},2);
        if layer ==1
            modelP.y = Ytr{1};
        else
            modelP.y = model.layer{layer-1}.vardist.means;
        end
        
        modelP.vis.index=-1;
        modelP.vis.layer = layer;
        
        modelP.vis.startPos = model.layer{layer}.vardist.means(startingPoints(i),:);
        modelP.vis.startDim = dims{i};
        modelP.vis.figHandle = {h1, h2};
        lvmVisualiseGeneral(modelP,  [], 'imageVisualise', 'imageModify', false,[16 16], 1,0,1);
        axis off
        %model.comp{v}, [], 'imageVisualise', 'imageModify', [height width], 0,0,1);
        fprintf('... When done, press any key to continue to next ')
        if i==length(layersToVisualise), fprintf('demo\n'), else fprintf('layer\n'); end
        pause
    end
end

%% Sample automatically
%- These values are model-specific (check scales).
% Sample from all layers but be careful to sample from a dimension which is
% switched on...
% !!! The samples are obtained by sampling a bit before the minimum X and a
% bit after the maximum, so there might be a bit of "nonesense" pictures in
% the beginning and end (when sampling by hand we don't have this problem)
% Layers to try: this is an example for a 5-deep structure
layers = [1 2 5 5];
% The following helps to see what point is which digit
%imagesc(reshape(Ytr{1}(i,:), 16,16))
% The corresponding "starting points" to sampel from
startingPoint = [1 79 51 51];
% The corresponding dimensions to sample from (check scales for specific
% layers)
dim = [2 8 5 6];
%---

fprintf('\n#--- Automatic sampling...\n')
reply = input('# Do you want to skip this part? Y/N [N]: ', 's');
if isempty(reply)
    reply = 'N';
end

if strcmp(reply, 'N')
    for j = 1:length(layers)
        fprintf('# Sampling from layer %d, dimension %d... ', layers(j), dim(j))
        layer = layers(j);
        %hsvargplvmSampleLayer(model, lInp, lOut, ind,  dim,X, startingPoint)
        [X,mu] = hsvargplvmSampleLayer(model,layer,1,-1,dim(j),[],startingPoint(j));
        h=figure;
        %pause
        
        %root = ['../diagrams/usps/sampleL' num2str(layer) 'Dim' num2str(dim) 'StPt' num2str(startingPoint)];
        root = []; % Comment to SAVE
        if ~isempty(root)
            mkdir(root) %%%%
        end
        for i=1:size(mu,1)
            imagesc(reshape(mu(i,:),16,16)'), colormap('gray')
            try
                 truesize(h,[100 100])
            catch
                pp = get(gcf, 'Position');
                set(h,'Position',[pp(1) pp(2) 100 100])
            end
            axis off
            if ~isempty(root)
                fileName = [root filesep num2str(i)];
                print('-dpdf', [fileName '.pdf']);
                print('-dpng', [fileName '.png']);
                fprintf('.')
            else
                pause(0.01)
                %pause
            end
        end
        imagesc(reshape(var(mu),16,16)'); title('variance samples')
        disp('Done! Press any key to continue...')
        pause
    end
end


%% Do the above for all layers, all dims and show the variance in the end (this can
% be a *bit* misleading, if the colormaps are not normalised... but helps
% with the above demo, ie identifying which layers/dims are worth sampling)

fprintf('\n#--- Get many samples from all layers, all dimensions and\n')
disp('     show the variance across samples to get a feeling of the')
disp('     kind of features discovered. ')
reply = input('# Do you want to skip this part? Y/N [N]: ', 's');
if isempty(reply)
    reply = 'N';
end

close all

if strcmp(reply, 'N')
    
    scrsz = get(0,'ScreenSize');
    %figure('Position',[scrsz(3)/4.86 scrsz(4)/1 1.2*scrsz(3)/1.6457 0.6*scrsz(4)/3.4682])
    figure
    startingPoint = 1;
    QQ=model.layer{1}.q; % layer 1 has the largest number of scales always
    clAll = [];
    for layer=1:model.H
        for dim=1:model.layer{layer}.q
            %hsvargplvmSampleLayer(model, lInp, lOut, ind,  dim,X,startingPoint)
            [X,mu] = hsvargplvmSampleLayer(model,layer,1,-1,dim,[],startingPoint);
            p = QQ*(layer-1)+dim;
            subplot(model.H,QQ ,p)
            imagesc(reshape(var(mu), 16,16)')
            clAll = [clAll; caxis];
        end
    end
    colormap gray
    % As above but use the same colormap
    %figure('Position',[scrsz(3)/4.86 scrsz(4)/3 1.2*scrsz(3)/1.6457 0.6*scrsz(4)/3.4682])
    figure
    
    for layer=1:model.H
        for dim=1:model.layer{layer}.q
            [X,mu] = hsvargplvmSampleLayer(model,layer,1,-1,dim,[],startingPoint);
            p = QQ*(layer-1)+dim;
            subplot(model.H, QQ,p)
            imagesc(reshape(var(mu), 16,16)')
            axis off
            caxis(max(clAll));
        end
    end
    colormap gray
    %figure('Position',[0.01*scrsz(3) 1.5*scrsz(4)/10 0.17*scrsz(3) 0.5*scrsz(4)])
    figure
    hsvargplvmShowScales(model);
    
    fprintf('... Done! Check figures... Proceeding to next demo... \n\n')
end

%% NN errors: (what matters mainly is the error on the top layer)
disp('#--- NN errors. Press any key to start...'); pause
figure
for h=1:model.H
    % order wrt to the inputScales
    curModel = model.layer{h}.comp{1};
    QQ = length(vargplvmRetainedScales(curModel));%curModel.q;
    if h ~= 1
        curModel.y = model.layer{h-1}.vardist.means;
    end
    curModel.vardist = model.layer{h}.vardist;
    mm = vargplvmReduceModel2(curModel,QQ);
    [mm2, ord ]= vargplvmReduceModel2(curModel,2);
    errors = fgplvmNearestNeighbour(mm, lbls);
    errors2 = fgplvmNearestNeighbour(mm2, lbls);
    % plot the two largest latent dimensions
    ax=subplot(model.H,1,h);
    lvmScatterPlot(mm2, lbls,ax); title(['Layer ' num2str(h) ' (errors:' num2str(errors) ')'])
    fprintf('# Vargplvm errors in the [%d-D | 2-D] projection: [%d | %d]\n', QQ,errors, errors2)
end


%% Visualise the latent space with the images

close all
h = model.H;

curModel = model.layer{h}.comp{1};
if h ~= 1
    curModel.y = model.layer{h-1}.vardist.means;
end
curModel.vardist = model.layer{h}.vardist;
mm2 = vargplvmReduceModel2(curModel,2);
errors2 = fgplvmNearestNeighbour(mm2, lbls);


dataType = 'image';
varargs{1} = [16 16];
varargs{2} = 1;
varargs{3} = 1;
varargs{4} = 1;

visualiseFunction = 'imageVisualise';
axesWidth = 0.03;
Y = Ytr{1};

lvmScatterPlot(mm2, lbls);
% 3rd argument: if we remove overlaps
figure; hsvargplvmStaticImageVisualise(mm2, Y, false, [dataType 'Visualise'], axesWidth, varargs{:});

fprintf('\n\n#--- End of demo!\n')