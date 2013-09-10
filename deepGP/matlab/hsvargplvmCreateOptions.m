
% Some options are given in globalOpt as cell arrays, some are given as
% single values, meaning that they be propagated for each layer. This
% function builds a complete struct with options. After this function is
% run, the field options will have a 2-D cell array:
% options.F{h}{m}
% for every field F which changes according to the layer and h indexes
% layers and m indexes subsets of latent spaces (has to be there, even if
% at layer h there is only a single space, we would have a single cell, ie 
% F{h}{1} 
function options = hsvargplvmCreateOptions(Ytr, options, globalOpt)

% Q
if ~iscell(options.Q)
    Q = options.Q;
    options = rmfield(options, 'Q');
    
    for h=1:options.H
        options.Q{h} = Q;
    end
end
    
% initX 
if ~iscell(options.initX)
    initX = options.initX;
    
    options = rmfield(options, 'initX');
    for h=1:options.H
        options.initX{h} = initX;
    end
end


% K and M
if ~iscell(Ytr)
    Ytr = {Ytr};
end

options.Kold = options.K;
options = rmfield(options, 'K');

M{1} = length(Ytr);
N = size(Ytr{1},1);
for h=1:options.H
    for m = 1:M{h}
        if ~iscell(options.Kold)
            options.K{h}{m} = options.Kold;
        end
        if options.K{h}{m} == -1
            options.K{h}{m} = N;
        end
    end
    if h ~= options.H
        if options.multOutput > h + 1
            M{h+1} = options.Q{H};
        else
            M{h+1} = 1;
        end
    end
end
options.M = M;
options = rmfield(options, 'Kold');



% kern, SNR
%if isfield(options, 'kern')
    options = rmfield(options, 'kern');
%end
for h=1:options.H
    for m=1:options.M{h}
        % Kern
        if iscell(options.baseKern) && iscell(options.baseKern{1})
            options.kern{h}{m} = globalOpt.baseKern{h}{m}; %{'rbfard2', 'bias', 'white'};
        else
            options.kern{h}{m} = globalOpt.baseKern;
        end
        
        if isfield(globalOpt, 'inputScales') && ~isempty(globalOpt.inputScales)
            options.inpScales{h} = globalOpt.inputScales;
        end
        
                
        
        %SNR
        if iscell(globalOpt.initSNR)
            options.initSNR{h} = globalOpt.initSNR{h};
        else
            options.initSNR{h} = globalOpt.initSNR;
        end
    end
end
%options.baseKern = options.kern; % Unecessary...


