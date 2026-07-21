function [outputArg1] = Roughness_func(y0,y1,x0,x1,resist_file1,resist_file2,imgI)
%UNTITLED 此处显示有关此函数的摘要
%   此处显示详细说明
% function [IdxTri,iTri]=Roughness(varargin)
err = 1e-4;
% addpath('F:\Matlab code in Trondheim\MARE2DEM\MATLAB\Troll');
% Find out the Vertices on the segments
% Read geometry line
% Get PSLG .poly file name:
% disp('%--Reading geometry data')
% [file path ] = uigetfile('*.resistivity','Select the Resistivity file (.resistivity)');
if  isempty(resist_file1) == 1
    % Turn button back to gray
    return
end

[ ppath, fileroot, e]= fileparts(resist_file1); % remove .resistivity name for later
% [ p, fileroot, e]= fileparts(fileroot); % remove iteration number

% file = fullfile(path,file);

% Read in the resistivity file:
Resistivity = readMARE2DEM_Resistivity(resist_file1);

% Read in the Model Poly file:
pFile = fullfile(ppath,Resistivity.modelFile);
[nodes, segments, eles, regions] = readPoly(pFile);

% Find out the nodes in the block
% x0=-10000;x1=20000;y0=200;y1=4000; % boundry of the block
Idx=find(nodes(:,1)>=x0 & nodes(:,1)<=x1 & nodes(:,2)>=y0 & nodes(:,2)<=y1);
hor_nodes=nodes(Idx,:);

% Find out segments
iseg=ismember(segments(:,1:2),Idx);
iseg=ismember(iseg,[1 1],'rows');
GeoSegs=segments(iseg,1:2);

%%
% Try to find out segments, Segments may be correct
%%
% Read in the triangle mesh nodes
% disp('%--Reading triangle mesh data')
% [file path ] = uigetfile('*.resistivity','Select the Resistivity file (.resistivity)');
if isempty(resist_file2) == 1
    % Turn button back to gray
    return
end

[ ppath1, fileroot, e]= fileparts(resist_file2); % remove .resistivity name for later
% [ p, fileroot, e]= fileparts(fileroot); % remove iteration number
% 
% file = fullfile(path,file);

% Read in the resistivity file:
Resistivity = readMARE2DEM_Resistivity(resist_file2);

% Read in the Model Poly file:
pFile = fullfile(ppath1,Resistivity.modelFile);
[nodes, segments, eles, regions] = readPoly(pFile);

TriIndex=regions(:,3);
centroids = regions(:,1:2);
% Read in the Model Penalty file:
pFile = fullfile(ppath1,Resistivity.penaltyFile);
[pen] = readPenalty(pFile);

% To find out the nearest hor_nodes
% d = ipdm(nodes,hor_nodes,'Subset','nearest','result','struct');
% d = ipdm(hor_nodes,nodes,'Subset','nearest','result','struct');

Idxnodes=find(nodes(:,1)>=x0 & nodes(:,1)<=x1 & nodes(:,2)>=y0 & nodes(:,2)<=y1);
% nNodes=length(Idxnodes);

% Vertices=hor_nodes;
% nodes(:,3)=nodes(:,2);nodes(:,2)=nodes(:,1);
% nodes(:,1)=1:length(nodes);
% Segs(:,3)=Segs(:,2);Segs(:,2)=Segs(:,1);
% Segs(:,1)=1:length(Segs);
%  [dist,path] = dijkstra(nodes,Segs,1,100);
%  P=nodes(Idxnodes(:),:);

%% Find the vertices on the segments
 unSeg=unique(GeoSegs);
 nSeg=length(GeoSegs); % the number of the segments of geometry
 nNodes=length(hor_nodes); % the number of the nodes of geometry
%  nNodes=length(GeoSegs);
 xb=nodes; % nodes of the mesh
 [ionsegx,ionsegy]=find(ipdm(hor_nodes,xb)==0);
%  onSeg=nodes(ionsegy,:); % nodes on the segments of the geometry
 onSeg=nodes(unSeg,:); % nodes on the segments of the geometry

