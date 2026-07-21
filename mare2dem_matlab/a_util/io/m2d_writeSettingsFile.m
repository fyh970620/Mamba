function m2d_writeSettingsFile(sFile,tolerance,TxPerGroup,CSEMRxPerGroup,MTRxPerGroup,MTFreqPerGroup,nCSEMFreqPerGroup,bOverwrite)
%
% Creates a  MARE2DEM settings file (usually named mare2dem.settings) that
% can be used to configure the parallel data decomposition
%
% Kerry Key
% Scripps Institution of Oceanography
%
if ~exist('bOverwrite','var') || isempty(bOverwrite)
    bOverwrite = false;
end

if exist( sFile,'file')
    if ~bOverwrite
        return; % if file exists, don't overwrite it
    end  
%     choice = questdlg('Warning: The MARE2DEM settings file already exists, shall I overwrite it?','Warning! ', 'Yes','No','No');
%     switch choice
%         case 'No'
% 
%             display('Not saving settings file...')
%             return
%     end
end

% Else do it:

if ~exist('tolerance','var')  || isempty(tolerance)
    tolerance = 1;
end
if ~exist('TxPerGroup','var')  || isempty(TxPerGroup)
    TxPerGroup = 10;
end
if ~exist('CSEMRxPerGroup','var')  || isempty(CSEMRxPerGroup)
    CSEMRxPerGroup = 40;
end
 
if ~exist('MTRxPerGroup','var') || isempty(MTRxPerGroup)
    MTRxPerGroup = 40;
end
if ~exist('MTFreqPerGroup','var') || isempty(MTFreqPerGroup)
    MTFreqPerGroup = 1;
end

if ~exist('nCSEMFreqPerGroup','var') || isempty(nCSEMFreqPerGroup)
    nCSEMFreqPerGroup = 1;
end

fid = fopen(sFile,'W');
fprintf(fid,'Tolerance (%%):                    %i  ! target solution accuracy (not guaranteed, but the code tries hard to get there).\n',tolerance);
fprintf(fid,'\n!\n! CSEM settings:\n!\n'); 
fprintf(fid,'Transmitters per group:           %i     ! set this <= 10\n',TxPerGroup); 
fprintf(fid,'CSEM receivers per group:         %i    ! adjust to maximize cluster usage\n',CSEMRxPerGroup);
fprintf(fid,'CSEM frequencies per group:       %i     ! this should be 1, or no more than the number of freqs per decade if you want to lighten the load\n',nCSEMFreqPerGroup);   
fprintf(fid,'Use mesh coarsening:              yes   ! Use a moving vertical window to simplify the mesh to the left and right of the transmitters\n');
fprintf(fid,'                                        ! and receivers in a given data subset. Only inversion parameters are coarsened and this is only done for CSEM\n');
fprintf(fid,'                                        ! modeling tasks. This can greatly speed up modeling of very long profiles of data.\n');
                                        
fprintf(fid,'\n!\n! MT settings:\n!\n'); 
fprintf(fid,'MT receivers per group:           %i    ! adjust to maximize cluster usage \n',MTRxPerGroup);
fprintf(fid,'MT frequencies per group:         %i     ! this should be 1, or no more than the number of freqs per decade if you want to lighten the load\n',MTFreqPerGroup);   
fprintf(fid,'Use MT scattered field:           no    ! Uncomment and set this to yes to use a scattered field MT formulation. This is useful for getting accurate deepwater resistive \n'  );   
fprintf(fid,'                                        ! lithosphere seafloor MT responses, but MARE2DEM may run a bit more slowly. ');

fprintf(fid,'\n\n');
fprintf(fid,'Print adaptive:                   yes   ! yes prints the adaptive refinement iteration stats\n');
fprintf(fid,'Print decomposition:              yes   ! yes prints the parallel decomposition settings\n');
fprintf(fid,'\n!\n! Advice:\n!\n'); 
fprintf(fid,'! See the Parallel Decomposition terminal output when running MARE2DEM.\n'); 
fprintf(fid,'! Try adjusting the receivers per group so that the total number of refinement groups\n'); 
fprintf(fid,'! is at least as large as the number of MPI processors on your computing system.\n'); 


fclose(fid); 
