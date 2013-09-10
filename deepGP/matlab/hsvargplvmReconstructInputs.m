% Try to reconstruct the training inputs of layer lInp to the oututs of
% layer lOut. A well-trained model should return outputs very close to the
% real outputs Y.

function mu = hsvargplvmReconstructInputs(model, Y, lInp, lOut, ind)

if nargin <2  || isempty(Y)
    Y = multvargplvmJoinY(model.layer{lOut});
end

if nargin < 4 || isempty(lOut)
    lOut = 1;
end

if nargin < 3 || isempty(lInp)
    lInp = model.H;
end

 % -1 means all
if nargin > 4 && ~isempty(ind) && ind == -1
    ind = 1:model.layer{lOut}.M;
elseif nargin < 5 || isempty(ind)
    ind  = model.layer{lOut}.M; 
end


X = model.layer{lInp}.vardist.means;


[X,mu]=hsvargplvmSampleLayer(model,lInp,lOut,ind,X);


imagesc(Y); title('original data')
figure
imagesc(mu); title('reconstruction');

