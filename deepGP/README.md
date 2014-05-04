deepGP v.1.0
========

Matlab code for deep Gaussian processes (Damianou and Lawrence, AISTATS 2013)

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

Getting started:
 - Please check deepGP/html/index.html for a short overview of this package (TODO!).
 - Check deepGP/matlab/README.txt for a quick manual.
 - Check deepGP/matlab/tutorial.m for introductory demonstrations.