function [Nodes,Segs,varargout] = m2d_triangulateRegion(DT,TriIndex,Nodes,Segs,target,area,tricode,triopts,bTalk, bAsk)
%
% Triangulates a target region, assuming that it resides in a segment
% bound region
%
% Inputs:
%
% Nodes(x,y)
% Segs(inode1,inode2)
% target(x,y)
% area constraint
% tricode - path to Triangle.c executable
% triopts
%
% Kerry Key
% Scripps Institution of Oceanography
%
 

holes       = [];  
attributes  = [target -1 area ];  % using -1 as flag for new elements in this region
sFile       = 'tempMamba2D.poly';
 
% Get triangle containing target:
inTri = pointLocation(DT,target(1),target(2));

% Get region index of target point:
triRegion = TriIndex(inTri);
 
 
lseg = false(size(Segs,1),1);
% Update segMarker. Get edge attachments first:
ti = edgeAttachments(DT,Segs(:,1),Segs(:,2));
for i = 1:length(ti)
    if length(ti{i}) == 2
        reg1 = TriIndex(ti{i}(1));
        reg2 = TriIndex(ti{i}(2));
    else
        reg1 = TriIndex(ti{i}(1));
        reg2 = 0;
    end
    if reg1 == triRegion || reg2 == triRegion  
        lseg(i) = true;
    end

end

 
% For all regions not triRegion, make holes:

[ireg,itri] = unique(TriIndex);
itri = itri(ireg~=triRegion);

    if exist('delaunayTriangulation','class')
        holes = incenter(DT,itri);
    else
        holes = incenters(DT,itri);
    end
 

% Save these segments and nodes to a file:
regionSegs = Segs(lseg,:);
regionNodes = Nodes;  % saving ALL nodes, but only region segments
regionNodes(:,3) = 1;
m2d_writePoly(sFile,regionNodes,regionSegs ,holes,attributes);
 

nOldNodes = size(Nodes,1);

% Call Triangle.c:
 
% triopts = sprintf('-q%ipaACjn',(qangle));
% triopts = sprintf('-q%ipaAC',qangle);
% tricode = Mamba2D_TrianglePath();
string = sprintf('!"%s" %s %s',tricode,triopts,sFile);

if bTalk
    echo on;   
    disp('Matlab now requesting execution of Triangle C-code ....')
    disp(string)
end
eval(string)
if bTalk
    echo off;
    disp('Back from Triangle C-code...')
end

% Read in the new .poly, .node and .ele files:
[p, n, ~] = fileparts(sFile);
sPolyFileNew = fullfile(p,sprintf('%s.1.poly',n));
[NewNodes,NewSegs, eles, ~, ~] = m2d_readPoly(sPolyFileNew);

delete(sFile);
[~,n] = fileparts(sFile);

delete(sprintf('%s.1.poly',n));
delete(sprintf('%s.1.node',n));
delete(sprintf('%s.1.ele',n));
 
if bAsk
    str = sprintf('Region has been triangulated with %i triangles, are you sure you want to proceed?',size(eles,1));
    
    choice = questdlg(str,'Triangulate Region:','Yes', 'No','No');
    
    switch choice
    case 'Yes'
        % do nothing
    case 'No'
        Nodes = [];
        Segs  = [];
        if nargout > 2
            varargout{1} = [];
        end
        return;
    end
    
end

RevisedSegs = [Segs(~lseg,:);NewSegs];

% plot check:
% 
% figure;
% plot(N(:,1),NewNodes(:,2),'b.')
% hold on;
% axis ij;
% 
% i = RevisedSegs(:,1);
% j = RevisedSegs(:,2);
% sy1 = NewNodes(i,1);
% sz1 = NewNodes(i,2);
% 
% sy2 = NewNodes(j,1);
% sz2 = NewNodes(j,2);
% plot([sy1 sy2 nan*sy2]',[sz1 sz2 nan*sy2]','c-') 
 

% Now add extra edges from the new triangular elements:
% Form adjacency matrix:
%All segments get 2 for boundary marker:

i1 = eles(:,4) == -1;
v1 = eles(i1,1); 
v2 = eles(i1,2); 
v3 = eles(i1,3); 

n1 = [v1;v2;v3; ];
n2 = [v2;v3;v1; ];
nn = sort([n1 n2],2);
eleSegs =  [nn ones(size(n2,1),1)];
 
RevisedSegs(:,1:2) = sort(RevisedSegs(:,1:2),2);

A = [RevisedSegs; eleSegs];
[Segs, ii] = unique(A(:,1:2),'rows');
Segs(:,3) = A(ii,3);

Nodes   = NewNodes;

% 
% Mesh smoothing: unfortunately this sometimes causes some slivers, so turning this
% off for now. Stay tuned for updated MARE2DEM that is less sensitive to
% slivers...
 
    % Now apply a little mesh smoothing so the grid node spacing becomes smoother than the default
    % grids from Triangle:
%     fixedNodes = find(Nodes(:,3));
%     method     = 'ODT';
%     rho        = [];
%     step       = 3;
% 
%     NewNodes   = meshSmoothingFromIFEM(Nodes(:,1:2),eles(:,1:3),step,rho,method,fixedNodes);
%    % [eles(:,1:3),flag] = edgeswapFromIFEM(NewNodes,eles(:,1:3));
%     Nodes = [NewNodes]; % Nodes(:,3)];
%  
if nargout > 2
    varargout{1} = eles;
end

end

