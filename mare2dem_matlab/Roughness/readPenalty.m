% 海洋电磁快速反演系统
% 基于Matlab GUI开发的关于海洋可控源电磁勘探技术（CSEM）的综合处理软件。
%
% 作者：郭振威
% 中南大学地球科学与信息物理学院
%
%
%
% 用于读取Penalty文件
function [pen] = readPenalty(file)

% 打开PSLG文件
fid = fopen(file,'r');

% 读取站点文件的格式字符串：
format = deblank(fgets(fid));
temp = fscanf(fid,'%i %i\n',2);
pen.nnz = temp(1);
pen.nrows = temp(2);
%阅读colind和值：
nnz = temp(1);
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
pencell = fscanf(fid,rstr,[ 2,nnz]);
penread = pencell';
pen.colind=penread(:,1);
pen.val=penread(:,2);

% 逐行阅读：
rowptr=[];
nrow=nnz/2+1;
pen.rowptr=fscanf(fid,'%i\n',nrow);

%关闭档案
fclose(fid);
end