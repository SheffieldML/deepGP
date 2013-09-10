switch globalOpt.demoType
    case 'skelDecompose'
        
        % load connectivity matrix
        % Load the results and display dynamically.
        %lvmResultsDynamic(model.type, dataSetName, experimentNo, 'skel', connect)
        dataType = 'skel';
        skel = acclaimReadSkel('35.asf');
        [tmpchan, skel] = acclaimLoadChannels('35_01.amc', skel);
        %channels = demCmu35VargplvmLoadChannels(Y1,skel);
        %channels = skelGetChannels(Y1, skel);
        %skelPlayData(skel, channels, 1/30);
        
        %%%% TODO: Change model so that model.y contains all submodel's y's and
        %%%% model.d = model.numModels. Then call lvmVisualise with model and
        %%%% create (for lvmClassVisualise) a function hsvargplvmPosteriorMeanVar to compute like posteriorMeanVar for every sampled
        %%%% X for all submodels and join them together immediately before the call
        %%%% to skelGetChannels.
        model2 = model;
        %model2.y = multvargplvmJoinY(model);
        model2.y = skelGetChannels(multvargplvmJoinY(model));%, skel);
        model2.d = size(model2.y,2);
        model2.type = 'multvargplvm';
        lvmVisualiseGeneral(model2, lbls, [dataType 'Visualise'], [dataType 'Modify'],false, skel);
        
        %% Understand what each dimension is doing
        %{
        YY = multvargplvmJoinY(model);
        for i=1:size(YY,2)
            Ytemp = YY(1,:); Ytemp(i) = -10; close all;subplot(1,2,1), skelVisualise(skelGetChannels(Ytemp),skel); subplot(1,2,2); skelVisualise(skelGetChannels(YY(1,:)),skel);
            title(num2str(i))
            pause
        end
        %}
end
