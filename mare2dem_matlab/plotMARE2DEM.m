function hFig = plotMARE2DEM(varargin)
%
% Plots a MARE2DEM resistivity model with iteractivity.
%
% Copyright 2017-2022
% Kerry Key
% Lamont Doherty Earth Observatory
% Columbia University
% http://emlab.ldeo.columbia.edu
%
% Copyright 2004-2016
% Kerry Key
% Scripps Institution of Oceanography
% University of California, San Diego
%
% Currently funded through the Electromagnetic Methods Research Consortium
% at the Lamont Doherty Earth Observatory, Columbia University.
% 
% Originally developed for the Seafloor Electromagnetic Methods 
% Consortium at Scripps.
%
% License:
%
% This program is free software; you can redistribute it and/or modify it
% under the terms of the  GNU General Public License as published by the
% Free Software Foundation; either version 2 of the License, or (at your
% option) any later version. This program is distributed in the hope that
% it will be useful, but WITHOUT ANY WARRANTY; without even the implied
% warranty of MERCHANTABILITY or FITNESS FOR A PARTICULAR  PURPOSE. See
% the GNU General Public License for more details. You should have received
% a copy of the GNU General Public License along with this program; if not,
% write to the Free Software Foundation, Inc.,
% 51 Franklin St, Fifth Floor, Boston, MA 02110-1301 USA.
%

%--------------------------------------------------------------------------

hFig     = [];
bNewIter = false;

%
% Parse the input arguments:
%
home = pwd;

if nargin() == 0
    
    [sFile,sIterPath] = uigetfile( '*.resistivity', 'Select a MARE2DEM resistivity file to plot:' );
    if ~ischar(sFile)
        disp('No files selected for plotting, returning...')
        if nargout() < 1    % don't spew "[]" to stdout
            clear hFig
        end
        return
    end
    
    %cd(sIterPath);
    inFile = fullfile(sIterPath,sFile);
    
elseif nargin() == 1
    
    inFile = varargin{1};
    
    inFile = m2d_getMostRecent(inFile,'*.resistivity');
    
    if isempty(inFile)
        h = warndlg('Error, no MARE2DEM resistivity file was found','Error','modal') ;
        waitfor(h)
        if nargout() < 1    % don't spew "[]" to stdout
            clear hFig
        end
        return
    end

elseif nargin() > 1 % callback to plotting functions
    
    switch lower(varargin{1})
        
        case 'newiter'
            bNewIter    = true;
            inFile      = varargin{2};
            hFig        = varargin{3};
            st          = get(hFig,'userdata'); 
            inFile      = fullfile(st.directory,inFile);
            stSettings  = getappdata(hFig,'stSettings');
            setappdata(hFig,'bChanged',true);
            
        otherwise
            % This is the entry point for external functions to call into
            % plotMARE2DEM in order to control / customize some of the
            % appearance of the plot window. Those external functions don't need
            % to know about the two unused params (hObj, event_data).
            f = str2func(varargin{1});
            [varargout{1:nargout}] = feval(f,[],[],varargin{2:end}); %#ok<*NASGU>
            if nargout() < 1    % don't spew "[]" to stdout
                clear hFig
            end
            return;
    end
end

if ~exist('st','var')
    
    st = [];
    st.sWJfile = [];
    st.sensitivity  = [];
    st.contourAxLim = [];
    st.icmp = 1;
 
end


if ~isempty(hFig)
    set( hFig, 'Pointer', 'watch' );
    drawnow;       
end

sub_removeListeners(hFig);


% Read in the files
[sIterPath] = fileparts(inFile);
if isempty(sIterPath)
    sIterPath = pwd;
end
res = m2d_readResistivity(inFile);

% special case: if 'tiz_ratio', replace z/h with h:
if strcmpi(res.anisotropy,'tiz_ratio')
    res.resistivity(:,2) = res.resistivity(:,1)./res.resistivity(:,2); % h = z/(z/h)
     % kwk debug: I still need to also modify sensistivity plotting code
     
end
% copy res struct to st struct
names = fieldnames(res);
for i = 1:length(names)
    st.(names{i}) = res.(names{i});
end
 
[st.nodes,st.segs,st.eles,holes,st.regions] = m2d_readPoly(fullfile(sIterPath,st.polyFile));
stD = m2d_readEMData2DFile(fullfile(sIterPath,st.dataFile));

% move stD's fields into st so we don't have to deal with too many nested structures 
if ~isempty(stD)
    st.stUTM  = stD.stUTM;
    st.stCSEM = stD.stCSEM;
    st.stMT   = stD.stMT;
    st.stDC   = stD.stDC;
    st.DATA   = stD.DATA;
else
    st.stUTM  = [];
    st.stCSEM = [];
    st.stMT   = [];
    st.stDC   = [];
    st.DATA   = [];    
end

st.resistivityFile = inFile;
st.directory       = sIterPath;
st.plotSensitivity = false;
 
% Make a DT:
st.TR = delaunayTriangulation(st.nodes(:,1),st.nodes(:,2),st.segs(:,1:2));

% Get a region index for each triangle:
[st.TriIndex, st.regionIndex] = m2d_getTriangleRegions(st.TR,st.segs(:,1:2),st.regions(:,1:2)); 

% Get anisotropic components:
st = setComponentList(st);

%
% Draw the figure:
%

 if ~bNewIter % new figure, first time plotting:
%     
    % Get the defaults
    stSettings = sub_getDefaults();
    
    % Try getting MRU values that override the defaults:
    stSettings = sub_getMRU(stSettings);
    
    % always turn off jacobian initially:
    stSettings.showSensContours = 'off';
  
    % Create a figure:
    [nMon] = m2d_getMonitorPosition();
    nSizeMax = [1800 1200];
    nSize(1) = min([nMon(1,3),nSizeMax(1)]);
    nSize(2) = min([nMon(1,4),nSizeMax(2)]);

    hFig = m2d_newFigure(nSize ,'visible','off');
    
    hFig.OuterPosition = stSettings.figureOuterPosition;
    
    set(hFig, 'menubar', 'figure', 'toolbar', 'figure', ...
              'CloseRequestFcn', {@sub_Close, hFig},...
              'SizeChangedFcn', {@sub_SizeChanged, hFig});
 
    % Set toolbar menus:
    sub_setToolBar(hFig)

    st.axes = gca;
 
    % Set aspect ratio:
    if strcmpi(stSettings.equalAspect,'on')
            axis auto;  % this sequence makes the axes fill the figure and then sets equal aspect
            axis fill;
            axis equal    
    else
        axis(st.axes,'normal')
    end

    [xlim,ylim] = m2d_estimateAreaOfInterest(st);

    set(hFig,'userdata',st,'CreateFcn',{@sub_reopenFig})

 
    % Update showFixed and showFree depending on model's fixed and free
    % regions. The idea is to catch when showFixed is false and the model
    % only contains fixed parameters and this nothing will be plotted...
    % we only catch that here when loading in a new model. 
    if strcmp(stSettings.showFixed,'off') && strcmp(stSettings.showFree,'off') % both off then turn both on
        stSettings.showFixed = 'on';
        set(findobj(hFig,'tag','showFixed'),'checked','on');      
        stSettings.showFree = 'on';
        set(findobj(hFig,'tag','showFree'),'checked','on');          
    elseif strcmp(stSettings.showFixed,'off') && ~any(st.freeparameter(:)) % fixed parameters off but model only has fixed parameters
        stSettings.showFixed = 'on';
        set(findobj(hFig,'tag','showFixed'),'checked','on');        
    end
    if strcmp(stSettings.showFree,'off') && all(st.freeparameter(:)) % free parameters off but model only has free parameters
        stSettings.showFree = 'on';
        set(findobj(hFig,'tag','showFree'),'checked','on');        
    end
                
    setappdata(hFig,'stSettings',stSettings);
    
    drawFigure(hFig,xlim,ylim );
    
    set(hFig,'visible','on')

 else

    set(hFig,'userdata',st);
    setappdata(hFig,'stSettings',stSettings);
    drawFigure(hFig );
    
end   

cd(home);
set( hFig, 'Pointer', 'arrow' ); drawnow       % progress pointer 

sub_addListeners(hFig);

setappdata(hFig,'bChanged',false);
setappdata(hFig,'bClosed',false);

if nargout() < 1    % don't spew "[]" to stdout
    clear hFig
end

end % plotMARE2DEM

%----------------------------------------------------------------------
function sub_Close( ~, ~, hFig )

    % save new figure position to settings so next time plotMARE2DEM is opened it uses
    % same position. This assumes user repositions figure to some desired size
    % and location.
    stSettings  = getappdata(hFig,'stSettings');
    stSettings.figureOuterPosition = hFig.OuterPosition;
    sub_saveMRU(stSettings,hFig);

% Modified from function written by D. Myer:
    
    bChanged = getappdata(hFig,'bChanged');
    st = get( hFig, 'UserData' );
    if bChanged
        sBtn = questdlg( 'Save changes before exit?', 'plotMARE2DEM' ...
            , 'Yes', 'No', 'Cancel', 'Yes' );
        if strcmpi( sBtn, 'yes' )
            sub_save([],[],hFig);
 
        elseif ~strcmpi( sBtn, 'no' )
            return;
        end
    end
   % If we get here, then closing the dialog is OK.
    delete( hFig );
 
    return;
end % sub_Close

%----------------------------------------------------------------------
function sub_SizeChanged( ~, ~, hFig )
    
    % update any additional axes overlays on figure:
    sub_adjustSecondAxes(hFig); 
  
    return;
end % SizeChangedFcn
 
%--------------------------------------------------------------------------
function sub_addListeners(hFig)
    % This allow user to udpate zoom using tool bar and code updates UTM
    % labels. Also user can udpate caxis and colormap from command line and
    % it is stored in the st structure so these don't change if plotting
    % new iteration etc.
    
    st = get(hFig,'userdata');
    
    st.lh1 = addlistener(st.axes,{'XTick' 'YTick'  'XDir' 'YDir' 'XLim' 'YLim' },'PostSet',@zoom_updateAxes);  % this seems to be called all the time when clicking on figure...
 
    st.lh2 = addlistener( st.axes , 'CLim' , 'PostSet' , @listener_updateCLim); 
    
    st.lh3 = addlistener(hFig,'UserData', 'PostSet' , @listener_updateUserdata); 
    
    set(hFig,'userdata',st);
    
end


%--------------------------------------------------------------------------
function sub_removeListeners(hFig)
    % remove listeners prior to saving a .fig file (otherwise you get error
    % on reopening figure):
    st = get(hFig,'userdata');
    if isfield(st,'lh1')
        delete(st.lh1) 
    end
    if isfield(st,'lh2')
        delete(st.lh2)
    end
    if isfield(st,'lh3')
        delete(st.lh3)
    end
end

%--------------------------------------------------------------------------
function sub_reopenFig(hFig,~)

% Set toolbar menus:
sub_setToolBar(hFig)

% restore zoom and other listeners:
sub_addListeners(hFig);
   
  
end
%--------------------------------------------------------------------------
function sub_setToolBar(hFig)

% Turn off some menus too:

    delete(findall(hFig,'tag','figMenuFile'))
    delete(findall(hFig,'tag','figMenuWindow'))
    delete(findall(hFig,'tag','figMenuDesktop'))
    delete(findall(hFig,'tag','figMenuTools'))
    delete(findall(hFig,'tag','figMenuHelp'))

% Turn off most buttons:
    set(findall(hFig,'ToolTipString','Save Figure'),'visible','off')
    set(findall(hFig,'ToolTipString','Open File'),'visible','off')
    set(findall(hFig,'ToolTipString','New Figure'),'visible','off')
    
    set(findall(hFig,'ToolTipString','Rotate 3D'),'visible','off')
    set(findall(hFig,'ToolTipString','Insert Legend'),'visible','off')
    set(findall(hFig,'ToolTipString','Insert Colorbar'),'visible','off')
    set(findall(hFig,'ToolTipString','Data Cursor'),'visible','off')
    set(findall(hFig,'ToolTipString','Brush/Select Data'),'visible','off')
    set(findall(hFig,'ToolTipString','Link Plot'),'visible','off')
    set(findall(hFig,'ToolTipString','Show Plot Tools and Dock Figure'),'visible','off')
    set(findall(hFig,'ToolTipString','Hide Plot Tools'),'visible','off')
    
    % Hijack the print button callback:
    set(findall(hFig,'ToolTipString','Print Figure'),'visible','on',...
                     'ClickedCallback', {@sub_print, hFig},...
                     'ToolTipString','Print Figure to Image File')
  
                 
end

%--------------------------------------------------------------------------
function sub_print(hObject,~,hFig)
    
    % Get file name:
    st = get(hFig,'userdata');
    
    sBaseFile = st.resistivityFile; %strtrim(get(findobj(st.hFigure,'tag','filenameroot'),'string'));
    str = '';
    if ~isempty(sBaseFile)
        str = sprintf('%s',sBaseFile);
    end
    [file, path ] = uiputfile({'*.eps';'*.pdf';'*.png'},' Save plotMARE2DEM figure as',str);
    if file==0
        return
    end
    [p, n, e] = fileparts(file);
    
    sFile = fullfile(path,n);
    
    set(hFig, 'Pointer', 'watch' ); drawnow;
    
    if strcmpi(e,'.pdf')
        ext = 'pdf';
    else
        ext = 'eps';
    end
    if isfield(st,'hax2') && ~isempty(st.hax2)
        set(st.hax2,'handlevisibility','on')
    end
    
    hFigPrint = copyobj(hFig, groot);
    set(hFigPrint,'visible','off','inverthardcopy','off','color','w');
    
    if isfield(st,'hax2') && ~isempty(st.hax2)
        set(st.hax2,'handlevisibility','off')
    end
    
    % Delete the red resistivity text for the current button press location: 
    delete(findobj(hFigPrint,'Tag', 'PointInPatchText' ))
    
    if strcmpi(e,'.png')
        print(hFigPrint,strcat(sFile,e),'-dpng','-r300','-noui')
    else
        % Use vecrast to save surface as bitmap and annotations in vector format.
        vecrast(hFigPrint, sFile, 300, 'bottom', ext);
    end
    
    close(hFigPrint);
    
    % Display message:
    str = [n e];
    h = helpdlg(sprintf('Done saving image to file  %s', str),'plotMARE2DEM Message:');
    set(h,'windowstyle','modal');
    uiwait(h)  
    
    set(hFig, 'Pointer', 'arrow' );
    
end

%----------------------------------------------------------------------
function  sub_save(~,~,hObject)

try
   
    st = get(hObject,'userdata');
    
    sBaseFile = st.resistivityFile; %strtrim(get(findobj(st.hFigure,'tag','filenameroot'),'string'));
       
    
    str = '';
    if ~isempty(sBaseFile)
        str = sprintf('%s.fig',sBaseFile);
    end
    [file, path ] = uiputfile('*.fig',' Save plotMARE2DEM figure as',str);
    if file==0
        return
    end
    
    set(hObject, 'Pointer', 'watch' ); drawnow;
 
    % Remove listeners:
    sub_removeListeners(hObject);
       
    setappdata(hObject,'bChanged',false);
    setappdata(hObject,'bClosed',true);
    sFile = fullfile(path,file);
    savefig(hObject,sFile);

    % Add listeners back to currently open figure:
    sub_addListeners(hObject);
    
    % Display message:
    h = helpdlg(sprintf('Done writing plotMARE2DEM figure file: \n %s', file),'plotMARE2DEM Message:');
    set(h,'windowstyle','modal');
    uiwait(h)
 
    set(hObject, 'Pointer', 'arrow' );
    
    set(hObject,'userdata',st);
    

catch Me

    echo off;

    waitfor( errordlg( {
        'Error writing plotMARE2DEM files!'
        ' '
        Me.identifier
        Me.message
        } ) );
        
end

    
end


%--------------------------------------------------------------------------    
function st = sub_getDefaults()

% Set a few defaults. These will be overridden by user's MRU

st.colorScaleResistivity 	= 'log10'; % log10 or linear 
st.colorScaleRatio          = 'log10'; % log10 or linear
st.colorScaleSensitivity    = 'log10'; % log10 or linear
st.colorScaleIP             = 'linear'; % log10 or linear

st.colorScaleLimitsResistivity = [0.1 10000];
st.colorScaleLimitsRatio       = [0.1 10];
st.colorScaleLimitsSensitivity = [1d-5 1];
st.colorScaleLimitsIP          = [0.01 2];


st.showSensContours             = 'off';
st.showSensContourLabels        = 'off';
st.sensitivityContourColor     = 'w';
st.sensitivityContourLineWidth = 0.5;
st.sensitivityContourInterval  = -10:.5:10;

st.transparencyAlpha          = 0.3;
st.sensitivityAlphaLowLimit   = log10(1d-3);

st.showResContours             = 'off';
st.showResContourLabels        = 'off';
st.resistivityContourColor     = 'w';
st.resistivityContourLineWidth = 0.5;
st.resistivityContourInterval = -10:.5:10; 
 

st.showParamBoundaries    = 'off';
st.paramBoundaryColor     = 'k';
st.paramBoundaryLineWidth = 0.5;

st.polygonFileColor     = 'k';
st.polygonFileLineWidth = 1;

st.lineFileColor        = 'k';
st.lineFileLineWidth    = 1;

st.femeshColor          = 'k';
st.femeshLineWidth      = 1;


% Well log point data overlays:
st.pointDataMarker           = 's';
st.pointDataMarkerEdgeColor  = 'k';
st.pointDataMarkerSize       = 5^2;  % pts^2
st.showPointDataNames        = 'on';

% Well log line style:
st.wellLogColor        = 'k';
st.wellLogLineWidth    = 1;
st.showWellLogNames    = 'on';

st.showInterpolated     = 'off';
st.showFixed            = 'on'; % please leave this default as 'on' so that novices will see when they make seawater and air the wrong resistivity
st.showFree             = 'on';
st.showUTM              = 'off';
st.showTitle            = 'on';

st.usekm               = 'off'; %  turn on to use km for units rather than meter
st.reverseX            = 'off'; % for flippling axis directions
st.reverseY            = 'off';
st.equalAspect         = 'off'; 

% Color Maps:
st.sResistivityColorMap = 'turbo';  % Google's better version of jet that doens't have luminance spikes.
                                    % https://ai.googleblog.com/2019/08/turbo-improved-rainbow-colormap-for.html  
st.sResistivityInverted = false;  % set to true to flipud(colormap)
st.sSensitivityColorMap = 'parula';   
st.sSensitivityInverted = false;  % set to true to flipud(colormap)
st.sRatioColorMap       = 'd1';  
st.sRatioInverted       = false;  % set to true to flipud(colormap)
st.sIPColorMap          = 'parula';   
st.sIPInverted          = false;  % set to true to flipud(colormap)
st.fontSize             = 14;

% Rx and Tx:
st.showRxCSEM             = 'on';
st.showRxMT               = 'on';
st.showTx                 = 'on';
st.showDC                 = 'on';
st.markerRxCSEM           = 'd';
st.markerRxMT             = 'v';
st.markerTx               = 'o';
st.markerDC               = 'o';
st.markersizeRxCSEM       = 6;
st.markersizeRxMT         = 9;
st.markersizeTx           = 6;
st.markersizeDC           = 6;
st.markerFaceColorRxCSEM  = 'w';
st.markerFaceColorRxMT    = 'w';
st.markerFaceColorTx      = 'w';
st.markerFaceColorDC      = 'w';
st.markerEdgeColorRxCSEM  = 'k';
st.markerEdgeColorRxMT    = 'k';
st.markerEdgeColorTx      = 'k';
st.markerEdgeColorDC      = 'k';
st.showNameRxCSEM         = 'off';
st.showNameRxMT           = 'off';
st.showNameTx             = 'off';
st.fontsizeRxCSEM         = 12;
st.fontsizeRxMT           = 12;
st.fontsizeTx             = 12;
st.fontcolorRxCSEM        = 'w';
st.fontcolorRxMT          = 'w';
st.fontcolorTx            = 'w';

 
% Set figure position based on currently attached displays:
[nMon] = m2d_getMonitorPosition();
nSizeMax = [1800 1200];
nSize(1) = min([nMon(1,3),nSizeMax(1)]);
nSize(2) = min([nMon(1,4),nSizeMax(2)]);
nPos = [nMon(1,1) nMon(1,2)+nMon(1,4) nSize]; 
nPos(2) = nPos(2) - nPos(4);
st.figureOuterPosition = nPos;

end

%--------------------------------------------------------------------------
function sub_resetToDefaults(~,~,hFig)
    
    % Delete existing MRU file:
    [p, f] = fileparts( mfilename('fullpath') );
    sMRU = fullfile( p, [f '.mru'] );
    delete(sMRU);
    
    delete(findobj(hFig,'tag','csemRxNames'))
    delete(findobj(hFig,'tag','txNames'))
    delete(findobj(hFig,'tag','mtRxNames'))
    
    st          = get(hFig,'Userdata');
    
    stSettings  = sub_getDefaults();   
   
    % Store in figure:
    setappdata(hFig,'stSettings',stSettings);
    setappdata(hFig,'bChanged',true);

    % save new settings:
    sub_saveMRU(stSettings,hFig);
    
    % Redraw figure:
    drawFigure(hFig);
    hFig.OuterPosition = stSettings.figureOuterPosition;
    
    
end

%----------------------------------------------------------------------
function sub_saveMRU(stSettings,hFig)

    % Make the name of the mat file that holds the MRU
    [p, f] = fileparts( mfilename('fullpath') );
    sMRU = fullfile( p, [f '.mru'] );
    
    save(sMRU, '-mat', 'stSettings');
    
    setappdata(hFig,'bChanged',true);
 
end

%--------------------------------------------------------------------------
function st = sub_getMRU(st)

    % Make the name of the mat file that holds the MRU
    [p, f] = fileparts( mfilename('fullpath') );
    sMRU = fullfile( p, [f '.mru'] );
    
    % If it exists, load it
    if exist( sMRU, 'file' )
        a = load( sMRU, '-mat');
        if ~isempty(a) && isfield(a,'stSettings') && ~isfield(a.stSettings,'lh1') %kwk debug
             % copy a struct to st struct
            names = fieldnames(a.stSettings);
            for i = 1:length(names)
                st.(names{i}) = a.stSettings.(names{i});
            end
        end

     end
    
    
% Catch here for old removed colormap:
if strcmpi(st.sResistivityColorMap,'anomaly')
    st.sResistivityColorMap = 'd1';
end
if strcmpi(st.sSensitivityColorMap,'anomaly')
    st.sSensitivityColorMap = 'd1';
end
if strcmpi(st.sRatioColorMap,'anomaly')
    st.sRatioColorMap = 'd1';
end
if strcmpi(st.sIPColorMap,'anomaly')
    st.sIPColorMap = 'd1';
end    

if islogical(st.showParamBoundaries)  % tweak for OLD setting logical
    st.showParamBoundaries = 'off';
    if st.showParamBoundaries
        st.showParamBoundaries = 'on';
    end
end

end
%--------------------------------------------------------------------------
function drawFigure(hFig,varargin)

st          = get(hFig,'Userdata');
stSettings  = getappdata(hFig,'stSettings');
 
hold(st.axes,'on')

set(st.axes,'fontsize',stSettings.fontSize);

set(st.axes,'color',[.7 .7 .7]) % neutral gray background color on axes
box on;
 
if strcmpi(stSettings.reverseX,'on')
    set(st.axes,'xdir','reverse');
else
    set(st.axes,'xdir','normal');
end
if strcmpi(stSettings.reverseY,'on')
    set(st.axes,'ydir','normal');   
else
    set(st.axes,'ydir','reverse');   % here reverse is normal since that's z positive down
end
set(st.axes,'tickdir','out','TickLength',[0.005 0.005])



if nargin() == 3
    xlim = varargin{1};
    ylim = varargin{2};
    %set(st.axes,'XLimMode','manual','YLimMode','manual')
    set(st.axes,'xlim',xlim); %,'ylim',ylim);
%    da = daspect(st.axes);
%     if all(da == 1)
%         pb = pbaspect(st.axes);
%         factor =  norm(xlim)/norm(ylim)*pb(2)/pb(1);
%         set(st.axes,'ylim',ylim*factor);
%     else
        set(st.axes,'ylim',ylim);
%     end
   
end
 
if strcmpi(stSettings.usekm,'on')
    str = 'Depth (km)';
else
    str = 'Depth (m)';
end
h = ylabel(st.axes,str);
set(h,'tag','text','handlevisibility','on','fontsize',stSettings.fontSize)


% Plot resistivity:
plotRhoXYZ([],[],hFig);

%
% Drop down menus for selecting which anisotropy to plot, segments,
% receivers, transmitters, etc...
%
sub_setUImenus([],[],hFig);

% Plot segments:
% note this is much faster than the naive way since it only 
% creates a single graphics handle, rather than one per segment.

delete(findobj(hFig,'tag','segments'));

x = st.TR.Points(:,1);
y = st.TR.Points(:,2);
X = [x(st.segs(:,1:2))  nan(size(st.segs,1),1)]';
Y = [y(st.segs(:,1:2))  nan(size(st.segs,1),1)]';
hSegs = plot(st.axes,X(:),Y(:),'-','linewidth',stSettings.paramBoundaryLineWidth,...
                           'color',stSettings.paramBoundaryColor,'tag','segments','visible',stSettings.showParamBoundaries);

delete(findobj(hFig,'tag','csemsites'));
delete(findobj(hFig,'tag','mtsites'));
delete(findobj(hFig,'tag','transmitters'));

% Plot sites:
if ~isempty(st.stCSEM) && isfield(st.stCSEM,'receivers')
    hRx = plot(st.axes,st.stCSEM.receivers(:,2),st.stCSEM.receivers(:,3),...
        'linestyle','none',...
        'marker',stSettings.markerRxCSEM,...
        'markersize',stSettings.markersizeRxCSEM,...
        'markerfacecolor',stSettings.markerFaceColorRxCSEM,...
        'markeredgecolor',stSettings.markerEdgeColorRxCSEM,...
        'tag','csemsites','visible',stSettings.showRxCSEM);
    
    set(findobj(hFig,'tag','showRxCSEM'),'checked',stSettings.showRxCSEM);
     
end
if ~isempty(st.stMT) && isfield(st.stMT,'receivers')
    hRx = plot(st.axes,st.stMT.receivers(:,2),st.stMT.receivers(:,3),...
        'linestyle','none',...
        'marker',stSettings.markerRxMT,...
        'markersize',stSettings.markersizeRxMT,...
        'markerfacecolor',stSettings.markerFaceColorRxMT,...
        'markeredgecolor',stSettings.markerEdgeColorRxMT,...
        'tag','mtsites','visible',stSettings.showRxMT);
        
    set(findobj(hFig,'tag','showRxMT'),'checked',stSettings.showRxMT);
end

 
% Plot transmitters:
if ~isempty( st.stCSEM) && isfield(st.stCSEM,'transmitters')
    hTx = plot(st.axes, st.stCSEM.transmitters(:,2), st.stCSEM.transmitters(:,3),...
        'linestyle','none',...
        'marker',stSettings.markerTx,...
        'markersize',stSettings.markersizeTx,...
        'markerfacecolor',stSettings.markerFaceColorTx,...
        'markeredgecolor',stSettings.markerEdgeColorTx,...
        'tag','transmitters','visible',stSettings.showTx);
    
    set(findobj(hFig,'tag','showTx'),'checked','on','checked',stSettings.showTx);
end

% Plot DC electrodes:
if ~isempty( st.stDC) && isfield(st.stDC,'rx_electrodes') && isfield(st.stDC,'tx_electrodes')
    tt = [st.stDC.rx_electrodes(:,2) st.stDC.rx_electrodes(:,3); st.stDC.tx_electrodes(:,2) st.stDC.tx_electrodes(:,3)];
    tt = unique(tt,'rows');
    hTrodes = plot(st.axes, tt(:,1), tt(:,2),...
        'linestyle','none',...
        'marker',stSettings.markerDC,...
        'markersize',stSettings.markersizeDC,...
        'markerfacecolor',stSettings.markerFaceColorDC,...
        'markeredgecolor',stSettings.markerEdgeColorDC,...
        'tag','dc_electrodes','visible',stSettings.showDC);
    
    set(findobj(hFig,'tag','showDC'),'checked','on','checked',stSettings.showDC);
end

zoom_updateAxes([],[]);

sub_uistack(hFig);

end % drawFigure
%--------------------------------------------------------------------------
function inView = getTrianglesInCurrentView(st)

y = st.TR.Points(:,1);
z = st.TR.Points(:,2);
Y = y(st.TR.ConnectivityList);
Z = z(st.TR.ConnectivityList);

inView = max(Y,[],2) >= st.axes.XLim(1) & ... % rightmost point is to right of left axis limit
         min(Y,[],2) <= st.axes.XLim(2) & ... % leftmost point is to left of right axis limit
         max(Z,[],2) >= st.axes.YLim(1) & ... % top point is to above bottom axis limit
         min(Z,[],2) <= st.axes.YLim(2);      % bottom most point is below top axis


end
 
    
%--------------------------------------------------------------------------
function [st,stSettings] = getAutoColorScale(st,stSettings)

% Limit colorscale to be the minimum of all values, ignoring values greater
% than 10^8 (which is likely the air layer)

    if strcmpi(stSettings.showFree,'on') && strcmpi(stSettings.showFixed,'on')
        iUse = st.freeparameter >= 0;
    elseif strcmpi(stSettings.showFree,'on') && ~strcmpi(stSettings.showFixed,'on')
        iUse = st.freeparameter > 0;
    elseif strcmpi(stSettings.showFree,'off') && ~strcmpi(stSettings.showFixed,'on')
        iUse = st.freeparameter == 0;
    else
        return
    end

   
    
    % Get unique list of regions that are in view (unique since a region can be composed of many triangles)    
    inView = getTrianglesInCurrentView(st);
    inView = unique(st.TriIndex(inView));
    
    lView = zeros(size(st.freeparameter,1),1);
    lView(inView) = true;
    
   % iUse = iUse(:,st.icmp) & lView;
    
 
