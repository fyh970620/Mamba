# README #

### Installation ###

 1. Download the MARE2DEM_MATLAB package, which contains this README file.
 2. Place that folder somewhere safe on the computer where you intend to run MATLAB.
 3. Open MATLAB, click the "Add Path" button and add the MARE2DEM_MATLAB folder and its subdirectories.
    Hit the save button.
 4. All done, now you can use the MATLAB routines.
     
### Main routines ###

* Mamba2D - used for creating MARE2DEM models for forward modeling and inversion.
* plotMARE2DEM - used to plot MARE2DEM inversion model results and to overlay various additional data such as wells and seismic SEGY images.
* plotMARE2DEM_MT
* plotMARE2DEM_CSEM

### Helper routines ###

* The files in subfolder a_util are the helper routines. Most users won't use these directly ever. But if you are a code writer and want to write your own hooks for MARE2DEM, you might find some of the helper routines useful. See for example the m2d_*.m routines.