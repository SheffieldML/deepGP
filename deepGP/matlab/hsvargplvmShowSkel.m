function hsvargplvmShowSkel(model)


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
m = 2;
figure
% First, sample from the intermediate layer
model2 = model.layer{1}.comp{m};
model2.vardist = model.layer{1}.vardist;
model2.X = model2.vardist.means;
%channelsA = skelGetChannels(Yall{m});
dataType = 'skel';
lvmVisualiseGeneral(model2, [], [dataType 'Visualise'], [dataType 'Modify'],false, skel{m});
ylim([-18 18])
%%
figure
m = 2;
dataType = 'skel';
% Now from the parent
modelP = model;
modelP.type = 'hsvargplvm';
modelP.vardist = model.layer{2}.vardist;
modelP.X = modelP.vardist.means;
modelP.q = size(modelP.X,2);

modelP.d = size(Yall{m},2);
modelP.y = Yall{m};
modelP.vis.index=m;
modelP.vis.layer = 1;
lvmVisualiseGeneral(modelP, [], [dataType 'Visualise'], [dataType 'Modify'],false, skel{m});
ylim([-20, 30]);
% USE e.g. ylim([-18 8]) to set the axis right if needed
end




