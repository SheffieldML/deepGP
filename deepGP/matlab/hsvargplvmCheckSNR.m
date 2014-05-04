function warnings = hsvargplvmCheckSNR(SNR, errLimit, warLimit, throwError)
% HSVARGPLVMCHECKSNR Check Signal to Noise Ratio after
% optimisation, to ensure that the trivial local minimum
% of learning only noise is avoided.
% DESC Check SNR of optimised model
% FORMAT 
% ARG SNR: the SNR of optiomised model
% ARG errLimit: Optional, the limit below which an error message
% is printed
% ARG warLimit: Optional, the limit below which a warning message
% is printed
% RETURN warnings as strings pairs (layer, modality) for these pairs that
% the SNR is low enough to be considered a warning.
%
% COPYRIGHT: Andreas C. Damianou, 2013
%
% DEEPGP

if nargin < 4 || isempty(throwError), throwError = true; end 
if nargin < 3 || isempty(warLimit), warLimit = 10; end
if nargin < 2 || isempty(errLimit), errLimit = 2; end
if nargin < 1, error('Not enough arguments given'); end

errStr = sprintf(['\nThis means that a bad local minimum has been reached\n', ...
 'where everything is explained by noise. Please try a different\n', ...
 'initialisation and/or consult the manual.\n']);
warStr = sprintf(['\nThis means that a bad local minimum has been reached\n', ...
 'where everything is explained by noise. Consider trying a different\n', ...
 'initialisation and/or consult the manual.\n']);

errors = [];
warnings = [];
for i = 1:length(SNR)
    for j = 1:length(SNR{i})
        if ~isempty(SNR{i}(j)) && SNR{i}(j) <= errLimit
            errors = [errors '(' num2str(i) ',' num2str(j) ') '];
            fprintf(1, 'SNR: Layer %d, modality %d: %f', i, j, SNR{i}(j))
        end
    end
end

if ~isempty(errors)
    errMsg = 'Error! Low SNR in (layer/modality) pairs: ';
    if throwError
        errMsg = [errMsg errors];
        errMsg = [errMsg errStr];
        error(errMsg);
    end
else
    for i = 1:length(SNR)
        for j = 1:length(SNR{i})
            if ~isempty(SNR{i}(j)) && SNR{i}(j) <= warLimit
                warnings = [warnings '(' num2str(i) ',' num2str(j) ') '];
            end
        end
    end
end

if ~isempty(warnings)
    warMsg = 'WARNING! Low SNR in (layer/modality) pairs: ';
    warMsg = [warMsg warnings];
    warMsg = [warMsg warStr];
    warning(warMsg);
end