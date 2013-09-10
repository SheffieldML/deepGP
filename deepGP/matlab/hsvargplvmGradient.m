function g = hsvargplvmGradient(params, model)

% VARGPLVMGRADIENT Variational GP-LVM gradient wrapper.
% FORMAT
% DESC is a wrapper function for the gradient of the negative log
% likelihood of an variatioanl GP-LVM model with respect to the latent postions
% and parameters.
% ARG params : vector of parameters and latent postions where the
% gradient is to be evaluated.
% ARG model : the model structure into which the latent positions
% and the parameters will be placed.
% RETURN g : the gradient of the negative log likelihood with
% respect to the latent positions and the parameters at the given
% point.
% 
% SEEALSO : vargplvmLogLikeGradients, vargplvmExpandParam
%
% COPYRIGHT : Michalis K. Titsias, 2009 - 2011
%
% COPYRIGHT : Neil D. Lawrence, 2006, 2005, 2010-2011

% VARGPLVM

model = modelExpandParam(model, params);

g = - modelLogLikeGradients(model);

% sum gradients of tied parameters, then assign corresponding summed gradients to each
% group of tied parameters
% if isfield( model, 'ties' )
%     g = g * model.T; % model.T == model.ties' * model.ties;
% end
% fprintf(1,'# G: %.13f\n',sum(abs(g))); %%% DEBUG
%fprintf(1,'# G: %.13f\n', norm(g)); %%% DEBUG (close to convergence this should go -> 0)