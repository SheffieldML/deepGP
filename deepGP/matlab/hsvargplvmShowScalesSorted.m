function scales = hsvargplvmShowScalesSorted(model)
for h=1:model.H
    scalesAll{h} = zeros(1, model.layer{h}.q);
    subplot(model.H,1,h)
    scales{h} = vargplvmShowScales(model.layer{h}.comp{1},0);
    %scales{h} = sort(scales{h},'descend');
    scales{h} = scales{h} ./ max(scales{h});
    bar([scales{h} NaN*ones(1,15-length(scales{h}))])
    set(gca, 'XTickLabelMode', 'manual', 'XTickLabel', []);
    set(gca, 'YTickLabelMode', 'manual', 'YTickLabel', []);
    
    %title(['Layer ' num2str(h)]);
end
