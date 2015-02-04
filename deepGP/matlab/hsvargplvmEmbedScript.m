% 
% DESC 
%
% COPYRIGHT: Andreas C. Damianou, 2015
%
% SEE ALSO: 
%
% DEEPGP

%% ------ CONFIGURING THE DEEP GP
%--- Mandatory configurations
if ~exist('Ytr', 'var'), error('You need to specify your outputs in Ytr{1}=...'); end

%--- Optional configurations: Whatever configuration variable is not already set (ie does not exist
% as a variable in the workspace) is set to a default value.
if ~exist('experimentNo','var'), experimentNo = 404; end
if ~exist('K','var'), K = 30; end
if ~exist('Q','var'), Q = 6; end
if ~exist('baseKern','var'), baseKern = 'rbfardjit'; end % {'rbfard2','white','bias'}; end


hsvargplvm_init;


%%
options = hsvargplvmOptions(globalOpt);
options.optimiser = 'scg2';
initXOptions = hsvargplvmInitXOptions(Ytr, options, globalOpt);


% Create a deepGP model, parametrized by its local options, global options
% and options that say how to initialise the latent spaces X
model = hsvargplvmModelCreate(Ytr, options, globalOpt, initXOptions);
%!!!!!!!!!!!!!!!!!!!!!!!!-----------------------
if exist('DEBUG_entropy','var') && DEBUG_entropy
    model.DEBUG_entropy = true;for itmp=1:model.H, model.layer{itmp}.DEBUG_entropy = true; end
end
params = hsvargplvmExtractParam(model); model = hsvargplvmExpandParam(model, params);

%% Optimise deep GP model
model.globalOpt = globalOpt;
[model,modelPruned, modelInitVardist] = hsvargplvmOptimiseModel(model, true, true);

% Uncomment if you decide to train for more iterations later...
%modelOld = model;
%model = hsvargplvmOptimiseModel(model, true, true, [], {0, [1000 1000 1000]});
