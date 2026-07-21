function [TriIndex, regionIndex] = m2d_getTriangleRegions(DT,segs,regions)
%
% Find the segment bound regions each triangle in DT resides in. 
%
% Returns:
%
% TriIndex:  new region index for each triangle in DT
%
% regionIndex:  dim(# new regions) index to input regions array. To
%               be used for propagting regions from old to new DT during
%               model refinement. Deleted regions in new DT are not
%               present in regionIndex. 
%               regionIndex is zero where DT has new regions not contained 
%               in input regions array.
%
 

n = size(DT.Points,1);

% Create adjacency matrix of input region boundary segments:
v1 = segs(:,1);
v2 = segs(:,2);
Adjacency = sparse([v1; v2],[v2; v1],ones(2*length(v1),1),n,n);

% Create [ntri 3] array of triangle edges flags, 1 if edge is a
% boundary segment:
v1 = DT(:,1);
v2 = DT(:,2);
v3 = DT(:,3);

e1 = full(Adjacency(sub2ind([n n],v2,v3))); % the three edges of the triangle
e2 = full(Adjacency(sub2ind([n n],v3,v1)));
e3 = full(Adjacency(sub2ind([n n],v1,v2)));
E = [e1 e2 e3];

% Get neighbors for all triangles:
N = neighbors(DT,(1:size(DT,1))');
N(~isfinite(N)) = 0;
N = N.*~E; % 0 the neighbors if crosses the region boundary segments


nTris    = size(DT,1);
TriIndex = zeros(nTris,1);
 
regionIndex = zeros(nTris,1);
 
%
% First pass maps input regions to triangles in DT
%
nRegions = 0;

if ~isempty(regions)
    
    iTri = pointLocation(DT, regions);

    for ireg = 1:size(regions,1)

        e = iTri(ireg);

        if TriIndex(e) ~= 0
            continue
        end

        nRegions  = nRegions + 1;

        regionIndex(nRegions) = ireg;  % points from new to old regions

        numNeighs = 1;
        neighs    = e;

        while numNeighs > 0  

             TriIndex(neighs) = nRegions;
             n                = N(neighs,1:3);
             N(neighs,:)      = 0;
             neighs           = n(n>0);        
             numNeighs       = length(neighs);
        end

    end
    
end

%
% Now find the remaining undiscovered regions:
%

iSrch = find(TriIndex==0);
for e = 1:length(iSrch)
    
    if TriIndex(iSrch(e)) ~= 0
        continue
    end
    
    nRegions  = nRegions + 1;
    
    
    numNeighs = 1;
    neighs    = iSrch(e);
    
    while numNeighs > 0 %any(neighs)
        
         TriIndex(neighs) = nRegions;
         n                = N(neighs,1:3);
         N(neighs,:)      = 0;
         neighs           = n(n>0);        
         numNeighs       = length(neighs);
    end
    
end
n = length(regionIndex); 
regionIndex(n+1:nRegions) = 0;

regionIndex = regionIndex(1:nRegions);

end % setDTregions