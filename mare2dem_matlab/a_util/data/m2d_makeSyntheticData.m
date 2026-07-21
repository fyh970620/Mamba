function m2d_makeSyntheticData(sInFile,sOutFile,stNoise)
%
% m2d_makeSyntheticData(sInFile,sOutFile,stNoise)
% reads in MARE2DEM response file sInFile, adds synthetic random Gaussian 
% noise usings the settings in structure stNoiseLevels and saves to file
% sOutFile.
%
% Inputs:
%
%   sInFile  - name of the MARE2DEM .resp file to read in (e.g.
%              model.0.resp). If file is not in current directory, the
%              name should include the path to the file.
%
%   sOutFile - name of the output MARE2DEM data file to output. 
%              (e.g. synthetic.emdata) 
%
%   stNoise  - structure specifying noise levels to use. You only need to
%              specify the fields for the data type in the input file 
%              (i.e. if you only have MT data, you only need to specify 
%              stNoise.mt.relNoise). Fields:
%
%     stNoise.mt.relNoise  - relative noise to add to MT responses
%                            (e.g. 0.05 means add 5% Gaussian noise). Note
%                            this is the relative error in apparent
%                            resistivity. Phase noise will be 0.5*relNoise.
%                            ( as can be shown by propagation of error from
%                            the impedance to app. res. and phase).
%       
%     stNoise.mt.relNoise_tipper - e.g. 1%
%
%     stNoise.mt.absNoise_tipper - e.g. 0.01
% 
%     stNoise.csem.relNoiseE - relative noise to add to CSEM electric field 
%                              responses (e.g. 0.05 means add 5% Gaussian noise).
%
%     stNoise.csem.minAmpE - Electric field responses below this amplitude 
%                            are omitted from the output data file.   
%                            KWK to do: NOT YET IMPLEMENTED
%                          
%     stNoise.csem.relNoiseB - relative noise to add to CSEM magnetic field 
%                              responses (e.g. 0.05 means add 5% Gaussian noise).
%
%     stNoise.csem.minAmpB - Magnetic field responses below this amplitude 
%                            are omitted from the output data file.
%                            KWK to do: NOT YET IMPLEMENTED
%
% Workflow:
% 
%  m2d_makeSyntheticData creates synthetic noisy data to use for
%  synthetic inversion studies. The general workflow is:
% 
%  0) Use m2d_makeDataFile.m to make a data file for forward modeling
%  1) Compute forward responses for the particular model of interest 
%  2) Use this routine to add synthetic random noise to the forward
%     responses to create synthetic data suitable for inversion studies.
%  3) Create an inversion model grid and invert the synthetic data to see
%     how well the data and model parameterization can resolve the original 
%     structure. 
%  
% This routine is a wrapper for function
% m2d_addSyntheticNoise() which does the actual synthetic noise addition.
% 
% Kerry Key
% Lamont-Doherty Earth Observatory
%   

%
% Check input arguments
%
    % kwk debug: to code...

%
% Read in input resp file:
%
st = m2d_readEMData2DFile(sInFile);

%
% Add synthetic noise:
%
st = m2d_addSyntheticNoise(st,stNoise);

%
% Save to sOutputSyntheticDataFile:
% 
m2d_writeEMData2DFile(sOutFile,st) 

 