function SNR = hsvargplvmShowSNR(model, layers, displ)

if nargin < 3
    displ = true;
end

if nargin < 2 || isempty(layers)
    layers = 1:model.H;
end

for h=layers
    if displ
        fprintf('# SNR Layer %d\n',h)
    end
    for m=1:model.layer{h}.M
        if isfield(model.layer{h}.comp{m}, 'mOrig')
            varY = var(model.layer{h}.comp{m}.mOrig(:));
        else
            varY = var(model.layer{h}.comp{m}.m(:));
        end
        beta = model.layer{h}.comp{m}.beta;
        SNR{h}(m) = varY * beta;
        if displ
            fprintf('    Model %d: %f  (varY=%f, 1/beta=%f)\n', m, SNR{h}(m), varY, 1/beta)
        end
    end
end