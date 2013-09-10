function [Y, lbls, Ytest, lblstest, skel] = lvmLoadData2(dataSetType, cmuDataset, cmuExamples)

% LVMLOADDATA Load a latent variable model dataset.
% FORMAT
% DESC loads a data set for a latent variable modelling problem.
% ARG dataset : the name of the data set to be loaded. Currently
% the possible names are 'robotWireless',
% 'robotTwoLoops', 'robotTraces', 'robotTracesTest', 'cmu35gplvm',
% 'cmu35Taylor', 'cmu35walkJog', 'vowels', 'stick', 'brendan',
% 'digits', 'twos', 'oil', 'oilTest', 'oilValid', 'oil100',
% 'swissRoll', 'missa'.
% RETURN Y : the training data loaded in.
% RETURN lbls : a set of labels for the data (if there are no
% labels it is empty).
% RETURN Ytest : the test data loaded in. If no test set is
% available it is empty.
% RETURN lblstest : a set of labels for the test data (if there are
% no labels it is empty).
%
% SEEALSO : mapLoadData, datasetsDirectory
%
% COPYRIGHT : Neil D. Lawrence, 2004, 2005, 2006, 2008, 2009

% DATASETS



% get directory

baseDir = datasetsDirectory;
dirSep = filesep;
lbls = [];
lblstest = [];
skel = [];
dataSetName = ['cmu' cmuDataset];

