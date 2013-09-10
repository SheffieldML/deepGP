% README Manual for Deep GPs
% Copyright: Andreas C. Damianou, 2012, 2013
% DEEPGP

  _                                    _                 
 | |                                  | |                
 | |__  _____   ____ _ _ __ __ _ _ __ | |_   ___ __ ___  
 | '_ \/ __\ \ / / _` | '__/ _` | '_ \| \ \ / / '_ ` _ \ 
 | | | \__ \\ V / (_| | | | (_| | |_) | |\ V /| | | | | |
 |_| |_|___/ \_/ \__,_|_|  \__, | .__/|_| \_/ |_| |_| |_|
                            __/ | |                      
                           |___/|_|                      



                              R E A D M E

___________________________________________________________________________
##################### DEPENDENCIES GRAPH ########################
___________________________________________________________________________

Dependencies graph:
- (1) vargplvm - Bayesian GPLVM/VGPDS/MRD toolbox: https://github.com/SheffieldML/vargplvm
- (2) GPmat - Neil Lawrence's GP matlab toolbox: https://github.com/SheffieldML/GPmat
- (3) Netlab v.3.3: http://www1.aston.ac.uk/ncrg/
- (4) Isomap.m: http://web.mit.edu/cocosci/isomap/code/Isomap.m
- (5) L2_distance.m: http://web.mit.edu/cocosci/isomap/code/L2_distance.m
- (6) keep.m: http://www.mathworks.com/matlabcentral/fileexchange/181-keep/content/keep.m

L2_distance ---- Isomap ---- GPmat ---- vargplvm ---- deepGP
							/			/
				Netlab ----------------

___________________________________________________________________________
############################# GENERAL #####################################
___________________________________________________________________________

This is the implementation of a hierarchical variatioanl GPLVM, where
instead of the standard one latent space, there's a hierarchy of those.
As a sub-case, there is another difference from the standard model:
instead of considering one observation space Y, we can choose to
consider more. If we choose different subsets or modalities, [Y1, Y2],
this is exactly equivalent to svargplvm. We might also choose one modality
per output dimension, i.e. we will have as outputs SEPARATE [y1 y2 y3...].
where subscript indexes dimensions. This is the implementation of
*multvargplvm* and it's basically a wrapper for svargplvm with a few
tweaks to work well on one-dimensional outputs.

In theory, the "multvargplvm" principle can also be applied to intermediate
latent nodes in a hierarchy. To summarize, in the full model we can select:
   
   * PARAMETERS for STRUCTURE:
   ________________________________________________________________________
    - The number H of hierarchical nodes and their dimensionalities
      Q_1, Q_2, ..., Q_H

    - The number S of outputs in the leaf nodes, Y_1, Y_2, ..., Y_S
        X_H -> X_{H-1} -> ... -> X_1 -> [Y_1, ..., Y_S]

    - Whether to define the number of outputs in the leaf nodes to be
      equal to the number of dimensions of a single dataset,
      i.e Yall would be [y_1, y_2, ..., y_d]

    - Whether to treat all intermediate layers X_1, ..., X_{H-1} as a
      single space, or if we will also apply the "multvargplvm" principle
      there and have many intermediate input/outputs, e.g.
      X_h would then be treated as [x_h;1, ..., x_h;q]
    

    * PARAMETERS for the actual MODEL:
    _______________________________________________________________________
     - The prior distribution of the parent, p(X_H). From version 1.0
       onwards, this prior can also be "dynamical", so that the parameters
       of the top layer are the reparametrized barmu, lambda and dynKern
       parameters. The constrain doesn't have to be dynamics (temporal), it
       can be anything, even given inputs so as to do "supervised learing".
     - The mappings F_h, h=1:H between the nodes (see below) => 
                 kernel parameters and inducing points for each node
     - variational parameters for each node.


    * Special case: MULTVARGPLVM (v. 0.1)
    _______________________________________________________________________

    This is the special case where the number of outputs is equal to the
    number of the single given output dimensions and we have only one
    layer of latent points (i.e. an svargplvm with a few tweaks to work
    well with the large number of one-dimensional outputs).



    * First implementation of HSVARGPLVM (v. 0.1) 
    _______________________________________________________________________
    
    In the current implementation of hsvargplvm, we treat the intermediate
    latent nodes as one space and the leaf nodes (outputs) can be treated
    either as one space, or subsets (like svargplvm), or one set per
    dimension (like multvargplvm). 




 
___________________________________________________________________________
########################## HSVARGPLVM ####################################
___________________________________________________________________________


_____________________________ ChangeLog

TODO: Make the model generic and allow H = 1 (that would be vargplvm/svargplvm).

* v.1.0: Complete (19/10/2012)
 Allow "dynamical" priors for the parent node. "Dynamical" means that it
 follows the framework of Damianou et al. NIPS 2011, but the actual input
 of the parent latent function does not need to be time, it can be anything
 or even given inputs, something which leads to deep GP regression.
 In this version I also fixed some bugs in the parallel code.

* v.0.2.3: Complete (15/9/2012)
 The hierarchies now are not limited to H=2! Any number of levels
 is now allowed.

* v.0.2.2: TODO (OK - done): Like v.0.1 but the intermediate layer is Q SEPARATE
  latent spaces.

* v.0.2.1: Complete, uploaded to SVN 9/9/2012 19:11 (changeSet 2468)
   Like v.0.1 but the intermediate layer can factorise wrt q.
   Affected files from previous version: 
       hsvargplvm_init, hsvargplvmOptions, hsvargplvmModelCreate,
       hsvargplvmUpdateStats, hsvargplvmLogLikelihood, 
       hsvargplvmLogLikeGradients

* v.0.1: Complete, uploaded to SVN 8/9/2012 23:45 (changeSet 2467)
  It's the version where we have only 3 layers 
  (leaves, 1 intermediate, 1 parent) and the intermediate is a signle space.

  


_____________________________ STRUCTURE
This is the model that implements the hierarchical vargplvm. The general
structure is:
X_H -> F -> X_{H-1} -> ... -> X_1 -> {F_1 -> Y_1, ..., F_M -> Y_M}
where H is the total number of layers, Y are the observed data which can
be split into M subsets (e.g. modalities) and all F's are associated with
different a) kernel parameters b) inducing points and all X's are associated
with different variational distribution. There is also a different beta
for each F. In other words, each F is a different GP.

