%-------------------------------------------------------------------------
function centroids = m2d_getCentroids(DT,TriIndex)
%
% Centroids of polygonal regions are obtained by geometric decomposition
% since thats a cinch given the existing DT.
% 3rd column returned is area of region.

if exist('delaunayTriangulation','class')
    y = DT.Points(:,1);
    z = DT.Points(:,2);
    yt = y(DT.ConnectivityList);
    zt = z(DT.ConnectivityList);
else
    y = DT.X(:,1);
    z = DT.X(:,2);
    yt = y(DT.Triangulation);
    zt = z(DT.Triangulation);
end

yct = sum(yt,2)/3;
zct = sum(zt,2)/3;
 

tarea = polyarea(yt',zt')';

nRegions = length(unique(TriIndex));
centroids = zeros(nRegions,2);

for i = 1:nRegions
    
    itris = find(TriIndex == i);
    
    sarea = sum(tarea(itris));
    
    ycentroid = sum(yct(itris).*tarea(itris))/ sarea;
    zcentroid = sum(zct(itris).*tarea(itris))/ sarea;
    centroids(i,1:3) = [ ycentroid zcentroid sarea];
    
end
 
end