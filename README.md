deepGP v.1.0
========

Matlab code for deep Gaussian processes (Damianou and Lawrence, AISTATS 2013)

Dependencies graph:
- (1) vargplvm - Bayesian GPLVM/VGPDS/MRD toolbox: https://github.com/SheffieldML/vargplvm
- (2) GPmat - Neil Lawrence's GP matlab toolbox: https://github.com/SheffieldML/GPmat
- (3) Netlab v.3.3: <s>http://www1.aston.ac.uk/ncrg/</s> Mirror (untested): https://uk.mathworks.com/matlabcentral/fileexchange/2654-netlab 
- (4) Isomap.m: https://www.mathworks.com/matlabcentral/mlc-downloads/downloads/submissions/62449/versions/1/previews/IsoMap.m/index.html
- (5) L2_distance.m: https://adamian.github.io/var/L2_distance.m 
- (6) keep.m: http://www.mathworks.com/matlabcentral/fileexchange/181-keep/content/keep.m

L2_distance ---- Isomap ---- GPmat ---- vargplvm ---- deepGP
							/			/
				Netlab ----------------

Getting started:
 - Please check deepGP/html/index.html for a short overview of this package.
 - Check deepGP/matlab/README.txt for a quick manual.
 - Check deepGP/matlab/tutorial.m for introductory demonstrations.
