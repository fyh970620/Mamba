function nLineOrientation =  m2d_getLineOrientation(nNorthings,nEastings)
%
% Fits a line to input northing and eastings points and returns its
% geographic orienation. Line orientation is between 0 to 180 degrees
% clockwise from north (i.e.,  0 = N, 90 = E, 180 = S);  0 to 180 is used
% so that a profile going roughly E-W plots from W (left) to E (right)
% rather than reversed. 
%

%
% Fit line to points:
%
dN = max(nNorthings) - min(nNorthings);
dE = max(nEastings)  - min(nEastings);

% use coordinate with most variation for independent variable in linear fit:
if dE > dN  % more E-W than N-S
   
    coeffs = polyfit(nEastings, nNorthings, 1);
    nLineOrientation = atan(coeffs(1))*180/pi;
    nLineOrientation = 90 - nLineOrientation;
    % Note:  0<= nLineOrientation <= 180
    
else % more N-S than E-W
    
    coeffs = polyfit(nNorthings, nEastings, 1);
    nLineOrientation = atan(coeffs(1))*180/pi;
    % Note:  -90<= nLineOrientation <= 90
    % so shift it:
    if nLineOrientation < 0 
        nLineOrientation = nLineOrientation+180;
    end
    
end

    
end