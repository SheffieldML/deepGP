clear

%--- Load data and model ------
dataSetName = 'highFive';
hsvargplvm_init;

% Load data
Y = vargplvmLoadData('demHighFiveHgplvm1');
Yall{1} = Y.YA;
Yall{2} = Y.YB;
%Yall{1} = vargplvmLoadData('hierarchical/demHighFiveHgplvm1',[],[],'YA');
%Yall{2} = vargplvmLoadData('hierarchical/demHighFiveHgplvm1',[],[],'YB');

% Load pre-trained model
try
    load demHighFiveHsvargplvm9
catch e
    if strcmp(e.identifier, 'MATLAB:load:couldNotReadFile')
        error('Seems like you are missing the .mat file which contains the training model! Check the matFiles folder!')
    end
    error(e.getReport)
end

% Restore model
for h=1:model.H
	model.layer{h}.comp{1}.latentIndices ={};
end
model = hsvargplvmRestorePrunedModel(model, Yall);
model.multOutput=false;

%% DEMO
warning off
fprintf('!! I''m turning off your MATLAB warnings...! \n\n');
fprintf('#------ Description --------\n\n');
fprintf('# We trained a 2-layer deep GP on two separate modalities, each representing \n')
fprintf('# a person walking, approaching the other subject and doing a high-five. \n')
fprintf('# For this demo we did not use any dynamics but nevertheless the latent spaces \n')
fprintf('# found are quite similar to the ones for hgplvm. \n\n')

close all
fprintf('#------ SCALES --------\n\n');
fprintf('# Here are the optimised lengthscales (upside-down; parent is at bottom...)\n')
fprintf('# Press any key to continue...')
hsvargplvmShowScales(model);

pause

fprintf('\n\n#------- SAMPLING -------\n\n');
fprintf('#---- Sampling from the intermediate layer\n')
fprintf('#-- 1st modality (blue scales), shared space (2 vs 7)... \n')
fprintf('#   Wait to load... and then press any key to continue... \n') 
close all
model.vis.startDim = {2 7};
hsvargplvmShowSkel2(model, 1, 1);
figure; hsvargplvmShowScales(model);

pause

fprintf('#-- 2nd modality (red scales), shared space (2 vs 7)...\n')
fprintf('#   Wait to load... and then press any key to continue... \n') 
close all
model.vis.startDim = {2 7};
hsvargplvmShowSkel2(model, 2, 1);
figure; hsvargplvmShowScales(model);

pause

fprintf('#-- 2nd modality (red scales), private space (8 vs 9)... \n')
fprintf('#   Wait to load... and then press any key to continue... \n') 
close all
model.vis.startDim = {8 9};
hsvargplvmShowSkel2(model, 2, 1);
figure; hsvargplvmShowScales(model);

pause

fprintf('#---- Sampling from the PARENT layer\n')
fprintf('#-- 2nd modality (blue scales), dominant dimensions (1 vs 3) ... \n')
fprintf('#   Wait to load... and then press any key to continue... \n') 
close all
model.vis.startDim = {1 3};
hsvargplvmShowSkel2(model, 2, 2);
figure; hsvargplvmShowScales(model);

pause


fprintf('\n\n# End of demo! Feel free to experiment with different combinations of dimensions.')

warning on