function [Y,skel, channels] = loadMocapData()

%YA = vargplvmLoadData('hierarchical/demHighFiveHgplvm1',[],[],'YA');
%{
curDir = pwd;
cd ../../../vargplvmDEPENDENCIES/DATASETS0p1371/mocap/cmu/02/
fileNameAsf='02.asf';
fileNameAmc='02_05.amc';
skel = acclaimReadSkel(fileNameAsf);
[channels, skel] = acclaimLoadChannels(fileNameAmc, skel);
% Remove root node?
channels(:, [1 3]) = zeros(size(channels, 1), 2);
skelPlayData(skel, channels, 1/40);
cd(curDir)
%}
%%
clear
close all
[Y, lbls, Ytest, lblstest,skel] = lvmLoadData2('cmuXNoRoot', '02', {'01','05','10'});
Yorig = Y;
% REmove motion in xz?

seq = cumsum(sum(lbls)) - [1:31];
% Ywalk = Y(1:3:70,:); % Orig: Y(1:85,:);
% Ypunch = Y(86:13:548,:); % Orig: Y(86:548,:);
% Ywash = Y(549:20:1209,:); % Orig:  Y(549:1209,:);
Ywalk = Y(1:2:70,:); % Orig: Y(1:85,:);
Ypunch = Y(86:13:548,:); % Orig: Y(86:548,:);
Ywash = Y(830:6:1140,:); % Orig:  Y(549:1209,:);

[channels xyzDiffIndices] = skelGetChannels(Ywalk);
Ywalk(:, xyzDiffIndices) = zeros(size(Ywalk(:, xyzDiffIndices) ));
[channels xyzDiffIndices] = skelGetChannels(Ypunch);
Ypunch(:, xyzDiffIndices) = zeros(size(Ypunch(:, xyzDiffIndices) ));
[channels xyzDiffIndices] = skelGetChannels(Ywash);
Ywash(:, xyzDiffIndices) = zeros(size(Ywash(:, xyzDiffIndices) ));


Y = [Ywalk; Ywash];
[channels] = skelGetChannels(Y);
close; skelPlayData(skel, channels, 1/5);


%%
%{
[channelsWalk] = skelGetChannels(Ywalk);
[channelsPunch] = skelGetChannels(Ypunch);
[channelsWash] = skelGetChannels(Ywash);
close; skelPlayData(skel, channelsWalk, 1/20);
close; skelPlayData(skel, channelsPunch, 1/20);
close; skelPlayData(skel, channelsWash, 1/20);
%}



%{
try
    load '../cmu13Data.mat'
catch
    [Y, lbls] = lvmLoadData2('cmu13');
    seq = cumsum(sum(lbls)) - [1:31];

    % load data
    [Y, lbls, Ytest, lblstest] = lvmLoadData2('cmu13NoRoot');
    skel = acclaimReadSkel('../../../vargplvmDEPENDENCIES/DATASETS0p1371/mocap/cmu/13/13.asf');
    % (I think) any motion of the specific subject would do here, just to get
    % the channels
    [tmpchan, skel] = acclaimLoadChannels('../../../vargplvmDEPENDENCIES/DATASETS0p1371/mocap/cmu/13/13_13.amc', skel);
end
%}







%{ 
See cmu49 for more coherent motions
try
    load '../cmu13Data.mat'
catch
    [Y, lbls] = lvmLoadData2('cmu13');
    seq = cumsum(sum(lbls)) - [1:31];

    % load data
    [Y, lbls, Ytest, lblstest] = lvmLoadData2('cmu13NoRoot');
    skel = acclaimReadSkel('../../../vargplvmDEPENDENCIES/DATASETS0p1371/mocap/cmu/13/13.asf');
    % (I think) any motion of the specific subject would do here, just to get
    % the channels
    [tmpchan, skel] = acclaimLoadChannels('../../../vargplvmDEPENDENCIES/DATASETS0p1371/mocap/cmu/13/13_13.amc', skel);
end
Yjump = Y(35:90,:);
Yjacks = Y(677:end,:);
channels = skelGetChannels(Yjump);
close; skelPlayData(skel, channels, 1/20);
%}

%%
function createCmuData(subject, motions)
baseDir = datasetsDirectory;
dirSep = filesep;
[Y, lbls, Ytest, lblstest] = lvmLoadData2('cmu13');
skel = acclaimReadSkel([baseDir 'mocap' dirSep 'cmu' dirSep '13' dirSep '13.asf']);
seq = cumsum(sum(lbls)) - [1:31];
[tmpchan, skel] = acclaimLoadChannels([baseDir 'mocap' dirSep 'cmu' dirSep '13' dirSep '13_16.amc'], skel);
[Y, lbls, Ytest, lblstest] = lvmLoadData2('cmu13NoRoot');


try
    load '../cmu13Data.mat'
catch
    [Y, lbls] = lvmLoadData2('cmu13');
    seq = cumsum(sum(lbls)) - [1:31];

    % load data
    [Y, lbls, Ytest, lblstest] = lvmLoadData2('cmu13NoRoot');
    skel = acclaimReadSkel('../../../vargplvmDEPENDENCIES/DATASETS0p1371/mocap/cmu/13/13.asf');
    % (I think) any motion of the specific subject would do here, just to get
    % the channels
    [tmpchan, skel] = acclaimLoadChannels('../../../vargplvmDEPENDENCIES/DATASETS0p1371/mocap/cmu/13/13_13.amc', skel);
end


 



%% 
%{
%%%%%%%%%%%%%%%%%
%baseDir = datasetsDirectory;
%dirSep = filesep;
%[Y, lbls, Ytest, lblstest] = lvmLoadData2('cmu13');
%skel = acclaimReadSkel([baseDir 'mocap' dirSep 'cmu' dirSep '13' dirSep '13.asf']);
%seq = cumsum(sum(lbls)) - [1:31];
%[tmpchan, skel] = acclaimLoadChannels([baseDir 'mocap' dirSep 'cmu' dirSep '13' dirSep '13_16.amc'], skel);
%[Y, lbls, Ytest, lblstest] = lvmLoadData2('cmu13NoRoot');

  
try
    load '../cmu13Data.mat'
catch
    [Y, lbls] = lvmLoadData2('cmu13');
    seq = cumsum(sum(lbls)) - [1:31];

    % load data
    [Y, lbls, Ytest, lblstest] = lvmLoadData2('cmu13NoRoot');
    skel = acclaimReadSkel('../../../vargplvmDEPENDENCIES/DATASETS0p1371/mocap/cmu/13/13.asf');
    % (I think) any motion of the specific subject would do here, just to get
    % the channels
    [tmpchan, skel] = acclaimLoadChannels('../../../vargplvmDEPENDENCIES/DATASETS0p1371/mocap/cmu/13/13_13.amc', skel);
end

Y = Y(1:12:1430,:);
Y = Y([1:45 72:end],:);
Y = Y([1:50 70:end],:);

[Ywalk, lbls, Ytest, lblstest] = lvmLoadData('cmu35gplvm');
Y = [Y; Ywalk(1:12:100,:)];


channels = skelGetChannels(Y);
  


%skelPlayData(skel, channels, 1/20);
%}