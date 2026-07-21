
function hpoly = m2d_plot_poly(sFile,linewidth,color)
%
% reads in .poly file in sFile and plots to current axes. Returns plot 
% object handle hpoly
%

% read in sFile:
[nodes,segs] = m2d_readPoly(sFile);


if ~exist('linewidth','var')
    linewidth = 1;
end
if ~exist('color','var')
    color = 'k';
end   

if ~isempty(nodes)

    x = nodes(:,1);
    y = nodes(:,2);
    
    % Fast plotting of multiple line segments as single graphics object by
    % using nans to denote the line breaks:
    X = [x(segs(:,1:2))  nan(size(segs,1),1)]';
    Y = [y(segs(:,1:2))  nan(size(segs,1),1)]';

    hpoly = plot(X(:),Y(:),'-','tag','polygons','linewidth',linewidth,'color',color);
    
end