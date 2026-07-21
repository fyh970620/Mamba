function diffMARE2DEM_Resistivity( sFile1, sFile2, sFileOut, fDiffFctn )
% diffMARE2DEM_Resistivity( sFile1, sFile2, sFileOut, fDiffFctn )
%
%   Difference two resistivity files with identical region layout and write the
% output to a third file.
%   Optionally specify your own differencing function (which must handle 2D
% matricies of values).
%   The default is @(A,B) (log10(A) - log10(B))
%   NOTE that whatever measure you use, it MUST NOT EVER RETURN <= ZERO because
% the plotting codes will try to take the log of it.
%
% David Myer
% August 2013
%
%-------------------------------------------------------------------------------
% See also readMARE2DEM_Resistivity, writeMARE2DEM_Resistivity

% Handle optional params
if nargin() < 4
%     fDiffFctn = @(A,B)max(0.1, abs( (A-B) ./ A * 100 ) );
    fDiffFctn = @(A,B) (log10(A) - log10(B));
end

% Read
stRes1 = m2d_readResistivity( sFile1 );
stRes2 = m2d_readResistivity( sFile2 );

% Diff
assert( all(size(stRes1.resistivity) == size(stRes2.resistivity)) ...
    , 'The two MARE2DEM resistivity files have different region lists. Cannot diff.' );
stRes1.resistivity = fDiffFctn( stRes1.resistivity, stRes2.resistivity );

stRes1.resistivityFile  = sFileOut;
% Write
m2d_writeResistivity( stRes1,0 );

return
end % diffMARE2DEM_Resistivity