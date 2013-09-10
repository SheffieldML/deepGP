function [channels, xyzDiffIndices, rotIndices] = skelGetChannels(Ytest)    

xyzDiffIndices = [];
rotIndices = [];

%left indices
    xyzInd = [2];
    xyzDiffInd = [1 3];
    rotInd = [4 6];
    rotDiffInd = [5];
    generalInd = [7:38 41:47 49:50 53:59 61:62];
    startInd = 1;
    endInd = length(generalInd);
    channels(:, generalInd) = 180*Ytest(:, startInd:endInd)/pi;
    startInd = endInd + 1;
    endInd = endInd + length(xyzDiffInd);
    channels(:, xyzDiffInd) = cumsum(Ytest(:, startInd:endInd), 1);
    startInd = endInd + 1;
    endInd = endInd + length(xyzInd);
    channels(:, xyzInd) = Ytest(:, startInd:endInd);
        %xyzDiffIndices = [xyzDiffIndices startInd:endInd]; %%%%%%%%%%%
    startInd = endInd + 1;
    endInd = endInd + length(xyzDiffInd);
    channels(:, xyzDiffInd) = cumsum(Ytest(:, startInd:endInd), 1);
        xyzDiffIndices = [xyzDiffIndices startInd:endInd];%%%%%%%%%
    startInd = endInd + 1;
    endInd = endInd + length(rotInd);
    channels(:, rotInd) = asin(Ytest(:, startInd:endInd))*180/pi;
    channels(:, rotInd(end)) = channels(:, rotInd(end))+270;
        rotIndices = [rotIndices startInd:endInd];
    startInd = endInd + 1;
    endInd = endInd + length(rotDiffInd);
    channels(:, rotDiffInd) = 0;%cumsum(asin(Ytest(:, startInd:endInd)), 1))*180/pi;
            xyzDiffIndices = [xyzDiffIndices startInd:endInd];%%%%%%%%%

    % skelPlayData(skel, channels, 1/25);