% % Find out segments
% iseg=ismember(segments(:,1:2),ionsegy);
% iseg=ismember(iseg,[1 1],'rows');
% GeoSegs=segments(iseg,1:2);
% 

 slops=[];
 for ii=1:nNodes-2
    xm=hor_nodes(ii,:);% hor_nodes from geometry
%     xm=onSeg(ii,:);% onSeg from mesh
    iSegs=ismember(GeoSegs,Idx(ii));
    iSeg=~ismember(iSegs,[0 0],'rows');
    in=~ismember(GeoSegs(iSeg,:),Idx(ii));% Segment, the other vertice
    iNSeg=GeoSegs(iSeg,:);
    xn=nodes(iNSeg(in),:);
    % compute slopes
    m1 = (xn(:,2) - xm(:,2)) ./ (xn(:,1) - xm(:,1));
    ds = ipdm(xm,xn);
    ds = fix(ds)+1;
    dp = ipdm(xm,xb);
    for i2=1:length(ds)
        I=find(dp<=ds(i2));
%         Ikick = ~ismember(I, GeoSegs(ii,:)); % Kick start and end points 
        Ikick = ~ismember(I, Idx(ii)); % Kick start and end points         
        iNodes=I(Ikick);
        % compute slopes
        m2 = (xb(iNodes,2) - xm(:,2)) ./ (xb(iNodes,1) - xm(:,1));   
        m1(find(abs(m1)>1/err)) = inf;  m2(find(abs(m2)>1/err)) = inf;
        for im=1:length(m1)
            idx = find(abs(m1(im)-m2)<err | (isinf(m1(im))&isinf(m2)));
            iNod=iNodes(idx)';
            onSeg=[onSeg; nodes(iNod,:)];
            unSeg=[unSeg;iNod];
        end
%         clear Ikick;
    end
 end
 GeoSegs(:,3)= (nodes(GeoSegs(:,1),2) - nodes(GeoSegs(:,2),2)) ./ (nodes(GeoSegs(:,1),1) - nodes(GeoSegs(:,2),1));
 
 iVerts=unique(unSeg); % This is the ID of the vertices on the segments

% Get nodes and segs:
Nodes = nodes(:,1:2);
[i j] = find(triu(segments));
Segs = [i j];

if isempty(Segs)
    delete(findobj(handles.hfigure,'tag','rpatch'))
    return; % nothing to color yet
end

% Create Delaunay Triangulation:
% DT = delaunayTriangulation(Nodes,Segs);
DT = DelaunayTri(Nodes,Segs);
if size(DT,1) == 0
    return
end

% Find out the triangles with the vertics
iDT=ismember(DT.Triangulation,iVerts);
id1=find(iDT(:,1)==1);
id2=find(iDT(:,2)==1);
id3=find(iDT(:,3)==1);
id=[id1;id2;id3];
idxDT=unique(id);
 % Get centers of current triangles:
    TriCenters = incenters(DT);
    d = ipdm(TriCenters(idxDT,:),regions(:,1:2),'Subset','nearest','result','struct');
    iTri=unique(d.columnindex);
%     x0=0;x1=25000;y0=0;y1=12000;
%     x0=-10000;x1=20000;y0=200;y1=4000;
    IdxTri=find(regions(:,1)>=x0 & regions(:,1)<=x1 & regions(:,2)>=y0 & regions(:,2)<=y1);
%     plot(regions(IdxTri,1),regionss(IdxTri,2),'*');

%% Read in seismic image
%    disp('%--Reading seismic image')
%    file = 'Trollresis.png';
    [A]=imgI;
%     x0=-10000;x1=20000;y0=0;y1=4000;
%      x0=500;x1=24500;y0=2000;y1=8000;
    
    [D,Sl]=metrictensor(A);
    [rows,cols]=size(D);

    D{end+1,end+1}=[1,0;0,1];
    
 Dxx=zeros(rows,cols);
 Dxy=zeros(rows,cols);
 Dyy=zeros(rows,cols);
