function [hfig] = m2d_newFigure( nSize, varargin )
%
% Function to make new figures for MARE2DEM matlab routines. 
%
% Uses pieces from D. Myer's getStackedFig()
%
%
    % Get monitor position
   	nMon = m2d_getMonitorPosition();
     
    
    % Put figure in top left corner of primary monitor:
    nPos = [nMon(1,1) nMon(1,2)+nMon(1,4)  0 0];
    
    % Get new figure and its size.
    if nargin > 1
        hfig = figure(varargin{:});
    else
        hfig = figure;
    end
    
    if exist('nSize','var') && isnumeric(nSize) && length(nSize) == 2
        nPos(3:4) = nSize;
    else
        nSize     = get(hfig, 'OuterPosition');
        nPos(3:4) = nSize(3:4);
    end
     
    nPos(2) = nPos(2) - nPos(4);
    set( hfig, 'OuterPosition', nPos );
    
      
    if nargout < 1
        clear hfig 
    end

return;
