function [stTopo, lOkay] = m2d_importTopo(stTopo,stUTM)
%
% Imports topography profile created by GeoMapApp. Checks to make
% topography transect in same direction as MARE2DEM survey profile.
%
% These files have long, lat, elevation (m) and distance (km)
% and so we need to convert distance into the same UTM0 point used
% here for the MT stations.

    lOkay = true;
    
    % Load profile:
    stTopo.topo = load(stTopo.sTopoFile);
    
    % Get depth data:
    if isfield(stTopo,'colDepthMeters')
        
        stTopo.zTopo = stTopo.topo(:,stTopo.colDepthMeters);
        
    elseif isfield(stTopo,'colElevationMeters')
        
        stTopo.zTopo = -stTopo.topo(:,stTopo.colElevationMeters);
    
    else
        
        str1 = sprintf('Error in importing topogrpahy, no depth or elevation column specified!');
        str = sprintf(' %s\n  Stopping, try again bucko!',str1);
        h = errordlg(str,'Error','modal');
        waitfor(h);
        lOkay = false;
        return                 
    
    end
    
    stTopo.bSHemi = false;
    if strcmpi(stUTM.hemi,'s')
        stTopo.bSHemi = true;
    end
    
    % Get distance along profile or project latitude and longitude onto survey
    % profile:
    if isfield(stTopo,'colLongitude') && isfield(stTopo,'colLatitude') % project onto survey profile:
        
         % Convert topo lon/lat to UTM:
        [stTopo.nTopoE,stTopo.nTopoN,stTopo.nZone,stTopo.bSHemi] = LonLat2UTM( stTopo.topo(:,stTopo.colLongitude), stTopo.topo(:,stTopo.colLatitude), stUTM.grid );
    
        % Get topography profile orientation by fitting line to points:
        nTopoOrientation = m2d_getLineOrientation(stTopo.nTopoN,stTopo.nTopoE);
        
        
        % Check that topo orientation is close to the survey line orientation:
        % first make sure both angles are between 0 and 180:
        if nTopoOrientation < 0
            nTopoOrientation = nTopoOrientation + 180;
        elseif nTopoOrientation > 180
            nTopoOrientation = nTopoOrientation - 180;
        end
        nLineOrientation = stUTM.theta+90;
        if nLineOrientation < 0
            nLineOrientation = nLineOrientation + 180;
        elseif nLineOrientation > 180
            nLineOrientation = nLineOrientation - 180;
        end    

        if abs(nTopoOrientation - nLineOrientation) > 5
            str1 = sprintf('Error, topography and survey lines orientations are not parallel!');
            str2 = sprintf('Survey line orientation: %.1f degrees ',nLineOrientation);
            str3 = sprintf('Topography profile orientation: %.1f degrees ',nTopoOrientation);
            str = sprintf(' %s\n %s\n %s\n Stopping, try again bucko!',str1,str2,str3);
            h = errordlg(str,'Error','modal');
            waitfor(h);
            lOkay = false;
            return
        end

        % Now project topography onto survey profile:
        dN = stTopo.nTopoN - stUTM.north0;
        dE = stTopo.nTopoE - stUTM.east0;

        cc = cosd(stUTM.theta);
        ss = sind(stUTM.theta); 

        x  =  cc*dN + ss*dE;
        y  = -ss*dN + cc*dE;    
        
        stTopo.xTopo = x;
        stTopo.yTopo = y; %  
        
    elseif isfield(stTopo,'colDistanceKm')
        
        stTopo.yTopo = stTopo.topo(:,stTopo.colDistanceKm)*1000;
        
     elseif isfield(stTopo,'colDistanceMeters')
        
        stTopo.yTopo = stTopo.topo(:,stTopo.colDistanceMeters);    
        
    end    
    
  
    % Make output topo array be position and depth:
%     topo = [yTopo zTopo];
    
 

end