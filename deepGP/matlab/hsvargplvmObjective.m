function f = hsvargplvmObjective(params, model)

% HSVARGPLVMOBJECTIVE Wrapper function for hierarchical var-GP-LVM objective.
% FORMAT
% DESC provides a wrapper function for the varihierarchical var-GP-LVM, it
% takes the negative of the log likelihood, feeding the parameters
% correctly to the model.
% ARG params : the parameters of the variational GP-LVM model.
% ARG model : the model structure in which the parameters are to be
% placed.
% RETURN f : the negative of the log likelihood of the model.
% 
% SEEALSO : hsvargplvmCreate, hsvargplvmLogLikelihood, hsvargplvmExpandParam
%
% COPYRIGHT : Andreas C. Damianoum 2012

% HSVARGPLVM


model = modelExpandParam(model, params);
f = - modelLogLikelihood(model);