for j=1:cols;
    for i=1:rows;
       Dxx(i,j)=D{i,j}(1,1);
       Dxy(i,j)=D{i,j}(1,2);
       Dyy(i,j)=D{i,j}(2,2);
    end
end
    % Creates an imref2d object given an image size and the world coordinate limits
    % in each dimension, specified by xWorldLimits and yWorldLimits.
    % y0=left; y1=right; x0=top; x1=bottom;
    xWorldLimits = [y0 y1];
    yWorldLimits = [x0 x1];
    RA = imref2d(size(A),xWorldLimits,yWorldLimits);

[XID]=find(centroids(:,1)>=x0 & centroids(:,1)<=x1 & centroids(:,2)>=y0 & centroids(:,2)<=y1);
IDTRI=ismember(XID,iTri);
XID=XID(IDTRI);

%% Rewrite penalty 
% Read in coordinates of iPatch and iRegion
for i=1:length(XID)
    % Find each region near geometry region, and find out their neighbers
    I=find(pen.colind==XID(i));
    ind= I(rem(I,2)==0);
    iRegion=XID(i);
    iPatch=pen.colind(ind-1);
    w=pen.val(ind-1);

    yR=centroids(iRegion,1);
    zR=centroids(iRegion,2);
    yt=centroids(iPatch,1);
    zt=centroids(iPatch,2);
    yt_in = yt>=x0 & yt<=x1;%  find the nodes out of the image
    zt_in = zt>=y0 & zt<=y1;
    if yt_in == zt_in    
        common_in = yt_in;
    else
        common_in = (yt_in == zt_in) == 1;
    end
    yt = yt(common_in);
    zt = zt(common_in);
    iPatch = iPatch(common_in);   % delete the elements out of the image
    w = w(common_in);
    dy=yt-yR;
    dz=zt-zR;
    
    jiregion=(yR-x0)./(x1-x0)*cols; iiregion=(zR-y0)./(y1-y0)*rows; 
    iiregion=fix(iiregion)+1; jiregion=fix(jiregion)+1;
    iiregion(iiregion <= 0) = 1; 
    iiregion(iiregion >= rows) = rows;
    jiregion(jiregion <= 0) = 1;
    jiregion(jiregion >= cols) = cols;
    
    jiPatch=(yt-x0)./(x1-x0)*cols; iiPatch=(zt-y0)./(y1-y0)*rows; 
    iiPatch=fix(iiPatch)+1;  jiPatch=fix(jiPatch)+1;
    iiPatch(iiPatch <= 0) = 1; 
    iiPatch(iiPatch >= rows) = rows;
    jiPatch(jiPatch <= 0) = 1;
    jiPatch(jiPatch >= cols) = cols;
    
    ii=ismember(iPatch,XID);
    dt = zeros(1,length(ii));
    for j=1:length(ii)
      d11(j)=Dxx(iiPatch(j),jiPatch(j));
      d12(j)=Dxy(iiPatch(j),jiPatch(j));
      d22(j)=Dyy(iiPatch(j),jiPatch(j));

      k1(j)=abs(iiPatch(j)-iiregion); 
      k2(j)=abs(jiPatch(j)-jiregion);
      dt(j) = computeTime(d11(j),d12(j),d22(j),k1(j),k2(j));
    end
    wt=w./dt'; % Give a travel time value for the boundary
    wt(~ii)=w(~ii); % Keep the old value for the flat area
%     wt=wt./sum(wt); % Normalized

    pen.val(ind(common_in)-1)=wt;
    pen.val(ind(common_in))=-wt;

    clear wt w ii k1 k2 dt;

end



fprintf('%-32s %s\n','Writing Penalty file:',pFile)

fid = fopen(pFile,'w');
fprintf(fid,'Format: CSR_penalty_1.0\n');
fprintf(fid,'%i %i\n', pen.nnz,pen.nrows);
fprintf(fid,'%i %g\n',[pen.colind pen.val]');
fprintf(fid,'%i\n',pen.rowptr);

fclose(fid);
outputArg1 = pFile;
end

