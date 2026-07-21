function [z,slopeAngle,lOnNode] = m2d_parseTopo(topo,y)  
%
% Interpolates input topography at position y to give depth z and slope
% angle (degrees), as well as a logical flag lOnNode noting y positions
% that are directly over nodes (so slope may not be not well defined
% there). 
%
% Note: MARE2DEM uses a right handed coordinate system with z
% pointing down and strike direction x, so receivers are along the y
% direction (positive to the right).
%
% Inputs:
%           topo - a single depth value for flat topography or array [y,z]
%           y    - position(s) to interpolate topo to get depth and slope.
%
% Outputs:
%           z          - depth of topography at position(s) in y
%           slopeAngle - angle (degrees) positive clockwise from +y towards +z.
%           lOnNode    - true where y positions are directly over a node in
%                        the topo array. Here the slope may not be well
%                        defined. 
%            
% Kerry Key
% Lamont-Doherty Earth Observatory, Columbia University
%
% To do: in addition to lOnNode, could output left/right side slopes so
% that calling routine can decide what to use when y is on a topo node
% where slope to left and right sides may be different.
%
%
%
    % Sort topo so position is increasing:
    if size(topo,1) > 1 
       [~,isort] = unique(topo(:,1));  % use unique to remove any 
                                       % duplicate y values (i.e. vertical
                                       % jumps in topo. If Rx placed on
                                       % vertical jump location, well
                                       % that's on you buddy and you get
                                       % the luck of the draw with the
                                       % unique function's output
       topo = topo(isort,:);
    end
    
  
    
    % interpolate topo:
    if size(topo,1) == 1  && size(topo,2) == 1  % single entry, make it a line with some padding
        z           = y*0 + topo;
        slopeAngle  = zeros(size(y));
        lOnNode     = false(size(z));
        
    else
        
        % pad topo horizontally so it extends past all y values:
        yt = [y(:);  topo(:,1)];
        miny = min(yt);
        maxy = max(yt);
        dy = maxy-miny;
        if dy == 0
            dy = 1d6;
        end
        yt   = [miny-2*dy; miny-dy; topo(:,1); maxy+dy;maxy+2*dy]; % two extra values each side for angle calc
        zt   = interp1(topo(:,1),topo(:,2),yt,'nearest','extrap'); % nearest neighbor extrapolate padding. i.e. make topo flat on padding
        topo = [yt(:) zt(:)];
       
        % interp topo to get z:
        z = interp1(topo(:,1),topo(:,2),y,'linear'); % use LINEAR interpolation *only* since topo is piecwise linear. 
        
        % Compute slope angle:
        %
        dy  = diff(topo(:,1));
        dz  = diff(topo(:,2));
        ang = 180/pi*atan2(dz,dy);
        pos = topo(1:end-1,1);  
            
        % Get slope at y. 
        % Note piecewise continuous linear topography results in a piecewise constant
        % slope, so 'previous' is the correct way to interpolate the slope at
        % y positons.
        slopeAngle = interp1(pos,ang,y,'previous');

        lOnNode = ismember(y,topo(:,1));    
        
        
 
end