if ~strcmpi(st.anisotropy,'isotropic_ip') && ~strcmpi(st.anisotropy,'isotropic_complex') && any(st.resistivity(:) <= 0)
    
    % DGM Aug 2013 - the data are log10 difference, not resistivity
%     if any(iFree(:))
%         cmin = min(min(st.resistivity(iFree)));
%         cmax = max(max(st.resistivity(iFree)));
%     else
        iUse = iUse & lView;
        cmin = min(st.resistivity(iUse));
        cmax = max(st.resistivity(iUse));
    %end
    ca = [-1 1] * max(abs(cmin),abs(cmax));
    
else
    
   
        
    if st.plotSensitivity
        
        iUse = st.freeparameter(:,st.icmp) > 0;
        iUse = iUse & lView;
        
        iparamnum =  st.freeparameter(iUse,st.icmp) ; 
        
        sens = st.sensitivity(iparamnum);        
        cmin = min(sens);
        cmax = max(sens);

    else
        
        if st.icmp <= st.nNonRatio  % not a ratio plot
            iUse = iUse(:,st.icmp) & lView;
            
            rho = st.resistivity(iUse,st.icmp);
            cmin = min(rho);
            cmax = max(rho);
            
            % Check for air which should be > 10^8, if cmax is air, then remove it:
            if cmax > 1d8
                cmax = max(rho(rho~=cmax)); 
            end
            
        else % ratio plot:
            
            [i1, i2] = getAnisotropicRatioComps(st);
            iUse = iUse(:,i1) | iUse(:,i2) & lView;  % if either parameter is free use both
            cc = st.resistivity(iUse,i1)'./st.resistivity(iUse,i2)';

            cmin = min((cc));
            cmax = max((cc));         
            
        end
    end
    
     ca = [cmin cmax];

end
 
% Check for small range:
tol = 0.5;
if abs(diff(log10(ca))) < tol && ~st.plotSensitivity
    ca = 10.^[log10(ca(1))-tol log10(ca(2))+tol];
end

if st.icmp <= st.nNonRatio
    if st.plotSensitivity
        stSettings.colorScaleLimitsSensitivity = ca;
        
    elseif strcmpi(st.anisotropy,'isotropic_ip') && st.icmp > 1 % eta, tau or c
        stSettings.colorScaleLimitsIP = ca; 
    else
        stSettings.colorScaleLimitsResistivity = ca;
    end
else % ratio plot
    stSettings.colorScaleLimitsRatio = ca;
end    

end
%--------------------------------------------------------------------------
function sub_setUImenus(~,~,hFig)
 

st        = get(hFig,'Userdata');
stSettings  = getappdata(hFig,'stSettings');

% Delete any existing menus:
delete(findobj(hFig,'type','uimenu'));


%-----------------%
% File menu %
%-----------------%
% Create the menu
hMenu = uimenu( hFig, 'Label', '&File' ,'position',1);
 
uimenu( hMenu, 'Label', '&Save .fig...', 'Callback', {@sub_save, hFig},'accelerator','s' );
%---
uimenu( hMenu, 'Label', '&Print image to file...', 'Callback', {@sub_print, hFig}, 'Separator', 'on','accelerator','p');
%---
uimenu( hMenu, 'Label', 'E&xit', 'Callback', {@sub_Close, hFig}, 'Separator', 'on','accelerator','w' );

%-----------------%
% Iterations menu %
%-----------------%
uimenu(hFig,'Label','Iterations','tag','itermenu','callback',{@IterationMenuDrop, hFig});

%-----------%
% Response menu %
%-----------%
m2 =  uimenu(hFig,'Label','Responses','callback',{@ResponseMenuDrop, hFig},'tag','responsemenu');

%------------------%
% Resistivity menu %
%------------------%
m3 =  uimenu(hFig,'Label','Resistivity'); 
for i = 1:length(st.cmps)
    schk = 'off';
    if i == st.icmp
        schk = 'on';
    end
    uimenu(m3,'Label',st.cmps{i},'callback', {@chgComponent, hFig,i},'tag','rho_cmps','checked',schk);
end

%-----------------%
% Appearance Menu %
%-----------------%
m4 =  uimenu(hFig,'Label','Appearance');

%Colormap control:
mCm = uimenu('Parent',m4,'Label','Colormap ');
uimenu(mCm,'Label','Invert Colormap','callback', {@sub_setColorMap, hFig,'invert'},'tag','uimenu_cm');

cColorMapList = m2d_colormaps('list_all');
[cCategories,~,ic] = unique(cColorMapList(:,3));
for iCat = 1:length(cCategories)
    str  = cCategories{iCat,1};
    hCat = uimenu(mCm,'Label',str ); 
    icc = find(ic == iCat);
    for j = 1:length(icc)
       uimenu(hCat,'Label',cColorMapList{icc(j),1},   'callback', {@sub_setColorMap, hFig,cColorMapList{icc(j),1}} ,'tag','uimenu_cm');  
    end
    
end
uimenu(mCm,'Label','Display All Colormaps','callback', {@sub_display_colormaps}, 'separator', 'on');

 

% Color Scale:
mCs = uimenu('Parent',m4,'Label','Color Scale');
uimenu('Parent',mCs,'Label','Automatic (using current view)', 'callback', {@setColorScaleAutoLimits,hFig} );
uimenu('Parent',mCs,'Label','Manual Limits',    'callback', {@setColorScaleManualLimits,hFig} );
uimenu('Parent',mCs,'Label','Log10',            'callback', {@setLinearOrLog10Scaling, hFig, 'Log10'}, 'separator', 'on' );
uimenu('Parent',mCs,'Label','Linear',           'callback', {@setLinearOrLog10Scaling, hFig, 'Linear'} );

% Axes control:
m10 = uimenu('Parent',m4,'Label','Axis');
uimenu(m10,'Label','Zoom to Survey Region',   'callback', {@sub_setAxisScale_Callback, hFig, 'zoomToSurvey'} );
uimenu(m10,'Label','Show Entire Model',       'callback', {@sub_setAxisScale_Callback, hFig, 'entireModel'} );
uimenu(m10,'Label','Equal Aspect Ratio',      'callback', {@sub_setAxisScale_Callback, hFig, 'equal'} ,'checked',stSettings.equalAspect);
uimenu(m10,'Label','Reverse Horizontal Axis', 'callback', {@sub_setAxisDirection, hFig, 'reverseX'},'checked',stSettings.reverseX);
uimenu(m10,'Label','Reverse Vertical Axis',   'callback', {@sub_setAxisDirection, hFig, 'reverseY'},'checked',stSettings.reverseY);

% Parameter settings:
mPm = uimenu('Parent',m4,'Label','Parameters');
uimenu('Parent',mPm,'Label','Interpolated Parameter Shading','tag','showInterpolated',...
       'callback', {@chgShading, hFig} ,'checked',stSettings.showInterpolated);
uimenu('Parent',mPm,'tag','showFixed','Label','Show Fixed Parameters','callback',  {@chgRgnVis, hFig, 'fixed'}, 'checked',stSettings.showFixed);
uimenu('Parent',mPm,'tag','showFree', 'Label','Show Free Parameters', 'callback',  {@chgRgnVis, hFig, 'free'} , 'checked',stSettings.showFree );

% Segments:
uimenu(mPm,'Label','Show Boundaries','tag','showParamBoundaries','callback', {@chgVisCheck, hFig, 'segments'},'checked',stSettings.showParamBoundaries);
uimenu(mPm,'Label','Line Thickness','callback', {@setFigProperty, hFig,'segments','paramBoundaryLineWidth','linewidth'});     
m41a = uimenu(mPm,'Label','Line Color');
sub_addColorSubMenus(m41a,hFig,'paramBoundaryColor','segments','color');

% Resistivity contours:
m41 = uimenu(m4, 'Label','Resistivity Contours' );
uimenu(m41, 'Label','Overlay Contours', 'tag','showResContours',            'callback', {@plotResContours, hFig}  ,'checked',stSettings.showResContours);
uimenu(m41, 'Label','Contour Inverval', 'tag','resistivityContourInterval', 'callback', {@setResistivityContours, hFig});
uimenu(m41, 'Label','Contour Labels',   'tag','showResContourLabels',       'callback', {@showContourLabels, hFig,'showResContourLabels'},  'checked',stSettings.showResContourLabels);     
uimenu(m41, 'Label','Line Thickness','callback', {@setFigProperty, hFig,'ResistivityContours','resistivityContourLineWidth','linewidth'}); 
m41a = uimenu(m41,'Label','Line Color');
sub_addColorSubMenus(m41a,hFig,'resistivityContourColor','ResistivityContours','color');

% Receivers:
sep = 'on';
if ~isempty(st.stCSEM) && isfield(st.stCSEM,'receivers')
    
    m1 = uimenu(m4,'Label','CSEM Receivers','separator',sep);
    sep = 'off';
    uimenu(m1,'Label','Show Markers',  'tag','showRxCSEM',     'callback', {@chgVisCheck, hFig, 'csemsites'} ,'checked',stSettings.showRxCSEM);
    uimenu(m1,'Label','Show Names',    'tag','showNameRxCSEM', 'callback', {@showNames,   hFig, 'csemRxNames'} );
    m2 = uimenu(m1,'Label','Marker');   
    sub_addMarkerSubMenus(m2,hFig,'markerRxCSEM','csemsites','marker');
    m2 = uimenu(m1,'Label','Marker Color'  ); 
    sub_addColorSubMenus(m2,hFig,'markerFaceColorRxCSEM','csemsites','markerfacecolor');
    uimenu(m1,'Label','Marker Size', 'callback', {@setFigProperty, hFig, 'csemsites','markersizeRxCSEM','markersize'} );
    m2 = uimenu(m1,'Label','Text Orientation'  ); 
    uimenu(m2,'Label','Horizontal', 'callback', {@chgTxtRotHorz, hFig, 'csemRxNames'} );
    uimenu(m2,'Label','Vertical',   'callback', {@chgTxtRotVert, hFig, 'csemRxNames'} );
    m2 = uimenu(m1,'Label','Font Color'  ); 
    sub_addColorSubMenus(m2,hFig,'fontcolorRxCSEM','csemRxNames','color');
    uimenu('Parent',m1,'Label','Font Size', 'callback', {@setFontSizeRxTx, hFig,'fontsizeRxCSEM','csemRxNames'});
end


if ~isempty(st.stMT) && isfield(st.stMT,'receivers')
    m1 = uimenu(m4,'Label','MT Receivers','separator',sep);
    sep = 'off';
    uimenu(m1,'Label','Show Markers',  'tag','showRxMT',     'callback', {@chgVisCheck, hFig, 'mtsites'} ,'checked',stSettings.showRxMT);
    uimenu(m1,'Label','Show Names',    'tag','showNameRxMT', 'callback', {@showNames,   hFig, 'mtRxNames'} );
    m2 = uimenu(m1,'Label','Marker');   
    sub_addMarkerSubMenus(m2,hFig,'markerRxMT','mtsites','marker');
    m2 = uimenu(m1,'Label','Marker Color'  ); 
    sub_addColorSubMenus(m2,hFig,'markerFaceColorRxMT','mtsites','markerfacecolor');
    uimenu(m1,'Label','Marker Size', 'callback', {@setFigProperty, hFig, 'mtsites','markersizeRxMT','markersize'} );
    m2 = uimenu(m1,'Label','Text Orientation'  ); 
    uimenu(m2,'Label','Horizontal', 'callback', {@chgTxtRotHorz, hFig, 'mtRxNames'} );
    uimenu(m2,'Label','Vertical',   'callback', {@chgTxtRotVert, hFig, 'mtRxNames'} );
    m2 = uimenu(m1,'Label','Font Color'  ); 
    sub_addColorSubMenus(m2,hFig,'fontcolorRxMT','mtRxNames','color');
    uimenu('Parent',m1,'Label','Font Size', 'callback', {@setFontSizeRxTx, hFig,'fontsizeRxMT','mtRxNames'});
end

% Transmitters:
if ~isempty(st.stCSEM) && isfield(st.stCSEM,'transmitters')
    m1 = uimenu('Parent',m4,'Label','Transmitters','separator',sep);
    sep = 'off';
    uimenu(m1,'Label','Show Markers', 'tag','showTx',     'callback', {@chgVisCheck, hFig, 'transmitters'},'checked',stSettings.showTx );
    uimenu(m1,'Label','Show Names','tag','showNameTx', 'callback', {@showNames,   hFig, 'txNames'} );
    m2 = uimenu(m1,'Label','Marker');   
    sub_addMarkerSubMenus(m2,hFig,'markerTx','transmitters','marker');
    m2 = uimenu(m1,'Label','Marker Color'  ); 
    sub_addColorSubMenus(m2,hFig,'markerFaceColorTx','transmitters','markerfacecolor');
    uimenu(m1,'Label','Marker Size', 'callback', {@setFigProperty, hFig, 'transmitters','markersizeTx','markersize'} );
    m2 = uimenu(m1,'Label','Text Orientation'  ); 
    uimenu(m2,'Label','Horizontal', 'callback', {@chgTxtRotHorz, hFig, 'txNames'} );
    uimenu(m2,'Label','Vertical',   'callback', {@chgTxtRotVert, hFig, 'txNames'} );
    m2 = uimenu(m1,'Label','Font Color'  ); 
    sub_addColorSubMenus(m2,hFig,'fontcolorTx','txNames','color');
    uimenu('Parent',m1,'Label','Font Size', 'callback', {@setFontSizeRxTx, hFig,'fontsizeTx','txNames'});
end

% DC electrodes:
if ~isempty(st.stDC) && isfield(st.stDC,'tx_electrodes')
    m1 = uimenu('Parent',m4,'Label','DC electodes','separator',sep);
    sep = 'off';
    uimenu(m1,'Label','Show Markers', 'tag','showDC',     'callback', {@chgVisCheck, hFig, 'dc_electrodes'},'checked',stSettings.showDC );
    %uimenu(m1,'Label','Show Names','tag','showNameTx', 'callback', {@showNames,   hFig, 'txNames'} );
    m2 = uimenu(m1,'Label','Marker');   
    sub_addMarkerSubMenus(m2,hFig,'markerDC','dc_electrodes','marker');
    m2 = uimenu(m1,'Label','Marker Color'); 
    sub_addColorSubMenus(m2,hFig,'markerFaceColorDC','dc_electrodes','markerfacecolor');
    uimenu(m1,'Label','Marker Size', 'callback', {@setFigProperty, hFig, 'dc_electrodes','markersizeDC','markersize'} );
%     m2 = uimenu(m1,'Label','Text Orientation'  ); 
%     uimenu(m2,'Label','Horizontal', 'callback', {@chgTxtRotHorz, hFig, 'txNames'} );
%     uimenu(m2,'Label','Vertical',   'callback', {@chgTxtRotVert, hFig, 'txNames'} );
%     m2 = uimenu(m1,'Label','Font Color'  ); 
%     sub_addColorSubMenus(m2,hFig,'fontcolorTx','txNames','color');
%     uimenu('Parent',m1,'Label','Font Size', 'callback', {@setFontSizeRxTx, hFig,'fontsizeTx','txNames'});
end

% Title:
m41 = uimenu('Parent',m4,'tag','showTitle','Label','Show Title','separator','on', 'callback',  {@chgShowTitle, hFig, 'figtitle'},'checked',stSettings.showTitle );

% UTM:
m41 = uimenu('Parent',m4,'tag','showUTM','Label','Show UTM Labels','callback',  {@chgShowUTM, hFig},'checked',stSettings.showUTM);

%Position units:
uimenu('Parent',m4,'Label','Use kilometers', 'callback', {@sub_setUnits, hFig},'tag','units_menu',  'checked',stSettings.usekm);
         
% Grid
uimenu('Parent',m4,'Label','Grid Lines', 'callback',{@sub_gridLines, hFig});

% Font size:
uimenu('Parent',m4,'Label','Font Size', 'callback', {@setFontSize, hFig});
 
% Developer relevant stuff:
m40b =  uimenu('Parent',m4,'Label','Developer');
% Penalty matrix:
%uimenu('Parent',m40b,'Label','Roughness Penalties','tag','plotPenaltiesBtn','callback',  {@plotPenalties, hFig} );
% Parameter and region numbering:
uimenu('Parent',m40b,'Label','Region Numbers',   'callback',  {@plotRegionNums, hFig});
uimenu('Parent',m40b,'Label','Parameter Numbers','callback',  {@plotParamNums, hFig} );

m40c =  uimenu('Parent',m40b,'Label','FE Mesh Utils');
uimenu('Parent',m40c,'Label','Overlay FE mesh','callback',    {@sub_plotFEmesh, hFig} );
uimenu('Parent',m40c,'Label','Remove FE mesh','callback',    {@sub_removeFEmesh, hFig} );
uimenu(m40c,'Label','Line Thickness','callback', {@setFigProperty, hFig,'femesh','femeshLineWidth','linewidth'});     
ms = uimenu(m40c,'Label','Line Color');
sub_addColorSubMenus(ms,hFig,'femeshColor','femesh','color');

% could add here:
    % refinement movie option 
    % error estimator plots etc

% Reset to Defaults
uimenu('Parent',m4,'Label','Reset to MARE2DEM defaults','callback', {@sub_resetToDefaults, hFig}, 'separator', 'on'  );



%-------------%
% Overlay menu % (i.e. poly files, lines...)
%-------------%
m5 = uimenu(hFig,'Label','Overlay','callback',{@SensitivityMenuDrop, hFig});

% Sensitivity from Jacobian

% Sensivity:
m41 = uimenu(m5, 'Label','Sensitivity Contours');
uimenu(m41, 'Label','Overlay Contours', 'tag','showSensContours', 'callback', {@plotSensitivityContours, hFig},'checked',stSettings.showSensContours );

uimenu(m41, 'Label','Contour Inverval', 'callback', {@setSensitivityContours, hFig});
uimenu(m41, 'Label','Contour Labels','tag','showSensContourLabels','callback', {@showContourLabels, hFig,'showSensContourLabels'}, 'checked',stSettings.showSensContourLabels);     
uimenu(m41,'Label','Line Thickness','callback', {@setFigProperty, hFig,'SensitivityContours','sensitivityContourLineWidth','linewidth'});     

m41a = uimenu(m41,'Label','Line Color');
sub_addColorSubMenus(m41a,hFig,'sensitivityContourColor','SensitivityContours','color');

m41b = uimenu(m5, 'Label','Transparency Map');
uimenu(m41b, 'Label','Overlay Transparency Map', 'tag','plotSensitivityAlpha',  'callback', {@plotSensitivityAlpha, hFig} );
uimenu(m41b, 'Label','Transparency Alpha', 'callback', {@transparencyAlpha, hFig} ...
          , 'tag', 'transparencyAlpha' );  
uimenu(m41b, 'Label','Sensitivity Lower Limit for Transparency', 'callback', {@sensitivityLowerLimit, hFig} ...
          , 'tag', 'sensitivityLowerLimit' );   
      
      
% This is no longer needed since we can set the transparency alpha to 0 to do the same thing:      
uimenu(m5, 'Label','Plot histogram of log10(Sensitivity)', 'callback', {@plotSensitivityHistogram, hFig} );


uimenu(m5,'Label','Plot Jacobian Sensitivity (from MARE2DEM -S)','tag','sensitivitymenu');
uimenu(m5,'Label','Plot Full Jacobian (from MARE2DEM -J)','callback', {@plotWJ, hFig} ); 
 
%initialize sensitivity drop down:
SensitivityMenuDrop([],[],hFig);


% Poly file:
m5p = uimenu(m5,'Label','PSLG (.poly) File' , 'separator', 'on' );
uimenu(m5p,'Label','Load File',         'callback', {@plotPolygons, hFig} );
uimenu(m5p,'Label','Line Thickness','callback', {@setFigProperty, hFig,'polygons','polygonFileLineWidth','linewidth'});     
m5pp = uimenu(m5p,'Label','Line Color');
sub_addColorSubMenus(m5pp,hFig,'polygonFileColor','polygons','color');
uimenu(m5p,'Label','Remove Polygons',   'callback', {@delByTag, hFig, 'polygons'} );

m5p = uimenu(m5,'Label','Line File','separator', 'on' );
uimenu(m5p,'Label','Load File(s)', 'callback', {@plotLines, hFig}  );
uimenu(m5p,'Label','Remove line(s)','callback', {@delByTag, hFig, 'lines'} );
uimenu(m5p,'Label','Line Thickness','callback', {@setFigProperty, hFig,'lines','lineFileLineWidth','linewidth'});     
m5pp = uimenu(m5p,'Label','Line Color');
sub_addColorSubMenus(m5pp,hFig,'lineFileColor','lines','color');
 
% Seismic Seg Y (depth migrated):
uimenu(m5,'Label','Seismic SEG Y','callback', {@importSEGY, hFig}, 'separator', 'on' );
uimenu(m5,'Label','Rescale SEG Y','callback', {@rescaleSEGY, hFig,[]});
uimenu(m5,'Label','Remove SEG Y', 'callback', {@delByTag, hFig, 'segy'} );

% Geo-image (DGM 5/4/2015 - largely copied from Mamba2D)
uimenu(m5,'Label','Load Geo-image','callback', {@importGeoImage, hFig}, 'separator', 'on' );
uimenu(m5,'Label','Show/Hide Geo-image transparency control','callback', {@showGeoTransp, hFig});
uimenu(m5,'Label','Remove Geo-image', 'callback', {@delByTag, hFig, 'geoimage'} );

% Well Logs as Point Data  
m5p = uimenu(m5,'Label','Well Log (colored marker style)', 'separator', 'on' );
uimenu(m5p,'Label','Load Data','callback', {@importPointData, hFig}  );  %  (<easting,northing,depth,value>)
uimenu(m5p,'Label','Remove Data','callback', {@delPointData, hFig} );
uimenu(m5p,'Label','Show Names','tag','showPointDataNames', 'callback', {@chgVisCheck,   hFig, 'pointdataname'},'checked',stSettings.showPointDataNames );
m5pm = uimenu(m5p,'Label','Marker');   
sub_addMarkerSubMenus(m5pm,hFig,'pointDataMarker','pointdata','marker');
uimenu(m5p,'Label','Marker Size','callback', {@setFigProperty, hFig,'pointdata','pointDataMarkerSize','sizedata'});     
m5p2 = uimenu(m5p,'Label','Marker Edge Color');  
uimenu(m5p2,'Label','black','callback', {@recolorByTag, hFig, 'pointDataMarkerEdgeColor','pointdata', 'markeredgecolor', 'k'} );  
uimenu(m5p2,'Label','white','callback', {@recolorByTag, hFig, 'pointDataMarkerEdgeColor','pointdata', 'markeredgecolor', 'w'} );  
uimenu(m5p2,'Label','none', 'callback', {@recolorByTag, hFig, 'pointDataMarkerEdgeColor','pointdata', 'markeredgecolor', 'none'} );  
 
mCm = uimenu('Parent',m5p,'Label','Colormap');
uimenu(mCm,'Label','Invert Colormap','callback', {@sub_setColorMapPointData, hFig,'invert'},'tag','uimenu_cm_pointdata');

cColorMapList = m2d_colormaps('list_all');
[cCategories,~,ic] = unique(cColorMapList(:,3));
for iCat = 1:length(cCategories)
    str  = cCategories{iCat,1};
    hCat = uimenu(mCm,'Label',str ); 
    icc = find(ic == iCat);
    for j = 1:length(icc)
       uimenu(hCat,'Label',cColorMapList{icc(j),1},   'callback', {@sub_setColorMapPointData, hFig,cColorMapList{icc(j),1}} ,'tag','uimenu_cm_pointdata');  
    end
    
end
uimenu(m5p,'Label','Color Scale ',  'callback', {@sub_setColorScalePointData,hFig} );
uimenu(m5p,'Label','Colorbar Title','callback', {@sub_setTitlePointData,hFig} );
uimenu(m5p,'Label','Colorbar Units','callback', {@sub_setUnitsPointData,hFig} );

% Well Logs as Lines:
mwlp = uimenu(m5,'Label','Well Log (line style)', 'separator', 'on' );
uimenu(mwlp,'Label','Load Data',  'callback', {@importWellLog, hFig} );
uimenu(mwlp,'Label','Remove Data','callback', {@delByTag, hFig, {'welllog' 'welllogname'}} );
uimenu(mwlp,'Label','Show Names','tag','showWellLogNames', 'callback', {@chgVisCheck,   hFig, 'welllogname'},'checked',stSettings.showWellLogNames );
uimenu(mwlp,'Label','Line Thickness','callback', {@setFigProperty, hFig,'welllog','wellLogLineWidth','linewidth'});     
mwlpp = uimenu(mwlp,'Label','Line Color');
sub_addColorSubMenus(mwlpp,hFig,'wellLogColor','welllog','color');

% 
% Export
%
 
m6 =  uimenu(hFig,'Label','Export');
uimenu(m6,'Label','Extract Vertical Profile(s)','callback', {@extractProfile, hFig, 'vert'} );
uimenu(m6,'Label','Extract Horizontal Profile(s)','callback', {@extractProfile, hFig, 'horizontal'} );
uimenu(m6,'Label','Export Unstructured Grid to File (y,z,rho_x,rho_y,rho_z)' ...
      , 'callback', {@extractRhoGrid, hFig});
uimenu(m6,'Label','Export Regular Grid to File (E,N,Z,rho_x,rho_y,rho_z)' ...
      , 'callback', {@extractRegularRhoGrid, hFig});
uimenu(m6,'Label','Export to VTK format for Paraview' ...
      , 'callback', {@exportToVTK, hFig});  


%------------------------%
% Survey Parameters menu (Rx and TX Geometries)
%------------------------%
m7 =  uimenu(hFig,'Label','Survey Geometry');
uimenu(m7,'Label','Map',                    'callback', {@plotSurveyMap, hFig, 'map'} );
uimenu(m7,'Label','Receiver Parameters',    'callback', {@plotSurveyMap, hFig, 'rx'} );
uimenu(m7,'Label','Transmitter Parameters', 'callback', {@plotSurveyMap, hFig, 'tx'} );


end % setUImenus
 

%--------------------------------------------------------------------------
function st = setComponentList(st)


switch st.anisotropy
    case 'isotropic'    % Note: .cmps below has order of resistivities in .resistivity array, plus possible anisotropy ratios
        st.cmps = {'Rho'};
        st.nNonRatio = 1;
    case 'triaxial'
        st.cmps = {'Rho x' 'Rho y' 'Rho z' 'Rho z/x' 'Rho z/y' 'Rho y/x'};
        st.nNonRatio = 3;
    case 'tix'
        st.cmps = {'Rho x' 'Rho y,z' 'Rho x/yz'};
        st.nNonRatio = 2;
    case 'tiy'
        st.cmps = {'Rho y' 'Rho x,z' 'Rho y/xz'};
        st.nNonRatio = 2;
    case {'tiz','tiz_ratio'}
        st.cmps = {'Rho z' 'Rho h' 'Rho z/h'};
        st.nNonRatio = 2;        
    case 'isotropic_ip'
        st.cmps = {'Rho' 'eta','tau' 'c'}; 
        st.nNonRatio = 4;
    case 'isotropic_complex'   
        st.cmps = {'Rho Real','Rho Imaginary' 'Imag/Real'};
        st.nNonRatio = 2;        
end

% Note: st.nNonRatio is the number of non-ratio parameters that can be plotted
% Also note that st.cmps variable names are hard coded in ratio plotting
% section of plotRhoXYZ, so they need to be changed there too if ever
% renamed here...

end

%--------------------------------------------------------------------------
function listener_updateUserdata(source,eventData)

hFig = eventData.AffectedObject;

bClosed = getappdata(hFig,'bClosed');
if ~bClosed
    setappdata(hFig,'bChanged',true);
else
    setappdata(hFig,'bClosed',true);
end

end

%--------------------------------------------------------------------------
function listener_updateCLim(source,eventData)

hFig = eventData.AffectedObject.Parent;

st          = get(hFig,'userdata');
stSettings  = getappdata(hFig,'stSettings');

ca = eventData.AffectedObject.CLim;

scale = getScale(st,stSettings);

if strcmpi(scale,'log10')
    ca = 10.^ca;
end

if st.icmp <= st.nNonRatio
    if st.plotSensitivity
        stSettings.colorScaleLimitsSensitivity = ca;
    elseif strcmpi(st.anisotropy,'isotropic_ip') && st.icmp > 1 % IP eta, tau or c
        stSettings.colorScaleLimitsIP = ca;  
    else
        stSettings.colorScaleLimitsResistivity = ca;
    end
else % ratio plot
    stSettings.colorScaleLimitsRatio = ca;
end   

setappdata(hFig,'stSettings',stSettings);

sub_saveMRU(stSettings,hFig);
 
end


%--------------------------------------------------------------------------
function sUnits = getUnits(st)

    if st.icmp <= st.nNonRatio
        if st.plotSensitivity 
            sUnits = 'sensitivity';
        elseif strcmpi(st.anisotropy,'isotropic_ip') && st.icmp > 1 % eta, tau or c
            sUnits = st.cmps{st.icmp};
        else
            sUnits = 'ohm-m';
        end
    else % ratio plot
        sUnits = 'ratio';
    end
    
end
%--------------------------------------------------------------------------
function scale = getScale(st,stSettings)

