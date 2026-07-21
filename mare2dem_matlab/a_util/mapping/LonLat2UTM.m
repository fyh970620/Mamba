function [nE,nN,nZone,bSHemi] = LonLat2UTM( nLon, nLat, nForceZone, sEllipsoid, nFalseE, nFalseN )
%
% function [nE,nN,nZone,bSHemi] = LonLat2UTM( nLon, nLat, nForceZone, sEllipsoid, nFalseE, nFalseN )
%
% Convert Lon,Lat to E,N,Zone,Hemi (UTM) using WGS84. Geographic not geomagnetic
% This function encapsulates the entire transformation without having to call
% the m_map library. It is easier to distribute. The guts come from m_map with
% attribution below.
%
% David Myer, Sept 2013
%-------------------------------------------------------------------------------
% See also UTM2LonLat
    
    % 6/26/2015 - Zones around Norway are special and have different false
    % eastings & northings. I occasionally encounter these done the correct way.
    if ~exist( 'nFalseE', 'var' )
        nFalseE = [];
    end
    if ~exist( 'nFalseN', 'var' )
        nFalseN = [];
    end

    % DGM 2/27/2015 - Support multiple ellipsoids
    % If ellipsoid is not given, default to WGS84
    if ~exist( 'sEllipsoid', 'var' ) || isempty( sEllipsoid )
        sEllipsoid = 'wgs84';
    end
    switch( lower( sEllipsoid ) )
    case 'wgs84' , nEllipsoid = [6378137.0, 1/298.257];
    case {'intl24', 'ed50'} % EuropeanDatum 1950 uses Intl 1924 ellipsoid params
                   nEllipsoid = [6378388.0, 1/297.000];
    case 'normal', nEllipsoid = [1.0, 0];
    case 'sphere', nEllipsoid = [6370997.0, 0];
    case 'grs80' , nEllipsoid = [6378137.0, 1/298.257];
    case 'grs67' , nEllipsoid = [6378160.0, 1/247.247];
    case 'wgs72' , nEllipsoid = [6378135.0, 1/298.260];
    case 'wgs66' , nEllipsoid = [6378145.0, 1/298.250];
    case 'wgs60' , nEllipsoid = [6378165.0, 1/298.300];
    case 'clrk66', nEllipsoid = [6378206.4, 1/294.980];
    case 'clrk80', nEllipsoid = [6378249.1, 1/293.466];
    case 'intl67', nEllipsoid = [6378157.5, 1/298.250];
    otherwise
        error( 'LonLat2UTM: Unknown / unsupported ellipsoid: "%s"', sEllipsoid );
    end
    
    % Compute or force the UTM zone
    if exist( 'nForceZone', 'var' ) && ~isempty( nForceZone )
        nZone = nForceZone;
    else
        nZone   = 1 + fix( (mod(median(nLon)+180,360)) / 6 );
    end
    bSHemi  = median(nLat) < 0;
    
    % DGM 8/2014: the computations only work if -180 <= nLon <= 180. So force
    % that to be true.
    nLon = mod( nLon, 360 );
    iChg = nLon > 180;
    nLon(iChg) = nLon(iChg) - 360;
    
    % Run the computations copied from m_map
    [nE,nN] = mu_ll2utm( nLat, nLon, nZone, bSHemi, nEllipsoid, nFalseE, nFalseN );
    
    return;
end % LonLat2UTM


