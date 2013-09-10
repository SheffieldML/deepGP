function [model, gradEvaluations, objEvaluations, grChek] = hsvargplvmOptimise(model, display, iters, varargin)

% HSVARGPLVMOPTIMISE Optimise a deep GP.
% FORMAT
% DESC takes a given deepGP model structure and optimises with
% respect to parameters and latent positions.
% ARG model : the model to be optimised.
% ARG display : flag dictating whether or not to display
% optimisation progress (set to greater than zero) (default value 1).
% ARG iters : number of iterations to run the optimiser
% for (default value 2000).
% RETURN model : the optimised model.
%
% SEEALSO :
%
% COPYRIGHT: Andreas C. Damianou, 2012

% DEEPGP


if nargin < 3
    iters = 2000;
    if nargin < 2
        display = 1;
    end
end

gradEvaluations = 0;
objEvaluations = 0;

options = optOptions;
params = modelExtractParam(model);
if length(varargin) == 2
    if strcmp(varargin{1}, 'gradcheck')
        assert(islogical(varargin{2}));
        %options(9) = varargin{2};
        doGradchek = varargin{2};
        if doGradchek
            [gradient, delta] = feval('gradchek', params, @modelObjective, @modelGradient, model);
            deltaf = gradient - delta;
            d=norm(deltaf - gradient)/norm(gradient + deltaf); %%
            d1=norm(deltaf - gradient,1)/norm(gradient + deltaf,1); %%
            fprintf(1,' Norm1 difference: %d\n Norm2 difference: %d\n',d1,d);
            grChek = {delta, d, d1};
        else
            grChek = [];
        end
    end
end

options(2) = 0.1*options(2);
options(3) = 0.1*options(3);

if display
    options(1) = 1;
    if length(params) <= 100
        options(9) = 1; % gradchek
    end
end
options(14) = iters;

if isfield(model, 'optimiser')
    optim = str2func(model.optimiser);
else
    optim = str2func('scg');
end


if strcmp(func2str(optim), 'optimiMinimize')
    % Carl Rasmussen's minimize function
    params = optim('hsvargplvmObjectiveGradient', params, options, model);
elseif strcmp(func2str(optim), 'scg2')
    % NETLAB style optimization with a slight modification so that an
    % objectiveGradient can be used where applicable, in order to re-use
    % precomputed quantities.
    [params, opt]= optim('hsvargplvmObjectiveGradient', params,  options, 'hsvargplvmGradient', model);
    gradEvaluations = opt(11);
    objEvaluations = opt(10);
else
    % NETLAB style optimization.
    [params, opt] = optim('hsvargplvmObjective', params,  options,  'hsvargplvmGradient', model);
    gradEvaluations = opt(9);
    objEvaluations = opt(10);
end

model = hsvargplvmExpandParam(model, params);

% Check SNR of optimised model
hsvargplvmCheckSNR(hsvargplvmShowSNR(model));
