function model = hsvargplvmUpdateStats(model, vardistx)

jitter = 1e-6;

for h=1:model.H
    if h==model.H & isfield(model.layer{h}, 'dynamics') & ~isempty(model.layer{h}.dynamics)
        if nargin > 1
            warning('Not tested!')
        end
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
        if nargin > 1
            % Need to augment the model with test (or new) observations.
            model.layer{h}.comp{m} = vargplvmUpdateStats2(model.layer{h}.comp{m}, vardistx{h}, false, []);
        else
            % The following is executed for leaf and intermediate nodes. The
            % only difference is in the "m" field, but this is handled above and UpdateStats2
            % is not aware of any differences.
            model.layer{h}.comp{m} = vargplvmUpdateStats2(model.layer{h}.comp{m}, model.layer{h}.vardist);
        end
        
        if h~=1
            % That's for the derivative of the intermediate nodes w.r.t the
            % latent space of the previous layers.
            Z = model.layer{h}.comp{m}.P1*model.layer{h}.comp{m}.Psi1';
            model.layer{h}.comp{m}.Z = Z'*Z;
        end
    end
end
end


