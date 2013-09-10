function [scales, scalesK] = hsvargplvmRetainedScales(model, thresh, displPlots, displ)

if nargin < 4 || isempty(displ)
    displ = false;
end

if nargin < 3 || isempty(displPlots)
    displPlots = true;
end

if nargin < 2 || isempty(thresh)
    thresh = 0.01;
end


for h=1:model.H
    scalesK{h} = zeros(model.layer{h}.M, model.layer{h}.q);
    scalesAll{h} = zeros(model.layer{h}.M, model.layer{h}.q);
    scalesAllTmp{h} = svargplvmScales('get', model.layer{h});

    for m=1:model.layer{h}.M
        scales{h}{m} = vargplvmRetainedScales(model.layer{h}.comp{m},thresh);
        scalesK{h}(m,scales{h}{m}) = 1;
        scalesAll{h}(m,:) = scalesAllTmp{h}{m};
        scalesAll{h}(m,:) = scalesAll{h}(m,:) / max(scalesAll{h}(m,:)); %% Scale so that 1 is max
    end
end

if displPlots
    for h=1:model.H
        if model.layer{h}.M > 1
            figure
            imagesc(scalesAll{h}); title(['All scales for layer ' num2str(h)]);     set(gca,'XGrid','on')
            figure
            imagesc(scalesK{h}); title(['Binarized scales for layer ' num2str(h)]);     set(gca,'XGrid','on')
        end
    end
end

if displ
    for h=1:model.H
        fprintf('# Layer %d\n', h)
        fprintf(' q  | Scales\n')
        fprintf('------------------\n')
        for q=1:model.layer{h}.M
            fprintf(' %d | %s \n',q,num2str(scales{h}{q}));
        end
        fprintf('\n');
    end
end