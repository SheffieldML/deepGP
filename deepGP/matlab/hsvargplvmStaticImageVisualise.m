%{
dataType = 'image';
varargs{1} = [16 16];
varargs{2} = 1;
varargs{3} = 1;
varargs{4} = 1;
hsvargplvmStaticImageVisualise(mm2, Y, [dataType 'Visualise'], 0.03, varargs{:});

varargin = varargs;
visualiseFunction = 'imageVisualise';
axesWidth = 0.03;
Y = Ytr{1};
%}



function hsvargplvmStaticImageVisualise(mm2, Y, remPoints, visualiseFunction, axesWidth, varargin)

% GPLVMSTATICIMAGEVISUALISE Generate a scatter plot of the images without overlap.

% GPLVM 

% set random seeds
randn('seed', 1e5)
rand('seed', 1e5)

colordef white 


if isempty(remPoints)
    remPoints = true;
end

% Turn Y into grayscale
try
    [plotAxes, data] = gplvmScatterPlot(mm2, []);
catch e
    [plotAxes, data] = lvmScatterPlotNoVar2(mm2, []);
end

xLim = get(plotAxes, 'xLim');
yLim = get(plotAxes, 'yLim');
posit = get(plotAxes, 'position');

widthVal = axesWidth*(xLim(2) - xLim(1))/posit(3);
heightVal = axesWidth*(yLim(2) - yLim(1))/posit(4);
numData = size(mm2.X, 1);

visitOrder = randperm(numData);
initVisitOrder = visitOrder;

% Plot the images
while ~isempty(visitOrder)
  i = visitOrder(1);
  if mm2.X(i, 1) > xLim(1) & mm2.X(i, 1) < xLim(2) ...
    & mm2.X(i, 2) > yLim(1) & mm2.X(i, 2) < yLim(2)
    point = invGetNormAxesPoint(mm2.X(i, :), plotAxes);
    x = point(1);
    y = point(2);
    
    digitAxes(i) =  axes('position', ...
			 [x - axesWidth/2 ...
		    y - axesWidth/2 ...
		    axesWidth ...
		    axesWidth]);
    handle = feval(visualiseFunction, Y(i, :), varargin{:});
    colormap gray
    axis image
    axis off
    
    widthLimScale = 2.6; % ORIG: 2
    heightLimScale = 1.5; % Orig: 1
    if remPoints
        removePoints = find(abs(mm2.X(visitOrder, 1) - mm2.X(i, 1)) < widthVal/widthLimScale ...
            &  abs(mm2.X(visitOrder, 2) - mm2.X(i, 2)) < heightVal/heightLimScale);
        visitOrder(removePoints) = [];
    else
        removePoints = find(abs(mm2.X(visitOrder, 1) - mm2.X(i, 1)) < widthVal/50 ...
            &  abs(mm2.X(visitOrder, 2) - mm2.X(i, 2)) < heightVal/50);
        visitOrder(removePoints) = [];
    end
  else
    visitOrder(1) = [];
  end
end
set(plotAxes, 'xlim', xLim);
set(plotAxes, 'ylim', yLim);
set(data, 'visible', 'off');
%ticks = [-4 -2 0 2 4];
%set(plotAxes, 'xtick', ticks)
%set(plotAxes, 'ytick', ticks)
