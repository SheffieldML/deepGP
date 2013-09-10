function stackedvargplvmClassVisualise(call, layer)


% LVMCLASSVISUALISE Callback function for visualising data.
% FORMAT
% DESC contains the callback functions for visualizing points from the
% latent space in the higher dimension space.
% ARG call : either 'click', 'move', 'toggleDynamics',
% 'dynamicsSliderChange'
%
%  

global visualiseInfo

switch call
 case 'click'
  [x, y]  = localCheckPointPosition(visualiseInfo.comp{layer});  
  if ~isempty(x) 
    visualiseInfo.comp{layer}.latentPos(visualiseInfo.comp{layer}.dim1) = x;
    visualiseInfo.comp{layer}.latentPos(visualiseInfo.comp{layer}.dim2) = y;
  end
  visualiseInfo.comp{layer}.clicked = ~visualiseInfo.comp{layer}.clicked;
  if isfield(visualiseInfo.comp{layer}.model, 'dynamics') & ~isempty(visualiseInfo.comp{layer}.model.dynamics)
    if visualiseInfo.comp{layer}.runDynamics
      visualiseInfo.comp{layer}.dynamicsRunning = 1;
      fhandle = str2func([visualiseInfo.comp{layer}.model.type 'DynamicsRun']);
      feval(fhandle);
      visualiseInfo.comp{layer}.dynamicsRunning = 0;
    end
  else
    visualiseInfo.comp{layer}.dynamicsRunning = 0;
  end
 case 'move'
  if visualiseInfo.comp{layer}.clicked & ~visualiseInfo.comp{layer}.runDynamics
    [x, y]  = localCheckPointPosition(visualiseInfo.comp{layer});  
    if ~isempty(x) 
        % This should be changed to a model specific visualisation.
        visualiseInfo.comp{layer}.latentPos(visualiseInfo.comp{layer}.dim1) = x;
        visualiseInfo.comp{layer}.latentPos(visualiseInfo.comp{layer}.dim2) = y;
        set(visualiseInfo.comp{layer}.latentHandle, 'xdata', x, 'ydata', y);
        %fhandle = str2func([visualiseInfo.comp{layer}.model.type 'PosteriorMeanVar']); %%%%
        fhandle = str2func('multvargplvmPosteriorMeanVar');
        %[mu, varsigma] = fhandle(visualiseInfo.model,visualiseInfo.latentPos); %%%
        mu = fhandle(visualiseInfo.comp{layer}.model,visualiseInfo.comp{layer}.latentPos); %%% varsigma = 0; %%%
        %if isfield(visualiseInfo.model, 'noise')
        %Y = noiseOut(visualiseInfo.model.noise, mu, varsigma); %%%
        %  Y = noiseOut(visualiseInfo.model.noise, mu, 0);
        %else
        Y = mu;  % That's actually a vector?
        if layer == 1 % base model
            Y = skelGetChannels(Y); %, visualiseInfo.varargin{:});%%%%% FOR SKEL
            %end
            visualiseInfo.comp{layer}.visualiseModify(visualiseInfo.comp{layer}.visHandle, ...
                Y, visualiseInfo.comp{layer}.varargin{:});
        else
            % TODO: !!!!!!!!!!!!!!!!!!!!!!!!!!
            % Update latent representations in all figures below this one...
            % (Maybe only in the visualiseInfo.comp{i}.dim1 & dim2
            % dimensions if this is possible)
            for curLayer = layer:-1:2
                % visualiseInfo.comp{layer-1}.latentPos = Y; %% That's only
                % the "bullet"'s position!!!
           %     stackedvargplvmClassVisualise('updateLatentRepresentation', layer-1)
            end
            % Now also call the base layer
            %stackedvargplvmClassVisualise(call, 1)  % UNCOMMENT!!
        end
    end
  end
 case 'toggleDynamics'
  visualiseInfo.comp{layer}.runDynamics = ~visualiseInfo.comp{layer}.runDynamics;
  set(visualiseInfo.comp{layer}.dynamicsRadio, 'value', visualiseInfo.comp{layer}.runDynamics);

 case 'dynamicsSliderChange'
  X = modelOut(visualiseInfo.comp{layer}.model.dynamics, get(visualiseInfo.comp{layer}.dynamicsSlider, 'value'));
  x = X(1);
  y = X(2);
  visualiseInfo.comp{layer}.latentPos(visualiseInfo.comp{layer}.dim1) = x;
  visualiseInfo.comp{layer}.latentPos(visualiseInfo.comp{layer}.dim2) = y;
  set(visualiseInfo.comp{layer}.latentHandle, 'xdata', x, 'ydata', y);
  fhandle = str2func([visualiseInfo.comp{layer}.model.type 'PosteriorMeanVar']);
  [mu, varsigma] = fhandle(visualiseInfo.comp{layer}.model, visualiseInfo.comp{layer}.latentPos);
  if isfield(visualiseInfo.comp{layer}.model, 'noise')
    Y = noiseOut(visualiseInfo.comp{layer}.model.noise, mu, varsigma);
  else
    Y = mu;
  end
  visualiseInfo.comp{layer}.visualiseModify(visualiseInfo.comp{layer}.visHandle, ...
                                Y, visualiseInfo.comp{layer}.varargin{:});


 case 'latentSliderChange'
  counter = 0;
  for i = size(visualiseInfo.comp{layer}.latentPos, 2):-1:1
    % Go through setting latent positions to slider positions.
    if i ~= visualiseInfo.comp{layer}.dim1 && i ~= visualiseInfo.comp{layer}.dim2
      counter = counter + 1;
      visualiseInfo.comp{layer}.latentPos(i) = get(visualiseInfo.comp{layer}.latentSlider(counter), 'value');
      set(visualiseInfo.comp{layer}.sliderTextVal(counter), 'string', num2str(visualiseInfo.comp{layer}.latentPos(i)));
    end
  end
  if visualiseInfo.showVariance
    lvmSetPlot;
  else
      lvmSetPlotNoVar([visualiseInfo.comp{layer}.model.type 'ClassVisualise']);
  end
  fhandle = str2func([visualiseInfo.comp{layer}.model.type 'PosteriorMeanVar']);
  [mu, varsigma] = fhandle(visualiseInfo.comp{layer}.model, visualiseInfo.comp{layer}.latentPos);
  if isfield(visualiseInfo.comp{layer}.model, 'noise')
    Y = noiseOut(visualiseInfo.comp{layer}.model.noise, mu, varsigma);
  else
    Y = mu;
  end
  visualiseInfo.comp{layer}.visualiseModify(visualiseInfo.comp{layer}.visHandle, ...
                                    Y, visualiseInfo.comp{layer}.varargin{:});

  visualiseInfo.comp{layer}.latentHandle = line(visualiseInfo.comp{layer}.latentPos(visualiseInfo.comp{layer}.dim1), ...
                                    visualiseInfo.comp{layer}.latentPos(visualiseInfo.comp{layer}.dim2), ...
                                    'markersize', 20, 'color', [0.5 0.5 0.5], ...
                                    'marker', '.', 'visible', 'on', ...
                                    'erasemode', 'xor');

 case 'updateLatentRepresentation'
  visualiseInfo.comp{layer}.dim1 = get(visualiseInfo.comp{layer}.xDimension, 'value');
  visualiseInfo.comp{layer}.dim2 = get(visualiseInfo.comp{layer}.yDimension, 'value');
  if visualiseInfo.showVariance
    lvmSetPlot;
  else
      hierSetPlotNoVar([visualiseInfo.comp{layer}.model.type 'ClassVisualise'], layer);
  end
  visualiseInfo.comp{layer}.latentHandle = line(visualiseInfo.comp{layer}.latentPos(visualiseInfo.comp{layer}.dim1), ...
                                    visualiseInfo.comp{layer}.latentPos(visualiseInfo.comp{layer}.dim2), ...
                                    'markersize', 20, 'color', [0.5 0.5 0.5], ...
                                    'marker', '.', 'visible', 'on', ...
                                    'erasemode', 'xor');

  
  


