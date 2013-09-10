
function [gK_uu, gPsi0, gPsi1, gPsi2, g_Lambda, gBeta, tmpV] = vargpCovGrads(model)

gPsi1 = model.beta * model.m * model.B';
gPsi1 = gPsi1'; % because it is passed to "kernVardistPsi1Gradient" as gPsi1'...

gPsi2 = (model.beta/2) * model.T1;

gPsi0 = -0.5 * model.beta * model.d;

gK_uu = 0.5 * (model.T1 - (model.beta * model.d) * model.invLmT * model.C * model.invLm);

sigm = 1/model.beta; % beta^-1

PLm = model.invLatT*model.P;
tmpV = sum(sum(PLm.*PLm));
gBeta = 0.5*(model.d*(model.TrC + (model.N-model.k)*sigm -model.Psi0) ...
    - model.TrYY + model.TrPP ...
    + (1/(model.beta^2)) * model.d * sum(sum(model.invLat.*model.invLat)) + sigm*tmpV);

%%%%TEMP
%{
    load TEMPbetaGradTrC;
    TEMPbetaGradTrC = [TEMPbetaGradTrC model.d*0.5*model.TrC];
    save 'TEMPbetaGradTrC.mat' 'TEMPbetaGradTrC';

    load TEMPbetaGradNksigm;
    TEMPbetaGradNksigm=[TEMPbetaGradNksigm model.d*0.5*(model.N-model.k)*sigm];
    save 'TEMPbetaGradNksigm.mat' 'TEMPbetaGradNksigm';

    load TEMPbetaGradPsi0;
    TEMPbetaGradPsi0=[TEMPbetaGradPsi0 (-0.5*model.d*model.Psi0)];
    save 'TEMPbetaGradPsi0.mat' 'TEMPbetaGradPsi0';

    load TEMPbetaGradTrPP;
    TEMPbetaGradTrPP=[TEMPbetaGradTrPP 0.5*model.TrPP];
    save 'TEMPbetaGradTrPP.mat' 'TEMPbetaGradTrPP';

    load TEMPbetaGradLat;
    TEMPbetaGradLat=[TEMPbetaGradLat (1/(model.beta^2)) * model.d * sum(sum(model.invLat.*model.invLat))*0.5];
    save 'TEMPbetaGradLat.mat' 'TEMPbetaGradLat';

    load TEMPbetaGradPlm;
    TEMPbetaGradPlm=[TEMPbetaGradPlm sigm*sum(sum(PLm.*PLm))*0.5];
    save 'TEMPbetaGradPlm.mat' 'TEMPbetaGradPlm';
%}
%%%%%


%gBeta = 0.5*(model.d*(model.TrC + (model.N-model.k)*sigm -model.Psi0) ...
%	- model.TrYY + model.TrPP ...
%	+ sigm * sum(sum(model.K_uu .* model.Tb)));

if ~isstruct(model.betaTransform)
    fhandle = str2func([model.betaTransform 'Transform']);
    gBeta = gBeta*fhandle(model.beta, 'gradfact');
else
    fhandle = str2func([model.betaTransform.type 'Transform']);
    gBeta = gBeta*fhandle(model.beta, 'gradfact', model.betaTransform.transformsettings);
end


g_Lambda = repmat(-0.5*model.beta*model.d, 1, model.N);
end
