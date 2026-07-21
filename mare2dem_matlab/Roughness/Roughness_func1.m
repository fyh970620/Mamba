% 海洋电磁快速反演系统
% 基于Matlab GUI开发的关于海洋可控源电磁勘探技术（CSEM）的综合处理软件。
%
% 作者：郭振威
% 中南大学地球科学与信息物理学院
%
%
%
% 用于计算粗糙度
function [outputArg1] = Roughness_func(y0,y1,x0,x1,resist_file1,resist_file2,imgI)
err = 1e-4;
%找出分段上的顶点
% 读取几何线
% 获取PSLG .poly文件名：
% disp（'％-读取几何数据'）
if  isempty(resist_file1) == 1
  %将按钮变回灰色
    return
end

[ ppath, fileroot, e]= fileparts(resist_file1); % 删除.resistivity名称以供以后使用


% 读入电阻率文件：
Resistivity = readMARE2DEM_Resistivity(resist_file1);

% 读取模型多边形文件：
pFile = fullfile(ppath,Resistivity.modelFile);
[nodes, segments, eles, regions] = readPoly(pFile);

%找出块中的节点
Idx=find(nodes(:,1)>=x0 & nodes(:,1)<=x1 & nodes(:,2)>=y0 & nodes(:,2)<=y1);
hor_nodes=nodes(Idx,:);

% 找出细分
iseg=ismember(segments(:,1:2),Idx);
iseg=ismember(iseg,[1 1],'rows');
GeoSegs=segments(iseg,1:2);

%%
% 尝试找出细分，细分可能是正确的
%%
% 读入三角形网格节点
% disp（'％-读取三角形网格数据'）

if isempty(resist_file2) == 1
    % 将按钮变回灰色
    return
end

[ ppath1, fileroot, e]= fileparts(resist_file2); % 删除.resistivity名称以供以后使用


% 读入Resistivity文件：
Resistivity = readMARE2DEM_Resistivity(resist_file2);

%读取模型Poly文件：
pFile = fullfile(ppath1,Resistivity.modelFile);
[nodes, segments, eles, regions] = readPoly(pFile);

TriIndex=regions(:,3);
centroids = regions(:,1:2);
%读取模型Penalty文件：
pFile = fullfile(ppath1,Resistivity.penaltyFile);
[pen] = readPenalty(pFile);


Idxnodes=find(nodes(:,1)>=x0 & nodes(:,1)<=x1 & nodes(:,2)>=y0 & nodes(:,2)<=y1);



%% 在线段上找到顶点
 unSeg=unique(GeoSegs);
 nSeg=length(GeoSegs); % 几何部分的数量
 nNodes=length(hor_nodes); % 几何结点数
 xb=nodes; %网格的节点
 [ionsegx,ionsegy]=find(ipdm(hor_nodes,xb)==0);
 onSeg=nodes(unSeg,:); % 几何部分上的节点
 

 slops=[];
 for ii=1:nNodes-2
    xm=hor_nodes(ii,:);

    iSegs=ismember(GeoSegs,Idx(ii));
    iSeg=~ismember(iSegs,[0 0],'rows');
    in=~ismember(GeoSegs(iSeg,:),Idx(ii));% 段，另一个顶点
    iNSeg=GeoSegs(iSeg,:);
    xn=nodes(iNSeg(in),:);
    % 计算斜率
    m1 = (xn(:,2) - xm(:,2)) ./ (xn(:,1) - xm(:,1));
    ds = ipdm(xm,xn);
    ds = fix(ds)+1;
    dp = ipdm(xm,xb);
    for i2=1:length(ds)
        I=find(dp<=ds(i2));
         
        Ikick = ~ismember(I, Idx(ii));    
        iNodes=I(Ikick);
        % 计算斜率
        m2 = (xb(iNodes,2) - xm(:,2)) ./ (xb(iNodes,1) - xm(:,1));   
        m1(find(abs(m1)>1/err)) = inf;  m2(find(abs(m2)>1/err)) = inf;
        for im=1:length(m1)
            idx = find(abs(m1(im)-m2)<err | (isinf(m1(im))&isinf(m2)));
            iNod=iNodes(idx)';
            onSeg=[onSeg; nodes(iNod,:)];
            unSeg=[unSeg;iNod];
        end
    end
 end
 GeoSegs(:,3)= (nodes(GeoSegs(:,1),2) - nodes(GeoSegs(:,2),2)) ./ (nodes(GeoSegs(:,1),1) - nodes(GeoSegs(:,2),1));
 
 iVerts=unique(unSeg); %这是线段上顶点的ID

% 获取节点和段：
Nodes = nodes(:,1:2);
[i j] = find(triu(segments));
Segs = [i j];

if isempty(Segs)
    delete(findobj(handles.hfigure,'tag','rpatch'))
    return; 
end

% 创建Delaunay三角剖分：
DT = DelaunayTri(Nodes,Segs);
if size(DT,1) == 0
    return
end

%用顶点找出三角形
iDT=ismember(DT.Triangulation,iVerts);
id1=find(iDT(:,1)==1);
id2=find(iDT(:,2)==1);
id3=find(iDT(:,3)==1);
id=[id1;id2;id3];
idxDT=unique(id);
 %获取当前三角形的中心：
    TriCenters = incenters(DT);
    d = ipdm(TriCenters(idxDT,:),regions(:,1:2),'Subset','nearest','result','struct');
    iTri=unique(d.columnindex);

    IdxTri=find(regions(:,1)>=x0 & regions(:,1)<=x1 & regions(:,2)>=y0 & regions(:,2)<=y1);


%% 读入地震图像

    [A]=imgI;

    
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
    %给定图像大小和WorldLimits创建一个imref2d对象
    % 在每个维度中，由xWorldLimits和yWorldLimits指定。
    xWorldLimits = [y0 y1];
    yWorldLimits = [x0 x1];
    RA = imref2d(size(A),xWorldLimits,yWorldLimits);

[XID]=find(centroids(:,1)>=x0 & centroids(:,1)<=x1 & centroids(:,2)>=y0 & centroids(:,2)<=y1);
IDTRI=ismember(XID,iTri);
XID=XID(IDTRI);

%%改写penalty 
% 读取iPatch和iRegion的坐标
for i=1:length(XID)
    % 找到几何区域附近的每个区域，并找出它们的邻居
    I=find(pen.colind==XID(i));
    ind= I(rem(I,2)==0);
    iRegion=XID(i);
    iPatch=pen.colind(ind-1);
    w=pen.val(ind-1);

    yR=centroids(iRegion,1);
    zR=centroids(iRegion,2);
    yt=centroids(iPatch,1);
    zt=centroids(iPatch,2);
    yt_in = yt>=x0 & yt<=x1;%  从图像中找到节点
    zt_in = zt>=y0 & zt<=y1;
    if yt_in == zt_in    
        common_in = yt_in;
    else
        common_in = (yt_in == zt_in) == 1;
    end
    yt = yt(common_in);
    zt = zt(common_in);
    iPatch = iPatch(common_in);   % 从图像中删除元素
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
    wt=w./dt'; % 给出边界的旅行时间值
    wt(~ii)=w(~ii); % 保留平面面积的旧值


    common_in1 = wt ~= 0;
    pen.val(ind(common_in1)-1)=wt(common_in1);
    pen.val(ind(common_in1))=-wt(common_in1);

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

