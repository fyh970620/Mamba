function vecrast(infigureHandle, filename, resolution, stack, exportType)

% Kerry Key, 2018-2021: Modified for plotMARE2DEM usage.
% 
% Used to save efficient high resolution images as combination of bitmap
% and vector graphics objects in single output file (pdf or eps). 
%   vector format: lines, symbols and text in vector format 
%   bitmap:  surface image data
%
%
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
% Theodoros Michelis, 6 October 2017
% TUDelft, Aerospace Engineering, Aerodynamics
% t.michelis@tudelft.nl
%
%
% D E S C R I P T I O N:
% vecrast is a function that allows to automatically save a figure with
% mixed vector and raster content. More specifically, two copies of the
% figure of interest are created, rasterFigure and vectorFigure. Patches,
% surfaces, contours, images, and lights are kept in rasterFigure but
% removed from vectorFigure. rasterFigure is then saved as a temporary
% .png image with the required resolution. The .png file is subsequently
% inserted into the vectorFigure, and the result is saved in a single
% vector file.
%
%
% I N P U T:
% vecrast(figureHandle, filename, resolution, stack, exportType)
%   figureHandle:   Handle of the figure of interest
%   filename:       Baseline name string of output file WITHOUT the extension.
%   resolution:     Desired resolution of rasterising in dpi
%   stack:          'top' or 'bottom'. Stacking of raster image with
%                       respect to axis in vector figure, see examples below.
%   exportType:     'pdf' or 'eps'. Export file type for the output file.
%
%
% N O T E S:
% - The graphics smoothing (anti-aliasing) is turned off for the raster
%   figure. This improves sharpness at the borders of the image and at the
%   same time greatly reduces file size. You may change this option in the
%   script by setting 'GraphicsSmoothing', 'on' (line 82).
% - A resolution of no less than 300 dpi is advised. This ensures that
%   interpolation at the edges of the raster image does not cause the image
%   to bleed outside the prescribed axis (make a test with 20dpi on the
%   first example and you will see what I mean).
% - The stacking option has been introduced to accomodate 2D and 3D plots
%   which require the image behind or in front the axis, respectively. This
%   difference can be seen in the examples below.
% - I strongly advise to take a look at the tightPlots function that allows
%   setting exact sizes of figures.

% E X A M P L E   1:
%   clear all; close all; clc;
%   Z = peaks(20);
%   contourf(Z,10)
%   vecrast(gcf, 'example1', 300, 'bottom', 'pdf');

% E X A M P L E   2:
%   clear all; close all; clc;
%   [X,Y] = meshgrid(1:0.4:10, 1:0.4:20);
%   Z = sin(X) + cos(Y);
%   surf(X,Y,Z)
%   vecrast(gcf, 'example2', 300, 'top', 'pdf');

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

% Some checks of the input ------------------------------------------------
if strcmp(stack, 'top') + strcmp(stack, 'bottom') == 0
    error('Stack must be ''top'' or ''bottom''');
end
if strcmp(exportType, 'pdf') + strcmp(exportType, 'eps') == 0
    error('Stack must be ''pdf'' or ''eps''');
end


% Ensure figure has finished drawing
drawnow;

% Copy figure:
figureHandle = copyobj(infigureHandle, groot);

% Set figure units to points
set(figureHandle, 'units', 'points', 'visible', 'off','inverthardcopy','off','color','w')
figurePosition = get(figureHandle, 'Position');

lLandscape = false;
if figurePosition(3) > figurePosition(4) && strcmp(exportType, 'pdf') 
    set(figureHandle,'paperorientation','landscape' );
    lLandscape = true;
end

axesHandle     = findall(figureHandle, 'type', 'axes');
set(axesHandle,'units','normalized');

colorbarHandle = findobj(figureHandle,'tag','Colorbar');
set(colorbarHandle,'units','normalized');

% Ensure figure size and paper size are the same

axesPosition     = get(axesHandle, 'Position');
colorparPosition = get(colorbarHandle, 'Position');
 
% if PDF output, resize to fit on page:
if strcmp(exportType, 'pdf')  
    set(figureHandle,'paperunits','points','papertype','usletter')
    if lLandscape
        fac = figurePosition(3)/612; %792; %ptFac is 792 (landscape) or 612 (portrait)
    else
        fac = figurePosition(4)/612; %/792; %ptFac is 792 (landscape) or 612 (portrait)
    end
    figurePosition = figurePosition/fac;
    set(figureHandle,'position',figurePosition);
