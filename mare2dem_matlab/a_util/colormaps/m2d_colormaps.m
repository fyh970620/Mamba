function varargout = m2d_colormaps(varargin)
% varargout = m2d_colormaps(varargin)
%
% Function for managing colormaps for the MARE2DEM MATLAB codes.
%
% Usage:
%
% cm = m2d_colormaps(colormap_name) returns the nx3 colormap.
% 
% cList = m2d_colormaps('list_all') generates a cell list of all available
% colormaps
%
% hfigure = m2d_colormaps('display_all') creates a figure showing all colormaps.
%
% Copyright 2018
% Kerry Key
% Lamont Doherty Earth Observatory
% Columbia University
%
%

% Developer notes:
% 
%  To add a new colormap, add it to the sub_getColorMapList() cell array
%  and add a function to retrieve it to sub_getColorMap().
%

if nargin ~= 1
   return
end

 
switch lower(varargin{1})
    
    case 'list_all'
        varargout{1} = sub_getColorMapList(); 
        
    case 'display_all'
        varargout{1} = sub_displayColorMaps();     

    otherwise
        if ischar(varargin{1})
            varargout{1} = sub_getColorMap(varargin{1});  
        end
        
end

if nargout< 1
   clear varargout
end


end
%--------------------------------------------------------------------------
function cColorMapList = sub_getColorMapList()

% {name, calling function(if different than name), classification, source}
    cColorMapList = {
        'parula'    ''              'linear'            'MATLAB';     
        'viridis'   ''              'linear'            'matplotlib';     
        'inferno'   ''              'linear'            'matplotlib';     
        'magma'     ''              'linear'            'matplotlib';
        'plasma'    ''              'linear'            'matplotlib';   
        'edge'      'pmkmp'         'diverging'         'Matteo Niccoli';   
        'linearl'   'pmkmp'         'linear'            'Matteo Niccoli';   
        'linlhot'   'pmkmp'         'linear'            'Matteo Niccoli';   
        'cubicyf'   'pmkmp'         'linear'            'Matteo Niccoli';   
        'cubicl'    'pmkmp'         'rainbow'           'Matteo Niccoli'; 
        'swtth'     'pmkmp'         'rainbow non uniform'   'Matteo Niccoli';   
        'jet'       ''              'rainbow non uniform'   'MATLAB';  
        'hsv'       ''              'rainbow non uniform'   'MATLAB' ; 
        'L1'        'colorcet'      'grayscale'         'Peter Kovesi';
        'L2'        'colorcet'      'grayscale'         'Peter Kovesi';
        'L3'        'colorcet'      'linear'            'Peter Kovesi';
        'L4'        'colorcet'      'linear'            'Peter Kovesi';
        'L5'        'colorcet'      'linear'            'Peter Kovesi';
        'L6'        'colorcet'      'linear'            'Peter Kovesi';
        'L7'        'colorcet'      'linear'            'Peter Kovesi';
        'L8'        'colorcet'      'linear'            'Peter Kovesi';
        'L9'        'colorcet'      'linear'            'Peter Kovesi';
        'L10'       'colorcet'      'linear'            'Peter Kovesi';
        'L11'       'colorcet'      'linear'            'Peter Kovesi';       
        'L12'       'colorcet'      'linear'            'Peter Kovesi';
        'L13'       'colorcet'      'linear'            'Peter Kovesi';  
        'L14'       'colorcet'      'linear'            'Peter Kovesi';
        'L15'       'colorcet'      'linear'            'Peter Kovesi';       
        'D1'        'colorcet'      'diverging'         'Peter Kovesi';
        'D2'        'colorcet'      'diverging'         'Peter Kovesi';
        'D3'        'colorcet'      'diverging'         'Peter Kovesi';
        'D4'        'colorcet'      'diverging'         'Peter Kovesi';
        'D5'        'colorcet'      'diverging'         'Peter Kovesi';
        'D6'        'colorcet'      'diverging'         'Peter Kovesi';
        'D7'        'colorcet'      'diverging'         'Peter Kovesi';
        'D8'        'colorcet'      'diverging'         'Peter Kovesi';
        'D9'        'colorcet'      'diverging'         'Peter Kovesi';
        'D10'       'colorcet'      'diverging'         'Peter Kovesi';
        'D11'       'colorcet'      'diverging'         'Peter Kovesi';        
        'D12'       'colorcet'      'diverging'         'Peter Kovesi';
        'R1'        'colorcet'      'rainbow'           'Peter Kovesi';
        'R2'        'colorcet'      'rainbow'           'Peter Kovesi';
        'R3'        'colorcet'      'rainbow'           'Peter Kovesi';
        'CBL1'      'colorcet'      'colorblind'        'Peter Kovesi';    
        'CBL2'      'colorcet'      'colorblind'        'Peter Kovesi';    
        'CBL3'      'colorcet'      'colorblind'        'Peter Kovesi';    
        'CBL4'      'colorcet'      'colorblind'        'Peter Kovesi';    
        'CBD1'      'colorcet'      'colorblind'        'Peter Kovesi';    
        'CBD2'      'colorcet'      'colorblind'        'Peter Kovesi';      
        'CBTL1'     'colorcet'      'colorblind'        'Peter Kovesi';    
        'CBTL2'     'colorcet'      'colorblind'        'Peter Kovesi';    
        'CBTL3'     'colorcet'      'colorblind'        'Peter Kovesi';    
        'CBTL4'     'colorcet'      'colorblind'        'Peter Kovesi';    
        'CBTD1'     'colorcet'      'colorblind'        'Peter Kovesi'; 
        'turbo'     'turbo'         'rainbow'           'Google via Daniel Fortunato'
%     names:  'L1' - 'L15'  for linear maps
%             'D1' - 'D12'  for diverging maps
%             'C1' - 'C9'   for cyclic maps
%             'R1' - 'R3'   for rainbow maps
%             'I1' - 'I3'   for isoluminant maps
%                                                    
%     maps for the red-green colour blind (Protanopia/Deuteranopia)
%             'CBL1' - 'CBL4' 
%             'CBD1' - 'CBD2' 
%             'CBC1' - 'CBC2' 
%     maps for the blue-yellow colour blind (Tritanopia)
%             'CBTL1' - 'CBTL4' 
%             'CBTD1' 
%             'CBTC1' - 'CBTC2'         
        };
