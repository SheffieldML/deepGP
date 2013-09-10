% If true, then the training/test set are created by biasing towards creating blocks
% (of size biased towards a predefined number)
if ~exist('splBlocks'), splBlocks = false; end

% Create a test set
if ~splBlocks
    indTr = randperm(Ntoy);
    indTr = sort(indTr(1:Ntr));
    indTs = setdiff(1:Ntoy, indTr);
else
    %--- Split training and test sets
    mask = [];
    lastTrPts = 0; %The last lastTrPts will be from YTr necessarily if > 0
    r=1; % start with tr. set
    while length(mask)<size(Y,1)-lastTrPts 
        if r % train
            blockSize = randperm(5); % maximum size of blocks for Train
        else
            blockSize = randperm(12); % maximum size of blocks for Test
        end
        blockSize = blockSize(1);
        pts = min(blockSize, size(Y,1)-lastTrPts - length(mask));
        if r
            mask = [mask ones(1,pts)];
        else
            mask = [mask zeros(1,pts)];
        end
        r = ~r; % alternate between tr. and test set
    end
    mask = [mask ones(1,lastTrPts)];
    indTr = find(mask);
    indTs = find(~mask);
    if sum(sort([indTr indTs]) - (1:size(Y,1)))
        error('Something went wrong in the dataset splitting...');
    end    
end


xAll = 1:Ntoy;
for i=1:length(Ytr)
    Yts{i} = Ytr{i}(indTs,:);
    Ytr{i} = Ytr{i}(indTr,:);
end
inpX = X(indTr, :);
Xstar = X(indTs,:);