if st.icmp <= st.nNonRatio
    
    if st.plotSensitivity 
        
        scale = stSettings.colorScaleSensitivity;
  
    elseif strcmpi(st.anisotropy,'isotropic_ip') && st.icmp > 1 % IP eta, tau or c
        scale = stSettings.colorScaleIP;
                
    else % resistivity
        scale = stSettings.colorScaleResistivity;
    end
    
else % ratio plot
    scale = stSettings.colorScaleRatio;
end

end
%--------------------------------------------------------------------------
function zoom_updateAxes(~,~)

hFig = gcf; % kwk debug: haven't been able to successfully pass this as input argument. Something to do with the auto callback...

st          = get(hFig,'userdata');
stSettings  = getappdata(hFig,'stSettings');

% If plotting sensitivity contours, update them if plot zoom has changed
% (since we only plot contours in current view):
checked = get(findobj(hFig,'tag','showSensContours'),'checked');
if strcmpi( checked , 'on' ) 
    if ~isempty(st.contourAxLim) && all(axis ~= st.contourAxLim)
        makeSensitivityContours(hFig,st,stSettings)
        st.contourAxLim = axis;
        set(hFig,'userdata',st);
    end
end


% If plotting resistivity contours, update them if plot zoom has changed
% (since we only plot contours in current view):

if strcmpi( stSettings.showResContours, 'on' ) 
    if ~isempty(st.contourAxLim) && all(axis ~= st.contourAxLim)
        makeResistivityContours(hFig,st,stSettings)
        st.contourAxLim = axis;
        set(hFig,'userdata',st);
    end
end


% Get current xticks:

sub_setAxisTickLabels(hFig)

% rescale any hax2 items:
sub_adjustSecondAxes(hFig);



end
%--------------------------------------------------------------------
function sub_adjustSecondAxes(hFig)

st = get(hFig,'userdata');
 
% if hax2 axies, scale it to match main axes:
if isfield(st,'hax2') && ~isempty(st.hax2)
    pos = get(st.axes,'position');
    xl = get(st.axes,'xlim');
    yl = get(st.axes,'ylim');
    xd = get(st.axes,'xdir');
    yd = get(st.axes,'ydir');
    
    set(st.hax2,'position',pos,'xlim',xl,'ylim',yl,'xdir',xd,'ydir',yd)
end

end
    
%--------------------------------------------------------------------
function sub_setUnits(hObj, ~,hFig)
% toggle between meters and kilometers on position scales

stSettings  = getappdata(hFig,'stSettings');

if strcmpi(get(hObj,'checked'),'on')
    stSettings.usekm = 'off';
else
    stSettings.usekm = 'on';
end
set(hObj,'checked',stSettings.usekm);

setappdata(hFig,'stSettings',stSettings);

sub_saveMRU(stSettings,hFig);

sub_setAxisTickLabels(hFig)

end


%--------------------------------------------------------------------------
function sub_setAxisTickLabels(hFig)

handles     = get(hFig,'userdata');
stSettings  = getappdata(hFig,'stSettings');

% use auto ticks from matlab and then relab them using m or km and possilby UTM:
set(handles.axes,'XTickMode','auto','YTickMode','auto');
 
xt = get(handles.axes,'xtick');
yt = get(handles.axes,'ytick');

% Overlabel the ticks so when panning the correct labels come up
% rather than repeats of the manual tick labels (which put incorrect labels
% for new ticks outside the original axis extent):
dt = diff(xt(1:2));
xt = min(xt)-10*dt:dt:max(xt)+10*dt;
set(handles.axes,'xtick',xt);

dt = diff(yt(1:2));
yt = min(yt)-10*dt:dt:max(yt)+10*dt;
set(handles.axes,'ytick',yt);

if strcmpi(stSettings.usekm,'on')
    xts = num2str(xt(:)/1d3);
    yts = num2str(yt(:)/1d3);
    xlabel('Position (km)')
    ylabel('Depth (km)')
    
else
    xts = num2str(xt(:));
    yts = num2str(yt(:));
    xlabel('Position (m)')
    ylabel('Depth (m)')
end
set(handles.axes,'xticklabel',xts);
set(handles.axes,'yticklabel',yts);

st  = get(hFig,'userdata');
 
% Create xticks for equivalent northings or eastings:
if strcmpi(stSettings.showUTM,'on') && ~isempty(st.stUTM) && st.stUTM.north0 ~= 0 && st.stUTM.east0 ~= 0
        
    % Only show UTM labels for ticks in current view:
    xl = get(handles.axes,'xlim');
    xt = xt(xt >= xl(1) & xt <= xl(2));
    
    % get scale:
    if strcmpi(stSettings.usekm,'on')
        fac = 1d3;
        sunt = 'km';
    else
        fac = 1;
        sunt = 'm';
    end
    
    n0 = st.stUTM.north0;
    e0 = st.stUTM.east0;
    theta = st.stUTM.theta;
    % note that theta is the direction for x, model is along y, so add
    % 90º:
    ctt = cosd(theta+90);
    stt = sind(theta+90);

    northing = xt*ctt+n0;
    easting  = xt*stt+e0;

    string = {}; 
    for i = length(northing):-1:1
        %         string{i} = num2str([northing; easting]','%8.0fN\n%-8.0fE');
        string{i} = sprintf('\n\n%-.0f N\n%-.0f E', northing(i)/fac,easting(i)/fac);
    end
    
    % 
    % % Add custom tick labels to bottom axis
    % 

    delete(findobj(hFig,'tag','xticks'))

    offset = 0.015;
    lim = get(handles.axes,'YLim');
    hx = text(handles.axes,xt,...
    repmat(lim(2)+offset*(lim(2)-lim(1)),length(xt),1),...
    string,'HorizontalAlignment','center',...
    'VerticalAlignment','top','fontsize',get(handles.axes,'fontsize')*2/3,'tag','xticks' );
    xlabel('');

else
    
    delete(findobj(hFig,'tag','xticks'))
    
end


end

%--------------------------------------------------------------------------
function extractProfile(~,~,hFig,hvMode)
st = get(hFig,'userdata');

% DGM 10/23/2013 - found this is NOT coded for the ratios. So skip politely.
if st.icmp > st.nNonRatio
    uiwait( msgbox( {
        'Profile extraction not currently coded for'
        'resistivity ratios. Sorry.'
        }, 'plotMARE2DEM', 'modal' ) );
    return;
end

% Ask for 2D line endpoints:
switch hvMode
    case 'vert'
        prompt = {'Enter Horizontal Column(s) y or yStart:dy:yEnd,(km) :','Enter Vertical Endpoints (km): zStart ZEnd'};
    case'horizontal'
        prompt = {'Enter Vertical Row(s) z or zStart:dz:zEnd,(km) :','Enter Horizontal Endpoints (km): = yStart yEnd'};
    otherwise
        return
end

dlg_title = 'Input for resistivity profile extraction';
num_lines = 1;
def = {'',''};
answer = inputdlg(prompt,dlg_title,num_lines,def);
if isempty(answer)
    return
end

% DGM 10/23/2013 If anisotropic, allow extraction of all components, not just
% the currently showing one.
iPull = st.icmp;
if ~strcmpi( st.anisotropy, 'isotropic' ) && st.icmp <= st.nNonRatio
    sBtn = questdlg( {
        'Do you want to extract all anisotropic or complex components'
        'or only the current one showing?'
        }, 'plotMARE2DEM', 'All', 'Current Only', 'All' );
    if strcmpi( sBtn, 'all' )
        switch( st.anisotropy )  % If all components selected, output all x,y,z components to avoid any confusion...
        case 'triaxial'
            iPull = [1 2 3]; 
        case 'tix'
            iPull = [1 2 2];   % .resistivity has x, yz
        case 'tiy'  
            iPull = [2 1 2];   % .resistivity has y, xz
        case {'tiz' 'tiz_ratio'}
            iPull = [2 2 1];  % .resistivity has  z, xy
        case 'isotropic_ip'
            iPull = [1 2 3 4];  % rho, eta, tau, c
        case 'isotropic_complex'
            iPull = [1 2];  % rho real, rho imag          
            
        end
    end
end


switch hvMode
    case 'vert'
        xProfiles = eval(sprintf('[%s]',answer{1})); %,'%g')
        xProfiles(2,:) = xProfiles;
        z = sscanf(answer{2},'%g');
        if length(z) ~=2
            beep
            return
        end
        zProfiles = repmat(z,1,size(xProfiles,2));
        
    case'horizontal'
        
        zProfiles = eval(sprintf('[%s]',answer{1}));
        zProfiles(2,:) = zProfiles;
        x = sscanf(answer{2},'%g');
        if length(x) ~=2
            beep
            return
        end
        xProfiles = repmat(x,1,size(zProfiles,2));
end
% convert input km to m...
xProfiles = xProfiles*1d3;
zProfiles = zProfiles*1d3;

