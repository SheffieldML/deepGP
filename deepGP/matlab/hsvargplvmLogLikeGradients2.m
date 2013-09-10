for h=1:model.H
   gTheta = [];
   gInd = [];
   gIndThetaBeta = [];
   gVarmeans = [];
   gVarcovs = [];
   gDyn = [];
   
   gTheta_i = [];
   gInd_i = [];
   gVarmeans_i = 0;
   gVarcovs_i = 0;
   gDyn_i = [];
   
   for i=1:model.layer{h}.M
       % Derivatives of L_{hm} term for non-vardistr. params
       model.comp{i}.vardist = model.vardist;
       
       if h ~= model.H % Not parent
            model.comp{i}.onlyLikelihood = true;
       end
       % For not parent, gVarmeansAll_i and covs are []
       [gVarmeansLik_i gVarcovsLik_i gVarmeansAll_i gVarcovsAll_i gInd_i gTheta_i gBeta_i] = ...
            vargplvmLogLikelihoodParts(model.layer{h}.comp{i});
        
        gIndThetaBeta = [gIndThetaBeta gInd_i gTheta_i gBeta_i];
               

        
        if h == model.H
            % Parent: we have KL terms that need to be added
%            gVarmeans_
 %...           
        else
            % Derivatives of L_{hm} term for vardistr. params (need to be added
            % since we only have one vardistr. which is common).
            gVarmeans_i = gVarmeans_i + gVarmeansLik;
            gVarcovs_i = gVarcovs_i + gVarcovsLik;
        end
   end
   
   if h ~= model.H
       % Derivatives of H_h term for vardistr. params (also need to be
       % added) - that's just the covars.
       %gVarcovsEntr_i = ... ;       
   end
   
   % Now amend the derivs. of the vardistr. of the previous layer
   if h ~= 1
       % ...
   end
end