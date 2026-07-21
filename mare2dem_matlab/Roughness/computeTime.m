% function [ t0 ] = computeTime( d11,d12,d22,s1,s2,t1,t2 )
function [ t0 ] = computeTime( d11,d12,d22,t1,t2 )
% 海洋电磁快速反演系统
% 基于Matlab GUI开发的关于海洋可控源电磁勘探技术（CSEM）的综合处理软件。
%
% 作者：郭振威
% 中南大学地球科学与信息物理学院
%
%
%
%这个函数用于计算相邻点之间的时间
%
%
%
%   输入: D11,D12,D22 是度规张量;
%          s1,s2 是度规张量;
%          t1,t2 是两点之间的时间,x，y方向
%   输出:  t0是两点之间的时间.

%     ds11 = d11*s1*s1;
%     ds12 = d12*s1*s2;
%     ds22 = d22*s2*s2;
    t12 = abs(t1-t2);
%     a = ds11+2.0*ds12+ds22;
%     b = 2.0*(ds12+ds22)*t12;
%     c = ds22*t12*t12-1.0;
%     d = b*b-4.0*a*c;

    a = d11+d22+2.0*d12;
    b = -2.0*(d11*t1+d22*t2+d12*(t1+t2));
    c = d11*t1*t1+d22*t2*t2+2.0*d12*t1*t2-1;
    d = b*b-4.0*a*c;
    if (d<0.0)
      t0=Inf;
      return;
    else
      u1 = (-b+sqrt(d))/(2.0*a); % t0-t1//%u1
%       u2 = (-b-sqrt(d))/(2.0*a); % u2
      u2 = u1+t12;               % t0-t2
      if u1<0.0 || u2<0.0
          t0=Inf;
          return;
      else 
          t0=u1;
          return;
      end
      if (ds11*u1+ds12*u2 < 0.0 || ds12*u1+ds22*u2 < 0.0)
          t0=NaN;
          return;
      else
        t0=t1+u1;
        t0=t2+u2;
      return; 
      end
    end

end

