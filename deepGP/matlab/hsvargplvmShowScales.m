function scales = hsvargplvmShowScales(model, displ, varargin)
if nargin < 2 || isempty(displ)
    displ = true;
end

% Layers to visualise
layers = model.H:-1:1;

% Do not show individual scales in mult-output
skipComp = false;

if nargin > 2
    if ~isempty(varargin{1}), layers = varargin{1}; end
    if length(varargin) > 2 && ~isempty(varargin{2})
        skipComp = varargin{2};
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
    if model.layer{h}.M > 10 && displ
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
        if displ
            if ~model.multOutput
                subplot(model.H,1,hCount)
            else
                figure
            end
        end
        scales{h} = svargplvmShowScales(model.layer{h}, displ);
        if displ
            title(['Layer ' num2str(h)]);
        end
    end
    
    if model.layer{h}.M > 10 && displ
        bar(scalesAll{h}); title(['Normalised sum of scales for layer ' num2str(h)])
    end
end