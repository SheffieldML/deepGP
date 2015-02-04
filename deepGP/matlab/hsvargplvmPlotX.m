function [h, hax, hplot] = hsvargplvmPlotX(model, layer, dims, symb, theta, newFig, classes, fancyPlot)
% HSVARGPLVMPLOTX Plot the latent space for a selected layer and selected
% pairs of dimensions. 
%
% DESC Plot the latent space for a selected layer and selected
% pairs of dimensions. If the dimensions are not given in the third
% argument (dims), then the two most dominant dimensions will be used.
% 
% FORMAT: hsvargplvmPlotX(model, layer, dims, <symb>, <theta>, <newFig>, <classes>)
%
% COPYRIGHT: Andreas C. Damianou, 2013, 2014
%
% DEEPGP

if nargin < 8  || isempty(fancyPlot), fancyPlot = false; end
if nargin < 7, classes = []; end
if nargin < 6 || isempty(newFig), newFig = true; end
% This argument allows us to rotate a 2-D visualisation by theta degrees
% (rad)
if nargin < 5 || isempty(theta), theta = 0; end % TODO
if nargin < 4 || isempty(symb), symb = '-x';  end
if nargin < 2, error(sprintf('At least three arguments required. Usage:\nhsvargplvmPlotX(model, layer, dims, symb, newFig, theta, classes, fancyPlot)')); end
if newFig
    h = figure;
    hax = axes;
else
    h=[]; hax=[];
end
if nargin < 3 || isempty(dims)
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

if (isempty(classes) || length(dims) > 2) && ~fancyPlot 
    hplot = plot_cl(model.layer{layer}.vardist.means, dims, classes, symb);
else
    if length(dims)~=2
        error('Dims must be 2 for this plot')
    end
    %-----
    if layer ~= 1
        model.layer{layer}.comp{1}.y = model.layer{layer-1}.vardist.means;
    end
    model.layer{layer}.comp{1}.vardist = model.layer{layer}.vardist;
    model.layer{layer}.comp{1}.X = model.layer{layer}.vardist.means;
    %figure; ax = axes;
    if model.layer{layer}.comp{1}.q > 2
        mm = vargplvmReduceModel2(model.layer{layer}.comp{1},2);
        if ~isempty(classes)
            errors = fgplvmNearestNeighbour(mm, classes);
        end
        lvmScatterPlot(mm, classes, hax);
    else
        if ~isempty(classes)
            errors = fgplvmNearestNeighbour(model.layer{layer}.comp{1}, classes);
        end
        lvmScatterPlot(model.layer{layer}.comp{1}, classes, hax);
    end
    if ~isempty(classes)
        title(['Layer ' num2str(layer) ' (errors:' num2str(errors) ')'])
        fprintf('# Errors in the 2-D projection: %d \n', errors)
    else
        title(['Layer ' num2str(layer) ])
    end
    % plot the two largest latent dimensions
    %ax=subplot(model.H,1,h);
    %-----
end


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