switch dataSetType
        case 'cmuX'
        try
            load([baseDir dataSetName '.mat']);
        catch
            [void, errid] = lasterr;
            if strcmp(errid, 'MATLAB:load:couldNotReadFile');
                skel = acclaimReadSkel([baseDir 'mocap' dirSep 'cmu' dirSep cmuDataset ...
                                    dirSep cmuDataset '.asf']);
                examples = cmuExamples;
                    %{'13', '16','31'};
                testExamples=[];
                % Label differently for each sequence
                exlbls = eye(31);
                testexlbls = eye(2);
                totLength = 0;
                totTestLength = 0;
                for i = 1:length(examples)
                    [tmpchan, skel] = acclaimLoadChannels([baseDir 'mocap' dirSep 'cmu' dirSep cmuDataset ...
                                    dirSep cmuDataset '_' examples{i} '.amc'], skel);
                    tY{i} = tmpchan(1:4:end, :);
                    tlbls{i} = repmat(exlbls(i, :), size(tY{i}, 1), 1);
                    totLength = totLength + size(tY{i}, 1);
                end
                Y = zeros(totLength, size(tY{1}, 2));
                lbls = zeros(totLength, size(tlbls{1}, 2));
                endInd = 0;
                for i = 1:length(tY)
                    startInd = endInd + 1;
                    endInd = endInd + size(tY{i}, 1);
                    Y(startInd:endInd, :) = tY{i};
                    lbls(startInd:endInd, :) = tlbls{i};
                end
                for i = 1:length(testExamples)
                    [tmpchan, skel] = acclaimLoadChannels([baseDir 'mocap' dirSep 'cmu' dirSep cmuDataset ...
                        dirSep cmuDataset '_' testExamples{i} '.amc'], skel);
                    tYtest{i} = tmpchan(1:4:end, :);
                    tlblstest{i} = repmat(testexlbls(i, :), size(tYtest{i}, 1), 1);
                    totTestLength = totTestLength + size(tYtest{i}, 1);
                end
                Ytest = [];%zeros(totTestLength, size(tYtest{1}, 2));
                lblstest = [];%zeros(totTestLength, size(tlblstest{1}, 2));
                endInd = 0;
                %for i = 1:length(tYtest)
                 %   startInd = endInd + 1;
                 %   endInd = endInd + size(tYtest{i}, 1);
                 %   Ytest(startInd:endInd, :) = tYtest{i};
                 %   lblstest(startInd:endInd, :) = tlblstest{i};
               % end
                save([baseDir dataSetName '.mat'], 'Y', 'lbls', 'Ytest', 'lblstest', 'skel');
            else
                error(lasterr);
            end
        end
    case 'cmuXNoRoot'
        [Y, lbls, Ytest, lblstest] = lvmLoadData2('cmuX', cmuDataset, cmuExamples);
        skel = acclaimReadSkel([baseDir 'mocap' dirSep 'cmu' dirSep cmuDataset dirSep cmuDataset '.asf']);
        
        [tmpchan, skel] = acclaimLoadChannels([baseDir 'mocap' dirSep 'cmu' dirSep cmuDataset dirSep cmuDataset '_' cmuExamples{1} '.amc'], skel);
        
      %  Ytest = Ytest(find(lblstest(:, 2)), :);
      %  lblstest = lblstest(find(lblstest(:, 2)), 2);
        
        %left indices
        xyzInd = [2];
        xyzDiffInd = [1 3];
        rotInd = [4 6];
        rotDiffInd = [5];
        generalInd = [7:38 41:47 49:50 53:59 61:62];
        
        jointAngles  = asin(sin(pi*Y(:, generalInd)/180));
        %jointAnglesTest  = asin(sin(pi*Ytest(:, generalInd)/180));
        
        endInd = [];
        for i = 1:size(lbls, 2)
            endInd = [endInd max(find(lbls(:, i)))];
        end
        catJointAngles = [];
        xyzDiff = [];
        catSinCos = [];
        startInd = 1;
        for i = 1:length(endInd)
            ind1 = startInd:endInd(i)-1;
            ind2 = startInd+1:endInd(i);
            catJointAngles = [catJointAngles; ...
                jointAngles(ind2, :)];
            xyzDiff = [xyzDiff;
                Y(ind1, xyzDiffInd) - Y(ind2, xyzDiffInd) ...
                Y(ind2, xyzInd)];
            catSinCos = [catSinCos; ...
                sin(pi*Y(ind2, rotInd)/180) ...
                sin(pi*Y(ind1, rotDiffInd)/180)-sin(pi*Y(ind2, rotDiffInd)/180) ...
                cos(pi*Y(ind2, rotInd)/180) ...
                cos(pi*Y(ind1, rotDiffInd)/180)-cos(pi*Y(ind2, rotDiffInd)/180)];
            startInd = endInd(i)+1;
        end
        Y = [catJointAngles xyzDiff catSinCos];
        %lbls = [];
 %{
    case 'cmu13'
        try
            load([baseDir 'cmu13.mat']);
        catch
            [void, errid] = lasterr;
            if strcmp(errid, 'MATLAB:load:couldNotReadFile');
                skel = acclaimReadSkel([baseDir 'mocap' dirSep 'cmu' dirSep '13' dirSep '13.asf']);
                examples = ...
                    {'13', '16','31'};
                testExamples=[];
                % Label differently for each sequence
                exlbls = eye(31);
                testexlbls = eye(2);
                totLength = 0;
                totTestLength = 0;
                for i = 1:length(examples)
                    [tmpchan, skel] = acclaimLoadChannels([baseDir 'mocap' dirSep 'cmu' dirSep '13' dirSep '13_' ...
                        examples{i} '.amc'], skel);
                    tY{i} = tmpchan(1:4:end, :);
                    tlbls{i} = repmat(exlbls(i, :), size(tY{i}, 1), 1);
                    totLength = totLength + size(tY{i}, 1);
                end
                Y = zeros(totLength, size(tY{1}, 2));
                lbls = zeros(totLength, size(tlbls{1}, 2));
                endInd = 0;
                for i = 1:length(tY)
                    startInd = endInd + 1;
                    endInd = endInd + size(tY{i}, 1);
                    Y(startInd:endInd, :) = tY{i};
                    lbls(startInd:endInd, :) = tlbls{i};
                end
                for i = 1:length(testExamples)
                    [tmpchan, skel] = acclaimLoadChannels([baseDir 'mocap' dirSep 'cmu' dirSep '13' dirSep '13_' ...
                        testExamples{i} '.amc'], skel);
                    tYtest{i} = tmpchan(1:4:end, :);
                    tlblstest{i} = repmat(testexlbls(i, :), size(tYtest{i}, 1), 1);
                    totTestLength = totTestLength + size(tYtest{i}, 1);
                end
                Ytest = [];%zeros(totTestLength, size(tYtest{1}, 2));
                lblstest = [];%zeros(totTestLength, size(tlblstest{1}, 2));
                endInd = 0;
                %for i = 1:length(tYtest)
                 %   startInd = endInd + 1;
                 %   endInd = endInd + size(tYtest{i}, 1);
                 %   Ytest(startInd:endInd, :) = tYtest{i};
                 %   lblstest(startInd:endInd, :) = tlblstest{i};
               % end
                save([baseDir 'cmu13.mat'], 'Y', 'lbls', 'Ytest', 'lblstest');
            else
                error(lasterr);
            end
        end
    case 'cmu13NoRoot'
        [Y, lbls, Ytest, lblstest] = lvmLoadData2('cmu13');
        skel = acclaimReadSkel([baseDir 'mocap' dirSep 'cmu' dirSep '13' dirSep '13.asf']);
        
        [tmpchan, skel] = acclaimLoadChannels([baseDir 'mocap' dirSep 'cmu' dirSep '13' dirSep '13_16.amc'], skel);
        
      %  Ytest = Ytest(find(lblstest(:, 2)), :);
      %  lblstest = lblstest(find(lblstest(:, 2)), 2);
        
        %left indices
        xyzInd = [2];
        xyzDiffInd = [1 3];
        rotInd = [4 6];
        rotDiffInd = [5];
        generalInd = [7:38 41:47 49:50 53:59 61:62];
        
        jointAngles  = asin(sin(pi*Y(:, generalInd)/180));
        %jointAnglesTest  = asin(sin(pi*Ytest(:, generalInd)/180));
        
        endInd = [];
        for i = 1:size(lbls, 2)
            endInd = [endInd max(find(lbls(:, i)))];
        end
        catJointAngles = [];
        xyzDiff = [];
        catSinCos = [];
        startInd = 1;
        for i = 1:length(endInd)
            ind1 = startInd:endInd(i)-1;
            ind2 = startInd+1:endInd(i);
            catJointAngles = [catJointAngles; ...
                jointAngles(ind2, :)];
            xyzDiff = [xyzDiff;
                Y(ind1, xyzDiffInd) - Y(ind2, xyzDiffInd) ...
                Y(ind2, xyzInd)];
            catSinCos = [catSinCos; ...
                sin(pi*Y(ind2, rotInd)/180) ...
                sin(pi*Y(ind1, rotDiffInd)/180)-sin(pi*Y(ind2, rotDiffInd)/180) ...
                cos(pi*Y(ind2, rotInd)/180) ...
                cos(pi*Y(ind1, rotDiffInd)/180)-cos(pi*Y(ind2, rotDiffInd)/180)];
            startInd = endInd(i)+1;
        end
        Y = [catJointAngles xyzDiff catSinCos];
        lbls = [];
  %}
end