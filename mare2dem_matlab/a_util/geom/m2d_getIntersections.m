function [intersect, xi, yi, pa, pb] = m2d_getIntersections(xya,xyb)
% tests for insection of any line in xya with the single line in xyb

intersect = [];
xi = [];
yi = [];

nb = size(xyb,1);
if nb > 1
    beep;
    disp('getIntersections assumes second segment is a single line!')
    return;
end

naInput = size(xya,1);

% First cut to reduce number of comps, is segment xyb in bounding boxes of the
% segments in xya>
iOverlap = doRectsOverlap(xyb,xya);

xya = xya(iOverlap,:);

% replicate b points na times:
na = size(xya,1);
xyb = repmat(xyb,na,1);

% Some differences for the linear equations:
dxb   = xyb(:,2) - xyb(:,1);
dxa   = xya(:,2) - xya(:,1);
dyb   = xyb(:,4) - xyb(:,3);
dya   = xya(:,4) - xya(:,3);
dy1ab = xya(:,3) - xyb(:,3);
dx1ab = xya(:,1) - xyb(:,1);

num_a = dxb.*dy1ab - dyb.*dx1ab;
num_b = dxa.*dy1ab - dya.*dx1ab;
den   = dyb.*dxa   - dxb.*dya;

pa = num_a ./den;
pb = num_b ./den;


% pa == 0 means first a node is intersection
% pa == 1 means second a node is intersection
% 0 < pa < 1 means intersection is on interior of segment a

% pb == 0 means first b node is intersection
% pb == 1 means second b node is intersection
% 0 < pb < 1 means intersection is on interior of segment b

xi = xya(:,1) + dxa.*pa;
yi = xya(:,3) + dya.*pa;

%Adj = (pa >= 0) & (pa <= 1) & (pb >= 0) & (pb <= 1);
tol = 1000*eps;
intersect = ( (pa > 0+tol) & (pa < 1-tol) & (pb > 0+tol) & (pb < 1-tol));
xi = xi(intersect);
yi = yi(intersect);

a = pa;
b = pb;
pa = -1*ones(naInput,1);
pb = pa;
pa(iOverlap) = a;
pb(iOverlap) = b;

intersect = iOverlap(intersect);


end
%----------------------------------------------------------------------
function overlap = doRectsOverlap(aRect,manyRects)
% overlap = index of rows where the single rectangle in aRect overlaps a rectangle in manyRect
% [x0 x1 y0 y1];

ax1 = min(aRect(1:2));
ax2 = max(aRect(1:2));
ay1 = min(aRect(3:4));
ay2 = max(aRect(3:4));

bx1 = min(manyRects(:,1:2),[],2);
bx2 = max(manyRects(:,1:2),[],2);
by1 = min(manyRects(:,3:4),[],2);
by2 = max(manyRects(:,3:4),[],2);

%    overlap = find( ~ ((ax1 > bx2 | bx1 > ax2) | (ay1 > by2 | by1 > ay2)));
d1 = ax1 - bx2;
d2 = bx1 - ax2;
d3 = ay1 - by2;
d4 = by1 - ay2;

tol = eps*100;

l1 = d1 > tol;
l2 = d2 > tol;
l3 = d3 > tol;
l4 = d4 > tol;

overlap = find(~((l1 | l2) | ( l3 | l4) ));

end