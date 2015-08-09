% Add a prior on the beta parameter to avoid low Signal to Noise Ratio
% problems.
function model = hsvargplvmControlSNR(model, meanSNR, layer, view, priorInfo, priorScale)

if nargin < 1, error('At least one argument needed!'); end
if nargin < 6, priorScale = 25; end
if nargin < 5, priorInfo = []; end
if nargin < 4 || isempty(view), view = 1; end
if nargin < 3 || isempty(layer), layer = model.H; end
% Where I want the expected value of my inv gamma if it was on SNR
if nargin < 2 || isempty(meanSNR), meanSNR = 150; end

if isempty(priorInfo)
    priorInfo.name = 'invgamma'; % What type of prior
    varData = var(model.layer{layer}.comp{view}.mOrig(:));
    meanB = meanSNR./varData;
    a=0.08;%1.0001; % Relatively large right-tail
    b=meanB*(a+1); % Because mode = b/(a-1)
    priorInfo.params = [a b];
end

model = hsvargplvmAddParamPrior(model, layer, 1, 'beta', priorInfo.name, priorInfo.params);
if ~isempty('priorScale')
    model.layer{layer}.comp{view}.paramPriors{1}.prior.scale = priorScale;
end
