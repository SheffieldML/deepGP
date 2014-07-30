function [h, hax, hplot] = hsvargplvmPlotX(model, layer, dims, symb, theta, newFig, classes)
% HSVARGPLVMPLOTX Plot the latent space for a selected layer and selected
% pairs of dimensions
%
% DESC Plot the latent space for a selected layer and selected
% pairs of dimensions
% 
% FORMAT: hsvargplvmPlotX(model, layer, dims, <symb>, <theta>, <newFig>, <classes>)
%
% COPYRIGHT: Andreas C. Damianou, 2013
%
% DEEPGP

if nargin < 7, classes = []; end
if nargin < 6 || isempty(newFig), newFig = true; end
% This argument allows us to rotate a 2-D visualisation by theta degrees
% (rad)
if nargin < 5 || isempty(theta), theta = 0; end % TODO
if nargin < 4 || isempty(symb), symb = '-x';  end
if nargin < 3, error(sprintf('At least three arguments required. Usage:\nhsvargplvmPlotX(model, layer, dims, symb, newFig, theta, classes)')); end
if newFig
    h = figure;
    hax = axes;
else
    h=[]; hax=[];
end
if nargin < 2 || isempty(dims)
    scales = hsvargplvmShowScales(model,0);
    [~,ind]=sort(scales{layer}{1}, 'descend');
    dims = ind(1:2);
end
if length(dims) > 3
    %error('Can only plot two or three dimensions against each other')
    for d=1:length(dims)
        hplot = plot(model.layer{layer}.vardist.means(:, dims(d)), symb); title(['d=' num2str(dims(d))])
        pause
    end
end


hplot = plot_cl(model.layer{layer}.vardist.means, dims, classes, symb);


% switch length(dims)
%     case 1
%         hplot = plot(model.layer{layer}.vardist.means(:, dims(1)), symb);
%     case 2
%         hplot = plot(model.layer{layer}.vardist.means(:,dims(1)), model.layer{layer}.vardist.means(:, dims(2)), symb);
%     case 3
%         hplot = plot3(model.layer{layer}.vardist.means(:,dims(1)), ... 
%             model.layer{layer}.vardist.means(:, dims(2)), ...
%             model.layer{layer}.vardist.means(:, dims(3)), symb); grid on
% end