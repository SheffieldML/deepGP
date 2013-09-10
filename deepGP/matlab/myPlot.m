function myPlot(X, t, fileName, root, lSizes, newFig)
if nargin < 2, t = []; end
if nargin < 3, fileName = []; end
if nargin < 4, root = []; end
if nargin < 5 || isempty(lSizes), lSizes{1}=4; lSizes{2}=14; end
if nargin < 6, newFig = true; end

if newFig, figure; end
plot(X(:,1), X(:,2),'--x','LineWidth',lSizes{1},...
    'MarkerEdgeColor','r',...
    'MarkerFaceColor','g',...
    'MarkerSize',lSizes{2}); title(t); axis off

%pause
if ~isempty(fileName)
    if ~isempty(root)
        fileName = [root filesep fileName];
    end
    print('-depsc', [fileName '.eps']);
    print('-dpdf', [fileName '.pdf']);
    print('-dpng', [fileName '.png']);
end