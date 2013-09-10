function [Y, skel, remIndices] = hsvargplvmLoadSkelData(subject, trimDims)

if nargin < 2
    trimDims = 1;
end
% ------- LOAD DATASET

switch subject
     case '13'
        examples = {'14','16','17','18'};%laugh,laugh,box,box,
        try
            load 'cmu13_14_16_17_18.mat';
        catch
            [Y, lbls, Ytest, lblstest,skel] = lvmLoadData2('cmuXNoRoot', '13', examples);
            save 'cmu13_14_16_17_18.mat' 'Y' 'lbls' 'skel'
        end
        Ynew{1}=Y(1:15:end,:);
    case '93'
        examples = {'02'};
        try
            load 'cmu93_02.mat';
        catch
            [Y, lbls, Ytest, lblstest,skel] = lvmLoadData2('cmuXNoRoot', '93', examples);
            save 'cmu93_02.mat' 'Y' 'lbls' 'skel'
        end
        Ynew{1}=Y([1:3:100 101:2:270],:);
    case '02'
        examples= {'01','05','10'};
        [Y, lbls, Ytest, lblstest,skel] = lvmLoadData2('cmuXNoRoot', '02', examples);
        seq = cumsum(sum(lbls)) - [1:31];
        seq = seq(1:length(examples));
        % Ywalk = Y(1:3:70,:); % Orig: Y(1:85,:);
        % Ypunch = Y(86:13:548,:); % Orig: Y(86:548,:);
        % Ywash = Y(549:20:1209,:); % Orig:  Y(549:1209,:);
        Ynew{1} = Y(1:2:70,:); % Orig: Y(1:85,:); % Walk
        Ynew{2} = Y(86:4:250,:); % Orig: Y(86:548,:);  % Punch
        Ynew{3} = Y(830:6:1140,:); % Orig:  Y(549:1209,:); % Wash
    case '17'
        %[Y,skel, channels] = loadMocapData();
        % Motions: angry walk, hobble, whistle/jauntily, box
        examples = {'02','05','07','10'};
        try
            load cmu17_02_05_07_10.mat
        catch
            [Y, lbls, Ytest, lblstest,skel] = lvmLoadData2('cmuXNoRoot', '17', examples);
            save 'cmu17_02_05_07_10.mat' 'Y' 'lbls' 'Ytest' 'lblstest' 'skel'
        end
        seq = cumsum(sum(lbls)) - [1:31];
        seq = seq(1:length(examples));
        Ynew{1} = Y(1:10:400,:); % Orig: Y(1:85,:);
        Ynew{2} = Y(seq(1)+1:40:seq(2)-280,:); % Orig: Y(86:548,:);
        Ynew{3} = Y(seq(2)+1:55:seq(3)-200,:); % Orig:  Y(549:1209,:);
        Ynew{4} = Y(seq(3)+1:8:5000,:);
    case '20'
        %[Y,skel, channels] = loadMocapData();
        % Motions: angry walk, hobble, whistle/jauntily, box
        examples = {'01','05','11'};
        try
            load cmu20_01_05_11.mat
        catch
            [Y, lbls, Ytest, lblstest,skel] = lvmLoadData2('cmuXNoRoot', '20', examples);
            save 'cmu20_01_05_11.mat' 'Y' 'lbls' 'skel'
        end
        seq = cumsum(sum(lbls)) - [1:31];
        seq = seq(1:length(examples));
        Ynew{1} = Y;
end
Yorig = Y;



if trimDims
    for i=1:length(Ynew)
        [channels, xyzDiffIndices{i}, rotInd{i}] = skelGetChannels(Ynew{i});
        %%% ATTENTION: 'remIndices' should be the same for all!! (for
        %%% consistency)
        remIndices{i} = [xyzDiffIndices{i} rotInd{i}]; 
        Ynew{i}(:, remIndices{i}) = zeros(size(Ynew{i}(:, remIndices{i}) ));
    end
else
    remIndices = {};
end

Y = [];
for i=1:length(Ynew)
    Y = [Y ; Ynew{i}];
end

%{
   [channels] = skelGetChannels(Ynew{1});
   close; skelPlayData(skel, channels, 1/5);
%}