end

%--------------------------------------------------------------------------
function cm = sub_getColorMap(scolormap)

cColorMapList = sub_getColorMapList();


iRow = strncmpi(scolormap,cColorMapList(:,1),length(scolormap));

if isempty(iRow)
    beep;
    fprintf('Colormap not found in sub_getColorMap: %s\n',scolormap);
    % use default:
    iRow = 1;  
    scolormap = 'parula';
end

% parse input str and load in the requested colormap:

sFunction = cColorMapList{iRow,2};

switch lower(sFunction)
    
    case 'pmkmp'   
        n = size(get(gcf,'colormap'),1);
        cm = pmkmp(n,scolormap);
    case 'colorcet'
        cm = colorcet(scolormap);
    otherwise
        cm = feval(scolormap);
end

end

%--------------------------------------------------------------------------
function hfigure = sub_displayColorMaps()

cColorMapList = sub_getColorMapList();

nScreenSize = m2d_getMonitorPosition();
hfigure = m2d_newFigure([nScreenSize(1,3:4)*1]);

[cCategories,~,ic] = unique(cColorMapList(:,3));
 
n = size(cColorMapList,1);

nrow = ceil(sqrt(n));
ncols = ceil(n/nrow);

i = 0;
for iCat = 1:length(cCategories)
    
    icc = find(ic == iCat);
    for j = 1:length(icc)
        i = i + 1;
        ax = subplot(nrow,ncols,i);
        cm = sub_getColorMap(cColorMapList{icc(j),1});
        imagesc([1:128]);
        colormap(ax,cm);
        set(ax,'xtick',[],'ytick',[]); 
        str1 = cColorMapList{icc(j),1};
        str2 = cColorMapList{icc(j),2};
        str3 = cColorMapList{icc(j),3};
        str4 = cColorMapList{icc(j),4};
        
        str = sprintf('%s (%s)\n Source: %s',str1,str3,str4);
        title(str)
    end
end

 
      
if nargout < 1
    clear hfigure 
end 


end


