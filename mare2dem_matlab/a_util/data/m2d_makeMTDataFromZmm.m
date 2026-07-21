function m2d_makeMTDataFromZmm(cFileList,sOutputFileName,sOutputModes,nErrorFloorTE,nErrorFloorTM,...
                               nOmitPeriods,nLineOrientation,nDeclination,nUTM0,sUTMzone, ...
                               stTopo, nRxZTopoOffset,nErrorFloorTipper)
%
% m2d_makeMTDataFromZmm(cFileList,sOutputFileName,sOutputModes,nErrorFloorTE,nErrorFloorTM,
%                       nOmitPeriods,nLineOrientation,nDeclination,nUTM0,sUTMzone,...
%                       stTopoCfg,nRxZTopoOffset)
%
% Function to create a MARE2DEM format MT data file from .zmm format MT responses.
% 
% Input arguments:
%
% cFileList         - cell array of .zmm files to include in the date
%                     file. Ideally these should be input in the correct
%                     order going down the survey profile. 
%
% sOutputFileName   - name of output data file (e.g., 'Line1.emdata')
%
% sOutputModes      - 'all','all impedance','TE','TM','tipper','TE+tipper'
%                     note: 'all' is everything including any tippers.
%                     'all impedance' is just TE + TM apparent resistivity
%                     and phase.
%
% nErrorFloorTE     - relative error floor (i.e.  0.01 means 1% error floor)
%
% nErrorFloorTM     - same as above
% nErrorTipper      - ABSOLUTE error floor of tipper vector real and
%                     imaginary components. E.g. 0.01
%
% nOmitPeriods      - [#Bands x 2] array with period bands to omit from the
%                     output. For example, to omit 5 to 15 s and 1000 to
%                     10000s use nOmitPeriods = [5 15; 1000 10000];
%
% nLineOrientation  - (optional) orientation to use for the survey profile.
%                     Degrees clockwise from geographic north. Use empty []
%                     to have the code instead fit a line to the input
%                     stations to determine the line orienation.
%
% nDeclination      - (optional) geomagnetic declination to correct for.
%                     Use 0 or empty [] to NOT correct for declination. 
%                     This correction is needed when the zmm files have 
%                     geomnagetic orientations and hence need to 
%                     be corrected to geographic orientation.
% nUTM0             - (optional) UTM values for [northing, easting] (m)
%
% sUTMzone          - (optional) character string with UTM grid zone (e.g., '11N')
%
%
% stTopo            - (optional). Structure specifying the columns in a topography
%                      file. Structure can have these elements:
%                      stTopo.sTopoFile       - name of topo file (required)
%                      stTopo.colLongitude  
%                      stTopo.colLatitude
%                      stTopo.colElevationMeters   (either this or colDepthMeters required )
%                      stTopo.colDepthMeters      
%                      stTopo.colDistanceKm    (either this or colLongitude & colLatitude required )
%                      stTopo.colDistanceMeters  (either this, km version, or colLongitude & colLatitude required )
% 
%                    The topography file must have at least two columns. In
%                    general it will be either:
%
%                     (1) Two column file with along line position and depth 
%                         This also requires UTM0 to be set above. Then
%                         set:
%                         stTopo.colDistanceKm  = 1
%                         stTopo.colDepthMeters = 2
%
%                     (2) GeoMapApp style topography file with 4 columns 
%                         Older GeoMapApp used:   [Longitude Latitude Elevation(m) Distance (km)  ]
%                         While newer (2017) files have [Longitude Latitude Distance (km) Elevation (m) ]
%                            stTopo.colLongitude  = 1;
%                            stTopo.colLatitude   = 2;
%                            stTopo.colElevationMeters = 4;   
%                            stTopo.colDistanceKm = 3    
%                        
%                      
%
%
% nRxZTopoOffset     - (optional). Requires sTopoFile . Vertical offset for positioning MT receivers near but 
%                       not directly on topography since MARE2DEM gets confused if Rx directly on a boundary.
%                       Since z is positive down, use small negative value
%                       (-0.1) to put seafloor receivers above seafloor.
%                       For land MT use small positive value to put
%                       receiver below land surface.   
%
% 
                       
% Written by:
%
% Kerry Key
% Lamont-Doherty Earth Observatory
% Columbia University
%
% Includes helper subfunctions from the MATLAB routines distributed with
% Egbert's EMTF codes.
%
%
% KWK developer notes: should move to a single input structure with fields
% for the various options, that way they can be added with growing the
% input argument list. For example I just added nErrorTipper but its at the
% end of the list since otherwise that might break existing data munching codes that
% calling this. With a strucure, new input options don't change the calling
% syntax.
%


%
% Parse some of the input arguments:
%
if ~exist('cFileList','var') || isempty(cFileList) 
    h = errordlg('No input list of zmm files to read given. Please list files in argument cFileList. Try again. ','m2d_makeMTDataFromZmm Error','modal');
    waitfor(h);
    return;     
end
if ~exist('sOutputFileName','var') || isempty(sOutputFileName) 
    h = errordlg('No output file name given. Try again. ','m2d_makeMTDataFromZmm Error','modal');
    waitfor(h);
    return;     
end
if ~exist('nLineOrientation','var')  
    nLineOrientation = [];
end
if ~exist('nDeclination','var') || isempty(nDeclination) 
    nDeclination = 0;
end
if ~exist('sOutputModes','var') || isempty(sOutputModes) 
    sOutputModes = 'all';
end
if ~exist('nErrorFloorTE','var') || isempty(nErrorFloorTE) 
    nErrorFloorTE = 0;
end
if ~exist('nErrorFloorTM','var') || isempty(nErrorFloorTM) 
    nErrorFloorTM = 0;
end
if ~exist('nErrorFloorTipper','var') || isempty(nErrorFloorTipper) 
    nErrorFloorTipper = 0;
end
if ~exist('nOmitPeriods','var') 
    nOmitPeriods = [];
end
if ~exist('nUTM0','var')  
    nUTM0 = [];
end
if ~exist('sUTMzone','var')  
    sUTMzone = '';
end
if ~exist('stTopo','var') 
    stTopo = [];
else
    if ~exist('nRxZTopoOffset','var') || isempty(nRxZTopoOffset) 
        h = errordlg('Error, nRxZTopoOffset input was not specified... Try again!','m2d_makeMTDataFromZmm Error','modal');
        waitfor(h);
        return;         
    end
end

  
%---------------------------------------------------------------------------
fprintf('\n\n Processing MT data files for new data file %s ...\n',(sOutputFileName))

%
% Note: the sub functions below have repetitive reading of the files in
% order to get the line orientation and UTM positions, prior to rotating
% the impedances, and it was easiest to program this with multiple file
% reads rather than passing around all the zmm related arrays.
%

% Get the UTM zone if not given:
[~, sUTMzone] = sub_getUTMZone(sUTMzone,cFileList);

% Get nLineOrientation if not given:
nLineOrientation = sub_getLineOrientation(nLineOrientation,cFileList,sUTMzone);
 
% Read in the zmm files:
nRotateTo = nLineOrientation-90-nDeclination; % nLineOrientation-90 so TE mode is perpendicular to line direction, also apply declination correction
st        = sub_readAndRotateZmmFiles(cFileList,nRotateTo);
    
%
% Check that data all have the same period bands since this code doesn't
% yet support multiple zmm files that have different period bands
lOkay = sub_checkPeriodsMatch(st);
if ~lOkay
    return
end

% Project stations onto line:
[st,nUTM0] = sub_projectOntoLine(st,nUTM0,nLineOrientation);

% Subset data based on requested modes and frequency bands:
st = sub_omitPeriods(st,nOmitPeriods);

% Apply error floor:
st = sub_applyErrorFloor(st,nErrorFloorTE,nErrorFloorTM,nErrorFloorTipper);

% Create arrays need for MARE2DEM:
[stMT,stUTM,DATA] = sub_createM2DArrays(st,sOutputModes,nLineOrientation,nUTM0,sUTMzone);

% If topography filename input, process it and drop receiver vertical
% position relative to topography:
stMT = sub_importTopoAndDrapeRecievers(st,stMT,stUTM,stTopo,nRxZTopoOffset,sOutputFileName);

% Save to MARE2DEM format data file:
sub_saveToM2DFile(sOutputFileName,stMT,stUTM,DATA);

% Display summary of operations and some metrics:
    %kwk debug: to do

% Goodbye message:
h = msgbox('All done combining the .zmm MT responses into a MARE2DEM data file','m2d_makeMTDataFromZmm.m','modal');
waitfor(h);
    
end

%--------------------------------------------------------------------------
function [stMT,stUTM,DATA] = sub_createM2DArrays(st,sOutputModes,nLineOrientation,nUTM0,sUTMzone)

% Fill in stMT structure:
stMT.frequencies  = 1./st(1).periods;
stMT.receiverName = {st.station};
z0s               = zeros(length(st),1);
stMT.receivers    = [ [st.x]' [st.y]' [st.z]' z0s z0s z0s z0s z0s];    %[x y z theta alpha beta length iSolveStatic]

% Fill in stUTM structure:
stUTM.grid   = sscanf(sUTMzone,'%i');
stUTM.hemi   = char(sscanf(sUTMzone,'%*i%c'));

stUTM.north0 = nUTM0(1);
stUTM.east0  = nUTM0(2);
stUTM.theta  = nLineOrientation-90; % theta is 'x' (aka conductivity strike) direction for 2D model
 
% Create DATA array:

DATA = zeros(length(stMT.frequencies)*length(stMT)*4,6);

ict = 0;
for ifreq = 1:length(stMT.frequencies)
 
    for irx = 1:length(st)
        
        switch lower(sOutputModes)
            
            case {'all','all impedance','te','te+tipper'}
            
            DATA(ict+1  ,1) = 123;  % log10 Z TE
            DATA(ict+1  ,2) = ifreq;
            DATA(ict+1  ,3) = irx;
            DATA(ict+1  ,4) = irx;
            DATA(ict+1  ,5) = log10(st(irx).apresTE(ifreq));
            DATA(ict+1  ,6) = st(irx).apresTE_se(ifreq)./st(irx).apresTE(ifreq)*0.4343; % covnert linear uncertainty to log10 uncertainty
            
            DATA(ict+2  ,1) = 104;  % phase TE
            DATA(ict+2  ,2) = ifreq;
            DATA(ict+2  ,3) = irx;
            DATA(ict+2  ,4) = irx;
            DATA(ict+2  ,5) = st(irx).phaseTE(ifreq);
            DATA(ict+2  ,6) = st(irx).phaseTE_se(ifreq); 
            
            ict = ict + 2;
            
        end
        
        switch lower(sOutputModes)
            
            case {'all','all impedance','tm'}
               
            DATA(ict+1  ,1) = 125;  % log10 Z TM
            DATA(ict+1  ,2) = ifreq;
            DATA(ict+1  ,3) = irx;
            DATA(ict+1  ,4) = irx;
            DATA(ict+1  ,5) = log10(st(irx).apresTM(ifreq));
            DATA(ict+1  ,6) = st(irx).apresTM_se(ifreq)./st(irx).apresTM(ifreq)*0.4343; % covnert linear uncertainty to log10 uncertainty
            
            DATA(ict+2  ,1) = 106;  % phase TM
            DATA(ict+2  ,2) = ifreq;
            DATA(ict+2  ,3) = irx;
            DATA(ict+2  ,4) = irx;
            DATA(ict+2  ,5) = st(irx).phaseTM(ifreq);
            DATA(ict+2  ,6) = st(irx).phaseTM_se(ifreq); 
            
            ict = ict + 2;
            
        end
        
        switch lower(sOutputModes)
            
            case {'all','tipper','te+tipper'}
 
            DATA(ict+1  ,1) = 133;  % real tipper
            DATA(ict+1  ,2) = ifreq;
            DATA(ict+1  ,3) = irx;
            DATA(ict+1  ,4) = irx;
            DATA(ict+1  ,5) = real(st(irx).tipperZY(ifreq));
            DATA(ict+1  ,6) = st(irx).tipperZY_se(ifreq);
            
            DATA(ict+2  ,1) = 134;  % imag tipper
            DATA(ict+2  ,2) = ifreq;
            DATA(ict+2  ,3) = irx;
            DATA(ict+2  ,4) = irx;
            DATA(ict+2  ,5) = imag(st(irx).tipperZY(ifreq));
            DATA(ict+2  ,6) = st(irx).tipperZY_se(ifreq);
            
            ict = ict + 2;
            
        end                
        
    end
end
DATA = DATA(1:ict,:);

end

%--------------------------------------------------------------------------
function sub_saveToM2DFile(sOutputFileName,stMT,stUTM,DATA)
% write the data file

stCSEM = [];
sComment = sprintf('Data created with routine m2d_makeMTDataFromZmm.m on %s',datestr(now));
m2d_writeEMData2DFile(sOutputFileName,sComment,stUTM,stCSEM,stMT,DATA) 

end


%--------------------------------------------------------------------------
function [stMT] = sub_importTopoAndDrapeRecievers(st,stMT,stUTM,stTopo,nRxZTopoOffset,sOutputFileName)
 
    if isempty(stTopo)
        h = warndlg('Warning, no topography file given so MT receivers will not have the correct depths! You have been warned..','Warning','modal');
        waitfor(h);
        return
    end
    % Load profile and do any conversions needed to get into
    % [position(m),depth(m)]
    [stTopo, lOkay] = m2d_importTopo(stTopo,stUTM);
    if ~lOkay
        return
    end
    
    topo = [stTopo.yTopo stTopo.zTopo];
                   
    % Now simplify the topography to reduce the Mamba2D meshing burdent
    % unnecessearily:
    tol = 1; % 1 m tolerance. Points colinear +- 1 m are removed to simplify the topography.
    topo = dpsimplify(topo,tol);
    
    % save simplified topo:
    [p,n] = fileparts(sOutputFileName);
    
    sNewTopoFile = fullfile(p,strcat(n,'_TopoSimplified.txt'));
    
    save(sNewTopoFile,'topo','-ascii');
    
    % This can be an external function since its useful for MT and CSEM
    % receivers:
    
    % Get topographic slope:
    dy         = diff(topo(:,1));
    dz         = diff(topo(:,2));
    slopeAngle = 180/pi*atan2(dz,dy);
 

    for i = 1:size(stMT.receivers,1)
    
       RxYpos = stMT.receivers(i,2);
       
       zTopo = interp1(topo(:,1),topo(:,2),RxYpos);
       
       newRxZ = zTopo + nRxZTopoOffset;
        
       iSeg = find( RxYpos - topo(:,1) > 0,1,'last');
       
       beta   = slopeAngle(iSeg); 
 
       %fprintf('0 %8.1f %8.1f 0 0 %6.1f 0 %s\n',RxYpos,newRxZ,beta, stMT.receiverName{i})

       % Modify station z position and tilt in stMT:
       stMT.receivers(i,1) = 0;
       stMT.receivers(i,3) = newRxZ;
       stMT.receivers(i,6) = beta;

    end
    
    

    % Check that topography profile is consistent with the MT receiver
    % profile:
    
    figure;
    
    %Plot on longitude and latitude:
    
    subplot(1,3,1);
    pos = [st.stdec];
  
    plot( stTopo.topo(:,stTopo.colLongitude), stTopo.topo(:,stTopo.colLatitude),'b-')
    hold on;
    plot(pos(2,:),pos(1,:),'ro')
    title('Long/Lat: topo (black), receivers (red o)');
    xlabel('Longitude')
    ylabel('Latitude')

    subplot(1,3,2);
    
    plot( stTopo.nTopoE,stTopo.nTopoN,'b-')
    hold on;
    plot([st.nEasting],[st.nNorthing],'ro')
    title('UTM: topo (black), receivers (red o)');
    xlabel('Easting (m)')
    ylabel('Northing (m)')  
    
    subplot(1,3,3);
    
    plot( stTopo.yTopo/1d3,stTopo.zTopo,'b-')
    hold on;
    plot( stMT.receivers(:,2)/1d3,stMT.receivers(:,3),'ro')
    title('Profile: topo (black) and receivers (red o)');
    xlabel('Position (km)')
    ylabel('Depth (m)')  ;
    axis ij
    
    text(stMT.receivers(:,2)/1d3,stMT.receivers(:,3),stMT.receiverName,'verticalalignment','bottom');
    

end
%--------------------------------------------------------------------------
function lOkay = sub_checkPeriodsMatch(st)

    lOkay = true;
    for iFile = 1:length(st)
        if iFile == 1
            periods1 = st(iFile).periods;
        else
            if any( abs(st(iFile).periods-periods1)./periods1 > .01) % if different by more than 1%. This allows for negligible differences due to rounding errors.
                h = errordlg('Error, the zmm files need to have the same period sampling. Aborting...','Error','modal');
                waitfor(h);
                lOkay = false;
                return;
            end
        end
    end
    
end
%--------------------------------------------------------------------------
function st = sub_applyErrorFloor(st,nErrorFloorTE,nErrorFloorTM,nErrorFloorTipper)
 
for iFile = 1:length(st)
    
    st(iFile).apresTE_se = sub_setErrFlrApRes(st(iFile).apresTE_se,st(iFile).apresTE,nErrorFloorTE);
    st(iFile).apresTM_se = sub_setErrFlrApRes(st(iFile).apresTM_se,st(iFile).apresTM,nErrorFloorTM);
    st(iFile).phaseTE_se = sub_setErrFlrPhase(st(iFile).phaseTE_se,nErrorFloorTE);
    st(iFile).phaseTM_se = sub_setErrFlrPhase(st(iFile).phaseTM_se,nErrorFloorTM);     
    
    if ~isempty(st(iFile).tipperZY)
        st(iFile).tipperZY_se = sub_setErrFlrTipper(st(iFile).tipperZY_se,nErrorFloorTipper);   
    end
end

end

%--------------------------------------------------------------------------
function se = sub_setErrFlrApRes(se,apres,nErrorFloor)

    lTooSmall     = se./apres < nErrorFloor;    

    se(lTooSmall) = apres(lTooSmall)*nErrorFloor;

end
%--------------------------------------------------------------------------
function se = sub_setErrFlrPhase(se,nErrorFloor)

    lTooSmall     = se < nErrorFloor*180/pi/2;    

    se(lTooSmall) = nErrorFloor*180/pi/2;

end
%--------------------------------------------------------------------------
function se = sub_setErrFlrTipper(se,nErrorFloor)

    lTooSmall     = se < nErrorFloor; 

    se(lTooSmall) = nErrorFloor;

end
%--------------------------------------------------------------------------
function st = sub_omitPeriods(st,nOmitPeriods)

if isempty(nOmitPeriods)
    return
end

periods = st.periods;

lKeep = true(size(periods));

for i = 1:size(nOmitPeriods,1)
    
    lRemove = periods >= nOmitPeriods(i,1) & periods <= nOmitPeriods(i,2);
    lKeep(lRemove) = false;
end

if any(~lKeep)
    
    for iFile = 1:length(st)
        
        st(iFile).periods     = st(iFile).periods(lKeep);
        st(iFile).apresTE     = st(iFile).apresTE(lKeep);
        st(iFile).phaseTE     = st(iFile).phaseTE(lKeep);
        st(iFile).apresTM     = st(iFile).apresTM(lKeep);
        st(iFile).phaseTM     = st(iFile).phaseTM(lKeep);
        st(iFile).apresTE_se  = st(iFile).apresTE_se(lKeep);
        st(iFile).phaseTE_se  = st(iFile).phaseTE_se(lKeep);
        st(iFile).apresTM_se  = st(iFile).apresTM_se(lKeep);
        st(iFile).phaseTM_se  = st(iFile).phaseTM_se(lKeep); 
        
        if ~isempty(st(iFile).tipperZY)
            st(iFile).tipperZY = st(iFile).tipperZY(lKeep);
            st(iFile).tipperZY_se = st(iFile).tipperZY_se(lKeep);
        end
        
    end
end
end

%--------------------------------------------------------------------------
function [st,nUTM0] = sub_projectOntoLine(st,nUTM0,nLineOrientation)
% Projects MT stations onto a survey Line and sorts stMT by position along
% the line. Also sets nUTM0 if none given.


% Map nLineOrientation to 0 to 360 degrees:
if nLineOrientation < 0 
    nLineOrientation = nLineOrientation + 360;
end

northings = [st.nNorthing];
eastings  = [st.nEasting];

% Get the line sorting order based on line orientation:
if nLineOrientation >= 315 || nLineOrientation <= 45
    [~,isort] = sort(northings);

elseif nLineOrientation > 135 && nLineOrientation <= 225
    [~,isort] = sort(northings(:),1,'descend');   

elseif nLineOrientation > 45 && nLineOrientation <= 135
    [~,isort] = sort(eastings);

elseif nLineOrientation > 225 && nLineOrientation < 315
    [~,isort] = sort(eastings(:),1,'descend');
    
end
    
if isempty(nUTM0) % use first receivers position
   nUTM0 = [northings(isort(1)), eastings(isort(1))];   
end    
 
% Now place stations in order along the profile:
st = st(isort);
 
% Now project stations onto the survey line:
dN = [st.nNorthing] - nUTM0(1);
dE = [st.nEasting]  - nUTM0(2);

theta = nLineOrientation - 90;

cc = cosd(theta);
ss = sind(theta); 

x  =  cc*dN + ss*dE;
y  = -ss*dN + cc*dE;

for iFile = 1:length(st)
    st(iFile).x = x(iFile);
    st(iFile).y = y(iFile);
    st(iFile).z = 0;
end

end

%--------------------------------------------------------------------------
function [nUTMzone, sUTMzone] = sub_getUTMZone(sUTMzone,cFileList)

if ~isempty(sUTMzone)
    nUTMzone = sscanf(sUTMzone,'%f',1);
else
    
    % read in a data file and get UTM zone from its latitude and longitude:
    stZmm = getApResFromZmm( cFileList{1}, [] );
    
    [~,~, nUTMzone,bHemiS] = LonLat2UTM( stZmm.nLongitude, stZmm.nLatitude );   
    
    if bHemiS
        sUTMzone = sprintf('%iS',nUTMzone);
    else
        sUTMzone = sprintf('%iN',nUTMzone);
    end
        
end

end


%--------------------------------------------------------------------------
function st = sub_readAndRotateZmmFiles(cFileList,nRotateTo)

    st = struct();
    
    for iFile = 1:length(cFileList)
 
        % New March 2020: use master routine getApResFromZmm.m to get all MT quantitites
        % from file:
        stZmm = getApResFromZmm( cFileList{iFile}, nRotateTo );
        
        % move needed elements from stZmm into structure st:
        iTE = strncmp('xy',stZmm.nOrder,2);
        iTM = strncmp('yx',stZmm.nOrder,2);
        
        st(iFile).station    = stZmm.sName;
        st(iFile).periods    = stZmm.nPrds;
        st(iFile).apresTE    = stZmm.nRho(:,iTE);
        st(iFile).phaseTE    = stZmm.nPhs(:,iTE);
        st(iFile).apresTE_se = stZmm.nRhoErr(:,iTE);
        st(iFile).phaseTE_se = stZmm.nPhsErr(:,iTE);        
        st(iFile).apresTM    = stZmm.nRho(:,iTM); 
        st(iFile).phaseTM    = stZmm.nPhs(:,iTM)+180; % kwk debug: wrap TM phase to 1st quadrant for MARE2DEM
        st(iFile).apresTM_se = stZmm.nRhoErr(:,iTM); 
        st(iFile).phaseTM_se = stZmm.nPhsErr(:,iTM);  
        
        st(iFile).tipperZY      = stZmm.nTzy;
        st(iFile).tipperZY_se   = stZmm.nTzyErr;
        
        st(iFile).nLongitude = stZmm.nLongitude;
        st(iFile).nLatitude  = stZmm.nLatitude;
 
        % Convert latitude and longitude to UTM positions:
        [st(iFile).nEasting,st(iFile).nNorthing, st(iFile).nUTMzone,st(iFile).bHemiS] = LonLat2UTM( st(iFile).nLongitude, st(iFile).nLatitude ); 
          
        
    end


end

%--------------------------------------------------------------------------
function nLineOrientation = sub_getLineOrientation(nLineOrientation,cFileList,sUTMgrid)
    
    % if line orientation given, nothing else to do here so return
    if ~isempty(nLineOrientation)
        return
    end
     
    fprintf('\n Solving for line orientation since no input given...\n')
    fprintf(' Line orientation detemined to be %.1f degrees clockwise from North\n\n',nLineOrientation)
    
    
    % Check for requested UTM zone:
    nForceZone = [];
    if ~isempty(sUTMgrid)
        nForceZone = sscanf(sUTMgrid,'%f',1);
    end
    
   % Read all stations and get longitudes and latitudes:
    nLatLot = zeros(length(cFileList),2);
    
    for iFile = 1:length(cFileList)      
        
        stZmm = getApResFromZmm( cFileList{iFile}, [] );
        
        nLatLot(iFile,1) = stZmm.nLatitude;       
        nLatLot(iFile,2) = stZmm.nLongitude;
        
        
    end
    
    % Convert to UTM:
    [nEastings,nNorthings, ~,~] = LonLat2UTM( nLatLot(:,2), nLatLot(:,1),nForceZone );    
    
    % Get line orientation by fitting line to points:
    nLineOrientation =  m2d_getLineOrientation(nNorthings,nEastings);
   
 
end
 
function [ps,ix] = dpsimplify(p,tol)
% Recursive Douglas-Peucker Polyline Simplification, Simplify
%
% [ps,ix] = dpsimplify(p,tol)
%
% dpsimplify uses the recursive Douglas-Peucker line simplification 
% algorithm to reduce the number of vertices in a piecewise linear curve 
% according to a specified tolerance. The algorithm is also know as
% Iterative Endpoint Fit. It works also for polylines and polygons
% in higher dimensions.
%
% In case of nans (missing vertex coordinates) dpsimplify assumes that 
% nans separate polylines. As such, dpsimplify treats each line
% separately.
%
% For additional information on the algorithm follow this link
% http://en.wikipedia.org/wiki/Ramer-Douglas-Peucker_algorithm
%
% Input arguments
%
%     p     polyline n*d matrix with n vertices in d 
%           dimensions.
%     tol   tolerance (maximal euclidean distance allowed 
%           between the new line and a vertex)
%
% Output arguments
%
%     ps    simplified line
%     ix    linear index of the vertices retained in p (ps = p(ix))
%
% Examples
%
% 1. Simplify line 
%
%     tol    = 1;
%     x      = 1:0.1:8*pi;
%     y      = sin(x) + randn(size(x))*0.1;
%     p      = [x' y'];
%     ps     = dpsimplify(p,tol);
%
%     plot(p(:,1),p(:,2),'k')
%     hold on
%     plot(ps(:,1),ps(:,2),'r','LineWidth',2);
%     legend('original polyline','simplified')
%
% 2. Reduce polyline so that only knickpoints remain by 
%    choosing a very low tolerance
%
%     p = [(1:10)' [1 2 3 2 4 6 7 8 5 2]'];
%     p2 = dpsimplify(p,eps);
%     plot(p(:,1),p(:,2),'k+--')
%     hold on
%     plot(p2(:,1),p2(:,2),'ro','MarkerSize',10);
%     legend('original line','knickpoints')
%
% 3. Simplify a 3d-curve
% 
%     x = sin(1:0.01:20)'; 
%     y = cos(1:0.01:20)'; 
%     z = x.*y.*(1:0.01:20)';
%     ps = dpsimplify([x y z],0.1);
%     plot3(x,y,z);
%     hold on
%     plot3(ps(:,1),ps(:,2),ps(:,3),'k*-');
%
%
%
% Author: Wolfgang Schwanghart, 13. July, 2010.
% w.schwanghart[at]unibas.ch

if nargin == 0
    help dpsimplify
    return
end
narginchk(2, 2)

% error checking
if ~isscalar(tol) || tol<0
    error('tol must be a positive scalar')
end

% nr of dimensions
nrvertices    = size(p,1); 
dims    = size(p,2);

% anonymous function for starting point and end point comparision
% using a relative tolerance test
compare = @(a,b) abs(a-b)/max(abs(a),abs(b)) <= eps;

% what happens, when there are NaNs?
% NaNs divide polylines.
Inan      = any(isnan(p),2);
% any NaN at all?
Inanp     = any(Inan);

% if there is only one vertex
if nrvertices == 1 || isempty(p)
    ps = p;
    ix = 1;

% if there are two 
elseif nrvertices == 2 && ~Inanp
    % when the line has no vertices (except end and start point of the
    % line) check if the distance between both is less than the tolerance.
    % If so, return the center.
    if dims == 2
        d    = hypot(p(1,1)-p(2,1),p(1,2)-p(2,2));
    else
        d    = sqrt(sum((p(1,:)-p(2,:)).^2));
    end

    if d <= tol;
        ps = sum(p,1)/2;
        ix = 1;
    else
        ps = p;
        ix = [1;2];
    end

elseif Inanp;
    % case: there are nans in the p array
    % --> find start and end indices of contiguous non-nan data
    Inan = ~Inan;
    sIX = strfind(Inan',[0 1])' + 1; 
    eIX = strfind(Inan',[1 0])'; 

    if Inan(end)==true;
        eIX = [eIX;nrvertices];
    end

    if Inan(1);
        sIX = [1;sIX];
    end

    % calculate length of non-nan components
    lIX = eIX-sIX+1;   
    % put each component into a single cell
    c   = mat2cell(p(Inan,:),lIX,dims);

    % now call dpsimplify again inside cellfun. 
    if nargout == 2;
        [ps,ix]   = cellfun(@(x) dpsimplify(x,tol),c,'uniformoutput',false);
        ix        = cellfun(@(x,six) x+six-1,ix,num2cell(sIX),'uniformoutput',false);
    else
        ps   = cellfun(@(x) dpsimplify(x,tol),c,'uniformoutput',false);
    end

    % write the data from a cell array back to a matrix
    ps = cellfun(@(x) [x;nan(1,dims)],ps,'uniformoutput',false);    
    ps = cell2mat(ps);
    ps(end,:) = [];

    % ix wanted? write ix to a matrix, too.
    if nargout == 2;
        ix = cell2mat(ix);
    end

else
    % if there are no nans than start the recursive algorithm
    ixe     = size(p,1);
    ixs     = 1;

    % logical vector for the vertices to be retained
    I   = true(ixe,1);

    % call recursive function
    p   = simplifyrec(p,tol,ixs,ixe);
    ps  = p(I,:);

    % if desired return the index of retained vertices
    if nargout == 2;
        ix  = find(I);
    end

end

% _________________________________________________________
function p  = simplifyrec(p,tol,ixs,ixe)
    % check if startpoint and endpoint are the same 
    % better comparison needed which included a tolerance eps
    c1 = num2cell(p(ixs,:));
    c2 = num2cell(p(ixe,:));   

    % same start and endpoint with tolerance
    sameSE = all(cell2mat(cellfun(compare,c1(:),c2(:),'UniformOutput',false)));
    if sameSE; 
        % calculate the shortest distance of all vertices between ixs and
        % ixe to ixs only
        if dims == 2;
            d    = hypot(p(ixs,1)-p(ixs+1:ixe-1,1),p(ixs,2)-p(ixs+1:ixe-1,2));
        else
            d    = sqrt(sum(bsxfun(@minus,p(ixs,:),p(ixs+1:ixe-1,:)).^2,2));
        end
    else    
        % calculate shortest distance of all points to the line from ixs to ixe
        % subtract starting point from other locations
        pt = bsxfun(@minus,p(ixs+1:ixe,:),p(ixs,:));

        % end point
        a = pt(end,:)';

        beta = (a' * pt')./(a'*a);
        b    = pt-bsxfun(@times,beta,a)';
        if dims == 2;
            % if line in 2D use the numerical more robust hypot function
            d    = hypot(b(:,1),b(:,2));
        else
            d    = sqrt(sum(b.^2,2));
        end
    end

    % identify maximum distance and get the linear index of its location
    [dmax,ixc] = max(d);
    ixc  = ixs + ixc; 

    % if the maximum distance is smaller than the tolerance remove vertices
    % between ixs and ixe
    if dmax <= tol;
        if ixs ~= ixe-1;
            I(ixs+1:ixe-1) = false;
        end
    % if not, call simplifyrec for the segments between ixs and ixc (ixc
    % and ixe)
    else   
        p   = simplifyrec(p,tol,ixs,ixc);
        p   = simplifyrec(p,tol,ixc,ixe);

    end

end
end

 