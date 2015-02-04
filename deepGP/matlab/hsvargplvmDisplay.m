% HSVARGPLVMDISPLAY Display as a text a deepGP model
% COPYRIGHT: Andreas C. Damianou, 2014
% SEEALSO: modelDisplay.m

function hsvargplvmDisplay(model)

fprintf('# Model type: %s\n', model.type)
fprintf('# Mapping kernels:\n')
for i = 1:length(model.layer)
    for j = 1:length(model.layer{i}.comp)
        fprintf('  Layer %d modality %d:\n', i,j);
        kernDisplay(model.layer{i}.comp{j}.kern,6);
    end
end
fprintf('# Number of inducing points:\n');
for i = 1:length(model.layer)
    for j = 1:length(model.layer{i}.comp)
        if model.layer{i}.comp{j}.fixInducing
            tmp = ' (Tied to X)';
        else
            tmp = '';
        end
         fprintf('  Layer %d modality %d: %d%s\n', i,j, model.layer{i}.comp{j}.k,tmp);
    end
end
fprintf('# SNR:\n');
SNRs=hsvargplvmShowSNR(model,1:model.H,0);
for i = 1:length(model.layer)
    for j = 1:length(model.layer{i}.comp)
       if model.layer{i}.comp{j}.initVardist
            tmp = ' (Fixed)';
        else
            tmp = '';
        end
         fprintf('  Layer %d modality %d: %.5f%s\n', i,j, SNRs{i}(j), tmp);
    end
end

fprintf('# D >> N mode activated:\n');
for i = 1:length(model.layer)
    for j = 1:length(model.layer{i}.comp)
        if model.layer{i}.comp{j}.DgtN
            tmp = 'Yes';
        else
            tmp = 'No';
        end
         fprintf('  Layer %d modality %d: %s\n', i,j, tmp);
    end
end

if isfield(model.layer{end}, 'dynamics') && ~isempty(model.layer{end}.dynamics)
    fprintf('# -- Dynamics --\n')
    constr = model.layer{end}.dynamics.constrainType{1};
    for ii = 2:length(model.layer{end}.dynamics.constrainType)
        constr = [constr ' ' model.layer{end}.dynamics.constrainType{ii}];
    end
    fprintf('# constrainType: %s\n', constr);
    fprintf('# Top layer kernel:\n')
    kernDisplay(model.layer{end}.dynamics.kern, 4);
end
fprintf('# (Approximate) log. marginal likelihood: %.3f\n',hsvargplvmLogLikelihood(model))