x = st.TR.Points(:,1);
y = st.TR.Points(:,2);
e = edges(st.TR);
xe = x(e);
ye = y(e);
XY2 =[xe(:,1:2) ye(:,1:2)];

 
icnt = 0;
nn = size(xProfiles,2)*length(iPull);
legstr = cell(nn,1);
plotMe = struct('x',[],'y',[]);
plotMe(nn).x = [];
ileg = 0;
for iPro = 1:size(xProfiles,2)
    
    XY1 = [xProfiles(1,iPro) xProfiles(2,iPro)  zProfiles(1,iPro) zProfiles(2,iPro) ];
    [intersect, xi, yi] = getIntersections(XY2,XY1);
    
    if isempty(intersect)
        % all in one triangle:
        si1 = pointLocation(st.TR,XY1([1 3]));
        si2 = pointLocation(st.TR,XY1([2 4]));
        for iCmp = iPull
            rho1 = st.resistivity(st.TriIndex(si1),iCmp);
            rho2 = st.resistivity(st.TriIndex(si2),iCmp);
            switch hvMode
            case 'vert'
                ileg = ileg+1;
                plotMe(ileg).x = [rho1 rho2]; % x and y plot objects..
                plotMe(ileg).y = XY1([3 4])/1d3;
                legstr{ileg} = num2str(xProfiles(1,iPro)/1d3);
            case'horizontal'
                ileg = ileg+1;
                plotMe(ileg).x = XY1([1 2])/1d3;
                plotMe(ileg).y = [rho1 rho2];
                legstr{ileg} = num2str(zProfiles(1,iPro)/1d3);
            end
            if numel(iPull) > 1
                legstr{ileg} = [legstr{ileg} ', ' st.cmps{iCmp}]; %('x' + iCmp - 1)];
            end
        end
    else
        
        % get unique intersections:
        A = unique([xi yi],'rows');
        xi = A(:,1);
        yi = A(:,2);  
        
        % sort them by range:
        r = sqrt( (xi-XY1(1)).^2 + (yi-XY1(3)).^2);
        [rr, ii] = sort(r);
        xi = xi(ii);
        yi = yi(ii);
        
        % Now get r position for line plots...
        rlast = sqrt( (XY1(2) - XY1(1))^2 + (XY1(4) - XY1(3))^2);
        R = [0 rr'; rr' rlast];

        % Get edge intersection midpoints, which must reside within an element
        % (ie not on an edge; not a vertex):
        xm = xi(1:end-1) + diff(xi)/2;
        ym = yi(1:end-1) + diff(yi)/2;
        
        % The list of all vertices that will be tested:
        xt = [XY1(1) xm' XY1(2)];
        yt = [XY1(3) ym' XY1(4)];
        
        si = pointLocation(st.TR,xt',yt');
        for iCmp = iPull
            rho = [];
            rho(:,1:2) = repmat(st.resistivity(st.TriIndex(si),iCmp),1,2);
            switch hvMode
            case 'vert'
                ileg = ileg+1;
                plotMe(ileg).x = reshape((rho'),numel(rho),1); % x and y plot objects..
                plotMe(ileg).y = reshape(R/1d3,numel(R),1)+zProfiles(1,iPro)/1d3;
                legstr{ileg} =  num2str(xProfiles(1,iPro)/1d3);
            case'horizontal'
                ileg = ileg+1;
                plotMe(ileg).x = reshape(R/1d3,numel(R),1)+xProfiles(1,iPro)/1d3;
                plotMe(ileg).y = reshape((rho'),numel(rho),1); % x and y plot objects..
                
                legstr{ileg} =  num2str(zProfiles(1,iPro)/1d3);
            end
            if numel(iPull) > 1
                legstr{ileg} = [legstr{ileg} ', ' st.cmps{iCmp} ]; % ('x' + iCmp - 1)]; 
            end
        end
    end
end

 
hFig = m2d_newFigure();
hAx = axes(hFig);   
for i = 1:numel(plotMe)
    switch hvMode
    case 'vert'
        semilogx(hAx,plotMe(i).x,plotMe(i).y,'-');
    case'horizontal'
        semilogy(hAx,plotMe(i).x,plotMe(i).y,'-');
    end
    hold all;
end
legend(legstr)
set(findobj(hFig,'type','line'),'linewidth',2)
 
str = 'Rho';
 
switch hvMode
case 'vert'
    axis ij;
    xlabel(sprintf('%s (ohm-m)',str)); % kwk debug... fix for lin/log10 options
    ylabel('Depth (km)'); %
case'horizontal'
    ylabel(sprintf('%s (ohm-m)',str)); % kwk debug... fix for lin/log10 options
    xlabel('Position (km)'); %
end

% DGM 10/24/2013 - if there is only one profile location, offer to write it out
% to a file. (This is more complicated if the user is pulling lots of profiles,
% so ignore that case).
if numel(iPull) == numel(plotMe)
    % Confirm the action
    bTraj = false;
    if strcmpi( hvMode, 'vert' ) && numel(iPull) == 1
        sBtn = questdlg( {
            'Do you want to write the profile to a file?'
            ' '
            'If so, choose between "trajectory" format and'
            'the simple z,rho format.'
            }, 'plotMARE2DEM Extract Profile' ...
            , 'Trajectory', 'Simple', 'Don''t Write', 'Trajectory' );
        if strcmpi( sBtn, 'Trajectory' )
            bTraj = true;
        elseif ~strcmpi( sBtn, 'Simple' )
            return;
        end
    else
        sBtn = questdlg( 'Do you want to write the profile to a file?' ...
            , 'plotMARE2DEM Extract Profile', 'Yes', 'No', 'Yes' );
        if ~strcmpi( sBtn, 'Yes' )
            return;
        end
    end
    
    % Get the output file name
    if strcmpi( hvMode, 'vert' )
        sSaveFile = fullfile( pwd(), [st.resistivityFile '_extracted_vert_' num2str(xProfiles(1,1)/1000) 'km.dat'] );
    else
        sSaveFile = fullfile( pwd(), [st.resistivityFile '_extracted_horiz_' num2str(zProfiles(1,1)/1000) 'km.dat'] );
    end
    [sF,sP] = uiputfile( {'*.dat', '.dat file'; '*','All Files'} ...
                       , 'Pick an output file', sSaveFile );
    if ~ischar(sF)
        return
    end
    sSaveFile = fullfile( sP, sF );
    
    % If exporting trajectory format (only for vertical profiles)
    if bTraj
        % Convert Y into N,E
        nOriginN    = st.stUTM.north0;
        nOriginE    = st.stUTM.east0;
        nRotate     = 90 - mod( st.stUTM.theta + 90, 360 );    % .theta is PERPENDICULAR to line strike
        nEN         = zeros(numel(plotMe(1).x),2);
        nEN(:,1)    = xProfiles(1,1);
        nEN = nEN * [ cosd(nRotate) sind(nRotate)
                     -sind(nRotate) cosd(nRotate)];
        nEN = colPlus( nEN, [nOriginE nOriginN] );
        nData = [round(nEN) plotMe(1).y*1000 log10(plotMe(1).x)];  % .y=depth, .x=linear resistivity
        clear nEN nRes y z
        
        nData = nData(2:2:end,:).'; % remove dups & turn on its side for output
        
        sHdr = sprintf( '%s\nx(m) y(m) depth(m) RT', st.resistivityFile );
        sFmt = '%.1f %.1f %.4f %.4f\n';
        
    else        % simple format
        % Assemble the data & header
        if strcmpi( hvMode, 'vert' )
            sHdr = '# Z (m)';
            nData(1,:) = plotMe(1).y * 1000;
        else
            sHdr = '# Y (m)';
            nData(1,:) = plotMe(1).x * 1000;
        end
        for i = 1:numel(plotMe)
            sHdr = [sHdr ', Rho' ('X' + iPull(i) - 1)]; %#ok<AGROW>
            if strcmpi( hvMode, 'vert' )
                nData(i+1,:) = plotMe(i).x;
            else
                nData(i+1,:) = plotMe(i).y;
            end
        end
        sFmt = [repmat( '%10g ', 1, numel(plotMe) + 1 ) '\n'];
        
        % Since plotMe.y is stairstep model with duplicate y depths to
        % account for every node of the stairstep plot, here just output
        % top_depth,resistivity for the 1D model so its ready ,e.g. for Dipole1D
        % modeling.
        nData = nData(:,1:2:end);
        
        % Also, since we pulled the profile from the st.TR triangulation
        % grid rather than the model, the profile will have extra nodes
        % where the TR splits a given parameter (e.g., where triangles
        % bisect a quad), so get rid of these for simplicity:
        
      
        bTry    = true;
        nDataOG = nData;
        
        i = 1;
        while bTry
            
            if all(nData(2:end,i+1) == nData(2:end,i))
                % remove that layer:
                nData(:,i+1) = [];
            else
                i = i + 1;
            end
            
            if i >= size(nData,2)
                bTry = false;
            end
            
        end
        
    end
    
    % Write
    fid = fopen( sSaveFile, 'w' );
    fprintf( fid, '%s\n', sHdr );
    fprintf( fid, sFmt, nData );
    fclose(fid);
end

end % extractProfile


%--------------------------------------------------------------------------
function exportToVTK(~,~,hFig)
%
% Exports the model to VTK format for plotting in 3D with Paraview  
%
st          = get(hFig,'userdata');
stSettings  = getappdata(hFig,'stSettings');

Tris     = st.TR.ConnectivityList;
Points   = st.TR.Points;
TriIndex = st.TriIndex;

% Check if fixed structure is visible, if not strip it out:
if strcmpi(stSettings.showFixed,'off')
    
    % index of free parameters:   
    lFree = all(st.freeparameter(TriIndex,:) > 0, 2);
    
    Tris = Tris(lFree,:);
    TriIndex = TriIndex(lFree);
    
    % Now get unique list of vertices required:
    verts = unique(Tris(:));
    
    % now renumber them:
    lKeep = false(size(Points,1),1);
    lKeep(verts) = true;
    Points = Points(lKeep,:);
    
    iOldToNew = zeros(size(Points,1),1);
    iOldToNew(verts) = 1:length(verts);
    
    Tris = iOldToNew(Tris);
    
end

% Trim output to current axes view:
axLim = axis;
    
lKeep = Points(:,1) >= axLim(1) & Points(:,1) <= axLim(2) & ...
        Points(:,2) >= axLim(3) & Points(:,2) <= axLim(4);
ind = find(lKeep);
clear iOldToNew;
iOldToNew(ind) = 1:length(ind);

Points = Points(lKeep,:);

iKeepTri = all(lKeep(Tris),2);
Tris     = Tris(iKeepTri,:);

Tris     = iOldToNew(Tris);

TriIndex = TriIndex(iKeepTri);


Y = Points(:,1);
Z = Points(:,2);
X = 0*Y;

% Rotate into UTM coords:
nRotate = -st.stUTM.theta; % Rotate so X is N, Y is E.
R = [ cosd(nRotate) sind(nRotate)
     -sind(nRotate) cosd(nRotate)];
    
XY0 = R*[X Y]';

nNorthing = XY0(1,:)' + st.stUTM.north0;
nEasting  = XY0(2,:)' + st.stUTM.east0;  
 
% Ask user for base UTM zone to use for output. The default is UTM zone in
% .resistivty file, but here you can change it to something else. This is
% useful for when different UTM zones have been set for two or more models
% in the .resistivity files but a common UTM zone is needed for a Paraview
% scene.

     
prompt =  sprintf('Enter UTM zone for output model \n (default is value from the .resistivity file)');
dlg_title = 'Set UTM Zone';
num_lines= 1;
defaultanswer = {sprintf('%i%s',st.stUTM.grid, st.stUTM.hemi)};
answer = inputdlg(prompt,dlg_title,num_lines,defaultanswer);

newGrid = sscanf(answer{1},'%i');
newHemi = char(sscanf(answer{1},'%*i%c'));

if newGrid ~= st.stUTM.grid && strcmpi(newHemi,st.stUTM.hemi)
    % Convert old UTM to Long & Lat, then convert using new grid:
    bSHemi = false;
    if strcmpi(st.stUTM.hemi,'s')
        bSHemi = true;
    end
    [nLon, nLat] = UTM2LonLat( nEasting, nNorthing,  double(st.stUTM.grid), bSHemi);
    [nEasting,nNorthing] = LonLat2UTM( nLon, nLat, newGrid  );
end

Points = [nNorthing nEasting Z];

nPts = size(Points,1);
nTri = size(Tris,1);

% If exporting from a shared .fig file, st.directory might not exist,\
% so test for that and change to local directory 
sOutputDir = st.directory;

if ~exist(sOutputDir,'dir') 
    sOutputDir = pwd;
end
    
sOutputFilename = fullfile(sOutputDir, [st.resistivityFile '.vtk'] );
 
% Save to VTK file:
fid = fopen(sOutputFilename,'w');
    
fprintf(fid,'# vtk DataFile Version 2.0\n' );  
fprintf(fid,'Unstructured Grid\n' );  
fprintf(fid,'ASCII\n' );  
fprintf(fid,'DATASET UNSTRUCTURED_GRID\n' );  
fprintf(fid,'POINTS %i double\n',nPts);    
fprintf(fid,' %12f %12f %12f\n',Points');   

 
fprintf(fid,'CELLS %i %i\n',nTri,nTri*4);
fprintf(fid,'3 %12i %12i %12i\n',Tris'-1);   
 
fprintf(fid,' CELL_TYPES  %i\n',nTri);
fprintf(fid,'%i\n',5 + 0*Tris(:,1)) ;   

fprintf(fid,'CELL_DATA %i\n',nTri) ;  

% Get all resistivity components:
log10rho = log10(st.resistivity(TriIndex,:));  

switch st.anisotropy
    case 'isotropic'    % Note: .cmps below has order of resistivities in .resistivity array, plus possible anisotropy ratios
        st.cmps = {'Log10(Rho_x)'};
    case 'triaxial'
        st.cmps = {'Log10(Rho_x)' 'Log10(Rho_y)' 'Log10(Rho_z)' 'Log10(Rho_x/Rho_y)' 'Log10(Rho_y/Rho_z)' 'Log10(Rho_z/Rho_x)' };   
        log10rho(:,6) = log10(st.resistivity(TriIndex,3) ./ st.resistivity(TriIndex,1)); % add ratio to log10Rho
        log10rho(:,5) = log10(st.resistivity(TriIndex,2) ./ st.resistivity(TriIndex,3)); % add ratio to log10Rho
        log10rho(:,4) = log10(st.resistivity(TriIndex,1) ./ st.resistivity(TriIndex,2)); % add ratio to log10Rho
    case 'tix'
        st.cmps = {'Log10(Rho_x)' 'Log10(Rho_y,z)' 'Log10(Rho_x/Rho_y,z)'};
        log10rho(:,3) = log10(st.resistivity(TriIndex,1)./ st.resistivity(TriIndex,2)); % add ratio to log10Rho
    case 'tiy'
        st.cmps = {'Log10(Rho_y)' 'Log10(Rho_x,z)' 'Log10(Rho_y/Rho_x,z)'};
        log10rho(:,3) = log10(st.resistivity(TriIndex,1) ./ st.resistivity(TriIndex,2)); % add ratio to log10Rho
    case {'tiz' 'tiz_ratio'}
        st.cmps = {'Log10(Rho_z)' 'Log10(Rho_h)' 'Log10(Rho_z/Rho_h)'};
        log10rho(:,3) = log10(st.resistivity(TriIndex,1) ./ st.resistivity(TriIndex,2)); % add ratio to log10Rho
    case 'isotropic_ip'
        st.cmps = {'Rho_x' 'eta','tau' 'c'}; 
        log10rho(:,2:4) = st.resistivity(TriIndex,2:4); % don't log scale eta, tau and c.  
    case 'isotropic_complex'
        st.cmps = {'Log10(Rho_real)' 'Log10(Rho_imag)' 'Log10(Rho_imag/Rho_real)'};  
        log10rho(:,3) = log10(st.resistivity(TriIndex,2)./ st.resistivity(TriIndex,1)); % add imag/real ratio to log10Rho
end

for i = 1:length(st.cmps)
    str = st.cmps{i};
    fprintf(fid,'SCALARS %s double 1\n',str);
    fprintf(fid,'LOOKUP_TABLE default\n');
    fprintf(fid,' %12f %12f %12f\n',log10rho(:,i));     
end

fclose(fid);
 
uiwait( msgbox( {
    sprintf( 'Wrote MARE2DEM model to file %s',sOutputFilename)
    }, 'Export to VTK format for Paraview', 'modal' ) );

    
end


%--------------------------------------------------------------------------
function extractRhoGrid(~,~,hFig)

st = get(hFig,'userdata');

% Output all three components (even if isotropic), to avoid user confusion
% about, e.g. TIZ ordering

switch st.anisotropy
    case 'isotropic'   
        icmps = [1 1 1 ];
    case 'triaxial'
        icmps = [1 2 3];
    case 'tix'
       icmps = [1 2 2];
    case 'tiy'
        icmps = [2 1 2];
    case {'tiz' 'tiz_ratio'}
         icmps = [2 2 1];
    case 'isotropic_ip'
         icmps = 1:4;
    case 'isotropic_complex'
         icmps = 1:2;         
end


%IC = incenter(st.TR,(1:length(st.TR(:,1)))');
%rho = st.resistivity(st.TriIndex,icmps);
% A = [IC rho];

centroids = getCentroids(st.TR,st.TriIndex);
rho = st.resistivity(:,icmps);
A = [centroids(:,1:2) rho];



% Get the name of the output file & write out
sSaveFile = fullfile( pwd(), [st.resistivityFile '_extracted_unstructured.xyz'] );
[sF,sP] = uiputfile( {'*.xyz', 'Extracted file (.xyz)'; '*','All Files'} ...
               , 'Pick an output file', sSaveFile );
if ~ischar(sF)
return
end
sSaveFile = fullfile( sP, sF );
 
 
save(sSaveFile,'A','-ascii');

    % Ta-da!
    uiwait( msgbox( {
        sprintf( 'Wrote %d locations to file', size(IC,1))
        sSaveFile
        }, 'Extract Unstructured Grid', 'modal' ) );
    
    
end

%--------------------------------------------------------------------------
% DGM 11/2013 - extract a grid of rho values for a regular mesh of positions
% specified by the user. This is usually a subset of the entire model; the area
% of interest.
function extractRegularRhoGrid(~,~,hFig)
    % Get the positions & turn them into a meshgrid
    nYL = xlim()/1d3;
    nZL = ylim()/1d3;
    cAns = inputdlg( {
        'Y positions (km) to extract at (e.g. -20:0.1:20):'
        'Z positions (km) to extract at (e.g. 0:0.1:10):'
        'Export "resistivity" or "conductivity":'
        'Export "linear" or "log10" values:'
        }, 'Extract Regular Grid', 1, {
        [num2str(floor(nYL(1))) ':0.1:' num2str(ceil(nYL(2)))] % by dflt, select what is showing
        [num2str(max(0.001,floor(nZL(1)))) ':0.1:' num2str(ceil(nZL(2)))]
            % Dflt to 1m bsl so that (a) we don't catch the air layer and (b) we
            % don't exactly line up with water layers - which are usually at
            % 100m intervals exactly.
        'resistivity'
        'linear'
        } );
    if isempty( cAns )
        return
    end
    [y,bOK] = str2num( cAns{1} ); %#ok<ST2NM>
    if ~bOK || numel(y) < 2
        uiwait( errordlg( {
            'Value for ''Y positions'' did not convert to an array of numbers.'
            }, 'Extract Regular Grid', 'modal' ) );
        return;
    end
    [z,bOK] = str2num( cAns{2} ); %#ok<ST2NM>
    if ~bOK || numel(z) < 2
        uiwait( errordlg( {
            'Value for ''Z positions'' did not convert to an array of numbers.'
            }, 'Extract Regular Grid', 'modal' ) );
        return;
    end
    y = y * 1000;   % cvt to meters
    z = z * 1000;
    [y,z] = meshgrid(y,z);
    
    % Get resistivities for the selected points
    st = get( hFig, 'UserData' );
    
% Output all three components (even if isotropic), to avoid user confusion
% about, e.g. TIZ ordering

    switch st.anisotropy
        case 'isotropic'   
            icmps = [1 1 1 ];
        case 'triaxial'
            icmps = [1 2 3];
        case 'tix'
           icmps = [1 2 2];
        case 'tiy'
            icmps = [2 1 2];
        case {'tiz' 'tiz_ratio'}
             icmps = [2 2 1];
        case 'isotropic_ip'
             icmps = 1:4;
        case 'isotropic_complex'
             icmps = 1:2;             
    end


    nRes = st.resistivity(st.TriIndex(pointLocation(st.TR,y(:),z(:))),icmps);
    
    % DGM 5/9/2014 - add new options: sigma vs rho; linear vs log
    if ~strncmpi( cAns{3}, 'r', 1 )
        nRes = 1./nRes;
    end
    if strncmpi( cAns{4}, 'lo', 2 )
        nRes = log10(nRes);
    end
    
    % Convert Y into N,E
    nOriginN    = st.stUTM.north0;
    nOriginE    = st.stUTM.east0;
    nRotate     = 90 - mod( st.stUTM.theta + 90, 360 );    % .theta is PERPENDICULAR to line strike
    nEN         = zeros(numel(y),2);
    nEN(:,1)    = y(:);
    nEN = nEN * [ cosd(nRotate) sind(nRotate)
                 -sind(nRotate) cosd(nRotate)];
    nEN = colPlus( nEN, [nOriginE nOriginN] );
    nENDR = [round(nEN) round(z(:)) nRes];
    clear nEN nRes y z
    
    % Get the name of the output file & write out
    sSaveFile = fullfile( pwd(), [st.resistivityFile '_extracted_mesh.xyz'] );
    [sF,sP] = uiputfile( {'*.xyz', 'Extracted file (.xyz)'; '*','All Files'} ...
                       , 'Pick an output file', sSaveFile );
    if ~ischar(sF)
        return
    end
    sSaveFile = fullfile( sP, sF );
    
%     save( sSaveFile, '-ASCII', 'nENDR' );
    % NB: Want more control over formatting for readability...
    sFmt = ['%7d %7d %5d' repmat(' %10.5g',1,size(nENDR,2)-3) '\n'];
    fid = fopen( sSaveFile, 'w' );
    fprintf( fid, sFmt, nENDR' );
    fclose(fid);
    
    % Ta-da!
    uiwait( msgbox( {
        sprintf( 'Wrote %d locations to file', size(nENDR,1))
        sSaveFile
        }, 'Extract Regular Grid', 'modal' ) );
    
    return;
end % extractRhoRegularGrid

function a = colPlus( a, b )
% colPlus(a,b) - add value b(1,i) to a(:,i).  b is a single row
% vector. a has same # of cols as b and many rows.
%
% David Myer
% May 2009
%
% See also colMinus
    a = colMinus( a, -b );
    return
end
function a = colMinus( a, b )
% colMinus(a,b) - subtract value b(1,i) from a(:,i).  b is a single row
% vector. a has same # of cols as b and many rows.  Useful for doing things
% like demeaning multiple columns of data: n = colMinus( n, mean(n) );
%
% David Myer
% Feb 2009
%
% See also colPlus

    nSzA = size(a);
    nSzB = size(b);
    if nSzA(2) ~= nSzB(2)
        error( 'colMinus: # of columns must match' );
    end
    if nSzB(1) ~= 1
        error( 'colMinus: b must have only one row' );
    end

    % be memory conscious
    if prod( nSzA ) > 200000
        for i=1:nSzA(1)
            a(i,:) = a(i,:) - b;
        end
    else
        a = a - repmat(b,nSzA(1),1);
    end

    return;
end


%--------------------------------------------------------------------------
function [intersect, xi, yi] = getIntersections(xya,xyb)
% tests for intersection of any line in xya with the single line in xyb
intersect = [];
xi = [];
yi = [];

nb = size(xyb,1);
if nb > 1
    beep;
    disp('getIntersections assumes second segment is a single line!')
    return;
end

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

% DGM 5/9/2014 - dispense with the tolerance search. MUST also include exact
% pass through of verticies otherwise the resistivity of some triangles will be
% completely missed. I.e. if the profile line passes exactly through a vertex,
% then this code skipped over the region that was entered entirely.
intersect = (pa >= 0) & (pa <= 1) & (pb >= 0) & (pb <= 1);
% tol = 1000*eps;
% intersect = ( (pa > 0+tol) & (pa < 1-tol) & (pb > 0+tol) & (pb < 1-tol));
xi = xi(intersect);
yi = yi(intersect);


% Check for degenerate case of parallel lines:
ipar = find(den==0); % if so, add endpoints of the segment:
intersect(ipar) = true;     % DGM 5/9/2014, this had "==" instead of "="
xi = [xi; xya(ipar,1);xya(ipar,2) ];
yi = [yi; xya(ipar,3);xya(ipar,4) ];
 

end

%--------------------------------------------------------------------------
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

overlap = find( ~ ((ax1 > bx2 | bx1 > ax2) | (ay1 > by2 | by1 > ay2)));


end

%--------------------------------------------------------------------------
function chgShading(hObject,~,hFig)

stSettings = getappdata(hFig,'stSettings');

if strcmpi(get(hObject,'checked'),'on')
     stSettings.showInterpolated = 'off';
     set(hObject,'checked','off');
else
    stSettings.showInterpolated = 'on';
    set(hObject,'checked','on');    
end
 
setappdata(hFig,'stSettings',stSettings);
plotRhoXYZ([],[],hFig);

% Save new MRU file:
sub_saveMRU(stSettings,hFig);


end

%--------------------------------------------------------------------------
function plotRhoXYZ(~,~,hFig)

% Note this routine does not set the userdata or appdata

hFreeCut = [];

set(hFig, 'Pointer', 'watch' ); drawnow;    
   
st          = get(hFig,'userdata');
stSettings  = getappdata(hFig,'stSettings');

x = st.TR.Points(:,1);
y = st.TR.Points(:,2);

% delete any existing parameter plot objects:
if ~isempty(findobj(hFig,'tag','free')) || ~isempty(findobj(hFig,'tag','fixed'))
    delete(findobj(hFig,'tag','free'));
    delete(findobj(hFig,'tag','freecut'));
    delete(findobj(hFig,'tag','fixed'));
    delete(findobj(hFig,'tag','free_fixedmask'));
    
end

% Delete any contours
delete(findobj(hFig,'tag','SensitivityContours'));
delete(findobj(hFig,'tag','ResistivityContours'));
 
if st.icmp <= st.nNonRatio  % not a ratio plot
    
    % index of free parameters:   
    lfree = st.freeparameter(st.TriIndex,st.icmp) > 0;
    
    % If plotting sensitivity, modify cc to be sensitivity values for free params: 
    if st.plotSensitivity  
        cc = st.freeparameter(st.TriIndex,st.icmp);
        iparamnum = cc(lfree);
        cc(:) = 0;
        if strcmpi(stSettings.colorScaleSensitivity,'log10')
            cc(lfree) = log10(st.sensitivity(iparamnum));
            sLegstr = 'log10(sensitivity)';
        elseif strcmpi(stSettings.colorScaleSensitivity,'linear')
            cc(lfree) = (st.sensitivity(iparamnum));
            sLegstr = 'sensitivity';
        end    
    elseif strcmpi(st.anisotropy,'isotropic_ip') && st.icmp > 1 % IP eta, tau or c
         if strcmpi(stSettings.colorScaleIP,'log10')
            cc = log10(st.resistivity(st.TriIndex,st.icmp)');
            sLegstr = 'log10(IP)';
        elseif strcmpi(stSettings.colorScaleIP,'linear')
            cc =      (st.resistivity(st.TriIndex,st.icmp)');
            sLegstr = 'IP';
         end   
    else % just resistivity
        % get resistivity for all regions:
        if strcmpi(stSettings.colorScaleResistivity,'log10')
            cc = log10(st.resistivity(st.TriIndex,st.icmp)');
            sLegstr = 'log10(ohm-m)';
        elseif strcmpi(stSettings.colorScaleResistivity,'linear')
            cc = (st.resistivity(st.TriIndex,st.icmp)');
            if ~strcmpi(st.anisotropy,'isotropic_ip') && any(st.resistivity(:) <= 0)
                sLegstr = 'log10(A) - log10(B)';
            else
                sLegstr = 'ohm-m';
            end
        end        
    end       


    % Create alpha mask based on sensitivity, if requested:
    sensAlpha  = [];
    
    if isfield( stSettings, 'sensitivityAlphaLowLimit' ) && ~isempty(st.sensitivity) && ~isempty( stSettings.sensitivityAlphaLowLimit )
            
        pnum        = st.freeparameter(st.TriIndex(lfree),st.icmp);   % param #s for the free triangles
        sensAlpha   = log10(st.sensitivity(pnum));

        % For alpha values below the lower limit, make entirely transparent.
        i0 = sensAlpha <= stSettings.sensitivityAlphaLowLimit;
        sensAlpha(~i0) = 1;
        sensAlpha(i0) =  stSettings.transparencyAlpha;
        
    end
         
    if strcmpi(stSettings.showInterpolated,'on')
        
        % Get lust of nodes and triangles that have a penalty cut:
        [lNodeCut, lTriCut] = sub_getNodeAndTriCutLists(st.segs,st.TR);
        
        % First we plot all triangles without cuts:
        lTriNoCut = ~lTriCut;
        
        % Create triangle based lists of values to plot for free parameters
        % only (fixed params get nans here):
        ccTri        = nan(size(st.TR,1),1);
        ccTri(lfree) = cc(lfree); 
        if ~isempty(sensAlpha)
            sensAlphaTri = nan(size(st.TR,1),1);
            sensAlphaTri(lfree) = sensAlpha;   
        end  

        % Now average parameter values for all nodes without penalty cuts
        % on triangles:     
        iNodesNoCut = find(~lNodeCut);
        ccNode = sub_getNodeAverage(st.TR,ccTri,iNodesNoCut);
        if ~isempty(sensAlpha) % note that sens
            sensAlphaNode  = sub_getNodeAverage(st.TR,sensAlphaTri,iNodesNoCut);
        end
        
        % Plot node averaged values for interpolated shading:
        
        faces = st.TR.ConnectivityList(lTriNoCut,:);
        verts = [x y];    
        
        % Apply sensitivity alpha mask if requested:
        if strcmpi( get( findobj( hFig, 'tag','plotSensitivityAlpha' ), 'checked' ), 'on' )
            hFree = patch(st.axes, 'faces',faces,'Vertices',verts,'facevertexcdata',ccNode,...
            'edgecolor','none','tag','free','CDataMapping','scaled','facecolor','interp', ....
            'FaceVertexAlphaData', sensAlphaNode, 'FaceAlpha', 'interp', 'AlphaDataMapping', 'scaled'   );
            st.axes.ALim = [0 1];  % force alpha range to be 0 to 1 so that sensAlpha transparency works correctly
        else
             hFree = patch(st.axes, 'faces',faces,'Vertices',verts,'facevertexcdata',ccNode,...
            'edgecolor','none','tag','free','CDataMapping','scaled','facecolor','interp');
        end       
        
 
        if ~isempty(lTriCut)
            % Now do more complex interpolation for triangles that have one
            % or more penalty cuts (and possible large parameter jumps from
            % triangle to another) To plo this, we list each node for each
            % triangle, so nodes get multiple values but colors are only
            % interpolated within each triangle, permitting the jumps in
            % the model across penalty cuts to be plotted correctly
            
            % For all cut triangles, non cut nodes can use existing
            % interpolated values in nodecc. cut nodes need to have new
            % averaging. 
            
            % - for each cut node we need to traverse ring of attached
            % triangles in both directions until we meet a cut.
%             faces = st.TR.ConnectivityList(iplotCuts,:);
%             verts = [yt zt]; need to be unwrapped to y z column vectors
%             face indexs need to be mapped to new vers ordering
%             st.TR.ConnectivityList)? do this afterstacking?
%           
%             nodecc = nan*faces; % each node in each triangle gets its own color
%             % for each face, test each vertex
%             
%             
            indCutNodes = find(lNodeCut);
            SI = vertexAttachments(st.TR, indCutNodes);
%             
%             ID = edgeAttachments(TR,startID,endID)
            
            % now plot them:
            hFreeCut = patch(st.axes, x(st.TR(lTriCut,:))',y(st.TR(lTriCut,:))',ccTri(lTriCut),...
                'edgecolor','none','tag','freecut');
            
        end
        
        %%% kwk debug: remember that all of the above needs to be added to
        %%% code for ratio plots below. Should make subfunctions for
        %%% better code reuse...
        
     % Plot gray mask over parameter region since interpolated shading of
     % FREE parameters will overlap into where free region has concavities:
     lfixed = st.freeparameter(st.TriIndex,st.icmp) == 0;  % set color to gray:
     svis = 'on';
     if strcmpi(stSettings.showFixed,'on')
         svis = 'off';
     end
     hFree_fixedmask = patch(st.axes, x(st.TR(lfixed,:))',y(st.TR(lfixed,:))',get(gca,'color'),...
                   'edgecolor','none','tag','free_fixedmask','visible',svis); 
     

 
                        
    else % plot parameters without interpolated shading
            
        hFree = patch(st.axes, x(st.TR(lfree,:)).' ...
                             , y(st.TR(lfree,:)).' ...
                             , cc(lfree), 'edgecolor','none','tag','free');
        
        % Apply sensitivity alpha mask if requested:
        if strcmpi( get( findobj( hFig, 'tag','plotSensitivityAlpha' ), 'checked' ), 'on' )
            set( hFree, 'FaceVertexAlphaData', sensAlpha ...
                      , 'FaceAlpha', 'flat', 'AlphaDataMapping', 'none' );
        end
    end
    
    
    % Plot Fixed parameters    
    lfixed = st.freeparameter(st.TriIndex,st.icmp) == 0;  
    hFixed = patch(st.axes, x(st.TR(lfixed,:))',y(st.TR(lfixed,:))',cc(lfixed),...
                            'edgecolor','none','tag','fixed');
 
    if st.plotSensitivity 
        cc = nan*st.resistivity(st.TriIndex,st.icmp)';
        if strcmpi(stSettings.colorScaleSensitivity,'log10')
            sLegstr = 'log10(sensitivity)';
        elseif strcmpi(stSettings.colorScaleSensitivity,'linear')
            sLegstr = 'sensitivity';
        end 
    elseif strcmpi(st.anisotropy,'isotropic_ip') && st.icmp > 1 % IP eta, tau or c
         if strcmpi(stSettings.colorScaleIP,'log10')
            cc = log10(st.resistivity(st.TriIndex,st.icmp)');
            sLegstr = 'log10(IP)';
        elseif strcmpi(stSettings.colorScaleIP,'linear')
            cc =      (st.resistivity(st.TriIndex,st.icmp)');
            sLegstr = 'IP';
         end
    else % plain rho:
        if strcmpi(stSettings.colorScaleResistivity,'log10')
            cc = log10(st.resistivity(st.TriIndex,st.icmp)');
            sLegstr = 'log10(ohm-m)';
        elseif strcmpi(stSettings.colorScaleResistivity,'linear')
            cc =      (st.resistivity(st.TriIndex,st.icmp)');
            if ~strcmpi(st.anisotropy,'isotropic_ip') && any(st.resistivity(:) <= 0)
                sLegstr = 'log10(A) - log10(B)';
            else
                sLegstr = 'ohm-m';
            end
        end        
    end  
    

    
    % Plot sensitivity contours if requested:
    if strcmpi( stSettings.showSensContours, 'on' ) && ~isempty(st.sensitivity)
        makeSensitivityContours(hFig,st,stSettings);  
        st.contourAxLim = axis;
    end
    
    
else  % Ratio plot
    
    [i1, i2] = getAnisotropicRatioComps(st);
    
    cc = st.resistivity(st.TriIndex,i1)'./st.resistivity(st.TriIndex,i2)';
    if strcmpi(stSettings.colorScaleRatio,'log10')
        cc = log10(cc);
        sLegstr = 'log10(ratio)';
    else
        sLegstr = 'ratio';
    end
    iplot = st.freeparameter(st.TriIndex,i1) > 0 | st.freeparameter(st.TriIndex,i2) > 0;
    
    if strcmpi(stSettings.showInterpolated,'on')
        SI = vertexAttachments(st.TR, (1:length(x))');
        yt = x(st.TR.ConnectivityList);
        zt = y(st.TR.ConnectivityList);
        tarea = polyarea(yt',zt')';
        
        % Modify iplot to not include parameters with penalty cuts:
        if size(st.segs,2) == 3
            icut = st.segs(:,3) < 0 ; % cuts are negative markers
            v1   = st.segs(icut,1);
            v2   = st.segs(icut,2);
            nodeCut = false(size(st.TR.Points,1),1);
            nodeCut(v1) = true;
            nodeCut(v2) = true;
            tr = st.TR.ConnectivityList;
            v1 = tr(:,1);
            v2 = tr(:,2);
            v3 = tr(:,3);
            iplotCuts = nodeCut(v1) |  nodeCut(v2) | nodeCut(v3);
            iplot = iplot & ~iplotCuts;
        else
            iplotCuts = [];
        end
        
        
        cc2 = cc;
        cc2(~iplot) = nan;
        newcc = ones(length(SI),1);
        for i = 1:length(SI)
            ind = SI{i};
            c = cc2(ind);
            a = tarea(ind)';
            newcc(i) = sum(c(~isnan(c)).*a(~isnan(c)))/sum(a(~isnan(c)));
        end
        faces = st.TR(iplot,:);
        verts = [x y];
        
        hFree = patch(st.axes, 'faces',faces,'Vertices',verts,'facevertexcdata',newcc,...
            'edgecolor','none','tag','free','CDataMapping','scaled','facecolor','interp');
        
        if ~isempty(iplotCuts)
            hFreeCut = patch(st.axes, x(st.TR(iplotCuts,:))',y(st.TR(iplotCuts,:))',cc(iplotCuts),...
                'edgecolor','none','tag','freecut');
        end
        
    else % plot actual parameters
        
        % Plot Free parameters
        
        hFree = patch(st.axes, x(st.TR(iplot,:))',y(st.TR(iplot,:))',cc(iplot),...
            'edgecolor','none','tag','free');
    end
    
    % Plot Fixed parameters
    iplot = st.freeparameter(st.TriIndex,i1) == 0 & st.freeparameter(st.TriIndex,i2) == 0;
    hFixed = patch(st.axes, x(st.TR(iplot,:))',y(st.TR(iplot,:))',cc(iplot),...
        'edgecolor','none','tag','fixed');
    
end

% Plot resistivity contours if requested:
if strcmpi( stSettings.showResContours , 'on' )
    makeResistivityContours(hFig,st,stSettings);  
    st.contourAxLim = axis;
end    

hCb = colorbar;
set(get(hCb,'ylabel'),'string',sLegstr,'tag','text','handlevisibility','on','fontsize',stSettings.fontSize)

str = st.cmps{st.icmp};
set(get(hCb,'title'),'string',str,'fontweight','bold',...
    'fontsize',stSettings.fontSize*.9,'tag','cb_text','HorizontalAlignment','center','handlevisibility','on')


% Update visibility:
set(hFixed,  'visible',stSettings.showFixed);
set(hFree,   'visible',stSettings.showFree);
set(hFreeCut,'visible',stSettings.showFree);


str = '';
    
if ~isempty(st.misfit)
    str = strcat(str,sprintf('    RMS: %g',st.misfit));


    % Add CSEM, DC and MT sub-misfits if data type present:
	lsum =  ~isempty(st.stCSEM) + ~isempty(st.stMT) + ~isempty(st.stDC);
   
    if lsum > 1
        
        % read in response file so we can compute submisfits:
        [p, n ] = fileparts(st.resistivityFile);
        sResponseFile =  fullfile(st.directory,strcat(n,'.resp'));
        if exist(sResponseFile,'file') % plot data file isntead
            stR = m2d_readEMData2DFile(sResponseFile);
            if ~isempty(stR)
                str = strcat(str,' (');
                laddComma = false;
                if any(stR.DATA(:,1)<100) % CSEM:
                    ld = stR.DATA(:,1)<100;
                    rms = sqrt(sum(stR.DATA(ld,8).^2)/length(stR.DATA(ld,8)));  
                    str = sprintf('%s%s',str,sprintf('CSEM: %0.2f',rms));
                    laddComma = true;
                end
                if any(stR.DATA(:,1)>100) && any(stR.DATA(:,1)<200) % MT:
                    ld = stR.DATA(:,1)>100 & stR.DATA(:,1)<200;
                    rms = sqrt(sum(stR.DATA(ld,8).^2)/length(stR.DATA(ld,8)));  
                    if laddComma
                        str = sprintf('%s%s',str,', ');
                    end
                    str = sprintf('%s%s',str,sprintf('MT: %0.2f',rms));
                    laddComma = true;
                end
                if any(stR.DATA(:,1)>200) && any(stR.DATA(:,1)<300) % DC:
                    ld = stR.DATA(:,1)>200 & stR.DATA(:,1)<300;
                    rms = sqrt(sum(stR.DATA(ld,8).^2)/length(stR.DATA(ld,8)));  
                    if laddComma
                        str = sprintf('%s%s',str,', ');
                    end                   
                    str = sprintf('%s%s',str,sprintf(' DC: %0.2f ',rms));

                end                
                str = strcat(str,')');    
            end
        end
    end
end

if st.plotSensitivity && st.icmp <= st.nNonRatio 
    [~,name,ext] = fileparts(st.sWJfile);
else
    [~,name,ext] = fileparts(st.resistivityFile);
end

% Add file name to title string:
file = strcat(name,ext);
str = sprintf('%s\n    Colors: %s',str,file );

% If sensitivity overlay or contours, display name:
if strcmpi( get(findobj(hFig,'tag','showSensContours'),'checked'), 'on') && ~isempty(st.sWJfile)
   [~,name,ext] = fileparts(st.sWJfile);
   file = strcat(name,ext);
   str = sprintf('%s,   Contours: %s',str,file );
elseif strcmpi( get( findobj( hFig, 'tag','plotSensitivityAlpha' ), 'checked' ), 'on' ) 
   [~,name,ext] = fileparts(st.sWJfile);
   file = strcat(name,ext);
   str = sprintf('%s,   Overlay: %s',str,file );
end

% Add directory to title str:
[p, folder] = fileparts(st.directory);
str = sprintf('%s, Folder: %s',str,folder );

% Add title to plot:
title(str,'tag','figtitle','handlevisibility','on','interpreter','none','visible',stSettings.showTitle);
    
% Set figure name to str:
set(hFig, 'name', str );

set(st.axes,'layer','top');


% Update colormap and colorscale limits:
if st.icmp <= st.nNonRatio
    if st.plotSensitivity  
        sub_applyColorMap(hFig,stSettings.sSensitivityColorMap,stSettings.sSensitivityInverted);
    else
        sub_applyColorMap(hFig,stSettings.sResistivityColorMap,stSettings.sResistivityInverted);
    end
else
    sub_applyColorMap(hFig,stSettings.sRatioColorMap,stSettings.sRatioInverted);
end
applyColorScale(st,stSettings);

% Plot penalties for st.icmp if requested:
hObj = findobj(hFig,'tag','plotPenaltiesBtn');
if ~isempty(hObj) && strcmpi(hObj.Checked,'on')
    makePenaltyPlot(hFig);
end

sub_uistack(hFig);


set(hFig, 'Pointer', 'arrow' );    

% Below throws a warning if the user has something like zoom or pan turned on.
stWarn = warning( 'off', 'MATLAB:modes:mode:InvalidPropertySet' );
set(hFig,'userdata',st,'WindowButtonUpFcn',@windowButtonUpCallbackFcn);
% set(hFig,'userdata',st,'WindowButtonMotionFcn',@windowButtonUpCallbackFcn);
warning( stWarn );


end


%--------------------------------------------------------------------------
function [valNode] = sub_getNodeAverage(TR,valTri,iNodesNoCut)
        
    valNode = nan(size(TR.Points,1),1);

    SI = vertexAttachments(TR, iNodesNoCut);
    y = TR.Points(:,1);
    z = TR.Points(:,2);
    yt = y(TR.ConnectivityList);
    zt = z(TR.ConnectivityList);
    tarea = polyarea(yt',zt')';

    for i = 1:length(SI)
        ind = SI{i};
        c   = valTri(ind);
        a   = tarea(ind);  
        valNode(iNodesNoCut(i)) = sum(c(~isnan(c)).*a(~isnan(c)))/sum(a(~isnan(c))); % area weighted average
    end         
    
end
%--------------------------------------------------------------------------
function [lNodeCut,lTriCut] = sub_getNodeAndTriCutLists(segs,TR)

    % Get list of nodes and triangles with penalty cuts:
    
    if size(segs,2) == 3
        icut = segs(:,3) < 0; % cuts are negative markers
        v1   = segs(icut,1);
        v2   = segs(icut,2);
        lNodeCut     = false(size(TR.Points,1),1);
        lNodeCut(v1) = true;
        lNodeCut(v2) = true;     
        tr = TR.ConnectivityList;
        v1 = tr(:,1);
        v2 = tr(:,2);
        v3 = tr(:,3);
        lTriCut = lNodeCut(v1) |  lNodeCut(v2) | lNodeCut(v3);
 
    else
        lTriCut = [];
        lNodeCut   = [];
    end     

end

%--------------------------------------------------------------------------
function  [i1, i2] = getAnisotropicRatioComps(st)
    
    switch st.anisotropy
        case 'tix'   % only x/yz 
                i1 = 1; 
                i2 = 2;
        case 'tiy'   % only y/xz 
                i1 = 1; 
                i2 = 2;
        case {'tiz','tiz_ratio'}
             % only z/xy 
                i1 = 1; 
                i2 = 2;
        case 'triaxial'
            switch lower(st.cmps{st.icmp})
                case 'rho z/x'
                     i1 = 3; 
                     i2 = 1;               
                case 'rho z/y'
                     i1 = 3; 
                     i2 = 2;
                case 'rho y/x'                    
                     i1 = 2; 
                     i2 = 1;   
            end  
        case 'isotropic_complex'   
              % only Imag/Real
                i1 = 2; 
                i2 = 1;           
                    
    end
end
%--------------------------------------------------------------------------
function makeSensitivityContours(hFig,st,stSettings)

% Delete any existing contours:
delete(findobj(hFig,'tag','SensitivityContours'));   

% Since the sensitivity is defined for the parameter polygons
% (triangles or quads or general), we need to map it to the
% vertices then use triangle contouring routine:

inView = getTrianglesInCurrentView(st);
inViewFree = inView & st.freeparameter(st.TriIndex,st.icmp) > 0;

% Get parameter numbers of triangles with free parameters: 
ifree     = st.freeparameter(st.TriIndex,st.icmp) > 0;
ip        = st.freeparameter(st.TriIndex,st.icmp);
iparamnum = ip(ifree);

if isempty(st.sensitivity)
    st = loadSensitivity(st);
end

cc = 0*(st.resistivity(st.TriIndex,st.icmp)'); % set color of each triangle to 0
cc(ifree) = log10(st.sensitivity(iparamnum));  % now set color of free parameter triangles to sensitivity  

% Get list of vertices for triangles in the current axes view:
TRinView = st.TR(inViewFree,:);
if isempty(TRinView)
    return
end
[vi,it,iv] = unique(TRinView(:));

% For each vertex in view, set its color to be area weighted
% average of attached triangles:
SI = vertexAttachments(st.TR,vi);

x = st.TR.Points(:,1);
y = st.TR.Points(:,2);

yt = x(st.TR.ConnectivityList);
zt = y(st.TR.ConnectivityList);
tarea = polyarea(yt',zt')';

% vertex color is average of connectected triangles:
newcc = ones(length(SI),1);
for i = 1:length(SI)
    ind = SI{i};
    c = cc(ind);
    a = tarea(ind)'; %1+0*tarea(ind)';
    newcc(i) = sum(c(~isnan(c)).*a(~isnan(c)))/sum(a(~isnan(c)));
    %  newcc(i) = max(c);
    %  newcc(i) = median(c(~isnan(c)));
end      

iOldToNew(vi) = 1:length(vi);

faces = iOldToNew(TRinView);


newcc(newcc==inf) = nan;
newcc(newcc==-inf) = nan;
ci = stSettings.sensitivityContourInterval;
co = stSettings.sensitivityContourColor;
cw = stSettings.sensitivityContourLineWidth;

% Check that contour interval overlaps data range, if not ask for new
% interval:
if ~isempty(ci) && ( min(newcc) > max(ci) || max(newcc) < min(ci) ) % true if data outside contour intervals:
    
    setSensitivityContours([],[],hFig);
    
else
    if length(ci(:)) == 1
        ci = [ci ci];
    end
    [c,h]   = tricontour(faces, x(vi), y(vi),newcc,ci,co);
    set( h, 'tag', 'SensitivityContours','linewidth',cw);

    checked = get(findobj(hFig,'tag','showSensContourLabels'),'checked');

    if strcmpi(checked,'on')
        hl      = clabel(c,'color',co);
        set( hl,'tag', 'SensitivityContours');
    end

end

sub_uistack(hFig);


end

%--------------------------------------------------------------------------
function makeResistivityContours(hFig,st,stSettings)

% Delete any existing contours:
delete(findobj(hFig,'tag','ResistivityContours'));   

% Since the resistivity is defined for the parameter polygons
% (triangles or quads or general), we need to map it to the
% vertices then use triangle contouring routine:

inView = getTrianglesInCurrentView(st);

if st.icmp <= st.nNonRatio  % not a ratio plot
    
    inViewFree = inView & st.freeparameter(st.TriIndex,st.icmp) > 0;
    % Get parameter numbers of triangles with free parameters: 
    ifree     = st.freeparameter(st.TriIndex,st.icmp) > 0;
    %ip        = st.freeparameter(st.TriIndex,st.icmp);
    %iparamnum = ip(ifree);
    %cc = 0*(st.resistivity(st.TriIndex,st.icmp)'); % set color of each triangle to 0
    cc = (st.resistivity(st.TriIndex,st.icmp)');
    
else
    
    [i1, i2] = getAnisotropicRatioComps(st); 
    inViewFree = inView & st.freeparameter(st.TriIndex,i1) > 0 | st.freeparameter(st.TriIndex,i2) > 0;
    ifree      = st.freeparameter(st.TriIndex,i1) > 0 | st.freeparameter(st.TriIndex,i2) > 0;
    
    cc = (st.resistivity(st.TriIndex,i1)./st.resistivity(st.TriIndex,i2))';    
    
end


cc(~ifree) = nan;
 
% Get list of vertices for triangles in the current axes view:
TRinView = st.TR(inViewFree,:);
[vi,it,iv] = unique(TRinView(:));

% For each vertex in view, set its color to be area weighted
% average of attached triangles:
SI = vertexAttachments(st.TR,vi);

x = st.TR.Points(:,1);
y = st.TR.Points(:,2);

yt = x(st.TR.ConnectivityList);
zt = y(st.TR.ConnectivityList);
tarea = polyarea(yt',zt')';

% vertex color is average of connectected triangles:
newcc = ones(length(SI),1);
for i = 1:length(SI)
    ind = SI{i};
    c = cc(ind);
    a = tarea(ind)'; %1+0*tarea(ind)';
    newcc(i) = sum(c(~isnan(c)).*a(~isnan(c)))/sum(a(~isnan(c)));
    %  newcc(i) = max(c);
    %  newcc(i) = median(c(~isnan(c)));
end      

iOldToNew(vi) = 1:length(vi);

faces = iOldToNew(TRinView);


newcc(newcc==inf) = nan;
newcc(newcc==-inf) = nan;

ci = stSettings.resistivityContourInterval;
co = stSettings.resistivityContourColor;
cw = stSettings.resistivityContourLineWidth;

scale = getScale(st,stSettings);

if strcmpi(scale,'log10')
    newcc = log10(newcc);
end


try % in case fails due to no changes
    
    [c,h]   = tricontour(faces, x(vi), y(vi),newcc,ci,co);
    set( h, 'tag', 'ResistivityContours','linewidth',cw);

    if strcmpi(stSettings.showResContourLabels,'on')
        hl      = clabel(c,'color',co);
        set( hl,'tag', 'ResistivityContours');
    end
catch
end

end

%--------------------------------------------------------------------------

function windowButtonUpCallbackFcn(hFig,~)


% Now find point in patch and show its resistivity value in text box:
FindPtInPatch(hFig);
    
end

%--------------------------------------------------------------------------
% Find the resistivity under the current mouse click.
% David Myer, Oct 2013.
function FindPtInPatch(hFig)
    
    st          = get(hFig,'userdata');
    stSettings  = getappdata(hFig,'stSettings');
    
    nPt = get(gca,'CurrentPoint');
    nPt = nPt(1,1:2);   % drop extra stuff
    nVal = [];
    if nPt(1) >= min(xlim()) && nPt(1) <= max(xlim()) ...
    && nPt(2) >= min(ylim()) && nPt(2) <= max(ylim()) 
        for h = reshape(findobj( gca, 'type', 'patch' ),1,[])
            if ~strcmpi( get(h,'Visible'), 'on' )
                continue;
            end
            X = get( h, 'XData' );
            Y = get( h, 'YData' );
            for i = 1:size(X,2)
                if PtInTri( nPt, X(:,i), Y(:,i) )
                    C = get( h, 'CData' );
                    if ~isempty(C) 
                        if numel(C) == max(size(C)) % flat
                            nVal = C(i);
                        else                        % interpolated
                            nVal = mean(C(:,i));
                        end
                    end
                    break;
                end
            end
            if ~isempty(nVal)
                break;
            end
        end
    end
    
    hTxt = findobj( hFig, 'Tag', 'PointInPatchText' );
    if isempty(nVal) || isnan(nVal)
       if ishandle(hTxt)
           delete(hTxt);
       end
    else
        
        scale = getScale(st,stSettings);
        sUnits = getUnits(st);
       
        
        if strcmpi(scale,'log10')
            nVal = 10.^nVal;
        end
 
        str = sprintf('%6.4g %s', (nVal),sUnits );
        if isempty(hTxt)
            uicontrol( 'Parent', hFig, 'Style', 'Text' ...
                    , 'String', str ...
                    , 'BackgroundColor', 'w', 'ForegroundColor', 'k' ...
                    , 'FontSize', 10, 'FontWeight', 'Normal' ...
                    , 'Units', 'Pixels', 'Position', [1 1 180 20] ...
                    , 'HorizontalAlignment', 'center' ...
                    , 'Tag', 'PointInPatchText' ...
                    );
            set( hFig, 'Toolbar', 'figure' );    % uicontrol turns it off.
        else
            set( hTxt, 'String', str);
        end
    end
    return;
    
    function b = PtInTri( nPt, X, Y )
        dX = nPt(1) - X(1);
        dY = nPt(2) - Y(1);
        
        bSignAB = (X(2) - X(1)) * dY > (Y(2) - Y(1)) * dX;
        bSignAC = (X(3) - X(1)) * dY > (Y(3) - Y(1)) * dX;
        if bSignAB == bSignAC
            b = false;  % not inside the cone formed by BAC
        else
            bSignBC = (X(3) - X(2)) * (nPt(2) - Y(2)) ...
                    > (Y(3) - Y(2)) * (nPt(1) - X(2));
            b = bSignBC == bSignAB;
        end
        return;
    end

end % FindPtInPatch


%--------------------------------------------------------------------------
function IterationMenuDrop(~,~,hFig)

st = get(hFig,'Userdata');

m40 = findobj(hFig,'tag','itermenu');

delete(get(m40,'children'));

st = get(hFig,'userdata');
if ~isempty(st.directory)
    str = sprintf('%s/*.resistivity',st.directory);
else
    str = '*.resistivity';
end
files = dir(str);
if isempty(files)
    return;
end
% Remove any hidden .resistivity files (these are sometimes introduced by
% CyberDuck, not sure why....
bKeep = logical(1:length(files));
for i = 1:length(files)
    if files(i).name(1) =='.'
        bKeep(i) = false;
    end
end
files = files(bKeep);

% Now sort them by date:
for i = 1:length(files)
    files(i).date = datenum(files(i).date);
end
[temp, isort] = sort([files.date]);
isort = fliplr(isort); % descending order

[p,f,e] = fileparts(st.resistivityFile);
fplotted = strcat(f,e);

% Add submenus if too many files to be shown on screen:
nLimit = 40;
if length(isort) > nLimit
    
    nSubMenus = ceil(length(isort)/nLimit);
    
    parent = m40;
 
    icnt = 0;
    
    for i = 1:length(isort)
        
        
        icnt = icnt + 1;
        if icnt > nLimit
            icnt = 0;
            parent =  uimenu( m40, 'Label', 'Additional files:');
        end
        fname = files(isort(i)).name;
        schk = 'off';
        if strcmp(fname,fplotted)
            schk = 'on';
        end
        m41 = uimenu( parent, 'Label', fname, 'checked',schk ...
                    , 'callback', {@chgIter, fname, hFig} );
    end
                
  
    
else
    
    for i = 1:length(isort)
        fname = files(isort(i)).name;
        schk = 'off';
        if strcmp(fname,fplotted)
            schk = 'on';
        end
        m41 = uimenu( m40, 'Label', fname, 'checked',schk ...
                    , 'callback', {@chgIter, fname, hFig} );
    end
    
end

m41 = uimenu( m40, 'separator','on','Label', 'Iteration Misfit Plot' ...
            , 'callback', {@plotMARE2DEMIterMisfit , hFig});
        
m42 = uimenu( m40, 'Label', 'Iteration Movie' ...
            , 'callback', {@makeIterationMove, hFig} );

end % IterationMenuDrop

%--------------------------------------------------------------------------
function ResponseMenuDrop(~,~,hFig)

m2 = findobj(hFig,'tag','responsemenu');
delete(get(m2,'children'));

st = get(hFig,'userdata');

% See if there's any MT data, if not skip:
if isfield(st.stCSEM,'receivers')
    uimenu( m2, 'Label', 'CSEM', 'callback', {@plotResponsesCSEM, hFig} );
end
if isfield(st.stMT,'receivers')
    uimenu( m2, 'Label', 'MT', 'callback', {@plotResponsesMT, hFig} );
end
 

end
%--------------------------------------------------------------------------
function SensitivityMenuDrop(~,~,hFig)

m40 = findobj(hFig,'tag','sensitivitymenu');

delete(get(m40,'children'));

st = get(hFig,'userdata');
if ~isempty(st.directory)
    str = sprintf('%s/*.sensitivity',st.directory);
else
    str = '*.sensitivity';
end
files = dir(str);
if isempty(files)
    return;
end
% Remove any hidden .resistivity files (these are sometimes introduced by
% CyberDuck, not sure why....
bKeep = logical(1:length(files));
for i = 1:length(files)
    if files(i).name(1) =='.'
        bKeep(i) = false;
    end
end
files = files(bKeep);

% Now sort them by date:
for i = 1:length(files)
    files(i).date = datenum(files(i).date);
end
[temp, isort] = sort([files.date]);
isort = fliplr(isort); % descending order

for i = 1:length(isort)
    fname = files(isort(i)).name;
    m41 = uimenu( m40, 'Label', fname ...
                , 'callback', {@plotWJ, hFig, fullfile(st.directory,fname) } );
end
 

end % SensitivityMenuDrop

%--------------------------------------------------------------------------
% Stub to call back through the main plot routine with a new iteration and
% without the two weirdo callback params.
function chgComponent(hObject,~,hFig,icmp)
   
    st = get(hFig,'userdata');
    st.icmp = icmp;
    set(hFig,'userdata',st);
    
    set(findobj(hFig,'tag','rho_cmps'),'checked','off');
    set(hObject,'checked','on');
 
    plotRhoXYZ([],[],hFig);
 
    
end

 
 
%--------------------------------------------------------------------------
% Stub to call back through the main plot routine with a new iteration and
% without the two weirdo callback params.
function chgIter(~,~,sIter,hFig)
    plotMARE2DEM( 'newiter', sIter, hFig );
end

%--------------------------------------------------------------------------
function makeIterationMove(~,~,hFig)

% Get list of files in acending order:
st = get(hFig,'userdata');
if ~isempty(st.directory)
    str = sprintf('%s/*.resistivity',st.directory);
else
    str = '*.resistivity';
end
files = dir(str);
if isempty(files)
    return;
end

% Now sort them by date:
for i = 1:length(files)
    files(i).date = datenum(files(i).date);
end
[temp, isort] = sort([files.date]);


% Ask for output filename:
[fP,fF] = fileparts(files(1).name);
[fP,fF] = fileparts(fF);
[sF,sP] = uiputfile( {'*.mp4', '.mp4 file'; '*','All Files'} ...
                   , 'Pick an output file', fF);
               
if isempty(sF) || all(sF == 0)
   return
end
if ~ischar(sF)
    sSaveFile = [];
else
    sSaveFile = fullfile( sP, sF );
end
   
 set(hFig, 'Pointer', 'watch' );   drawnow

% Initialize the movie figure:
 
if ~isempty(sSaveFile)
  
     set(hFig,'DoubleBuffer','on');
     set(hFig,'renderer','zbuffer')

    % Use Matlab's newer movie capture method:
    vidObj = VideoWriter(sSaveFile,'MPEG-4');
    vidObj.FrameRate = 2;
    vidObj.Quality = 100;
    open(vidObj);

end

for i = 1:length(isort)
    fname = files(isort(i)).name;
    plotMARE2DEM( 'newiter', fname, hFig );

    if ~isempty(sSaveFile)
        F = getframe(hFig);
        writeVideo(vidObj,F);
        delete(findobj('tag','arrow'))
    end


end % loop over time
if ~isempty(sSaveFile)
    close(vidObj);
end 
    
 h = helpdlg(sprintf('Done saving image to file  %s', sSaveFile),'plotMARE2DEM Message:');
    set(h,'windowstyle','modal');
    uiwait(h)  
    
set(hFig, 'Pointer', 'arrow' );    

end

%--------------------------------------------------------------------------
% menu callback to change the visibility of free or fixed model regions
function chgShowUTM(hObject,~,hFig)

stSettings = getappdata(hFig,'stSettings');

if strcmpi(stSettings.showUTM,'on')
    stSettings.showUTM = 'off';
    set(hObject,'checked','off');
else
    stSettings.showUTM = 'on';
    set(hObject,'checked','on');
end

setappdata(hFig,'stSettings',stSettings);

% Save new MRU file:
sub_saveMRU(stSettings,hFig);

zoom_updateAxes([],[]);

end
 
%--------------------------------------------------------------------------
function sub_gridLines(hObject,~,hFig)

if strcmpi(get(hObject,'checked'),'on')
    set(hObject,'checked','off');
    grid off;
else
    set(hObject,'checked','on');
    grid on;
end
 

end

%--------------------------------------------------------------------------
% menu callback to change the visibility of free or fixed model regions
function chgShowTitle(hObject,~,hFig,sTag)

stSettings = getappdata(hFig,'stSettings');

if strcmpi(stSettings.showTitle,'on')
    stSettings.showTitle = 'off';
    set(hObject,'checked','off');
    set(findobj(hFig,'tag',sTag),'visible','off');
else
    stSettings.showTitle = 'on';
    set(hObject,'checked','on');
    set(findobj(hFig,'tag',sTag),'visible','on');
end

setappdata(hFig,'stSettings',stSettings);
 
% Save new MRU file:
sub_saveMRU(stSettings,hFig);


end
%--------------------------------------------------------------------------
% menu callback to change the visibility of free or fixed model regions
function chgRgnVis(hObject,~,hFig,sWhat)

stSettings = getappdata(hFig,'stSettings');

switch sWhat
    case 'free'
        if strcmpi(stSettings.showFree,'on')
            stSettings.showFree = 'off';
            set(findobj(hFig,'tag','free'),'visible',stSettings.showFree);
            set(findobj(hFig,'tag','free_fixedmask'),'visible',stSettings.showFree);
            set(hObject,'checked','off');
 
        else
            stSettings.showFree = 'on';
            set(findobj(hFig,'tag','free'),'visible',stSettings.showFree);
            set(findobj(hFig,'tag','free_fixedmask'),'visible',stSettings.showFree);
            set(hObject,'checked','on');
        end
    case 'fixed'
        if strcmpi(stSettings.showFixed,'on')
            stSettings.showFixed = 'off';
            set(findobj(hFig,'tag','fixed'),'visible',stSettings.showFixed);
            set(findobj(hFig,'tag','free_fixedmask'),'visible','on'); % turn off so fixed can be seen
            set(hObject,'checked','off');
        else
            stSettings.showFixed = 'on';
            set(findobj(hFig,'tag','fixed'),'visible',stSettings.showFixed);
            set(findobj(hFig,'tag','free_fixedmask'),'visible','off');  % turn off so any interpolated free params don't bleed
            set(hObject,'checked','on');
        end
end

setappdata(hFig,'stSettings',stSettings);
 
% Save new MRU file:
sub_saveMRU(stSettings,hFig);

end
%--------------------------------------------------------------------------
% Menu callback function to change the visibility of some tagged items
function chgVisCheck(hObject,~, hFig, sTag)

st          = get(hFig,'userdata');
stSettings  = getappdata(hFig,'stSettings');

if isfield(st,'hax2') && ~isempty(st.hax2)
    set(st.hax2,'handlevisibility','on')
end   
    
hTag = findobj( hFig, 'tag', sTag);
check = get(hObject,'checked');

switch check
    case 'on'
        set(hTag , 'visible', 'off' );
        set(hObject,'checked','off');
        if ~isempty(hObject.Tag)
            stSettings.(hObject.Tag) = 'off';
        end
    case 'off'
        set(hTag , 'visible', 'on' );
        set(hObject,'checked','on');
        if ~isempty(hObject.Tag)
            stSettings.(hObject.Tag) = 'on';
        end
end

if isfield(st,'hax2') && ~isempty(st.hax2)
    set(st.hax2,'handlevisibility','off')
end   

setappdata(hFig,'stSettings',stSettings);
sub_saveMRU(stSettings,hFig);

end

%--------------------------------------------------------------------------
% Menu callback function to change the visibility of some tagged items
function chgVis(~,~, hFig, sTag, sState)
    set( findobj( hFig, 'tag', sTag ), 'visible', sState );
end

%--------------------------------------------------------------------------
function showNames(hObject,~, hFig, sTag)

hTag = findobj( hFig, 'tag', sTag,'type','text' );

stSettings  = getappdata(hFig,'stSettings');

if ~isempty(hTag)
 
    sState = get(hTag, 'visible' );
    if strcmpi(sState,'on')
        delete(hTag); %set(hTag,'visible','off')
        set(hObject,'checked','off')
    else
        set(hTag,'visible','on')
        set(hObject,'checked','on')           
    end

else % don't exist yet
    
    % plot them:
        
    st = get(hFig,'userdata');
     
    switch sTag

         case 'csemRxNames'

             % Plot sites:
            if ~isempty(st.stCSEM) && isfield(st.stCSEM,'receivers')
                co = stSettings.fontcolorRxCSEM;
                fs = stSettings.fontsizeRxCSEM;
                hRxNames = text(st.stCSEM.receivers(:,2),st.stCSEM.receivers(:,3),st.stCSEM.receiverName,...
                    'tag',sTag,'HorizontalAlignment','center','VerticalAlignment','bottom',...
                    'visible','on','fontsize',fs,'color',co,'Interpreter','none','clipping','on');

            end
            % Make the default text alignment be vertical, using special routine that adds leading spaces:
            chgTxtRotVert([],[],hFig,sTag);

        case 'mtRxNames'

            if ~isempty(st.stMT) && isfield(st.stMT,'receivers')
                co = stSettings.fontcolorRxMT;
                fs = stSettings.fontsizeRxMT;
                hRxNames = text(st.stMT.receivers(:,2),st.stMT.receivers(:,3),st.stMT.receiverName,...
                    'tag',sTag,'HorizontalAlignment','center','VerticalAlignment','bottom',...
                    'visible','on','fontsize',fs,'color',co,'Interpreter','none','clipping','on');
            end
            % Make the default text alignment be vertical, using special routine that adds leading spaces:
            chgTxtRotVert([],[],hFig,sTag);


         case 'txNames'


            % Plot transmitters:
            if ~isempty( st.stCSEM) && isfield(st.stCSEM,'transmitters')
                co = stSettings.fontcolorTx;
                fs = stSettings.fontsizeTx;
                hTxNames = text(st.stCSEM.transmitters(:,2),st.stCSEM.transmitters(:,3),st.stCSEM.transmitterName,...
                    'tag',sTag,'HorizontalAlignment','center','VerticalAlignment','bottom','visible','on',...
                    'fontsize',fs,'color',co,'Interpreter','none','clipping','on');

            end
             % Make the default text alignment be vertical, using special routine that adds leading spaces:
            chgTxtRotVert([],[],hFig,sTag);
    end       
 
    set(hObject,'checked','on')        
        
end

sub_uistack(hFig);
 
end


function sub_uistack(hFig)

% Stacks plot objects correctly:

% shading goes to bottom layer:
uistack(findobj(hFig,'tag','fixed'),'bottom');
uistack(findobj(hFig,'tag','free_fixedmask'),'bottom');
uistack(findobj(hFig,'tag','freecut'),'bottom');
uistack(findobj(hFig,'tag','free'),'bottom');

% then transparency masks:


% image overlays:
uistack(findobj(hFig,'tag','segy'),'top');
uistack(findobj(hFig,'tag','geoimage'),'top');

% line overlays etc:

uistack(findobj(hFig,'tag','SensitivityContours'),'top');
uistack(findobj(hFig,'tag','ResistivityContours'),'top');

uistack(findobj(hFig,'tag','femesh'),'top');
uistack(findobj(hFig,'tag','segments'),'top');
uistack(findobj(hFig,'tag','polygons'),'top');
uistack(findobj(hFig,'tag','lines'),'top');
uistack(findobj(hFig,'tag','pointdata'),'top');
uistack(findobj(hFig,'tag','penalties'),'top');


% stations etc:
uistack(findobj(hFig,'tag','csemsites'),'top');
uistack(findobj(hFig,'tag','mtsites'),'top');
uistack(findobj(hFig,'tag','transmitters'),'top');
uistack(findobj(hFig,'tag','dc_electrodes'),'top');
uistack(findobj(hFig,'tag','csemRxNames'),'top');
uistack(findobj(hFig,'tag','mtRxNames'),'top');
uistack(findobj(hFig,'tag','txNames'),'top');
uistack(findobj(hFig,'tag','welllog'),'top');
uistack(findobj(hFig,'tag','welllogname'),'top');

end

%--------------------------------------------------------------------------
% Menu callback function to change the rotation of some text items
function chgTxtRotHorz(~,~,hFig,sTag)

    hObjs = findobj( hFig, 'tag',sTag );
    if isempty(hObjs)
        return
    end
    set( hObjs,'rotation', 0,'HorizontalAlignment','center','VerticalAlignment','bottom');
     
    % remove leading spaces, if any:
    for i = 1:length(hObjs)
        str = get(hObjs(i),'string');
        set(hObjs(i),'string',sprintf('%s',strtrim(str)));
    end
        
    
end
function chgTxtRotVert(~,~, hFig,sTag)

    hObjs = findobj( hFig, 'tag',sTag );
    if isempty(hObjs)
        return
    end
    set( hObjs,  'rotation', 90,'HorizontalAlignment','left','VerticalAlignment','middle' );
 
    % add 4 leading spaces so text is above marker:     
    for i = 1:length(hObjs)
        str = get(hObjs(i),'string');
        str = sprintf('   %s',str);
        set(hObjs(i),'string',str);
    end
 
        
end


%--------------------------------------------------------------------------
% Menu callback function to delete some tagged items
function delByTag(~,~, hFig, sTag)
if iscell(sTag)
    cTag = sTag;
    nT = length(cTag);
else
    nT = 1;
    cTag = {sTag};
end
    
for i = 1:nT
    sTag = cTag{i};
    delete( findobj( hFig, 'tag', sTag ) );
    if strcmpi(sTag,'segy')
        st = get(hFig,'userdata');
        st.SEGY = [];
        set(hFig,'userdata',st);
        delete(findobj('tag','sliderFig'));
    end
end

end
%--------------------------------------------------------------------------
function delPointData(~,~, hFig)
    st = get(hFig,'userdata');
    if isfield(st,'hax2') && ~isempty(st.hax2)
        set(st.hax2,'handlevisibility','on')
        delete( findobj( hFig, 'tag', 'pointdata' ) );
        delete( findobj( hFig, 'tag', 'hax2_colorbar' ) );
        delete( st.hax2 );
        st = rmfield(st,'hax2');
        set(hFig,'userdata',st);
    end
end
%--------------------------------------------------------------------------
function sub_addColorSubMenus(mParent,hFig,sField,sTag,sProp)

stSettings  = getappdata(hFig,'stSettings');

sColors = {
    'white' 'w';
    'black' 'k';
    'red' 'r';
    'green' 'g';
    'blue' 'b';
    'magenta' 'm'
    'cyan' 'c'
    'gray' [.5 .5 .5]
    };
for i = 1:size(sColors,1)
    uimenu(mParent,'Label',sColors{i,1},'callback', {@recolorByTag, hFig, sField,sTag, sProp, sColors{i,2}} );  
end

end


%--------------------------------------------------------------------------
% Menu callback function to re-color a property of some tagged items
function recolorByTag(~,~, hFig,sField, sTag, sProp, sColor )
 
    stSettings  = getappdata(hFig,'stSettings');
    
    st = get(hFig,'userdata');
    if isfield(st,'hax2') && ~isempty(st.hax2)
        set(st.hax2,'handlevisibility','on')
    end   
    
    
    stSettings.(sField) = sColor;
    
    setappdata(hFig,'stSettings',stSettings);
    
    % Save new MRU file:
    sub_saveMRU(stSettings,hFig);
   
    % now color them:  
    hObjs = findobj( hFig, 'tag', sTag );
    for i = 1:length(hObjs)
        if isprop(hObjs(i),sProp)
            set( hObjs(i), sProp,sColor);
           % set( hObjs(i), 'color',sColor); % kludge...
        else
            set( hObjs(i), 'EdgeColor',sColor); % kludge...
        end
    end
    
    if isfield(st,'hax2') && ~isempty(st.hax2)
        set(st.hax2,'handlevisibility','off')
    end  
    
end


%--------------------------------------------------------------------------
function sub_addMarkerSubMenus(mParent,hFig,sField,sTag,sProp)

stSettings  = getappdata(hFig,'stSettings');

sMarker = {
    'o' 
    's' 
    'd'
    'v'
    '^'
    '<'
    '>'
    };
for i = 1:size(sMarker,1)
    uimenu(mParent,'Label',sMarker{i},'callback', {@setMarker, hFig, sField,sTag, sProp, sMarker{i}} );  
end

end

%--------------------------------------------------------------------------
% Menu callback function to re-color a property of some tagged items
function setMarker(~,~, hFig,sField, sTag, sProp, sMarker )
 
    stSettings  = getappdata(hFig,'stSettings');
    
    stSettings.(sField) = sMarker;
    
    setappdata(hFig,'stSettings',stSettings);
    
    % Save new MRU file:
    sub_saveMRU(stSettings,hFig);
   
    st = get(hFig,'userdata');
    if isfield(st,'hax2') && ~isempty(st.hax2)
       set(st.hax2,'handlevisibility','on')
    end
    
    % now color them:  
    hObjs = findobj( hFig, 'tag', sTag );
    for i = 1:length(hObjs)
        if isprop(hObjs(i),sProp)
            set( hObjs(i), sProp,sMarker);
        else
            set( hObjs(i), 'marker',sMarker); % kludge...
        end
    end

    if isfield(st,'hax2') && ~isempty(st.hax2)
       set(st.hax2,'handlevisibility','off')
    end
    
end

%--------------------------------------------------------------------------
function setFigProperty(~,~,hFig,sTag,sField,sProp)

    stSettings  = getappdata(hFig,'stSettings');
    st = get(hFig,'userdata');
    if isfield(st,'hax2') && ~isempty(st.hax2)
        set(st.hax2,'handlevisibility','on')
    end
    
    prompt = sprintf('Enter %s:',sProp);
    dlg_title = 'plotMARE2DEM: ';
    num_lines = 1;
    def = {num2str(stSettings.(sField))};
    answer = inputdlg(prompt,dlg_title,num_lines,def);
    if isempty(answer)
        return
    end
    
    stSettings.(sField) = str2double(answer{1});   
        
    setappdata(hFig,'stSettings',stSettings);

    sub_saveMRU(stSettings,hFig);

    % now apply them:  
    hObjs = findobj( hFig, 'tag', sTag );
    for i = 1:length(hObjs)
        set( hObjs(i), sProp,stSettings.(sField));  
    end
    
    if isfield(st,'hax2') && ~isempty(st.hax2)
        set(st.hax2,'handlevisibility','off')
    end
    
end

%--------------------------------------------------------------------------
% Menu callback function to rescale axis text & various fonts on the plot
function setFontSize(~,~,hFig)

    stSettings  = getappdata(hFig,'stSettings');
    
    prompt = sprintf('Enter font size:');
    dlg_title = 'plotMARE2DEM:';
    num_lines = 1;
    def = {num2str(stSettings.fontSize)};
    answer = inputdlg(prompt,dlg_title,num_lines,def);
    if isempty(answer)
        return
    end
    
    stSettings.fontSize = str2double(answer{1});   
    set( gca, 'fontsize', stSettings.fontSize  );
    
    hTexts  = findobj(hFig,'tag','text','-or','tag','cb_text','-or','tag','xticks');
    set( hTexts, 'fontsize', stSettings.fontSize ); 
 
    hCb = findobj(hFig,'tag','Colorbar');
    yl = get(hCb,'ylabel');
    set( yl, 'fontsize', stSettings.fontSize );
    set(get(hCb,'title'),'fontsize',stSettings.fontSize*.9)
    
    setappdata(hFig,'stSettings',stSettings);

    sub_saveMRU(stSettings,hFig);

end

%--------------------------------------------------------------------------
% Menu callback function to rescale axis text & various fonts on the plot
function setFontSizeRxTx(~,~,hFig,sField,sTag)

    stSettings  = getappdata(hFig,'stSettings');
    
    prompt = sprintf('Enter font size:');
    dlg_title = 'plotMARE2DEM: ';
    num_lines = 1;
    def = {num2str(stSettings.(sField))};
    answer = inputdlg(prompt,dlg_title,num_lines,def);
    if isempty(answer)
        return
    end
    
    stSettings.(sField) = str2double(answer{1});   
    set( findobj(hFig,'tag',sTag), 'fontsize', stSettings.(sField)  );
    
    setappdata(hFig,'stSettings',stSettings);

    sub_saveMRU(stSettings,hFig);

end

%--------------------------------------------------------------------------
function plotResponsesCSEM(~,~,hFig)

st = get(hFig,'userdata');
[p, n ] = fileparts(st.resistivityFile);

sResponseFile =  fullfile(st.directory,strcat(n,'.resp'));
if ~exist(sResponseFile,'file') % plot data file isntead
   sResponseFile =  fullfile(st.directory,st.dataFile); 
end
plotMARE2DEM_CSEM(sResponseFile);
end

%--------------------------------------------------------------------------
function plotResponsesMT(~,~,hFig)

st = get(hFig,'userdata');
[p, n ] = fileparts(st.resistivityFile);

sResponseFile =  fullfile(st.directory,strcat(n,'.resp'));
if ~exist(sResponseFile,'file') % plot data file instead
   sResponseFile =  fullfile(st.directory,st.dataFile); 
end
plotMARE2DEM_MT(sResponseFile);

end

%--------------------------------------------------------------------------
function plotSurveyMap(~,~,hFig,sType)

 
st = get(hFig,'userdata');

% Call external routine:
plotMARE2DEM_SurveyLayout(sType,st);

 
end

%--------------------------------------------------------------------------
function importSEGY(~,~,hFig)

st = get(hFig,'userdata');

% Ask for the SEGY file:
[ff, pp] = uigetfile('*.segy;*.sgy', 'Select  a Depth Migrated SEGY File (.segy,.sgy):');

if ff <= 0
    return
end
sFile  = fullfile(pp,ff);

set(hFig, 'Pointer', 'watch' );
drawnow;
        
% read in Segy file:
st.SEGY.sFile = sFile;
[st.SEGY.Data,st.SEGY.SegyTraceHeaders,st.SEGY.SegyHeader]=ReadSegy(sFile);

% store data in fig:
set(hFig,'userdata',st);

% make slider menu figure:
segyMenu(hFig);

% Call rescaling and plotting routine:
%rescaleSEGY([],[],hFig);

set(hFig, 'Pointer', 'arrow' );


end

function segyMenu(hFig)

% Create UI figure with three sliders (contrast, brightness, transparency):
%%
hSliderFig = figure('menubar','none','name','SEGY Settings','tag','sliderFig');
pos = get(hSliderFig,'position');
fWidth = 400;
fHeight= 500;

dx = 40;
hOffset = 20;
vOffset = 60;
v0 = 50;

st = get(hFig,'userdata');

% Set defaults if first call:
if ~isfield(st,'SEGY') || ~isfield(st.SEGY,'zScale') 
    st.SEGY.clip = nan;
    st.SEGY.posShift = 0;
    st.SEGY.zScale = 1;
    st.SEGY.xyScale = 1 ;
    st.SEGY.transpExp = 1;
    st.SEGY.bright = 0.5;
    st.SEGY.contrast = 0.5;
    % store data in fig:
    set(hFig,'userdata',st);
end

st.SEGY.posShift = 0;
st.SEGY.clip = max(abs(st.SEGY.Data(:)));

% Get input position and depth range of segy file (and project position
% onto 2D model axis):
ytrace = [st.SEGY.SegyTraceHeaders.cdpY];
xtrace = [st.SEGY.SegyTraceHeaders.cdpX];
if length(unique(ytrace))==1 
    fprintf('Warning for segy import: SEGY.SegyTraceHeaders.cdpY \n so trying SEGY.SegyTraceHeaders.SourceY! \n')
    ytrace = [st.SEGY.SegyTraceHeaders.SourceY];
    xtrace = [st.SEGY.SegyTraceHeaders.SourceX];
end
dn = (ytrace  - st.stUTM.north0);
de = (xtrace  - st.stUTM.east0 );
c = cosd(st.stUTM.theta);
s = sind(st.stUTM.theta);
R = [c s; -s c];
rotated = R*[dn; de];
x = rotated(1,:);
y = rotated(2,:);
z = [st.SEGY.SegyHeader.time];



% Display input figure:
set(hSliderFig,'position',[pos(1:2) fWidth fHeight] );
bgndColor = get(hSliderFig,'color');
 
hContrast = uicontrol('Style','slider','Min',0,'Max',1,...
                'Value',st.SEGY.contrast, 'Position',[hOffset v0+20  fWidth-40 20 ],'tag','contrast');
hContrastLabel = uicontrol('Style','text','string','Constrast', ...
                           'Position',[hOffset v0+20+vOffset/2  fWidth-40 20 ],'backgroundcolor',bgndColor);    
                           
hBright   = uicontrol('Style','slider','Min',0,'Max',1,...
                'Value',st.SEGY.bright, 'Position',[hOffset v0+20+vOffset fWidth-40 20 ],'tag','bright');
hBrightLabel = uicontrol('Style','text','string','Brightness', ...
                           'Position',[hOffset v0+20+1.5*vOffset  fWidth-40 20 ],'backgroundcolor',bgndColor);  
                       
hTrans   = uicontrol('Style','slider','Min',0,'Max',1,...
                'Value',st.SEGY.transpExp, 'Position',[hOffset v0+20+2*vOffset fWidth-40 20],'tag','trans');
hTransLabel = uicontrol('Style','text','string','Transparency', ...
                           'Position',[hOffset v0+20+2.5*vOffset  fWidth-40 20 ],'backgroundcolor',bgndColor);              

hApply = uicontrol('Style','pushbutton','string','Apply','fontsize',14, ...
                           'Position',[fWidth/2-80/2 20 60 30 ],'backgroundcolor',bgndColor,...
                           'callback',  {@rescaleSEGY, hFig, hSliderFig}); 
% inline shift and clipping:
sTip = 'SEGY data amplitudes will be limited to +- this value. Initial value is max(amplitude).';
hClipLabel   = uicontrol('Style','text','string',sprintf('Clip amplitude:'), ...
                           'Position',[hOffset v0+20+3.5*vOffset  140 20 ],'backgroundcolor',bgndColor,'tooltip',sTip);  
hClip        = uicontrol('Style','edit','string',num2str(st.SEGY.clip), ...
                           'Position',[hOffset v0+20+3.2*vOffset  140 20 ],'backgroundcolor',[1 1 1],'tag','segyclip','tooltip',sTip); 

sTip = 'Use this to manually adjust the horizontal position of the SEGY overlay.';
hShiftLabel  = uicontrol('Style','text','string','Position shift (m)', ...
                           'Position',[hOffset+fWidth/2 v0+20+3.5*vOffset  140 20 ],'backgroundcolor',bgndColor,'tooltip',sTip);     
                       
hShift       = uicontrol('Style','edit','string',num2str(st.SEGY.posShift), ...
                           'Position',[hOffset+fWidth/2 v0+20+3.2*vOffset  140 20 ],'backgroundcolor',[1 1 1],'tag','posshift','tooltip',sTip);
                       
% vert and horiz: scaling:
sTip = 'SEGY file position will be multiplied by this value';
hVScaleLabel  = uicontrol('Style','text','string','Vert. Scaling (ft to m = .3048)', ...
                           'Position',[hOffset v0+20+4.5*vOffset  140 20 ],'backgroundcolor',bgndColor,'tooltip',sTip);  
hVScale        = uicontrol('Style','edit','string',num2str(st.SEGY.zScale), ...
                           'Position',[hOffset v0+20+4.2*vOffset  140 20 ],'backgroundcolor',[1 1 1],'tag','vscale','tooltip',sTip); 
                       
hHScaleLabel  = uicontrol('Style','text','string','Horz. Scaling (ft to m = .3048)', ...
                           'Position',[hOffset+fWidth/2 v0+20+4.5*vOffset  140 20 ],'backgroundcolor',bgndColor,'tooltip',sTip);     
                       
hHScale        = uicontrol('Style','edit','string',num2str(st.SEGY.xyScale), ...
                           'Position',[hOffset+fWidth/2 v0+20+4.2*vOffset  140 20 ],'backgroundcolor',[1 1 1],'tag','hscale','tooltip',sTip);

% Display info:

ystr  = sprintf('Position: %.1f to %.1f',min(y(:)),max(y(:)));
zstr  = sprintf('Depth: %.1f to %.1f',min(z(:)),max(z(:)));
astr  = sprintf('Amplitude: %.1f to %.1f',min(st.SEGY.Data(:)),max(st.SEGY.Data(:)));
dstr  = sprintf('Array size: %i rows by %i cols',size(st.SEGY.Data));

hystr = uicontrol('Style','text','string',ystr,'Position',[hOffset v0+20+5.8*vOffset  240 20 ],'backgroundcolor',bgndColor,'HorizontalAlignment','left'); 
hzstr = uicontrol('Style','text','string',zstr,'Position',[hOffset v0+20+5.5*vOffset  240 20 ],'backgroundcolor',bgndColor,'HorizontalAlignment','left'); 
hastr = uicontrol('Style','text','string',astr,'Position',[hOffset v0+20+5.2*vOffset  240 20 ],'backgroundcolor',bgndColor,'HorizontalAlignment','left'); 
hastr = uicontrol('Style','text','string',dstr,'Position',[hOffset v0+20+4.9*vOffset  240 20 ],'backgroundcolor',bgndColor,'HorizontalAlignment','left'); 

hastr = uicontrol('Style','text','string','Input file SEGY extents:','Position',[hOffset v0+20+6.1*vOffset  240 20 ],...
'FontWeight','normal','backgroundcolor',bgndColor,'HorizontalAlignment','left');
[~,sFile,ext] = fileparts(st.SEGY.sFile);
str = sprintf('SEGY file: %s',strcat(sFile,ext));
hastr = uicontrol('Style','text','string',str,'Position',[hOffset v0+20+6.6*vOffset  300 20 ],...
    'FontWeight','bold','backgroundcolor',bgndColor,'HorizontalAlignment','left'); 
end
    
%--------------------------------------------------------------------------
function rescaleSEGY(~,~,hFig,hSliderFig)

set(hFig, 'Pointer', 'watch' );
drawnow; 

st = get(hFig,'userdata');

if ~isfield(st,'SEGY') || ~isfield(st.SEGY,'sFile') || isempty(st.SEGY.sFile)
    set(hFig, 'Pointer', 'arrow' );
    return
end

if isempty(hSliderFig) || ~ishandle(hSliderFig)
    set(hFig, 'Pointer', 'arrow' );
    segyMenu(hFig);
    return;
end
 
                         
%% Get the settings from the menu figure:
st.SEGY.clip     = str2double(get(findobj(hSliderFig,'tag','segyclip'),'string'));
st.SEGY.posShift     = str2double(get(findobj(hSliderFig,'tag','posshift'),'string'));
st.SEGY.zScale     = str2double(get(findobj(hSliderFig,'tag','vscale'),'string'));
st.SEGY.xyScale    = str2double(get(findobj(hSliderFig,'tag','hscale'),'string'));
st.SEGY.transpExp  = (get(findobj(hSliderFig,'tag','trans'),'val'));
st.SEGY.bright     = (get(findobj(hSliderFig,'tag','bright'),'val'));
st.SEGY.contrast   = (get(findobj(hSliderFig,'tag','contrast'),'val'));
%%
% Delete any previous segy plot:
delete(findobj(hFig,'tag','segy'));

% Get SEGY data:
Data = st.SEGY.Data;
z = [st.SEGY.SegyHeader.time]*st.SEGY.zScale;

% Trim data where entire row is 0:
iZeroRows = sum(Data,2)==0;

Data(iZeroRows,:) = [];
z(iZeroRows) = [];


% clip data amplitudes:
Data( Data >  st.SEGY.clip) =  st.SEGY.clip;
Data( Data < -st.SEGY.clip) = -st.SEGY.clip;


% create RGB indexes for grayscale:
% data is scaled to be between -1 and 1:

mind = min(min(Data));
maxd = max(max(abs(Data)));
 
col = Data/maxd;

delete(findobj('tag','segyhistogram'));

hF = figure('tag','segyhistogram');

ax1 = subplot(2,1,1); 
hist(col(:),31)
set(ax1,'xlim',[-1 1]);
title('Input segy data')



% if col is entirely non-negative, this could be chirp data, so remap to
% negative:
if min(col(:))>=0
    col = -col;
    % remap onto -1 to 1:
    mind = min(col(:));
    maxd = max(col(:));
    col = 2*(col-mind)./(maxd-mind) - 1;
end

% Power law contrast formula:  new = old.^c where c = 2.^(-5*m)

m = 2*st.SEGY.contrast-1; % -1 to 1
c = 2.^(-5*m); 
 
col(col>0) =     col(col>0).^c;    % apply contrast to positive values
col(col<0) = -((-col(col<0)).^c);  % apply contrast to negative values   

% Add some brightness: aka linearly translate colors along grayscale axis
b = 2*st.SEGY.bright-1; % spans -1 to 1
col = col+ b;
 
% clip colors to -1 to 1 range:
col(col>1)  =  1;
col(col<-1) = -1;


ax2 = subplot(2,1,2); 
hist(col(:),31)
set(ax2,'xlim',[-1 1]);
title('After brightness and contrast  ')


col(:,:,2)= col;
col(:,:,3)= col(:,:,2); 


% Project this onto the model axes:
% cdpX = east, cpdY = north
ytrace = [st.SEGY.SegyTraceHeaders.cdpY];
xtrace = [st.SEGY.SegyTraceHeaders.cdpX];
if length(unique(ytrace))==1 
    fprintf('Warning for segy import: SEGY.SegyTraceHeaders.cdpY \n so trying SEGY.SegyTraceHeaders.SourceY! \n')
    ytrace = [st.SEGY.SegyTraceHeaders.SourceY];
    xtrace = [st.SEGY.SegyTraceHeaders.SourceX];
end
% dn = (ytrace*st.SEGY.xyScale  - st.stUTM.north0);
% de = (xtrace*st.SEGY.xyScale  - st.stUTM.east0 );
dn = (ytrace*st.SEGY.xyScale  - st.stUTM.north0);
de = (xtrace*st.SEGY.xyScale  - st.stUTM.east0 );

c = cosd(st.stUTM.theta);
s = sind(st.stUTM.theta);
R = [c s; -s c];
rotated = R*[dn; de];
x = rotated(1,:);
y = rotated(2,:) + st.SEGY.posShift;


% add it to the MARE2DEM plot:

figure(hFig);
hss = imagesc(y,z,col);
 
% make it transparent:
set(hss,'AlphaData',((-col(:,:,1)+1)/2).^(st.SEGY.transpExp*2))
 

set(hss,'tag','segy');

sub_uistack(hFig);


set(hFig,'userdata',st);

set(hFig, 'Pointer', 'arrow' );

end

%--------------------------------------------------------------------------
% DGM 5/4/2015 - import a geo-image overlay a la Mamba2D
function importGeoImage(~,~,hFig)
    % Ask for geoimage graphics file:
    [sF, sP] = uigetfile( '*.jpg;*.png;*.tiff;*.tif','Select geoimage figure file (.jpg, .png, .tiff files)');
    if sF==0
        return
    end
    sFile = fullfile(sP,sF);
    clear sP sF
    
    % Read in image file:
    A = imread(sFile);
    
    % See if there is a .geocoord file for the image:
    [sP,sF,sX] = fileparts(sFile);
    sGfile = fullfile(sP,strcat(sF,'.geocoord'));
    try
        gc = load(sGfile);
        if numel(gc) == 6   % top, bott, left(e,n), right(e,n)
            y0 = gc(1);y1 = gc(2);x0 = gc(3:4);x1 = gc(5:6);
        else
            y0 = gc(1);y1 = gc(2);x0 = gc(3);x1 = gc(4);
        end
    catch Me
        % Get geo-coordinates of figure:
        t1 = sprintf('Input coordinates:\n Top');
        prompt = {t1,'Bottom:','Left: ','Right'};
        dlg_title = 'Geoimage';
        num_lines= 1;
        answer = inputdlg(prompt,dlg_title,num_lines);
        if isempty(answer)
            return;
        end
        y0 = str2double(answer{1});
        y1 = str2double(answer{2});
        x0 = str2double(answer{3});
        x1 = str2double(answer{4});
    end

    % If E,N are given for left & right, then these are UTM and need to be
    % translated into local coords. Use the given datafile for that...
    st = get( hFig, 'UserData' );
    if numel(x0) == 2 && numel(x1) == 2
        dn = ([x0(2) x1(2)] - st.stUTM.north0);
        de = ([x0(1) x1(1)] - st.stUTM.east0 );
        c = cosd(st.stUTM.theta);
        s = sind(st.stUTM.theta);
        R = [c s; -s c];
        rotated = R*[dn; de];
        y = sort(rotated(2,:));
        x0 = y(1);
        x1 = y(2);
    end
    
    % Delete any previous geoimage
    delete(findobj(hFig,'tag','geoimage'));
    
    % Put the image up
    hgeo = image( [x0 x1], [y0 y1], A );  % make sure it's in km not m
    set(hgeo,'tag','geoimage');
    set(hgeo,'alphadatamapping','none');
    alpha(hgeo,0.5);
    
    % Make sure things are stacked properly on top of one another
    
    sub_uistack(hFig);
    
 
    return;
end % importGeoImage

%--------------------------------------------------------------------------
% Show/hide the geo-image transparency slider. DGM 5/4/2015
function showGeoTransp(~,~,hFig)
    hSlider = findobj( hFig, 'tag', 'geoslider' );
    if ~isempty(hSlider)
        delete(hSlider);
        return;
    end
    hGeo = findobj( hFig, 'tag', 'geoimage' );
    if isempty(hGeo)
        beep;
        return;
    end
    
    hSlider = uicontrol( 'Parent', hFig, 'Style', 'slider' ...
        , 'Units', 'pixels', 'Position', [0 0 200 25] ...
        , 'Min', 0, 'Max', 1, 'SliderStep', [0.01 0.1] ...
        , 'Value', get(hGeo,'AlphaData') ...
        , 'tag', 'geoslider', 'BusyAction', 'cancel', 'Interruptible', 'off' ...
        , 'Callback', {@setGeoTransp,hSlider,hGeo} ...
        );
    return;
end % showGeoTransp

%--------------------------------------------------------------------------
% Manage change from the geo-image transparency slider control
function setGeoTransp(hSlider,~,~,hGeo)
    if isempty(hSlider) || ~ishandle(hSlider)
        return;
    end
    if isempty(hSlider) || ~ishandle(hGeo)
        delete(hSlider);
        return;
    end
    
    alpha( hGeo, get( hSlider, 'Value' ) );
    return;
end % setGeoTransp

%--------------------------------------------------------------------------
function importPointData(~,~,hFig)

st = get(hFig,'userdata');
stSettings = getappdata(hFig,'stSettings');
 

% Ask for the point data file:
[ff, pp] = uigetfile('*.*', 'Select a point data text file(s) (list of <easting,northing,depth,value>):', 'MultiSelect', 'on');

if length(ff) == 1 && ff <= 0
    return
end
if ~iscell(ff)
    ff = {ff};
end
for iwell = 1:length(ff)
    
    sFile  = fullfile(pp,ff{iwell});
    
    data = load(sFile);

    if isempty(data) || size(data,2) < 4
        uiwait( errordlg( {
        'Error importing data file. Need to have four columns of <easting,northing,depth,value>'
        }, 'Load Point Data', 'modal' ) );
        return
    end
    stWell(iwell).data = data; 

     
end


% Ask for title string and units label, but only if this is the first call:

if isfield(st,'hax2') && ~isempty(st.hax2)
    set(st.hax2,'handlevisibility','on')
    cb2 =  findobj(hFig,'tag','hax2_colorbar');
    hTitle = get(cb2,'title');
    sval = get(hTitle,'string'); 
    %sval = str{:};
    hUnit = get(cb2,'ylabel');
    sunit = get(hUnit,'string');  
    %sunit = str{:};
else 
    options.Resize='on';
    str = {'Point Data Title:' 'Point Data Units:' };
    defaultanswer ={' ' ,' ' };
    stitle = 'Load Point Data:';        
    answer = inputdlg(str,stitle, [1, length(stitle)+22],defaultanswer,options);

    if isempty(answer)
        return
    end
    sval    = (answer{1});
    sunit   = (answer{2});

end

for iwell = 1:length(ff)

    data = stWell(iwell).data;
    
    % Extract data:
    easting     = data(:,1);
    northing    = data(:,2);
    z           = data(:,3);
    value       = data(:,4);

    % project to easting, northing to model coordinate system:
    % Project this onto the model axes:
    % cdpX = east, cpdY = north
    dn = (northing - st.stUTM.north0)';
    de = (easting  - st.stUTM.east0)';
    c = cosd(st.stUTM.theta);
    s = sind(st.stUTM.theta);
    R = [c s; -s c];
    rotated = R*[dn; de];
    x = rotated(1,:);
    y = rotated(2,:);


    % Make axes2 if it doesn't exist already:
    ax1pos = get(st.axes,'position');

    if ~isfield(st,'hax2') || isempty(st.hax2)

        st.hax2 = axes('position',ax1pos);

        xl = get(st.axes,'xlim');
        yl = get(st.axes,'ylim');
        xdir = get(st.axes,'xdir');
        ydir = get(st.axes,'ydir');
        set(st.hax2,'xlim',xl,'ylim',yl,'xdir',xdir,'ydir',ydir,'xtick',[],'ytick',[],'visible','off');

        % By default, copy over the main axes colormap:
        cm = colormap(st.axes);
        colormap(st.hax2,cm);

        cb2pos = [.95 ax1pos(2) .01 ax1pos(4)];
        cb2 = colorbar(st.hax2,'Position',cb2pos,'tag','hax2_colorbar','handlevisibility','on');
        set(get(cb2,'ylabel'),'string',sunit,'tag','pointDataUnits','handlevisibility','on','fontsize',stSettings.fontSize)

        set(get(cb2,'title'),'string',sval,'fontweight','bold',...
        'fontsize',stSettings.fontSize*.9,'tag','pointDataTitle','HorizontalAlignment','center','handlevisibility','on')

        hold(st.hax2,'on');

    end

    % Add markers to the plot on hax2:
    hdots = scatter(st.hax2,y,z,stSettings.pointDataMarkerSize,value,'filled',stSettings.pointDataMarker);
    set(hdots,'markeredgecolor',stSettings.pointDataMarkerEdgeColor,'tag','pointdata','handlevisibility','on');  
    
    % Add names:
    [p,sName,e] = fileparts(ff{iwell});
    hpdn = text(y(1),z(1),sName,'tag','pointdataname','interpreter','none');
    if strcmpi(stSettings.showPointDataNames,'off')
        set(hpdn,'visible','off')
    end
    

end
% Adjust visibility of axes and its handle:
st.hax2.HandleVisibility = 'off';
 
% Don't forget to store this back into the user data:
set(hFig,'userdata',st);
 
end

%--------------------------------------------------------------------------
function sub_setTitlePointData(~,~,hFig)

st = get(hFig,'userdata');

if isfield(st,'hax2') && ~isempty(st.hax2)
    set(st.hax2,'handlevisibility','on')
    cb2 =  findobj(hFig,'tag','hax2_colorbar');
    hTitle = get(cb2,'title');
    str = get(hTitle,'string');  
    prompt = sprintf('Enter title string');
    dlg_title = 'plotMARE2DEM: ';
    num_lines = 1;
    def = {str};
    answer = inputdlg(prompt,dlg_title,num_lines,def);
    if isempty(answer)
        set(st.hax2,'handlevisibility','off')
        return
    end
    set(hTitle,'string',answer)
    set(st.hax2,'handlevisibility','off')
end

end
%--------------------------------------------------------------------------
function sub_setUnitsPointData(~,~,hFig)
st = get(hFig,'userdata');

if isfield(st,'hax2') && ~isempty(st.hax2)
    set(st.hax2,'handlevisibility','on')
    cb2 =  findobj(hFig,'tag','hax2_colorbar');
    hUnit = get(cb2,'ylabel');
    str = get(hUnit,'string');  
    prompt = sprintf('Enter unit string');
    dlg_title = 'plotMARE2DEM: ';
    num_lines = 1;
    def = {str};
    answer = inputdlg(prompt,dlg_title,num_lines,def);
    if isempty(answer)
        set(st.hax2,'handlevisibility','off')
        return
    end
    set(hUnit,'string',answer)
    set(st.hax2,'handlevisibility','off')
end

end


%--------------------------------------------------------------------------
function importWellLog(~,~,hFig)

st          = get(hFig,'userdata');
stSettings  = getappdata(hFig,'stSettings');

% Ask for the Well Log file: 

[ff, pp] = uigetfile('*.*', 'Select well log files (list of <easting,northing,depth,value>):', 'MultiSelect', 'on');

if length(ff) == 1 && ff <= 0
    return
end

% Averaging or Resistivity-Thickness Dialog:

prompt={'Bin size (m), 0 = none:','Plot log10: (0=no)','Relative Width:'};
name='Well log options';
numlines=1;
defaultanswer={'0','0','0.05'};
answer=inputdlg(prompt,name,numlines,defaultanswer);
nBin = str2double(answer{1});
lPlotLog10  = str2double(answer{2});
frac  = str2double(answer{3});
if ~iscell(ff)
    a =ff;
    clear ff;
    ff{1} = a;
end

clear stw
maxrange = 0;
for iwell = 1:length(ff)
    
    sFile  = fullfile(pp,ff{iwell});
    
    try
        wellLog = load(sFile);
        [p,sName,e] = fileparts(sFile);
    catch
        % read in log file:
        fid = fopen(sFile,'r');
        sName = fgets(fid);
        sFormat = fgets(fid);
        [tok, rem] = strtok(sFormat);
        [tok, rem] = strtok(rem); %#ok<*STTOK>
        [tok, rem] = strtok(rem);
        [tok, rem] = strtok(rem);
        if strcmpi(tok,'rt') || strcmpi(tok,'ao90')
            n = 4;
        else
            n = 5; % must be Rh Rv
        end
        % Fast read: fails on poor input files:
        % wellLog = fscanf(fid,'%f',[4 inf]);
        % So we use the slow careful read:
        wellLog = zeros(20000,n);
        icnt = 0;
        while ~feof(fid)
            str = fgets(fid); % get a line at a time and decode
            line = sscanf(str,'%f',n);
            if numel(line) ~= n
                break
            end
            icnt = icnt+1;
            wellLog(icnt,:) = line;
        end
        wellLog = wellLog(1:icnt,:);
        fclose(fid);
    end
    
    
    % Project this onto the model axes:
    % wellLog(:,1) = east, wellLog(:,2) = north
    dn = (wellLog(:,2) - st.stUTM.north0);
    de = (wellLog(:,1) - st.stUTM.east0 );
    c = cosd(st.stUTM.theta);
    s = sind(st.stUTM.theta);
    R = [c s; -s c];
    rotated = R*[dn'; de'];
    x = rotated(1,:)';
    y = rotated(2,:)';
    z = wellLog(:,3);
    
    rho = wellLog(:,4); % kwk debug: need to add special case for Rh,Rv logs...
    rho(rho<0) = nan;
    
    % get rid of bad values:
    iokay = ~isnan(rho);
    rho   = rho(iokay);
    y     = y(iokay);
    z     = z(iokay);
    
   
    % Bin the data:
    if nBin > 0
        bins = z(1):nBin:z(end)+nBin;
        rbined = zeros(length(bins)-1,1);
        zbined = rbined;
        ybined = rbined;
        for i = 1:length(bins)-1
            ibin = z >= bins(i) & z < bins(i+1);
            rbined(i) = mean(rho(ibin));
            zbined(i) = mean(z(ibin));
            ybined(i) = mean(y(ibin));
        end
        rho = rbined;
        z = zbined;
        y = ybined; % just in case its a deviated well
    end
    
    if lPlotLog10 == 1
        rho = log10(rho);
    end
    
    
    % bundle into temporary structure for use in multiple file
    % common horizontal scaling:
    stw(iwell).rho = rho;
    stw(iwell).y   = y;
    stw(iwell).z   = z;
    stw(iwell).sName = sName;
 
    maxrange = max( max(rho)-min(rho),maxrange);
end

xl = get(gca,'xlim');
xr = xl(2)-xl(1);

% Now scale data by maxrange and plot it:

for iwell = 1:length(ff)
    
    % extract components for this well:
    y = stw(iwell).y;
    z = stw(iwell).z;  
    sName = stw(iwell).sName;
    rho = stw(iwell).rho;
    
    rho = (rho - min(rho))/maxrange - 1/2;  % roughly -0.5 to 0.5 depending on maxrange
    
 
    % add it to the MARE2DEM plot:
    my = y;
    my(:) = mean(y); % kwk just use vertial column for now...code deviated boreholes at a later time...
 
    yp = my + rho*frac*xr;  
    hwl = plot(st.axes,yp,z,'-','color',stSettings.wellLogColor, 'linewidth',stSettings.wellLogLineWidth);
    set(hwl,'tag','welllog');
    
    %hwl = plot(my(1),z(1)-.1,'wo','tag','welllog');
    axes(st.axes) 
    hwl = text(yp(1),z(1),sName);
    set(hwl,'tag','welllogname','interpreter','none','visible',stSettings.showWellLogNames);
  
    
end


set(hFig,'userdata',st);
end

%--------------------------------------------------------------------------
function sub_setAxisScale_Callback(hObject, ~, hFig,sAxis)

handles     = get(hFig,'userdata');
stSettings  = getappdata(hFig,'stSettings');

if strcmpi(sAxis,'equal') 
    ax = axis;
    
    if strcmpi(get(hObject,'checked'),'on')
        axis(handles.axes,'normal')
        stSettings.equalAspect  = 'off'; 
        
        if isfield(handles,'hax2') && ~isempty(handles.hax2)
            axis(handles.hax2,'normal')
        end
       
    else
        set(gca,'xlimmode','auto','ylimmode','auto')
        pb = pbaspect(handles.axes);
        daspect(handles.axes,[1 1 1])
        pbaspect(handles.axes,pb);
        stSettings.equalAspect = 'on'; 
        
        if isfield(handles,'hax2') && ~isempty(handles.hax2)
            daspect(handles.hax2,[1 1 1])
            pbaspect(handles.hax2,pb);
        end
        
    end
    set(hObject,'checked',stSettings.equalAspect);
    
elseif strcmpi(sAxis,'entireModel') 
    pb = pbaspect(handles.axes);
    axis tight
    pbaspect(handles.axes,pb);
%     if isfield(handles,'hax2') && ~isempty(handles.hax2)
%         pb = pbaspect(handles.axes);
%         axis tight
%         pbaspect(handles.axes,pb);
%     end  
elseif strcmpi(sAxis,'zoomToSurvey') 
    [xlim,ylim ] = m2d_estimateAreaOfInterest(handles);
    dar = get(handles.axes,'DataAspectRatio');  
    
    if any(dar ~= 1) % If axis normal:
  
        set(handles.axes,'xlim',xlim,'ylim',ylim)
            
    else %if axis equal, only set xlim:
        %pb = pbaspect;
        %factor =  norm(xlim)/norm(ylim)*pb(2)/pb(1);
        %set(handles.axes,'ylimmode','auto','xlim',xlim,'ylim',factor*ylim)
         set(handles.axes,'xlim',xlim,'ylim',ylim)
    end
    
end

zoom reset; % this makes the current view the zoom reset (i.e. double click) view;

  
setappdata(hFig,'stSettings',stSettings);

sub_setAxisTickLabels(hFig);
 
sub_saveMRU(stSettings,hFig);

zoom_updateAxes([],[]);  % redraws contours etc

end

%--------------------------------------------------------------------------
function sub_setAxisDirection(hObject, ~, hFig,sDir)

handles     = get(hFig,'userdata');
stSettings  = getappdata(hFig,'stSettings');

if strcmpi(get(hObject,'checked'),'off')
    % reverse axis:
    if strcmpi(sDir,'reverseX')
        set(handles.axes,'xdir','reverse');
    else
        set(handles.axes,'ydir','normal');  % Note that in MARE2DEM, ypositive down is the default, so reversing means y positive up, or normal to MATLAB.
    end
    set(hObject,'checked','on')
    stSettings.(sDir) = 'on';
else
    % reverse axis:
    if strcmpi(sDir,'reverseX')
        set(handles.axes,'xdir','normal');
    else
        set(handles.axes,'ydir','reverse');
    end
    set(hObject,'checked','off')
    stSettings.(sDir) = 'off';
    
end
  
setappdata(hFig,'stSettings',stSettings);
 
sub_saveMRU(stSettings,hFig);


end

%--------------------------------------------------------------------------
function sWJfile = getWJFile(st)
    
    sWJfile = [];

    if ~isfield( st, 'sWJfile' ) || isempty(st.sWJfile)
        sWJfile = st.directory;
    end
    [ff, pp] = uigetfile({
        '*.sensitivity;*.jacobian;*.jacobian.mat;*.jacobianBin', 'Jacobian file (*.jacobian)'
        '*', 'All files'
        }, 'Select a sensitivity (.sensitivity, .jacobian, ,.jacobianBin) file:', sWJfile );
    if ff <= 0
        return
    end
   sWJfile  = fullfile(pp,ff);
    
end

%--------------------------------------------------------------------------
function st = loadSensitivity(st)

st.sensitivity = [];

%
% Load in sensitivity or Jacobian (and convert to sensitivity):
%
[~,~,e] = fileparts( st.sWJfile );
sFileType = lower(e);
st.sensitivity = [];

switch sFileType

    case '.sensitivity'
        
        %sensitivity = sub_loadSensitivity(st.sWJfile);
    
        fid = fopen(st.sWJfile,'r');
        if fid <=0
            beep;
            fprintf(' Error opening sensitivity file: %s\n',st.sWJfile);
            return
        end        
        st.sensitivity = fread(fid,'double');
        fclose(fid);
        
    case '.jacobian'
        st.sensitivity = sub_loadJacobian(st);
        
    case '.jacobianbin'
        st.sensitivity = sub_loadJacobian(st);
        
    case '.mat'
        load(st.sWJfile);
        st.sensitivity = sensitivity;
end

% handle infinities (divide by zeros errors?)
minsens = min(st.sensitivity(st.sensitivity>0));
st.sensitivity(st.sensitivity == -inf) = NaN;
st.sensitivity(st.sensitivity ==  inf) = NaN;
st.sensitivity(st.sensitivity ==  0.0) = minsens;  % set to min values. 0 sensitivity is usually in exerior region of moving footprint
  
    
    % percentile option: kwk debug
    
%     [nUniq,~,i] = unique(st.sensitivity);
%     nUniq = (0:(numel(nUniq)-1)) / (numel(nUniq)-1);
%     st.sensitivity = nUniq(i);

end


%--------------------------------------------------------------------------
function setSensitivityContours(~,~,hFig)

st          = get(hFig,'userdata');
stSettings  = getappdata(hFig,'stSettings');


if ~isfield( st, 'sensitivity' ) || isempty(st.sensitivity)
    uiwait( errordlg( {
        'No Jacobian sensitivity loaded.'
        'First load the .sensitivity or .jacobian file, then try again.'
        }, 'Plot Sensitivity Histogram', 'modal' ) );
    return;
end
    
% Ask the user to specify what the contours should be
str = sprintf('Enter contour values for log10(Sensitivity). \n \nUse an array (e.g. [-3 -2.5 -2 -1.5 -1]) or array expression (e.g. [-3:.5:-1]) for specific intervals. Or specify a single value N for N contours\nrange(log10(sensitivity)) = %.2g to %.2g',...
               log10(min(st.sensitivity)),log10(max(st.sensitivity)));

cDefault = {num2str(stSettings.sensitivityContourInterval)};
 
cAns = inputdlg( str ...
    , 'plotMARE2DEM Sensitivity contours', 1, cDefault ...
    , struct('Resize', 'on', 'WindowStyle', 'modal', 'Interpreter', 'none') );
if isempty( cAns )
    return;
end

% add on brackets in case user didn't include them and sort in case not in
% order:
stSettings.sensitivityContourInterval = sort(eval(sprintf('[%s]',cAns{1})));

setappdata(hFig,'stSettings',stSettings);

sub_saveMRU(stSettings,hFig);
 
plotRhoXYZ( [], [], hFig );     % cause a replot
 
return;
end % setSensitivityContours



%--------------------------------------------------------------------------
function plotSensitivityAlpha(hObject,~,hFig)

 st = get(hFig,'userdata');
  
 if strcmpi(get(hObject,'checked'),'on')
    set(hObject,'checked','off');
      
    set( hFig, 'UserData', st );    % save the map
    plotRhoXYZ( [], [], hFig );     % cause a replot    
    return
    
 end
 
 
if ~isfield( st, 'sensitivity' ) || isempty(st.sensitivity)
%     uiwait( errordlg( {
%         'No Jacobian sensitivity loaded.'
%         'First load the .sensitivity or .jacobian file, then try again.'
%         }, 'Plot Sensitivity Histogram', 'modal' ) );
%     return;
% If sensitivity not loaded already, then load it:
    
    if isempty(st.sWJfile) % select a new file:
    
        st.sWJfile = getWJFile(st);
   
        if isempty(st.sWJfile)
            return
        end

    end

    % Load sensitivity file:
    st = loadSensitivity(st );
 

end
    
set(hObject,'checked','on'); 

st.plotSensitivity = false;

set( hFig, 'UserData', st );    % save the map
plotRhoXYZ( [], [], hFig );     % cause a replot
return;

end

%--------------------------------------------------------------------------
function plotSensitivityContours(hObject,~,hFig)

st = get(hFig,'userdata');

stSettings  = getappdata(hFig,'stSettings');

if strcmpi(get(hObject,'checked'),'on')
    set(hObject,'checked','off');
    stSettings.showSensContours = 'off';
    
else
    % If sensitivity not loaded already, then load it:
    if isempty(st.sensitivity)

        if isempty(st.sWJfile) % select a new file:

            st.sWJfile = getWJFile(st);

            if isempty(st.sWJfile)
                set(hObject,'checked','off');
                stSettings.showSensContours = 'off';
                return
            end

        end

        % Load sensitivity file:
        st = loadSensitivity(st );
        if isempty(st.sensitivity)
            set(hObject,'checked','off');
            stSettings.showSensContours = 'off';
            return
        end

        st.plotSensitivity = false;
        set(hObject,'checked','on');
        stSettings.showSensContours = 'on';
    else
        st.plotSensitivity = false;
        set(hObject,'checked','on');
        stSettings.showSensContours = 'on';    
    end
end
setappdata(hFig,'stSettings',stSettings);

sub_saveMRU(stSettings,hFig);  

set(hFig,'Userdata',st);
 
 
plotRhoXYZ( [], [], hFig );     % cause a replot


return;

end

 

%--------------------------------------------------------------------------
function showContourLabels(hObject,~,hFig,sField)

stSettings  = getappdata(hFig,'stSettings');

if strcmpi(get(hObject,'checked'),'off')
   set(hObject,'checked','on');
   stSettings.(sField) = 'on';
else
   set(hObject,'checked','off');
   stSettings.(sField) = 'off';
end

setappdata(hFig,'stSettings',stSettings);

sub_saveMRU(stSettings,hFig);
  
plotRhoXYZ( [], [], hFig );     % cause a replot
 
end


%--------------------------------------------------------------------------
function plotWJ(~,~,hFig,sFile)

if ~exist('sFile','var')
    sFile = [];
end

st = get(hFig,'userdata');

if isempty(sFile) % select a new file:
    
    st.sWJfile = getWJFile(st);
   
    if isempty(st.sWJfile)
        return
    end

else
    st.sWJfile = sFile;
    
end

% Load sensitivity file:
st = loadSensitivity(st);


% Force replotting, which will now use sensitivity of current rho x y or z
% component:
st.plotSensitivity  = true;
set( hFig, 'UserData', st );    % save the map
plotRhoXYZ( [], [], hFig );     % cause a replot


end % plotWJ


%--------------------------------------------------------------------------
function sensitivity = sub_loadJacobian(st)

% Read in the file
    fid = fopen(st.sWJfile,'r');
    if fid <=0
        beep;
        fprintf(' Error opening sensitivity file: %s\n',st.sWJfile);
        return
    end
    h = waitbar(0.25,'Reading file, be patient...','WindowStyle','modal');
    
    [~,~,e] = fileparts( st.sWJfile );  % file may already have .mat on it. look for that
    if strcmpi( e, '.jacobian' )
        % Old ascii format (slow to read!):
        fprintf('Reading Jacobian in older ascii format. Try using new MARE2DEM to save in binary format.\n')
        temp = fscanf(fid,'%i %i\n',2);
        nData = temp(1);
        nParams = temp(2);
        % WJ = textscan(fid,'%g',nData*nParams);
        WJ = fscanf(fid,'%E',[ nData nParams]);
    elseif strcmpi( e, '.jacobianBin' )
        % Faster binary read
        nData   = fread(fid,1,'int32');
        nParams = fread(fid,1,'int32');
        WJ      = fread(fid,[nData nParams],'float64');   
    end
    fclose(fid);
    close (h);
    if numel(WJ) ~= nData*nParams
        uiwait( errordlg( {
            'The jacobian file appears to be truncated.'
            sprintf( 'Expected %d data * %d parameters', nData, nParams )
            sprintf( '  Loaded %d data * %d parameters', size(WJ) )
            }, 'Load Jacobian', 'modal' ) );
        return;
    end
    
    %
    % Ask user which data to use for sensitivity plot:
    %
    iTypes = [0; unique(st.DATA(:,1))];
    cTypes = num2cell(iTypes);
    cTypes{1} = 'All';
    ind = menu( 'Select data type to use:', cTypes );
    if ind < 1  % user cancel
        return;
    end    
    
    % For now let's just sum the Jacobian over all data (later code could be added
    % to select specific Rx, Tx, Freqs, components etc).
    % NB: We use sum(abs()) so that +ve effect on some params and -ve on others (i.e
    % MT apres & phase) don't cancel.
    if ind == 1
        sd = (diag(1./st.DATA(:,6)));
        sensitivity = sum(abs(sd*WJ),1);
    else
        iUse = st.DATA(:,1) == iTypes(ind);
%         beep
%         fprintf('KWK debug line 3841 in plotMARE2DEM\n')
%          iUse = st.DATA(:,1) == iTypes(ind) &  st.DATA(:,2) == 1; 
        sd = (diag(1./st.DATA(iUse,6)));
        sensitivity = sum(abs(sd*WJ(iUse,:)),1);
    end
    clear WJ    % release the massive amount of memory as early as possible
    
    % Normalize by the region area so that it is similar to the Frechet derivative
    x = st.TR.Points(:,1); 
    y = st.TR.Points(:,2); 
    yt = x(st.TR.ConnectivityList);
    zt = y(st.TR.ConnectivityList);
    tarea = polyarea(yt.',zt.').';
    iplot = st.freeparameter(st.TriIndex,st.icmp) > 0;
    ipnum = st.freeparameter(st.TriIndex(iplot),st.icmp);
 
    tarea2 = tarea(iplot);
    paramArea = zeros(size(sensitivity));
    for i = 1:length(ipnum)
        paramArea(ipnum(i)) = paramArea(ipnum(i))+ tarea2(i);
    end
    % DGM 6/11/2014 - for anisotropic inversions, there may be 2 or 3 parameters
    % which share the same triangles. However, the TriIndex values are only linked
    % to one of those parameters. So... share the areas across all params which
    % point to the same physical triangles.
    for i = 1:size(st.freeparameter,1)
        nSumEm = unique(st.freeparameter(i,:));
        if numel(nSumEm) > 1
            paramArea(nSumEm) = sum(paramArea(nSumEm));
        end
    end
    sensitivity = (sensitivity ./ paramArea)';  
    
end
 
%-------------------------------------------------------------------------------
% DGM 8/26/2014 - plot a histogram of the log Sensitivity values, marking the percentiles
function plotSensitivityHistogram(~,~,hFig)
    st = get( hFig, 'UserData' );
    if ~isfield( st, 'sensitivity' ) || isempty(st.sensitivity)
        uiwait( errordlg( {
            'No Jacobian sensitivity loaded.'
            'First load the .sensitivity or .jacobian file, then try plotting.'
            }, 'Plot Sensitivity Histogram', 'modal' ) );
        return;
    end
    
    n = log10( st.sensitivity(:) );
    nBins = floor(min(n))+0.5 : ceil(max(n))-0.5;   % these are bin CENTERs
    
    n = sort(n);
    nPrcBin = floor(min(n)) :0.5: ceil(max(n));
    nPrc = NaN(size(nPrcBin));
    for iBin = 1:numel(nPrcBin)
        i = find( n > nPrcBin(iBin), 1, 'first' );
        if isempty(i)
            nPrc(iBin) = 1;
        else
            nPrc(iBin) = i / numel(n);
        end
    end
    nPrc = nPrc * 100;
    
    m2d_newFigure();
    subplot(2,1,1);
    hist( n, nBins );
    xlabel( 'log10(Sensitivity)' );
    ylabel( 'Count' );
    [~,f,e] = fileparts( st.sWJfile );
    title( ['Histogram of log10(Sensitivity) for ' f e] );
    nXL = xlim();
    set( gca, 'xtick', nXL(1):nXL(2) );
    
    subplot(2,1,2);
    plot( nPrcBin, nPrc, '-b' );
    set( gca, 'xtick', nXL(1):nXL(2), 'ytick', 0:25:100, 'ygrid', 'on' );
    xlabel( 'log10(Sensitivity)' );
    ylabel( 'Percentile' );
    title( 'CDF' );
    
end % plotSensitivityHistogram



%--------------------------------------------------------------------------
function transparencyAlpha(~,~,hFig)
    
    st          = get( hFig, 'UserData' );
    stSettings  = getappdata(hFig,'stSettings');

    %ask for new alpha:
    cDefault = {num2str(stSettings.transparencyAlpha)};
    
    cAns = inputdlg( 'Enter transparency alpha value between 0 to 1 (0 is opaque, 1 is fully transparent):' ...
    , 'plotMARE2DEM Sensitivity', 1, cDefault ...
    , struct('Resize', 'on', 'WindowStyle', 'modal', 'Interpreter', 'none') );
    if isempty( cAns )
        return;
    end

    stSettings.transparencyAlpha = str2double(cAns{1});  
    
    setappdata(hFig,'stSettings',stSettings);

    sub_saveMRU(stSettings,hFig);

    plotRhoXYZ( [], [], hFig );     % cause a replot

    return;
end % transparencyAlpha


%--------------------------------------------------------------------------
function sensitivityLowerLimit(~,~,hFig)
    
    st          = get( hFig, 'UserData' );
    stSettings  = getappdata(hFig,'stSettings');

    %ask for new alpha:
    cDefault = {num2str(stSettings.sensitivityAlphaLowLimit)};
    
    cAns = inputdlg( 'Enter log10(sensitivity) lower limit for transparency (if in doubt, plot the sensitivity contours first then pick the desired contour):' ...
    , 'plotMARE2DEM Sensitivity', 1, cDefault ...
    , struct('Resize', 'on', 'WindowStyle', 'modal', 'Interpreter', 'none') );
    if isempty( cAns )
        return;
    end

    stSettings.sensitivityAlphaLowLimit = str2double(cAns{1});  
    
    setappdata(hFig,'stSettings',stSettings);

    sub_saveMRU(stSettings,hFig);

    plotRhoXYZ( [], [], hFig );     % cause a replot

    return;
end % sensitivityLowerLimit

%--------------------------------------------------------------------------
function plotResContours(hObject,~,hFig)

stSettings  = getappdata(hFig,'stSettings');

if strcmpi(get(hObject,'checked'),'on')
    set(hObject,'checked','off');
    stSettings.showResContours = 'off';
else
    set(hObject,'checked','on');
    stSettings.showResContours = 'on';

end

setappdata(hFig,'stSettings',stSettings);

sub_saveMRU(stSettings,hFig);

if strcmpi(stSettings.showResContours,'on')
    plotRhoXYZ( [], [], hFig );     % cause a replot  
else
    delete(findobj(hFig,'tag','ResistivityContours')); 
end

end

%--------------------------------------------------------------------------
function setResistivityContours(~,~,hFig)

st          = get(hFig,'userdata');
stSettings  = getappdata(hFig,'stSettings');

% Ask the user to specify what the contours should be
str = sprintf('Enter contour values for log10(resistivity). \n \nUse an array (e.g. [-1 0 1 2 3 4]) or array expression (e.g. [0.25:0.25:2]) for specific intervals. Or specify a single value N for N contours\nrange(log10(resistivity)) = %.2g to %.2g',...
               log10(min(st.resistivity)),log10(max(st.resistivity)));

cDefault = {'10'};
if isfield(stSettings,'resistivityContourInterval')
    cDefault = {num2str(stSettings.resistivityContourInterval)};
end

cAns = inputdlg( str ...
    , 'plotMARE2DEM Resistivity contours', 1, cDefault ...
    , struct('Resize', 'on', 'WindowStyle', 'modal', 'Interpreter', 'none') );
if isempty( cAns )
    return;
end

try
    % add on brackets in case user didn't include them and sort in case not in
    % order:  
    answer = sort(eval(sprintf('[%s]',cAns{1})));

    if length(answer) > 50 || (length(answer)==1 && answer > 50)
        beep
        fprintf('Too many contours requested, skipping. number of contours = %i\n',length(answer))
        return

    end

    
    stSettings.resistivityContourInterval = answer;

    setappdata(hFig,'stSettings',stSettings);

    sub_saveMRU(stSettings,hFig);

    plotRhoXYZ( [], [], hFig );     % cause a replot

catch
    
end

end % setResistivityContours


%--------------------------------------------------------------------------
function setLinearOrLog10Scaling(~,~,hFig,sType)

st          = get(hFig,'userdata');
stSettings  = getappdata(hFig,'stSettings');

% Get the current scaling        
switch lower(sType)
    
    case('log10')
        
        if st.icmp <= st.nNonRatio
            if st.plotSensitivity  
                stSettings.colorScaleSensitivity = 'log10';
            elseif strcmpi(st.anisotropy,'isotropic_ip') && st.icmp > 1 % eta, tau or c
                stSettings.colorScaleIP = 'log10';
            else
                stSettings.colorScaleResistivity = 'log10';
            end
        else
            stSettings.colorScaleRatio = 'log10';
        end     
        
    case('linear')
        
        if st.icmp <= st.nNonRatio
            if st.plotSensitivity  
                stSettings.colorScaleSensitivity = 'linear';
            elseif strcmpi(st.anisotropy,'isotropic_ip') && st.icmp > 1 % eta, tau or c
                stSettings.colorScaleIP = 'linear';               
            else
                stSettings.colorScaleResistivity = 'linear';
            end
        else
            stSettings.colorScaleRatio = 'linear';
        end     
                
end
 
       
setappdata(hFig,'stSettings',stSettings);

sub_saveMRU(stSettings,hFig);

plotRhoXYZ([],[],hFig)
 
end

%--------------------------------------------------------------------------
function sub_setColorMap(hObject,~,hFig,sColorMap) %#ok<*INUSL>

st          = get(hFig,'Userdata');
stSettings  = getappdata(hFig,'stSettings');

set(findobj(hFig,'tag','uimenu_cm'),'checked','off');
set(hObject,'checked','on');

% Set colormap:
if st.icmp <= st.nNonRatio  % not a ratio plot
    
    if st.plotSensitivity  

        if strcmpi(sColorMap,'invert')
            if stSettings.sSensitivityInverted 
                stSettings.sSensitivityInverted  = false;
            else
                stSettings.sSensitivityInverted = true;
            end
        else
            stSettings.sSensitivityInverted = false; % don't invert when changing colormap
            stSettings.sSensitivityColorMap = sColorMap;    
        end
        sub_applyColorMap(hFig,stSettings.sSensitivityColorMap,stSettings.sSensitivityInverted); 
        
    elseif strcmpi(st.anisotropy,'isotropic_ip') && st.icmp > 1 % eta, tau or c
        
        if strcmpi(sColorMap,'invert')
            if stSettings.sIPInverted 
                stSettings.sIPInverted  = false;
            else
                stSettings.sIPInverted = true;
            end
        else
            stSettings.sIPInverted = false; % don't invert when changing colormap
            stSettings.sIPColorMap = sColorMap;    
        end
        sub_applyColorMap(hFig,stSettings.sIPColorMap,stSettings.sIPInverted);         
    else
        
        if strcmpi(sColorMap,'invert')
            if stSettings.sResistivityInverted 
                stSettings.sResistivityInverted  = false;
            else
                stSettings.sResistivityInverted = true;
            end
        else
            stSettings.sResistivityInverted = false; % don't invert when changing colormap
            stSettings.sResistivityColorMap = sColorMap;    
        end
        sub_applyColorMap(hFig,stSettings.sResistivityColorMap,stSettings.sResistivityInverted);
    end

    
else % ratio plot:

    if strcmpi(sColorMap,'invert')
        if stSettings.sRatioInverted 
            stSettings.sRatioInverted  = false;
        else
            stSettings.sRatioInverted = true;
        end
    else
        stSettings.sRatioInverted = false; % don't invert when changing colormap
        stSettings.sRatioColorMap = sColorMap;   
    end
    sub_applyColorMap(hFig,stSettings.sRatioColorMap,stSettings.sRatioInverted) 
end


setappdata(hFig,'stSettings',stSettings); 
%set(hFig,'Userdata',st);

% Save new MRU file:
sub_saveMRU(stSettings,hFig);

end

%--------------------------------------------------------------------------
function sub_setColorMapPointData(hObject,~,hFig,sColorMap) %#ok<*INUSL>

st   = get(hFig,'Userdata');
 
if isfield(st,'hax2') && ~isempty(st.hax2)
    set(st.hax2,'handlevisibility','on')

    wasChecked = get(hObject,'checked');
    set(findobj(hFig,'tag','uimenu_cm_pointdata'),'checked','off');
    if ~strcmpi(wasChecked,'on')
        set(hObject,'checked','on')
    end

    if strcmpi(sColorMap,'invert')
        cm = flipud(colormap(st.hax2)); 
    else
        cm = m2d_colormaps(sColorMap);     
    end
    colormap(st.hax2,cm);
 
    set(st.hax2,'handlevisibility','off')

end

end
%--------------------------------------------------------------------------
function sub_applyColorMap(hFig,sColorMap,lInverted) %#ok<*INUSL>

cm = m2d_colormaps(sColorMap);

if lInverted  == true
    cm = flipud(cm); 
end
 
colormap(hFig,cm);

% Uncheck everything:
set(findobj(hFig,'tag','uimenu_cm'),'checked','off');

% Set inverted check if needed:
hInvert = findobj(hFig,'Text','Invert Colormap');
if lInverted
    set(hInvert,'checked','on')  
end

% Set colormap check:
hObject = findobj(hFig,'Text',sColorMap);
set(hObject,'checked','on')  

 
end

%--------------------------------------------------------------------------
function sub_display_colormaps(varargin)
    m2d_colormaps('display_all');
end
%--------------------------------------------------------------------------
function setColorScaleAutoLimits(~,~,hFig)

st          = get(hFig,'userdata');
stSettings  = getappdata(hFig,'stSettings');

[st,stSettings] = getAutoColorScale(st,stSettings);

applyColorScale(st,stSettings);

set(hFig,'userdata',st);
setappdata(hFig,'stSettings',stSettings);

% Save new MRU file:
sub_saveMRU(stSettings,hFig);


end

%--------------------------------------------------------------------------
function applyColorScale(st,stSettings)

if st.icmp <= st.nNonRatio
    
    if st.plotSensitivity 
        
        ca = stSettings.colorScaleLimitsSensitivity;
        scale = stSettings.colorScaleSensitivity;
  
    elseif strcmpi(st.anisotropy,'isotropic_ip') && st.icmp > 1 % IP eta, tau or c
        
        ca = stSettings.colorScaleLimitsIP;
        scale = stSettings.colorScaleIP;
                
    else % resistivity
        
        ca = stSettings.colorScaleLimitsResistivity;
        scale = stSettings.colorScaleResistivity;
    end
    
else % ratio plot
    ca = stSettings.colorScaleLimitsRatio;
    scale = stSettings.colorScaleRatio;
end

if strcmpi(scale,'log10')
    if ca(1) == 0
        ca(1) = 0.001;
    end
    ca = log10(ca);
end
caxis(ca);


end


%--------------------------------------------------------------------------
function setColorScaleManualLimits(~,~,hFig)

st          = get(hFig,'userdata');
stSettings  = getappdata(hFig,'stSettings');

name = 'Colorscale limits: ';

if st.icmp <= st.nNonRatio
    
    if st.plotSensitivity 
        ca = stSettings.colorScaleLimitsSensitivity;
        prompt={'Upper Limit (linear sensitivity)', 'Lower Limit (linear sensitivity)'};
        
    elseif strcmpi(st.anisotropy,'isotropic_ip') && st.icmp > 1 % IP eta, tau or c
        
        ca = stSettings.colorScaleLimitsIP;
        prompt={ 'Upper Limit (linear IP)','Lower Limit (linear IP)'}; 
         
    else
        ca = stSettings.colorScaleLimitsResistivity;
        prompt={'Upper Limit (linear ohm-m)', 'Lower Limit (linear ohm-m)'};
    end
    
else % ratio plot
    ca = stSettings.colorScaleLimitsRatio;
    prompt={'Upper Limit (linear ratio)', 'Lower Limit (linear ratio)'};
end
 
    
defans = cellstr(num2str(fliplr(ca)'));
lims = inputdlg(prompt,name,[1 35],defans);
if isempty(lims)
    return
end
ca = [str2double(lims{2}) str2double(lims{1})] ;

if st.icmp <= st.nNonRatio
    if st.plotSensitivity
        stSettings.colorScaleLimitsSensitivity = ca;
    elseif strcmpi(st.anisotropy,'isotropic_ip') && st.icmp > 1 % IP eta, tau or c
        stSettings.colorScaleLimitsIP = ca;  
    else
        stSettings.colorScaleLimitsResistivity = ca;
    end
else % ratio plot
    stSettings.colorScaleLimitsRatio = ca;
end   


applyColorScale(st,stSettings);

setappdata(hFig,'stSettings',stSettings);
set(hFig,'userdata',st);

% Save new MRU file:
sub_saveMRU(stSettings,hFig);

end

%--------------------------------------------------------------------------
function sub_setColorScalePointData(~,~,hFig)

st = get(hFig,'userdata');

if isfield(st,'hax2') && ~isempty(st.hax2)
    
    name = 'Colorscale limits: ';

    ca = caxis(st.hax2);
    prompt={'Upper Limit', 'Lower Limit'};

    defans = cellstr(num2str(fliplr(ca)'));
    lims = inputdlg(prompt,name,[1 35],defans);
    if isempty(lims)
        return
    end
    ca = [str2double(lims{2}) str2double(lims{1})] ;

    caxis(st.hax2,ca)

end
 
end

%--------------------------------------------------------------------------
function plotPolygons(~,~,hFig,ff)

if nargin == 4
    pp = '';
    
else
    
    [ff, pp] = uigetfile('*.poly', 'Select  a polygon (.pslg) file:');
end

if ff > 0
    
    set(hFig, 'Pointer', 'watch' ); drawnow;    
    
    stSettings  = getappdata(hFig,'stSettings');
    
    polyFile  = fullfile(pp,ff);
 
    [nodes,segs,eles,holes,regions] = m2d_readPoly(polyFile);
 
    
    if ~isempty(nodes)
        
        x = nodes(:,1);
        y = nodes(:,2);
        i1 = segs(:,1)';
        i2 = segs(:,2)';
        
        % slow plot since it makes a separate graphics object for each line segment:
        %h = plot(x([i1 i2]),y([i1; i2]),'k-');
        
        % better to insert nan's and plot as single graphics object:
        X = [x(segs(:,1:2))  nan(size(segs,1),1)]';
        Y = [y(segs(:,1:2))  nan(size(segs,1),1)]';

        h = plot(X(:),Y(:),'-','tag','polygons','linewidth',stSettings.polygonFileLineWidth,'color',stSettings.polygonFileColor);
        
        % make sure receivers and transmitters are on top: % KWK: could use
        % uistack for this instead         
        sub_uistack(hFig);
        
    end
    
    set(hFig, 'Pointer', 'arrow' ); drawnow;    
    
end

end

%--------------------------------------------------------------------------
function plotLines(~,~,hFig)

% DGM 9/10/2014 - add multi-select so many lines can be added at once.
[sF,sP] = uigetfile('*', 'Select one or more line files (2 columns of position, depth)' ...
    , 'Multiselect', 'on' );
if isnumeric(sF)    % user cancel
    return
end
if iscell(sF)   % many selected
    sF = sort(sF);
    for i=numel(sF):-1:1
        cList{i} = fullfile( sP, sF{i} );
    end
    clear i
else            % one selected
    cList = {fullfile( sP, sF )};
end
clear sF sP

for iFile = 1:numel(cList)
    % Load & plot
    a = load( cList{iFile} );
    x = a(:,1);
    y = a(:,2);
    [~,sFile] = fileparts( cList{iFile} );  % make the filename the legend for this line
    
    plot(x,y,'k-','tag','lines','linewidth',2,'DisplayName',sFile);
    
    % make sure receivers and transmitters are on top:
    sub_uistack(hFig);
    
end

end

%--------------------------------------------------------------------------
function plotPenalties(hObject,~,hFig)

st = get(hFig,'userdata');
if ~isfield(st,'penaltyFile') || ~isempty(st.penaltyFile)
    fprintf(' penalty files are deprecated by new MARE2DEM code, nothing to plot, sorry!\n')
    beep;
end

if strcmpi( get( hObject, 'checked' ), 'on' )
    set( hObject, 'checked' , 'off' );
    delete(findobj(hFig,'tag','penalties'));
    
    return
    
else % plot the penalites:
    set( hObject, 'checked' , 'on' );

    set( hFig, 'Pointer', 'watch' ); drawnow;
    
    makePenaltyPlot(hFig);
    
    set( hFig, 'Pointer', 'arrow' );
end

end

%-------------------------------------------------------------------------
function makePenaltyPlot(hFig)
   
    
    delete(findobj(hFig,'tag','penalties'));

    st = get(hFig,'userdata');
    
    if ~isfield(st,'penaltyFile') || isempty(st.penaltyFile)
        beep
        str = 'sorry, penalty files are deprecated now that MARE2DEM calculates the penalty matrix internally. ';
        uiwait(msgbox(str,'Error','modal'));
        return
    end
    if isfield(st,'penalties')
        penalties = st.penalties;
    else
        st.penalties = m2d_readPenaltyFile(fullfile( st.directory, st.penaltyFile ));
        penalties = st.penalties;
    end
    % Need to go from free parameter number in penalties to region
    % number, but show penalties for current component plotted:
    iregion = (1:size(st.freeparameter,1))'; %repmat((1:size(st.freeparameter,1))',1,ncol);
    
    nparams = max(st.freeparameter(:));
    param2region = zeros(nparams,1);
    
    lFree = st.freeparameter(:,st.icmp)>0;
    param2region(st.freeparameter(lFree,st.icmp)) = iregion(lFree); 
       

    p1 = penalties(:,1);
    p2 = penalties(:,2);
    r1 = param2region(p1);
    r2 = param2region(p2);
    
    lUse = r1 > 0 & r2 > 0;
    r1 = r1(lUse);
    r2 = r2(lUse);

    % Plot at centroid (although beware of non-convex and u shaped regions
    % where centroid fall outside region!
    centroids = getCentroids(st.TR,st.TriIndex);
    % This is non essential, but I could put a test here to see if centroid lies in the region, if not use centroid of one of polygons' triangles instead. 

    xr1 = centroids(r1,1);
    xr2 = centroids(r2,1);
    yr1 = centroids(r1,2);
    yr2 = centroids(r2,2);

    x = [xr1 xr2]';
    y = [yr1 yr2]';

    % Trick to plot all lines in single graphics object, otherwise this a
    % graphics object per column of x is generated and this is SUPER ULTRA MEGA
    % SLOW!!!!!!!. Trick below gives lickety-split plotting:
    x(3,:) = nan;
    y(3,:) = nan;
    x = x(:);
    y = y(:);
    h = plot(x,y,'m-');
    set(h,'tag','penalties');

    h = plot(st.regions(:,1),st.regions(:,2),'k.');
    set(h,'tag','penalties');
    
end
%-------------------------------------------------------------------------
function centroids = getCentroids(DT,TriIndex)
%
% Centroids of polygonal regions are obtained by geometric decomposition
% since thats a cinch given the existing DT.
% 3rd column returned is area of region.

if exist('delaunayTriangulation','class')
    y = DT.Points(:,1);
    z = DT.Points(:,2);
    yt = y(DT.ConnectivityList);
    zt = z(DT.ConnectivityList);
else
    y = DT.X(:,1);
    z = DT.X(:,2);
    yt = y(DT.Triangulation);
    zt = z(DT.Triangulation);
end

yct = sum(yt,2)/3;
zct = sum(zt,2)/3;
 

tarea = polyarea(yt',zt')';

nRegions = length(unique(TriIndex));
centroids = zeros(nRegions,2);

for i = 1:nRegions
    
    itris = find(TriIndex == i);
    
    sarea = sum(tarea(itris));
    
    ycentroid = sum(yct(itris).*tarea(itris))/ sarea;
    zcentroid = sum(zct(itris).*tarea(itris))/ sarea;
    centroids(i,1:3) = [ ycentroid zcentroid sarea];
    
end
 
end
%--------------------------------------------------------------------------
function plotParamNums(hObject,~,hFig)


if strcmpi( get( hObject, 'checked' ), 'on' )
    set( hObject, 'checked' , 'off' );
    
    delete(findobj(hFig,'tag','paramnums'));
    
    return
    
else % plot the parameter numbers:
    set( hObject, 'checked' , 'on' );
    st = get(hFig,'userdata');

    figure(hFig);

    if st.icmp <= st.nNonRatio  % not a ratio plot
        paramnum = st.freeparameter(:,st.icmp);
    else
        beep
        h = errordlg('Parameter numbers not defined for resistivity ratios! Please select the Rho x, y or z first!','plotMARE2DEM error','modal');
        waitfor(h);
        return;
    end
    iFree = find(paramnum > 0);
    p = paramnum(iFree);

    x = st.regions(iFree,1);
    y = st.regions(iFree,2);

    % Get zoom extent, and only show labels within current zoom window,
    % otherwise text plotting can overwhelm Matlab so it locks up:
    xlim = get(st.axes,'xlim');
    ylim = get(st.axes,'ylim');

    iplot = x >= xlim(1) & x <= xlim(2) & y >= ylim(1) & y <= ylim(2);


    h =  findobj(hFig,'type','text');
    fs = get(h(1),'fontsize');

    ht = text(x(iplot),y(iplot),num2str(p(iplot)));
    set(ht,'tag','paramnums','color','w',...
        'horizontalalignment','center','verticalalignment','middle')
end

end

%--------------------------------------------------------------------------
function plotRegionNums(hObject,~,hFig)
% region numbers are regions listed in .resistivity file

if strcmpi( get( hObject, 'checked' ), 'on' )
    set( hObject, 'checked' , 'off' );
    
    delete(findobj(hFig,'tag','regionnums'));
    
    return
    
else % plot the region numbers:
    
    set( hObject, 'checked' , 'on' );
    st = get(hFig,'userdata');

    figure(hFig);

    x = st.regions(:,1);
    y = st.regions(:,2);
    n = (1:size(st.regions,1))';

    % Get zoom extent, and only show labels within current zoom window,
    % otherwise text plotting can overwhelm Matlab so it locks up:
    xlim = get(st.axes,'xlim');
    ylim = get(st.axes,'ylim');

    iplot = x >= xlim(1) & x <= xlim(2) & y >= ylim(1) & y <= ylim(2);


    h =  findobj(hFig,'type','text');
    fs = get(h(1),'fontsize');

    ht = text(x(iplot),y(iplot),num2str(n(iplot)));
    set(ht,'tag','regionnums','color','w',...
        'horizontalalignment','center','verticalalignment','middle')
end

end

%--------------------------------------------------------------------------
% Plot up the misfit and roughness
function  plotMARE2DEMIterMisfit(~,~,varargin)
if nargin ==3
    hFig = varargin{1};
else
    hFig = gcf;
end
st = get(hFig,'userdata');
if ~isempty(st.directory)
    sPath = st.directory;
else
    sPath ='./';
end

% Magic numbers used here:
fontSize = 16;
lineWidth = 2;
markerSize = 24;
 
% Read resistivity file up to CURRENTLY PLOTTED iteration (in case older
% files present in folder):
[sP,sN,sE1] = fileparts(st.resistivityFile);
[sP,sBase,sE2] = fileparts(sN);

stFiles = dir(fullfile(sPath, sprintf('%s.*.resistivity',sBase )));  
stFiles = {stFiles.name};

 
% Read in the files, check the time stamp and only save files newer than
% the first iteration file(i.e. ignore any older files perhaps from a
% previous inversion run).
%
[misfit, roughness, nIter, nTime] = deal(zeros(1,numel(stFiles)));
for iFile = 1:numel(stFiles)
   
    stRes = m2d_readResistivity(fullfile(sPath,stFiles{iFile}),'No Data');
    if ~isempty(stRes.misfit) && ~isempty(stRes.roughness)
        misfit(iFile)       = stRes.misfit;
        roughness(iFile)    = stRes.roughness;
    end
    nTime(iFile)        = datenum(stRes.dateAndTime); 
    [~,f] = fileparts( stFiles{iFile} );
    iAt = find( f == '.', 1, 'last' );
    nIter(iFile)        = str2double(f(iAt+1:end));
end

 
[nTime,iSort]   = sort(nTime);
nIter           = nIter(iSort);
misfit          = misfit(iSort);
roughness       = roughness(iSort);
stFiles         = stFiles(iSort);

bKeep       = ismember(nIter,1:nIter(end));
nTime       = nTime(bKeep);
nIter       = nIter(bKeep);
misfit      = misfit(bKeep);
roughness   = roughness(bKeep);
stFiles     = stFiles(bKeep);

% read the highest iteration for use below
if isempty(stFiles)
    errordlg('No other iterations files found so I can''t plot the misfit as a function of Occam iteration number, sorry!','Iteration Misfit Plot:');
    return
end
Resistivity = m2d_readResistivity(fullfile(sPath,stFiles{end}),'No Data');
clear stFiles iSort iNaN iFile stRes f iAt

% Load the log file for the currently plotted inversion run:
stLog = (fullfile(sPath, sprintf('%s.logfile',sBase )));  % KWK: use matlab intrinsic to keep special dependencies to a minimum....
%stLog = {stLog.name};

if iscell(stLog) && numel(stLog) > 1
    files = dir(fullfile(sPath, '*.logfile'));
    for i = 1:length(files)
        files(i).date = datenum(files(i).date);
    end
    [~,iSort] = sort([files.date],'descend');
    stLog = {fullfile( sPath, files(iSort(1)).name )};
    clear files i iSort
    stOCC = readOccLogfile(stLog{1});
else
    stOCC = readOccLogfile(stLog);
end

if ~isempty(misfit)
    startingRMS = stOCC(1).startingRMS(1);
    misfit = [startingRMS misfit];
   
    if numel(nIter) < numel(misfit)
        nIter = [zeros(1,numel(misfit)-numel(nIter)) nIter];
    end
 
    % plot it:
    nSize = [1000 800];
    hFig = m2d_newFigure(nSize);

    [~,f] = fileparts(st.resistivityFile);
    set( hFig, 'name', f );
    
    % Misfit
    subplot(2,2,1);
    mn = min(misfit);
    mx = max(misfit);
    if mx/mn > 10
        semilogy(nIter,misfit,'.-','linewidth',lineWidth,'markersize',markerSize);
    else
        plot(nIter,misfit,'.-','linewidth',lineWidth,'markersize',markerSize);
    end
    hold on;
    %title( f, 'Interpreter', 'none' );
    title('Misfit')
    xlabel('Iteration Number');
    set(gca,'xtick',nIter);
    ylabel('RMS Misfit');
    if isfield(stOCC,'convergenceStatus')
        conv = [stOCC.convergenceStatus];
        iNotConv = find(conv == 0);
        iConv = find(conv > 0)+1;  % +1 since nIter(1) is 0
        if ~isempty(iConv)
            hold on;
            plot(nIter(iConv(1):end),misfit(iConv(1):end),'.','markersize',markerSize);
        end
    end
    
    target = Resistivity.targetMisfit;
    ax = axis;
    
    plot(ax(1:2),[startingRMS startingRMS],'k--')
    plot(ax(1:2),[target target],'k--')
 
    sub_axisTightPadded;
    

    % Change in misfit
%     subplot(2,2,3);
%     nPctChg = (1 - misfit(2:end)./ misfit(1:end-1)) * 100;
%     nPctChg(nPctChg<=0) = NaN;  % protect against no chg and negative chg (which can happen on restarts)
%     semilogy( (nIter(1:end-1) + nIter(2:end)) / 2, nPctChg, '.-' ,'linewidth',lineWidth,'markersize',markerSize);
%     sub_axisTightPadded;
%     xlabel( 'Iteration Number' );
%     ylabel( '% change in Misfit' );
%     
    
    % iteration time:
 
    subplot(2,2,3);
    nSecs = [stOCC(:).iterationSeconds];
    
    plot( 1:length(nSecs),nSecs , '.-' ,'linewidth',lineWidth,'markersize',markerSize);
    sub_axisTightPadded;
    xlabel( 'Iteration Number' );
    ylabel( ' Time (s)' );
    title(sprintf('Total time: %.1f s',sum(nSecs)));
    set(gca,'xtick',nIter);   
    
    % Model roughness
    subplot(2,2,2);
    roughness =  [stOCC(1).startingRoughness(1) roughness];
    plot(nIter,roughness,'.-','linewidth',lineWidth,'markersize',markerSize);
    xlabel('Iteration Number');
    ylabel(' ||Rm||^2');
    title('Roughness ')
    set(gca,'xtick',nIter);
    
    if isfield(stOCC,'convergenceStatus')
        conv = [stOCC.convergenceStatus];
        iNotConv = find(conv == 0);
        iConv = find(conv > 0)+1;  % +1 since nIter(1) is 0
        if ~isempty(iConv)
            hold on;
            plot(nIter(iConv(1):end),roughness(iConv(1):end),'.','markersize',markerSize);
        end
    end
    sub_axisTightPadded;
 
    
    set(findobj(hFig,'type','axes')   ,'fontsize',fontSize);
    
end

% Misfit versus Mu:
subplot(2,2,4); 
set(gca,'fontsize',fontSize);
nColors = size(get(gca,'ColorOrder'),1);
 
mi = 1;
mm = {'o' 'x' '+' 'v' 'd' '.' '>' '<' '*' 's' '^' 'p' 'h'};

legstr = cell(length(stOCC),1);
for i=1:length(stOCC)
    [ y, isort] = sort(stOCC(i).mu);
    
    if mod(i,nColors)==0
        mi = mi + 1;
    end
    if mi > length(nColors)
        mi = 1;
    end
    loglog(stOCC(i).mu(isort),stOCC(i).misfit(isort),'-','marker',mm{mi},'linewidth',lineWidth);
    hold all;
    if ~isempty(stOCC(i).mu)
        legstr{i} = (stOCC(i).sIter);
    end
end
xlabel('Mu');ylabel('Misfit') 

legstr =legstr(~cellfun('isempty',legstr));
 
legend(legstr,'location','NorthWest','AutoUpdate','off' )
title('Misfit versus Lagrange Multiplier');
set(findobj(hFig,'type','axes')   ,'fontsize',fontSize);
 
ax = axis;
ax(1:2) = log10(ax(1:2));
xPad = .04*(ax(2)-ax(1));
xL = ax(1)-xPad;
xU = ax(2)+xPad;
xL = 10.^xL;
xU = 10.^xU;
if exist('target','var')
    plot([xL xU],[target target],'k--')
end
plot([xL xU],[stOCC(1).startingRMS  stOCC(1).startingRMS],'k--')


sub_axisTightPadded;
set(gca,'xtick',10.^[-10:10])

% Joint inversion misfits:

%  First check for new .group_rms.log file:  
[sP,sN,sE1] = fileparts(st.resistivityFile);
[sP,sBase,sE2] = fileparts(sN);
sGroupLog = fullfile(sPath, sprintf('%s.group_rms.log',sBase ));

if exist(sGroupLog,'file') % new 12/2022 .group_rms.log file:

    st = m2d_read_group_rms_log(sGroupLog);
    if ~isempty(st.headers)

        nSize = [800 600];
        hFig =  m2d_newFigure(nSize);
        set(gca,'fontsize',fontSize);
       
        iter = st.rmslog(:,1);
        rms = st.rmslog(:,2:end);

        mn = min(rms(:));
        mx = max(rms(:));

        if mx/mn > 10
            hLines = semilogy(iter,rms,'.-');
        else
            hLines = plot(iter,rms,'.-');
        end
        hold on;
        str = sBase;
        if isfield(Resistivity,'sJointInvWeightType')
            str = sprintf('Model: %s, Joint inverison weights: %s',sBase,Resistivity.sJointInvWeightType);
        end
        title(str , 'Interpreter', 'none' );
        xlabel('Iteration Number');
        ylabel('RMS Misfit');
  

        sub_axisTightPadded;
        
        target = Resistivity.targetMisfit;
        ax = axis;
        ax(1:2) = log10(ax(1:2));
        xPad = .04*(ax(2)-ax(1));
        xL = ax(1)-xPad;
        xU = ax(2)+xPad;
        xL = 10.^xL;
        xU = 10.^xU;
        
        plot([xL xU],[target target],'k--')
        sub_axisTightPadded;

       legend( hLines,st.headers{2:end}, 'Interpreter','none')
        
        set(findobj(hFig,'type','axes')  ,'fontsize',fontSize);
        set(findobj(hFig,'type','line') ,'linewidth',lineWidth,'markersize',markerSize);


    end

 


elseif ~isempty([stOCC.misfitMT])  % old way
    
    % kludge for dealing with way log file read in where stOCC has new
    % index for each step cut...
    rmsMT = [];
    rmsCSEM = [];
    iter = [];
    ict = 0;
    rms = [];
    
    for i = 1:length(stOCC)
        if ~isempty(stOCC(i).misfitMT)
            ict = ict + 1;
%             if ict == 1 && floor(stOCC(i).iter) == 1
%   
%                 iter(ict) = 0; %#ok<AGROW>
%                 
%                 rmsCSEM(ict) = stOCC(i).misfitCSEMstarting; %#ok<AGROW>
%                 rmsMT(ict)   = stOCC(i).misfitMTstarting; %#ok<AGROW>
%                 rms(ict)     = stOCC(i).startingRMS;     %#ok<AGROW>      
%                 ict = ict + 1;
%             end
            iter(ict)    = floor(stOCC(i).iter);%#ok<AGROW>
            rmsCSEM(ict) = stOCC(i).misfitCSEM; %#ok<AGROW>
            rmsMT(ict)   = stOCC(i).misfitMT; %#ok<AGROW>
            rms(ict)     = stOCC(i).misfitFinal; %#ok<AGROW>
        end
    end
    nSize = [800 600];
    hFig =  m2d_newFigure(nSize);
    set(gca,'fontsize',fontSize);
    mn = min([rmsCSEM rmsMT]);
    mx = max([rmsCSEM rmsMT]);
    if mx/mn > 10
        semilogy(iter,rms,'k.-',iter,rmsCSEM,'r.-',iter,rmsMT,'b.-');
    else
        plot(iter,rms,'k.-',iter,rmsCSEM,'r.-',iter,rmsMT,'b.-');
    end
    hold on;
    title( f, 'Interpreter', 'none' );
    xlabel('Iteration Number');
    ylabel('RMS Misfit');
    legend('Joint','CSEM','MT')
    sub_axisTightPadded;
    
    target = Resistivity.targetMisfit;
    ax = axis;
    ax(1:2) = log10(ax(1:2));
    xPad = .04*(ax(2)-ax(1));
    xL = ax(1)-xPad;
    xU = ax(2)+xPad;
    xL = 10.^xL;
    xU = 10.^xU;

    plot([xL xU],[target target],'k--')
    sub_axisTightPadded;
    
    set(findobj(hFig,'type','axes')  ,'fontsize',fontSize);
    set(findobj(hFig,'type','line') ,'linewidth',lineWidth,'markersize',markerSize);
    
end

end % plotMARE2DEMIterMisfit

%--------------------------------------------------------------------------
function sub_axisTightPadded
    axis tight;
    ax = axis;
%     if strcmp(get(gca,'xscale'),'log')
%         ax(1:2) = log10(ax(1:2));
%     end
%     xPad = .04*(ax(2)-ax(1));
%     xL = ax(1)-xPad;
%     xU = ax(2)+xPad;
%     if strcmp(get(gca,'xscale'),'log')
%         xL = 10.^xL;
%         xU = 10.^xU;
%     end
%     xlim([xL xU]);
    if strcmp(get(gca,'yscale'),'log')
        ax(3:4) = log10(ax(3:4));
    end    
    yPad = .04*(ax(4)-ax(3));
    yL = ax(3)-yPad;
    yU = ax(4)+yPad;
    if strcmp(get(gca,'yscale'),'log')
        yL = 10.^yL;
        yU = 10.^yU;
    end    
    
    ylim( [yL yU] );
end
    
%--------------------------------------------------------------------------
function   stOCC = readOccLogfile(lfile)
stOCC= [];
stOCC(1).rough = [];
if ~exist(lfile,'file')
    return
end

fid = fopen(lfile,'r');
if fid<0
    return
end

ict = 0;
 
% Preallocate for speed
stOCC(1000).iter = [];

while 1
    line=fgets(fid);
    if line==-1
        break
    end
    line  = lower(line);

    if contains(line,'format:     occamlog.2012.0')

    elseif contains(line,'** iteration')

        % start new record:
        ict = ict + 1;
        halfcount = 0;
        stOCC(ict).iter = sscanf(line,'** iteration    %i **');
        stOCC(ict).sIter = sprintf('Iter: %i',floor(stOCC(ict).iter));
        stOCC(ict).misfit = []; % reset
        stOCC(ict).misfitFinal = []; % reset
        stOCC(ict).misfitCSEM = []; % reset
        stOCC(ict).misfitMT = []; % reset
        stOCC(ict).misfitCSEMstarting = []; % reset
        stOCC(ict).misfitMTstarting = []; % reset
        stOCC(ict).mu = [];
        stOCC(ict).rough = [];
        lGetStartRMS = true;
        stOCC(ict).iterationSeconds  = [];

    elseif contains(line,'cutting')
        % first save last loop
        %             stOCC(ict).misfit = misfit;
        %             stOCC(ict).mu = mu;

        % start new record:
        ict = ict+1;
        halfcount = halfcount+1;
        stOCC(ict).iter = floor(stOCC(ict-1).iter)+1/(2^halfcount);
        stOCC(ict).sIter = sprintf('Iter: %i, Step-cut %i',floor(stOCC(ict).iter),halfcount);
        stOCC(ict).misfit = []; % reset
        stOCC(ict).misfitFinal = []; % reset
        stOCC(ict).misfitCSEM = []; % reset
        stOCC(ict).misfitMT = []; % reset           
        stOCC(ict).mu = [];
        stOCC(ict).rough = [];

    elseif contains(line,'restarted')
        irestart = sscanf(line,'  *** occam restarted here from iteration:%i');

        for i = 1:ict
            if stOCC(i).iter == irestart
                stOCC = stOCC(1:i);
                ict = i;
                break
            end
        end
    elseif contains(line,'model misfit')
        stOCC(ict).misfitFinal = sscanf(line,'                  model misfit: %g');

    elseif contains(line,'csem misfit')
         val = sscanf(line,'                   csem misfit: %g');

%         if ict == 1 && isempty(stOCC(ict).misfitCSEMstarting)
%             stOCC(ict).misfitCSEMstarting = val;
%         else
            stOCC(ict).misfitCSEM = val;
%        end 

    elseif contains(line,'mt misfit')

        val = sscanf(line,'                     mt misfit: %g'); 
%         if ict == 1 && isempty(stOCC(ict).misfitMTstarting)
%             stOCC(ict).misfitMTstarting = val;
%         else
            stOCC(ict).misfitMT = val;
%        end

    elseif contains(line,'convergence status')
        stOCC(ict).convergenceStatus = sscanf(line,'            convergence status:  %g');

    elseif contains(line,'iteration time, cumulative (s):')
        val = sscanf(line,'iteration time, cumulative (s):%g'); 
        stOCC(ict).iterationSeconds = val;   % just retrieve iteration time

    elseif ~isempty(sscanf(line,'%g'))


        vars = sscanf(line,'%g');

        if (length(vars) < 7 )
            continue
        end

        if lGetStartRMS
            stOCC(ict).startingRMS = vars(1);
            stOCC(ict).startingRoughness = vars(2);
            lGetStartRMS = false;
        else
            stOCC(ict).misfit = [stOCC(ict).misfit, vars(1)];
            stOCC(ict).mu     = [stOCC(ict).mu, 10.^vars(3)];
            stOCC(ict).rough  = [stOCC(ict).rough, vars(2)];
        end

    end
end
 
stOCC = stOCC(1:ict);

fclose(fid);
end

%--------------------------------------------------------------------------
function ht = my_xticklabels(varargin)

%MY_XTICKLABELS replaces XTickLabels with "normal" texts
%   accepting multiline texts and TEX interpreting
%   and shrinks the axis to fit the texts in the window
%
%    ht = my_xticklabels(Ha, xtickpos, xtickstring)
% or
%    ht = my_xticklabels(xtickpos, xtickstring)
%
%  in:    xtickpos     XTick positions [N*1]
%        xtickstring   Strings to use as labels {N*1} cell of cells
%
% Examples:
% plot(randn(20,1))
% xtl = {{'one';'two';'three'} '\alpha' {'\beta';'\gamma'}};
% h = my_xticklabels(gca,[1 10 18],xtl);
% % vertical
% h = my_xticklabels([1 10 18],xtl, ...
%     'Rotation',-90, ...
%     'VerticalAlignment','middle', ...
%     'HorizontalAlignment','left');

% Pekka Kumpulainen 12.2.2008
%
% Modified by Kerry Key for 'ydir','reverse' plots

textopts = {};
if length(varargin{1})==1 && ...
        ishandle(varargin{1}) && ...
        strcmpi(get(varargin{1},'Type'),'axes')
    Ha = varargin{1};
    xtickpos = varargin{2};
    xtickstring = varargin{3};
    if nargin() > 3
        textopts = varargin(4:end);
    end
else
    Ha = gca;
    Hfig = get(Ha,'Parent');
    xtickpos = varargin{1};
    xtickstring = varargin{2};
    if nargin() > 2
        textopts = varargin(3:end);
    end
end

set(Ha,'XTick',xtickpos, 'XTickLabel','')
h_olds = findobj(Ha, 'Tag', 'MUXTL');
if ~isempty(h_olds)
    delete(h_olds)
end

%% Make XTickLabels
NTick = length(xtickpos);
Ydir = get(gca,'ydir');
if strcmp(Ydir,'reverse')
    Ybot = max(get(gca,'YLim'));
else
    Ybot = min(get(gca,'YLim'));
end

% Add on padding to account for outward y tick length:
tl = get(gca,'TickLength');
% convert to points
Ybot = Ybot - tl(2);

ht = zeros(NTick,1);
for ii = 1:NTick
    ht(ii) = text('String',xtickstring{ii}, ...
        'Units','data', ...
        'VerticalAlignment', 'top', ...
        'HorizontalAlignment', 'center ', ...
        'Position',[xtickpos(ii) Ybot], ...
        'Tag','MUXTL');
end
if ~isempty(textopts)
    set(ht,textopts{:})
end

%% squeeze axis if needed
% haunits = get(Ha,'units');
% htunits = get(ht,'units');
%
% set(Ha,'Units','pixels')
% Axpos = get(Ha,'Position');
% % set(Hfig,'Units','pixels')
% % Figpos = get(Hfig,'Position');
%
% set(ht,'Units','pixels')
% TickExt = zeros(NTick,4);
% for ii = 1:NTick
%     TickExt(ii,:) = get(ht(ii),'Extent');
% end
%
% needmove = -(Axpos(2) + min(TickExt(:,2)));
%
% if needmove>0;
%     Axpos(2) = Axpos(2)+needmove+2;
%     Axpos(4) = Axpos(4)-needmove+2;
%     set(Ha,'Position',Axpos);
% end
%
% set(Ha,'Units',haunits)
% %set(ht,'Units',htunits)
end

%--------------------------------------------------------------------------
function sub_removeFEmesh(hObject,~,hFig)

    delete(findobj(hFig,'tag','femesh'));

end
%--------------------------------------------------------------------------
function sub_plotFEmesh(hObject,~,hFig)

[ff, pp] = uigetfile('*.ele', 'Select FE mesh file (.ele)');

if length(ff) == 1 && ff <= 0
    return
end
[~,n,~] = fileparts(ff);

froot  = fullfile(pp,n);
  
  
% Read .node file:
    fid     = fopen(strcat(froot,'.node'),'r');
    temp    = fscanf(fid,'%i %i %i %i\n',4);
    nvert   = temp(1);
    natr    = temp(3);
    nbndmrk = temp(4);
    nodes   = fscanf(fid,'%g',[ 3+natr+nbndmrk,nvert]);
    fclose(fid);

% Read .ele file:
    fid     = fopen(strcat(froot,'.ele'),'r');
    temp    = fscanf(fid,'%i %i %i\n',3);
    ntri    = temp(1);
    ndptri  = temp(2);
    natr    = temp(3);  
    tris    = fscanf(fid,'%g',[1+ndptri+natr,ntri]);
    fclose(fid);
    
    TR = triangulation(tris(2:4,:)',nodes(2:3,:)');

% Delete any existing FE mesh on plot:
    delete(findobj(hFig,'tag','femesh'));
    
   
% Plot mesh:
    h = triplot(TR,'k');
    set(h,'tag','femesh');
    
    
    sub_uistack(hFig);
end
