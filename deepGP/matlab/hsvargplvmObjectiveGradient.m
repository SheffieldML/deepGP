function [f, g] = hsvargplvmObjectiveGradient(params, model)

% SVARGPLVMOBJECTIVEGRADIENT Wrapper function for shared VARGPLVM objective and gradient.
% FORMAT
% DESC returns the negative log likelihood of a Gaussian process
% model given the model structure and a vector of parameters. This
% allows the use of NETLAB minimisation functions to find the model
% parameters.
% ARG params : the parameters of the model for which the objective
% will be evaluated.
% ARG model : the model structure for which the objective will be
% evaluated.
% RETURN f : the negative log likelihood of the SVARGPLVM model.
% RETURN g : the gradient of the negative log likelihood of the SVARGPLVM
% model with respect to the parameters.
%
% SEEALSO : minimize, svargplvmModelCreate, svargplvmGradient, svargplvmLogLikelihood, svargplvmOptimise
% 
% COPYRIGHT :  Andreas C. Damianou, 2011

% SVARGPLVM
  
% Check how the optimiser has given the parameters
if size(params, 1) > size(params, 2)
  % As a column vector ... transpose everything.
  transpose = true;
  model = hsvargplvmExpandParam(model, params');
else
  transpose = false;
  model = hsvargplvmExpandParam(model, params);
end

f = - hsvargplvmLogLikelihood(model);
% fprintf(1,'# F: %.13f\n',f); %%% DEBUG
if nargout > 1
  g = - hsvargplvmLogLikeGradients(model);
%  fprintf(1,'# G: %.13f .\n',sum(abs(g))); %%% DEBUG
end
if transpose
  g = g';
end