end




function point = localGetNormCursorPoint(figHandle)

point = get(figHandle, 'currentPoint');
figPos = get(figHandle, 'Position');
% Normalise the point of the curstor
point(1) = point(1)/figPos(3);
point(2) = point(2)/figPos(4);

function [x, y] = localGetNormAxesPoint(point, axesHandle)

position = get(axesHandle, 'Position');
x = (point(1) - position(1))/position(3);
y = (point(2) - position(2))/position(4);
lim = get(axesHandle, 'XLim');
x = x*(lim(2) - lim(1));
x = x + lim(1);
lim = get(axesHandle, 'YLim');
y = y*(lim(2) - lim(1));
y = y + lim(1);


function [x, y] = localCheckPointPosition(visualiseInfo)

% Get the point of the cursor
point = localGetNormCursorPoint(gcf);

% get the position of the axes
position = get(visualiseInfo.plotAxes, 'Position');


% Check if the pointer is in the axes
if point(1) > position(1) ...
      & point(1) < position(1) + position(3) ...
      & point(2) > position(2) ...
      & point(2) < position(2) + position(4);
  
  % Rescale the point according to the axes
  [x y] = localGetNormAxesPoint(point, visualiseInfo.plotAxes);

  % Find the nearest point
else
  % Return nothing
  x = [];
  y = [];
end