X_H is the parent latent space
X_1:X_{H-1} are the intermediate ones.


* Definition: A model is all of the above associated with a different GP,
i.e a variational distribution, inducing points, beta, F.

* More than one models in the same layer are only allowed (for the moment)
in the leaf nodes (TODO: change that !!!). These models share a variational
distribution, exactly as in svargplvm.

* Models of different layers, are coupled as follows:
    model.y of layer h is the model.X of layer h-1.
    model.m of layer h is the centered data of layer h-1.
TODO: The equations at the moment do NOT include the bias, so model.m for 
layers > 1 are uncentered...


_____________________________ BOUND and derivatives

The bound is as follows: (see notes) - 5 different kinds of terms


_____________________________ Initialisation

Check the hsvargplvmModelCreate in combination with hsvargplvm_init.
In general, the values can either be given as a single variable (in which
case this value is inherited in all models), or as a cell array (in which
case a specific value is defined for each model). 


_____________________________ Optimisation

The optimisation can be done while initialising the variational
distributions of some layers and then normal optimisation.
This is done by calling:
    model = hsvargplvmPropagateField(model, 'initVardist', true,dims);
    model = hsvargplvmPropagateField(model, 'learnSigmaf', false,dims);
for the initialisation, and
    model = hsvargplvmPropagateField(model, 'initVardist', false,dims);
    model = hsvargplvmPropagateField(model, 'learnSigmaf', true,dims);
for afterwards. dims can be omitted to init. everything, but it is often
useful to only fix only the leaf layers (i.e. dims = 1), -at least for 
beta-, because the rest of the layers have different data variance in each
iteration and the SNR cannot be fixed. For this reason, it might be also
good to give a higher initSNR value to intermediate nodes, by using:
e.g. initSNR = {100, 200}; if there are two layers.

In the high level demos (e.g. tutorial.m) it is enough to just set the
desired iterations for initialising the var. distr (initVardistIters = ...)
and the initial SNR per layer (initSNR, as above). 

After optimisation, use hsvargplvmShowSNR(model) and
hsvargplvmShowScales(model) to see the results, and
hsvargplvmPlotX(model, layer, dims) to plot the dimensions.


!! Note that if rbfardjit is used as a mapping kernel, then its variance
(sigmaf) is always initialised to the variance of the data, var(m(:)),
so by keeping both sigmaf and beta fixed the SNR is fixed in a better
way that just fixing beta and using some other mapping kernel. 


___________________ Avoiding bad local optima

The optimisation procedure is gradient based, ie there is no an analytic
form to a unique solution. This means that the quality of the optimisation
is depending upon many things, mostly: initialisation, optimiser used,
numerical errors.

From the above, the easiest to control is the initialisation.
After optimisation, the function hsvargplvmCheckSNR(hsvargplvmShowSNR(model))
is automatically called, to check if a bad local minimum is reached.
If indeed a bad local optimum is reached (ie signal is very low compared to
noise), then the model is badly trained and the results are unreliable.

When this unfortunate scenario happens, please try a different initialisation,
for example:
    - increase the number of iterations for init. the var. distr. (initVardistIters).
    - increase the initial SNR
    - initialising the means of q(X) with a different method than the default 'pca',
      e.g. with vargplvm (see tutorial.m)
    - preprocess the data first, so that some noise is removed.
    - ...

_____________________________ Current issues

1) How to also segment X_h, h > 1? So that I can have the multvargplvm
approach in the intermediate layers? 
One way is v.0.2.1 above. Another is v.0.2.2
2) How to manage the fact that some of the dimensions of X_h are irrelevant
but nevertheless the upper level inherits all of the space? (hopefully
the upper level's scales will "understand" and "inherit" the information
about the irrelevant scales?), and this is the current solution.
3) How to handle the fact that the data variance of a model in layer h>1
always changes (since its data come from a X of the below layers which
changes)? Does that affect the optimisation of beta of that particular
layer? SNR should be relatively high and it depends on the variance of
the data and the value of beta. The current solution just allows to set
the parameter beta for the intermediate layers to a very large value. The
SNR of course will change during optimisation since the "data" part also
changes, but the very large value for beta might do the trick. Or we can
"manually" start by average beta, do a few iters. with beta fixed, then 
make it bigger according to the new SNR, etc.



___________________________________________________________________________
                                                                      ...



________________________________________________________________________
 