%-------------------------------------------------------------------------------
%-------------------------------------------------------------------------------
%-------------------------------------------------------------------------------
% BELOW EXCERPTED FROM m_map's mp_utm.m function. Original header follows:
% 6/26/2015 DGM modified to support the weird zones around Norway
%-------------------------------------------------------------------------------
%-------------------------------------------------------------------------------
%-------------------------------------------------------------------------------
% MP_UTM   Universal Transverse Mercator projection
%           This function should not be used directly; instead it is
%           is accessed by various high-level functions named M_*.
%
% mp_utm.m, Peter Lemmond (peter@whoi.edu)
%
% created mp_utm.m 13Aug98 from mp_tmerc.m, v1.2d distribution, by:
%
% Rich Pawlowicz (rich@ocgy.ubc.ca) 2/Apr/1997
%
% This software is provided "as is" without warranty of any kind. But
% it's mine, so you can't sell it.
%
% Mathematical formulas for the projections and their inverses are taken from
%
%      Snyder, John P., Map Projections used by the US Geological Survey, 
%      Geol. Surv. Bull. 1532, 2nd Edition, USGPO, Washington D.C., 1983.
%
%
% 10/Dec/98 - PL added various ellipsoids.
function [x,y] = mu_ll2utm( lat,lon, zone, hemisphere, ellipsoid, FALSE_EAST, FALSE_NORTH )
%mu_ll2utm		Convert geodetic lat,lon to X/Y UTM coordinates
%
%	[x,y] = mu_ll2utm (lat, lon, zone, hemisphere,ellipsoid)
%
%	input is latitude and longitude vectors, zone number, 
%		hemisphere(N=0,S=1), ellipsoid info [eq-rad, flat]
%	output is X/Y vectors
%
%	see also	mu_utm2ll, utmzone


% some general constants

DEG2RADS    = pi/180;
RADIUS      = ellipsoid(1);
FLAT        = ellipsoid(2);
K_NOT       = 0.9996;
if ~exist( 'FALSE_EAST', 'var' ) || isempty( FALSE_EAST )
    FALSE_EAST  = 500000;
end
if ~exist( 'FALSE_NORTH', 'var' ) || isempty( FALSE_NORTH )
    FALSE_NORTH = 10000000;
end

% check for valid numbers

if (max(abs(lat)) > 90)
  error('latitude values exceed 89 degree');
end

if ((zone < 1) || (zone > 60))
  error ('utm zones only valid from 1 to 60');
end

% compute some geodetic parameters

lambda_not  = ((-180 + zone*6) - 3) * DEG2RADS;

e2  = 2*FLAT - FLAT*FLAT;
e4  = e2 * e2;
e6  = e4 * e2;
ep2 = e2/(1-e2);

% some other constants, vectors

lat = lat * DEG2RADS;
lon = lon * DEG2RADS;

sinL = sin(lat);
tanL = tan(lat);
cosL = cos(lat);

T = tanL.*tanL;
C = ep2 * (cosL.*cosL);
A = (lon - lambda_not).*cosL;
A2 = A.*A;
A4 = A2.*A2;
S = sinL.*sinL;

% solve for N

N = RADIUS ./ (sqrt (1-e2*S));

% solve for M

M0 = 1 - e2*0.25 - e4*0.046875 - e6*0.01953125;
M1 = e2*0.375 + e4*0.09375 + e6*0.043945313;
M2 = e4*0.05859375 + e6*0.043945313;
M3 = e6*0.011393229;
M = RADIUS.*(M0.*lat - M1.*sin(2*lat) + M2.*sin(4*lat) - M3.*sin(6*lat));

% solve for x

X0 = A4.*A/120;
X1 = 5 - 18*T + T.*T + 72*C - 58*ep2;
X2 = A2.*A/6;
X3 = 1 - T + C;
x = N.*(A + X3.*X2 + X1.* X0);

% solve for y

Y0 = 61 - 58*T + T.*T + 600*C - 330*ep2;
Y1 = 5 - T + 9*C + 4*C.*C;

y = M + N.*tanL.*(A2/2 + Y1.*A4/24 + Y0.*A4.*A2/720);


% finally, do the scaling and false thing. if using a unit-normal radius,
% we don't bother.

x = x*K_NOT + (RADIUS>1) * FALSE_EAST;

y = y*K_NOT;
if (hemisphere)
  y = y + (RADIUS>1) * FALSE_NORTH;
end

return
end