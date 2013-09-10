function lvmVisualiseHierarchical(model, YLbls, ...
			visualiseFunction, visualiseModify, showVariance, varargin)

% LVMVISUALISEGENERAL Visualise the manifold.
% This is a copy of lvmVisualise where the classVisualise function depends on the
% model type. Additionally, there is a flag showVariance which, when set to
% false, does not plot the variance of the inputs in the scatter plot,
% something which saves a lot of computational time for high-dimensional
% data.
%
% SEEALSO : lvmVisualise, lvmClassVisualise, lvmScatterPlot,
% lvmScatterPlotNoVar
%

% MLTOOLS

global visualiseInfo

visualiseInfo.showVariance = showVariance;

visualiseInfo.activeLayer = 1;
for i = 1:model.numLayers
    hierarchicalScatterPlot(model.layer{i}, i, YLbls, showVariance);
end



% Now the data figure (skeleton, image, etc)

figure(model.numLayers + 1)
clf

if length(visualiseFunction)>4 & strcmp(visualiseFunction(1:5), 'image') & length(varargin)>0
  set(gcf, 'menubar', 'none')
  xPixels = 115;
  yPixels = 115;
  set(gcf, 'position', [232 572 xPixels yPixels/varargin{1}(1)*varargin{1}(2)])
  visualiseInfo.comp{1}.visualiseAxes = subplot(1, 1, 1);
  xWidth = varargin{1}(1)/xPixels;
  yHeight = varargin{1}(2)/yPixels;
  set(visualiseInfo.comp{1}.visualiseAxes, 'position', [0.5-xWidth/2 0.5-yHeight/2 xWidth yHeight])
else
  visualiseInfo.comp{1}.visualiseAxes =subplot(1, 1, 1);
end
visData = zeros(1,model.layer{1}.numModels);
if(length(visualiseFunction)>4 & strcmp(visualiseFunction(1:5), 'image'))
  visData(1) = min(min(model.layer{1}.y));
  visData(end) = max(max(model.layer{1}.y));
else
  [void, indMax]= max(sum((model.layer{1}.y.*model.layer{1}.y), 2));
  visData = model.layer{1}.y(indMax, :);
end

set(get(visualiseInfo.comp{1}.visualiseAxes, 'title'), 'string', 'Y', 'fontsize', 30);
set(visualiseInfo.comp{1}.visualiseAxes, 'position', [0.05 0.05 0.9 0.8]);

visualiseInfo.comp{1}.visualiseFunction = str2func(visualiseFunction);
visHandle = visualiseInfo.comp{1}.visualiseFunction(visData, varargin{:});
set(visHandle, 'erasemode', 'xor')

% Pass the data to visualiseInfo
% visualiseInfo.model = model;
visualiseInfo.comp{1}.varargin = varargin;
visualiseInfo.comp{1}.visualiseModify = str2func(visualiseModify);
visualiseInfo.comp{1}.visHandle = visHandle;


hold off


function hierarchicalScatterPlot(model, curLayer, YLbls, showVariance)
global visualiseInfo


%lvmClassVisualiseFunc = [model.type 'ClassVisualise'];
lvmClassVisualiseFunc = ['stackedvargplvm' 'ClassVisualise'];
if ~exist(lvmClassVisualiseFunc)
    lvmClassVisualiseFunc = 'lvmClassVisualise';
end


figure(curLayer)
clf
visualiseInfo.comp{curLayer}.dim1 = 1;
visualiseInfo.comp{curLayer}.dim2 = 2;
visualiseInfo.comp{curLayer}.latentPos = zeros(1, model.q);
visualiseInfo.comp{curLayer}.model = model;
visualiseInfo.comp{curLayer}.lbls = YLbls;
if showVariance
    visualiseInfo.comp{curLayer}.plotAxes = lvmScatterPlot(model, YLbls);
else
    visualiseInfo.comp{curLayer}.plotAxes = lvmScatterPlotNoVar(model, YLbls);
end

if showVariance
    lvmSetPlot;
else
    hierSetPlotNoVar(lvmClassVisualiseFunc, curLayer);
end
visualiseInfo.comp{curLayer}.latentHandle = line(0, 0, 'markersize', 20, 'color', ...
                                  [0 0 0], 'marker', '.', 'visible', ...
                                  'on', 'erasemode', 'xor');

visualiseInfo.comp{curLayer}.clicked = 0;
visualiseInfo.comp{curLayer}.digitAxes = [];
visualiseInfo.comp{curLayer}.digitIndex = [];

visualiseInfo.comp{curLayer}.dynamicsRadio = ...
    uicontrol('Style', 'radiobutton', ...
              'String', 'Run Dynamics', ...
              'units', 'normalized', ...
              'position', [0 0 0.2 0.05], ...
              'Callback', [lvmClassVisualiseFunc '(''toggleDynamics'')'], ...
              'value', 0);

visualiseInfo.comp{curLayer}.dynamicsSlider = ...
    uicontrol('Style', 'slider', ...
              'String', 'Time', ...
              'sliderStep', [0.01, 0.1], ...
              'units', 'normalized', ...
              'position', [0 0.95 1 0.05], ...
              'callback', [lvmClassVisualiseFunc '(''dynamicsSliderChange'')']);

if ~isfield(model, 'dynamics') | isempty(model.dynamics)
  set(visualiseInfo.comp{curLayer}.dynamicsRadio, 'visible', 'off');
  set(visualiseInfo.comp{curLayer}.dynamicsSlider, 'visible', 'off');
else
  if ~isfield(model.dynamics, 'dynamicsType') 
    set(visualiseInfo.comp{curLayer}.dynamicsRadio, 'visible', 'on');
    set(visualiseInfo.comp{curLayer}.dynamicsSlider, 'visible', 'off');
  else
    switch model.dynamics.dynamicsType
     case 'regressive'
      set(visualiseInfo.comp{curLayer}.dynamicsRadio, 'visible', 'off');
      set(visualiseInfo.comp{curLayer}.dynamicsSlider, 'visible', 'on');
      set(visualiseInfo.comp{curLayer}.dynamicsSlider, 'min', min(model.dynamics.X), ...
                        'max', max(model.dynamics.X), ...
                        'value', model.dynamics.X(1))
     case 'auto-regressive'
      set(visualiseInfo.comp{curLayer}.dynamicsRadio, 'visible', 'on');
      set(visualiseInfo.comp{curLayer}.dynamicsSlider, 'visible', 'off');
    end
  end
end
visualiseInfo.comp{curLayer}.runDynamics = false;

% Set the callback function
set(gcf, 'WindowButtonMotionFcn', [lvmClassVisualiseFunc '(' '''move''' ',' num2str(curLayer) ')'])
set(gcf, 'WindowButtonDownFcn', [lvmClassVisualiseFunc '(' '''click''' ',' num2str(curLayer) ')'])

