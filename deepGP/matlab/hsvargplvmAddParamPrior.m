function model = hsvargplvmAddParamPrior(model, h, m, paramName, priorName, varargin)
% HSVARGPLVMADDPARAMPRIOR Add a prior on some of the parameters of the
% model
% 
% DESC The objective function of the model can be written (in the log space) as
% F = F_likelihood + F_prior, where the F_likelihood term tries to fit the
% data and the F_prior term includes our prior assumptions/biases. The
% current function allows to incorporate prior distributions on some of the
% parameters of the model. Check hsvargplvmTestPrior.m for a tutorial on
% how to do that. The current function is a wrapper for vargplvmAddParamPrior.m
%
% ARG model:     The deep GP (hsvargplvm) model for which to add the prior
% ARG h:         Which layer of the model is receiving the prior
% ARG m:         Which modality of the h-th layer to receive the prior (currently
%                only m=1)
% ARG paramName: The name of the parameter to receive the prior. Check
%                vargplvmAddParamPrior to see the names; the names are same as returned
%                from [~,names]=hsvargplvmExtractParam(model), and a regexp is used to
%                match the given name.
% ARG priorName: The name of the prior to use. Check the availability of
%                <name>PriorLogProb.m functions to see which priors are implemented. 
% ARG varargin:  Any arguments needed for the specific constructor of the
%                prior are going to be pased.
%
% SEEALSO: vargplvmAddParamPrior.m, hsvargplvmTestPrior.m
%
% COPYRIGHT: Andreas Damianou, 2015
% DEEPGP

if m > 1
    error('Not tested for m > 1 yet')
end

    
model.layer{h}.comp{m}.vardist = model.layer{h}.vardist;
model.layer{h}.comp{m} = vargplvmAddParamPrior(model.layer{h}.comp{m}, paramName,priorName, varargin{:});
model.layer{h}.comp{m} = rmfield(model.layer{h}.comp{m}, 'vardist');

% If there are dynamics, the prior index needs fixing
model.layer{h}.comp{m}.paramPriors{end}.index = model.layer{h}.comp{m}.paramPriors{end}.index + model.layer{end}.dynamics.kern.nParams;