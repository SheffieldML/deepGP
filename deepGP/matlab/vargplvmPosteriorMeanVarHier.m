% The same as vargplvmPosteriorMeanVar, but a small change in the
% calculations involving model.m, because in the indermediate layers
% model.m is replaced by the expectation varmu*varmu'+Sn wrt the X of the
% bottom layer.
% SEEALSO: hsvargplvmPosteriorMeanVar
function [mu, varsigma] = vargplvmPosteriorMeanVarHier(model, X, varX)



if nargin < 3
  vardistX.covars = repmat(0.0, size(X, 1), size(X, 2));%zeros(size(X, 1), size(X, 2));
else
  vardistX.covars = varX;
end
vardistX.latentDimension = size(X, 2);
vardistX.numData = size(X, 1);
%model.vardist.covars = 0*model.vardist.covars; 
vardistX.means = X;
%model = vargplvmUpdateStats(model, model.X_u);


Ainv = model.P1' * model.P1; % size: NxN

if ~isfield(model,'alpha')
    if isfield(model, 'mOrig')
        model.alpha = Ainv*model.Psi1'*model.mOrig; % size: 1xD
    else
        model.alpha = Ainv*model.Psi1'*model.m; % size: 1xD
    end
end
Psi1_star = kernVardistPsi1Compute(model.kern, vardistX, model.X_u);

% mean prediction 
mu = Psi1_star*model.alpha; % size: 1xD

if nargout > 1
   % 
   % precomputations
   vard = vardistCreate(zeros(1,model.q), model.q, 'gaussian');
   Kinvk = (model.invK_uu - (1/model.beta)*Ainv);
   %
   for i=1:size(vardistX.means,1)
      %
      vard.means = vardistX.means(i,:);
      vard.covars = vardistX.covars(i,:);
      % compute psi0 term
      Psi0_star = kernVardistPsi0Compute(model.kern, vard);
      % compute psi2 term
      Psi2_star = kernVardistPsi2Compute(model.kern, vard, model.X_u);
    
      vars = Psi0_star - sum(sum(Kinvk.*Psi2_star));
      
      for j=1:model.d
         %[model.alpha(:,j)'*(Psi2_star*model.alpha(:,j)), mu(i,j)^2]
         varsigma(i,j) = model.alpha(:,j)'*(Psi2_star*model.alpha(:,j)) - mu(i,j)^2;  
      end
      varsigma(i,:) = varsigma(i,:) + vars; 
      %
   end
   % 
   if isfield(model, 'beta')
      varsigma = varsigma + (1/model.beta);
   end
   %
end
      
% Rescale the mean
mu = mu.*repmat(model.scale, size(vardistX.means,1), 1);

% Add the bias back in
mu = mu + repmat(model.bias, size(vardistX.means,1), 1);

% rescale the variances
if nargout > 1
    varsigma = varsigma.*repmat(model.scale.*model.scale, size(vardistX.means,1), 1);
end
  