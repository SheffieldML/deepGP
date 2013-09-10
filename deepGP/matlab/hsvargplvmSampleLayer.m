% Sample points from the vardistr. of the layer "lInp" and find outputs in
% layer "lOut" for the outputs "ind".
function [X, mu, sigma] = hsvargplvmSampleLayer(model, lInp, lOut, ind,  dim,X, startingPoint)

if nargin <7 || isempty(startingPoint)
     % This point will be initially drawn. Then, we will sample and alter
     % only one if its dimensions.
    startingPoint = 1;
end

if nargin < 3 || isempty(lOut)
    lOut = 1;
end

if nargin < 2 || isempty(lInp)
    lInp = model.H;
end

 % -1 means all
if nargin > 3 && ~isempty(ind) && ind == -1
    ind = 1:model.layer{lOut}.M;
elseif nargin < 4 || isempty(ind)
    ind  = 1:model.layer{lOut}.M; 
end

if nargin < 6 || isempty(X)
    Xorig = model.layer{lInp}.vardist.means;
    N = size(Xorig,1);
    xmin = min(Xorig(:,dim));
    xmax = max(Xorig(:,dim));
    df = xmax - xmin;
    xmin = xmin - 4*df/N; % also catch some points before xmin
    xmax = xmax + 4*df/N;
    x = linspace(xmin,xmax, 3*N); % this is the series of changes made in a specific dimension
    X = repmat(Xorig(startingPoint,:), length(x),1); % Just select some initial point
    X(:,dim) = x';
end

%fprintf('# Sampling from layer %d to layer %d for dimension %d...\n', lInp, lOut, dim)


if nargout > 2
    [mu sigma] = hsvargplvmPosteriorMeanVar(model, X, [], lInp, lOut, ind);
else
    mu = hsvargplvmPosteriorMeanVar(model, X, [], lInp, lOut, ind);
end

