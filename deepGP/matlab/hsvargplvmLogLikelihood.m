function ll = hsvargplvmLogLikelihood(model)

F_leaves = hsvargplvmLogLikelihoodLeaves(model.layer{1});
F_nodes = hsvargplvmLogLikelihoodNode(model);
F_entropies = hsvargplvmLogLikelihoodEntropies(model);
% This refers to the KL quantity of the top node. The likelihood part is
% computed in hsvargplvmLogLikelihoodNode.
F_parent = hsvargplvmLogLikelihoodParent(model.layer{model.H});

ll = F_leaves + F_nodes + F_entropies + F_parent;

end

% The ln p(Y|X) terms
function F_leaves = hsvargplvmLogLikelihoodLeaves(modelLeaves)

F_leaves = 0;
for m=1:modelLeaves.M
    modelLeaves.comp{m}.onlyLikelihood = true;
    F_leaves = F_leaves + vargplvmLogLikelihood(modelLeaves.comp{m});
end
end

% The <ln p(X_h | X_{h-1})>_{q(X_{h-1}} nodes
function F_nodes = hsvargplvmLogLikelihoodNode(model)
F_nodes = 0;
for h=2:model.H
    % It's just like the leaves computation, the only difference is the
    % trace(Y*Y') term which now is replaced by an expectation w.r.t the
    % latent space of the previous layer. However, this replacement is done
    % in hsvargplvmUpdateStats and we dont have to worry here about it
    F_nodes = F_nodes + hsvargplvmLogLikelihoodLeaves(model.layer{h});
end

end

% The H_{q(X_h)} nodes, h ~= H
function F_entropies = hsvargplvmLogLikelihoodEntropies(model)
F_entropies = 0;
for h=1:model.H-1
    vardist = model.layer{h}.vardist;
    F_entropies = F_entropies - 0.5*(vardist.numData*vardist.latentDimension* ...
            (log(2*pi) + 1) + sum(sum(log(vardist.covars))));
end

end

% The -KL[q(X_H) || p(X_H)]
function F_parent = hsvargplvmLogLikelihoodParent(modelParent)
%if modelParent.M > 1
%    warning('Not implemented multiple models in parent node yet')
%end
% Copied from vargplvmLogLikelihood:
if isfield(modelParent, 'dynamics') & ~isempty(modelParent.dynamics)
        % A dynamics model is being used.
        F_parent = modelVarPriorBound(modelParent);
        F_parent = F_parent + 0.5*modelParent.q*modelParent.N; %%% The constant term!!
else
    varmeans = sum(sum(modelParent.vardist.means.*modelParent.vardist.means));
    varcovs = sum(sum(modelParent.vardist.covars - log(modelParent.vardist.covars)));
    F_parent = -0.5*(varmeans + varcovs) + 0.5*modelParent.q*modelParent.N;
end
end