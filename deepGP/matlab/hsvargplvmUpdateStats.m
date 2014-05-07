function model = hsvargplvmUpdateStats(model)

jitter = 1e-6;

for h=1:model.H
    if h==model.H & isfield(model.layer{h}, 'dynamics') & ~isempty(model.layer{h}.dynamics)
        model.layer{model.H} = vargplvmDynamicsUpdateStats(model.layer{model.H});
    end
        
    for m=1:model.layer{h}.M
        if h~=1 % Not leaf
            % This is an intermediate node. Its data change in every
            % iteration and we have to reset the scaled data to the means
            % of the vardist. of the previous node (future implementations
            % with more latent spaces can also have indices here!!)
            means = model.layer{h-1}.vardist.means;
            covars = model.layer{h-1}.vardist.covars;
            if ~isempty(model.layer{h}.comp{m}.latentIndices)
                % In this layer h the "means" ie the X of layer h-1 are
                % here outputs. We also have multOutput option, i.e. only
                % the full output space "means" will be grouped into
                % smaller subpsaces as defined in latentIndices.
                means = means(:, model.layer{h}.comp{m}.latentIndices);
                covars = covars(:, model.layer{h}.comp{m}.latentIndices);
            end
            if model.centerMeans
                [Y, bias, scale] = scaleData(means); %% ??????????????????????
                model.layer{h}.comp{m}.scale = scale; %%% ???????
                model.layer{h}.comp{m}.bias = bias;  %%% ???
                % Probably centering the means would also change the bound,
                % because now the expectation is not <x x'> but
                % <(x-bias)(x-bias)'>, so what we do here is not enough!
            else
                Y = means; %%%%%%%% ???????????
            end
            model.layer{h}.comp{m}.mOrig = Y;

            
            %!!!  TODO: The following should be Y.*Y, i.e. the centered version
            % of the means. That would also change FURTHER the bound,
            % because now we will have an expectation of <(x-bias)(x-bias)'>
            model.layer{h}.comp{m}.TrYY = sum(sum(means.*means)) + sum(sum(covars));
            
            %%%%
            % This is the part that changes from the leaf nodes/vargplvm to
            % the intermediate nodes. Tr(YY') becomes tr(<XX'>)
            sumAll = 0;
            for q=1:size(means,2)
                sumAll = sumAll + (means(:,q)*means(:,q)'+diag(covars(:,q)));
            end
            % This term substitutes Y for the intermediate nodes. Same
            % trick as for the high-dimensionality problems.
            model.layer{h}.comp{m}.m = jitChol(sumAll)';
            %%%            
        end
        % The following is executed for leaf and intermediate nodes. The
        % only difference is in the "m" field, but this is handled above and UpdateStats2
        % is not aware of any differences.
        model.layer{h}.comp{m} = vargplvmUpdateStats2(model.layer{h}.comp{m}, model.layer{h}.vardist);
        
        if h~=1
            % That's for the derivative of the intermediate nodes w.r.t the
            % latent space of the previous layers.
            Z = model.layer{h}.comp{m}.P1*model.layer{h}.comp{m}.Psi1';
            model.layer{h}.comp{m}.Z = Z'*Z;
        end
    end
end
end


% That's ALL copied from vargplvmUpdateStats, without the last line that
% sets model.X = model.vardist.means. Also, vardist is separated from
% model.vardist.
function model = vargplvmUpdateStats2(model, vardist)
jitter = 1e-6;


X_u = model.X_u;

model.K_uu = kernCompute(model.kern, X_u);

% Always add jitter (so that the inducing variables are "jitter" function variables)
% and the above value represents the minimum jitter value
% Putting jitter always ("if" in comments) is like having a second
% whiteVariance in the kernel which is constant.
%if (~isfield(model.kern, 'whiteVariance')) | model.kern.whiteVariance < jitter
%K_uu_jit = model.K_uu + model.jitter*eye(model.k);
%model.Lm = chol(K_uu_jit, 'lower');
%end

% There is no white noise term so add some jitter.
if ~strcmp(model.kern.type, 'rbfardjit')
    model.K_uu = model.K_uu ...
        + sparseDiag(repmat(jitter, size(model.K_uu, 1), 1));
end

model.Psi0 = kernVardistPsi0Compute(model.kern, vardist);
model.Psi1 = kernVardistPsi1Compute(model.kern, vardist, X_u);
[model.Psi2, AS] = kernVardistPsi2Compute(model.kern, vardist, X_u);

% M is model.k
%model.Lm = chol(model.K_uu, 'lower');
model.Lm = jitChol(model.K_uu)';      % M x M: L_m (lower triangular)   ---- O(m^3)
model.invLm = model.Lm\eye(model.k);  % M x M: L_m^{-1}                 ---- O(m^3)
model.invLmT = model.invLm'; % L_m^{-T}
model.C = model.invLm * model.Psi2 * model.invLmT;
model.TrC = sum(diag(model.C)); % Tr(C)
% Matrix At replaces the matrix A of the old implementation; At is more stable
% since it has a much smaller condition number than A=sigma^2 K_uu + Psi2
model.At = (1/model.beta) * eye(size(model.C,1)) + model.C; % At = beta^{-1} I + C
model.Lat = jitChol(model.At)';
model.invLat = model.Lat\eye(size(model.Lat,1));
model.invLatT = model.invLat';
model.logDetAt = 2*(sum(log(diag(model.Lat)))); % log |At|

model.P1 = model.invLat * model.invLm; % M x M

% First multiply the two last factors; so, the large N is only involved
% once in the calculations (P1: MxM, Psi1':MxN, Y: NxD)
model.P = model.P1 * (model.Psi1' * model.m); 

% Needed for both, the bound's and the derivs. calculations.
model.TrPP = sum(sum(model.P .* model.P));

%%% Precomputations for the derivatives (of the likelihood term) of the bound %%%
%model.B = model.invLmT * model.invLatT * model.P; %next line is better
model.B = model.P1' * model.P;
model.invK_uu = model.invLmT * model.invLm;
Tb = (1/model.beta) * model.d * (model.P1' * model.P1);
Tb = Tb + (model.B * model.B');
model.T1 = model.d * model.invK_uu - Tb;
end