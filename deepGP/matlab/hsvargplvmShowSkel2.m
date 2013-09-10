function hsvargplvmShowSkel2(model, visModality, visLayer)

if nargin < 2
    visModality = 1;
end

if nargin < 3
    visLayer = 1;
end

baseDir = datasetsDirectory;
dirSep = filesep;

skel{1} = acclaimReadSkel([baseDir 'mocap' dirSep 'cmu' dirSep '20' dirSep '20.asf']);
    [YA, skel{1}] = acclaimLoadChannels([baseDir 'mocap' dirSep 'cmu' dirSep '20' dirSep '20_11.amc'], skel{1});
    seqInd = [50:4:113 114:155 156:4:size(YA, 1)];
    YA = YA(seqInd, :);
    %    YA(:, [4:end]) = asind(sind(YA(:, [4:end])));
    skel{2} = acclaimReadSkel([baseDir 'mocap' dirSep 'cmu' dirSep '21' dirSep '21.asf']);
    [YB, skel{2}] = acclaimLoadChannels([baseDir 'mocap' dirSep 'cmu' dirSep '21' dirSep '21_11.amc'], skel{2});
    YB = YB(seqInd, :);

Yall{1} = YA;
Yall{2} = YB;

%%


figure
gca;
dataType = 'skel';
% Now from the parent
modelP = model;
modelP.type = 'hsvargplvm';
modelP.vis.index=visModality;
modelP.vis.layer = visLayer; % The layer we are visualising FROM

modelP.vardist = model.layer{modelP.vis.layer}.vardist;
modelP.X = modelP.vardist.means;
modelP.q = size(modelP.X,2);

modelP.d = model.layer{model.H}.M;
%YY = multvargplvmJoinY(model.layer{1});
%Ynew = zeros(size(YY,1), size(YY,2)+length(vA));
%Ynew(:, dms) = YY;
modelP.y = Yall{visModality}; % Ytochannels(Ynew);
%modelP.Ytochannels = true; 


lvmVisualiseGeneral(modelP, [], [dataType 'Visualise'], [dataType 'Modify'],false, skel{visModality});
ylim([-20, 30]);
zlim([0, 40]);