function [params, names] = vargplvmExtractParamNoVardist(model)

% VARGPLVMEXTRACTPARAMNOVARDIST Extract a parameter vector from a variational GP-LVM model.
% ignoring the variational distribution. See vargplvmExtractParam.


if nargout > 1
  returnNames = true;
else
  returnNames = false;
end 
params = [];
names = {};



% Inducing inputs
if ~model.fixInducing
    if ~isfield(model, 'learnInducing') || (isfield(model, 'learnInducing') && model.learnInducing)
        params =  [params model.X_u(:)'];
        if returnNames
            for i = 1:size(model.X_u, 1)
                for j = 1:size(model.X_u, 2)
                    X_uNames{i, j} = ['X_u(' num2str(i) ', ' num2str(j) ')'];
                end
            end
            names = {names{:}, X_uNames{:}};
        end
    end
end


% Kernel parameters  
if returnNames
  [kernParams, kernParamNames] = kernExtractParam(model.kern); 
  for i = 1:length(kernParamNames)
    kernParamNames{i} = ['Kernel, ' kernParamNames{i}];
  end
  names = {names{:}, kernParamNames{:}};
else
  kernParams = kernExtractParam(model.kern);
end
params = [params kernParams];


% beta in the likelihood 
if model.optimiseBeta
   
   if ~isstruct(model.betaTransform)
       fhandle = str2func([model.betaTransform 'Transform']);
       betaParam = fhandle(model.beta, 'xtoa');
   else
      if isfield(model.betaTransform,'transformsettings') && ~isempty(model.betaTransform.transformsettings)
          fhandle = str2func([model.betaTransform.type 'Transform']);
          betaParam = fhandle(model.beta, 'xtoa', model.betaTransform.transformsettings);
      else
          error('vargplvmExtractParam: Invalid transform specified for beta.'); 
      end
   end   

   params = [params betaParam(:)'];
   
   if returnNames
     for i = 1:length(betaParam)
       betaParamNames{i} = ['Beta ' num2str(i)];
     end
     names = {names{:}, betaParamNames{:}};
   end
end


