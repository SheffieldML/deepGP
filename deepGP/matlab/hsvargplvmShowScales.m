function scales = hsvargplvmShowScales(model, displ, varargin)
if nargin < 2 || isempty(displ)
    displ = true;
end

% Layers to visualise
layers = model.H:-1:1;

% Do not show individual scales in mult-output
skipComp = false;

displayAsMatrix = false; 

if nargin > 2
    if ~isempty(varargin{1}), layers = varargin{1}; end
    if length(varargin) > 1 && ~isempty(varargin{2})
        skipComp = varargin{2};
    end
    if length(varargin) > 2 && ~isempty(varargin{3})
        displayAsMatrix = varargin{3};
    end
end

%{
if ~model.multOutput
    for h=1:model.H
        if displ
            subplot(model.H,1,h)
        end
        vargplvmShowScales(model.layer{h}.comp{1},displ); title(num2str(h));
    end
    return
end
%}

for hCount=1:length(layers)
    h = layers(hCount);
    scalesAll{h} = zeros(1, model.layer{h}.q);
    if model.layer{h}.M > 10 && displ && ~displayAsMatrix
        for i=1:model.layer{h}.M
            sc = vargplvmShowScales(model.layer{h}.comp{i}, ~skipComp);
            scalesAll{h} = scalesAll{h} + sc;
            if ~skipComp
                title(['Scales for layer ' num2str(h) ', model ' num2str(i)])
                pause
            end
        end
        scalesAll{h} = scalesAll{h} ./ max(scalesAll{h});
    else
        if displ && ~displayAsMatrix
            if ~model.multOutput
                subplot(model.H,1,hCount)
            else
                figure
            end
        end
        scales{h} = svargplvmShowScales(model.layer{h}, (displ && ~displayAsMatrix));
        if displ && ~displayAsMatrix
            title(['Layer ' num2str(h)]);
        end
        if model.layer{h}.M < 2
            scalesAll{h} = scales{h}{1};
            scalesAll{h} = scalesAll{h} ./ max(scalesAll{h});
        end
    end
    
    if model.layer{h}.M > 10 && displ && ~displayAsMatrix
        bar(scalesAll{h}); title(['Normalised sum of scales for layer ' num2str(h)])
    end
end

if displayAsMatrix
    maxQ = length(scalesAll{1});
    for h = 2:model.H
        if length(scalesAll{h}) > maxQ
            maxQ = length(scalesAll{h});
        end
    end
    
    scalesAllMat = zeros(model.H, maxQ);
    for hh = 1:model.H
        %h = hh;             % This will put layer 1 on top
        h = model.H - hh +1; % This will put layer H on top
        for q = 1:maxQ
            if q <= length(scalesAll{hh})
                scalesAllMat(h,q) = scalesAll{hh}(q);
            else
                scalesAllMat(h,q) = NaN;
            end
        end
    end
    h=imagesc(scalesAllMat);
    set(h,'alphadata',~isnan(scalesAllMat))
    colorbar
end