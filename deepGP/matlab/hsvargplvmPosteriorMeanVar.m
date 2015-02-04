% This function is used for predicting in the hierarchical model.  
% All intermediate mu and sigma should be returned, (TODO!!!)  or
% the user can give extra arguments to define which outputs to get.

% ARG model: the hsvargplvm model
% ARG X: the test latent points of the TOP layer (parent)
% ARG varX: the variance associated with X. Can be left empty ([])
% ARG lInp: the layer we predict FROM, in the most general case the parent
% ARG lOut: the layer we predict at, ie the prediction is propagated from
% the lInp layer down to this layer.
% ARG ind: If there are multiple output nodes in layer "layer", we predict
% for the node(s) idexed with "ind", ie ind is a vector.

function [mu, varsigma] = hsvargplvmPosteriorMeanVar(model, X, varX, lInp, lOut, ind)

if nargin < 5 || isempty(lOut)
    lOut = 1;
end

if nargin < 4 || isempty(lInp)
    lInp = model.H;
end

 % -1 means all
if nargin > 5 && ~isempty(ind) && ind == -1
    ind = 1:model.layer{lOut}.M;
elseif nargin < 6 || isempty(ind)
    ind  = model.layer{lOut}.M; 
end

if model.layer{lInp}.q ~= size(X,2)
    error('Latent position given has the wrong dimensions!')
end
if nargin < 3 
    varX = [];
end

Xcur = X;
varXcur = varX;
for h=lInp:-1:lOut
    if h == lOut % This if-else is not really needed...
        muPart = []; varxPart = [];
        for m=ind
            % If we reach the layer that we actually want to predict at, then
            % this is our final prediction.
            if isempty(varXcur)
                if nargout > 1
                    [mu, varsigma] = vargplvmPosteriorMeanVarHier(model.layer{h}.comp{m}, Xcur);
                    varxPart = [varxPart varX];
                else
                    mu = vargplvmPosteriorMeanVarHier(model.layer{h}.comp{m}, Xcur);
                end
                muPart = [muPart mu];
            else
                if nargout > 1
                    [mu,varsigma] = vargplvmPosteriorMeanVarHier(model.layer{h}.comp{m}, Xcur, varXcur);
                     varxPart = [varxPart varX];
                else
                    mu = vargplvmPosteriorMeanVarHier(model.layer{h}.comp{m}, Xcur, varXcur);
                end
                muPart = [muPart mu];
            end
        end
        mu = muPart;
        if nargout > 1
            varX = varxPart;
        end
    else
        % If this is just an intermediate node until the layer we want to
        % reach at, then we have to go through all the submodels in the
        % current layer, predict in each one of them and join the
        % predictions into a single output which now becomes the input for
        % the next level.
        muPart = []; varxPart = [];
        for m=1:model.layer{h}.M
            if isempty(varXcur)
                if nargout > 1
                    [mu, varx] = vargplvmPosteriorMeanVarHier(model.layer{h}.comp{m}, Xcur);
                    varxPart = [varxPart varX];
                else
                    mu = vargplvmPosteriorMeanVarHier(model.layer{h}.comp{m}, Xcur);
                end
                muPart = [muPart mu];
            else
                if nargout > 1
                    [mu, varX] = vargplvmPosteriorMeanVarHier(model.layer{h}.comp{ind}, Xcur, varXcur);
                    varxPart = [varxPart varX];
                else
                     mu = vargplvmPosteriorMeanVarHier(model.layer{h}.comp{ind}, Xcur, varXcur);
                end
                muPart = [muPart mu];
            end
        end
        Xcur = muPart;
        varXcur = varxPart;
    end
end


% Some dimensions might be not learned but nevertheless required as an
% output so that the dimensions are right (e.g. hsvargplvmClassVisualise).
% In that case, just pad these dims. with zeros
if isfield(model, 'zeroPadding') && ~isempty(model.zeroPadding)
     muNew = zeros(size(mu,1), length(model.zeroPadding.rem)+length(model.zeroPadding.keep));
     muNew(:, model.zeroPadding.keep) = mu;
     mu = muNew;
end