else
    fac = 1;
    set(figureHandle, 'PaperUnits', 'points', 'PaperSize', [figurePosition(3) figurePosition(4)])
    set(figureHandle, 'PaperPositionMode', 'manual', 'PaperPosition', [0 0 figurePosition(3) figurePosition(4)]);
end

if fac ~= 1  % scale fonts, lines and markers:
    
    for i = 1:length(axesHandle)
        set(axesHandle(i), 'FontSize', get(axesHandle(i), 'FontSize')/fac);
    end

    vecText = findall(figureHandle, 'type', 'text');
    for i=1:length(vecText)
        set(vecText(i), 'FontSize', get(vecText(i), 'FontSize')/fac);
    end
    
    % Line and marker data:
    vecLines = findobj(figureHandle,'type','line');
    for i=1:length(vecLines)
        set(vecLines(i), 'markersize', get(vecLines(i), 'markersize')/fac);       
        set(vecLines(i), 'LineWidth' , get(vecLines(i), 'LineWidth')/fac);
    end    
    if length(axesHandle) == 1
        set(axesHandle,'position',axesPosition);
    else
        for i = 1:length(axesHandle)
            set(axesHandle(i),'position',axesPosition{i});
        end
    end
    % Scatter data:
    vecScat = findobj(figureHandle,'type','scatter');
    for i=1:length(vecScat)
        set(vecScat(i), 'SizeData',   get(vecScat(i), 'SizeData')/fac);       
        set(vecScat(i), 'LineWidth' , get(vecScat(i), 'LineWidth')/fac);
    end        
    
    % colorbar text
    hCb = findobj(figureHandle,'tag','Colorbar');
    hYl = get(hCb,'ylabel');
    if length(hYl) == 1        
        set(hYl,'fontsize',get(hYl,'fontsize')/fac);
        set(get(hCb,'title'),'fontsize',get(get(hCb,'title'),'fontsize')/fac)
        set(colorbarHandle,'position',colorparPosition);         
    else      
        for i = 1:length(hYl)
            set(hYl{i},'fontsize',get(hYl{i},'fontsize')/fac);
            set(get(hCb(i),'title'),'fontsize',get(get(hCb(i),'title'),'fontsize')/fac)
            set(colorbarHandle(i),'position',colorparPosition{i});
        end
    end
end

% Create a copy of the figure and remove smoothness in raster figure
rasterFigure = copyobj(figureHandle, groot);
vectorFigure = copyobj(figureHandle, groot);

set(rasterFigure, 'GraphicsSmoothing', 'on', 'color', 'w', 'visible', 'off'); 
set(vectorFigure, 'GraphicsSmoothing', 'on', 'color', 'w', 'visible', 'off');

% Fix vector image axis limits based on the original figure
% (this step is necessary if these limits have not been defined)
axesHandle = findall(vectorFigure, 'type', 'axes');
for i = 1:length(axesHandle)
    xlim(axesHandle(i), 'manual');
    ylim(axesHandle(i), 'manual');
    zlim(axesHandle(i), 'manual');
end

% Create axis in vector figure to fill with raster image
rasterAxis = axes(vectorFigure, 'color', 'none', 'box', 'off', 'units', 'points');
set(rasterAxis, 'position', [0 0 figurePosition(3) figurePosition(4)]);
uistack(rasterAxis, stack);

% Ensure fontsizes are the same in all figures
figText = findall(figureHandle, 'type', 'text');
rastText = findall(rasterFigure, 'type', 'text');
vecText = findall(vectorFigure, 'type', 'text');
for i=1:length(figText)
    set(rastText(i), 'FontSize', get(figText(i), 'FontSize'));
    set(vecText(i), 'FontSize', get(figText(i), 'FontSize'));
end

% Raster Figure ----------------------------------------------------------
% Select what to remove from raster figure
axesHandle = findall(rasterFigure, 'type', 'axes');
axesPosition = get(axesHandle,'position'); %kwk save position since removing some 2 line title text objects below can result in auto resizing
%set(axesHandle, 'color', 'none');
set(axesHandle,'xtick',[],'ytick',[],'xlabel',[],'ylabel',[],'title',[],'box','off','xc','w','yc','w')

