% 海洋电磁快速反演系统
% 基于Matlab GUI开发的关于海洋可控源电磁勘探技术（CSEM）的综合处理软件。
%
% 作者：郭振威
% 中南大学地球科学与信息物理学院
%
%
%
% 用于读取Poly文件
function [nodes,segments, eles, regions] = readPoly(file)

eles = [];

%打开PSLG文件
fid = fopen(file,'r');
%读入节点：
temp    = fscanf(fid,'%i %i %i %i\n',4);
nnodes   = temp(1);

%如果nnodes == 0，则节点位于单独的文件中，并进行三角剖分
% 已经被计算了。因此，让我们找到.node文件，将其读入
% 并仅保留边界节点：
if nnodes ==0
    [p n e] =fileparts(file);
    filen = fullfile(p,n);
    fid2 = fopen(strcat(filen,'.node'),'r');
    if fid2 < 0;
        disp('error, no nodes defined')
        return
    end
    temp    = fscanf(fid2,'%i %i %i %i\n',4);
    nvert   = temp(1);
    natr    = temp(3);
    nbndmrk = temp(4);
    NODE = fscanf(fid2,'%g',[ 3+natr+nbndmrk,nvert]);
    nodes = NODE';
    fclose(fid2);
    nnodes = nvert;
    nodes = nodes(:,2:end);
    
    % 读取.ele文件：
    fid2    = fopen(strcat(filen,'.ele'),'r');
    temp    = fscanf(fid2,'%i %i %i\n',3);
    ntri    = temp(1);
    ndptri  = temp(2);
    natr = temp(3);
    TRI= fscanf(fid2,'%g',[1+ndptri+natr,ntri]);
    fclose(fid2);
    eles = TRI(2:5,:)';
else
    % 这是一个普通的基本.poly文件
    
    natr    = temp(3);
    nbndmrk = temp(4);
    rstr = [];
    for i = 1:3+natr+nbndmrk
        rstr = sprintf('%s %%g',rstr);
    end
    rstr = strcat(rstr,'\n');
    nodes = fscanf(fid,rstr,[ 3+natr+nbndmrk,nnodes]);
    nodes = nodes(2:3,:)';
    
end

% 细分：
temp = fscanf(fid,'%g %g\n',2);
nsegs = temp(1);
if length(temp)==2
    natr = temp(2);
else
    natr = 0;
end
rstr = [];
for i = 1:3+natr
    rstr = sprintf('%s %%g',rstr);
end
rstr = strcat(rstr,'\n');
segs = fscanf(fid,rstr,[ 3+natr,nsegs]);
segments = segs(2:3+natr,:)';

nholes = fscanf(fid,'%i\n',1);
if nholes>0
    holes = fscanf(fid,'%i %g %g\n',[3 nholes] );
end
%约束条件
nconst = fscanf(fid,'%g',1);
const= fscanf(fid,'%g %g %g %g %g\n',[ 5,nconst]);
regions = const(2:end,:)';
%关闭文件：
fclose(fid);

end