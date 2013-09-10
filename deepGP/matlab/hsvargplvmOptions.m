
% See also: hsvargplvm_init

function [options, optionsDyn] = hsvargplvmOptions(globalOpt, timeStampsTraining, labelsTrain)

if nargin < 2
    timeStampsTraining = [];
end

if nargin < 3
    labelsTrain = [];
end

%-- One options structure where there are some parts shared for all
% models/layers and some parts specific for a few layers / submodels.


options = vargplvmOptions('dtcvar');

% Taken from globalOpt
options.H = globalOpt.H;
options.baseKern = globalOpt.baseKern;
options.Q = globalOpt.Q;
options.K = globalOpt.K;
options.enableDgtN = globalOpt.DgtN;
options.initial_X = globalOpt.initial_X;
options.initX = globalOpt.initX;
options.multOutput = globalOpt.multOutput;
if options.multOutput > 2
    warning('Multoutput > 2 has wrong derivatives!!')
end
% 
options.optimiser = 'scg2';



% !!!!! Be careful to use the same type of scaling and bias for all models!!!
% scale = std(Ytr);
% scale(find(scale==0)) = 1;
%options.scaleVal = mean(std(Ytr));
% options.scaleVal = sqrt(var(Ytr{i}(:))); %%% ??
options.scale2var1 = globalOpt.scale2var1;

options.fixInducing = globalOpt.fixInducing;

%----- Parent prior (we call priors "dynamics", but it can actually be some
% other type of prior, eg labels etc.). 
% The relevant fields of globalOpt are coming from the svargplvm_init
% (called within hsvargplvm_init).
if isempty(globalOpt.dynamicsConstrainType) || nargout < 2
    optionsDyn = [];
else
    if ~isempty(labelsTrain)
        optionsDyn.labelsTrain = labelsTrain;
    end
    % This does not mean it needs time inputs, it's just saying that it'll
    % use the kernel types and reparametrization used in VGPDS (regressive
    % "dynamics" etc).
    optionsDyn.type = 'vargpTime';
    optionsDyn.inverseWidth=30;
    optionsDyn.vardistCovars = globalOpt.vardistCovarsMult;
    if iscell(globalOpt.initX)
        optionsDyn.initX = globalOpt.initX{end};
    else
        optionsDyn.initX = globalOpt.initX;
    end
    optionsDyn.constrainType = globalOpt.dynamicsConstrainType;
    if ~isempty(timeStampsTraining)
        optionsDyn.t = timeStampsTraining;
    end
    optionsDyn.kern = globalOpt.dynamicKern;
end