for i = 1:length(axesHandle)
    contents = findall(axesHandle(i));
    toKeep = [...
        findall(axesHandle(i), 'type', 'patch');...
        findall(axesHandle(i), 'type', 'surface');...
        findall(axesHandle(i), 'type', 'contour');...
        findall(axesHandle(i), 'type', 'image');...
        findall(axesHandle(i), 'type', 'axes');...
        findall(axesHandle(i), 'type', 'light')
        ];
    toRemove = setxor(contents, toKeep);
    set(toRemove, 'visible', 'off');
end

% Remove all annotations from raster figure
annotations = findall(rasterFigure, 'Tag', 'scribeOverlay');
for i = 1:length(annotations)
    set(annotations(i), 'visible', 'off');
end

% Hide all colorbars and legends from raster figure
colorbarHandle = findall(rasterFigure, 'type', 'colorbar');
legendHandle = findall(rasterFigure, 'type', 'legend');
set([colorbarHandle; legendHandle], 'visible', 'off');
if length(axesHandle) == 1
    set(axesHandle,'position',axesPosition);
else
    for i = 1:size(axesHandle)
        set(axesHandle(i),'position',axesPosition{i}); % restore original position if auto resized...
    end
end
% Print rasterFigure on temporary .png
% ('-loose' ensures that the bounding box of the figure is not cropped)
set(rasterFigure,'papersize',figurePosition(3:4),'paperposition',figurePosition)

[p,n,e] = fileparts(filename);
tempRasterFilename = fullfile(p, ['.' n 'Temp.png']);
print(rasterFigure,tempRasterFilename, '-dpng', ['-r' num2str(resolution) ], '-opengl');  % , '-loose' doesn't apply to png...
close(rasterFigure);
close(figureHandle);

% Vector Figure -----------------------------------------------------------
% Select what to keep in vector figure
axesHandle = findall(vectorFigure, 'type', 'axes');
set(axesHandle, 'color', 'none');
for i = 1:length(axesHandle)
    toRemove = [...
        findall(axesHandle(i), 'type', 'patch');...
        findall(axesHandle(i), 'type', 'surface');...
        findall(axesHandle(i), 'type', 'contour');...
        findall(axesHandle(i), 'type', 'image');...
        findall(axesHandle(i), 'type', 'light');...
        ];
    set(toRemove, 'visible', 'off');
end

% Insert Raster image into the vector figure
[A, ~, alpha] = imread(tempRasterFilename);

if isempty(alpha)==1
 % 4/6/20: kwk debug: commenting out since this incorrrectly rotates in
 % R2019b. Worked before though, oh well, whatever Mathworks...
%     if lLandscape  
%         imagesc(rasterAxis, fliplr(permute(A,[2 1 3])));
%     else
        imagesc(rasterAxis, A);     
%    end
else
    imagesc(rasterAxis, A, 'alphaData', alpha);
end
axis(rasterAxis, 'off');

% Bring all annotations on top
annotations = findall(vectorFigure, 'Tag', 'scribeOverlay');
for i = 1:length(annotations)
    uistack(annotations(i), 'top'); 
end
 
% Ensure figure has finished drawing
drawnow;

% Finalise ----------------------------------------------------------------
% Remove raster image from directory
delete(tempRasterFilename); % COMMENT THIS IF YOU WANT TO KEEP PNG FILE


% Print and close the combined vector-raster figure
% set(vectorFigure, 'Renderer', 'painters');
if strcmp(exportType, 'pdf')  
    % set page size to limits of figure:
    set(vectorFigure,'units','points');
    figurePosition = get(vectorFigure,'position');
    set(vectorFigure,'papersize',figurePosition(3:4));
    set(vectorFigure,'paperposition',[0 0 figurePosition(3:4)]);
    print(vectorFigure, [filename '.pdf'], '-dpdf', '-loose', '-painters','-noui', ['-r' num2str(resolution) ]);
elseif strcmp(exportType, 'eps')  
    print(vectorFigure, [filename '.eps'], '-depsc2', '-loose', '-painters','-noui');
end

close(vectorFigure);
 
 

end