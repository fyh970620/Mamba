% 海洋电磁快速反演系统
% 基于Matlab GUI开发的关于海洋可控源电磁勘探技术（CSEM）的综合处理软件。
%
% 作者：郭振威
% 中南大学地球科学与信息物理学院
%
%
%
% 用于计算结构张量
function [Sxx, Sxy, Syy] = structureTensor(I,si,so)
[m,n] = size(I);
Sxx = NaN(m,n);
Sxy = NaN(m,n);
Syy = NaN(m,n);

% 高斯导数与卷积的稳健微分：
x  = -2*si:2*si;
g  = exp(-0.5*(x/si).^2);
g  = g/sum(g);
gd = -x.*g/si; %这是标准化的吗？

Ix = conv2(I, conv2(g',gd),'same' );
Iy = conv2(I, conv2(g,gd'),'same' );

Ixx = Ix.^2;
Ixy = Ix.*Iy;
Iyy = Iy.^2;

% 平滑：
x  = -2*so:2*so;
g  = exp(-0.5*(x/so).^2);
Sxx = conv2(Ixx,conv2( g',g ),'same'); 
Sxy = conv2(Ixy,conv2( g',g ),'same'); 
Syy = conv2(Iyy,conv2( g',g ),'same'); 

