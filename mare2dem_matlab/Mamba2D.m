function varargout = Mamba2D(varargin)
%
% Mamba2D: MARE2DEM Model Building Assistant
%
% Usage: generally just call Mamba2D without any arguments and use the GUI
% buttons to create or import content.  
%
% Copyright 2017-2021
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


% Begin initialization code - DO NOT EDIT
gui_Singleton = 0;
gui_State = struct('gui_Name', mfilename, ...
    'gui_Singleton',  gui_Singleton, ...
    'gui_OpeningFcn', @Mamba2DOpeningFcn, ...
    'gui_OutputFcn',  @Mamba2DOutputFcn, ...
    'gui_LayoutFcn',  [] , ...
    'gui_Callback',   []);
 
if nargin==1  && ischar(varargin{1}) % call with .resistivity file input only
    % don't str2func...
else
    if nargin && ischar(varargin{1})
        gui_State.gui_Callback = str2func(varargin{1});
    end
end

%
% Do the callback
%
if nargout
    [varargout{1:nargout}] = gui_mainfcn(gui_State, varargin{:});
else
    if isempty(varargin)
        gui_mainfcn(gui_State);
    else
        gui_mainfcn(gui_State,varargin{:});
    end
end
end
% End initialization code - DO NOT EDIT
 
%----------------------------------------------------------------------
% --- Executes just before GUI is made visible.
function Mamba2DOpeningFcn(hObject, ~, handles, varargin)
%----------------------------------------------------------------------

handles.output     = hObject;
handles.hModelAxes = findobj(hObject,'tag','modelaxes');
handles.hFigure    = hObject;

% Undo storage:
handles.nUndo    = 0;  % undo(i).model = model structure
handles.iUndo    = 0;  % undo(i).model = model structure
handles.nRedo    = 0;  % undo(i).model = model structure
handles.nMaxUndo = 40; % save last nMaxUndo model structures

handles.ui_figure_version = '4.11';  % new November 2020: set UI figure version so UI can be updated
% if opening .fig file saved with older version of Mamba2D.

set(handles.hFigure,'CreateFcn',{@sub_reopenFig})
%set(handles.hFigure,'SizeChangedFcn',[])

%
% Initialize data structures:
%
handles = sub_initialize(handles);
 
% Get defaults stSettings structure:
stSettings = sub_getDefaults();

% Try getting most recently used values that override the defaults:
stSettings = sub_getMRU(stSettings);

% Get the path to the Triangle C code executable:
handles = getTrianglePath(handles);  %KWK this can be removed when Triangle call is replaced

% Set up colorbar:
yb = colorbar;
set(yb,'buttondown',{},'handlevisibility','on','tag','Colorbar')
handles.hColorbar = yb;

% Create the zoom and pan objecs with autocallback:
sub_addZoomCallback(handles.hFigure);
 
% Setup UI menu items:
sub_setUImenus(handles.hFigure,stSettings);

% Save pixel dimensions:
set(handles.hModelAxes,'units','pixels');
handles.axesPosPixels = get(handles.hModelAxes,'position');
set(handles.hModelAxes,'units','normalized');

% Save handles to figure's GUI data:
guidata(hObject, handles);  

% Store setting in figure's app data:
setappdata(handles.hFigure,'stSettings',stSettings);
 
%
% Don't modify anything in handles or stSettings beneath here since guidata
% already has beed saved
%
sub_applyColorMap(handles.hFigure,stSettings.sColorMap,stSettings.sColorMapInverted)
sub_setColorScale([],[],handles.hFigure,stSettings.sColorScale);  % this updates stSettings to appdata
sub_applyColorScaleLimits(stSettings);  

sub_setAxisScale(handles,stSettings); % this sets axis equal | normal using stSettings.equalAspect

% Set axis ticks and labels:
sub_setAxisTickLabels(handles.hFigure)

% Disable the "save" button on the figure file menu so users can't
% overwrite the original .fig file. 
set(handles.hFigure, 'menubar', 'none', 'toolbar', 'none');

hButtons = findobj(handles.hFigure,'type','uicontrol','style','togglebutton');
set(hButtons,'enable','off' ); % disable all buttons until resistivity file imported or bounding box created
set(findobj(handles.hFigure,'tag','importResistivity'),'enable','on');
set(findobj(handles.hFigure,'tag','importSEGY'),'enable','off');
set(findobj(handles.hFigure,'tag','importGeoImage'),'enable','off');

path = pwd;
   
set(findobj(handles.hFigure,'tag','outputfolder'),'string',sub_formatPathString(path))
set(findobj(handles.hFigure,'tag','outputfolder'),'tooltip',path,'enable','on');


% Hijack the print button callback:
set(findall(handles.hFigure,'ToolTipString','Print Figure'),'visible','on',...
                 'ClickedCallback', {@sub_print, handles.hFigure},...
                 'ToolTipString','Print Model to Image File')
                 
% Pointer type for drawing and selecting objects
set(handles.hFigure,'pointer','arrow');
 
% Put figure in top left corner of primary monitor:
%set(handles.hFigure,'SizeChangedFcn',@resizeFcn_Callback)

set(handles.hFigure,'outerposition',stSettings.figureOuterPosition,'visible','on');
drawnow;


if ~isempty(varargin) && length(varargin)==1
   importResFile(hObject,varargin{1}) 
end
 
end

function pathstr = sub_formatPathString(path)
% wraps and truncates path string to fit in text box in UI
w = 48; 
nlimit = 3*w;
if length(path) > nlimit
    p = path(end-nlimit+1:end);
else
    p = path;
end
n = ceil(length(p)/w); 
for i= 1:n
    i0=(i-1)*w+1;
    i1= min((i)*w,length(p));
    pathstr{i} = p(i0:i1); 
    if n > 1 && i == 1
        pathstr{i} = strcat('...',pathstr{i});
    end
end

end

%--------------------------------------------------------------------------
function handles = sub_initialize(handles)
%
% Intialized Mamba2D handles.model structure 
%

% Model structure contains nodes, segments, parameters and arrays for
% plotting 
handles.model.nodes         = [];               % [y,z] of nodes
handles.model.boundingBox   = [];               % [ top bottom left right]
handles.model.segments      = sparse(1,1,0);    % Format: n x n symmetric adjacency matrix with
                                                % 1 for each column that a given node (row #) connects to.
% The DelaunayTri object for plotting the regional colors:
handles.model.DT                = [];
handles.model.DTprevious        = [];
handles.model.TriIndex          = [];
handles.model.TriIndexPrevious  = [];

handles.model.regions       = [];    % y,z points inside each region
handles.model.resistivity   = [ ];   % nregions x num_anisotropy (1,2 or 3)
handles.model.bounds        = [ ];   % nregions x 2 * num_anisotropy (lower, upper for each region, each anisotropy)
handles.model.prejudice     = [ ];   % nregions x num_anisotropy + 1. Last value is weight for prejudice.
handles.model.freeparameter = [ ];   % nregions x num_anisotropy. 0 if region is fixed, parameter number if free parameter
handles.model.anisotropy    = '';
path = pwd; 
handles.model.path = path;


% Graphics handles:
handles.hNodes          = [];  % Handle to node graphics objects
handles.hSegments       = [];  % Handle for segments graphics object
handles.hSegmentsCut    = [];  % Handle for segments graphics object
handles.hFree           = [];  % Handle for DT of parameter regions   
handles.hFixed          = [];  % Handle for DT of parameter regions 
handles.hgeo            = [];  % Handle for geoimage object, if any
handles.hsegy           = [];  % Handle for SEGY seismic image overlay


% Erase existing data structures and plot objects:
cla;
%delete(findobj(handles.hFigure,'tag','appearancemenu'));
hMenu = findobj(handles.hFigure,'tag','datamenu');
if ~isempty(hMenu), delete(hMenu); end
delete(findobj(handles.hFigure,'tag','datamenu'));

end

%--------------------------------------------------------------------------
function sub_reopenFig(hFig,~)

current_ui_version = '4.11';  

handles = guidata(hFig);

if ~isfield(handles,'ui_figure_version') || ~strcmpi(handles.ui_figure_version,current_ui_version)
    % Politely remind user that they should save .resistivity file and
    % reopen using the new Mamba2D version:
     str1 = sprintf('此Mamba2D图形来自旧版本，与当前Mamba2D.m文件不兼容。 \n');
     str2 = sprintf(' 建议保存MARE2DEM文件后重新导入Mamba2D。 \n');
     str3 = sprintf(' 是否需要我自动帮您完成？\n');
     str = strcat(str1,str2,str3);
     choice = questdlg(str,'Mamba2D图形版本过期警告','Yes', 'No','No'); 
     switch choice
         
         case 'Yes'
                         
            % Save to .resistivity file:
            writeMARE2DEM_Callback(hFig);

            % Get file name:
            sBaseFile = strtrim(get(findobj(handles.hFigure,'tag','filenameroot'),'string'));
            sResistivityFile  = sprintf('%s.0.resistivity',sBaseFile);
            if isfield(handles.model,'path') && isempty(handles.model.path)
                path = handles.model.path; 
            else
                path = pwd;
            end
            sResistivityFile = fullfile(path,sResistivityFile);
    
            % Close current figure:
            %handles.hFigure.CloseRequestFcn = [];
            handles.hFigure.SizeChangedFcn = [];
            closeFig_Callback([],[],handles,true);

            clear handles hFig;

            % Open new Mamba2D figure and load filename:
            %hFig = Mamba2D('visible','on');
            %importResFile(hFig,sResistivityFile);
            Mamba2D(sResistivityFile);
            return
                      
         otherwise
             return
        end        
     
end

addlistener(hFig,'FileName','PostSet',@(src,evnt) sub_FileNameUpdate(hFig,src,evnt));

% Turn on the zoom callback
sub_addZoomCallback(hFig);

end
%--------------------------------------------------------------------------
function sub_FileNameUpdate(hFig,src,evt)

% Set output folder to same folder .fig file was opened in:
handles = guidata(hFig);
sFile = hFig.FileName;
guiFile = which('Mamba2D.fig');
if ~strcmpi(sFile,guiFile)
    [path,~] = fileparts(sFile);

    set(findobj(handles.hFigure,'tag','outputfolder'),'string',sub_formatPathString(path));
    set(findobj(handles.hFigure,'tag','outputfolder'),'tooltip',path,'enable','on');
    handles.model.path = path;   
    guidata(hFig,handles);
end
delete(src)
 
end

function sub_addZoomCallback(hFig)

hz = zoom;
hp = pan;
hz.ActionPostCallback = @sub_zoomOrPanPostCallback;
hp.ActionPostCallback = @sub_zoomOrPanPostCallback;

end
%--------------------------------------------------------------------------
function sub_zoomOrPanPostCallback(hFig,~)
    
sub_setAxisTickLabels(hFig)

end

%--------------------------------------------------------------------------
function sub_setAxisTickLabels(hFig)

handles     = guidata(hFig);
stSettings  = getappdata(hFig,'stSettings');

set(handles.hModelAxes,'XTickMode','auto','YTickMode','auto');
 
xt = get(handles.hModelAxes,'xtick');
yt = get(handles.hModelAxes,'ytick');

% Overlabel the ticks so when panning the correct labels come up
% rather than repeats of the manual tick labels (which put incorrect labels
% for new ticks outside the original axis extent):
if length(xt) < 2, return; end
dt = diff(xt(1:2));
xt = min(xt)-10*dt:dt:max(xt)+10*dt;
set(handles.hModelAxes,'xtick',xt);

dt = diff(yt(1:2));
yt = min(yt)-10*dt:dt:max(yt)+10*dt;
set(handles.hModelAxes,'ytick',yt);

if strcmpi(stSettings.usekm,'on')
    xts = num2str(xt(:)/1d3);
    yts = num2str(yt(:)/1d3);
    xlabel('y (km)')
    ylabel('z (km)')
    
else
    xts = num2str(xt(:));
    yts = num2str(yt(:));
    xlabel('y (m)')
    ylabel('z (m)')
end
set(handles.hModelAxes,'xticklabel',xts);
set(handles.hModelAxes,'yticklabel',yts);

set(handles.hModelAxes, 'fontsize',stSettings.fontSize,'tickdir','out','ticklength',[.01 .01]/2,'box','on');

if strcmpi(stSettings.equalAspect,'on')
    daspect([1 1 1]);
end

sub_applyAxisDir(handles,stSettings);
 

end 
%--------------------------------------------------------------------------
function st = sub_getDefaults()
%
% Sets default values for Mamba2D settings. 
%
% Defaults:

% Set radial distance for selecting nearby segments and nodes:
st.dr               = 6;       % pixel radius for picking nearby nodes and segments 
st.defcircle        = 21;      % default number of segments used for ngons
st.nNodesPltSmall   = 50000;   % Delete segments updates if less than this number of nodes

st.BoundingBox = [-100000 100000 -100000 100000];  % top bottom left right in m

% Plot visibility control variables:
st.showNodes        = 'on';
st.showSegments     = 'on';
st.showFreeRegions  = 'on'; % default is to show the patch plotted polygonal regions
st.showFixedRegions = 'on'; % default is to show the patch plotted polygonal regions
st.showDTedges      = 'off';  % only for debugging

st.nodeSize        = 2;    % 'o' symbol size for nodes
st.nodeColor       = 'k';
st.tempNodeColor   = 'g';
st.tempRegionColor = [0.5 0.5 0.5];
st.segThickness    = 0.5;           
st.segColor        = 'k';
st.segColorCut     = 'w';


st.segAttributeDflt    =  1;           % Segment attribute is currently used to denote penalty cut weights. 1 is full penalty. -1 is cut.
st.sColorScale         = 'log10';      % default linear or log10 sColorScale
st.caxis               = [.1 1000];    % linear sColorScale limits, can be changed in figure menu
st.sColorMapInverted   = false;        % set to true to flipud(colormap)
st.sColorMap           = 'turbo';      % Google's better version of jet that doens't have luminance spikes.

st.fontSize            = 14;
st.usekm               = 'off'; %  turn on to use km for units rather than meter
st.reverseX            = 'off'; % for flippling axis directions
st.reverseY            = 'off';
st.equalAspect         = 'on'; 
 
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
    
end

%----------------------------------------------------------------------
function handles = sub_updateUndo(handles)
 
% Update the Undo structure with the latest model:
handles.nUndo = min(handles.nUndo+1,handles.nMaxUndo);

handles.iUndo = handles.iUndo + 1;

if handles.iUndo > handles.nMaxUndo
    handles.iUndo = 1;
end

handles.undo(handles.iUndo).model = handles.model;
handles.undoButton.Enable = 'on';
handles.redoButton.Enable = 'off';
 
handles.nRedo = 0;

end

 
%----------------------------------------------------------------------
function callbackController(hObject, ~, handles)   

 
tag = get(hObject,'tag');
if ~isstruct(handles) || ~isfield(handles, 'model') || ~isstruct(handles.model) || ~isfield(handles.model, 'boundingBox')
    return; % 不符合条件直接退出，不执行后面的判断，彻底避免报错
end

if  ~strcmpi(tag,'redoButton') && isempty(handles.model.boundingBox) && ...
    ~ismember(tag,{'createBoundingBox' 'importPoly', 'importResistivity'}) 
    beep;
    h = warndlg('添加任何元素前，请先指定模型边界框！','');
    set(h,'windowstyle','modal')
    waitfor(h);
    try  % toggle button
        set(hObject,'value',0)
    catch Me %#ok<*NASGU>
    end
    return;
end

% If in quad or triangle meshing mode, ignore any other callbacks:

if isfield(handles,'Quad') && isfield(handles.Quad,'hQuadFig') && isgraphics(handles.Quad.hQuadFig)
    figure(handles.Quad.hQuadFig);
    set(hObject,'value',0)
    return;
end


if isfield(handles,'Tri') && isfield(handles.Tri,'hTriFig') && isgraphics(handles.Tri.hTriFig)
    figure(handles.Tri.hTriFig);
    set(hObject,'value',0)
    return;
end

% Update buttons:
sub_toggleButtons(handles,'off');

% Update undo structure:  
if ~strcmpi(tag,'undoButton') && ~strcmpi(tag,'redoButton')
    
    handles = sub_updateUndo(handles);
    
    % Turn on the button that generated this callback:
    set(hObject,'foregroundcolor','g','enable','on','value',1);
 
end

%Save to guidata in the callback below fails:
handles.bChanged = false;  % this is set to true if callback calls updateModel 

guidata(hObject,handles)


% Execute the requested callback:
try 
    tag = get(hObject,'tag');
    feval(sprintf('%s_Callback',tag),hObject);
    
catch ME
    
    if  isvalid( handles.hFigure) % figure hasn't been deleted
        beep;
        fprintf('Mamba2D.m回调函数出错： %s\n',sprintf('%s_Callback',tag));
        fprintf('正在恢复到输入模型状态...\n'); 

        fprintf('\n函数出错：%s\n',ME.stack(1).name); 
        fprintf('\n错误信息： %s\n\n\n',ME.message); 

    % Should it now resort to handles.undo(1)?
    
    else
        return
    end
    
end

try % in case figure was closed already...


% Update buttons:
sub_toggleButtons(handles,'on');

% Check to see if model didn't change at all, if so adjust undo pointer so
% undo button only increments for actual model changes
handles = guidata(hObject);
if ~handles.bChanged && ~strcmpi(tag,'undoButton') && ~strcmpi(tag,'redoButton')
    handles.iUndo = handles.iUndo - 1;
    if handles.iUndo == 0
        handles.iUndo = handles.nMaxUndo;
    end
    handles.nUndo = handles.nUndo - 1;
    if handles.nUndo == 0
        handles.undoButton.Enable = 'off'; 
    end
end
guidata(hObject,handles)

 
if ~strcmpi(tag,'undoButton') && ~strcmpi(tag,'redoButton')
    set(hObject,'foregroundcolor','k','enable','on','value',0);
end
title(handles.hModelAxes,' ' )
set(handles.hFigure,'pointer','arrow')

catch
    
end

end

%--------------------------------------------------------------------------
 function sub_toggleButtons(handles,sState)

% Find all toggle buttons and turn them off:
hButtons = findobj(handles.hFigure,'type','uicontrol','style','togglebutton');
set(hButtons,'foregroundcolor','k','value',0);


% Disable Zoom buttons:
set(findobj(handles.hFigure,'tag','zoomIn'), 'enable',sState);
set(findobj(handles.hFigure,'tag','zoomOut'),'enable',sState);
set(findobj(handles.hFigure,'tag','panTool'),'enable',sState);
 
zoom off;
pan off;

% Toggle Appearance menu too:
set(findobj(handles.hFigure,'tag','appearancemenu'), 'enable',sState);

end
   
%--------------------------------------------------------------------
function sub_setUnits(hObj, ~,hFig)
 
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

%--------------------------------------------------------------------
function sub_setColorScale(~, ~,hFig,sColorScale)
 
stSettings  = getappdata(hFig,'stSettings');

stSettings  = sub_swapColorScale(stSettings,sColorScale);

setappdata(hFig,'stSettings',stSettings);

sub_plotModel(hFig);

end

%--------------------------------------------------------------------
function stSettings = sub_swapColorScale(stSettings,sColorScale)
      
sOld    = stSettings.sColorScale;
ca      = caxis(gca); %stSettings.caxis; %caxis(handles.hModelAxes);

switch lower(sColorScale)
    case 'linear'
        
        if strcmpi(sOld,'log10')
            ca = 10.^ca; 
        end
        stSettings.sColorScale = 'linear';
        stSettings.caxis       = ca;
        caxis(stSettings.caxis );
        
    case 'log10'
        stSettings.sColorScale = 'log10';
        if strcmpi(sOld,'linear')
            stSettings.caxis = ca;
            ca(1) = max(ca(1),0.001); % make sure we don't log10(0)
            ca = log10(ca);
        else
            stSettings.caxis = 10.^ca;
        end
        caxis(log10(stSettings.caxis));
        
end

end

%---------------------------------------------------------
function sub_setColorScaleLimitsAuto(~, ~,hFig)

handles     = guidata(hFig);
stSettings  = getappdata(hFig,'stSettings');

% Get range of current values and set limits based on that:
 
%KWK debug: need to add auto colorscale code here.
% should look at currently plotted parameter and DT
% regions in current view, then set limits appropriately

% if isempty(lims)
%     return
% end

%stSettings.caxis = [str2double(lims{2}) str2double(lims{1})] ;

%sub_applyColorScaleLimits(stSettings)

setappdata(hFig,'stSettings',stSettings);

sub_saveMRU(stSettings,hFig);

end


%---------------------------------------------------------
function sub_setColorScaleLimitsManual(~, ~,hFig)

handles     = guidata(hFig);
stSettings  = getappdata(hFig,'stSettings');

% Get caxis settings and save them, in case user has set them from command
% line:
stSettings.caxis = caxis(handles.hModelAxes);
if strcmp(stSettings.sColorScale,'log10')
   stSettings.caxis = 10.^stSettings.caxis; 
end
prompt  = {'上限 (ohm-m)', '下限 (ohm-m)'};
name    = '色标:';
defans  = cellstr(num2str(fliplr(stSettings.caxis)'));
lims    = inputdlg(prompt,name,1,defans);

if isempty(lims)
    return
end

stSettings.caxis = [str2double(lims{2}) str2double(lims{1})] ;

sub_applyColorScaleLimits(stSettings)

setappdata(hFig,'stSettings',stSettings);

sub_saveMRU(stSettings,hFig);

end

%---------------------------------------------------------
function sub_applyColorScaleLimits(stSettings)

ca = stSettings.caxis;
 
if strcmp(stSettings.sColorScale,'log10')
    caxis(log10(ca));
else
    caxis(ca);
end

end
%---------------------------------------------------------
function sub_showNodes_Callback(hObject, ~, ~)
 
handles     = guidata(hObject);
stSettings  = getappdata(handles.hFigure,'stSettings');

switch hObject.Checked
    case 'off'
        handles.hNodes.Visible  = 'on'; % this sets the 'visible' property of graphics handle hNodes(:)
        hObject.Checked         = 'on';     
        stSettings.showNodes    = 'on';
    case 'on'
        handles.hNodes.Visible  = 'off';
        hObject.Checked         = 'off';     
        stSettings.showNodes    = 'off';   
end

guidata(hObject,handles);
setappdata(handles.hFigure,'stSettings',stSettings);
sub_saveMRU(stSettings,handles.hFigure);

end
%---------------------------------------------------------
function sub_showSegments_Callback(hObject, ~, ~)

handles     = guidata(hObject);
stSettings  = getappdata(handles.hFigure,'stSettings');

switch hObject.Checked
    case 'off'
        handles.hSegments.Visible   = 'on';
        hObject.Checked             = 'on';     
        stSettings.showSegments     = 'on';
        if ~isempty(handles.hSegmentsCut)
            handles.hSegmentsCut.Visible = 'on';
        end

    case 'on'
        handles.hSegments.Visible   = 'off';
        hObject.Checked             = 'off';     
        stSettings.showSegments     = 'off';
        if ~isempty(handles.hSegmentsCut)
            handles.hSegmentsCut.Visible='off';
        end
  
end

guidata(hObject,handles);
setappdata(handles.hFigure,'stSettings',stSettings);
sub_saveMRU(stSettings,handles.hFigure);

end
 
%---------------------------------------------------------
function sub_showFixedRegions_Callback(hObject, ~,~)

handles     = guidata(hObject);
stSettings  = getappdata(handles.hFigure,'stSettings');

switch hObject.Checked
    case 'off'
        if ~isempty(handles.hFixed)
            handles.hFixed.Visible  = 'on';
        end
        hObject.Checked             = 'on';     
        stSettings.showFixedRegions = 'on';
    case 'on'
        if ~isempty(handles.hFixed)
            handles.hFixed.Visible  = 'off';
        end
        hObject.Checked             = 'off';  
        stSettings.showFixedRegions = 'off';
end

guidata(hObject,handles);
setappdata(handles.hFigure,'stSettings',stSettings);
sub_saveMRU(stSettings,handles.hFigure);

end 
%---------------------------------------------------------
function sub_showFreeRegions_Callback(hObject, ~,~)

handles     = guidata(hObject);
stSettings  = getappdata(handles.hFigure,'stSettings');

switch hObject.Checked
    case 'off'
        if ~isempty(handles.hFree)
            handles.hFree.Visible   = 'on';
        end
        hObject.Checked             = 'on';
        stSettings.showFreeRegions  = 'on';
    
    case 'on'
        if ~isempty(handles.hFree)
            handles.hFree.Visible   = 'off';
        end
        hObject.Checked             = 'off';
        stSettings.showFreeRegions  = 'off';  
end

guidata(hObject,handles);
setappdata(handles.hFigure,'stSettings',stSettings);
sub_saveMRU(stSettings,handles.hFigure);

end
%---------------------------------------------------------
function sub_showDTedges_Callback(hObject,~,~)

handles     = guidata(hObject);
stSettings  = getappdata(handles.hFigure,'stSettings');

switch hObject.Checked
    case 'off'
        handles.hFree.EdgeColor  = 'm';
        handles.hFixed.EdgeColor = 'm';
        hObject.Checked          = 'on';
        stSettings.showDTedges   = 'on';
    
    case 'on'
        handles.hFree.EdgeColor  = 'none';
        handles.hFixed.EdgeColor = 'none';
        hObject.Checked          = 'off';  
        stSettings.showDTedges   = 'off';
end

guidata(hObject,handles);
setappdata(handles.hFigure,'stSettings',stSettings);
sub_saveMRU(stSettings,handles.hFigure);

end

%--------------------------------------------------------------------------
function sub_setAxisDirection(hObject, ~, ~,sDir)

handles     = guidata(hObject);
stSettings  = getappdata(handles.hFigure,'stSettings');

if strcmpi(get(hObject,'checked'),'off')
    set(hObject,'checked','on')
    stSettings.(sDir) = 'on';
else
    set(hObject,'checked','off')
    stSettings.(sDir) = 'off';
    
end
    
sub_applyAxisDir(handles,stSettings);

setappdata(handles.hFigure,'stSettings',stSettings);
 
sub_saveMRU(stSettings,handles.hFigure);


end

%--------------------------------------------------------------------------
function sub_applyAxisDir(handles,stSettings)

    % x axis:
    if strcmpi(stSettings.reverseX,'on')
        set(handles.hModelAxes,'xdir','reverse');
    else
        set(handles.hModelAxes,'xdir','normal');  
    end
    % y axis:
    if strcmpi(stSettings.reverseY,'on')
        set(handles.hModelAxes,'ydir','normal');  % note that MARE2DEM 'normal' has y positive down, so normal and reverse are swapped here
    else
        set(handles.hModelAxes,'ydir','reverse');  
    end
    
    sub_saveMRU(stSettings,handles.hFigure);

end
%--------------------------------------------------------------------------
function sub_setAxisScale_Callback(hObject, ~, ~,sAxis)

handles     = guidata(hObject);
stSettings  = getappdata(handles.hFigure,'stSettings');

if strcmpi(sAxis,'equal') 
 
    if strcmpi(get(hObject,'checked'),'on')
        stSettings.equalAspect  = 'off'; 
    else
        stSettings.equalAspect = 'on'; 
    end
    set(hObject,'checked',stSettings.equalAspect);
    
    sub_setAxisScale(handles,stSettings);
    
elseif strcmpi(sAxis,'entireModel') 
    pb = pbaspect;
    axis tight
    pbaspect(pb);
  
elseif strcmpi(sAxis,'zoomToSurvey') 
    xlim = [];
    
    if  isfield(handles,'st')
        [xlim,ylim ] = m2d_estimateAreaOfInterest(handles.st);
    else
        pb = pbaspect;
        axis tight
        pbaspect(pb);
    end
 
    if ~isempty(xlim)
        
        dar = get(handles.hModelAxes,'DataAspectRatio');  

%         if any(dar ~= 1) % If axis normal:
% 
%             set(handles.hModelAxes,'xlim',xlim,'ylim',ylim)
% 
%         else %if axis equal, only set xlim:
%             pb = pbaspect;
%             factor =  norm(xlim)/norm(ylim)*pb(2)/pb(1);
%             set(handles.hModelAxes,'ylimmode','auto','xlim',xlim,'ylim',factor*ylim)
            set(handles.hModelAxes,'xlim',xlim,'ylim',ylim)
%        end
    end
    
end

zoom reset; % this makes the current view the zoom reset (i.e. double click) view;

setappdata(handles.hFigure,'stSettings',stSettings);

sub_setAxisTickLabels(handles.hFigure);
 
sub_saveMRU(stSettings,handles.hFigure);


end
%--------------------------------------------------------------------------
function  sub_setAxisScale(handles,stSettings)
    
    if strcmpi(stSettings.equalAspect,'on')
    
        set(gca,'xlimmode','auto','ylimmode','auto')
        axis auto;  % this sequence makes the axes fill the figure and then sets equal aspect
        axis fill;
        axis equal;
    else
        axis(handles.hModelAxes,'normal')
    end
    
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
 
handles     = guidata(hObject);
stSettings  = getappdata(handles.hFigure,'stSettings');

sub_saveMRU(stSettings,handles.hFigure);

end

%--------------------------------------------------------------------------
function sub_resetToDefaults(hObject,~, hFig )

% Delete existing MRU file:
[p, f] = fileparts( mfilename('fullpath') );
sMRU = fullfile( p, [f '.mru'] );
delete(sMRU);

% Delete any Rx/Tx name text on figure:
delete(findobj(hFig,'tag','csemRxNames'))
delete(findobj(hFig,'tag','txNames'))
delete(findobj(hFig,'tag','mtRxNames'))
    
% Delete Rx and Tx plots:
delete(findobj(hFig,'tag','csemsites'))
delete(findobj(hFig,'tag','mtsites'))
delete(findobj(hFig,'tag','transmitters'))
    
% Get the defaults
stSettings = sub_getDefaults();

% save new settings:
sub_saveMRU(stSettings,hFig);

setappdata(hFig,'stSettings',stSettings);

set(hFig,'outerposition',stSettings.figureOuterPosition,'visible','on');

sub_applyColorMap(hFig,stSettings.sColorMap,stSettings.sColorMapInverted);
sub_setColorScale([],[],hFig,stSettings.sColorScale);  % this updates stSettings to appdata
sub_applyColorScaleLimits(stSettings)

% Update UI menus with correct check boxes:    
sub_setUImenus(hFig,stSettings)
 
% Update axes directions:
handles     = guidata(hFig);
if strcmpi(get(findobj(hFig,'tag','reverseX'),'checked'),'on')
    set(handles.hModelAxes,'xdir','reverse');
else
    set(handles.hModelAxes,'xdir','normal');
end
 
if strcmpi(get(findobj(hFig,'tag','reverseY'),'checked'),'on')
    set(handles.hModelAxes,'ydir','normal');
else
    set(handles.hModelAxes,'ydir','reverse');
end
setappdata(hFig,'bFigChanged',true);

sub_plotModel(hFig); 
    
end
%---------------------------------------------
function handles = getTrianglePath(handles)

% Because we are now asking for the path, it comes up that whenever you load a
% .resistivity file, you get asked again. So check to see if we have it already
% and don't ask again.
if isfield( handles, 'tricode' ) && exist( handles.tricode, 'file' )
    return;
end

% Path to compiled Triangle c code
bAskForIt = false;
if exist('Mamba2D_TrianglePath.m', 'file')
    trianglepath = Mamba2D_TrianglePath();
    % Check to see that c-code is really there:
    if exist(trianglepath, 'file')==2
        handles.tricode = trianglepath;
    else % display error
        bAskForIt = true;
    end
else
    bAskForIt = true;
end

if bAskForIt
    beep;
    waitfor( errordlg( {
        '找不到Triangle可执行文件！'
        '请在接下来的对话框中选择可执行文件。'
        } ) );
    if ispc()
        cSpec = {'*.exe', 'Executables (*.exe)'};
    else
        cSpec = {'*.', 'Executables (*.)'};
    end
    [sF, sP] = uigetfile( cSpec, '选择Triangle可执行文件' );
    if ~ischar(sF)
        return;
    end
    handles.tricode = fullfile( sP, sF );
end
end
%----------------------------------------------------------------------
% --- Outputs from this function are returned to the command line.
function varargout = Mamba2DOutputFcn(hObject, eventdata, handles)
%----------------------------------------------------------------------
% varargout  cell array for returning output args (see VARARGOUT);
% hObject    handle to figure
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)

% Get default command line output from handles structure
varargout{1} = handles.output;
end

%----------------------------------------------------------------------
function addSegment_Callback(hObject)

handles     = guidata(hObject);
stSettings  = getappdata(handles.hFigure,'stSettings');

set(handles.hFigure,'pointer','cross')

but = 1;
lastNode =[];
selected = [];
nNew     = 0;

nSign  = 1; 

while but == 1
     
    % get a point from the mouse:
    [x0, y0, but] = sub_getPoints(1,handles.hFigure,handles.hModelAxes); 
    if but~=1
        break
    end
    ax = axis(handles.hModelAxes);
    if x0 < ax(1) || x0 > ax(2) || y0 < ax(3) || y0 > ax(4)
        break
    end
     
    [handles, isegNodes] = sub_addNodeSeg(x0,y0,handles,stSettings,lastNode,stSettings.segAttributeDflt);
    
    if isempty(isegNodes)
        continue;
    end
    
    lastNode = isegNodes(1);
    
    nNew = nNew + 1;
    
    % Get updated position (in case nearby node selected):
    x0 = handles.model.nodes(lastNode,1);
    y0 = handles.model.nodes(lastNode,2);
    
    line(x0,y0,'marker','o','markersize',stSettings.nodeSize,...
            'markerfacecolor',stSettings.tempNodeColor,'color',stSettings.tempNodeColor,...
            'linestyle','none','tag','tempNode','visible','on');
        
    if length(isegNodes)>1 % turn previous last node back to normal color (overprint for temporarily) along with other new nodes for divided segments
        
        x0 = handles.model.nodes(isegNodes,1);
        y0 = handles.model.nodes(isegNodes,2);

        line(x0,y0,'marker','none','color',stSettings.segColor ,...
        'linestyle','-','tag','tempNode','visible','on','linewidth',stSettings.segThickness);    
    
            
        line(x0(2:end),y0(2:end),'marker','o','markersize',stSettings.nodeSize,...
                'markerfacecolor',stSettings.nodeColor,'color',stSettings.nodeColor,...
                'linestyle','none','tag','tempNode','visible','on');    
    
    end
  
    
end  % while loop
 
if nNew > 0

    % Update the model and plot it:
    sub_updateModelPlot(handles);  % saves h to guidata so no need to do that here again
    % NB: The temporary new nodes are deleted by sub_updateModelPlot
 
end

% Exit gracefully:

set(handles.hFigure,'pointer','arrow')

end
%----------------------------------------------------------------------
function addRectangle_Callback(hObject)
    handles = guidata(hObject);
    stSettings = getappdata(handles.hFigure,'stSettings');

    set(handles.hFigure,'pointer','cross')
    title(handles.hModelAxes,'*** 在模型坐标轴上拖动矩形 ***','color','r')
 
    while 1
        [x0, x1, y0, y1] = selectWithRBBox(handles);
        
        if isempty(x0)
            break;
        end
        
        ax = axis(handles.hModelAxes);
        if x0 < ax(1) || x0 > ax(2) || y0 < ax(3) || y0 > ax(4)
            break
        end    
        
        % 矩形四个顶点
        points = [x0 y0; x0 y1; x1 y1; x1 y0; x0 y0];
        lastNode = [];
        
        % 逐个添加节点和线段
        for i = 1:size(points,1)
            [handles, n] = sub_addNode(points(i,1), points(i,2), handles, stSettings, 0);
            if ~isempty(lastNode)
                handles.model.segments(lastNode, n) = 1;
                handles.model.segments(n, lastNode) = 1;
            end
            lastNode = n;
        end
        
        % 标记修改并刷新
        handles.bChanged = true;
        guidata(hObject, handles);
        sub_updateModelPlot(handles);
    end
    
    title(handles.hModelAxes,'')
    set(handles.hFigure,'pointer','arrow')
end

%--------------------------------------------------------------------------
function addHoriz_Callback(hObject)
    handles = guidata(hObject);
    
    % 弹出输入框，支持同时输入多个深度（用空格分隔）
    answer = inputdlg('Layer Boundary Depths (m):','水平线深度');
    if isempty(answer), return; end
    
    depths = str2double(strsplit(answer{1}));
    depths = depths(isfinite(depths)); % 过滤无效输入
    if isempty(depths), return; end
    
    % 获取边界框 [top bottom left right]
    bbox = handles.model.boundingBox;
    y_left = bbox(3);
    y_right = bbox(4);
    
    % 获取全局设置
    stSettings = getappdata(handles.hFigure,'stSettings');
    
    % 逐个添加水平线
    for z = depths
        % 只添加两个端点，不调用任何其他函数
        [handles, n1] = sub_addNode(y_left, z, handles, stSettings, 0);
        [handles, n2] = sub_addNode(y_right, z, handles, stSettings, 0);
        
        % 直接在邻接矩阵中添加线段
        handles.model.segments(n1, n2) = 1;
        handles.model.segments(n2, n1) = 1;
    end
    
    % 标记修改并保存
    handles.bChanged = true;
    guidata(hObject, handles);
    
    % 调用我们修复好的刷新函数显示
    sub_updateModelPlot(handles);
end
%--------------------------------------------------------------------------
function addVert_Callback(hObject)

sub_addLayer(hObject,'vert');

end

%--------------------------------------------------------------------------
function sub_addLayer(hObject,sOrient)

handles     = guidata(hObject);
stSettings  = getappdata(handles.hFigure,'stSettings');

% Ask user layer top depth:
% Make pop up box with x and z info for this node:
if isempty(handles.model.boundingBox)
    beep;
    h = warndlg('添加层前请先指定模型边界框！','');
    set(h,'windowstyle','modal')
else
    
    num_lines= [1 40];
        
    switch lower(sOrient)
        
        case 'horiz'
            
            prompt = {'Layer Boundary Depths (m):'};
            dlg_title = 'Horizontal Layering:';
  
            answer = inputdlg(prompt,dlg_title,num_lines);
            
        case 'vert'
                        
            prompt = {'Layer Boundary Positions (m):'};
            dlg_title = 'Vertical Layering:';
            
            answer = inputdlg(prompt,dlg_title,num_lines);
            
    end
    
        
    if ~isempty(answer)

        %nSegAttr = sub_penaltyCutQuestion( stSettings.segAttributeDflt );
        nSegAttr = 1;
         
        layers = str2num(answer{1}); %#ok<ST2NM> % keep this str2num so formulas e.g., '1000:1000:5000' work
         
        topSide     = handles.model.boundingBox(1);
        bottomSide  = handles.model.boundingBox(2);           
        leftSide    = handles.model.boundingBox(3);
        rightSide   = handles.model.boundingBox(4);        
            
        if isnumeric(layers) && ~isempty(layers)
            
            for i = 1:length(layers)
                
                l = layers(i);
 
                switch lower(sOrient)

                    case 'horiz'

                    if l == topSide || l == bottomSide
                        continue;
                    end  
                    
                    xl = leftSide;
                    xr = rightSide;
                    
                    yl = l;
                    yr = l;
              
                    case 'vert'

                    if l == leftSide || l == rightSide
                        continue;
                    end  
                    
                    yl = topSide;
                    yr = bottomSide;
                    
                    xl = l;
                    xr = l;   

                end
  
                % Insert the left node:
                lastNode = [];
                
                minDist = 0;  % force new node always unless exactly equal
                
                [handles, isegNodes] = sub_addNodeSeg(xl,yl,handles,stSettings,lastNode,nSegAttr,minDist);  
                
                % Insert right node and the segment:
                [handles, ~] = sub_addNodeSeg(xr,yr,handles,stSettings,isegNodes(1),nSegAttr,minDist);  
                
            end
        end
    end
 
 
    % Update the model and plot it:
    sub_updateModelPlot(handles);  % saves h to guidata so no need to do that here again
    % NB: The temporary new nodes and regions are deleted by sub_updateModelPlot     

end % outer while loop for moving nodes

set(handles.hFigure,'pointer','arrow')
 
end

%--------------------------------------------------------------------------
function undoButton_Callback(hObject)
%R2015b
 
handles = guidata(hObject);

if handles.nUndo > 0
    
    set( handles.hFigure, 'Pointer', 'watch' ); drawnow;
    
    % SaveGet current model:
    current = handles.model;
    
    % Replace current with top of undo stack:
    handles.model = handles.undo(handles.iUndo).model;
    
    % Insert current at iUndo for redo option:
    handles.undo(handles.iUndo).model = current;
    
    % increment undo pointer and counter:
    handles.iUndo = handles.iUndo - 1;
    if handles.iUndo == 0
        handles.iUndo = handles.nMaxUndo;
    end
    
    handles.nUndo = handles.nUndo - 1;
    if handles.nUndo == 0
        handles.undoButton.Enable = 'off';
    end
    
    handles.nRedo = handles.nRedo + 1;
    handles.redoButton.Enable = 'on';
        
    % get path in GUI tooltip since sometimes .fig is moved from one folder
    % to another and we don't want old folder path in undo handles to take over.
    handles.model.path = get(findobj(handles.hFigure,'tag','outputfolder'),'tooltip');
  
    if isempty(handles.model.nodes)        
        cla(handles.hModelAxes)
        guidata(hObject,handles)
        handles.undoButton.Enable = 'off';
 
    else
        
        % Update the model and plot it:
        sub_updateModelPlot(handles);  % saves h to guidata so no need to do that here again
    end
    
    set(handles.hFigure,'pointer','arrow')
   
    if isempty(handles.model.nodes) % all the way back at the start..
        hButtons = findobj(handles.hFigure,'type','uicontrol','style','togglebutton');
        set(hButtons,'enable','off' ); % disable all buttons until resistivity file imported or bounding box created
        set(findobj(handles.hFigure,'tag','importResistivity'),'enable','on');
        set(findobj(handles.hFigure,'tag','importSEGY'),'enable','off');
        set(findobj(handles.hFigure,'tag','importGeoImage'),'enable','off');
        set(findobj(handles.hFigure,'tag','redoButton'),'enable','on' );
    end
end

% wow, that was easy now that the core model and plot updating routines
% have been updated, whew!

 set(hObject,'foregroundcolor','k','value',0);
 
end

%--------------------------------------------------------------------------
function redoButton_Callback(hObject) %#ok<DEFNU>
%R2015b
 
handles = guidata(hObject);

if handles.nRedo > 0
    
    set( handles.hFigure, 'Pointer', 'watch' ); drawnow;
    
    % SaveGet current model:
    current = handles.model;
   
    handles.iUndo = handles.iUndo + 1;   
    if handles.iUndo > handles.nMaxUndo
        handles.iUndo = 1;
    end
    
    handles.nUndo = handles.nUndo + 1;
       
    handles.undoButton.Enable = 'on';
    
    handles.model = handles.undo(handles.iUndo).model;
    
    handles.undo(handles.iUndo).model = current;
    
    handles.nRedo = handles.nRedo - 1;
    
    if handles.nRedo == 0
        handles.redoButton.Enable = 'off';
    end
    
    if isempty(handles.model.nodes)        
        cla(handles.hModelAxes)
        guidata(hObject,handles)
        handles.redoButton.Enable = 'off';
 
    else
        
        % Update the model and plot it:
        sub_updateModelPlot(handles);  % saves h to guidata so no need to do that here again
    end
    set(handles.hFigure,'pointer','arrow')

    hButtons = findobj(handles.hFigure,'type','uicontrol','style','togglebutton');
    set(hButtons,'enable','on' );

end

set(hObject,'foregroundcolor','k','value',0);
 
end
%----------------------------------------------------------------------
function counter_Callback(hObject, ~, handles)  
    % === 修复版：光标位置回调，加容错避免点索引报错 ===
    % 先判断handles是不是结构体，有没有需要的字段
    if ~isstruct(handles) || ~isfield(handles, 'hModelAxes') || ~isfield(handles, 'hFigure')
        return; % 不符合条件直接退出，不执行后面的代码，就不会报错了
    end

% Cursor position:
[x,y] = gpos( handles.hModelAxes, handles.hFigure);
set(findobj(hObject,'tag','cursorPosition'),'string',sprintf('%8g   %8g',x,y))

% Get resistivity at x,y:
return

 
end
%----------------------------------------------------------------------
function addNgon_Callback(hObject)

handles     = guidata(hObject);
stSettings  = getappdata(handles.hFigure,'stSettings');

% Get number of points to add:
str1 = 'Numer of sides:';
str2 = 'Center Position [ y z ] (m): ';
str3 = 'Radius (m): ';
temp = inputdlg({str1; str2; str3},'N-gon',1,{num2str(stSettings.defcircle); ''; ''});
if ~isempty(temp)
    [nsides,ct] = sscanf(temp{1},'%g');
    err = 0;
    if ct ~=1
        err=1;
        fprintf('正多边形函数错误：边数输入无效 : %s',temp{1});
    end
    [center,ct] = sscanf(temp{2},'%g %g');
    if ct ~=2
        err=1;
        fprintf('正多边形函数错误：中心位置输入无效: %s',temp{2});
    end
    
    [radius,ct] = sscanf(temp{3},'%g');
    if ct ~=1
        err=1;
        fprintf('正多边形函数错误：半径输入无效 : %s',temp{3});
    end
    
    % Check for correct input syntax:
    if err
        disp('请重新输入正多边形参数')
    elseif nsides>2
         
        x0 = center(1);
        y0 = center(2);
   
        
        L = -pi/2+linspace(0,2*pi,nsides+1);
        L = L(1:end-1);
        xv = x0+ radius*cos(L)';
        yv = y0+ radius*sin(L)';
        
        lastNode = [];
        
        for i = 1:length(L)
            
            
            % Carefully add each node and segment:
            [handles, iSegNodes] = sub_addNodeSeg(xv(i),yv(i),handles,stSettings,lastNode,stSettings.segAttributeDflt,0);
            lastNode = iSegNodes(1);
        end
        % Add the last node:
        [handles, ~] = sub_addNodeSeg(xv(1),yv(1),handles,stSettings,lastNode,stSettings.segAttributeDflt,0);
        
        
    else
        fprintf('正多边形：%i 条边不足，未添加正多边形',nsides);
    end
    
end

% Update the model and plot it:
sub_updateModelPlot(handles);  % saves h to guidata so no need to do that here again
        
title(handles.hModelAxes,'')
 
set(handles.hFigure,'pointer','arrow')

end
%----------------------------------------------------------------------
function createBoundingBox_Callback(hObject)

handles = guidata(hObject);

stSettings  = getappdata(handles.hFigure,'stSettings');

if ~isempty(handles.model.boundingBox) && ~isempty(handles.model.nodes)
 
    str0 = '警告：您即将修改现有模型边界框。';
    str1 = '如果您正在修改反演网格，这可能会导致问题！';
    str2 = ' 确定要继续吗?'
    str = sprintf('%s\n%s\n%s',str0,str1,str2);
    choice = questdlg(str,'Mamba2D','Yes', 'No','No');       
    switch choice
        case 'No'
            return;
    end
end     

% Dialog to get bounding box: 
 
if isempty(handles.model.boundingBox)
    top   = stSettings.BoundingBox(1);
    bot   = stSettings.BoundingBox(2);
    left  = stSettings.BoundingBox(3);
    right = stSettings.BoundingBox(4);
else
    top   = handles.model.boundingBox(1);
    bot   = handles.model.boundingBox(2);
    left  = handles.model.boundingBox(3);
    right = handles.model.boundingBox(4);
end

options.Resize='on';
stra = 'CSEM：边界应距离最近的收发器至少100公里。';
strb = 'MT：边界应距离最近的接收器至少500-1000公里';
strc = 'from nearest receivers. Even wider ';
strc2 ='boundaries may be needed for models'; 
strd = 'with strong 2D effects (for example';
strd2 = 'long period responses for coastline models).';
stre = 'Top (m):';
str1 = sprintf('%s\n\n%s\n%s\n%s\n%s\n%s\n\n%s',stra,strb,strc,strc2,strd,strd2,stre); 
str = {str1 'Bottom (m):' 'Left (m):' 'Right (m):' };
defaultanswer ={sprintf('%g ',top) sprintf('%i ',bot)  sprintf('%g ',left)  sprintf('%g ',right)    };
stitle = 'Model Bounding Box:';        
answer = inputdlg(str,stitle, [1, length(stitle)+22],defaultanswer,options);

if isempty(answer)
    return
end

top     = str2double(answer{1});
bot  = str2double(answer{2});
left    = str2double(answer{3});
right   = str2double(answer{4});

% New or modify?
 
if length([top;bot;left;right])<4
    str = sprintf('Mamba2D.m出错 \n 您忘记输入所有边界框坐标！');
    
    h = warndlg(str,'Mamba2D');
    set(h,'windowstyle','modal')
    waitfor(h);
    return
end

if top>bot    
    
    str = sprintf('边界框警告：顶部深于底部，已交换数值');
    beep;
    h = warndlg(str,'Mamba2D');
    set(h,'windowstyle','modal')
    waitfor(h);
     
    temp = bot;
    bot  = top;
    top  = temp;
end

if left>right
 
    str = sprintf('边界框警告：左侧大于右侧，已交换数值');
    beep;
    h = warndlg(str,'Mamba2D');
    set(h,'windowstyle','modal')
    waitfor(h);    
   
    temp = right;
    right = left;
    left = temp;
 
end
x = [left left right right]';
y = [top bot bot top]';

% Modify old bounding box nodes if they exist

if ~isempty(handles.model.boundingBox) && ~isempty(handles.model.nodes)
    
    oldBB = handles.model.boundingBox;
    
    % Get all nodes located on boundary (in addition to just the corner
    % nodes):
    lTop   = handles.model.nodes(:,2) == oldBB(1);
    lBot   = handles.model.nodes(:,2) == oldBB(2);
    lLeft  = handles.model.nodes(:,1) == oldBB(3);
    lRight = handles.model.nodes(:,1) == oldBB(4);
    
    % Check to see that the new BB doesn't orphan any nodes. Meaning the
    % new box does not leave non-boundary nodes located outside its dimensions.
    
    bInPoly = inpolygon(handles.model.nodes(:,1),handles.model.nodes(:,2),x,y);

    lInterior = ~lTop & ~lBot & ~lLeft & ~lRight;

    if any(~bInPoly(lInterior))
        str0 = '请求的新边界框会导致部分内部模型线段节点孤立。 ';
        str1 = '操作中止。';
        str2 = '  请尝试增大边界框或移除有问题的节点。';
        str = sprintf('%s\n%s\n%s',str0,str1,str2);
        h = errordlg(str,'Mamba2D错误','modal');
        waitfor(h);
        return  
    else
        handles.model.nodes(lTop,2)   = top;
        handles.model.nodes(lBot,2)   = bot;
        handles.model.nodes(lLeft,1)  = left; 
        handles.model.nodes(lRight,1) = right;  
        handles.model.boundingBox     = [top bot left right];
        
        % ====================== 修复：添加DT对象空值保护 ======================
        % Update DT Points and regions points
        if isfield(handles.model, 'DT') && ~isempty(handles.model.DT) && isobject(handles.model.DT)
            % get index of modified nodes:
            iModNode = find( handles.model.DT.Points ~= handles.model.nodes);
            % get index of triangles containing said nodes:
            TR = handles.model.DT.ConnectivityList;
            lTriMod = ( ismember(TR(:,1),iModNode) |  ismember(TR(:,2),iModNode) |  ismember(TR(:,3),iModNode));
            % get centers of modified triangles:
            x = handles.model.nodes(:,1);
            y = handles.model.nodes(:,2);
            xc = sum(x(TR(lTriMod,:)),2)/3;
            yc = sum(y(TR(lTriMod,:)),2)/3;
            % center of modified triangles:
            if isfield(handles.model, 'TriIndex') && ~isempty(handles.model.TriIndex) && length(handles.model.TriIndex) == size(TR,1)
                iTriIndex = handles.model.TriIndex(lTriMod);
                handles.model.regions(iTriIndex,:) = [xc,yc];
            end
        end
        % ======================================================================
       
    end
 
   
    
else % First bounding box:
     
    handles.model.boundingBox = [top bot left right];
    
    segs = [ 1 2; 2 3; 3 4; 4 1];
    
    handles.model.nodes = [x(:) y(:)];
 
    n = size(handles.model.nodes,1);
 
    handles.model.segments = sparse([segs(:,1);segs(:,2)],[segs(:,2);segs(:,1)],ones(2*size(segs,1),1),n,n);  
    
end

% Set Axes limits with bounding box:
dx = (right - left)*.0000005;
dy = (bot - top)*.0000005; % make it tight but not perfect since sometimes nodes are then clipped

handles.hModelAxes.XLim = [left-dx right+dx];
handles.hModelAxes.YLim = [top-dy bot+dy];


% Plot model:
sub_updateModelPlot(handles);  % saves h to guidata so no need to do that here again

hButtons = findobj(handles.hFigure,'type','uicontrol','style','togglebutton');
set(hButtons,'enable','on' );

%set(findobj(h.hFigure,'tag','redoButton'),'enable','off' );
% ========== 初始化叠加橙色底色，不破坏任何交互 ==========
ax = gca;
% 删除旧底色，避免多次点击叠加
% ========== 初始化叠加底色，与原生色标完全一致 ==========
ax = gca;
% 删除旧底色，避免多次点击叠加多层
delete(findobj(ax,'Type','patch','EdgeColor','none'));

if isfield(handles.model,'nodes') && ~isempty(handles.model.nodes)
    x = handles.model.nodes(:,1);
    z = handles.model.nodes(:,2);
    
    % 严格对齐原生色标设置，保证颜色映射完全一致
    colormap(ax, jet);
    caxis(ax, [-1, 2]);
    
    % 使用和原生相同的电阻率数值映射，不用硬编码RGB
    hBg = fill(ax, [min(x),max(x),max(x),min(x)], ...
                   [min(z),min(z),max(z),max(z)], ...
                   log10(10), 'EdgeColor','none');
    uistack(hBg, 'bottom');
end
% =====================================================

end
%--------------------------------------------------------------------------
function segs = sub_getSegments(spAdj)
%
% Given sparse node adjacency array, returns nsegs x 2 listing of segment
% endpoint nodes
%
[i,j,v] = find(triu(spAdj,1)); 

% catch to remove any errant diagonal entries:
ldiag = i == j;
i(ldiag) = [];
j(ldiag) = [];
v(ldiag) = [];

% output array:
segs = [i j v];

end

%--------------------------------------------------------------------------
function sub_updateModelPlot(h)
    % 修复版：保留边界框设置的坐标轴范围和方向
    % 只绘制节点和线段，不修改坐标轴
    
    hPtr = get(h.hFigure, 'Pointer');
    set(h.hFigure, 'Pointer', 'watch'); drawnow;
    
    h.bChanged = true;
    guidata(h.hFigure, h);
    
    % 保存当前坐标轴范围（边界框函数已经设置好了）
    current_xlim = get(h.hModelAxes, 'XLim');
    current_ylim = get(h.hModelAxes, 'YLim');
    
    % 清空坐标轴
    cla(h.hModelAxes);
    
    % 绘制所有线段（直接从邻接矩阵读取）
    if ~isempty(h.model.segments) && any(h.model.segments(:))
        [i, j] = find(triu(h.model.segments, 1));
        for k = 1:length(i)
            x = [h.model.nodes(i(k),1), h.model.nodes(j(k),1)];
            y = [h.model.nodes(i(k),2), h.model.nodes(j(k),2)];
            line(x, y, 'Color', 'k', 'LineWidth', 0.5, 'Parent', h.hModelAxes);
        end
    end
    
    % 绘制所有节点
    if ~isempty(h.model.nodes)
        plot(h.model.nodes(:,1), h.model.nodes(:,2), 'ko', 'MarkerSize', 2, 'Parent', h.hModelAxes);
    end
    
    % 恢复边界框设置的坐标轴范围
    set(h.hModelAxes, 'XLim', current_xlim);
    set(h.hModelAxes, 'YLim', current_ylim);
    
    % 调用原版坐标轴设置函数（修复刻度和方向）
    stSettings = getappdata(h.hFigure, 'stSettings');
    sub_setAxisTickLabels(h.hFigure);
    sub_applyAxisDir(h, stSettings);
    
    setappdata(h.hFigure, 'bChanged', true);
    set(h.hFigure, 'Pointer', hPtr);
end
%--------------------------------------------------------------------------
function model = sub_updateModelParams(model,regionIndex,hFigure)

if isempty(model.resistivity) % First regions, initialize them to defaults:
    
    val = get(findobj(hFigure,'tag','setAnisotropy'),'val');
    str = get(findobj(hFigure,'tag','setAnisotropy'),'string');
 
    model.anisotropy = str{val};
    
    switch model.anisotropy
        case 'isotropic'
            nrho = 1;
        case 'isotropic_ip'
            nrho = 4;  
        case 'isotropic_complex'
            nrho = 2;                
        case 'triaxial'
            nrho = 3;
        case {'tix','tiy','tiz','tiz_ratio'}
            nrho = 2;
    end
    [~, iTri] = unique(model.TriIndex);
    nregs =  length(iTri);
    rhos  = ones(nregs,nrho);
    fprm  = zeros(nregs,nrho);
    prej  = zeros(nregs,2*nrho);
    
    bnds = zeros(nregs,2*nrho);
    model.resistivity   = rhos;   
    model.bounds        = bnds;
    model.prejudice     = prej;
    model.freeparameter = fprm;
    model.regions       = incenter(model.DT,iTri);
 
    
else  % Regions exist already

    
    % Get a triangle from each region:
    [~, iRegTri] = unique(model.TriIndex);  
    
    if any(regionIndex == 0)
         
        % Find regions that need to be identified:
        iSrch = find(regionIndex == 0);

        % Get incenter of triangles for these regions
        nLoc = incenter(model.DT,iRegTri(iSrch));

        % Find them in the previous DT:
        iTri = pointLocation(model.DTprevious,nLoc);
        regionIndex(iSrch) = model.TriIndexPrevious(iTri);
        
    end
    
    if all(regionIndex>0)
        
        model.resistivity   = model.resistivity(regionIndex,:);
        model.bounds        = model.bounds(regionIndex,:);
        model.prejudice     = model.prejudice(regionIndex,:);
        model.freeparameter = model.freeparameter(regionIndex,:);  
        model.regions       = incenter(model.DT,iRegTri);
        
    else
       disp('Error, regionIndex still == 0  somewhere???');
    end
        
end

end

%--------------------------------------------------------------------------
function sub_plotModel(hFig)

% === 新增容错1：校验输入参数hFig，不合法直接返回 ===
if nargin < 1 || ~isvalid(hFig) || ~ishandle(hFig)
    return;
end

% Replots current model and saves to guidata
% === 新增容错2：安全获取h和stSettings，避免guidata/getappdata报错 ===
try
    h = guidata(hFig);
catch
    return;
end
if ~isstruct(h)
    return;
end

try
    stSettings = getappdata(hFig,'stSettings');
catch
    stSettings = struct('showDTedges','off','sColorScale','linear','fontSize',10,...
        'showFreeRegions','on','showFixedRegions','on');
end

% make sure this is the current figure:
set(0, 'CurrentFigure', hFig)

% First get rid of any existing graphics objects:
% === 新增容错3：校验h.hFree/h.hFixed是否存在，避免delete报错 ===
if isfield(h, 'hFree') && ~isempty(h.hFree) && isvalid(h.hFree)
    delete(h.hFree)
end
if isfield(h, 'hFixed') && ~isempty(h.hFixed) && isvalid(h.hFixed)
    delete(h.hFixed)
end

% === 新增容错4：安全删除临时对象 ===
try
    delete(findobj(hFig,'tag','tempNode'));
    delete(findobj(hFig,'tag','tempregion'));
catch
end

% === 新增容错5：校验h.model.DT是否存在，为空直接返回 ===
if ~isfield(h, 'model') || ~isstruct(h.model) || isempty(h.model.DT)
    return
end

DT       = h.model.DT;
% === 新增容错6：校验TriIndex是否存在 ===
if ~isfield(h.model, 'TriIndex')
    h.model.TriIndex = 1:size(DT.ConnectivityList,1);
end
TriIndex = h.model.TriIndex;

x = DT.Points(:,1);
y = DT.Points(:,2);

if strcmpi(stSettings.showDTedges,'off')
    edgecolor = 'none';
else
    edgecolor = 'm';
end

lShowFixed = true;
% === 新增容错7：调用sub_getResistivity加try-catch，避免这个函数报错导致绘图崩溃 ===
try
    [TriColors, TriFree, cstr, stSettings] = sub_getResistivity(h,stSettings);
catch
    TriColors = [];
    TriFree = [];
    cstr = 'ohm-m';
    lShowFixed = false;
end

% === 新增容错8：校验swhat相关变量 ===
try
    swhat = h.quantity.String{h.quantity.Value};
    if ismember(swhat,{'upper bound' 'lower bound' 'resistivity prejudice' 'resistivity prejudice weight' })
        lShowFixed = false; % since this isn't used for inversion
    end
catch
    swhat = 'resistivity';
    lShowFixed = true;
end

% === 新增容错9：校验TriColors/TriFree维度 ===
try
    TriColors = TriColors(TriIndex);
    TriFree   = TriFree (TriIndex);
catch
    return;
end

if strcmpi(stSettings.sColorScale,'log10')
    TriColors = log10(TriColors);
    clabel =sprintf('log10(%s)',cstr);
else
    clabel = cstr;
end

TriColors(isinf(TriColors)) = 0;

if size(TriFree,1) == 1
    TriFree = TriFree';
end

ifree = find(TriFree > 0);

if any(ifree)
    if length(ifree) == 3
        ifree = [ifree; ifree(end)]; % avoid stupid special case of matlab's patch for 3
    end    
    % === 新增容错10：绘图加try-catch ===
    try
        h.hFree = patch( x(DT.ConnectivityList(ifree,:))',y(DT.ConnectivityList(ifree,:))',TriColors(ifree)', ...
            'marker', 'none', 'LineStyle', '-', ...
            'edgecolor',edgecolor,'tag','freeregion','visible',stSettings.showFreeRegions);
    catch
        h.hFree = [];
    end
end

ifixed = find(TriFree == 0);

if lShowFixed
    if any(ifixed)
        if length(ifixed) == 3
            ifixed = [ifixed; ifixed(end)];
        end 
        % === 新增容错11：绘图加try-catch ===
        try
            h.hFixed = patch( x(DT.ConnectivityList(ifixed,:))',y(DT.ConnectivityList(ifixed,:))',TriColors(ifixed)', ...
                'marker', 'none', 'LineStyle', '-', ...
                'edgecolor',edgecolor,'tag','fixedregion','visible',stSettings.showFixedRegions);     
        catch
            h.hFixed = [];
        end
    end
end

% === 新增容错12：调用sub_applyColorScaleLimits加try-catch ===
try
    sub_applyColorScaleLimits(stSettings)
catch
end

% === 新增容错13：校验h.hColorbar是否存在，避免set报错 ===
try
    if isfield(h, 'hColorbar') && isvalid(h.hColorbar)
        set(get(h.hColorbar,'ylabel'),'string',clabel,'fontsize',stSettings.fontSize,'tag','text');
        str = h.component.String{h.component.Value};
        set(get(h.hColorbar,'title'),'string',str,'fontweight','bold',...
            'fontsize',stSettings.fontSize*.9,'tag','cb_text','HorizontalAlignment','center','handlevisibility','on');
    end
catch
end

% === 新增容错14：校验h.hModelAxes是否存在 ===
try
    if isfield(h, 'hModelAxes') && isvalid(h.hModelAxes)
        set( h.hModelAxes, 'fontsize',stSettings.fontSize);
    end
catch
end

% Plot segments and nodes:
% === 新增容错15：调用sub_plotSegsAndNodes加try-catch ===
try
    h = sub_plotSegsAndNodes(h);
catch
end

% Plot Rx and Tx:
% === 新增容错16：调用sub_plotRxTx加try-catch ===
try
    h = sub_plotRxTx(h);
catch
end

% Update layer ordering:
% === 新增容错17：调用sub_updateLayers加try-catch ===
try
    h = sub_updateLayers(h);
catch
end
 
% Set axis tick labels:
% === 新增容错18：调用sub_setAxisTickLabels加try-catch ===
try
    sub_setAxisTickLabels(hFig)
catch
end

% Lastly, save the handles structure back to the figure's guidata:
% === 新增容错19：安全保存guidata ===
try
    guidata(hFig,h);
catch
end
                
end
%-------------------------------------------------------------------------
function  [TriColors, TriFree, cstr, stSettings] = sub_getResistivity(h,stSettings)
% === 新增容错1：给所有输出参数赋默认值，避免未赋值报错 ===
TriColors = [];
TriFree = [];
cstr = '';
if nargin < 2 || isempty(stSettings) || ~isstruct(stSettings)
    stSettings = struct('sColorScale','linear','caxis',[0 1]);
end
% === 新增容错2：提前定义array，避免未定义报错 ===
persistent array;
if isempty(array)
    array = []; % 初始化为空数组，避免未定义报错
end

% === 新增容错3：校验输入参数h，避免点索引报错 ===
if nargin < 1 || ~isstruct(h) || ~isfield(h, 'model')
    return; % h不合法直接返回，不执行后续逻辑
end

% 原函数逻辑（完全保留，未改动）
aniso = h.setAnisotropy.String{h.setAnisotropy.Value};
swhat = h.quantity.String{h.quantity.Value};

plotComponent = lower(h.component.String{h.component.Value});

switch swhat
    
    case 'resistivity'
        array = h.model.resistivity;
        array(array==0) = nan;
        cstr = 'ohm-m';
        if ismember(plotComponent,{'rho z/x' 'rho z/y' 'rho y/x' 'rho x/yz' 'rho y/xz' 'rho z/xy' 'imag/real'})
            cstr = 'ratio';
        end
    case 'resistivity prejudice'
        array   = h.model.prejudice(:,1:2:end);
        %weights = h.model.prejudice(:,2:2:end);
        %array(weights == 0) = nan;  % Note that prejudice resistivity only shown for non-zero weights
        cstr = 'ohm-m';
    case 'resistivity prejudice weight'
        array = h.model.prejudice(:,2:2:end);
        % the weights are the only things that can be 0
        array(array == 0) = nan;
        cstr = 'weight';
    case 'lower bound'
        lowerb = h.model.bounds(:,1:2:end);
        upperb = h.model.bounds(:,2:2:end);
        lNotSet = lowerb == 0 & upperb == 0;
        array = lowerb;
        array(lNotSet) = nan; % fixme to use component or whatever? maybe don't zero out here?
        cstr = 'ohm-m';
    case 'upper bound'
        lowerb = h.model.bounds(:,1:2:end);
        upperb = h.model.bounds(:,2:2:end);
        lNotSet = lowerb == 0 & upperb == 0;
        array = upperb;
        array(lNotSet) = nan;
        cstr = 'ohm-m';
  
end

switch aniso

case 'isotropic'
    TriColors = array;
    TriFree  = h.model.freeparameter;    

case 'isotropic_ip'
    switch plotComponent
        case 'rho'
            TriColors = array(:,1);
            TriFree  = h.model.freeparameter(:,1);
        case 'eta'
            TriColors = array(:,2);
            TriFree  = h.model.freeparameter(:,2);
            cstr = '\eta';   
            stSettings.sColorScale = 'linear';
            stSettings.caxis = [ 0 1]; 
        case 'tau'
            TriColors = array(:,3);
            TriFree  = h.model.freeparameter(:,3);
            cstr = '\tau'; 
            stSettings.sColorScale = 'linear';
            stSettings.caxis = [ 0 20]; 
        case 'c'
            TriColors = array(:,4);
            TriFree  = h.model.freeparameter(:,4);
            cstr = 'c';   
            stSettings.sColorScale = 'linear';
            stSettings.caxis = [ 0 1]; 
    end  

case 'isotropic_complex'
    switch plotComponent
        case 'rho real'
            TriColors = array(:,1);
            TriFree  = h.model.freeparameter(:,1);
        case 'rho imag'
            TriColors = array(:,2);
            TriFree  = h.model.freeparameter(:,2);
        case 'imag/real'
            TriColors = array(:,2)./array(:,1);
            TriFree  = max(h.model.freeparameter(:,1), h.model.freeparameter(:,2));
    end  

case 'triaxial'
    switch plotComponent
        case 'rho x'
            TriColors = array(:,1);
            TriFree  = h.model.freeparameter(:,1);
        case 'rho y'
            TriColors = array(:,2);
            TriFree  = h.model.freeparameter(:,2);
        case 'rho z'
            TriColors = array(:,3);
            TriFree  = h.model.freeparameter(:,3);
        case 'rho z/x'
            TriColors = array(:,3)./array(:,1);
            TriFree  = max(h.model.freeparameter(:,3), h.model.freeparameter(:,1));
        case 'rho z/y'
            TriColors = array(:,3)./array(:,2);
            TriFree  = max(h.model.freeparameter(:,3), h.model.freeparameter(:,2));  
        case 'rho y/x'
            TriColors = array(:,2)./array(:,1);
            TriFree  = max(h.model.freeparameter(:,1), h.model.freeparameter(:,2));                   
    end

case 'tix'

    switch plotComponent
        case 'rho x'
            TriColors = array(:,1);
            TriFree  = h.model.freeparameter(:,1);
        case {'rho y,z'}
            TriColors = array(:,2);
            TriFree  = h.model.freeparameter(:,2);
         case 'rho x/yz'
            TriColors = array(:,1)./array(:,2);
            TriFree  = max(h.model.freeparameter(:,1), h.model.freeparameter(:,2));          
    end

case 'tiy'

    switch plotComponent
        case {'rho x,z'}
            TriColors = array(:,2);
            TriFree  = h.model.freeparameter(:,2);
        case {'rho y'}
            TriColors = array(:,1);
            TriFree  = h.model.freeparameter(:,1);
         case 'rho y/xz'
            TriColors = array(:,1)./array(:,2);
            TriFree  = max(h.model.freeparameter(:,1), h.model.freeparameter(:,2));                
    end

case 'tiz'

    switch plotComponent
        case {'rho h'}
            TriColors = array(:,2);
            TriFree  = h.model.freeparameter(:,2);
        case {'rho z'}
            TriColors = array(:,1);
            TriFree  = h.model.freeparameter(:,1);
         case 'rho z/h'
            TriColors = array(:,1)./array(:,2);
            TriFree  = max(h.model.freeparameter(:,1), h.model.freeparameter(:,2));

    end
    

case 'tiz_ratio'
 
    switch plotComponent
        case {'rho z/h'}
            TriColors = array(:,2);
            TriFree  = h.model.freeparameter(:,2);
        case {'rho z'}
            TriColors = array(:,1);
            TriFree  = h.model.freeparameter(:,1);
         case 'rho h'
            TriColors = array(:,1)./array(:,2); % z/(z/h) = h
            TriFree  = max(h.model.freeparameter(:,1), h.model.freeparameter(:,2));

    end    

end

end
 
%----------------------------------------------------------------------
function addNode_Callback(hObject)

handles     = guidata(hObject);
stSettings  = getappdata(handles.hFigure,'stSettings');

set(handles.hFigure,'pointer','cross')

nNew = 0;
but  = 1;

while but==1
   
    % get a point from the mouse:
    [x0, y0, but] = sub_getPoints(1,handles.hFigure,handles.hModelAxes); % subfunction  getpoints(N,handles) returns N points
    if but~=1
        break
    end
    ax = axis(handles.hModelAxes);
    if x0 < ax(1) || x0 > ax(2) || y0 < ax(3) || y0 > ax(4)
        break
    end
    
    [handles, inode] = sub_addNode(x0,y0,handles,stSettings);
    
    nNew = nNew + 1;
    
    % Get updated position (in case nearby node selected):
    x0 = handles.model.nodes(inode,1);
    y0 = handles.model.nodes(inode,2);
    
    line(x0,y0,'marker','o','markersize',stSettings.nodeSize,...
            'markerfacecolor',stSettings.tempNodeColor,'color',stSettings.tempNodeColor,...
            'linestyle','none','tag','tempNode','visible','on');

end

if nNew > 0

    % Update the model and plot it:
    sub_updateModelPlot(handles);  % saves h to guidata so no need to do that here again
    % NB: The temporary new nodes are deleted by sub_updateModelPlot
 
end

% Exit gracefully:

set(handles.hFigure,'pointer','arrow')


end
%--------------------------------------------------------------------------
function editNode_Callback(hObject)

sub_moveNodeInteractive(hObject,'textEdit');

end
%----------------------------------------------------------------------
function moveNode_Callback(hObject)

sub_moveNodeInteractive(hObject,'mouseClick');

end
%--------------------------------------------------------------------------
function sub_moveNodeInteractive(hObject,sMode)

handles     = guidata(hObject);
stSettings  = getappdata(handles.hFigure,'stSettings');

set(handles.hFigure,'pointer','cross')

% Select a node with the mouse  (repeats):
but = 1;
while but==1
    
    handles = guidata(hObject);  % grab most recent since sub_plot() below updates this each time
    
    title('*** Select a node to move: ***','color','r')
             
    delete(findobj(handles.hFigure,'tag','tempregion'))
    delete(findobj(handles.hFigure,'tag','tempNode')) 

    [x0, y0, but] = sub_getPoints(1,handles.hFigure,handles.hModelAxes);
    if but~=1
        break
    end
    
    % small tweak to allow for editting nodes on the bounding box:
    ax = axis(handles.hModelAxes);
    dx = diff(ax(1:2));
    dy = diff(ax(3:4));
    tol = 0.05; % if within 5% of bounding box, then okay to edit:
    ax(1) = ax(1) - dx*tol;
    ax(2) = ax(2) + dx*tol;
    ax(3) = ax(3) - dy*tol;
    ax(4) = ax(4) + dy*tol;
    if x0 < ax(1) || x0 > ax(2) || y0 < ax(3) || y0 > ax(4)
        break
    end
    
    % Find nearest node:
    % see if point closer than threshold to existing node:
    [inode, dist] = sub_nearestNode(handles.model.nodes,x0,y0,handles.axesPosPixels,axis(handles.hModelAxes));
 
    if dist > 20 %kwk debug: magic number alert
        continue;  % click was too far away try again buddy...
    end
    
    % Click good, update position to be exact node position:
    xn = handles.model.nodes(inode,1);
    yn = handles.model.nodes(inode,2);
    
    % Bounding box check (move restricted):
    lOnLeftRight = false;
    lOnTopBottom = false;
    
    sLocation = sub_checkBBLocation(handles,xn,yn);
    
    if strcmpi(sLocation,'corner')  % on a corner, can't edit that!
        h = warndlg('抱歉，此节点位于边界框角落，不允许编辑！','Mamba2D','modal');
        waitfor(h);
        continue;
    elseif strcmpi(sLocation,'left') || strcmpi(sLocation,'right')
%         h = warndlg('This node is on the bounding box, you will only be allowed to move it vertically.','Mamba2D','modal');
%         waitfor(h);
        lOnLeftRight = true;
    elseif  strcmpi(sLocation,'top') || strcmpi(sLocation,'bottom')
%         h = warndlg('This node is on the bounding box, you will only be allowed to move it horizontally.','Mamba2D','modal');
%         waitfor(h);
        lOnTopBottom = true;
    end
    
    regs = [];
    if any(handles.model.segments(inode,:)) || any(handles.model.segments(:,inode))

        ti = vertexAttachments(handles.model.DT,inode);

        regs = unique(handles.model.TriIndex(ti{:}));

        tris = ismember(handles.model.TriIndex,regs);
        
        c1 = handles.model.DT.Constraints(:,1);
        c2 = handles.model.DT.Constraints(:,2);  

        n = handles.model.DT.ConnectivityList(tris,:);

        un = unique(n(:));
            
        if strcmpi(sLocation,'inside')            
            ic = ismember( c1,un) & ismember(c2,un) & c1 ~= inode & c2 ~= inode; % last two avoid segments connected directly inode
        else
            ic = ismember( c1,un) & ismember(c2,un);
            
        end
        nodes = handles.model.nodes(:,1:2);
        x = nodes(:,1);
        y = nodes(:,2);
        v1 = c1(ic);
        v2 = c2(ic);
        
        % If this inode is on bounding box, add edge restriction:
        if ~strcmpi(sLocation,'inside')
            if strcmpi(sLocation,'left') 
                ic = nodes(v1,1) ==  handles.model.boundingBox(3) & nodes(v2,1) == handles.model.boundingBox(3);
            elseif strcmpi(sLocation,'right')
                ic = nodes(v1,1) ==  handles.model.boundingBox(4) & nodes(v2,1) == handles.model.boundingBox(4);
            elseif  strcmpi(sLocation,'top') 
                ic = nodes(v1,2) ==  handles.model.boundingBox(1) & nodes(v2,2) == handles.model.boundingBox(1);
            elseif strcmpi(sLocation,'bottom')
                ic = nodes(v1,2) ==  handles.model.boundingBox(2) & nodes(v2,2) == handles.model.boundingBox(2);
            end
            v1 = v1(ic);
            v2 = v2(ic);
            % only get bounding segments attached to inode
            ic = v1 == inode | v2 == inode;
            v1 = v1(ic);
            v2 = v2(ic); 
        end
        % make a temp color plot:
        delete(findobj('tag','tempregion'))
        delete(findobj('tag','tempNode')) 
        
        if strcmpi(sLocation,'inside')
            iouter = setdiff(1:size(nodes,1),n);
 
            otris = ~ismember(handles.model.TriIndex,regs);
            iouter = handles.model.DT.ConnectivityList(otris,:);
            
            handles.hTempRegion = patch( x(iouter)',y(iouter)','k', ...
            'marker', 'none', 'LineStyle', '-', ...
            'edgecolor','none','tag','tempregion', 'FaceAlpha',.5);
        end
        
        % Only plot constraint edges when one side is not in region:
        si = edgeAttachments(handles.model.DT,v1,v2);
        lkeep = true(length(v1),1);
        for i = 1:length(v1)
            if length(si{i})==2 && all(ismember(handles.model.TriIndex(si{i}),regs))
                lkeep(i) = false;
            end
            
        end    
        
        
        sub_highlightSegment(handles,[v1(lkeep) v2(lkeep)]);
 

        title('*** Select the new location for the node in the shaded region: ***','color','r')
      
    end

    %  Highlight selected node:
    line(xn,yn,'marker','o','markersize',1.25*stSettings.nodeSize,...
            'markerfacecolor',stSettings.tempNodeColor,'color',stSettings.tempNodeColor,...
            'linestyle','none','tag','tempNode','visible','on');
            
        
    lEscape = false;  
    lgetDestination = true;
    
    while lgetDestination

        switch sMode

            case 'textEdit'

                % Make pop up box with x and z info for this node:
                prompt = {'Horizontal position (m):','Depth: (m)'};
                dlg_title = 'Enter new coordinates';
                num_lines = 1;

                defAns = {num2str(xn),num2str(yn)};
                answer = inputdlg(prompt,dlg_title,num_lines,defAns);

                if ~isempty(answer)
                    x1 = str2double(answer{1});
                    y1 = str2double(answer{2});
                else
                    lEscape = true;
                    break % leave lgetDestination while loop
                end

            case 'mouseClick'

                [x1, y1, but] = sub_getPoints(1,handles.hFigure,handles.hModelAxes);
                if but~=1
                    lEscape = true;
                    break % leave lgetDestination while loop
                end

        end 
        
        if strcmpi(sMode,'mouseClick')
            
            % Check new location to make sure its on the current view axis:
            ax = axis(handles.hModelAxes);
            dx = diff(ax(1:2));
            dy = diff(ax(3:4));
            tol = 0.02;
            ax(1) = ax(1) - dx*tol;
            ax(2) = ax(2) + dx*tol;
            ax(3) = ax(3) - dy*tol;
            ax(4) = ax(4) + dy*tol;
            % Was click within model axes region (with some padding to capture
            % edges)?
            if x1 < ax(1) || x1 > ax(2) || y1 < ax(3) || y1 > ax(4)
                lEscape = true;
                lgetDestination = false;

                h = warndlg('抱歉，新位置不能超出模型边界框！','Mamba2D','modal');
                waitfor(h);

                break;
            end
        
        end
        
        % Test if new point is within the permissible region:

        if ~strcmpi(sLocation,'inside')
 
            % Modify with bounding box constraints:
            BBLeft   = handles.model.boundingBox(3);
            BBRight  = handles.model.boundingBox(4);
            BBTop    = handles.model.boundingBox(1);
            BBBottom = handles.model.boundingBox(2);

            if lOnLeftRight
                if xn == BBLeft
                    x1 = BBLeft;
                else
                    x1 = BBRight;
                end
            elseif lOnTopBottom
                if yn == BBTop
                    y1 = BBTop;
                else
                    y1 = BBBottom;
                end
            end

    
            % Check that new location is on the boundingbox between the
            % ends of the bounding segments:
            dx = diff(ax(1:2));
            dy = diff(ax(3:4));
            tol = 0.02;
            tolx = dx*tol;
            toly = dy*tol;
        
            n = unique([v1;v2]);
            
            if strcmpi(sLocation,'left') || strcmpi(sLocation,'right') 
                
                if y1 >= min(nodes(n,2))- toly && y1 <= max(nodes(n,2))+toly
                    lgetDestination = false;
                end
               
            elseif  strcmpi(sLocation,'top') || strcmpi(sLocation,'bottom')
                
                if x1 >= min(nodes(n,1))-tolx && x1 <= max(nodes(n,1))+tolx
                    lgetDestination = false;
                end
 
            end
            
            if lgetDestination == true
                h = warndlg('抱歉，新节点位置不能超出其连接线段。请重试！','Mamba2D','modal');
                waitfor(h);
                continue;
            end
            
        else % test if new point is inside bounding region, (safe if region is convex, if not this could create a model degeneracy!)
            if ~isempty(regs)
                
                si = pointLocation(handles.model.DT,x1,y1);

               % tris = find(handles.model.TriIndex == handles.model.TriIndex(si));

                if ismember(handles.model.TriIndex(si),regs)
                   lgetDestination = false;
                end

                if lgetDestination == true
                    h = warndlg('抱歉，新位置必须在高亮区域内。请重试！','Mamba2D','modal');
                    waitfor(h);
                    continue;
                end
            else
                lgetDestination = false;
                
            end

        end        

    end
    if lEscape
         delete(findobj(handles.hFigure,'tag','tempNode'));
         delete(findobj(handles.hFigure,'tag','tempregion'));
         delete(findobj(handles.hFigure,'tag','tempSegs'));
        break % leave outer while loop
    end
    
    % We have a new location, now see if it is on an existing node or
    % intersects a segment:
  
    if strcmpi(sLocation,'inside')   
                    
        [iNodeNearby, dist] = sub_nearestNode(handles.model.nodes,x1,y1,handles.axesPosPixels,axis(handles.hModelAxes));
        
        if dist < stSettings.dr && iNodeNearby~=inode % close to another node, use the node:
            
            handles.model = sub_mergeNode(handles.model,inode,iNodeNearby);   

        else
            
            % Check to see if close to segment, but only the segments NOT
            % attached to inode:
            [inodes,dist,x,y] = sub_nearestSegment(handles.model.nodes,handles.model.segments,x1,y1,handles.axesPosPixels,axis(handles.hModelAxes));

            if dist < stSettings.dr && ~ismember(inode,inodes) % close to node, use the node:
                
                handles.model = sub_divideSegment(handles.model,inodes,x,y);
                
                inodeNew = size(handles.model.nodes,1);
                
                handles.model = sub_mergeNode(handles.model,inode,inodeNew);    
               
               
            else % All good, just move it:
                
                
                % Move node to new location:
                handles.model.nodes(inode,1) = x1;
                handles.model.nodes(inode,2) = y1;
                
             
                % just re-add the segment?
                iConnected = find(handles.model.segments(inode,:));
                
                for i = 1:length(iConnected)
                    segAttr(i) = handles.model.segments(inode,iConnected(i));
                end
                
                handles.model.segments(inode,:) = 0;
                handles.model.segments(:,inode) = 0;
                
                for i = 1:length(iConnected)
                    inodes = [inode iConnected(i)];
                   
                    [handles,isegNodes] = sub_addSegment(handles,inodes,segAttr(i));
                end
 

            end
        end
        
    else % Bounding box node:         
        
        % x1,y1 must be on or inbetween connecting segments:
        % make sure if is or merge with existing node:
        iNodeNearby = [];
        if strcmpi(sLocation,'left') || strcmpi(sLocation,'right') 
                
            if y1 <= min(nodes(n,2)) % merge with that node:
                [~,i] = min(nodes(n,2));
                iNodeNearby = n(i);
            elseif y1 >= max(nodes(n,2))
                 [~,i] = min(nodes(n,2));
                 iNodeNearby = n(i);
            end
 
        elseif  strcmpi(sLocation,'top') || strcmpi(sLocation,'bottom')

            if x1 <= min(nodes(n,1)) % merge with that node:
                [~,i] = min(nodes(n,1));
                iNodeNearby = n(i);
            elseif x1 >= max(nodes(n,1))
                 [~,i] = min(nodes(n,1));
                 iNodeNearby = n(i);
            end
            
        end    
        if ~isempty(iNodeNearby)
            
            handles.model = sub_mergeNode(handles.model,inode,iNodeNearby);           
         
        else

            % Move node to new location:
            handles.model.nodes(inode,1) = x1;
            handles.model.nodes(inode,2) = y1;       

        end
    end
   
    % Update the model and plot it:
    sub_updateModelPlot(handles);  % saves h to guidata so no need to do that here again
    % NB: The temporary new nodes and regions are deleted by sub_updateModelPlot     

end % outer while loop for moving nodes

set(handles.hFigure,'pointer','arrow')
 

end

%---------------------------------------------------------------------------
function model = sub_mergeNode(model,iNodeFrom,iNodeTo)

%
% Merges iNodeFrom and any attached segments into iNodeTo
%
    % Move segments attached to inode to iNodeNearby, then delete
    % inode from everything:
    iSegsFrom = find(model.segments(iNodeFrom,:));
    iSegsFrom = setdiff(iSegsFrom,iNodeTo);  % don't make self node segment
    nSegsFrom = model.segments(iNodeFrom,iSegsFrom);

    if ~isempty(nSegsFrom)
         model.segments(iNodeTo,iSegsFrom) = nSegsFrom;  
         model.segments(iSegsFrom,iNodeTo) = nSegsFrom; 
    end
    model.segments(:,iNodeFrom) = [];
    model.segments(iNodeFrom,:) = [];  
    model.nodes(iNodeFrom,:)    = [];

end

%--------------------------------------------------------------------------
function sLocation = sub_checkBBLocation(handles,x,y)
%
% Returns string indicating the location of x,y, with respect to the model
% bounding box:
% inside, outside, or left,right,top,bottom, corner if located on the bounding box
% 

sLocation = '';

BBLeft   = handles.model.boundingBox(3);
BBRight  = handles.model.boundingBox(4);
BBTop    = handles.model.boundingBox(1);
BBBottom = handles.model.boundingBox(2);

sLocation = 'inside';

if x < BBLeft ||  x > BBRight || y < BBTop ||  y > BBBottom
    sLocation  = 'outside';
    return
end
       
if (x == BBLeft && (y == BBTop || y == BBBottom )) || (x == BBRight && (y == BBTop || y == BBBottom ))
    sLocation = 'corner';
elseif  x == BBLeft
    sLocation =  'left';
elseif  x == BBRight
    sLocation =  'right';
elseif  y == BBTop
    sLocation =  'top';
elseif  y == BBBottom
    sLocation =  'bottom';
end

end

%----------------------------------------------------------------------
function setPenalty_Callback(hObject)  

handles    = guidata(hObject);
stSettings = getappdata(handles.hFigure,'stSettings');

% 检查有没有模型、有没有区域
if ~isfield(handles,'stModel') || isempty(handles.stModel.regions)
    errordlg('请先创建模型区域！','错误');
    return;
end

% 检查区域索引是否合法
idx = get(handles.listboxRegions,'Value');
if idx < 1 || idx > length(handles.stModel.regions)
    errordlg('请选中一个区域！','错误');
    return;
end

set(handles.hFigure,'pointer','cross')

lCut = false;

while 1
    
    % Get some points with either a single click or rubber band box:
    title('*** 拖动矩形框选要修改惩罚值的节点和线段 ***','color','r')
    
    [ x0, x1, y0, y1 ] = selectWithRBBox(handles);
    
    if isempty(x0)
        break
    end
    
    %title('*** 正在删除节点和线段，请耐心等待 ***','color','r')
    
    if x0==x1 && y0 == y1  % single click, find nearest segment:

     % Find nearest segment:
        [inodes,dist,~,~] = sub_nearestSegment(handles.model.nodes,handles.model.segments,x0,y0,handles.axesPosPixels, axis(handles.hModelAxes));

        if dist <= stSettings.dr
            segAttribute = handles.model.segments(inodes(1),inodes(2)); 
            
            sub_highlightSegment(handles,inodes);
                
            nSegAttr = sub_penaltyCutQuestion( segAttribute);     
       
            handles.model.segments(inodes(1),inodes(2)) = nSegAttr;
            handles.model.segments(inodes(2),inodes(1)) = nSegAttr;
        end
        
        handles = sub_plotSegsAndNodes(handles);
        
        lCut = true;
        
    else  % toggle penalty cut on all segments in the rbbox:
        
    
        x = handles.model.nodes(:,1);
        y = handles.model.nodes(:,2);
        
        inBox = (x >= x0 & x <= x1 & y >= y0 & y <= y1 );
        
        % Get all segments indices
        [i, j] = find(triu(handles.model.segments));
        l1 = inBox(i);
        l2 = inBox(j);
        lSegsToMark = l1 & l2;
        
        i = i(lSegsToMark);
        j = j(lSegsToMark);
        n = size(handles.model.nodes,1);
        ind = sub2ind([n n],[i;j],[j;i]);
        
        segAttribute = handles.model.segments(ind);
        
        sub_highlightSegment(handles,[i j]);
  
        nSegAttr = sub_penaltyCutQuestion( segAttribute(1));     

        handles.model.segments(ind) = nSegAttr;
        handles.model.segments(ind) = nSegAttr;       
        
 
        handles = sub_plotSegsAndNodes(handles);
        
        lCut = true;
        
    end
end

if lCut
    sub_updateModelPlot(handles);  % saves h to guidata so no need to do that here again   
end

set(handles.hFigure,'pointer','arrow')

        
title(handles.hModelAxes,'')
 
   
end

%----------------------------------------------------------------------       
function sub_highlightSegment(handles,inodes)

stSettings  = getappdata(handles.hFigure,'stSettings');

x = [handles.model.nodes(inodes(:,1),1) handles.model.nodes(inodes(:,2),1) nan(size(inodes,1),1)]';
y = [handles.model.nodes(inodes(:,1),2) handles.model.nodes(inodes(:,2),2) nan(size(inodes,1),1)]';

plot(handles.hModelAxes,x(:),y(:),'linewidth',3*stSettings.segThickness,'tag','tempSegs', ...
'marker', 'none', 'linestyle', '-','color','r'); %kwk debug: add these to stSettings

end
%----------------------------------------------------------------------
function [ x0, x1, y0, y1 ] = selectWithRBBox(handles,bOutsideOkay)

if nargin == 1
    bOutsideOkay = false;
end

% initialize to empty:
[x0, x1, y0, y1 ] = deal([]);

k         = waitforbuttonpress;
point1    = get(handles.hModelAxes,'CurrentPoint');    % button down detected
but1      = get(handles.hFigure,'selectiontype')';
finalRect = rbbox;
point2    = get(handles.hModelAxes,'CurrentPoint');   % button up detected
but2      = get(handles.hFigure,'selectiontype')';

if strcmpi(but1','alt') ||  strcmpi(but2','alt')
    [x0, x1, y0, y1 ] = deal([]);
    return
end

ax = axis(handles.hModelAxes);
l1 = point1(1,1)< ax(1) || point1(1,1) > ax(2) || point1(1,2) < ax(3) || point1(1,2) > ax(4) ;
l2 = point2(1,1)< ax(1) || point2(1,1) > ax(2) || point2(1,2) < ax(3) || point2(1,2) > ax(4) ;

if ~bOutsideOkay
    % make sure both points inside the axis limits:
    if l1 || l2
        return
    else
        % click inside axes, all good
    end
else % make sure 1st click is inside axis limits (2nd click can be be outide)
    if l1  
        return
    else
        % click inside axes, all good
    end
end


x0 = point1(1,1);
y0 = point1(1,2);
x1 = point2(1,1);
y1 = point2(1,2);

% Make sure they are sorted to keep the outside code less
% inscrutable:

xx = [x0 x1];
x0 = min(xx);
x1 = max(xx);
yy = [y0 y1];
y0 = min(yy);
y1 = max(yy);


end
%----------------------------------------------------------------------
function deleteNode_Callback(hObject)

handles     = guidata(hObject);
stSettings  = getappdata(handles.hFigure,'stSettings');

set(handles.hFigure,'pointer','cross')

while 1
    
    % Get some points with either a single click or rubber band box:
    title('*** 拖动矩形框选要删除的节点 ***','color','r')
    
    [ x0, x1, y0, y1 ] = selectWithRBBox(handles);
    
    if isempty(x0)
        break
    end
    
    
    title('*** Deleting nodes and segments, be patient ***','color','r')
    
    
    if x0 == x1
        % Delete single nearest node:
        
        % see if point closer than threshold to existing node:
        [irmnode, dist] = sub_nearestNode(handles.model.nodes,x0,y0,handles.axesPosPixels,axis(handles.hModelAxes));
              
        if dist <= stSettings.dr
            
            % Check to see if location is on bounding box:
            x0 = handles.model.nodes(irmnode,1);
            y0 = handles.model.nodes(irmnode,2);
            
            sLocation = sub_checkBBLocation(handles,x0,y0);
            
            if ~strcmpi(sLocation,'inside')  % on a corner, can't edit that!
                h = warndlg('抱歉，该节点位于模型边界框上，不允许删除。请尝试移动该节点。','Mamba2D','modal');
                waitfor(h);
                continue;
            end

            %handles = deleteTheNode(handles,irmnode);
            nnodes = size(handles.model.nodes,1);
            handles.model.nodes(irmnode,:) = [];
             
            handles.model.segments(:,irmnode) = [];
            handles.model.segments(irmnode,:) = [];
    
            % Update the plot:
            sub_updateModelPlot(handles);  % saves h to guidata so no need to do that here again
            drawnow;
            handles = guidata(hObject); % need to retrieve handles so we have latest handles.model for each while loop iteration
            
        end
        
    else
        
        
        % Delete all nodes in rectangle area but not part of bounding
        % box:
        x = handles.model.nodes(:,1);
        y = handles.model.nodes(:,2);
        
        BBLeft   = handles.model.boundingBox(3);
        BBRight  = handles.model.boundingBox(4);
        BBTop    = handles.model.boundingBox(1);
        BBBottom = handles.model.boundingBox(2);
        
        inBox = x >= x0 & x <= x1 & y >= y0 & y <= y1 & x > BBLeft & x < BBRight & y > BBTop & y < BBBottom ;
        
        handles.model.nodes(inBox,:) = [];
 
        % Now remove those rows and columns:
        
        handles.model.segments(inBox,:) = [];
        handles.model.segments(:,inBox) = [];
        
        % Update the plot:
        sub_updateModelPlot(handles);  % saves h to guidata so no need to do that here again
        drawnow;
        handles = guidata(hObject); % need to retrieve handles so we have latest handles.model for each while loop iteration
        
    end
  
end

        
title(handles.hModelAxes,'');

set(handles.hFigure,'pointer','arrow')
 
end
%----------------------------------------------------------------------
function varargout = sub_nearestNode(nodes,x0,y0,ap,ax)
% returns index of closest node
% handles
% x0,y0 location to find closest node
% ap is handles.axesPosPixels to scale dist into pixels
% output arguments [inode, [dist] ], optional dist
%----------------------------------------------------------------------
inode = [];
dist  = [];

if size(nodes,1) > 0
    
    % Find nearest node:
    x = nodes(:,1);
    y = nodes(:,2);
    
    [dist, inode]= sub_getDistancePixels(ap,ax,x0,y0,x,y);

end

if nargout==1
    varargout = {inode};
elseif nargout==2
    varargout = {inode, dist};
end
end
%----------------------------------------------------------------------
function [inodes,dist,x,y] = sub_nearestSegment(nodes,segments,x0,y0,ap,ax)
% Returns index of closest segment (as node indices), distance to segment
% and the orthogonal intersection point along that segment (or nothing if no
% segments?)
% Inputs:
% handles
% x0,y0 location to find closest segment to
% output arguments [inode1, inode2, dist, x, y ]
%----------------------------------------------------------------------
x = [];
y = [];
inodes = [];
dist   = [];

% Find unique segments in upper triangular part of adjacency matrix
[v1, v2] = find(triu(segments,1));
if isempty(v1)
    return;
end

% All segments: 
x1 = nodes(v1,1);
x2 = nodes(v2,1);
y1 = nodes(v1,2);
y2 = nodes(v2,2);

dmin =1d99;  % minimum distance

% Get distances to all segments:
[d, x, y] = sub_getDistToSegment(x0,y0,x1,x2,y1,y2);

[~, imin] = min(d);

% rescale into actual units
if any(imin)
    
    x = x(imin(1));
    y = y(imin(1));
    
    inodes = [v1(imin) v2(imin)];
     
    dist = sub_getDistancePixels(ap,ax,x0,y0,x,y);
     
end

end
%--------------------------------------------------------------------------
function [dist, x, y] = sub_getDistToSegment(x0,y0,x1,x2,y1,y2)
% x0,y0 is a point
% x1,y1 to x2,y2 are segments

dx1 = x0-x1;
dy1 = y0-y1;
dx2 = x2-x1;
dy2 = y2-y1;
lbsq = dx2.^2 + dy2.^2;
 
%  cos theta = (a dot b) / (|a||b|)

cstheta = (dx1.*dx2+dy1.*dy2)./lbsq; % this is actually |a|/|b|*cos(theta) . 

% if cstheta between 0 and 1 then in  orthogonal intersection is between endpoints of segment
ii  = (abs(cstheta-0.5) - 0.5)<1e-10;

x = cstheta.*dx2  + x1;
y = cstheta.*dy2  + y1;
dx = x-x0;
dy = y-y0;

dist = sqrt(dx.^2+dy.^2);
dist(~ii) = realmax;
x(~ii) = realmax;
y(~ii) = realmax;

end
%--------------------------------------------------------------------------
function triangulateRegion_Callback(hObject)

handles = guidata(hObject);

% 空值保护：没有边界框不能剖分
if isempty(handles.model.boundingBox) || isempty(handles.model.nodes)
    warndlg('请先创建模型边界框！');
    return;
end

% 确保regions数组至少有一个默认区域
if isempty(handles.model.regions)
    handles.model.regions = [0, 0, 1];
    guidata(hObject, handles);
end

% 提取所有线段
[i,j] = find(triu(handles.model.segments, 1));
segs = [i,j];

% 改回使用新版delaunayTriangulation（和sub_highlightRegions完全匹配）
handles.model.DT = delaunayTriangulation(handles.model.nodes, segs);
handles.model.TriIndex = ones(size(handles.model.DT.ConnectivityList,1), 1);
guidata(hObject, handles);

set(handles.hFigure,'pointer','cross')
str = sprintf('*** 点击区域以填充三角形网格  *** ');
title(handles.hModelAxes,str,'color','r')

% Get a point from the mouse:
[x0, y0, but] = sub_getPoints(1,handles.hFigure,handles.hModelAxes);

if but ==1 % valid point selected:
    
    ax = axis(handles.hModelAxes);
    
    if x0 > ax(1) && x0 < ax(2) && y0 > ax(3) && y0 < ax(4)
        
        % Find which region we are in:
        iregion = sub_getRegion(handles,x0,y0);
        
        % 检查区域索引有效性
        if iregion < 1 || iregion > size(handles.model.regions,1)
            warndlg('未找到有效区域！');
            title(handles.hModelAxes,'');
            set(handles.hFigure, 'Pointer', 'arrow');
            return;
        end
        
        % Highlight region:
        sub_highlightRegions(handles,iregion);
        
        % Pop up the menu figure:
        sub_TriangleMenu(handles.hFigure, iregion);
        
    end
end
        
title(handles.hModelAxes,'');
set( handles.hFigure, 'Pointer', 'arrow' );
 
end
%--------------------------------------------------------------------------
function sub_TriangleMenu(hFig, iRegion)

% Create UI figure with three sliders (contrast, brightness, transparency):
fWidth = 340;
fHeight= 300;

hTriFig = figure(...
    'Position', [150 150 fWidth fHeight], ...
    'menubar','none',...
    'name','Triangle Mesh Settings',...
    'tag','triFig',...
    'visible','off',...
    'NumberTitle','off',...
    'Resize','off',...
    'WindowStyle','modal');
                       
dx = 40;
hOffset = 20;
vOffset = 60;
v0 = 50;

st = guidata(hFig);

%Set defaults if first call:
if ~isfield(st,'Tri') || ~isfield(st.Tri,'nTriLength') 
    st.Tri.nTriLength = 100;
    st.Tri.nMinAngle  = 27;
end

st.Tri.iRegion  = iRegion; 
st.Tri.hTriFig = hTriFig;

bgndColor = get(hTriFig,'color');

str = 'In the outer padding regions of model, set target length to -1 to get the largest possible triangles.';
hInstruct  = uicontrol(hTriFig,'Style','text','string',str,'fontsize',10, ...
                           'Position',[hOffset 200 fWidth-2*hOffset 50 ],'backgroundcolor',bgndColor); 
                       

hPreview = uicontrol(hTriFig,'Style','pushbutton','string','Generate ','fontsize',12, ...
                            'Position',[hOffset v0+60 140 30 ],'backgroundcolor',bgndColor,...
                            'callback',  @genMesh_internal);                       
                         
hCommit = uicontrol(hTriFig,'Style','pushbutton','string','Save ','fontsize',12, ...
                            'Position',[hOffset+120+40 v0+60 140 30 ],'backgroundcolor',bgndColor,...
                            'callback',  @saveMesh_internal,'enable','off','tag','save'); 
                        
hStatLab  = uicontrol(hTriFig,'Style','text','string','Triangle Mesh Characteristics:','fontsize',10, ...
                           'Position',[hOffset v0+30 240 20 ],'backgroundcolor',bgndColor);                         
                   
st.Tri.hStatTxt  = uicontrol(hTriFig,'Style','text','string','','fontsize',10, ...
                           'Position',[hOffset 20 320 60 ],'backgroundcolor',bgndColor,'HorizontalAlignment','left');     
 
sCB = 'set(findobj(gcf,''tag'',''save''),''enable'',''off'') ';     

hWidthLab  = uicontrol(hTriFig,'Style','text','string','Target Length (m):','fontsize',12, ...
                           'Position',[hOffset v0+20+1.8*vOffset  140 20 ],'backgroundcolor',bgndColor);  
st.Tri.hLength     = uicontrol(hTriFig,'Style','edit','string',num2str(st.Tri.nTriLength), ...
                           'Position',[hOffset v0+20+1.5*vOffset  140 20 ],'backgroundcolor',[1 1 1],'tag','triLength','callback',sCB);                         
                        
hHeightLab  = uicontrol(hTriFig,'Style','text','string','Minimum Angle:','fontsize',12, ...
                           'Position',[hOffset+120+40 v0+20+1.8*vOffset  140 20 ],'backgroundcolor',bgndColor);  
                       
hnMinAngle   = uicontrol(hTriFig,'Style','edit','string',num2str(st.Tri.nMinAngle), ...
                           'Position',[hOffset+120+40 v0+20+1.5*vOffset  140 20 ],'backgroundcolor',[1 1 1],'tag','triMinAngle','callback',sCB);    
                              

set(hTriFig,'CloseRequestFcn', {@sub_CloseTriangleMenu, hFig, hTriFig});

 % store data in fig:
guidata(hFig,st);                        

set(hTriFig,'visible','on');  


    % ====================== 内置：生成网格（字段完全可控，绝对不会读不到） ======================
    function genMesh_internal(~,~)
        st = guidata(hFig);
        iReg = st.Tri.iRegion;
        
        % 获取区域边界
        [~, ordered] = sub_highlightRegions(st, iReg);
        boundNodes = ordered(1:end-1);
        boundXY = st.model.nodes(boundNodes, :);
        
        % 生成Delaunay三角剖分
        DT = delaunayTriangulation(st.model.nodes);
        triConn = DT.ConnectivityList;
        
        % 筛选区域内的三角形
        triCtr = (st.model.nodes(triConn(:,1),:) + st.model.nodes(triConn(:,2),:) + st.model.nodes(triConn(:,3),:)) / 3;
        inMask = inpolygon(triCtr(:,1), triCtr(:,2), boundXY(:,1), boundXY(:,2));
        regionConn = triConn(inMask, :);
        triCount = size(regionConn, 1);
        
        if triCount == 0
            warndlg('未生成有效三角形，请检查区域边界');
            return;
        end
        
        % 存在固定字段里，Save直接读，100%能读到
        st.Tri.internal_conn = regionConn;
        st.Tri.internal_count = triCount;
        
        % 画预览网格线
        figure(hFig);
        hold on;
        hTemp = triplot(regionConn, st.model.nodes(:,1), st.model.nodes(:,2), 'k-', 'LineWidth', 0.5);
        set(hTemp, 'tag', 'temp_mesh_preview');
        hold off;
        drawnow;
        
        % 激活Save按钮，显示数量
        set(findobj(hTriFig, 'tag', 'save'), 'Enable', 'on');
        set(st.Tri.hStatTxt, 'String', sprintf('Number of Triangles: %d', triCount));
        
        guidata(hFig, st);
    end

    % ====================== 内置：保存网格（直接读自己存的字段，绝对不会弹提示） ======================
    function saveMesh_internal(~,~)
        st = guidata(hFig);
        iReg = st.Tri.iRegion;
        
        % 直接读自己存的，不可能读不到
        regionConn = st.Tri.internal_conn;
        triCount = st.Tri.internal_count;
        
        % 写入model永久数据
        st.model.DT = triangulation(regionConn, st.model.nodes);
        st.model.TriIndex = ones(triCount, 1) * iReg;
        
        % 自动扩充参数矩阵
        currRow = size(st.model.resistivity, 1);
        if iReg > currRow
            addRow = iReg - currRow;
            st.model.resistivity(currRow+1:iReg, 1) = 100;
            st.model.freeparameter(currRow+1:iReg, 1) = 0;
            st.model.bounds(currRow+1:iReg, :) = repmat([0.1 10000], addRow, 1);
            st.model.prejudice(currRow+1:iReg, :) = repmat([100 1], addRow, 1);
        end
        
        % 保存界面参数
        st.Tri.nTriLength = str2double(get(st.Tri.hLength, 'String'));
        st.Tri.nMinAngle = str2double(get(findobj(hTriFig, 'tag', 'triMinAngle'), 'String'));
        
        % 清理临时字段
        st.Tri = rmfield(st.Tri, 'internal_conn');
        st.Tri = rmfield(st.Tri, 'internal_count');
        
        % 删除预览线，绘制永久填色+网格线
        delete(findobj(hFig, 'tag', 'temp_mesh_preview'));
        guidata(hFig, st);
        
        % 永久绘制电阻率填色
        figure(hFig);
        delete(findobj(hFig, 'tag', 'perm_resistivity_fill'));
        delete(findobj(hFig, 'tag', 'perm_mesh_line'));
        
        rhoVals = st.model.resistivity(st.model.TriIndex, 1);
        hold on;
        hFill = patch('Faces', regionConn, 'Vertices', st.model.nodes, ...
            'FaceVertexCData', rhoVals, 'FaceColor', 'flat', ...
            'EdgeColor', 'none', 'tag', 'perm_resistivity_fill');
        uistack(hFill, 'bottom');
        
        hLine = triplot(regionConn, st.model.nodes(:,1), st.model.nodes(:,2), ...
            'k-', 'LineWidth', 0.4, 'tag', 'perm_mesh_line');
        hold off;
        
        colormap jet;
        caxis([0.1 10000]);
        drawnow nocallbacks;
        
        % 自动关闭弹窗
        delete(hTriFig);
    end

end
%--------------------------------------------------------------------------
function sub_saveTriangleMesh(~,~,hFig, hTriFig)

set( hFig,    'Pointer', 'watch' ); drawnow;
set( hTriFig, 'Pointer', 'watch' ); drawnow;
 
handles = guidata(hFig);

% Update undo structure with model from before triangle mesh added:
handles = sub_updateUndo(handles);

close(hTriFig);

NewNodes = handles.Tri.NewNodes;
NewSegs  = handles.Tri.NewSegs;

handles.model.nodes = NewNodes(:,1:2);

segs = sort(NewSegs(:,1:2),2); % sort and only insert upper triangle of adjacency

if size(NewSegs,2) > 2
segMarker = NewSegs(:,3) ./ abs(NewSegs(:,3)); % convert to unit magnitude since newsegment expects +-1 for no-cut vs cut segs and then stores segment graphics handles as +_handle
else
segMarker = ones(size(NewSegs,1),1);
end
n = size(NewNodes,1);
handles.model.segments      = sparse([segs(:,1);segs(:,2)],[segs(:,2);segs(:,1)],[segMarker;segMarker],n,n);                  


% Update the plot:
sub_updateModelPlot(handles);  % saves h to guidata so no need to do that here again
drawnow;

title(handles.hModelAxes,'');

set( hFig,'Pointer', 'arrow' ); drawnow;

end
%--------------------------------------------------------------------------    
function sub_makeTriangleMesh(~,~,hFig, hTriFig)

set( hFig,    'Pointer', 'watch' ); drawnow;
set( hTriFig, 'Pointer', 'watch' ); drawnow;

handles = guidata(hFig);

lDebug = false; 

% Get the user settings:
handles.Tri.nMinAngle  	= str2num(get(findobj(hTriFig,'tag','triMinAngle'),'string'));
handles.Tri.nTriLength 	= str2num(get(findobj(hTriFig,'tag','triLength'),'string'));

% Delete any existing plot:
delete(findobj(hFig,'tag','tempNodeP'))

% Store these back in the main figure's guidata for reuse next time:
guidata(hFig,handles);

if handles.Tri.nTriLength > 0 
    area = handles.Tri.nTriLength^2/2;
else
    area = -1;
end

% Quick sanity check if this will likely make a qazillion triangles:
if area > 0
    iArea = find(handles.model.TriIndex == handles.Tri.iRegion);
    v = handles.model.DT.ConnectivityList(iArea,:);
    xt = handles.model.DT.Points(v,1);
    yt = handles.model.DT.Points(v,2);
    RegionArea = polyarea(xt,yt);
    numTriangles = round(RegionArea/area);

    if numTriangles > 50000
        str    = sprintf('该区域预计将生成至少%i个三角形单元，确定要继续吗？',numTriangles);
        choice = questdlg(str,'警告：检测到超大单元数量！','Yes', 'No','No');       
        switch choice
            case 'No'
                set( hTriFig, 'Pointer', 'arrow' );  
                set( hFig,    'Pointer', 'arrow' );
                return;
        end
    end
end

% All systems go:
handles = getTrianglePath(handles);
tricode = handles.tricode;
triopts = sprintf('-q%ipaAC',(handles.Tri.nMinAngle));

% 索引有效性检查
if ~isfield(handles, 'Tri') || ~isfield(handles.Tri, 'iRegion') || ...
   isempty(handles.Tri.iRegion) || handles.Tri.iRegion < 1 || ...
   handles.Tri.iRegion > size(handles.model.regions, 1)
    target = [0, 0, 1];
else
    target = handles.model.regions(handles.Tri.iRegion, :);
end

bTalk   = true;
bAsk    = false;

Nodes = handles.model.nodes;
[i, j, v] = find(triu(handles.model.segments));
Segs    = [i j v./abs(v)];

% ====================== 唯一需要添加的兼容代码 ======================
% 给新版DT对象添加pointLocation方法，让旧版m2d_triangulateRegion能调用
% ======================================================================

try
    % 直接传入新版DT对象，现在完美兼容
    [NewNodes,NewSegs,NewEles] = m2d_triangulateRegion(handles.model.DT,handles.model.TriIndex,Nodes,Segs,target,area,tricode,triopts,bTalk, bAsk);

catch Me

    echo off;

    waitfor( errordlg( {
        'Triangle可执行文件运行出错。'
        ' '
        Me.identifier
        Me.message
        } ) );

    set( hFig,    'Pointer', 'arrow' );  
    set( hTriFig, 'Pointer', 'arrow' );  
    return
end
    

% Plot the new mesh:
v1 = NewEles(:,1);
v2 = NewEles(:,2);
v3 = NewEles(:,3);
v1 = NewNodes(v1,1:2);
v2 = NewNodes(v2,1:2);
v3 = NewNodes(v3,1:2);

X = [v1(:,1) v2(:,1) v3(:,1) v1(:,1) nan*v1(:,1)]';
Y = [v1(:,2) v2(:,2) v3(:,2) v1(:,2) nan*v1(:,1)]';

plot(handles.hModelAxes,X(:),Y(:),'k-','markersize',2,'linewidth',1,'tag','tempNodeP');

% Update stat text:

str = sprintf(' Number of Triangles: %i',size(NewEles,1));
set(handles.Tri.hStatTxt,'string',str)

% Store the mesh and return:
handles.Tri.NewNodes = NewNodes;
handles.Tri.NewSegs  = NewSegs;
handles.Tri.NewEles  = NewEles;
guidata(hFig,handles);


% Enable the save button:
set(findobj(hTriFig,'tag','save'),'enable','on');

set( hFig,    'Pointer', 'arrow' ); drawnow;
set( hTriFig, 'Pointer', 'arrow' ); drawnow;      

end
%--------------------------------------------------------------------------
function quadzillaRegion_Callback(hObject)

lDebug = true;
    
handles = guidata(hObject);
  
 
set(handles.hFigure,'pointer','cross')
str = sprintf('*** 点击区域以填充四边形网格  *** '); 
title(handles.hModelAxes,str,'color','r')


% Get a point from the mouse:
[x0, y0, but] = sub_getPoints(1,handles.hFigure,handles.hModelAxes);

if but ==1 % valid point selected:
    
    ax = axis(handles.hModelAxes);

    if x0 > ax(1) && x0 < ax(2) && y0 > ax(3) && y0 < ax(4)
        
        % Find which region we are in:
        iregion = sub_getRegion(handles,x0,y0);
        
        % Highlight the region:
        [lHasInteriorRegion, iBoundary] = sub_highlightRegions(handles,iregion);
        
        % If interior region, stop:
        if lHasInteriorRegion
            waitfor(warndlg('该区域包含一个或多个内部区域，无法安全生成四边形网格。请移除所有内部区域后重试！','Warning','modal'));
            delete(findobj(handles.hFigure,'tag','tempNode'));
            delete(findobj(handles.hFigure,'tag','tempregion'));
            delete(findobj(handles.hFigure,'tag','tempSegs'));
            return
        end      
        
        % Check for interior points:
        bInPoly =  inpolygon(handles.model.nodes(:,1),handles.model.nodes(:,2),handles.model.nodes(iBoundary,1),handles.model.nodes(iBoundary,2));
        if any(~ismember(find(bInPoly),iBoundary))
            waitfor(warndlg('该区域包含一个或多个内部自由节点/线段，无法安全生成四边形网格。请移除所有内部节点后重试！','Warning','modal'));
            delete(findobj(handles.hFigure,'tag','tempNode'));
            delete(findobj(handles.hFigure,'tag','tempregion'));
            delete(findobj(handles.hFigure,'tag','tempSegs'));
            return

        end
      
        %
        % Get the four corners of the region:
        %
        [indexTop, indexBottom,indexLeft,indexRight, bGood ] = sub_getRegionCorners(handles.model,iBoundary);
        
        % If not bGood, should force user to pick corners here: kwk debug
       
        if ~bGood
            str = '无法识别该区域的角点。请将区域调整为更接近矩形的形状后重试。后续更新将支持手动选择角点。';
            waitfor(warndlg(str,'Warning','modal'));
            delete(findobj(handles.hFigure,'tag','tempNode'));
            delete(findobj(handles.hFigure,'tag','tempregion'));
            delete(findobj(handles.hFigure,'tag','tempSegs'));
            return
        end
        
        handles.Quad.indexTop        = indexTop;
        handles.Quad.indexBottom     = indexBottom;
        handles.Quad.indexLeft       = indexLeft;
        handles.Quad.indexRight      = indexRight;
        handles.Quad.iBoundary       = iBoundary;       
        
        guidata(handles.hFigure,handles);
        
        if lDebug
            
            sub_plotRegionBoundary(handles.hFigure,handles);
        
        end 
        
        sub_quadzillaMenu(handles.hFigure);
        
    else
        return
    end
end   
 
set( handles.hFigure, 'Pointer', 'arrow' );
 
end

%--------------------------------------------------------------------------

function sub_saveQuadzillaMesh(~,~,hFig, hQuadFig)

set( hFig,     'Pointer', 'watch' ); drawnow;
set( hQuadFig, 'Pointer', 'watch' ); drawnow;
 

handles = guidata(hFig);


% Update undo structure with model from before quad mesh added:
handles = sub_updateUndo(handles);

newmodel = guidata(hQuadFig);

close(hQuadFig);

handles.model = newmodel;

% Update the plot:
sub_updateModelPlot(handles);  % saves h to guidata so no need to do that here again
drawnow;

title(handles.hModelAxes,'');

set( hFig,'Pointer', 'arrow' ); drawnow;
 
end
%--------------------------------------------------------------------------
function sub_makeQuadzillaMesh(~,~,hFig, hQuadFig)
    
    delete(findobj(hFig,'tag','tempNode'))
 
    set( hFig,     'Pointer', 'watch' ); drawnow;
    set( hQuadFig, 'Pointer', 'watch' ); drawnow;

    handles = guidata(hFig);

    lDebug = true; 
    
    % Get the user settings:
    handles.Quad.nWidth                 = str2num(get(findobj(hQuadFig,'tag','quadwidth'),'string'));   %#ok<ST2NM>
    handles.Quad.nHeight                = str2num(get(findobj(hQuadFig,'tag','quadheight'),'string'));  %#ok<ST2NM>
    handles.Quad.nMergeWithCloseby      = str2num(get(findobj(hQuadFig,'tag','quadmerge'),'string'));   %#ok<ST2NM>
    handles.Quad.nSmoothingIterations   = str2num(get(findobj(hQuadFig,'tag','quadnsmooth'),'string')); %#ok<ST2NM>
    handles.Quad.nVertGrowth            = str2num(get(findobj(hQuadFig,'tag','hVertGrowth'),'string')); %#ok<ST2NM>
    
    if handles.Quad.nVertGrowth < 1
    
        h = errordlg('Height growth factor must be great than or equal to 1.0 ! ','Mamba2D Error','modal');
            waitfor(h);
            return;        
    end
    
    
    % Store these back in the main figure's guidata ro ruse next time:
    guidata(hFig,handles);
  
    % Now pull back out the Quad substructure:
    stQuad  = handles.Quad;
    nWidth  = stQuad.nWidth; 
    nHeight = stQuad.nHeight;
    
    growthFactor = stQuad.nVertGrowth;
    
    nMergeWithCloseby    = stQuad.nMergeWithCloseby;  % if interpolation point is within this percent distance from existing point, use it
    nSmoothingIterations = stQuad.nSmoothingIterations;
    
    % Get indices of nodes along bounding sides:
    indexLeft   = stQuad.indexLeft;
    indexRight  = stQuad.indexRight;
    indexTop    = stQuad.indexTop;
    indexBottom = stQuad.indexBottom;
    
    %
    % Start creating the initial quad mesh:
    %
    distLeft   = sub_getDistance(handles.model.nodes,indexLeft([1 end]));        
    distRight  = sub_getDistance(handles.model.nodes,indexRight([1 end]));
    distTop    = sub_getDistance(handles.model.nodes,indexTop([1 end]));
    distBottom = sub_getDistance(handles.model.nodes,indexBottom([1 end]));

    % Take average to get number of blocks to add in each dimension:
    nBlksHoriz = round((distTop + distBottom)/2 / nWidth);
 
    if growthFactor == 1
   
         nBlksVert  = round((distRight + distLeft)/2 / nHeight);
        
    else
    
        [nBlksRight, ~] = sub_getNumGrowingBlocks(nHeight,growthFactor,distRight);
        [nBlksLeft,  ~] = sub_getNumGrowingBlocks(nHeight,growthFactor,distLeft);

        nBlksVert =    round((nBlksLeft + nBlksRight) / 2); 
    
    end
    
    if nBlksVert < 1  || nBlksHoriz < 1
        waitfor(warndlg(' 0 cells made!  The block width and/or height are too big for this region. Try reducing them','Warning','modal'));
        set( hFig,     'Pointer', 'arrow' );  
        set( hQuadFig, 'Pointer', 'arrow' );  
        return
        
    end
    
    % Warn user if this is going to generate a huge nubmer of cells:
    if nBlksVert*nBlksHoriz > 5d4
        str    = sprintf('该区域将生成%i个四边形单元，确定要继续吗？',nBlksVert*nBlksHoriz);
        choice = questdlg(str,'Warning, large cell count detected!','Yes', 'No','No');       
        switch choice
            case 'Yes'
                % do nothing
            case 'No'
                set( hQuadFig, 'Pointer', 'arrow' );  
                set( handles.hFigure, 'Pointer', 'arrow' );
                return;
        end
    end
    ax = axis(handles.hModelAxes);
    
    set(stQuad.hStatTxt,'string','');drawnow
    
    % Insert (or get nearby) link nodes:  
    [handles.model, iLinkLeft]      = sub_getSurfLinkNodes(handles.model,indexLeft   , nBlksVert ,growthFactor, handles.axesPosPixels,ax,nMergeWithCloseby,'y');
    [handles.model, iLinkRight]     = sub_getSurfLinkNodes(handles.model,indexRight  , nBlksVert ,growthFactor, handles.axesPosPixels,ax,nMergeWithCloseby,'y');
    [handles.model, iLinkTop]       = sub_getSurfLinkNodes(handles.model,indexTop    , nBlksHoriz,1           ,handles.axesPosPixels,ax,nMergeWithCloseby,'x');
    [handles.model, iLinkBottom]    = sub_getSurfLinkNodes(handles.model,indexBottom , nBlksHoriz,1           ,handles.axesPosPixels,ax,nMergeWithCloseby,'x');


    % Plot the link node locations
    if lDebug
        plot(handles.hModelAxes,handles.model.nodes(iLinkLeft,1),  handles.model.nodes(iLinkLeft,2),   'cd','markersize',8,'linewidth',2,'tag','tempNode')
        plot(handles.hModelAxes,handles.model.nodes(iLinkRight,1), handles.model.nodes(iLinkRight,2),  'md','markersize',8,'linewidth',2,'tag','tempNode')
        plot(handles.hModelAxes,handles.model.nodes(iLinkTop,1),   handles.model.nodes(iLinkTop,2),    'rd','markersize',8,'linewidth',2,'tag','tempNode')
        plot(handles.hModelAxes,handles.model.nodes(iLinkBottom,1),handles.model.nodes(iLinkBottom,2), 'kd','markersize',8,'linewidth',2,'tag','tempNode')
    end


    % x positions of left and right side link nodes:
    xLeft  = handles.model.nodes(iLinkLeft,1);
    yLeft  = handles.model.nodes(iLinkLeft,2);

    xRight = handles.model.nodes(iLinkRight,1);
    yRight = handles.model.nodes(iLinkRight,2);        

    % positions of top and bottom side link nodes:
    xTop = handles.model.nodes([indexTop(1); iLinkTop; indexTop(end)],1);
    yTop = handles.model.nodes([indexTop(1); iLinkTop; indexTop(end)],2);
    rTop = sub_getPathLengthRelative(handles.model.nodes([indexTop(1); iLinkTop; indexTop(end)],1:2));

    xBot = handles.model.nodes([indexBottom(1); iLinkBottom; indexBottom(end)],1);
    yBot = handles.model.nodes([indexBottom(1); iLinkBottom; indexBottom(end)],2);               
    rBot = sub_getPathLengthRelative(handles.model.nodes([indexBottom(1); iLinkBottom; indexBottom(end)],1:2));


    % Create arrays with new node locations:
    % for simplicity we will include the top,bottom,left and right
    % walls. But remember that those nodes have already been
    % inserted so don't reinsert them.

    [xNew,yNew] =  deal(zeros(length(iLinkLeft)+2,length(iLinkTop)+2));

    xNew(1,:)   = xTop;
    yNew(1,:)   = yTop;

    xNew(end,:) = xBot;
    yNew(end,:) = yBot;

    
    if growthFactor == 1

        % Get normalized versions of top and bottom surfaces:  
        % Remove linear fit of line connecting first and last point:
        yTop = yTop - yTop(1);
        yTop = yTop - yTop(end)*rTop;

        yBot = yBot - yBot(1);
        yBot = yBot - yBot(end)*rBot;


        for iLayer = 1:length(iLinkLeft)

            % Get x position:

            % Get average between top and bottom surfaces:
            xSurf = xTop + iLayer*(xBot - xTop) /(length(iLinkLeft)+1);

            % Normalize it to unit interval (0,1)
            xSurf = (xSurf- xSurf(1))/(xSurf(end) - xSurf(1));

            % Now scale to (xLeft,xRight)
            xNewLayer = xLeft(iLayer) + xSurf*(xRight(iLayer) - xLeft(iLayer));

            ySurf = yTop + iLayer*(yBot - yTop) /(length(iLinkLeft)+1); % linear interpolation between top and bottom


            % Now fit along line connecting yLeft and yRight:
            yAdd = yLeft(iLayer) + rTop*(yRight(iLayer)-yLeft(iLayer));

            yNewLayer = ySurf + yAdd;

            xNew(iLayer+1,:)       = xNewLayer';
            yNew(iLayer+1,:)       = yNewLayer';
            
        end

    else % growth factor
            
        yDist = yBot-yTop;

        yDist(1)   = sub_getPathLength(handles.model.nodes(indexLeft,:));
        yDist(end) = sub_getPathLength(handles.model.nodes(indexRight,:));
        
        ff = (growthFactor.^[1:nBlksVert-1]);

        fsum  = 1+sum(growthFactor.^[1:nBlksVert-1]);
        dy = yDist/(fsum);
 
        for iLayer = 1:length(iLinkLeft)
             
            % Get average between top and bottom surfaces:
            xSurf = xTop + iLayer*(xBot - xTop) /(length(iLinkLeft)+1);

            % Normalize it to unit interval (0,1)
            xSurf = (xSurf- xSurf(1))/(xSurf(end) - xSurf(1));

            % Now scale to (xLeft,xRight)
            xNew(iLayer+1,:)  = xLeft(iLayer) + xSurf*(xRight(iLayer) - xLeft(iLayer));
            
     
            fsum  = sum(growthFactor.^([1:iLayer]-1));
 
            yNew(iLayer+1,:)  = yTop + dy*fsum;
            
            [~,yNew(iLayer+1,1)]   = sub_getPathPositionAtDist(handles.model.nodes(indexLeft,:),   dy(1)*fsum);
            [~,yNew(iLayer+1,end)] = sub_getPathPositionAtDist(handles.model.nodes(indexRight,:),dy(end)*fsum);
            
        end
    
    end
    
   
    if lDebug
        plot(handles.hModelAxes,xNew',yNew','co-','markersize',2,'linewidth',1,'tag','tempNode')  
        plot(handles.hModelAxes,xNew, yNew ,'co-','markersize',2,'linewidth',1,'tag','tempNode')  
    end

    % Now smooth the new mesh nodes:
    xNewSm = xNew;
    yNewSm = yNew;

    for iSmooth = 1:nSmoothingIterations

        % Winslow smoothing:
        % see e.g. page 25 in http://kfe.fjfi.cvut.cz/~kucharik/Papers/Kucharik-disertation_06.pdf 

        for i = 2:size(xNew,1)-1
            for j = 2:size(xNew,2)-1

                xp = (xNewSm(i+1,j) -  xNewSm(i-1,j))/2;
                yp = (yNewSm(i+1,j) -  yNewSm(i-1,j))/2;
                xq = (xNewSm(i,j+1) -  xNewSm(i,j-1))/2;
                yq = (yNewSm(i,j+1) -  yNewSm(i,j-1))/2;                 

                alpha = xp^2  + yp^2;
                beta  = xp*xq + yp*yq;
                gamma = xq^2  + yq^2;

                xNewSm(i,j) = 1/(2*(alpha+gamma))*( alpha*(xNewSm(i,j+1) + xNewSm(i,j-1) ) +   gamma*(xNewSm(i+1,j)+xNewSm(i-1,j)) ...
                                                   -beta/2*(xNewSm(i+1,j+1) - xNewSm(i-1,j+1)+xNewSm(i-1,j-1)-xNewSm(i+1,j-1)  ));

                yNewSm(i,j) = 1/(2*(alpha+gamma))*( alpha*(yNewSm(i,j+1) + yNewSm(i,j-1)) +   gamma*(yNewSm(i+1,j)+yNewSm(i-1,j)) ...
                                                   -beta/2*(yNewSm(i+1,j+1) - yNewSm(i-1,j+1)+ yNewSm(i-1,j-1)-yNewSm(i+1,j-1)  ));           

            end
        end

    end
    
    % Now scan the boundaries and check if the boundary edges are close or cross new cell edges. 
    % This can be an issue for example where topography segments gridded
    % finer than the quad mesh dip down into the mesh. If this happens:
    %  1. keep removing new cell edges until it doesn't cross anymore
    %  2. also watch for where it dips down close to a cell edge but not
    %  necessary across it. This could lead to many very tiny elements in
    %  the MARE2DEM code.
    
    
    % Scan top and bottom boundaries:
    indLink  = [indexTop(1); iLinkTop; indexTop(end)];
    xLinkTop = handles.model.nodes(indLink,1);
    indTop   = unique( [iLinkTop; indexTop]);
    
    xTop = handles.model.nodes(indTop,1);
    yTop = handles.model.nodes(indTop,2);
    [xTop,isort] = sort(xTop);
    yTop         = yTop(isort);
    
    indLink  = [indexBottom(1); iLinkBottom; indexBottom(end)];
    xLinkBot = handles.model.nodes(indLink,1);
    indBot   = unique( [iLinkBottom; indexBottom]);
    
    xBot = handles.model.nodes(indBot,1);
    yBot = handles.model.nodes(indBot,2);
    [xBot,isort] = sort(xBot);
    yBot         = yBot(isort);
    
    [bKeepH,bKeepV] = deal(true(size(xNewSm)));
    
    targetAspect = 0; % KWK no longer using this OLD:  nHeight/nWidth/8; % if topo extends too far into cell, remove this layer boundary %kwk debug: magic number alert!
    
   
    nHorizEdgesRemoved = 0;
    nVertEdgesRemoved  = 0;
    
    for iCol = 1:size(xNewSm,2)-1
        
        % Get x,y of top segment for this column:
        bTop = xTop >= xLinkTop(iCol) & xTop <= xLinkTop(iCol+1);
        xt   = xTop(bTop);
        yt   = yTop(bTop);
              
        lCheck = true;    
        iRow   = 1; 
        while lCheck
            iRow = iRow + 1; % we start at row 2 since top row is existing outer boundary
            
            if iRow > size(xNewSm,1)-1 
                break
            end
            
            xr = xNewSm(iRow,iCol:iCol+1); 
            yr = yNewSm(iRow,iCol:iCol+1);  
            
            % Does line(xr,yr) intersect path(xt,yt)?
            xya = [xt(1:end-1) xt(2:end) yt(1:end-1) yt(2:end) ];
            [intersect, xi, yi, pa, pb] = m2d_getIntersections(xya,[xr yr]);
            
            % tests for insection of any line in xya with the single line in xyb
             if isempty(intersect) 
                 
                 % Check for closest point:
                 dist = sub_getRelativeDistancePointsToLine([xt yt], [xr' yr']);
                 
                 if any(dist < targetAspect)
                    bKeepH(iRow,iCol) = false;
                    nHorizEdgesRemoved = nHorizEdgesRemoved + 1;
                 else
                    lCheck = false;
                 end
                 
             else% knock out this line:
                 bKeepH(iRow,iCol) = false;
             end
             
        end
        
        % Check bottom now:
        
        % Get x,y of bottom segment for this column:
        bBot = xBot >= xLinkBot(iCol) & xBot <= xLinkBot(iCol+1);
        xb   = xBot(bBot);
        yb   = yBot(bBot);
              
        lCheck = true;    
        iRow = size(xNewSm,1); 
        while lCheck
            iRow = iRow - 1; % we start at 1 row up from bottom
            
            if iRow < 2
                break
            end
            
            xr = xNewSm(iRow,iCol:iCol+1); 
            yr = yNewSm(iRow,iCol:iCol+1);  
            
            % Does line(xr,yr) intersect path(xt,yt)?
            xya = [xb(1:end-1) xb(2:end) yb(1:end-1) yb(2:end) ];
            [intersect, ~, ~, ~, ~] = m2d_getIntersections(xya,[xr yr]);
            
            % tests for insection of any line in xya with the single line in xyb
             if isempty(intersect) 
                 
                % Check for closest point:
                 dist = sub_getRelativeDistancePointsToLine([xb yb], [xr' yr']);
                 
                 if any(dist < targetAspect)
                    bKeepH(iRow,iCol) = false;
                    nHorizEdgesRemoved = nHorizEdgesRemoved + 1;
                 else
                    lCheck = false;
                 end
                 
             else% knock out this line:
                 bKeepH(iRow,iCol) = false;
             end
             
        end
 
    end
 
   % Now check left and right side boundaries:
   
    indLink   = [indexLeft(1); iLinkLeft; indexLeft(end)];
    yLinkLeft = handles.model.nodes(indLink,2);
    indLeft   = unique( [iLinkLeft; indexLeft]);
    
    xLeft = handles.model.nodes(indLeft,1);
    yLeft = handles.model.nodes(indLeft,2);
    [yLeft,isort] = sort(yLeft);
    xLeft         = xLeft(isort);
    
    indLink    = [indexRight(1); iLinkRight; indexRight(end)];
    yLinkRight = handles.model.nodes(indLink,2);
    indRight   = unique( [iLinkRight; indexRight]);
    
    xRight = handles.model.nodes(indRight,1);
    yRight = handles.model.nodes(indRight,2);
    [yRight,isort] = sort(yRight);
    xRight         = xRight(isort);
  
    
    targetAspect = 0; % KWK no longer using this OLD: nWidth/nHeight/8; % if topo extends too far into cell, remove this layer boundary %kwk debug: magic number alert!
 
    
    for iRow = 1:size(xNewSm,1)-1
        
        % Get x,y of left segment for this row:
        bLeft = yLeft >= yLinkLeft(iRow) & yLeft <= yLinkLeft(iRow+1);
        xt   = xLeft(bLeft);
        yt   = yLeft(bLeft);
              
        lCheck = true;    
        iCol   = 1; 
       
        while lCheck
            
            iCol = iCol + 1; % we start at row 2 since top row is existing outer boundary
            
            if iCol > size(xNewSm,2)-1 
                break
            end
            
            xr = xNewSm(iRow:iRow+1,iCol)'; 
            yr = yNewSm(iRow:iRow+1,iCol)';  
            
            % Does line(xr,yr) intersect path(xt,yt)?
            xya = [xt(1:end-1) xt(2:end) yt(1:end-1) yt(2:end) ];
            [intersect, xi, yi, pa, pb] = m2d_getIntersections(xya,[xr yr]);
            
            % tests for insection of any line in xya with the single line in xyb
             if isempty(intersect) 
                 
                 % Check for closest point:
                 dist = sub_getRelativeDistancePointsToLine([xt yt], [xr' yr']);
                 
                 if any(dist < targetAspect)
                    bKeepV(iRow+1,iCol) = false;
                    nVertEdgesReomved = nVertEdgesRemoved + 1;
                 else
                    lCheck = false;
                 end
                 
             else% knock out this line:
                 bKeepV(iRow+1,iCol) = false;
             end
             
        end
        
    % Get x,y of right segment for this row:
        bRight = yRight >= yLinkRight(iRow) & yRight <= yLinkRight(iRow+1);
        xt   = xRight(bRight);
        yt   = yRight(bRight);
              
        lCheck = true;    
        iCol   = size(xNewSm,2);
       
        while lCheck
            iCol = iCol - 1;  
            
            if iCol < 1
                break
            end
            
            xr = xNewSm(iRow:iRow+1,iCol)'; 
            yr = yNewSm(iRow:iRow+1,iCol)';  
            
            % Does line(xr,yr) intersect path(xt,yt)?
            xya = [xt(1:end-1) xt(2:end) yt(1:end-1) yt(2:end) ];
            [intersect, xi, yi, pa, pb] = m2d_getIntersections(xya,[xr yr]);
            
            % tests for insection of any line in xya with the single line in xyb
             if isempty(intersect) 
                 
                 % Check for closest point:
                 dist = sub_getRelativeDistancePointsToLine([xt yt], [xr' yr']);
                 
                 if any(dist < targetAspect)
                    bKeepV(iRow+1,iCol) = false;
                    nVertEdgesReomved = nVertEdgesRemoved + 1;
                 else
                    lCheck = false;
                 end
                 
             else% knock out this line:
                 bKeepV(iRow+1,iCol) = false;
             end
             
        end       
%         % Check bottom now:
%         % Get x,y of bottom segment for this column:
%         bBot = xBot >= xLinkBot(iCol) & xBot <= xLinkBot(iCol+1);
%         xb   = xBot(bBot);
%         yb   = yBot(bBot);
%               
%         lCheck = true;    
%         iRow = size(xNewSm,1); 
%         while lCheck
%             iRow = iRow - 1; % we start at 1 row up from bottom
%             
%             if iRow < 2
%                 break
%             end
%             
%             xr = xNewSm(iRow,iCol:iCol+1); 
%             yr = yNewSm(iRow,iCol:iCol+1);  
%             
%             % Does line(xr,yr) intersect path(xt,yt)?
%             xya = [xb(1:end-1) xb(2:end) yb(1:end-1) yb(2:end) ];
%             [intersect, xi, yi, pa, pb] = m2d_getIntersections(xya,[xr yr]);
%             
%             % tests for insection of any line in xya with the single line in xyb
%              if isempty(intersect) 
%                  
%                 % Check for closest point:
%                  dist = sub_getRelativeDistancePointsToLine([xb yb], [xr' yr']);
%                  
%                  if any(dist < targetAspect)
%                     bKeepH(iRow,iCol) = false;
%                     nHorizEdgesRemoved = nHorizEdgesRemoved + 1;
%                  else
%                     lCheck = false;
%                  end
%                  
%              else% knock out this line:
%                  bKeepH(iRow,iCol) = false;
%              end
%              
%         end
 
    end    
    
    %
    % Check inner angles for each new vertex and flag small ones:
    %
    maxAngle = 0;
    minAngle = 180;

    
    for iCol = 1:size(xNewSm,2)
        for iRow = 1:size(xNewSm,1)-1
 
            % angles 1:4 are UR, LR, LL, UL clockwise
            % Angle 1:
            if iRow > 1 && iCol <  size(xNewSm,2) && bKeepH(iRow,iCol)
                v1(1) = diff( xNewSm([iRow],[iCol iCol+1]));
                v1(2) = diff( yNewSm([iRow],[iCol iCol+1]));
                v2(1) = diff( xNewSm([iRow iRow-1],[iCol]));
                v2(2) = diff( yNewSm([iRow iRow-1],[iCol]));
                angle1 = acos( sum(v1.*v2)/(norm(v1)*norm(v2)));    
            else
                angle1 = nan;
            end
          
            % Angle 2:
            if iRow < size(xNewSm,1) && iCol <  size(xNewSm,2) && bKeepH(iRow,iCol)
                v1(1) = diff( xNewSm([iRow],[iCol iCol+1]));
                v1(2) = diff( yNewSm([iRow],[iCol iCol+1]));
                v2(1) = diff( xNewSm([iRow iRow+1],[iCol]));
                v2(2) = diff( yNewSm([iRow iRow+1],[iCol]));
                angle2 = acos(sum(v1.*v2) /(norm(v1)*norm(v2)));                   
            else
                angle2 = nan;
            end       
            
            % Angle 3:
            if iRow < size(xNewSm,1) && iCol > 1  && bKeepH(iRow,iCol-1)
                v1(1) = diff( xNewSm([iRow],[iCol iCol-1]));
                v1(2) = diff( yNewSm([iRow],[iCol iCol-1]));
                v2(1) = diff( xNewSm([iRow iRow+1],[iCol]));
                v2(2) = diff( yNewSm([iRow iRow+1],[iCol]));
                angle3 = acos( sum(v1.*v2)/(norm(v1)*norm(v2)));                
            else
                angle3 = nan;
            end 
            
            % Angle 4:
            if iRow > 1 && iCol > 1 && bKeepH(iRow,iCol-1)
                v1(1) = diff( xNewSm([iRow],[iCol iCol-1]));
                v1(2) = diff( yNewSm([iRow],[iCol iCol-1]));
                v2(1) = diff( xNewSm([iRow iRow-1],[iCol]));
                v2(2) = diff( yNewSm([iRow iRow-1],[iCol]));
                angle4 = acos( sum(v1.*v2)/(norm(v1)*norm(v2)));
            else
                angle4 = nan;
            end 
            
            % Knock out vertical segment if an angle is too small:
            minAngleTolerance = 25*pi/180; %kwk debug magic number alert!
            
            if angle1 < minAngleTolerance  || angle4 < minAngleTolerance
                bKeepV(iRow,iCol) = false;
                angle1 = nan;
                angle4 = nan;
                nVertEdgesRemoved = nVertEdgesRemoved + 1;
            end
           
            if angle2 < minAngleTolerance  || angle3 < minAngleTolerance
                bKeepV(iRow+1,iCol) = false;
                angle2 = nan;
                angle3 = nan;
                nVertEdgesRemoved = nVertEdgesRemoved + 1;
            end   
            
            if  iCol <  size(xNewSm,2)    
                if ~bKeepH(iRow,iCol)
                    angle1 = nan;
                    angle2 = nan;   
                end
            end
            if  iCol > 1 
                if ~bKeepH(iRow,iCol-1)
                    angle3 = nan;
                    angle4 = nan;   
                end
             end
            
            minAngle = min(minAngle,min(180/pi*[angle1,angle2,angle3,angle4]));
            maxAngle = max(maxAngle,max(180/pi*[angle1,angle2,angle3,angle4]));

        end
    end
    
    
    delete(findobj(hFig,'tag','tempNodeP'))
    
%     plot(handles.hModelAxes,xNewSm(1:end,:)',yNewSm(1:end,:)','g--','markersize',2,'linewidth',1,'tag','tempNodeP')  
%     plot(handles.hModelAxes,xNewSm(:,1:end) ,yNewSm(:,1:end) ,'g--','markersize',2,'linewidth',1,'tag','tempNodeP')
%  

    plot(handles.hModelAxes,xNewSm(2:end-1,:)',yNewSm(2:end-1,:)','r--','markersize',2,'linewidth',1,'tag','tempNodeP')  
    plot(handles.hModelAxes,xNewSm(:,2:end-1) ,yNewSm(:,2:end-1) ,'r--','markersize',2,'linewidth',1,'tag','tempNodeP')
     
    xNewSm = xNewSm(2:end-1,2:end-1);
    yNewSm = yNewSm(2:end-1,2:end-1);
    bKeepH = bKeepH(2:end-1,2:end-1);
    bKeepV = bKeepV(2:end,2:end-1);  

    nx = size(xNewSm,1);
    ny = size(xNewSm,2);
    
% Scan for dangles and remove them:
    
% looping over interior nodes:
    for iRow=1:nx
        for iCol=1:ny
            if iCol>1
                if ~bKeepH(iRow,iCol-1) && ~bKeepH(iRow,iCol) && ~bKeepV(iRow+1,iCol) % dangle down
                    bKeepV(iRow,iCol) = false;
                    nVertEdgesRemoved = nVertEdgesRemoved + 1;
                end
                
                 if ~bKeepH(iRow,iCol-1) && ~bKeepH(iRow,iCol) && ~bKeepV(iRow,iCol) % dangle up
                    bKeepV(iRow+1,iCol) = false;
                    nVertEdgesRemoved = nVertEdgesRemoved + 1;
                 end
                
            end
        
        end
    end
    
    % Set up segments for new nodes:    
    segs = zeros(2*nx*ny-ny-nx ,2);
    iseg = 0;
    for i=1:nx
        for j=1:ny
            
             % add horizontal:
            if  bKeepH(i,j) && j < ny   % bKeepH(i,j) is horiz segment to right of i,j
                iseg            = iseg + 1;
                v1              = i + nx*(j-1);
                v2              = i + nx*(j  );
                segs(iseg,1:2)   = [v1 v2];
            end
            
            % add vertical:
             if bKeepV(i+1,j) && i < nx %  bKeepV has top and bottom rows still. bKeepV(i+1,j) corresponds to row 1 in reduced xNewSm. bKeep(i,j) is for up segment too...
                iseg            = iseg + 1;
                v1              = i + nx*(j-1);
                v2              = v1 + 1;
                segs(iseg,1:2)   = [v1 v2];
            end           
        end
    end 
    segs = segs(1:iseg,:);
    
    % Finally, create a new model by adding new nodes and segs to existing
    % model    
    newmodel = handles.model;    
    nNodeOld = size(newmodel.nodes,1);
    newmodel.nodes = [newmodel.nodes; xNewSm(:) yNewSm(:)];
    nNodeNew = size(newmodel.nodes,1);
  
    % Add segments linking to top and bottom nodes etc:
    segs = segs + nNodeOld;
    
    segsLeft    = [iLinkLeft  [1:nx]' + nNodeOld];
    segsRight   = [iLinkRight [[1:nx]+(ny-1)*nx]' + nNodeOld];

    % Knock out any small angles in vert segs for top and bottom link nodes:
    bKeepTop =  bKeepV(1,:);
    bKeepBot =  bKeepV(end,:);
    
    indTop = [1:nx:nx*(ny-1)+1]';
    indBot = [nx:nx:nx*ny]';
 
    if ~isempty(indTop) && ~isempty(indBot)
        segsTop     = [iLinkTop(bKeepTop)    indTop(bKeepTop) + nNodeOld ];
        segsBot     = [iLinkBottom(bKeepBot) indBot(bKeepBot) + nNodeOld ];
    else
        segsTop     = [iLinkTop(bKeepTop) iLinkBottom(bKeepBot) ];
        segsBot     = []; %[];
    end
%     if 
%         
%     else
%         
%     end
    segs = [segs; segsLeft;segsRight;segsTop;segsBot];
    
    x = newmodel.nodes(:,1); 
    y = newmodel.nodes(:,2);      
    x = x(segs)';
    y = y(segs)';
    x(3,:) = nan;
    y(3,:) = nan;
    
    n   = size(newmodel.nodes,1);
    
    segsExisting  = sub_getSegments(handles.model.segments);  

    segs = [segsExisting(:,1:2); segs];
    s   = ones(2*size(segs,1),1);  
    
    s(1:size(segsExisting,1)) = segsExisting(:,3);
    s(size(segs,1)+1:size(segs,1)+size(segsExisting,1)) = segsExisting(:,3);
    
    newmodel.segments = sparse([segs(:,1);segs(:,2)],[segs(:,2);segs(:,1)],s,n,n);
    
    % Plot the final segs in black and removed segs will be revealed
    % underneath in red from earlier plot:
    plot(handles.hModelAxes,x(:),y(:),'k-','markersize',2,'linewidth',1,'tag','tempNodeP');
    h = title(handles.hModelAxes,'Black lines: final mesh, Red dashed: segments removed due to degeneracies','tag','tempNode');
     
    %    % Update the quad setting figure with the quad stats:    
    str = sprintf(' Total Cells: %i (%i rows x %i columns)',(nx+1)*(ny+1),nx,ny+1);
    str = sprintf('%s\n Minimum angle: %.1f, Maximum angle: %.1f',str,minAngle,maxAngle);
    str = sprintf('%s\n \n Cleanup:   Edges removed: %i ''vertical'' and %i ''horizontal''',str,nVertEdgesRemoved,nHorizEdgesRemoved);   
   
    set(stQuad.hStatTxt,'string',str)
    
    % Store new model in guidata for hQuadFig: 
    guidata(hQuadFig,newmodel);
    
    % Enable the save button:
    set(findobj(hQuadFig,'tag','save'),'enable','on');

    set( hFig, 'Pointer', 'arrow' ); drawnow;
    set( hQuadFig, 'Pointer', 'arrow' ); drawnow;

end
 
%--------------------------------------------------------------------------
function dist = sub_getRelativeDistancePointsToLine(points,line)
% line = [x1 y1; x2 y2]
% points = same but with one or more rows
% https://en.wikipedia.org/wiki/Distance_from_a_point_to_a_line

num = abs(  diff(line(:,2))*points(:,1) - diff(line(:,1))*points(:,2) + line(2,1)*line(1,2)- line(2,2)*line(1,1));
den = sqrt( diff(line(:,1))^2 + diff(line(:,2))^2); % line length
dist = num/den;

% Normalize deistance by line length to get aspect ratio like quantity:
dist = dist/den;

end

%--------------------------------------------------------------------------
function sub_quadzillaMenu(hFig)

% Create UI figure with three sliders (contrast, brightness, transparency):
fWidth = 340;
fHeight= 390;

% ====================== 核心修复：替换缺失的m2d_newFigure ======================
hQuadFig = figure(...
    'Position', [150 150 fWidth fHeight], ...
    'menubar','none', ...
    'name','Quadzilla Mesh Settings', ...
    'tag','quadFig', ...
    'visible','off', ...
    'NumberTitle','off', ...
    'Resize','off');
% =============================================================================

dx = 40;
hOffset = 20;
vOffset = 60;
v0 = 50;

st = guidata(hFig);
 

%Set defaults if first call:
if ~isfield(st,'Quad') || ~isfield(st.Quad,'nWidth') 
    st.Quad.nWidth = 100;
    st.Quad.nHeight = 100;
    st.Quad.nSmoothingIterations = 0;
    st.Quad.nMergeWithCloseby = 0.05;
    st.Quad.nVertGrowth = 1;
end

 
st.Quad.hQuadFig = hQuadFig;

bgndColor = get(hQuadFig,'color');


hPickCorners = uicontrol(hQuadFig,'Style','pushbutton','string','Pick Corners ','fontsize',12, ...
                            'Position',[hOffset v0+20+3.5*vOffset+40  140 30 ],'backgroundcolor',bgndColor,...
                            'callback',  {@sub_pickRegionCorners, hFig, hQuadFig});                       

         
hGrowthLab  = uicontrol(hQuadFig,'Style','text','string','Height growth factor','fontsize',12, ...
                            'Position',[hOffset+120+40 v0+4*20+3.5*vOffset 140 20 ],'backgroundcolor',bgndColor,...
                            'tooltip','Turn smoothing to 0 or 1 if this factor > 1'); 
                                       
sCB = 'set(findobj(gcf,''tag'',''save''),''enable'',''off'') ';                            
st.Quad.hVertGrowth     = uicontrol(hQuadFig,'Style','edit','string',num2str(st.Quad.nVertGrowth), ...
                           'Position',[hOffset+120+40 v0+4*20+3.2*vOffset  140 20 ],'backgroundcolor',[1 1 1],...
                           'tag','hVertGrowth','callback',sCB,'tooltip','Turn smoothing to 0 or 1 if this factor > 1');                                                             
                        
hPreview = uicontrol(hQuadFig,'Style','pushbutton','string','Generate ','fontsize',12, ...
                            'Position',[hOffset v0+60 140 30 ],'backgroundcolor',bgndColor,...
                            'callback',  {@sub_makeQuadzillaMesh, hFig, hQuadFig});                       
                         
hCommit = uicontrol(hQuadFig,'Style','pushbutton','string','Save ','fontsize',12, ...
                            'Position',[hOffset+120+40 v0+60 140 30 ],'backgroundcolor',bgndColor,...
                            'callback',  {@sub_saveQuadzillaMesh, hFig, hQuadFig},'enable','off','tag','save'); 
                        
hStatLab  = uicontrol(hQuadFig,'Style','text','string','Quad Mesh Characteristics.:','fontsize',10, ...
                           'Position',[hOffset v0+30 140 20 ],'backgroundcolor',bgndColor);                         
                   
st.Quad.hStatTxt  = uicontrol(hQuadFig,'Style','text','string','','fontsize',10, ...
                           'Position',[hOffset 20 320 60 ],'backgroundcolor',bgndColor,'HorizontalAlignment','left');     

hWidthLab  = uicontrol(hQuadFig,'Style','text','string','Target block width (m):','fontsize',12, ...
                           'Position',[hOffset v0+20+3.5*vOffset  140 20 ],'backgroundcolor',bgndColor);  
                       
sCB = 'set(findobj(gcf,''tag'',''save''),''enable'',''off'') ';              
st.Quad.hWidth     = uicontrol(hQuadFig,'Style','edit','string',num2str(st.Quad.nWidth), ...
                           'Position',[hOffset v0+20+3.2*vOffset  140 20 ],'backgroundcolor',[1 1 1],'tag','quadwidth','callback',sCB);
                       
          
hHeightLab  = uicontrol(hQuadFig,'Style','text','string','Target block height (m):','fontsize',12, ...
                           'Position',[hOffset+120+40 v0+20+3.5*vOffset  140 20 ],'backgroundcolor',bgndColor); 
                       
st.Quad.hHeight     = uicontrol(hQuadFig,'Style','edit','string',num2str(st.Quad.nHeight), ...
                           'Position',[hOffset+120+40 v0+20+3.2*vOffset  140 20 ],'backgroundcolor',[1 1 1],'tag','quadheight','callback',sCB);    
                       
                       
hMergLab  = uicontrol(hQuadFig,'Style','text','string',' Merge Tolerance (0-1):','fontsize',12, ...
                           'Position',[hOffset v0+20+2.5*vOffset  140 20 ],'backgroundcolor',bgndColor);  
st.Quad.hMerg    = uicontrol(hQuadFig,'Style','edit','string',num2str(st.Quad.nMergeWithCloseby), ...
                           'Position',[hOffset v0+20+2.2*vOffset  140 20 ],'backgroundcolor',[1 1 1],'tag','quadmerge','callback',sCB);                         

hSmoothLab  = uicontrol(hQuadFig,'Style','text','string','# Smoothing Iterations:','fontsize',12, ...
                           'Position',[hOffset+120+40 v0+20+2.5*vOffset  140 20 ],'backgroundcolor',bgndColor);  
st.Quad.hSmooth     = uicontrol(hQuadFig,'Style','edit','string',num2str(st.Quad.nSmoothingIterations ), ...
                           'Position',[hOffset+120+40 v0+20+2.2*vOffset  140 20 ],'backgroundcolor',[1 1 1],'tag','quadnsmooth','callback',sCB);      
                       
hPick = uicontrol(hQuadFig,'Style','pushbutton','string','Optional  -->  Select New Corners','fontsize',12, ...
                            'Position',[hOffset+30 v0+15+1.5*vOffset  220 30 ],'backgroundcolor',bgndColor,...
                            'callback',  {@sub_rescaleSEGY, hFig, hQuadFig},'enable','off'); 
                         

set(hQuadFig,'CloseRequestFcn', {@sub_CloseQuadzillaMenu, hFig, hQuadFig});

 % store data in fig:
guidata(hFig,st);                        
set(hQuadFig,'visible','on');

end

%--------------------------------------------------------------------------
function sub_pickRegionCorners(~,~,hFig,hQuadFig)

% Get data from main Mamba2D figure:
st = guidata(hFig);

% Create a new figure with the boundary nodes in it and ask for the four
% corners:

fWidth = 900;
fHeight= 800;
hPickFig =  m2d_newFigure([fWidth fHeight],'menubar','none','name',...
                'Quadzilla: Pick region corners','tag','pickFig',...
                'visible','on','NumberTitle','off','Resize','off');

 
% Plot boundary sets:
 sub_plotRegionBoundary(hPickFig,st);

dx = 80;
dy = 30;

% Add picking buttons:
bgndColor = get(hPickFig,'color');

hTopLeft = uicontrol(hPickFig,'Style','pushbutton','string','Top left ','fontsize',12, ...
                            'Position',[20 fHeight-2*dy dx dy ],'backgroundcolor',bgndColor,...
                            'callback',  {@sub_pickCorner, hFig, hPickFig, 'topleft'});                       
                         
hTopRight = uicontrol(hPickFig,'Style','pushbutton','string','Top right ','fontsize',12, ...
                            'Position',[20+dx*1 fHeight-2*dy dx dy ],'backgroundcolor',bgndColor,...
                            'callback',  {@sub_pickCorner, hFig, hPickFig, 'topright'});      
                        
hBotLeft = uicontrol(hPickFig,'Style','pushbutton','string','Bottom left ','fontsize',12, ...
                            'Position',[20+dx*2 fHeight-2*dy dx dy ],'backgroundcolor',bgndColor,...
                            'callback',  {@sub_pickCorner, hFig, hPickFig, 'bottomleft'});      
                        
hBotRight = uicontrol(hPickFig,'Style','pushbutton','string','Bottom right ','fontsize',12, ...
                            'Position',[20+dx*3 fHeight-2*dy dx dy ],'backgroundcolor',bgndColor,...
                            'callback',  {@sub_pickCorner, hFig, hPickFig, 'bottomright'});                         
                                                                           
hDone = uicontrol(hPickFig,'Style','pushbutton','string',' Done ','fontsize',12, ...
                            'Position',[20+dx*4 fHeight-2*dy dx dy ],'backgroundcolor',bgndColor,...
                            'callback',  {@sub_pickCornerDone,hFig,hPickFig,hQuadFig});                        
                                                                           
end

%--------------------------------------------------------------------------
function sub_pickCornerDone(~,~,hFig,hPickFig,hQuadFig)

close(hPickFig)

% Update region in hFig

delete(findobj(hFig,'tag','tempNode'))
 
st = guidata(hFig);

sub_plotRegionBoundary(hFig,st);

figure(hQuadFig);
 
end

%--------------------------------------------------------------------------
function sub_pickCorner(hObj,~,hFig,hPickFig,sCorner)

str = sprintf('Select %s corner',sCorner);
ht = title(str);

[x,y,button]=ginput(1);

if button ~= 1
    delete(ht)
    return
end
 
delete(ht);

% get nearest node:
st = guidata(hFig);

iBoundary   = st.Quad.iBoundary;
iBoundary   = iBoundary(1:end-1); % removed duplicate

xn = st.model.nodes(iBoundary,1);
yn = st.model.nodes(iBoundary,2);

r2 = (xn-x).^2 + (yn-y).^2;
[~,imin] = min(r2);

iNode = iBoundary(imin);


indexLeft   = st.Quad.indexLeft;
indexRight  = st.Quad.indexRight;
indexTop    = st.Quad.indexTop;
indexBottom = st.Quad.indexBottom;

iNodeTopLeft  = indexTop(1);
iNodeTopRight = indexTop(end);
iNodeBotRight = indexBottom(end);
iNodeBotLeft  = indexBottom(1);


switch lower(sCorner)
    
    case 'topleft'
        iNodeTopLeft  = iNode;
    case 'topright'
        iNodeTopRight = iNode;
    case 'bottomleft'
        iNodeBotLeft  = iNode;
    case 'bottomright'
        iNodeBotRight = iNode;
end


iTopLeft   = find(iBoundary == iNodeTopLeft);
iTopRight  = find(iBoundary == iNodeTopRight);
iBotRight  = find(iBoundary == iNodeBotRight);
iBotLeft   = find(iBoundary == iNodeBotLeft);
 
ind = [1:length(iBoundary) 1:length(iBoundary)];


if iTopLeft < iTopRight
    indexTop = ind(iTopLeft:iTopRight);
else
    indexTop = ind(iTopLeft:iTopRight+length(iBoundary));
end
if iTopRight < iBotRight
    indexRight = ind(iTopRight:iBotRight);
else
    indexRight = ind(iTopRight:iBotRight+length(iBoundary));
end
if iBotRight < iBotLeft
    indexBottom = ind(iBotRight:iBotLeft);
else
    indexBottom = ind(iBotRight:iBotLeft+length(iBoundary));
end
if iBotLeft < iTopLeft
    indexLeft = ind(iBotLeft:iTopLeft);
else
    indexLeft = ind(iBotLeft:iTopLeft+length(iBoundary));
end

st.Quad.indexLeft   = flipud(iBoundary(indexLeft));
st.Quad.indexRight  = iBoundary(indexRight);
st.Quad.indexTop    = iBoundary(indexTop);
st.Quad.indexBottom = flipud(iBoundary(indexBottom));

% Plot boundary sets:
sub_plotRegionBoundary(hPickFig,st);

guidata(hFig,st);

end

%--------------------------------------------------------------------------
function sub_plotRegionBoundary(hFig,st)
    
    figure(hFig);
     
    indexLeft   = st.Quad.indexLeft;
    indexRight  = st.Quad.indexRight;
    indexTop    = st.Quad.indexTop;
    indexBottom = st.Quad.indexBottom;
    
    ht = plot(st.model.nodes(indexTop,1),   st.model.nodes(indexTop,2),   'c-','markersize',12,'linewidth',3,'tag','tempNode');
    hold on;
    hb = plot(st.model.nodes(indexBottom,1),st.model.nodes(indexBottom,2),'k-','markersize',12,'linewidth',3,'tag','tempNode');
    hl = plot(st.model.nodes(indexLeft,1)  ,st.model.nodes(indexLeft,2),  'm-','markersize',12,'linewidth',3,'tag','tempNode');
    hr = plot(st.model.nodes(indexRight,1), st.model.nodes(indexRight,2), 'g-','markersize',12,'linewidth',3,'tag','tempNode');

    plot(st.model.nodes(indexTop(1),1),    st.model.nodes(indexTop(1),2),    'c.','markersize',24,'tag','tempNode')
    plot(st.model.nodes(indexTop(end,1)),  st.model.nodes(indexTop(end),2),  'g.','markersize',24,'tag','tempNode')
    plot(st.model.nodes(indexRight(end),1),st.model.nodes(indexRight(end),2),'k.','markersize',24,'tag','tempNode')
    plot(st.model.nodes(indexLeft(end),1), st.model.nodes(indexLeft(end),2), 'm.','markersize',24,'tag','tempNode')     
    axis ij;
    
    hl = legend([ht hb hl hr],{'Top','Bottom','Left','Right'});
    set(hl,'tag','tempNode');
    
end

%--------------------------------------------------------------------------
function sub_CloseQuadzillaMenu(~,~,hFig,hQuadFig)
    % 1. 先安全清理临时绘图元素，加异常捕获防止崩溃
    try
        if ishandle(hFig) && isvalid(hFig)
            delete(findobj(hFig,'tag','tempSegs'))
            delete(findobj(hFig,'tag','tempregion'))
            delete(findobj(hFig,'tag','tempNode')) 
            delete(findobj(hFig,'tag','tempNodeP')) 
            % 仅当主窗口有效时才切换当前图窗、清空标题
            set(groot,'CurrentFigure',hFig);
            title(hFig, '');
        end
    catch
        % 清理失败静默跳过，不弹窗卡死
    end

    % 2. 最后再关闭四边形设置子窗口（调换原代码执行顺序）
    try
        if ishandle(hQuadFig) && isvalid(hQuadFig)
            delete(hQuadFig);
        end
    catch
    end
end
%--------------------------------------------------------------------------
function sub_CloseTriangleMenu(~,~,hFig,hTriFig)
 
    delete(findobj(hFig,'tag','tempSegs'))
    delete(findobj(hFig,'tag','tempregion'))
    delete(findobj(hFig,'tag','tempNode')) 
    delete(findobj(hFig,'tag','tempNodeP')) 
    
    set(groot,'CurrentFigure',hFig);
    title('')
    
    delete(hTriFig);

end
%--------------------------------------------------------------------------
function [nBlks, width0] = sub_getNumGrowingBlocks(nWidth,growthFactor,dist)
% given a distance, growthFactor and target width, computes number of
% blocks and modified width to make it fit

    y = zeros(10^4,1);
    y(1) = nWidth;
    icnt = 1;
    while y(icnt) < dist
        icnt = icnt + 1;
        y(icnt) = y(icnt-1) + nWidth*growthFactor^icnt; % the next yy 
    end
    y = y(1:icnt);
    
    % Pick number of blocks depending on whether y(icnt) or icnt-1 is
    % closer to dist:
    if abs(y(icnt)-dist) > abs(y(icnt-1)-dist)
        icnt = icnt - 1;
    end

    nBlks = icnt;
    
    fsum  = 1+sum(growthFactor.^[1:nBlks-1]);
    
    width0 = dist/fsum;
    
    
end

%--------------------------------------------------------------------------
function [posBlock] = sub_getGrowingBlocks(growthFactor,dist,nBlks)
% given the number of blocks, fixed distance, fixed growthFactor computes
% block edge locations 

fsum  = 1+sum(growthFactor.^[1:nBlks-1]);

width0 = dist/fsum;

posBlock = cumsum(width0*growthFactor.^[0:nBlks-2]);
    
end

%--------------------------------------------------------------------------
function [model, iLink] = sub_getSurfLinkNodes(model,index,nInsert,growthFactor,ap,ax,nMergeWithCloseby,sDir)
%
% inserts new nodes at xInsert,yInsert, or uses existing nodes if the 
% relative distance is less than nMergeWithCloseby

pathLength  = sub_getPathLength(model.nodes(index,1:2));  

 
%blockLength = pathLength/nInsert;
posBlock = sub_getGrowingBlocks(growthFactor,pathLength,nInsert);


%dist   = sub_getDistance(model.nodes,index([1 end]));     
%blockLength = dist/nInsert;

iLink = zeros(nInsert-1,1);

x = model.nodes(index,1);
y = model.nodes(index,2);

% create a segment adjacency structure for only the boundary nodes for
% much faster searches when dealing with huge models:
n = size(model.nodes,1);
segAdj = [ [index(1:end-1);index(2:end)]  [index(2:end);index(1:end-1)] ];
s = ones(2*(length(index)-1),1);
segments = sparse(segAdj(:,1),segAdj(:,2),s,n,n);

dp = diff([posBlock pathLength]);

for i = 1:nInsert-1

    [xInsert,yInsert] = sub_getPathPositionAtDist(model.nodes(index,1:2),posBlock(i)); 

    [inodes,~,~,~] = sub_nearestSegment(model.nodes,segments,xInsert,yInsert,ap, ax );

    % now get distance to inodes:

    dist1 = sqrt( (xInsert - model.nodes(inodes(1),1)).^2  + (yInsert - model.nodes(inodes(1),2)).^2);
    dist2 = sqrt( (xInsert - model.nodes(inodes(2),1)).^2  + (yInsert - model.nodes(inodes(2),2)).^2);

    if dist1/dp(i) <= nMergeWithCloseby   
        iLink(i) = inodes(1);
    elseif dist2/dp(i) <= nMergeWithCloseby    
        iLink(i) = inodes(2);
    else
        model = sub_divideSegment(model,inodes,xInsert,yInsert);
        iLink(i) = size(model.nodes,1);
        
        % update segment adjacency array:
        segments(inodes(1),inodes(2)) = 0; %kwk debug: not it says sparse indexing expressions may be slow. can we replace with own custom code?
        segments(inodes(2),inodes(1)) = 0;
        segments(inodes(1),iLink(i))  = 1;
        segments(inodes(2),iLink(i))  = 1;
        segments(iLink(i) ,inodes(2)) = 1;
        segments(iLink(i) ,inodes(1)) = 1;
    end
end

end
%--------------------------------------------------------------------------
function  [x,y] = sub_getPathPositionAtDist(nodes,dist)
%
% Returns the x,y position of path defined by nodes at distance dist along
% the path made by connecting the node
%

dRpath = (sqrt( diff(nodes(:,1) ).^2  + diff(nodes(:,2)).^2));

mileage = [0;cumsum(dRpath)];

x = interp1(mileage,nodes(:,1),dist);
y = interp1(mileage,nodes(:,2),dist);


end

%--------------------------------------------------------------------------
function  [x,y] = sub_getPathPositionAtRelativeDist(nodes,dist)
%
% Returns the x,y position of path defined by nodes at RELATIVE distance dist along
% the path made by connecting the nodes
%

dRpath = (sqrt( diff(nodes(:,1) ).^2  + diff(nodes(:,2)).^2));

mileage = [0;cumsum(dRpath)];
mileage = mileage./mileage(end);

x = interp1(mileage,nodes(:,1),dist);
y = interp1(mileage,nodes(:,2),dist);


end

%--------------------------------------------------------------------------
function  r = sub_getPathLengthRelative(nodes)
%
% Returns the r in relative units (0 to 1) for position along path defined
% by connecting nodes in order.

dRpath = (sqrt( diff(nodes(:,1) ).^2  + diff(nodes(:,2)).^2));

mileage = [0;cumsum(dRpath)];

r = mileage/mileage(end); 

end

%--------------------------------------------------------------------------
function dist = sub_getPathLength(nodes)

dist = sum(sqrt( diff(nodes(:,1) ).^2  + diff(nodes(:,2)).^2));

end

%--------------------------------------------------------------------------
function dist = sub_getDistance(nodes,inodes)

dist = sqrt( diff(nodes(inodes,1)).^2  + diff(nodes(inodes,2)).^2);

end

%--------------------------------------------------------------------------
function [indexTop, indexBottom,indexLeft,indexRight, bGood ] = sub_getRegionCorners(model,iBoundary)

    bGood = true; % set to false at the end if picked corners are not consistent
    
    % ========== 新增：输入合法性前置校验 ==========
    % 过滤非法节点编号（NaN、负数、超范围、非整数）
    iBoundary = iBoundary(~isnan(iBoundary) & iBoundary >= 1 & iBoundary <= size(model.nodes,1));
    iBoundary = round(iBoundary); % 强制转为整数
    if length(iBoundary) < 4
        warndlg('区域边界节点不足，无法识别四边形角点，请检查区域是否为闭合凸四边形');
        bGood = false;
        indexTop = [];
        indexBottom = [];
        indexLeft = [];
        indexRight = [];
        return;
    end

    % This is a bit of a hack job at the momemt...

    x = model.nodes(iBoundary,1);
    y = model.nodes(iBoundary,2);

    dx = diff(x);
    dy = diff(y);

    dr = sqrt(dx.^2+dy.^2);
    % ========== 新增：处理重合节点，避免除以零产生NaN ==========
    dr(dr < eps) = 1e-6; 
    dx = dx./dr;
    dy = dy./dr;

    ld = length(dx);
    vb = [ -dx([ld 1:ld-1]) -dy([ld 1:ld-1]) ] ;
    va = [dx dy];

    % unit vector bisecting inner angle at each node:
    vc = (va+vb)/2;

    % Get direction:
    ang = atan2d(vc(:,2),vc(:,1));

    ang_vavb = atan2d( va(:,1).*vb(:,2) - vb(:,1).*va(:,2), sum(va.*vb,2));

    ang_vavb(ang_vavb<0) = ang_vavb(ang_vavb<0) + 360;

    bInnerAng = ang_vavb < 180;

    [ geom, iner, cpmo ] = sub_polygeom( x, y );
    % centroid of polygon:
    xc = geom(2);
    yc = geom(3);

    bLeftSide   = x(1:end-1) < xc;    
    bRightSide  = x(1:end-1) > xc;    

    cva = va(:,1) + 1i*va(:,2);
    cvb = vb(:,1) + 1i*vb(:,2);


    scoreUL = abs(( cva - complex( 1, 0) )).^2 + abs(( cvb - complex( 0, 1) )).^2;

    scoreUR = abs(( cva - complex( 0, 1) )).^2 + abs(( cvb - complex(-1, 0) )).^2;

    scoreLR = abs(( cva - complex(-1, 0) )).^2 + abs(( cvb - complex( 0,-1) )).^2;

    scoreLL = abs(( cva - complex( 0,-1) )).^2 + abs(( cvb - complex( 1, 0) )).^2;

    scoreLR(bLeftSide)  = inf;
    scoreLL(bRightSide) = inf;
    scoreUR(bLeftSide)  = inf;
    scoreUL(bRightSide) = inf;  


    iSmall = find(scoreUR < .5);
    if length(iSmall)>1
        % take rightmost one
       [~,imax] = max(y(iSmall)); 
       indexUR = iSmall(imax);
    else
       [~,indexUR] = min(scoreUR); 
    end

    iSmall = find(scoreLR < .5);
    if length(iSmall)>1
        % take rightmost one
       [~,imax] = max(y(iSmall)); 
       indexLR = iSmall(imax);
    else
       [~,indexLR] = min(scoreLR); 
    end

    iSmall = find(scoreUL < .5);
    if length(iSmall)>1
        % take left one
       [~,imin] = min(y(iSmall)); 
       indexUL = iSmall(imin);
    else
       [~,indexUL] = min(scoreUL); 
    end

    iSmall = find(scoreLL < .5);
    if length(iSmall)>1
        % take leftmost one
       [~,imin] = min(y(iSmall)); 
       indexLL = iSmall(imin);
    else
       [~,indexLL] = min(scoreLL); 
    end             

    % ========== 新增：角点索引合法性校验 ==========
    cornerIdx = [indexUR, indexLR, indexUL, indexLL];
    if any(~isfinite(cornerIdx)) || any(cornerIdx < 1) || any(cornerIdx > ld)
        warndlg('无法识别有效四边形角点，区域形状不适合四边形网格，请改用三角形网格');
        bGood = false;
        indexTop = [];
        indexBottom = [];
        indexLeft = [];
        indexRight = [];
        return;
    end

    ind = [1:length(iBoundary)-1 1:length(iBoundary)-1];

    % Get sorted list of top and bottom, from left to right sides:
    if indexUR < indexUL
        indexTop = ind(indexUL:indexUR+length(iBoundary)-1);
    else
        indexTop = indexUL:indexUR;
    end

    if indexLR < indexLL
        indexBottom = indexLR:indexLL;
    else
        indexBottom = ind(indexLR:indexLL+length(iBoundary)-1);            
    end
    indexBottom = fliplr(indexBottom);

    % Get sorted list of left and right sides, sorted from top to
    % bottom: (top is up on plot, so negative y, bottom is down, or
    % more positive y):

    if indexUR < indexLR
        indexRight = indexUR:indexLR;
    else
        indexRight = ind(indexUR:indexLR+length(iBoundary)-1);
    end


     if indexLL < indexUL
        indexLeft = indexLL:indexUL;
    else
        indexLeft = ind(indexLL:indexUL+length(iBoundary)-1);
    end
    indexLeft = fliplr(indexLeft);               

    % return index to global node
    indexUL = iBoundary(indexUL);
    indexUR = iBoundary(indexUR);
    indexLL = iBoundary(indexLL);
    indexLR = iBoundary(indexLR);

    indexTop    = iBoundary(indexTop);
    indexBottom = iBoundary(indexBottom);
    indexRight  = iBoundary(indexRight);
    indexLeft   = iBoundary(indexLeft); 
        
    % Check that boundary is good:
    % Only one node should be shared between adjacent sides:
    if length(intersect(indexTop,indexLeft))>1
        bGood = false;
    end
    if length(intersect(indexTop,indexRight))>1
        bGood = false;
    end    
    if length(intersect(indexBottom,indexLeft))>1
        bGood = false;
    end
    if length(intersect(indexBottom,indexRight))>1
        bGood = false;
    end    
        
end

%----------------------------------------------------------------------
function iregion = sub_getRegion(handles,x,y)
    iregion = 0;
    
    if ~isfield(handles.model, 'DT') || isempty(handles.model.DT)
        return;
    end
    
    if ~isfield(handles.model, 'TriIndex') || isempty(handles.model.TriIndex)
        return;
    end
    
    try
        % 新版delaunayTriangulation正确调用方式：对象.方法(参数)
        si = handles.model.DT.pointLocation(x, y);
        
        if ~isnan(si) && si >= 1 && si <= length(handles.model.TriIndex)
            iregion = handles.model.TriIndex(si);
        end
    catch
        iregion = 0;
    end
end
%----------------------------------------------------------------------
function varargout = sub_getPoints(N,hFigure,hModelAxes)
% returns index of closest node
% handles
% x0,y0 location to find closest node to
%
% Never implemented N....
%
k = waitforbuttonpress;
t = get(hModelAxes,'currentpoint');
x = t(1,1);
y = t(2,2);
k = get(hFigure,'selectiontype');
if strcmp(k,'alt')
    button = 0;
else
    button = 1;
end
if nargout>2
    varargout = {x, y, button};
elseif nargout==2
    varargout = {x, y};
end

 
end
%----------------------------------------------------------------------
function model = sub_divideSegment(model,inodes,x,y)
% divides up the segment connecting nodes inodes at point x,y
%
if diff(inodes) == 0  % don't connect node to itself.
    return;
end

% Insert the new node at x,y:
model.nodes = [model.nodes; [x,y] ];
 
% Remove old segment connecting inodes in the node adjacency matrix:
attr = model.segments(inodes(1),inodes(2)); % get the attribute 
 
model.segments(inodes(1),inodes(2)) = 0;
model.segments(inodes(2),inodes(1)) = 0;

% Now add the two new segments:

% first segment
nnodes = size(model.nodes,1);
model.segments(inodes(1),nnodes ) = attr;
model.segments(nnodes, inodes(1)) = attr;

% second segment
model.segments(inodes(2),nnodes ) = attr;
model.segments(nnodes, inodes(2)) = attr;


end
%----------------------------------------------------------------------
function [handles,isegNodes] = sub_addSegment(handles,inodes,varargin)
    % 简化版sub_addSegment：不处理线段交点，只添加基本线段
    % 彻底解决m2d_getIntersections缺失的问题
    
    % 处理输入参数
    if nargin == 3
        nSegAttr = varargin{1};
    else
        nSegAttr = 1; % 默认线段属性
    end
    
    isegNodes = [];
    
    % 不连接节点到自身
    if inodes(1) == inodes(2)
        return;
    end
    
    % 检查线段是否已经存在
    if handles.model.segments(inodes(1),inodes(2)) ~= 0
        isegNodes = inodes;
        return;
    end
    
    % 直接添加线段，跳过所有交点检测逻辑
    handles.model.segments(inodes(1),inodes(2)) = nSegAttr;
    handles.model.segments(inodes(2),inodes(1)) = nSegAttr;
    
    isegNodes = inodes;
end
%--------------------------------------------------------------------------
function [icrossed, distAlongSeg] = sub_getNodesIntersected(handles,inodes)
% 
% Find any nodes that the proposed segment intersects:
%
icrossed     = [];
distAlongSeg = [];

% nodes to examine:
x = handles.model.nodes(:,1);
y = handles.model.nodes(:,2);

% segment endpoints
x1 = (x(inodes(1)));
x2 = (x(inodes(2)));
y1 = (y(inodes(1)));
y2 = (y(inodes(2)));


% First cut to reduce number of comps, is x,y in bounding box of the
% segment?
tol = 1000*eps;
in = find( (x >= min(x(inodes))-tol &  x <= max(x(inodes))+tol & y >= min(y(inodes))-tol & y <= max(y(inodes))+tol));

x = x(in);
y = y(in);


dx1 =  x-x1;
dy1 =  y-y1;
dx2 = x2-x1;
dy2 = y2-y1;
lb = sqrt(dx2.^2 + dy2.^2);
dx2 = dx2./lb;
dy2 = dy2./lb;
cstheta = (dx1.*dx2+dy1.*dy2); %./(dx2.*dx2+dy2.*dy2); %  abs(a)/abs(b) * cos theta = (a dot b) / (abs(b)^2)

% if cstheta between 0 and 1 then in  orthogonal intersection is between endpoints of segment
ii  = find(abs(cstheta./lb-0.5) <=0.5);

distFromSeg =  abs( dx1(ii).*dy2 - dx2.*dy1(ii) );

distAlongSeg = cstheta(ii);

% keep nodes on segment:

tol = 1d-6; % micrometer seems reasonable... %KWK debug, magic number alert!
ikeep = (abs(distFromSeg) < tol);

icrossed = in(ii(ikeep));
distAlongSeg = distAlongSeg(ikeep);
distFromSeg = distFromSeg(ikeep);

% only keep nodes other than segment endpoints, and output them in
% order along p1 to p2:
[icrossed, i] = setdiff(icrossed,inodes);
distAlongSeg = distAlongSeg(i);
distFromSeg = distFromSeg(i);

[distAlongSeg, isort] = sort(distAlongSeg);
icrossed = icrossed(isort);
distFromSeg = distFromSeg(isort);


end

%----------------------------------------------------------------------
function segments = sub_newSegment(segments,inodes,varargin)
% Add segment connecting nodes inodes.
% *** Only call this routine if the segments do not overlap or intersect*** 
% *** If you are unsure, use sub_addSegments instead since it checks for
% intersctions with nodes and segments.
% inodes can have more than one row for many segments
%----------------------------------------------------------------------
 
if nargin ==3
    nSegAttr = varargin{1};
else
    nSegAttr = 1;
end

n = size(segments,1);

ind = sub2ind([n n],[inodes(:,1);inodes(:,2)],[inodes(:,2);inodes(:,1)]);
s   = nSegAttr*ones(size(inodes,1),1);  
 
segments(ind) = [s; s];

end
%----------------------------------------------------------------------
function handles = sub_updateLayers(handles)
% updates order of plot objects to:
% sites > nodes > segments > regions


hsites    = findobj(handles.hModelAxes,'tag','sites');
hnodes    = findobj(handles.hModelAxes,'tag','node');
hsegments = findobj(handles.hModelAxes,'tag','segment');
hfree     = findobj(handles.hModelAxes,'tag','freeregion');
hfixed    = findobj(handles.hModelAxes,'tag','fixedregion');
hgeoimage = findobj(handles.hModelAxes,'tag','geoimage');
hsegy     = findobj(handles.hModelAxes,'tag','segy');

uistack(hsegments,'top')
uistack(hnodes,'top')
uistack(hsites,'top')
% uistack(hgeoimage,'bottom')%kwk debug need to test this jan 2016
uistack(hfixed,'bottom')
uistack(hfree,'bottom')



uistack(findobj(handles.hFigure,'tag','mtsites'),'top');
uistack(findobj(handles.hFigure,'tag','csemsites'),'top');
uistack(findobj(handles.hFigure,'tag','transmitters'),'top');

uistack(findobj(handles.hFigure,'tag','csemRxNames'),'top');
uistack(findobj(handles.hFigure,'tag','mtRxNames'),'top');
uistack(findobj(handles.hFigure,'tag','txNames'),'top');


% Also update the counters:

nnodes = size(handles.model.nodes,1);

segs = sub_getSegments(handles.model.segments);
nsegs = size(segs,1);

set(findobj(handles.hFigure,'tag','NodeCounter'),'string',num2str(nnodes));
set(findobj(handles.hFigure,'tag','SegmentCounter'),'string',num2str(nsegs));

nfree  = length(find(handles.model.freeparameter(:) > 0 ));  
nfixed = length(find(handles.model.freeparameter(:) == 0));  
set(findobj(handles.hFigure,'tag','FreeCounter'),'string',num2str(nfree));
set(findobj(handles.hFigure,'tag','FixedCounter'),'string',num2str(nfixed));
end


%----------------------------------------------------------------------
function [handles, isegNodes] = sub_addNodeSeg(x0,y0,handles,stSettings,lastnode,nSegAttr,varargin) 

if length(varargin)==1
    minDist = varargin{1};
else
    minDist = stSettings.dr;
end
%
% First we add the new node at x0,y0:
%
[handles, inode] = sub_addNode(x0,y0,handles,stSettings,minDist);
% if lastnode given, connect a segment back to it, subject to any
% intersections and new nodes needed along the path:
%

if ~isempty(lastnode)
    
    [handles,isegNodes] = sub_addSegment(handles,[lastnode inode],nSegAttr);
    %isegNodes is index to all nodes (2 or more) for new segment and any
    %required divisions accounting for intersections.
    % isegNodes(1) is the leading node to be used for the next segment
    isegNodes = fliplr(isegNodes); % most recent is now first
else
    isegNodes = inode;
end

end

%----------------------------------------------------------------------
function [handles, inode] = sub_addNode(x0,y0,handles,stSettings,varargin) 

% inode is index of the node

if length(varargin)==1
    minDist = varargin{1};
else
    minDist = stSettings.dr;
end

%
% Make sure x,y not outside of the bounding box if it exists:
%
if length(handles.model.boundingBox) == 4
    sLocation = sub_checkBBLocation(handles,x0,y0);
    switch sLocation
        case 'outside'
            if x0 < handles.model.boundingBox(3)
                x0 = handles.model.boundingBox(3);
            elseif x0 > handles.model.boundingBox(4)
                x0 = handles.model.boundingBox(4);
            end
            if y0 < handles.model.boundingBox(1)
                y0 = handles.model.boundingBox(1);
            elseif y0 > handles.model.boundingBox(2)
                y0 = handles.model.boundingBox(2);
            end
            beep;
            disp('Warning: node location outside bounding box, moved to boundary.')

        case {'inside','corner','left','right','top','bottom'}
            % nothing to do
    end   
    
     
end

tol = minDist + 10000*eps; % eps is maching precision

% see if point closer than threshold to existing node:
[inode, dist] = sub_nearestNode(handles.model.nodes,x0,y0,handles.axesPosPixels,axis(handles.hModelAxes));
 
if ~isempty(dist)
    if dist > tol % far enough away, check to see if on a segment
       % if handles.checkSegDist   % sometimes we skip the segment test to speed up bulk addition of nodes...
            [inodes,dist,x,y] = sub_nearestSegment(handles.model.nodes,handles.model.segments,x0,y0,handles.axesPosPixels,axis(handles.hModelAxes));
      %  else
      %      dist = realmax;
      %  end
        if dist <= tol  % mouse click was closer than threshold distance to a segment
            % plot new node and divide up old segment
            handles.model = sub_divideSegment(handles.model,inodes,x,y);
            
            inode = size(handles.model.nodes,1);
         
        else  % away from existing nodes and segments, just add a new node
            handles.model.nodes = [handles.model.nodes; [x0,y0] ];
            inode = size(handles.model.nodes,1);
            handles.model.segments(inode,:) = 0;
            handles.model.segments(:,inode) = 0;
             
        end
    else  % do nothing if too close to existing node
%         beep
%         fprintf('using existing nearby node!\n');
    end
else % dist isempty, so this must be the first node, add it:
        handles.model.nodes = [handles.model.nodes; [x0,y0] ];
        
        inode = size(handles.model.nodes,1);
        handles.model.segments(inode,:) = 0;
        handles.model.segments(:,inode) = 0;
end
 
end
%----------------------------------------------------------------------
function setValues_Callback(hObject)

handles = guidata(hObject);

set(handles.hFigure,'pointer','cross')
title('*** 点击区域选择，或拖拽框选多个区域 ***','color','r')

while 1
    
    [ x0, x1, y0, y1 ] = selectWithRBBox(handles,true);
    
    if isempty(x0)
        break
    end
    
    % 判断是否已有网格
    hasDT = isfield(handles.model, 'DT') && ~isempty(handles.model.DT) ...
        && (isa(handles.model.DT, 'triangulation') || isa(handles.model.DT, 'delaunayTriangulation'));
    
    iregion = [];
    
    if hasDT
        % ========== 有网格：沿用原生高精度点选/框选 ==========
        DT = handles.model.DT;
        TriIndex = handles.model.TriIndex;
        
        if x0 == x1 && y0 == y1
            si = pointLocation(DT,x0,y0);
            if ~isnan(si) && si >= 1 && si <= length(TriIndex)
                iregion = TriIndex(si);
            end
        else
            xv = [x0 x0 x1 x1 x0]';
            yv = [y0 y1 y1 y0 y0]';
            triConn = DT.ConnectivityList;
            triPoints = DT.Points;
            TriCenters = (triPoints(triConn(:,1),:) + triPoints(triConn(:,2),:) + triPoints(triConn(:,3),:)) / 3;
            inpoly = inpolygon(TriCenters(:,1),TriCenters(:,2),xv,yv);
            iregion = unique(TriIndex(inpoly));
            
            si = pointLocation(DT,xv,yv);
            si = si(~isnan(si));
            iadd = unique(TriIndex(si));
            iregion = unique([iregion; iadd]);
        end
        
    else
        % ========== 无网格：手动输入区域号直接赋值 ==========
        prompt = {'请输入区域编号（多个用空格分隔）：'};
        definput = {'1'};
        dlg_title = '选择区域';
        answer = inputdlg(prompt, dlg_title, 1, definput);
        
        if isempty(answer)
            continue;
        end
        
        iregion = str2num(answer{1}); %#ok<ST2NM>
        if isempty(iregion) || any(iregion < 1)
            warndlg('请输入有效的正整数区域编号');
            continue;
        end
        
        % 尝试高亮显示（有网格才会高亮，无网格不影响赋值）
        try
            sub_highlightRegions(handles, iregion);
        catch
            % 无网格高亮失败也没关系，不影响参数写入
        end
    end
    
    % 过滤非法编号，空区域直接跳过
    iregion = iregion(iregion >= 1);
    if isempty(iregion)
        continue;
    end
    
    sub_highlightRegions(handles,iregion);
    
    % ========== 参数设置（全中文提示） ==========
    aniso = handles.setAnisotropy.String{handles.setAnisotropy.Value};
    
    switch aniso
        case 'isotropic'
            sRes = '各向同性电阻率 (Ω·m)，例如：10.0';
            sBnd = '参数上下界，例如：0.1 100.0';
            sPrj = '先验值 权重，例如：10.0  1';
            nrho = 1;
            
        case 'isotropic_ip'    
            sRes = '激电线性参数：ρ η τ C，例如：10,0.1,0.1,0.1';
            sBnd = '参数上下界，例如：0.1 100.0';
            sPrj = '先验值 权重，例如：10.0  1';
            nrho = 4; 
 
        case 'isotropic_complex'    
            sRes = '复电阻率：实部 虚部 (Ω·m)，例如：10.0 0.1';
            sBnd = '参数上下界（共2组）：';
            sPrj = '先验值 权重（共2组）：';
            nrho = 2;          
           
        case 'triaxial'
            sRes = '三轴电阻率：ρx ρy ρz (Ω·m)，例如：1.0 10.0 1.0';
            sBnd = '参数上下界（共3组）：';
            sPrj = '先验值 权重（共3组）：';
            nrho = 3;           
        case 'tix'
            sRes = '横向各向同性(x轴)：ρx ρyz (Ω·m)，例如：1.0 10.0';
            sBnd = '参数上下界（共2组）：';
            sPrj = '先验值 权重（共2组）：';
            nrho = 2;
        case 'tiy'
            sRes = '横向各向同性(y轴)：ρy ρxz (Ω·m)，例如：1.0 10.0';
            sBnd = '参数上下界（共2组）：';
            sPrj = '先验值 权重（共2组）：';
            nrho = 2;
        case 'tiz'
            sRes = '横向各向同性(z轴)：ρz ρh (Ω·m)，例如：1.0 10.0';
            sBnd = '参数上下界（共2组）：';
            sPrj = '先验值 权重（共2组）：';
            nrho = 2;
        case 'tiz_ratio'
            sRes = '纵向电阻率 ρz (Ω·m)、纵横比 ρz/h，例如：5.0 1.5';
            sBnd = '参数上下界（共2组）：';
            sPrj = '先验值 权重（共2组）：';
            nrho = 2;           
    end
    
    % 自动补全参数矩阵，避免索引越界
    maxRegNum = max(iregion);
    currentRow = size(handles.model.resistivity, 1);
    if maxRegNum > currentRow
        addRow = maxRegNum - currentRow;
        handles.model.resistivity(currentRow+1:currentRow+addRow, 1:nrho) = 100;
        handles.model.freeparameter(currentRow+1:currentRow+addRow, 1:nrho) = 0;
        handles.model.bounds(currentRow+1:currentRow+addRow, 1:2*nrho) = repmat([0.1 10000], addRow, 1);
        handles.model.prejudice(currentRow+1:currentRow+addRow, 1:2*nrho) = repmat([100 1], addRow, 1);
        guidata(hObject, handles);
    end
    
    lAskAgain = true;
    
    while lAskAgain
        
        rhos = handles.model.resistivity(iregion(1),:);
        bnds = handles.model.bounds(iregion(1),:);
        prj  = handles.model.prejudice(iregion(1),:);
        free = handles.model.freeparameter(iregion(1),:);
        
        sFre = '是否为自由反演参数？1=是，0=否';
        
        options.Resize='on';
        
        str = {sRes sFre sBnd sPrj};
        
        defaultanswer ={sprintf('%g ',rhos) sprintf('%i ',free)  sprintf('%g ',bnds)  sprintf('%g ',prj)    };
        
        answer = inputdlg(str,'电阻率参数设置',1,defaultanswer,options);
        
        if isempty(answer)
            lAskAgain = false;
            delete(findobj(handles.hFigure,'tag','tempNode'));
            delete(findobj(handles.hFigure,'tag','tempregion'));
            delete(findobj(handles.hFigure,'tag','tempSegs'));
            continue
        end

        rhos = str2num(answer{1});
        free = str2num(answer{2});
        bnds = str2num(answer{3});
        prej = str2num(answer{4});

        % 输入校验（中文提示）
        if length(rhos) ~= nrho
            str = sprintf('输入的电阻率参数有 %d 个，当前各向异性设置需要 %d 个参数',length(rhos),nrho);
            h = errordlg(str,'参数错误','modal');
            waitfor(h);
            continue;
        elseif length(free) ~= nrho
            beep;
            str = sprintf('输入的自由参数标记有 %d 个，当前设置需要 %d 个',length(free),nrho);
            h = errordlg(str,'参数错误','modal');
            waitfor(h);
            continue;
        elseif length(bnds) ~= 2*nrho
            beep;
            str = sprintf('输入的上下界有 %d 个数值，当前设置需要 %d 个（2组/参数）',length(bnds),2*nrho);
            h = errordlg(str,'参数错误','modal');   
            waitfor(h);
            continue;
        elseif length(prej) ~= 2*nrho
            beep;
            str = sprintf('输入的先验权重有 %d 个数值，当前设置需要 %d 个（2组/参数）',length(prej),2*nrho);
            h = errordlg(str,'参数错误','modal');            
            waitfor(h);
            continue;          
        end

        if any(rhos < 0)
            beep;
            h = errordlg('电阻率不能为负值，请重新输入！','参数错误','modal');
            waitfor(h);
            continue;
        end
 
        lower = bnds(1:2:end);
        upper = bnds(2:2:end);
        if any(lower > upper)
            beep;
            h = errordlg('下界必须小于上界，请重新输入！','参数错误','modal');
            waitfor(h);
            continue;
        end
        if ~all(ismember(free,[0 1]))
            beep;
            h = errordlg('自由参数标记只能填 0 或 1','参数错误','modal');
            waitfor(h);
            continue;
        end
        if  any(prej(2:2:end)< 0)
            beep;
            h = errordlg('权重不能为负值，请重新输入！','参数错误','modal');
            waitfor(h);
            continue;
        end
        
        lowerBoundGlobal    = str2double(get(findobj(handles.hFigure,'tag','lowerbound'),'string'));
        upperBoundGlobal    = str2double(get(findobj(handles.hFigure,'tag','upperbound'),'string'));
              
        switch aniso            
            case {'isotropic_ip', 'isotropic_complex'}
                    rhos_test = rhos(1);
                    free_test = free(1);
            otherwise 
                    rhos_test = rhos;
                    free_test = free;
        end
 
            
        if any(rhos_test < lowerBoundGlobal) && any(free_test > 0)
            beep;
            h = errordlg('电阻率小于全局下界设置，请重新输入！','参数错误','modal');
            waitfor(h);
            continue;
        end   
        if  any(rhos_test > upperBoundGlobal) && any(free_test > 0)
            beep;
            h = errordlg('电阻率大于全局上界设置，请重新输入！','参数错误','modal');
            waitfor(h);
            continue;
        end   
        
        for i = 1:nrho
            if free_test(i) > 0 && lower(i)>0 && upper(i)>0 && rhos(i) < lower(i)
                beep;
                h = errordlg('电阻率小于本区域设置的下界，请重新输入！','参数错误','modal');
                waitfor(h);
                continue;
            end   
            if free_test(i) > 0 && upper(i)>0 && rhos(i) > upper(i)
                beep;
                h = errordlg('电阻率大于本区域设置的上界，请重新输入！','参数错误','modal');
                waitfor(h);
                continue;
            end     
        end

        lAskAgain = false;
        
        rhos = repmat(rhos,length(iregion),1);
        free = repmat(free,length(iregion),1);
        bnds = repmat(bnds,length(iregion),1);
        prej = repmat(prej,length(iregion),1);

        % 写入参数
        handles.model.resistivity(iregion,1:nrho)        = rhos;
        handles.model.freeparameter(iregion,1:nrho)      = free;
        handles.model.bounds(iregion,1:2*nrho)           = bnds;
        handles.model.prejudice(iregion,1:2*nrho)        = prej;

        handles.bChanged = true;
        
        guidata(hObject,handles);
        sub_plotModel(handles.hFigure);  
        drawnow;
        handles = guidata(hObject);
   
    end
 
end

title(' ' )
set(handles.hFigure,'pointer','arrow')
 
end
%----------------------------------------------------------------------
function  varargout = sub_highlightRegions(handles,iregion)
%
% Usage:
% sub_highlightRegions(handles,iregion);
% or
% [lHasInteriorRegion, ordered] =  sub_highlightRegions(handles,iregion);
% where ordered is a list of nodes of the segments bounding region.
%

    % 清理上一次的临时高亮图层，避免堆积
    delete(findobj(handles.hModelAxes, 'tag', 'tempregion'));
    delete(findobj(handles.hModelAxes, 'tag', 'tempBoundary'));
    
    % 空值校验：无匹配区域直接返回，不崩溃
    if ~any(ismember(handles.model.TriIndex, iregion))
        lHasInteriorRegion = false;
        ordered = [];
        if nargout == 2
            varargout{1} = lHasInteriorRegion;
            varargout{2} = ordered;
        end
        return;
    end

    lreg   = ismember(handles.model.TriIndex,iregion);      
    iouter = handles.model.DT.ConnectivityList(~lreg,:);
    
    x = handles.model.nodes(:,1);
    y = handles.model.nodes(:,2);
    handles.hTempRegion = patch(handles.hModelAxes, x(iouter)',y(iouter)','k', ...
    'marker', 'none', 'LineStyle', '-', ...
    'edgecolor','none','tag','tempregion', 'FaceAlpha',.5);
    
    warning('off','MATLAB:triangulation:PtsNotInTriWarnId');
    TR = triangulation(handles.model.DT.ConnectivityList(lreg,:),handles.model.DT.Points);    
    warning('on','MATLAB:triangulation:PtsNotInTriWarnId');
    
    TRFreeBoundary = freeBoundary(TR);

    lHasInteriorRegion = false;
 
    % ====================== 核心修复：直接绘制边界，替代sub_highlightSegment ======================
    if ~isempty(TRFreeBoundary)
        % 提取所有边界边的端点坐标
        p1 = TRFreeBoundary(:,1);
        p2 = TRFreeBoundary(:,2);
        x1 = handles.model.nodes(p1, 1);
        y1 = handles.model.nodes(p1, 2);
        x2 = handles.model.nodes(p2, 1);
        y2 = handles.model.nodes(p2, 2);
        % 批量绘制红色高亮边界线，和原版高亮效果一致
        line([x1, x2]', [y1, y2]', ...
            'Color', 'r', 'LineWidth', 2, ...
            'tag', 'tempBoundary', 'Parent', handles.hModelAxes);
    end
    % ======================================================================================
    
    if nargout == 2
        
        % Get boundary segments:
        boundarySegs = TRFreeBoundary;
        
        % Remove dangles?
        
        ordered = zeros(size(boundarySegs,1)+1,1);
        ordered(1:2) = boundarySegs(1,:);
        boundarySegs(1,:) = 0;
        icnt = 2;
        eps_idx = [2 1]; % 避免与内置函数eps重名
        for i = 1:size(boundarySegs,1)-1
          
            [irow,icol] = find(boundarySegs == ordered(icnt));
             
            if isempty(irow)
                lHasInteriorRegion = true;
                break;
            end
            icnt = icnt + 1;
           
            ordered(icnt) = boundarySegs(irow,eps_idx(icol));
            boundarySegs(irow,:) = 0;
        end
        
        if ~lHasInteriorRegion
            
            % Sort them to be in order:
            x = handles.model.nodes(ordered(1:end),1);
            y = handles.model.nodes(ordered(1:end),2);

            % Use the Shoelace formula to tell if its clockwise or
            % counterclockwise. This works for non-convex polygons, so it is
            % robust:

            % shoelace formula for area of polygon. If negative, its clockwise:
            area = sum(x(1:end-1).*y(2:end) - x(2:end).*y(1:end-1))/2;


            if area < 0
                ordered = flipud(ordered);
            end
        end
        
        % output:
        varargout{1} = lHasInteriorRegion;
        varargout{2} = ordered;
        
    end
    

end

%--------------------------------------------------------------------------
function [ geom, iner, cpmo ] = sub_polygeom( x, y ) 
%POLYGEOM Geometry of a planar polygon
%
%   POLYGEOM( X, Y ) returns area, X centroid,
%   Y centroid and perimeter for the planar polygon
%   specified by vertices in vectors X and Y.
%
%   [ GEOM, INER, CPMO ] = POLYGEOM( X, Y ) returns
%   area, centroid, perimeter and area moments of 
%   inertia for the polygon.
%   GEOM = [ area   X_cen  Y_cen  perimeter ]
%   INER = [ Ixx    Iyy    Ixy    Iuu    Ivv    Iuv ]
%     u,v are centroidal axes parallel to x,y axes.
%   CPMO = [ I1     ang1   I2     ang2   J ]
%     I1,I2 are centroidal principal moments about axes
%         at angles ang1,ang2.
%     ang1 and ang2 are in radians.
%     J is centroidal polar moment.  J = I1 + I2 = Iuu + Ivv

% H.J. Sommer III - 02.05.14 - tested under MATLAB v5.2
%
% sample data
% x = [ 2.000  0.500  4.830  6.330 ]';
% y = [ 4.000  6.598  9.098  6.500 ]';
% 3x5 test rectangle with long axis at 30 degrees
% area=15, x_cen=3.415, y_cen=6.549, perimeter=16
% Ixx=659.561, Iyy=201.173, Ixy=344.117
% Iuu=16.249, Ivv=26.247, Iuv=8.660
% I1=11.249, ang1=30deg, I2=31.247, ang2=120deg, J=42.496
%
% H.J. Sommer III, Ph.D., Professor of Mechanical Engineering, 337 Leonhard Bldg
% The Pennsylvania State University, University Park, PA  16802
% (814)863-8997  FAX (814)865-9693  hjs1@psu.edu  www.me.psu.edu/sommer/

% begin function POLYGEOM

% check if inputs are same size
if ~isequal( size(x), size(y) )
  error( 'X and Y must be the same size');
end

% number of vertices
[ x, ~ ] = shiftdim( x );
[ y, ~ ] = shiftdim( y );
[ n, ~ ] = size( x );

% temporarily shift data to mean of vertices for improved accuracy
xm = mean(x);
ym = mean(y);
x = x - xm*ones(n,1);
y = y - ym*ones(n,1);

% delta x and delta y
dx = x( [ 2:n 1 ] ) - x;
dy = y( [ 2:n 1 ] ) - y;

% summations for CW boundary integrals
A = sum( y.*dx - x.*dy )/2;
Axc = sum( 6*x.*y.*dx -3*x.*x.*dy +3*y.*dx.*dx +dx.*dx.*dy )/12;
Ayc = sum( 3*y.*y.*dx -6*x.*y.*dy -3*x.*dy.*dy -dx.*dy.*dy )/12;
Ixx = sum( 2*y.*y.*y.*dx -6*x.*y.*y.*dy -6*x.*y.*dy.*dy ...
          -2*x.*dy.*dy.*dy -2*y.*dx.*dy.*dy -dx.*dy.*dy.*dy )/12;
Iyy = sum( 6*x.*x.*y.*dx -2*x.*x.*x.*dy +6*x.*y.*dx.*dx ...
          +2*y.*dx.*dx.*dx +2*x.*dx.*dx.*dy +dx.*dx.*dx.*dy )/12;
Ixy = sum( 6*x.*y.*y.*dx -6*x.*x.*y.*dy +3*y.*y.*dx.*dx ...
          -3*x.*x.*dy.*dy +2*y.*dx.*dx.*dy -2*x.*dx.*dy.*dy )/24;
P = sum( sqrt( dx.*dx +dy.*dy ) );

% check for CCW versus CW boundary
if A < 0
  A = -A;
  Axc = -Axc;
  Ayc = -Ayc;
  Ixx = -Ixx;
  Iyy = -Iyy;
  Ixy = -Ixy;
end

% centroidal moments
xc = Axc / A;
yc = Ayc / A;
Iuu = Ixx - A*yc*yc;
Ivv = Iyy - A*xc*xc;
Iuv = Ixy - A*xc*yc;
J = Iuu + Ivv;

% replace mean of vertices
x_cen = xc + xm;
y_cen = yc + ym;
Ixx = Iuu + A*y_cen*y_cen;
Iyy = Ivv + A*x_cen*x_cen;
Ixy = Iuv + A*x_cen*y_cen;

% principal moments and orientation
I = [ Iuu  -Iuv ;
     -Iuv   Ivv ];
[ eig_vec, eig_val ] = eig(I);
I1 = eig_val(1,1);
I2 = eig_val(2,2);
ang1 = atan2( eig_vec(2,1), eig_vec(1,1) );
ang2 = atan2( eig_vec(2,2), eig_vec(1,2) );

% return values
geom = [ A  x_cen  y_cen  P ];
iner = [ Ixx  Iyy  Ixy  Iuu  Ivv  Iuv ];
cpmo = [ I1  ang1  I2  ang2  J ];

% end of function POLYGEOM

end
%----------------------------------------------------------------------
function deleteSegment_Callback(hObject)

handles     = guidata(hObject);
stSettings  = getappdata(handles.hFigure,'stSettings');

set(handles.hFigure,'pointer','cross')

% Select a node with the mouse  (repeats):
but = 1;

nDeleted = 0;
lUpdated = false;

while but==1

    % Select a segment:
    [x0, y0, but] = sub_getPoints(1,handles.hFigure,handles.hModelAxes); % subfunction  getpoints(N,handles) returns N points
    if but~=1
        break
    end
    ax = axis(handles.hModelAxes);
    if x0 < ax(1) || x0 > ax(2) || y0 < ax(3) || y0 > ax(4)
        break
    end
    
    % Find nearest segment:
    [inodes,dist,~,~] = sub_nearestSegment(handles.model.nodes,handles.model.segments,x0,y0,handles.axesPosPixels,axis(handles.hModelAxes));

    if dist <= stSettings.dr
         
        handles.model.segments(inodes(1),inodes(2)) = 0;
        handles.model.segments(inodes(2),inodes(1)) = 0;
    
        nDeleted = nDeleted + 1;
 
        %
        % Update model if is small, else just update plot segments and do
        % the whole kebab later:
        %
        if size(handles.model.nodes,1) < stSettings.nNodesPltSmall            
            sub_updateModelPlot(handles);  % saves h to guidata so no need to do that here again
            lUpdated = true;
            handles = guidata(hObject); %kwk debug, have sub_update return handles...
        else
            handles = sub_plotSegsAndNodes(handles);
            lUpdated = false;
        end
           
      
    end
end

if nDeleted > 0 && ~lUpdated
    % Update the model and plot it:
    sub_updateModelPlot(handles);  % saves h to guidata so no need to do that here again
    % NB: The temporary new nodes and regions are deleted by sub_updateModelPlot     
end
    
set(handles.hFigure,'pointer','arrow')

 
end

%--------------------------------------------------------------------------
function  handles = sub_plotSegsAndNodes(handles)
 

stSettings  = getappdata(handles.hFigure,'stSettings');

if ~isempty(handles.hSegmentsCut)
    delete(handles.hSegmentsCut) 
end
if ~isempty(handles.hSegments)
    delete(handles.hSegments) 
end
if ~isempty(handles.hNodes)
    delete(handles.hNodes) 
end    
set(0, 'CurrentFigure', handles.hFigure)

delete(findobj(handles.hFigure,'tag','tempNode'));
delete(findobj(handles.hFigure,'tag','tempSegs'));

nodes = handles.model.nodes(:,1:2);
segs  = sub_getSegments(handles.model.segments);  

if ~isempty(segs)

    v1 = segs(:,1);
    v2 = segs(:,2);
    
    iFullPenalty = segs(:,3) == 1;
    

    x = [nodes(v1(iFullPenalty),1) nodes(v2(iFullPenalty),1) nan(length(v1(iFullPenalty)),1)]';
    y = [nodes(v1(iFullPenalty),2) nodes(v2(iFullPenalty),2) nan(length(v1(iFullPenalty)),1)]';

    handles.hSegments = plot(x(:),y(:),'linewidth',stSettings.segThickness,'tag','segment', ...
    'marker', 'none', 'linestyle', '-','color',stSettings.segColor);
    
    set(handles.hSegments,'visible',stSettings.showSegments');
    
    x = [nodes(v1(~iFullPenalty),1) nodes(v2(~iFullPenalty),1) nan(length(v1(~iFullPenalty)),1)]';
    y = [nodes(v1(~iFullPenalty),2) nodes(v2(~iFullPenalty),2) nan(length(v1(~iFullPenalty)),1)]';
  
    handles.hSegmentsCut = plot(x(:),y(:),'linewidth',stSettings.segThickness,'tag','segment', ...
    'marker', 'none', 'linestyle', '-','color',stSettings.segColorCut);
    
    set(handles.hSegmentsCut,'visible',stSettings.showSegments');    
 

end

%
% Plot nodes:
%
handles.hNodes  = line(nodes(:,1),nodes(:,2),'marker','o','markersize',stSettings.nodeSize,...  
                'markerfacecolor',stSettings.nodeColor,'color',stSettings.nodeColor, ...
                'linestyle','none','tag','node','visible',stSettings.showNodes);
                    
 end
%----------------------------------------------------------------------
function importGeoImage_Callback(hObject)
% KWK debug: needs to be tested still

handles = guidata(hObject);

% Delete previous geoimage if it exists:
hgeoimage = findobj(handles.hModelAxes,'tag','geoimage');
if ~isempty(hgeoimage)
    delete(hgeoimage)
end

% Ask for geoimage graphics file:
[file, path ] = uigetfile( '*.jpg;*.png;*.tiff;','Select geoimage figure file (.jpg, .png, or .tiff files)');
if file==0
    return
end
[~, ~, ~] = fileparts(file);

file = fullfile(path,file);

 % Read in image file:
[A]=imread(file);
% See if there is a .geocoord file for the image:
[pathstr,name, ~] = fileparts(file);
gfile = fullfile(pathstr,strcat(name,'.geocoord'));
try
    gc = load(gfile);
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

% DGM 5/1/2015 - if E,N are given for left & right, then these are UTM
% and need to be translated into local coords. Use the given datafile
% for that...
if numel(x0) == 2 && numel(x1) == 2
    UTM = struct( 'north0', 0, 'east0', 0, 'theta', 0 );
    sDataFile = get( findobj( handles.hFigure, 'tag', 'datafile' ), 'String' );
    if exist( sDataFile, 'file' )
        %[UTM] = m2d_readEMData2DFile( sDataFile, 'Silent' );
        stD = m2d_readEMData2DFile(sDataFile, 'Silent' );
        UTM = stD.stUTM;
 
        dn = ([x0(2) x1(2)] - UTM.north0);
        de = ([x0(1) x1(1)] - UTM.east0 );
        c = cosd(UTM.theta);
        s = sind(UTM.theta);
        R = [c s; -s c];
        rotated = R*[dn; de];
        y = sort(rotated(2,:));
        x0 = y(1);
        x1 = y(2);
    end
end


% Plot up geoimage:
handles.hgeo = image([x0 x1],[y0 y1],A);
set(handles.hgeo,'tag','geoimage');

handles = sub_updateLayers(handles);

% This sets the alpha mapping to be 0 (clear) to 1 (opaque)
set(handles.hgeo,'alphadatamapping','none')

% Update Guidata
guidata(hObject,handles);

 
end
%----------------------------------------------------------------------
function deleteGeoImage_Callback(hObject)

handles = guidata(hObject);

% Delete  geoimage if it exists:
delete(findobj(handles.hFigure,'tag','geoimage'))
delete(findobj(handles.hFigure,'tag','segy'))

if ~isempty(handles.SEGY.hSliderFig)
    delete(handles.SEGY.hSliderFig) 
    handles.SEGY = [];
end


end


%--------------------------------------------------------------------------
function importSEGY_Callback(hObject)

handles = guidata(hObject);

% Check to see if we have a sliderfig already:
if isfield(handles,'SEGY') && ~isempty(handles.SEGY.hSliderFig) && isgraphics((handles.SEGY.hSliderFig))
    
    % Bring the slider menu to the front:
    uistack(handles.SEGY.hSliderFig);

elseif ~isempty(findobj(handles.hFigure,'tag','segy')) % SEGY data already plotted, bring up adjustment menu again
    % make slider menu figure:
    sub_segyMenu(handles.hFigure);
   
    
else
    % Ask for the SEGY file:
    [ff, pp] = uigetfile('*.segy;*.sgy', 'Select  a Depth Migrated SEGY File (.segy,.sgy):');

    if ff <= 0
        return
    end
    sFile  = fullfile(pp,ff);

    set( handles.hFigure, 'Pointer', 'watch' ); drawnow;

    % read in Segy file:
    handles.SEGY.sFile = sFile;
    [handles.SEGY.Data,handles.SEGY.SegyTraceHeaders,handles.SEGY.SegyHeader]=ReadSegy(sFile);

    % Update Guidata
    guidata(hObject,handles);

    set(handles.hFigure, 'Pointer', 'arrow' );
    
    % make slider menu figure:
    sub_segyMenu(handles.hFigure);
    
    
end
    

end
%--------------------------------------------------------------------------
function sub_segyMenu(hFig)

% Create UI figure with three sliders (contrast, brightness, transparency):
fWidth = 400;
fHeight= 350;

hSliderFig =  m2d_newFigure([fWidth fHeight],'menubar','none',...
                              'name','SEGY Settings','tag','sliderFig',...
                              'visible','off','NumberTitle','off');

dx = 40;
hOffset = 20;
vOffset = 60;
v0 = 50;

st = guidata(hFig);
 
st.SEGY.hSliderFig = hSliderFig;


% Set defaults if first call:
if ~isfield(st,'SEGY') || ~isfield(st.SEGY,'zScale') 
    st.SEGY.zScale = 1;
    st.SEGY.xyScale = 1 ;
    st.SEGY.transpExp = 1;
    st.SEGY.bright = 0.5;
    st.SEGY.contrast = 0.5;
   
end

 % store data in fig:
guidata(hFig,st); 

bgndColor = get(hSliderFig,'color');
 
hContrast = uicontrol(hSliderFig,'Style','slider','Min',0,'Max',1,...
                'Value',st.SEGY.contrast, 'Position',[hOffset v0+20  fWidth-40 20 ],'tag','contrast');
hContrastLabel = uicontrol(hSliderFig,'Style','text','string','Constrast', ...
                           'Position',[hOffset v0+20+vOffset/2  fWidth-40 20 ],'backgroundcolor',bgndColor);    
                           
hBright   = uicontrol(hSliderFig,'Style','slider','Min',0,'Max',1,...
                'Value',st.SEGY.bright, 'Position',[hOffset v0+20+vOffset fWidth-40 20 ],'tag','bright');
hBrightLabel = uicontrol(hSliderFig,'Style','text','string','Brightness', ...
                           'Position',[hOffset v0+20+1.5*vOffset  fWidth-40 20 ],'backgroundcolor',bgndColor);  
                       
hTrans   = uicontrol(hSliderFig,'Style','slider','Min',0,'Max',1,...
                'Value',st.SEGY.transpExp, 'Position',[hOffset v0+20+2*vOffset fWidth-40 20],'tag','trans');
hTransLabel = uicontrol(hSliderFig,'Style','text','string','Transparency', ...
                           'Position',[hOffset v0+20+2.5*vOffset  fWidth-40 20 ],'backgroundcolor',bgndColor);              

hApply = uicontrol(hSliderFig,'Style','pushbutton','string','Apply','fontsize',14, ...
                           'Position',[fWidth/2-80/2 20 60 30 ],'backgroundcolor',bgndColor,...
                           'callback',  {@sub_rescaleSEGY, hFig, hSliderFig}); 

hVScaleLabel  = uicontrol(hSliderFig,'Style','text','string','Vert. Scaling (ft to m = .3048)', ...
                           'Position',[hOffset v0+20+3.5*vOffset  140 20 ],'backgroundcolor',bgndColor);  
hVScale        = uicontrol(hSliderFig,'Style','edit','string',num2str(st.SEGY.zScale), ...
                           'Position',[hOffset v0+20+3.2*vOffset  140 20 ],'backgroundcolor',[1 1 1],'tag','vscale'); 
                       
hHScaleLabel  = uicontrol(hSliderFig,'Style','text','string','Horz. Scaling (ft to m = .3048)', ...
                           'Position',[hOffset+fWidth/2 v0+20+3.5*vOffset  140 20 ],'backgroundcolor',bgndColor);     
                       
hHScale        = uicontrol(hSliderFig,'Style','edit','string',num2str(st.SEGY.xyScale), ...
                           'Position',[hOffset+fWidth/2 v0+20+3.2*vOffset  140 20 ],'backgroundcolor',[1 1 1],'tag','hscale');

                       
set(hSliderFig,'visible','on');
end
    
%--------------------------------------------------------------------------
function sub_rescaleSEGY(~,~,hFig,hSliderFig)

set(hFig, 'Pointer', 'watch' );
drawnow; 

st = guidata(hFig);

if ~isfield(st,'SEGY') || ~isfield(st.SEGY,'sFile') || isempty(st.SEGY.sFile)
    set(hFig, 'Pointer', 'arrow' );
    return
end

if isempty(hSliderFig) || ~ishandle(hSliderFig)
    set(hFig, 'Pointer', 'arrow' );
    sub_segyMenu(hFig);
    return;
end

                         
% Get the settings from the menu figure:
st.SEGY.zScale     = str2double(get(findobj(hSliderFig,'tag','vscale'),'string'));
st.SEGY.xyScale    = str2double(get(findobj(hSliderFig,'tag','hscale'),'string'));
st.SEGY.transpExp  = (get(findobj(hSliderFig,'tag','trans'),'val'));
st.SEGY.bright     = (get(findobj(hSliderFig,'tag','bright'),'val'));
st.SEGY.contrast   = (get(findobj(hSliderFig,'tag','contrast'),'val'));

% Delete any previous segy plot:
delete(findobj(hFig,'tag','segy'));

% Get SEGY data:
Data = st.SEGY.Data;

% create RGB indexes for grayscale:
% data is scaled to be between 0 and 1:

mind = min(min(Data));
maxd = max(max(Data));
Data(Data<mind) = mind;
Data(Data>maxd) = maxd;
%
col = (Data -  mind)./ (maxd-mind);


%apply gain:
%

a = st.SEGY.bright*.2+.30;
col = col ./ ( (1/a-2).*(1-col) + 1 );

a = (1-st.SEGY.contrast)*.5;
colNew = col;
iCol = col<0.5; 
colNew(iCol)  = col(iCol) ./ ( (1/a-2).*(1-2*col(iCol)) + 1 );
colNew(~iCol) =  ( (1/a-2).*(1-2*col(~iCol)) - col(~iCol) ) ./ ( (1/a-2).*(1-2*col(~iCol)) - 1 );
 
col = colNew;

col(col>1) = 1;
col(col<0) = 0;

col(:,:,2)= col;
col(:,:,3)= col(:,:,2); 

%
% Get UTM position from data file or user entry:
% DGM 12/11/2013 - if a data file is already specified, read the UTM info out of
% it (if any) and use it for the default answer when asking the user.
if ~isfield(st,'UTM')    
    
    sDataFile = get( findobj( st.hFigure, 'tag', 'datafile' ), 'String' );
    
    if exist( sDataFile, 'file' )
        [st.UTM] = m2d_readEMData2DFile( sDataFile, 'Silent' );
        stD = m2d_readEMData2DFile(sDataFile, 'Silent' );
        st.UTM = stD.stUTM;
    else
        st.UTM = struct( 'north0', 0, 'east0', 0, 'theta', 0 );
        prompt={sprintf('Enter 2D Model Origin\n UTM North, East and 2D strike x:')};
        name='SEG Y Import';
        numlines=1;
        defaultanswer = { [num2str(st.UTM.north0) ' ' num2str(st.UTM.east0) ' ' num2str(st.UTM.theta)] };
        answer=inputdlg(prompt,name,numlines,defaultanswer);
        if isempty(answer)
            return;
        end
        temp = sscanf(answer{1},'%g');
        st.UTM.north0 = temp(1);
        st.UTM.east0  = temp(2);
        st.UTM.theta  = temp(3);
    end
end

% Project this onto the model axes:
% cdpX = east, cpdY = north
dn = ([st.SEGY.SegyTraceHeaders.cdpY]/st.SEGY.xyScale  - st.UTM.north0); %/1d3; %KWK debug using m instead of km...
de = ([st.SEGY.SegyTraceHeaders.cdpX]/st.SEGY.xyScale  - st.UTM.east0 ); %/1d3;
c = cosd(st.UTM.theta);
s = sind(st.UTM.theta);
R = [c s; -s c];
rotated = R*[dn; de];
x = rotated(1,:);
y = rotated(2,:);

z = [st.SEGY.SegyHeader.time]*st.SEGY.zScale*1000; % KWK debug convert from km to m


% add it to the MARE2DEM plot:

%Make the figure h current, but do not change its visibility or stacking with respect to other figures:
set(groot,'CurrentFigure',hFig);
 
hss = imagesc(y,z,col);
 
% make it transparent:
set(hss,'AlphaData',(1-col(:,:,1)).^(st.SEGY.transpExp*2))
 

set(hss,'tag','segy');

st = sub_updateLayers(st);
    
% store data in fig:
guidata(hFig,st);

set(hFig, 'Pointer', 'arrow' );

end


%----------------------------------------------------------------------
function transparencyslide_Callback(hObject, ~, handles)

hgeoimage = findobj(handles.hFigure,'tag','geoimage');
if ~isempty(hgeoimage)
    alph = get(hObject,'Value');
    alpha(hgeoimage,alph);
end

end


%--------------------------------------------------------------------------
function sub_setColorMap(hObject,~,hFig,sColorMap)

stSettings  = getappdata(hFig,'stSettings');

if strcmpi(sColorMap,'invert')
    if stSettings.sColorMapInverted 
        stSettings.sColorMapInverted  = false;
    else
        stSettings.sColorMapInverted = true;
    end 
else
    stSettings.sColorMapInverted = false;    % don't invert when changing colormap
    stSettings.sColorMap         = sColorMap;     
end
 
sub_applyColorMap(hFig,stSettings.sColorMap,stSettings.sColorMapInverted) 

setappdata(hFig,'stSettings',stSettings);
 
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

%----------------------------------------------------------------------
function setAnisotropy_Callback(~, ~, handles)

% 修复：检查并获取有效的主窗口句柄
if ~isfield(handles, 'hFigure') || ~ishandle(handles.hFigure)
    handles.hFigure = ancestor(hObject, 'figure');
    guidata(handles.hFigure, handles); % 更新handles结构体
end

set(handles.hFigure,'pointer','cross')

if isempty(handles.model.boundingBox)
    beep;
    h = warndlg('添加任何元素前，请先指定模型边界框！','');
    set(h,'windowstyle','modal')
    waitfor(h);
    set(findobj(handles.hFigure,'tag','setAnisotropy'),'val',1);
    return;
end

sPrev = handles.model.anisotropy;
sNew  = handles.setAnisotropy.String{handles.setAnisotropy.Value};
if strcmpi(sPrev,sNew)
    return % no change
end

% If anisotropy has been previously specified, then check with the user to
% make sure they are okay with changing it:
if size(handles.model.resistivity,1)>1 || size(handles.model.resistivity,2)>1
    sBtn = questdlg( 'You are changing an existing anisotropy setting, are you sure?', 'Mamba2D' ...
        , 'Yes', 'Cancel', 'Cancel' );
    if strcmpi( sBtn, 'cancel' )
        
        % return to previous menu setting:
        c = handles.setAnisotropy.String;
        handles.setAnisotropy.Value = find(strcmp(sPrev,c));
       
        return;
    end
end

% Adjusts all the parameter arrays to the new anisotropy setting:
handles = sub_setAnisotropy(handles);

% Plot model:
sub_updateModelPlot(handles);  % saves h to guidata so no need to do that here again

set(handles.hFigure,'pointer','arrow')

end
%----------------------------------------------------------------------
function handles = sub_setAnisotropy(handles)

anisotropy_old = handles.model.anisotropy;

% Get the new setting:
handles.model.anisotropy = handles.setAnisotropy.String{handles.setAnisotropy.Value};
switch handles.model.anisotropy
    case 'isotropic'
        nrho = 1;
    case 'isotropic_ip'    
        nrho = 4; 
    case 'isotropic_complex'    
        nrho = 2;
    case 'triaxial'
        nrho = 3;
    case {'tix', 'tiy', 'tiz','tiz_ratio'}
        nrho = 2;
end

sub_setAnisotropyComponentsMenu(handles);
  
% Get existing parameters, and their nrho:
if ~isempty(handles.model.resistivity)
    nOld = length(handles.model.resistivity(1,:));
else
    nOld = 0;
end

erhos = handles.model.resistivity;
ebnds = handles.model.bounds;
eprj  = handles.model.prejudice;
efree = handles.model.freeparameter;


nregs = size(handles.model.resistivity,1);

% initialize new arrays:
handles.model.resistivity   = zeros(nregs,nrho);
handles.model.bounds        = zeros(nregs,2*nrho);
handles.model.prejudice     = zeros(nregs,2*nrho);
handles.model.freeparameter = zeros(nregs,nrho);

% Copy over any "safe" existing values for rho and free parameter settings:
if nOld > 0
 
    switch handles.model.anisotropy

        case 'isotropic_ip'    
           
            handles.model.resistivity(:,1)   = erhos(:,1);          % Real component
            handles.model.resistivity(:,2:4) = 0;                   % Cole-Cole parameters
            handles.model.freeparameter      = efree(:,[1 1 1 1]);  % all free or fixed according to previous model's settings
            handles.model.bounds(:,1:2)      = ebnds(:,1:2);
            handles.model.prejudice(:,[1 2]) = eprj(:,[1 2]);       % real prejudice gets copied from existing x or rho_0 component
            
        case 'isotropic_complex'
            
            % this is a little risky to copy over from existing, possibly
            % non-ip model. just set imaginary to small value to play it
            % safe. User can modify as desired.
            
            handles.model.resistivity(:,1)   = erhos(:,1 );
            handles.model.resistivity(:,2)   = 1d-6; % default is small imaginary conductivity. Has to be nonzero..
            handles.model.freeparameter(:,1) = efree(:,1 );
            handles.model.freeparameter(:,2) = efree(:,1 );
 
            handles.model.bounds(:,[1 2])    = ebnds(:,[1 2]);
            handles.model.prejudice(:,[1 2]) = eprj(:,[1 2]);   % real prejudice gets copied from existing x component
 
        case 'isotropic'
     
            handles.model.resistivity   = erhos(:,1 );
            handles.model.freeparameter = efree(:,1);
            handles.model.bounds        = ebnds(:,[1 2]);
            handles.model.prejudice     = eprj(:,[1 2]); 
            
        case {'tix','tiy','tiz'}
            
            handles.model.resistivity   = erhos(:,[1 1]);
            handles.model.freeparameter = efree(:,[1 1] );
            handles.model.bounds        = ebnds(:,[1 2 1 2]);
            handles.model.prejudice     = eprj(:,[1 2 1 2]);  
            
        case{'tiz_ratio'}
            
            handles.model.resistivity   = erhos(:,[1 1]);
            handles.model.bounds        = ebnds(:,[1 2 1 2]);
            handles.model.prejudice     = eprj(:,[1 2 1 2]);  
            handles.model.freeparameter = efree(:,[1 1] ); 
            
            switch anisotropy_old
                
                case{'tiz'}  %
                    handles.model.resistivity      = erhos(:,[1 2]);
                    handles.model.resistivity(:,2) = handles.model.resistivity(:,1)./ ...
                                                     handles.model.resistivity(:,2); % z/h
                    handles.model.bounds        = ebnds(:,[1 2 1 2]);
                    lowr =  ebnds(:,1)./ebnds(:,4); % lowest z / highest h
                    uppr =  ebnds(:,2)./ebnds(:,3); % highest z / lowest h
                    lgo = isfinite(uppr);
                    handles.model.bounds(lgo,3) = lowr(lgo);
                    lgo = isfinite(uppr);
                    handles.model.bounds(lgo,4) = uppr(lgo);
                    
                    handles.model.prejudice     = eprj(:,[1 2 1 2]);
                    lowr =  eprj(:,1)./eprj(:,4); % lowest z / highest h
                    uppr =  eprj(:,2)./eprj(:,3); % highest z / lowest h
                    lgo = isfinite(uppr);
                    handles.model.prejudice(lgo,3) = lowr(lgo);
                    lgo = isfinite(uppr);
                    handles.model.prejudice(lgo,4) = uppr(lgo);                    
            end
            
           
           
                       

        case {'triaxial'}
            
            handles.model.resistivity   = erhos(:,[1 1 1]);
            handles.model.freeparameter = efree(:,[1 1 1] );
            handles.model.bounds        = ebnds(:,[1 2 1 2 1 2]);
            handles.model.prejudice     = eprj(:,[1 2 1 2 1 2]); 
            
    end
    
 
end

% Finally, set safe defaults for complex or cole-cole parameters:

switch handles.model.anisotropy

    case 'isotropic_ip'    

        handles.model.bounds(:,3)     = 0;  % bound eta to between 0 to 1
        handles.model.bounds(:,4)     = 1;
        handles.model.bounds(:,5)     = 0;  % bound tau to between 0 to 20
        handles.model.bounds(:,6)     = 20;
        handles.model.bounds(:,7)     = 0;  % bound c to between 0 to 1
        handles.model.bounds(:,8)     = 1;     

        handles.model.prejudice(:,3:2:end) = 0 ;  
        handles.model.prejudice(:,4:2:end) = 0 ;

    case 'isotropic_complex'

        % By default, always prejudice imaginary to zero for stabilty.
        % User could change this later if desired.
        handles.model.prejudice(:,3) = 1d-6; 
        handles.model.prejudice(:,4) = 1; % imag prej weight = 1

end
 
% Enable or disable special IP buttons if IP model:
hObj = findobj(handles.hFigure,'tag','IP_buttons');
switch handles.model.anisotropy
    case {'isotropic_ip'  ,'isotropic_complex'}
        set(hObj,'visible','on')  
    otherwise
        set(hObj,'visible','off')    
end

% Turn on or off anisotropy roughness settings:
sub_update_anisotropy_ui(handles);

end
%--------------------------------------------------------------------------

function sub_update_anisotropy_ui(handles)
    
    switch handles.model.anisotropy
    
    case {'tix','tiy','tiz','tiz_ratio','triaxial'}
        set(findobj(handles.hFigure,'tag','str_anisotropyRatioRoughnessWeight') ,'enable','on');  
        set(findobj(handles.hFigure,'tag','anisotropyRatioRoughnessWeight') ,'enable','on');
        set(findobj(handles.hFigure,'tag','str_anisotropyPenaltyWeight') ,'enable','on');  
        set(findobj(handles.hFigure,'tag','anisotropyPenaltyWeight') ,'enable','on');
        
    otherwise
        set(findobj(handles.hFigure,'tag','str_anisotropyRatioRoughnessWeight') ,'enable','off');  
        set(findobj(handles.hFigure,'tag','anisotropyRatioRoughnessWeight') ,'enable','off');
        set(findobj(handles.hFigure,'tag','str_anisotropyPenaltyWeight') ,'enable','off');  
        set(findobj(handles.hFigure,'tag','anisotropyPenaltyWeight') ,'enable','off');
end


end
%--------------------------------------------------------------------------
function sub_setAnisotropyComponentsMenu(cmps_in)
% === 修复版：设置各向异性分量菜单，确保String属性合法 ===
    persistent cmps;
    if isempty(cmps)
        % 初始化默认值
        cmps = struct();
        cmps.xx = 1;
        cmps.yy = 1;
        cmps.zz = 1;
        cmps.xy = 0;
        cmps.xz = 0;
        cmps.yz = 0;
    end
    
    % 如果有输入，就更新cmps
    if nargin > 0 && isstruct(cmps_in)
        cmps = cmps_in;
    end
    
    % 安全获取GUI数据
    try
        handles = guidata(gcbf);
    catch
        return;
    end
    
    % 安全设置菜单文本，确保永远是字符串
    try
        set(handles.xxAnisotropyText, 'String', num2str(cmps.xx));
        set(handles.yyAnisotropyText, 'String', num2str(cmps.yy));
        set(handles.zzAnisotropyText, 'String', num2str(cmps.zz));
        set(handles.xyAnisotropyText, 'String', num2str(cmps.xy));
        set(handles.xzAnisotropyText, 'String', num2str(cmps.xz));
        set(handles.yzAnisotropyText, 'String', num2str(cmps.yz));
    catch ME
        % 任何设置失败都跳过，不报错
        fprintf('跳过设置各向异性菜单：%s\n', ME.message);
    end
end
    
%----------------------------------------------------------------------
function importSegments_Callback(hObject)

handles     = guidata(hObject);
stSettings  = getappdata(handles.hFigure,'stSettings'); 

% Get the segments file:
[file, path ] = uigetfile('*','Select segment or topography text file:');
if file==0
    return
end
file = fullfile(path,file);
% Open file:
fid = fopen(file);
% Read in nodes:
nodes = fscanf(fid,'%g %g\n',[2 inf]);
nodes = nodes';
% close the file
fclose(fid);



% Remove input nodes outside the bounding box, but add nodes on bounding box where
% input segments intersect it:
nodes = sub_clipToBoundingBox(handles,nodes);

BBLeft   = handles.model.boundingBox(3);
BBRight  = handles.model.boundingBox(4);

lExtendToSides = false;

if min(nodes(:,1)) ~= BBLeft || max(nodes(:,1)) ~= BBRight
    
    choice = questdlg('Shall I extend the segment ends to the model sides?', ...
        'Import Topo:','Yes', 'No','I like cupcakes','Yes');

    switch choice
        case 'Yes'
            lExtendToSides = true;

        case 'No'
            % do nothing
            lExtendToSides = false;
        case 'I like cupcakes'
            lExtendToSides = true;
            % Brent Wheelock's gong function:
            nsound = load('gong.mat');
            player = audioplayer(nsound.y, nsound.Fs);
            play(player,[1 (get(player, 'SampleRate')* 5)]); %use for gong
            pause(5); %use for gong

    end


    if  lExtendToSides  % sort increasing to right
        [~, isort] = sort(nodes(:,1));
         nodes = nodes(isort,:);

        % add left/right endpoints:
        BBLeft   = handles.model.boundingBox(3);
        BBRight  = handles.model.boundingBox(4);
        nodes = [BBLeft nodes(1,2); nodes; BBRight nodes(end,2)];

    end

end

% Ask user about creating penalty cuts
nSegAttr = sub_penaltyCutQuestion( stSettings.segAttributeDflt );

% Add them:
lastNode = [];

minDist = 0; % i.e. don't merge the proposed nodes with any existing nodes.
             % KWK debug: this means the input segments should be sensible
             % and the current model should not have any segments etc in
             % this region. Users beware!
             
for i = 1:size(nodes,1)
    x = nodes(i,1);
    y = nodes(i,2);
    [handles, isegNodes] = sub_addNodeSeg(x,y,handles,stSettings,lastNode,nSegAttr,minDist);  
    lastNode = isegNodes(1);
end

% Update the model and plot it:
sub_updateModelPlot(handles);     

end

%--------------------------------------------------------------------------
function sub_clean_up_model(handles)
    
   % Clean up model: remove any unnecessary nodes on collinear segments
    % (i.e. the middle node in  .---.---. ). These can appear when making
    % 1D layering that extends to sides, then later deleteing the
    % segment(s) created but not the nodes, resulting in potentially
    % closely spaced nodes on the model sides and these can result in
    % unnecessary small finite elements being made in these padding
    % regions.
 
    [handles.model.nodes,...
     handles.model.segments] = m2d_simplify_poly(handles.model.nodes,handles.model.segments);

    % update model.DT regions after possible node deletions above:
    sub_updateModelPlot(handles); 
    
end
%--------------------------------------------------------------------------
function nSegAttr = sub_penaltyCutQuestion( segAttribute)
%
% returns 1 for full penalty, -1 for cut
%

% we used +-1 in the file to denote penalty vs cut, but to users its 1 and
% 0:
if segAttribute == -1
    dflt = 'Yes';
else
    dflt = 'No';
end

ButtonName = questdlg('Shall I cut the roughness penalty?', 'Segment Penalty :', 'Yes', 'No', dflt);

if strcmpi(ButtonName,'yes')
     nSegAttr = -1;
else
     nSegAttr = 1;
end

end

%--------------------------------------------------------------------------
function nodes = sub_clipToBoundingBox(handles,nodes)

% Remove nodes outside the bounding box:
BBLeft   = handles.model.boundingBox(3);
BBRight  = handles.model.boundingBox(4);
BBTop    = handles.model.boundingBox(1);
BBBottom = handles.model.boundingBox(2);

% Loop through input nodes and add new ones at the bounding box intersections:
%
% note this assumes nodes segment sequence is horizontal and not
% vertical...
%
for i = 1:length(nodes)-1
    if (nodes(i,1) < BBLeft && nodes(i+1,1) > BBLeft) || (nodes(i,1) > BBLeft && nodes(i+1,1) < BBLeft)
        Vq = interp1(nodes(i:i+1,1),nodes(i:i+1,2),BBLeft);
        nodes = [nodes(1:i,:); BBLeft Vq; nodes(i+1:end,:)];
    end
end
for i = 1:length(nodes)-1
    if (nodes(i,1) < BBRight && nodes(i+1,1) > BBRight) || (nodes(i,1) > BBRight && nodes(i+1,1) < BBRight)
        Vq = interp1(nodes(i:i+1,1),nodes(i:i+1,2),BBRight);
        nodes = [nodes(1:i,:); BBRight Vq; nodes(i+1:end,:)];
    end
end
for i = 1:length(nodes)-1
    if (nodes(i,2) < BBTop && nodes(i+1,2) > BBTop) || (nodes(i,2) > BBTop && nodes(i+1,2) < BBTop)
        Vq = interp1(nodes(i:i+1,2),nodes(i:i+1,1),BBTop);
        nodes = [nodes(1:i,:); Vq BBTop; nodes(i+1:end,:)];
    end
end
for i = 1:length(nodes)-1
    if (nodes(i,2) < BBBottom && nodes(i+1,2) > BBBottom) || (nodes(i,2) > BBBottom && nodes(i+1,2) < BBBottom)
        Vq = interp1(nodes(i:i+1,2),nodes(i:i+1,1),BBBottom);
        nodes = [nodes(1:i,:); Vq BBBottom; nodes(i+1:end,:)];
    end
end
% Finally remove the nodes that are outside the bounding box:
nodes = nodes( nodes(:,1) >= BBLeft,:);
nodes = nodes( nodes(:,1) <= BBRight,:);
nodes = nodes( nodes(:,2) >= BBTop,:);
nodes = nodes( nodes(:,2) <= BBBottom,:);

end

%--------------------------------------------------------------------------
function sub_save(~,~,hFig)
% called from File menu
    saveMamba2D_Callback(hFig);
end
%----------------------------------------------------------------------
function saveMamba2D_Callback(hObject)

try
    handles = guidata(hObject);
    
    sBaseFile = strtrim(get(findobj(handles.hFigure,'tag','filenameroot'),'string'));   
    
    str = '';
    if ~isempty(sBaseFile)
        str = sprintf('%s.fig',sBaseFile);
    end
    curdir = pwd;
    if isfield(handles.model,'path') && ~isempty(handles.model.path)
        path = handles.model.path; 
    else
        path = pwd;
        handles.model.path = path;
        guidata(hObject,handles); % resave path in fig
    end
    try
        cd(path);
    end
    [file, path ] = uiputfile('*.fig',' Save Workspace as',str);
    if file==0
        cd(curdir);
        return
    end
    cd(curdir);
    
    set( handles.hFigure, 'Pointer', 'watch' );
    
    sFile = fullfile(path,file);
 
    set(handles.hFigure,'Filename',sFile);
    
    % Update buttons:
    sub_toggleButtons(handles,'on');
   
    savefig(handles.hFigure,sFile);
    
    set(handles.hFigure, 'Pointer', 'arrow' );
    
    h = helpdlg(sprintf('Done writing Mamba2D figure file: \n %s', file),'Mamba2D Message:');
    set(h,'windowstyle','modal');
    uiwait(h)
    
    setappdata(handles.hFigure,'bChanged',false);
     
catch Me

    echo off;
    set(handles.hFigure, 'Pointer', 'arrow' );
     
    waitfor( errordlg( {
        'Error writing MARE2DEM files!'
        ' '
        Me.identifier
        Me.message
        } ) );
        
end

    
end
 
%----------------------------------------------------------------------
function writeMARE2DEM_Callback(hObject)
% Writes model to MARE2DEM .resistivity and .poly files. Also creates
% penalty file for inversion models.

handles = guidata(hObject);

set( handles.hFigure, 'Pointer', 'watch' ); drawnow;

% Delete any preexisting orphaned waitbars:
delete(findall(0,'tag','TMWWaitbar'));
  
% Check to make sure all fixed/free resistivities are non-zero:

switch handles.model.anisotropy
    case 'isotropic'
        nrho = 1;
    case 'isotropic_ip'
        nrho = 1;   % here we're just looking at rho, not additional IP params, which could be 0  
    case 'isotropic_complex'
        nrho = 2;           
    case 'triaxial'
        nrho = 3;
    case {'tix','tiy','tiz','tiz_ratio'}
        nrho = 2;
end

if any(handles.model.resistivity(:,1:nrho) <= 0)
 
    h = errordlg('Error, some resistivities are still undefined  (0, colored white). MARE2DEM files can not be written until you define them!','Mamba2D Error','modal');
    waitfor(h);
    set(handles.hFigure, 'Pointer', 'arrow' );
    return;
    
end
 
try
    
    % remove any collinear nodes:
    sub_clean_up_model(handles);
    
    
    % now get on with writting the file:
    handles = guidata(hObject);
    
    % Get structure for m2d_writeResistivity input:
    st = handles.model;
    
 
    
    % File name:
    sBaseFile = strtrim(get(findobj(handles.hFigure,'tag','filenameroot'),'string'));
    
    if isempty(deblank(sBaseFile))
        h = errordlg('Error, File Root not defined. Try again.','Mamba2D Error','modal');
        waitfor(h);
        set(handles.hFigure, 'Pointer', 'arrow' );
        return
    end
    
    st.dataFile =  strtrim(get(findobj(handles.hFigure,'tag','datafile'),'string'));
   
    if isempty(deblank(st.dataFile))
        h = errordlg('Error, Data File not defined. Try again.','Mamba2D Error','modal');
        waitfor(h);
        set(handles.hFigure, 'Pointer', 'arrow' );
        return
    end    
    
    st.settingsFile =  strtrim(get(findobj(handles.hFigure,'tag','settingsfile'),'string'));

    if isempty(deblank(st.settingsFile))
        h = errordlg('Error, Settings File not defined. Try again.','Mamba2D Error','modal');
        waitfor(h);
        set(handles.hFigure, 'Pointer', 'arrow' );
        return
    end     

    st.resistivityFile  = sprintf('%s.0.resistivity',sBaseFile);
    st.polyFile         = sprintf('%s.poly',sBaseFile);
    
    % Try to get correct path to save to:
    if isfield(handles.model,'path') && ~isempty(handles.model.path)
        path = handles.model.path; 
    else
        path = pwd;
        handles.model.path = path;
        guidata(hObject,handles); % resave path in fig
    end
    
    if exist(fullfile(path,st.resistivityFile),'file')
        str = sprintf('Warning: File %s already exists, shall I overwrite it?',st.resistivityFile);
        choice = questdlg(str,'Warning! ', 'Yes','No','No');
        switch choice
            case 'No'

                disp('Not saving resistivity file...')
                status = false;
                return
        end
    end
    
    hWaitbar = waitbar(.1,'Assembling arrays','Name','Writing MARE2DEM Files...');
    
    set(hWaitbar,'WindowStyle','modal');
    hWaitbar.Children.Title.Interpreter = 'none';
    
    % Set up a few arrays need for the output routines:
    Nodes           = handles.model.nodes(:,1:2);
    [i, j, v]       = find(triu(handles.model.segments));
    [i, isort] = sort(i);
    j = j(isort);
    v = v(isort);
    Segs            = [i j];       
    segMarker = v; % Segmarker needs to be 2 if segment is between 2 free parameters, or 1 if at least one side has a fixed parameter. 
    % This allows MARE2DEM to coarsen the mesh outside a data footprint window where segMarker == 2
    
   
    
    % Update segMarker. Get edge attachments first:
    ti = edgeAttachments(handles.model.DT,i,j);
    for i = 1:length(ti)
        if length(ti{i}) == 2
            reg1 = handles.model.TriIndex(ti{i}(1));
            reg2 = handles.model.TriIndex(ti{i}(2));
            if  all(handles.model.freeparameter(reg1,:)) &&  all(handles.model.freeparameter(reg2,:))
                segMarker(i) = 2*segMarker(i);  % freeparams on both sides
            else
                segMarker(i) = 1*segMarker(i);  % on or both sides are fixed
            end           
        else
            segMarker(i) = 1*segMarker(i);  
        end
        
    end
    Segs(:,3) = segMarker;
  
    holes   = [];
 
    % Get centers of current triangles:
    if exist('delaunayTriangulation','class')
        TriCenters = incenter(handles.model.DT,(1:size(handles.model.DT,1))');
    else
        TriCenters = incenters(handles.model.DT,(1:size(handles.model.DT,1))');
    end
    
    waitbar(.4,hWaitbar,'Assembling arrays...') 

    % Get unique regions:
    [~, iregs] = unique(handles.model.TriIndex);
    regionYZ    = [ TriCenters(iregs,1) TriCenters(iregs,2) ]; %KWK debug: should modify this to use region centroid, if centroid is in region (watch out for U's etc)

    attributes  = [regionYZ (1:size(regionYZ,1))' -1*ones(size(regionYZ,1),1)];
    
    % Create the resistivity file: this also assigns freeparameter numbers
    % in model.freeparameter    
    
    lowerBoundGlobal    = get(findobj(handles.hFigure,'tag','lowerbound'),'string');
    upperBoundGlobal    = get(findobj(handles.hFigure,'tag','upperbound'),'string');
   
    targetMisfit        = get(findobj(handles.hFigure,'tag','targetmisfit'),'string');
 
    st.globalBounds     = [str2num(lowerBoundGlobal) str2num(upperBoundGlobal)];
    st.targetMisfit     = str2num(targetMisfit);
    
    % Roughness penalty settings: 
    % first set some defaults so this code will work with old saved GUI figs:
    st.sRoughnessPenaltyMethod        = 'gradient';
    st.yzPenaltyWeights               = [3 1];
    st.penaltyCutWeight               = 0.1;
    st.anisotropyPenaltyWeight        = 0;
    st.anisotropyRatioRoughnessWeight = 1;
         
    val = get(findobj(handles.hFigure,'tag','roughnessPenaltyMethod'),'val');
    str = get(findobj(handles.hFigure,'tag','roughnessPenaltyMethod'),'string');
    if ~isempty(val)
        st.sRoughnessPenaltyMethod = str{val};   
    end
    val = str2double(get(findobj(handles.hFigure,'tag','yRoughnessWeight'),'string'));
    if isfinite(val)
        st.yzPenaltyWeights(1) = val;
    end
    val = str2double(get(findobj(handles.hFigure,'tag','zRoughnessWeight'),'string'));
    if isfinite(val)
        st.yzPenaltyWeights(2) = val;           
    end
    val = str2double(get(findobj(handles.hFigure,'tag','penaltyCutWeight'),'string'));
    if isfinite(val)
        st.penaltyCutWeight = val;   
    end
    val = str2double(get(findobj(handles.hFigure,'tag','anisotropyPenaltyWeight'),'string'));
    if isfinite(val)
        st.anisotropyPenaltyWeight = val;  
    end
    val = str2double(get(findobj(handles.hFigure,'tag','anisotropyRatioRoughnessWeight'),'string'));
    if isfinite(val)
        st.anisotropyRatioRoughnessWeight = val; 
    end
   
   % Write resistivity file to specified path    
    waitbar(.6,hWaitbar,sprintf('%s %s','Writing resistivity file:',st.resistivityFile));
    st.resistivityFile = fullfile(path,st.resistivityFile);
    bOverwrite = true;
 
    fprintf('\n%-32s %s\n','Writing Resistivity file:',st.resistivityFile)
    [status,st] = m2d_writeResistivity(st,bOverwrite);

    if status == false
       set( handles.hFigure, 'Pointer', 'arrow' );
       return 
    end
    
    % Write poly file to specified path:
    waitbar(.8,hWaitbar,sprintf('%s %s','Writing poly file:',st.polyFile))
    st.polyFile = fullfile(path,st.polyFile);
     
    % Create the model poly file:
    fprintf('%-32s %s\n','Writing Poly file:',st.polyFile);
    m2d_writePoly(st.polyFile,Nodes,Segs,holes,attributes)
  
    % === 新增：写入粗糙度参数到MARE2DEM设置文件 ===
    % 先打开设置文件，追加写入粗糙度参数
    fid_settings = fopen(st.settingsFile, 'a'); % a=追加模式，不覆盖原有内容
    if fid_settings ~= -1
        fprintf(fid_settings, '\n# === 粗糙度(Roughness)参数 ===\n');
        % 优先用Roughness按钮计算的参数，没有就用界面输入的默认值
        if isfield(handles, 'roughness')
            fprintf(fid_settings, 'free resistivity yz weights = %g %g\n', handles.roughness.yzWeights(1), handles.roughness.yzWeights(2));
            fprintf(fid_settings, 'penalty cut weight = %g\n', handles.roughness.cutWeight);
            fprintf(fid_settings, 'total model roughness = %.4f\n', handles.roughness.total);
        else
            % 没点Roughness按钮，用界面输入框的默认值
            y_weight = str2double(get(findobj(handles.hFigure,'tag','yRoughnessWeight'),'string'));
            z_weight = str2double(get(findobj(handles.hFigure,'tag','zRoughnessWeight'),'string'));
            cut_weight = str2double(get(findobj(handles.hFigure,'tag','penaltyCutWeight'),'string'));
            if ~isfinite(y_weight), y_weight = 3; end
            if ~isfinite(z_weight), z_weight = 1; end
            if ~isfinite(cut_weight), cut_weight = 0.1; end
            fprintf(fid_settings, 'free resistivity yz weights = %g %g\n', y_weight, z_weight);
            fprintf(fid_settings, 'penalty cut weight = %g\n', cut_weight);
        end
        fclose(fid_settings);
    end
    % === 新增代码结束 ===
    
    % 原代码里的这一行，保持不动
    m2d_writeSettingsFile(st.settingsFile);


    %
    % Create mare2dem.settings file:
    %
    st.settingsFile = fullfile(path,st.settingsFile);
    m2d_writeSettingsFile(st.settingsFile);
    
    
    set( handles.hFigure, 'Pointer', 'arrow' );
    
    delete(hWaitbar)

    h = helpdlg('Done writing MARE2DEM files','Mamba2D Message:');
    set(h,'windowstyle','modal');
    uiwait(h)
    
    
    catch Me

        echo off;
        if exist('hWaitbar')
            delete(hWaitbar)
        end
        waitfor( errordlg( {
            'Error writing MARE2DEM files!'
            ' '
            Me.identifier
            Me.message
            } ) );
        
    end

    set(handles.hFigure, 'Pointer', 'arrow' ); 

end
%----------------------------------------------------------------------
function importResistivity_Callback(hObject)

% Get PSLG .poly file name:
[file, path ] = uigetfile('*.resistivity','Select the Resistivity file (.resistivity)');
if file==0
    return
end

importResFile(hObject,fullfile(path,file));

end


%-------------------------------------------------------------------------------
% DGM 10/16/2015 - support calling Mamba2D with parameters to load an existing
% resistivity file. Do it like this:
%   h = Mamba2D;
%   Mamba2D('importResFile',h,sPathAndFile,[]);
% where sPathAndFile contains the path + name of a .resistivity file.
%
%-------------------------------------------------------------------------------
function importResFile(hObject,sFile,~)
[path,file, e]  = fileparts(sFile);
file            = [file e];

handles     = guidata(hObject);

set( handles.hFigure, 'Pointer', 'watch' ); drawnow;

[ ~, fileroot,~]= fileparts(file); % remove .resistivity name for later
[ ~, fileroot,~]= fileparts(fileroot); % remove iteration number

file = fullfile(path,file);

% Read in the resistivity file:
Resistivity = m2d_readResistivity(file);

% Read in the Model Poly file:
pFile = fullfile(path,Resistivity.polyFile);
 
[nodes,segments,~,~,regions] = m2d_readPoly(pFile);

% Check for duplicate nodes (i.e. corrupted mesh and fix it):
[nodes_u,iu,iog] = unique(nodes,'rows','stable');
if size(nodes_u,1) < size(nodes,1) % dang, we got duplicated nodes, fix them..
    beep
    disp('Mamba2D warning: removing duplicate nodes from input .poly file...')
    disp('polygon model may not be valid...')
    v1 = iog(segments(:,1));
    v2 = iog(segments(:,2));
    segments(:,1:2) = [v1 v2];
    nodes = nodes_u;
end


handles = guidata(handles.hFigure);
handles = sub_initialize(handles);

stSettings  = getappdata(handles.hFigure,'stSettings');

% turn on hidden IP buttons if IP/complex selected 
switch Resistivity.anisotropy
    case {'isotropic_ip','isotropic_complex'} 
        hObj = findobj(handles.hFigure,'tag','IP_buttons');
        set(hObj,'visible','on')       

    otherwise
        hObj = findobj(handles.hFigure,'tag','IP_buttons');
        set(hObj,'visible','off')
end

cStr = get(findobj(handles.hFigure,'tag','setAnisotropy'),'string');

val = find(strcmp(cStr,Resistivity.anisotropy));

if isempty(val)
    str = sprintf('Error, unknown anisotropy setting in input file: %s',Resistivity.anisotropy);
    waitfor( errordlg( str ) );
    return;
end
 
% Set the anisotropy menu to the new setting:
set(findobj(handles.hFigure,'tag','setAnisotropy'),'val',val);

% Update the GUI fields:
set(findobj(handles.hFigure,'tag','filenameroot'),'string',fileroot);
set(findobj(handles.hFigure,'tag','outputfolder'),'string',sub_formatPathString(path));
set(findobj(handles.hFigure,'tag','outputfolder'),'tooltip',path);
set(findobj(handles.hFigure,'tag','datafile'),'string',Resistivity.dataFile);
set(findobj(handles.hFigure,'tag','settingsfile'),'string',Resistivity.settingsFile);
set(findobj(handles.hFigure,'tag','targetmisfit'),'string',Resistivity.targetMisfit);
set(findobj(handles.hFigure,'tag','lowerbound'),'string',Resistivity.globalBounds(1));
set(findobj(handles.hFigure,'tag','upperbound'),'string',Resistivity.globalBounds(2));

if ~isempty(Resistivity.sRoughnessPenaltyMethod)
    switch Resistivity.sRoughnessPenaltyMethod
        case 'gradient'
            val = 1;
        case 'first_difference'
            val = 2;
    end
    set(findobj(handles.hFigure,'tag','roughnessPenaltyMethod'),'val',val);  
end
if ~isempty(Resistivity.yzPenaltyWeights) && isnumeric(Resistivity.yzPenaltyWeights)
    set(findobj(handles.hFigure,'tag','yRoughnessWeight'),'string',Resistivity.yzPenaltyWeights(1));
    set(findobj(handles.hFigure,'tag','zRoughnessWeight'),'string',Resistivity.yzPenaltyWeights(2));
end
if ~isempty(Resistivity.penaltyCutWeight) && isnumeric(Resistivity.penaltyCutWeight)
    set(findobj(handles.hFigure,'tag','penaltyCutWeight'),'string',Resistivity.penaltyCutWeight);
end
if ~isempty(Resistivity.anisotropyPenaltyWeight) && isnumeric(Resistivity.anisotropyPenaltyWeight)
    set(findobj(handles.hFigure,'tag','anisotropyPenaltyWeight'),'string',Resistivity.anisotropyPenaltyWeight);
end
if ~isempty(Resistivity.anisotropyRatioRoughnessWeight) && isnumeric(Resistivity.anisotropyRatioRoughnessWeight)
    set(findobj(handles.hFigure,'tag','anisotropyRatioRoughnessWeight'),'string',Resistivity.anisotropyRatioRoughnessWeight);
end

% Copy over a few things not in the UI:  % KWK: this is another
% example of why these codes need to be rewritten from the ground up. Ugg. 
handles.model.sDataGroupFile          = Resistivity.sDataGroupFile;
handles.model.sJointInvWeightType     = Resistivity.sJointInvWeightType;
handles.model.bRoughnessWithPrejudice = Resistivity.bRoughnessWithPrejudice;
handles.model.betaMGS                 = Resistivity.betaMGS;
 


% We have a clean slate, and let's assume the input model is legit (no
% duplicate nodes or intersecting segments). Update everything:

handles.model.nodes = nodes(:,1:2);

n = size(nodes,1);

% check for degenerate segments that connect node to itself:
lRemove = segments(:,1) == segments(:,2);
segments(lRemove,:) = [];
if any(lRemove) 
    beep
    disp('Mamba2D warning: removing degenerate segments from input .poly file...')
end

segs = sort(segments(:,1:2),2); % sort and only insert upper triangle of adjacency

if size(segments,2) > 2
    segMarker = segments(:,3) ./ abs(segments(:,3)); % convert to unit magnitude since newsegment expects +-1 for no-cut vs cut segs and then stores segment graphics handles as +_handle
else
    segMarker = ones(size(segments,1),1);
end
 
handles.model.segments      = sparse([segs(:,1);segs(:,2)],[segs(:,2);segs(:,1)],[segMarker;segMarker],n,n);  

% Don't forget to set a new bounding box
mnx = min(handles.model.nodes(:,1));
mxx = max(handles.model.nodes(:,1));
mny = min(handles.model.nodes(:,2));
mxy = max(handles.model.nodes(:,2));

handles.model.boundingBox = [mny mxy mnx mxx]; % top bottom left right;

% Insert the model parameters:
Resistivity.freeparameter(Resistivity.freeparameter > 1) = 1; % just want 1s and 0s here

handles.model.resistivity       = Resistivity.resistivity;
handles.model.freeparameter     = Resistivity.freeparameter;
handles.model.bounds            = Resistivity.bounds;
handles.model.prejudice         = Resistivity.prejudice;
handles.model.regions           = regions(:,1:2);
handles.model.anisotropy        = Resistivity.anisotropy;
handles.model.path              = path;

% Set anisotropy component menu:
sub_setAnisotropyComponentsMenu(handles);
sub_update_anisotropy_ui(handles);

% Plot model:
sub_updateModelPlot(handles);  % updates Guidata


% Read in the data file 
sFile = fullfile(path,Resistivity.dataFile);
sub_loadDataFile(sFile,handles.hFigure); % updates Guidata
 
% Set axis scale to data extent:
sub_setAxisScale_Callback(handles.hFigure, [],[],'zoomToSurvey')
 
drawnow;

% Exit:
hButtons = findobj(handles.hFigure,'type','uicontrol','style','togglebutton');
set(hButtons,'enable','on' );

set( handles.hFigure, 'Pointer', 'arrow' );

end
%----------------------------------------------------------------------
function bulkPrejudice_Callback(hObject)


    handles     = guidata(hObject);
 
    % Get values to set from user:

    aniso = handles.setAnisotropy.String{handles.setAnisotropy.Value};
    
    switch aniso
        case 'isotropic'
            sPrj = 'Enter prejudice and weight, e.g., 10.0  1';
            n = 2;
        case 'isotropic_ip'    
            sPrj = 'Enter prejudice and weight, e.g., (pr_rho wt_rho pr_etc wt_eta pr_tau wt_tau pr_c wt_c)';
            n = 8;
        case 'isotropic_complex'    
            sPrj = 'Enter prejudice and weight (pr_Re wt_Re pr_Im wt_Im):  ';
            n = 4;
        case 'triaxial'
            sPrj = 'Enter prejudice and weight (pr_x wt_x pr_y wt_y pr_z wt_z):  ';
            n = 6;
        case 'tix'
            sPrj = 'Enter prejudice and weight (pr_x wt_x pr_yz wt_yz):  ';
            n = 4;
        case 'tiy'
            sPrj = 'Enter prejudice and weight (pr_y wt_y pr_xz wt_xz):  ';
            n = 4;
        case 'tiz'
            sPrj = 'Enter prejudice and weight (pr_z wt_z pr_h wt_h):  ';
            n = 4;
        case 'tiz_ratio'
            sPrj = 'Enter prejudice and weight (pr_z wt_z pr_z/h wt_z/h):  ';
            n = 4;            
    end
    
    str = 'Use -1 to NOT modify existing values';
    sPrj = sprintf('%s\n%s',sPrj,str);

    defaultanswer = {num2str(zeros(1,n))};

    options.Resize='on';
    lAskAgain = true;
    
    while lAskAgain    
        
        answer = inputdlg(sPrj,'Bulk Prejudice Settings:',1,defaultanswer,options);

        if isempty(answer)
            lAskAgain = false;
            continue;
            
        else

            vals = str2num(answer{1}); %#ok<ST2NM> % cou

            if length(vals) ~= n
                str = sprintf('Input prejudice settings has %i value(s) where %i values are required. Try again',length(vals),n);
                h = errordlg(str,'Mamba2D Error','modal');
                waitfor(h);
                continue;
            end
            prej = vals(1:2:end);
            weight = vals(2:2:end);
            
            % Set prejudice and prejudice weights:
            nrho = size(handles.model.resistivity,2);
            for i = 1:nrho
                if prej(i)>=0
                    handles.model.prejudice(:,2*i-1) = prej(i);
                end
                if weight(i)>=0
                    handles.model.prejudice(:,2*i  ) = weight(i);
                end
            end


            guidata(hObject,handles)

            str = 'Done prejudice and its weights';

            h = helpdlg(str,'Mamba2D Message:');
            set(h,'windowstyle','modal');
            uiwait(h)   
            
            lAskAgain = false;
        end
    end
    
% Exit:
hButtons = findobj(handles.hFigure,'type','uicontrol','style','togglebutton');
set(hButtons,'enable','on' );

set( handles.hFigure, 'Pointer', 'arrow' ); drawnow;
 

end

%----------------------------------------------------------------------
function importPrejudice_Callback(hObject)

% Get PSLG .poly file name:
[file, path ] = uigetfile('*.resistivity','Select the resistivity file to use as a prejudice (.resistivity)');
if file==0
    return
end

importPrejudiceFromResFile(hObject,fullfile(path,file));

end
%----------------------------------------------------------------------
function importPrejudiceFromResFile(hObject,sFile,~)
[path,file, e]  = fileparts(sFile);
file            = [file e];

handles     = guidata(hObject);

set( handles.hFigure, 'Pointer', 'watch' ); drawnow;

[ ~, fileroot,~]= fileparts(file); % remove .resistivity name for later
[ ~, fileroot,~]= fileparts(fileroot); % remove iteration number

file = fullfile(path,file);

% Read in the resistivity file:
Prejudice = m2d_readResistivity(file);

% First check that Prejudice model is compatible with existing model (ie same number of parameters):

lError = false;

if size(Prejudice.resistivity,1) ~= size(handles.model.resistivity,1)    
    lError = true;  
else
    
    % Now carefully insert prejudice, depending on model parameterization:
    
     switch handles.model.anisotropy
         
        case {'isotropic','isotropic_ip','isotropic_complex'}
             handles.model.prejudice(:,1)   = Prejudice.resistivity(:,1);
             handles.model.prejudice(:,2)   = 1;
             
        case {'tix','tiy','tiz','tiz_ratio', 'triaxial'}  % these can only be done safefly when anisotropy type is the same
            
            if size(Prejudice.resistivity,2) ~= size(handles.model.resistivity,2)
                lError = true;
            else 
                nrho = size(handles.model.resistivity,2);
                handles.model.prejudice(:,1:2:2*nrho)   = Prejudice.resistivity; 
                handles.model.prejudice(:,2:2:2*nrho)   = 1;
            end
     end   
end
if ~lError
    
    guidata(hObject,handles)
    
    str1 = 'Done importing resistivity file to use as a prejudice model.';
    str2 = 'Prejudice weights are set to 1 by default. Modify using the set p. weight button.';
    str3 = 'Use the quantity menu on the lower right to view prejudice model.';
    str = sprintf('%s\n%s\n%s\n',str1,str2,str3);
    h = helpdlg(str,'Mamba2D Message:');
    set(h,'windowstyle','modal');
    uiwait(h)   
    
else
    
    str0 = 'Error importing a prejudice model. Dimensions do not agree. ';
    str1 = sprintf(' Current model: %i %i',size(handles.model.resistivity));
    str2 = sprintf('Imported model: %i %i',size(Prejudice.resistivity));
    str3 = sprintf('Aborting! Try again, bucko!');
    str = sprintf('%s\n%s\n%s\n%s',str0,str1,str2,str3);
    h = errordlg(str,'Mamba2D Error','modal');
    waitfor(h);
    return      
    
end

% Exit:
hButtons = findobj(handles.hFigure,'type','uicontrol','style','togglebutton');
set(hButtons,'enable','on' );

set( handles.hFigure, 'Pointer', 'arrow' ); drawnow;

end
%---------------------------------------------------------------------- ---
function importPoly_Callback(hObject)
 
handles = guidata(hObject);

% Get PSLG .poly file name:
[file, path ] = uigetfile('*.poly','Select PSLG file (.poly)');
if file==0
    % Turn button back to gray
    return
end

set( handles.hFigure, 'Pointer', 'watch' ); drawnow;

[ ~, fileroot, ~]= fileparts(file); % remove .poly name for later
set(findobj(handles.hFigure,'tag','filenameroot'),'string',fileroot);
file = fullfile(path,file);

% Get the file:
[nodes, segments, ~, ~,~] = m2d_readPoly(file);



if isempty(handles.model.nodes)  % Nothing is drawn yet, so we can do a superfast addition assuming the .poly file has valid no duplicate nots nor in
    
    % We have a clean slate, and let's assume the input model is legit (no
    % duplicate nodes or intersecting segments). Update everything:

    handles.model.nodes = nodes(:,1:2);

    n = size(nodes,1);

    % check for degenerate segments that connect node to itself:
    lRemove = segments(:,1) == segments(:,2);
    segments(lRemove,:) = [];
    
    segs = sort(segments(:,1:2),2); % sort and only insert upper triangle of adjacency
    
    if size(segments,2) > 2
        segMarker = segments(:,3) ./ abs(segments(:,3)); % convert to unit magnitude since newsegment expects +-1 for no-cut vs cut segs and then stores segment graphics handles as +_handle
    else
        segMarker = ones(size(segments,1),1);
    end
    handles.model.segments      = sparse([segs(:,1);segs(:,2)],[segs(:,2);segs(:,1)],[segMarker;segMarker],n,n);

    % Don't forget to set a new bounding box
    mnx = min(handles.model.nodes(:,1));
    mxx = max(handles.model.nodes(:,1));
    mny = min(handles.model.nodes(:,2));
    mxy = max(handles.model.nodes(:,2));

    handles.model.boundingBox = [mny mxy mnx mxx]; % top bottom left right;
    
else
    
    
    % Got to go the slow road and check for overlaps etc:
    
    choice = questdlg('Model already has nodes and segments, are you sure you want to add stuff from .poly file? This will be slow since it has to be done carefully...', ...
        'Import Poly:','Yes', 'No','No');
    
    beep;
    disp('Sorry importing an overlapping .poly file structure is not yet supported.')
%    
%     if strcmpi(choice,'Yes')
%         
%         handles.updateLayers = false;
%         title('***Adding nodes, be patient... ***','color','r');drawnow
%         %  Add nodes to plot and handles array:
%         inode = zeros(size(nodes,1),1);
%         for i = 1:size(nodes,1)
%             [handles inode(i)] = addNode(handles,nodes(i,1),nodes(i,2));
%         end
%         
%         
%         title('***Adding segments, be patient...
%         ***','color','r');drawnowi
%         % Add segments to plot and handles array:
%         handles.updateLayers = false;
%         for i = 1:size(segments,1)
%             inodes = segments(i,1:2);
%             handles = addSegment(handles,inode(inodes));
%         end
%         handles.updateLayers = true;
%    end
end
 
% Plot model:
sub_updateModelPlot(handles);  % updates Guidata
 
set( handles.hFigure, 'Pointer', 'arrow' ); drawnow;


end

%--------------------------------------------------------------------------
function import1Dmodel_Callback(hObject)


handles = guidata(hObject);

set( handles.hFigure, 'Pointer', 'watch' ); drawnow;

 
       
% Select file that is [z rho]  and read it in:
 
% Get the segments file:
[file, path ] = uigetfile('*','Select 1D model text file with [z_top, rho] in meters and ohm-m');
if file==0
    set( handles.hFigure, 'Pointer', 'arrow' ); drawnow;
    return
end

model1D = load(fullfile(path,file));

if isempty(model1D)
    set( handles.hFigure, 'Pointer', 'arrow' ); drawnow;
    return;
end
       
       
% Ask user if 1D model should be projected onto fixed or free regions, or
% both:
sMode = questdlg('Project 1D model onto which parameters?','Mamba2D: 1D Model Import','fixed', 'free','both','fixed');    

sInterp = questdlg('Interpolation type:','Mamba2D: 1D Model Import','piecewise constant', 'piecewise linear','piecewise linear');    
 

%-----------------------------------------
% Project 1D modeling onto 2D model cells:
%%----------------------------------------   
 
% Interpolate 1D model to centroids of all regions:
centroids = m2d_getCentroids( handles.model.DT, handles.model.TriIndex); 
switch sInterp

    case 'piecewise constant'  % i.e. [z_top rho]
        centroid_rho1d = interp1(model1D(:,1),model1D(:,2:end),centroids(:,2),'previous'); % fast interpolation here at the start, then pull values needed later
    case 'piecewise linear'   % [z_middle rho]
        centroid_rho1d = interp1(model1D(:,1),model1D(:,2:end),centroids(:,2),'linear'); % fast interpolation here at the start, then pull values needed later
end

% get regions to insert into:
switch sMode
    case 'free'
       lInsert = handles.model.freeparameter  > 0; 

    case 'fixed'
       lInsert = handles.model.freeparameter == 0;

    case 'both'
       lInsert = ~isnan(handles.model.freeparameter);          
end

% Anisotropy check:
if (size(centroid_rho1d,2) == 1)
    % case 1:  1d model is isotropic so insert into all resistivity
    % columns:  
    lGo = lInsert & isfinite(centroid_rho1d(:,1));
    for icol = 1:size(handles.model.resistivity,2)
        handles.model.resistivity(lGo,icol) = centroid_rho1d(lGo);
    end
elseif ( size(centroid_rho1d,2) > 1) && (size(centroid_rho1d,2) == size(handles.model.resistivity,2))
    
    for icol = 1:size(handles.model.resistivity,2)
        lGo = lInsert & isfinite(centroid_rho1d(:,icol));
        handles.model.resistivity(lGo,icol) = centroid_rho1d(lGo,icol);
    end    
    
else
    str = sprintf('Error! # of 1D model anisotropic components does not equal 2D model''s: %i vs %i \n Try modifying input 1D model',size(handles.model.resistivity,2),size(centroid_rho1d,2));
    waitfor(errordlg(str,'Mamba2D Error','modal'));
    set( handles.hFigure, 'Pointer', 'arrow' ); drawnow;
    return;
end
 
%
% Plot updated model:
%
sub_updateModelPlot(handles);  % updates Guidata
 
set( handles.hFigure, 'Pointer', 'arrow' ); drawnow;

end

%--------------------------------------------------------------------------
function import2Dmodel_Callback(hObject)


handles = guidata(hObject);

set( handles.hFigure, 'Pointer', 'watch' ); drawnow;

       
% Select file that is [z rho]  and read it in:
 
% Get the segments file:
[file, path ] = uigetfile('*','Select 2D model text file with [y,z,rho] in meters and ohm-m');
if file==0
    set( handles.hFigure, 'Pointer', 'arrow' ); drawnow;
    return
end

model2D = load(fullfile(path,file));

if isempty(model2D)
    set( handles.hFigure, 'Pointer', 'arrow' ); drawnow;
    return;
end
       
       
% Ask user if 2D model should be projected onto fixed or free regions, or
% both:
sMode = questdlg('Project 2D model onto which parameters?','Mamba2D: 2D Model Import','fixed', 'free','both','fixed');    

sInterp = questdlg('Interpolation type:','Mamba2D: 2D Model Import','piecewise constant', 'piecewise linear','piecewise linear');    
 

%-----------------------------------------
% Project imported 2D model onto MARE2D cells:
%%----------------------------------------   
 

% Interpolate 1D model to centroids of all regions:
centroids = m2d_getCentroids( handles.model.DT, handles.model.TriIndex); 
switch sInterp

    case 'piecewise constant'  % i.e. [z_top rho]
        F = scatteredInterpolant(model2D(:,1),model2D(:,2),model2D(:,3:end),'nearest','none');
       
    case 'piecewise linear'  % [z_middle rho]
        F = scatteredInterpolant(model2D(:,1),model2D(:,2),model2D(:,3:end),'linear','none');
end

centroid_rho2d = F(centroids(:,1),centroids(:,2));

% get regions to insert into:
switch sMode
    case 'free'
       lInsert = handles.model.freeparameter  > 0; 

    case 'fixed'
       lInsert = handles.model.freeparameter == 0;

    case 'both'
       lInsert = ~isnan(handles.model.freeparameter);          
end

% Anisotropy check:
if (size(centroid_rho2d,2) == 1)
    % case 1:  1d model is isotropic so insert into all resistivity
    % columns:  
    lGo = lInsert & isfinite(centroid_rho2d(:,1));
    for icol = 1:size(handles.model.resistivity,2)
        handles.model.resistivity(lGo,icol) = centroid_rho2d(lGo);
    end
elseif ( size(centroid_rho2d,2) > 1) && (size(centroid_rho2d,2) == size(handles.model.resistivity,2))
    
    for icol = 1:size(handles.model.resistivity,2)
        lGo = lInsert & isfinite(centroid_rho2d(:,icol));
        handles.model.resistivity(lGo,icol) = centroid_rho2d(lGo,icol);
    end    
    
else
    str = sprintf('Error! # of 2D model anisotropic components does not equal 2D model''s: %i vs %i \n Try modifying input 1D model',size(handles.model.resistivity,2),size(centroid_rho1d,2));
    waitfor(errordlg(str,'Mamba2D Error','modal'));
    set( handles.hFigure, 'Pointer', 'arrow' ); drawnow;
    return;
end
 
%
% Plot updated model:
%
sub_updateModelPlot(handles);  % updates Guidata
 
set( handles.hFigure, 'Pointer', 'arrow' ); drawnow;

end
%--------------------------------------------------------------------------
function splitSegment_Callback(hObject)

handles     = guidata(hObject);
stSettings  = getappdata(handles.hFigure,'stSettings');

set(handles.hFigure,'pointer','cross')

but = 1;

nSplit = 0;

while but==1
    
    % Select a segment:
    [x0, y0, but] = sub_getPoints(1,handles.hFigure,handles.hModelAxes); % subfunction  getpoints(N,handles) returns N points
    if but~=1
        break
    end
    ax = axis(handles.hModelAxes);
    if x0 < ax(1) || x0 > ax(2) || y0 < ax(3) || y0 > ax(4)
        break
    end
    
    % Find nearest segment:
    [inodes,dist,~,~] = sub_nearestSegment(handles.model.nodes,handles.model.segments,x0,y0,handles.axesPosPixels,ax);

    % ====================== 核心修复：添加索引有效性检查 ======================
    if dist > stSettings.dr || isempty(inodes) || any(inodes < 1) || any(inodes > size(handles.model.nodes,1))
        continue; % 没有找到有效线段，跳过这次点击
    end
    % ======================================================================
       
    sub_highlightSegment(handles,inodes);
          
    str = sprintf('Enter # of pieces:');
    temp= inputdlg(str,'Split Segments',1);
    
    if ~isempty(temp)
        npieces = str2double(temp{1});
        if ~isfinite(npieces) || npieces < 2
            warndlg('请输入大于等于2的整数！');
            continue;
        end
        
        xn = handles.model.nodes(inodes,1);
        yn = handles.model.nodes(inodes,2);
        
        x = linspace(min(xn),max(xn),npieces+1);
        y = linspace(min(yn),max(yn),npieces+1);
        
        if xn(1) > xn(2)
            x = fliplr(x);
        end
        if yn(1) > yn(2)
            y = fliplr(y);
        end
        
        for i = 2:npieces
            % get new node location:
            x0 = x(i);
            y0 = y(i);
            
            % divide the segment:
            handles.model = sub_divideSegment(handles.model,inodes,x0,y0);
            inodes = [size(handles.model.nodes,1) inodes(2)];
            nSplit = nSplit + 1;
            
        end
    
        %
        % Plot segments:
        %
        handles = sub_plotSegsAndNodes(handles);
      
    end
end


if nSplit > 0
    % Update the model and plot it:
    sub_updateModelPlot(handles);  % saves h to guidata so no need to do that here again
    % NB: The temporary new nodes and regions are deleted by sub_updateModelPlot     
end
    
set(handles.hFigure,'pointer','arrow')

end
%--------------------------------------------------------------------------
function [x,y]=gpos(h_axes,h_figure)
%GPOS Get current position of cusor and return its coordinates in axes with handle h_axes
% h_axes - handle of specified axes
% [x,y]  - cursor coordinates in axes h_aexs
%
% -------------------------------------------------------------------------
% Note:
%  1. This function should be called in the figure callback WindowButtonMotionFcn.
%  2. It works like GINPUT provided by Matlab,but it traces the position
%       of cursor without click and is designed for 2-D axes.
%  3. It can also work even the units of figure and axes are inconsistent,
%       or the direction of axes is reversed.
% -------------------------------------------------------------------------

% Written by Kang Zhao,DLUT,Dalian,CHINA. 2003-11-19
% E-mail:kangzhao@student.dlut.edu.cn

%h_figure=gcf;

units_figure = get(h_figure,'units');
units_axes   = get(h_axes,'units');

if_units_consistent = 1;

if ~strcmp(units_figure,units_axes)
    if_units_consistent=0;
    set(h_axes,'units',units_figure); % To be sure that units of figure and axes are consistent
end

% Position of origin in figure [left bottom]
pos_axes_unitfig    = get(h_axes,'position');
% KWK debug: exit if no values (not yet sure why this happens?)
if numel(pos_axes_unitfig)==0 
    return;
end
width_axes_unitfig  = pos_axes_unitfig(3);
height_axes_unitfig = pos_axes_unitfig(4);

xDir_axes=get(h_axes,'XDir');
yDir_axes=get(h_axes,'YDir');

% Cursor position in figure
pos_cursor_unitfig = get( h_figure, 'currentpoint'); % [left bottom]

if strcmp(xDir_axes,'normal')
    left_origin_unitfig = pos_axes_unitfig(1);
    x_cursor2origin_unitfig = pos_cursor_unitfig(1) - left_origin_unitfig;
else
    left_origin_unitfig = pos_axes_unitfig(1) + width_axes_unitfig;
    x_cursor2origin_unitfig = -( pos_cursor_unitfig(1) - left_origin_unitfig );
end

if strcmp(yDir_axes,'normal')
    bottom_origin_unitfig     = pos_axes_unitfig(2);
    y_cursor2origin_unitfig = pos_cursor_unitfig(2) - bottom_origin_unitfig;
else
    bottom_origin_unitfig = pos_axes_unitfig(2) + height_axes_unitfig;
    y_cursor2origin_unitfig = -( pos_cursor_unitfig(2) - bottom_origin_unitfig );
end

xlim_axes=get(h_axes,'XLim');
width_axes_unitaxes=xlim_axes(2)-xlim_axes(1);

ylim_axes=get(h_axes,'YLim');
height_axes_unitaxes=ylim_axes(2)-ylim_axes(1);

x = xlim_axes(1) + x_cursor2origin_unitfig / width_axes_unitfig * width_axes_unitaxes;
y = ylim_axes(1) + y_cursor2origin_unitfig / height_axes_unitfig * height_axes_unitaxes;

% Recover units of axes,if original units of figure and axes are not consistent.
if ~if_units_consistent
    set(h_axes,'units',units_axes);
end

% KWK modify to not show values outside axes limits:
ax = axis(h_axes);

if x > max(xlim_axes) || x < min(xlim_axes) || y > max(ylim_axes) || y < min(ylim_axes)
    x =[];
    y = [];
end
end
%--------------------------------------------------------------------------
function qualityAngle_Callback(hObject, ~, ~)
str = get(hObject,'string');
if isempty(str)
else
    val = str2double(str);
    if val < 10 || val > 32
        h = errordlg('错误：质量角度必须在 10-32 度之间','Mamba2D Error','modal');
        waitfor(h);
        set(hObject,'string','30');
    end
end
end

%--------------------------------------------------------------------------
function resizeFcn_Callback(hObject, ~, handles)
 
handles.hModelAxes.Units = 'pixels';
handles.hFigure.Units    = 'pixels';


ax = axis;

%set(gca,'PlotBoxAspectRatioMode','manual')

% Resize tool panel:
if ~isprop(handles.hFigure,'Position')
    return
end
figPos  = handles.hFigure.Position;
toolPos = handles.mamba2DPanel.Position;

dx = 45; 
x0 = toolPos(1)+toolPos(3)+dx;
y0 = 35;
dy = 30;

% Set minimum x and y extent:
figPos = max([0 0 toolPos(3)+x0+dx,toolPos(4)+y0+dy],figPos);
handles.hFigure.Position = figPos;
  
handles.mamba2DPanel.Position = [toolPos(1) figPos(4)-toolPos(4) toolPos(3:4)];  % this keeps panel in upper left position with static size.

% Update axes position:
wx = figPos(3) - x0 - 2*dx;    % sets width to figure width minus mamba2DPanel width minus some padding
wy = figPos(4) - y0 - dy;
 
handles.hModelAxes.OuterPosition = [ x0 y0 wx wy ];
 
pbaspect([1 wy/wx 1])
 
handles.axesPosPixels    =  handles.hModelAxes.OuterPosition;

%axis fill  % this can wreak havoc when resizing figure

%axis(ax) 
set(gca,'xlim',ax(1:2))

zoom reset 

% save new figure position to settings so next time Mamba2D is opened it uses
% same position. This assumes user repositions figure to some desired size
% and location.
stSettings  = getappdata(handles.hFigure,'stSettings');
stSettings.figureOuterPosition = handles.hFigure.OuterPosition;
setappdata(handles.hFigure,'stSettings',stSettings);


% Update Guidata
guidata(hObject,handles);

end
%-----------------------------------------------
function [dist, ii] = sub_getDistancePixels(ap,ax,x0,y0,x1,y1)

% x1,y1 can be vectors 
 
% normalize distance to number of pixels:
dx = abs(x1-x0(1));
dy = abs(y1-y0(1)); 

axp = ap(3);
ayp = ap(4);
 

% New Feb 2012:
nxpx = dx/abs(diff(ax(1:2)))*axp;  %kwk debug: this might not be correct for true pixel distance. seems to fail when zoom is large
nypx = dy/abs(diff(ax(3:4)))*ayp;
[dist, ii]  = min( sqrt(nxpx.^2 + nypx.^2));

end
 
%--------------------------------------------------------------------------
function sub_Close(~,~,hFig)
% called from File menu, triggers a close event for the figure, which calls
% the main closeFig_callback function.
    close(hFig);
end
%----------------------------------------------------------------------
function closeFig_Callback(hObject, eventdata, handles)
% === 修复版：关闭窗口回调，彻底避免点索引报错 ===
try
    % 先安全校验数据，不对就直接关窗口
    if nargin < 3 || ~isstruct(handles) || ~isfield(handles, 'hFigure')
        delete(gcf);
        return;
    end
    
    % 原有的业务逻辑，保持不动
    bChanged = getappdata(handles.hFigure, 'bChanged');
    if bChanged
        ButtonName=questdlg('您的模型有未保存的更改，确定要关闭吗？', ...
            '关闭 Mamba2D', ...
            '是','否','否');
        switch ButtonName
            case '是'
                delete(handles.hFigure);
            case '否'
                return;
        end
    else
        delete(handles.hFigure);
    end
catch
    % 任何异常都直接关窗口，绝对不弹红色报错
    delete(gcf);
end


end
%--------------------------------------------------------------------------
function importWorkspace_Callback(hObject)  
% imports points from workspace variables

handles     = guidata(hObject);
stSettings  = getappdata(handles.hFigure,'stSettings');


% get current workspace variables
vars = evalin('base','who');

if isempty(vars)
    warndlg('工作区中无变量，请先定义变量！','Warning','modal');
    return
end
[s,v] = listdlg('PromptString','选择数组或水平位置向量',...
    'SelectionMode','single',...
    'ListString',vars,'ListSize',[250 150]);
if v==1
    A = evalin('base',vars{s});
    [i, j] = size(A);
    if i==2 && j~=2 % make column vectors
        x = A(1,:);
        y = A(2,:);
    elseif j==2
        x = A(:,1);
        y = A(:,2);
    elseif i==1 || j==1
        x = A;
        [s,v] = listdlg('PromptString','Select a vertical position vector',...
            'SelectionMode','single',...
            'ListString',vars);
        if v==1
            y = evalin('base',vars{s});
        else
            % Turn button back to gray
            return
        end
    end
else
    % Turn button back to gray
    return
end
% Ask if segments desired?
ButtonName=questdlg('Make nodes or segments?','Import pts', ...
    'Nodes','Segments','Segments');

% Ask user about creating penalty cuts
nSegAttr = sub_penaltyCutQuestion( stSettings.segAttributeDflt );
minDist = 0;

% Add them:
if strcmp(ButtonName,'Segments')
    if size(x,2) > 1
        x = x';
    end
    if size(y,2) > 1
        y = y';
    end
    title('***正在添加节点和线段，请稍候... ***','color','r');drawnow
    lastNode = [];
    
    for i = 1:length(x)
        [handles, isegNodes] = sub_addNodeSeg(x(i),y(i),handles,stSettings,lastNode,nSegAttr,minDist);  
        lastNode = isegNodes(1);   
    end
            
    title(handles.hModelAxes,'')
    
else
    title('***正在添加节点，请稍候.... ***','color','r');drawnow
    
    for i = 1:length(x)
        [handles, ~] = sub_addNode(x(i),y(i),handles,stSettings,minDist);
    end
            
    title(handles.hModelAxes,'')
end
 
% Update the model and plot it:
sub_updateModelPlot(handles);     

end

% --------------------------------------------------------------------
function replot_Callback(g0, g1, h)
% this is called when either the quantity or component menus are used

if strcmpi(g0.Tag,'quantity') % then update the components menu:
    sub_setAnisotropyComponentsMenu(h)
end

sub_plotModel(h.hFigure);  

end

%--------------------------------------------------------------------------
% Read the given data file and check that its receivers are IN THE WATER
% (marine) or IN THE GROUND (sub-aerial).       Added by DGM 13 Dec 2012
function chkRxDepth_Callback(hObject) %kwk debug march 2018: check if this is still working
handles = guidata(hObject);

% Get the name of the data file
sDataFile = get( findobj( handles.hFigure, 'tag', 'datafile' ), 'String' );
if ~exist( sDataFile, 'file' )
    uiwait( errordlg( {
        '无法找到数据文件: '
        sDataFile
        ''
        '无法检查接收器深度.'
        } ) );
    return;
end

% Read it (if can't, msg & exit)
%[stUTM,stCSEM,stMT,stDC, nData] = m2d_readEMData2DFile( sDataFile, 'Silent' );
stD = m2d_readEMData2DFile(sDataFile, 'Silent');

% move stD's fields into st so we don't have to deal with too many nested structures 
stUTM   = stD.stUTM;
stCSEM  = stD.stCSEM;
stMT    = stD.stMT;
stDC    = stD.stDC;
nData   = stD.DATA;

if isempty(stCSEM) && isempty(stMT)
    uiwait( errordlg( {
        'Could not OPEN the data file: '
        sDataFile
        } ) );
    return;
end

% Check each of the CSEM & MT receivers. Issue warnings as appropriate.
cMsgs = {};
if isfield( stMT, 'receivers' ) && ~isempty( stMT.receivers )
    nPassStart = 1;
    Y = stMT.receivers(:,2);
    Z = stMT.receivers(:,3);
    if isfield( stMT, 'names' ) && ~isempty( stMT.names )
        cNames = stMT.names;
    else
        cNames = cell(size(Y,1),1);
    end
    sType = 'MT Rx';
else
    nPassStart = 2;
    Y = stCSEM.receivers(:,2);
    Z = stCSEM.receivers(:,3);
    if isfield( stCSEM, 'names' ) && ~isempty( stCSEM.names )
        cNames = stCSEM.names;
    else
        cNames = cell(size(Y,1),1);
    end
    sType = 'CSEM Rx';
end
for iPass = nPassStart:3
    for iRx = 1:size(Y,1)
        iRgn = pointLocation( handles.DT, Y(iRx), Z(iRx) );
        if isnan(iRgn)
            cMsgs{end+1} = sprintf( '%s Site #%d is not inside the model space.' ...
                , sType, iRx );
            
        elseif Z(iRx) > 0                       % Sub-MARINE site
            iRgn = handles.TriIndex(iRgn);
            
            % if resistivity doesn't look like reasonable seawater, go
            % upward for a bit until we find seawater.
            nAdjust = 0;
            while nAdjust < 50 && handles.resistivity(iRgn,1) > 0.4
                nAdjust = nAdjust + 0.1;
                iRgn = pointLocation( handles.DT, Y(iRx), Z(iRx) - nAdjust );
                if isnan(iRgn)
                    break;
                end
                iRgn = handles.TriIndex(iRgn);
            end
            if nAdjust > 0
                if ~isempty(cNames{iRx})
                    sSite = sprintf( '(Name:%s)', cNames{iRx} );
                else
                    sSite = sprintf( '(No name)' );
                end
                if handles.resistivity(iRgn,1) > 0.4
                    cMsgs{end+1} = sprintf( '%s #%d %s is DEEP in the ground. Move up to seawater.' ...
                        , sType, iRx, sSite );
                else
                    cMsgs{end+1} = sprintf( '%s #%d %s WAS in the ground. NOW MOVED from Z = %.1f to %.1f' ...
                        , sType, iRx, sSite, Z(iRx), Z(iRx) - nAdjust );
                    switch( iPass )
                    case 1
                        stMT.receivers(iRx,3) = Z(iRx) - nAdjust;
                    case 2
                        stCSEM.receivers(iRx,3) = Z(iRx) - nAdjust;
                    case 3
                        stCSEM.transmitters(iRx,3) = Z(iRx) - nAdjust;
                    end
                end
            end
            
        else                                    % Sub-AERIAL site
            iRgn = handles.TriIndex(iRgn);
            
            % if resistivity looks like air, go downward looking for ground
            nAdjust = 0;
            while nAdjust < 50 && handles.resistivity(iRgn,1) > 1e5 % I like to use 1e6 for air to suppress numerical precision issues
                nAdjust = nAdjust + 0.1;
                iRgn = pointLocation( handles.DT, Y(iRx), Z(iRx) + nAdjust );
                if isnan(iRgn)
                    break;
                end
                iRgn = handles.TriIndex(iRgn);
            end
            if nAdjust > 0
                if ~isempty(cNames{iRx})
                    sSite = sprintf( '(Name:%s)', cNames{iRx} );
                else
                    sSite = sprintf( '(No name)' );
                end
                if handles.resistivity(iRgn,1) > 0.4
                    cMsgs{end+1} = sprintf( '%s #%d %s is HIGH in the air. Move down to the ground.' ...
                        , sType, iRx, sSite );
                else
                    cMsgs{end+1} = sprintf( '%s #%d %s WAS in the air. NOW MOVED from Z = %.1f to %.1f' ...
                        , sType, iRx, sSite, Z(iRx), Z(iRx) + nAdjust );
                    switch( iPass )
                    case 1
                        stMT.receivers(iRx,3) = Z(iRx) + nAdjust;
                    case 2
                        stCSEM.receivers(iRx,3) = Z(iRx) + nAdjust;
                    case 3
                        stCSEM.transmitters(iRx,3) = Z(iRx) + nAdjust;
                    end
                end
            end
            
        end
    end
    
    % Get ready for next pass...
    if iPass == 1
        % Go from MT to CSEM Rx
        if ~isfield( stCSEM, 'receivers' ) || isempty( stCSEM.receivers )
            break;
        end
        Y = stCSEM.receivers(:,2);
        Z = stCSEM.receivers(:,3);
        if isfield( stCSEM, 'names' ) && ~isempty( stCSEM.names )
            cNames = stCSEM.names;
        else
            cNames = cell(size(Y,1),1);
        end
        sType = 'CSEM Rx';
        
    elseif iPass == 2
        % Go from CSEM Rx to CSEM Tx
        if ~isfield( stCSEM, 'transmitters' ) || isempty( stCSEM.transmitters )
            break;
        end
        Y = stCSEM.transmitters(:,2);
        Z = stCSEM.transmitters(:,3);
        if isfield( stCSEM, 'transmitterName' ) && ~isempty( stCSEM.transmitterName )
            cNames = stCSEM.transmitterName;
        else
            cNames = cell(size(Y,1),1);
        end
        sType = 'CSEM Tx';
    end
end

% Write an updated data file
m2d_writeEMData2DFile(sDataFile,'Updated by Mamba2D Check RxTx function.',stUTM,stCSEM,stMT,nData);

if ~isempty( cMsgs )
    for i=1:numel(cMsgs)
        fprintf( '%s\n', cMsgs{i} );
    end
    uiwait( msgbox( [
        {
        ['File ' sDataFile ' has been UPDATED!']
        ''
        '以下信息已打印至命令行窗口:'
        ''
        }
        cMsgs'], 'Mamba2D', 'modal' ) );
else
    uiwait( msgbox( 'All Receiver & Transmitter Depths check out OK.', 'Mamba2D', 'modal' ) );
end

return;
end % chkRxDepth


%--------------------------------------------------------------------------
function sub_setUImenus(hFig,stSettings)

handles = guidata(hFig); % read only here

% Delete any existing menus:
delete(findobj(hFig,'tag','appearancemenu'));
delete(findobj(hFig,'tag','filemenu'));

%-----------------%
% File menu %
%-----------------%
% Create the menu
hMenu = uimenu( hFig, 'Label', '&File','tag','filemenu' );
 
uimenu( hMenu, 'Label', '&Save Mamba2D GUI to .fig file...', 'Callback', {@sub_save, hFig},'accelerator','s','Interruptible','off' );
%---
h = uimenu( hMenu, 'Label', '&Print to image file...', 'Callback', {@sub_print, hFig}, 'Separator', 'on','accelerator','p','Interruptible','off' );
%---
uimenu( hMenu, 'Label', 'E&xit', 'Callback', {@sub_Close, hFig}, 'Separator', 'on','accelerator','w' ,'Interruptible','off' );

%-----------------%
% Appearance menu %
%-----------------%
m40 =  uimenu(hFig,'Label','Appearance','BusyAction','cancel','tag','appearancemenu');
 
uimenu('Parent',m40,'Label','Free parameters' ,'callback'             , {@sub_showFreeRegions_Callback,  hFig},'checked',stSettings.showFreeRegions, 'BusyAction','cancel');
uimenu('Parent',m40,'Label','Fixed parameters','callback'             , {@sub_showFixedRegions_Callback, hFig},'checked',stSettings.showFixedRegions,'BusyAction','cancel');
uimenu('Parent',m40,'Label','Segments' ,'callback'                    , {@sub_showSegments_Callback,     hFig},'checked',stSettings.showSegments,    'BusyAction','cancel');
uimenu('Parent',m40,'Label','Nodes' ,'callback'                       , {@sub_showNodes_Callback,        hFig},'checked',stSettings.showNodes,       'BusyAction','cancel');

str = getenv('USER');
if strcmpi(str,'kkey')
    uimenu('Parent',m40,'Label','DT edges (for debugging only)','callback', {@sub_showDTedges_Callback,hFig});
end


 
% Colormap: 
mCm = uimenu('Parent',m40,'Label','Colormap ','separator','on');
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
mCs = uimenu('Parent',m40,'Label','Color Scale');
%uimenu('Parent',mCs,'Label','Automatic (using current view)', 'callback', {@sub_setColorScaleLimitsAuto,hFig} );
uimenu('Parent',mCs,'Label','Manual Limits',                  'callback', {@sub_setColorScaleLimitsManual,hFig} );

uimenu('Parent',mCs,'Label','Log10', 'callback', {@sub_setColorScale, hFig, 'Log10'}, 'separator', 'on' );
uimenu('Parent',mCs,'Label','Linear','callback', {@sub_setColorScale, hFig, 'Linear'} );


% Axes control:
m10 = uimenu('Parent',m40,'Label','Axis');
uimenu(m10,'Label','Zoom to Survey Region', 'callback', {@sub_setAxisScale_Callback, hFig, 'zoomToSurvey'} );
uimenu(m10,'Label','Show Entire Model',     'callback', {@sub_setAxisScale_Callback, hFig, 'entireModel'} );
%uimenu(m10,'Label','Normal',                'callback', {@sub_SetAxisScale_Callback, hFig, 'normal'} );
uimenu(m10,'Label','Equal Aspect Ratio',    'callback', {@sub_setAxisScale_Callback, hFig, 'equal'} ,'checked',stSettings.equalAspect);
uimenu(m10,'Label','Reverse Horizontal Axis', 'tag','reverseX','callback', {@sub_setAxisDirection, hFig, 'reverseX'},'checked',stSettings.reverseX);
uimenu(m10,'Label','Reverse Vertical Axis', 'tag','reverseY',  'callback', {@sub_setAxisDirection, hFig, 'reverseY'},'checked',stSettings.reverseY);
 
% Line thickness 
uimenu(m40,'Label','Set Line Width','callback', {@setFigProperty, hFig,'segment','segThickness','linewidth'});    
 
% Node size:
uimenu(m40,'Label','Set Node Marker Size','callback', {@setFigProperty, hFig,'node','nodeSize','markersize'});    
 
% Font size:
m12 = uimenu('Parent',m40,'Label','Font Size', 'callback', {@setFontSize, hFig});

% Grid
m12 = uimenu('Parent',m40,'Label','Grid Lines', 'callback',{@sub_gridLines, hFig});

%Position units:
m10 = uimenu('Parent',m40,'Label','Use kilometers', 'callback', {@sub_setUnits, hFig},...
             'tag','units_menu','checked',stSettings.usekm);
         
% Receivers:
if isfield(handles,'st')
    
    st = handles.st;

    if isfield(st,'stMT') && ~isempty(st.stMT) && isfield(st.stMT,'receivers') 
        m1 = uimenu('Parent',m40,'Label','MT Receivers','separator','on');
        uimenu(m1,'Label','Show Markers',  'tag','showRxMT',     'callback', {@chgVisCheck, hFig, 'mtsites'} );
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

    
    if isfield(st,'stCSEM') && ~isempty(st.stCSEM) && isfield(st.stCSEM,'receivers')
        m1 = uimenu('Parent',m40,'Label','CSEM Receivers','separator','on');
        uimenu(m1,'Label','Show Markers',  'tag','showRxCSEM',     'callback', {@chgVisCheck, hFig, 'csemsites'} );
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

    % Transmitters:
    if isfield(st,'stCSEM') && ~isempty(st.stCSEM) && isfield(st.stCSEM,'transmitters')
        m1 = uimenu('Parent',m40,'Label','Transmitters','separator','on');
        uimenu(m1,'Label','Show Markers', 'tag','showTx',     'callback', {@chgVisCheck, hFig, 'transmitters'} );
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
        m1 = uimenu('Parent',m40,'Label','DC electodes','separator','on');
       
        uimenu(m1,'Label','Show Markers', 'tag','showDC',     'callback', {@chgVisCheck, hFig, 'dc_electrodes'},'checked',stSettings.showDC );
        m2 = uimenu(m1,'Label','Marker');   
        sub_addMarkerSubMenus(m2,hFig,'markerDC','dc_electrodes','marker');
        m2 = uimenu(m1,'Label','Marker Color'); 
        sub_addColorSubMenus(m2,hFig,'markerFaceColorDC','dc_electrodes','markerfacecolor');
        uimenu(m1,'Label','Marker Size', 'callback', {@setFigProperty, hFig, 'dc_electrodes','markersizeDC','markersize'} );
 
    end

end

set(findobj(hFig,'tag','showRxCSEM'),'checked',stSettings.showRxCSEM)
set(findobj(hFig,'tag','showRxMT')  ,'checked',stSettings.showRxMT) 
set(findobj(hFig,'tag','showTx')    ,'checked',stSettings.showTx) 

% Reset to defaults:
uimenu('Parent',m40,'Label','Reset all to MARE2DEM defaults','callback', {@sub_resetToDefaults, hFig}, 'separator', 'on'  );


% Set Anisotropy menu:
hObj = findobj(hFig,'tag','setAnisotropy');
c = {'isotropic','isotropic_ip','isotropic_complex','tix', 'tiy', 'tiz','triaxial'}; % ,'tiz_ratio'
set(hObj,'string',c) 
   

end % setUImenus

%--------------------------------------------------------------------------
% Menu callback function to rescale axis text & various fonts on the plot
function setFontSize(~,~,hFig)

    stSettings  = getappdata(hFig,'stSettings');
    
    prompt = sprintf('Enter font size:');
    dlg_title = 'Mamba2D:';
    num_lines = 1;
    def = {num2str(stSettings.fontSize)};
    answer = inputdlg(prompt,dlg_title,num_lines,def);
    if isempty(answer)
        return
    end
    
    stSettings.fontSize = str2double(answer{1});   
    set( gca, 'fontsize', stSettings.fontSize  );
    
    hTexts  = findobj(gcf,'tag','text','-or','tag','cb_text','-or','tag','xticks');
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
    dlg_title = 'Mamba2D: ';
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
    
end


%--------------------------------------------------------------------------
function sub_addMarkerSubMenus(mParent,hFig,sField,sTag,sProp)

stSettings  = getappdata(hFig,'stSettings');

sMarker = {
    'd' 
    'v' 
    'o'
    's'
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
   
    % now color them:  
    hObjs = findobj( hFig, 'tag', sTag );
    for i = 1:length(hObjs)
        if isprop(hObjs(i),sProp)
            set( hObjs(i), sProp,sMarker);
        else
            set( hObjs(i), 'marker',sMarker); % kludge...
        end
    end
    
end

%--------------------------------------------------------------------------
function setFigProperty(~,~,hFig,sTag,sField,sProp)

    stSettings  = getappdata(hFig,'stSettings');
    
    prompt = sprintf('Enter %s:',sProp);
    dlg_title = 'Mamba2D: ';
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
    
end

%--------------------------------------------------------------------------
% Menu callback function to change the visibility of some tagged items
function chgVisCheck(hObject,~, hFig, sTag)

stSettings  = getappdata(hFig,'stSettings');

hTag = findobj( hFig, 'tag', sTag);
check = get(hObject,'checked');

switch check
    case 'on'
        set(hTag , 'visible', 'off' );
        set(hObject,'checked','off');
        stSettings.(hObject.Tag) = 'off';
    case 'off'
        set(hTag , 'visible', 'on' );
        set(hObject,'checked','on');
        stSettings.(hObject.Tag) = 'on';
end

setappdata(hFig,'stSettings',stSettings);
sub_saveMRU(stSettings,hFig);

end


%--------------------------------------------------------------------------
function showNames(hObject,~, hFig, sTag)

hTag = findobj( hFig, 'tag', sTag );

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
     
    
    handles = guidata(hFig); 
    
    if ~isfield(handles,'st')
        return
    end
    st = handles.st;
    
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

uistack(findobj(hFig,'tag','csemRxNames'),'top');
uistack(findobj(hFig,'tag','mtRxNames'),'top');
uistack(findobj(hFig,'tag','txNames'),'top');

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
function selectFolder_Callback(hObject)
 
handles     = guidata(hObject);

% Select output folder folder(s):
startPath = handles.model.path;

path = uigetdir(startPath, 'Select output folder:');
if path==0
    return
end
set(findobj(handles.hFigure,'tag','outputfolder'),'string',sub_formatPathString(path));
set(findobj(handles.hFigure,'tag','outputfolder'),'tooltip',path,'enable','on');

handles.model.path = path;

guidata(hObject,handles);

end

%--------------------------------------------------------------------------
function loadData_Callback(hObject)
 
handles     = guidata(hObject);

curdir = pwd;
if isfield(handles.model,'path') && ~isempty(handles.model.path)
    path = handles.model.path; 
else
    path = pwd;
end
cd(path);

% Select the file(s):
[sFile,sFilePath]  = uigetfile( {'*.data;*.resp;*.emdata;*.dcdata'}, 'Select a MARE2DEM data or response file:' ,'MultiSelect', 'off');
if isnumeric(sFile) && sFile ==0
    disp('No files selected for plotting, returning...')
    cd(curdir);
    return
end
cd(curdir);


set( handles.hFigure, 'Pointer', 'watch' );
drawnow;

sFile = fullfile(sFilePath,sFile);

sub_loadDataFile(sFile,handles.hFigure) % saves to guidata

end

%--------------------------------------------------------------------------
function sub_loadDataFile(sFile,hFig)

handles     = guidata(hFig);

delete(findobj(handles.hFigure,'tag','csemsites'))
delete(findobj(handles.hFigure,'tag','mtsites'))
delete(findobj(handles.hFigure,'tag','transmitters'))
delete(findobj(handles.hFigure,'tag','dc_electrodes'))
    
%[st.UTM,st.stCSEM,st.stMT,st.DC,st.DATA] = m2d_readEMData2DFile(sFile);

stD = m2d_readEMData2DFile(sFile);

% If returned structure is empty, return:
if isempty(stD)
    return
end

% move stD's fields into st so we don't have to deal with too many nested structures 
st.stUTM  = stD.stUTM;
st.stCSEM = stD.stCSEM;
st.stMT   = stD.stMT;
st.stDC   = stD.stDC;
st.DATA   = stD.DATA;

handles.st = st;
 
% Add Rx,Tx and strings to GUI:
[~,n,e]=fileparts(sFile); 
set(findobj(handles.hFigure,'tag','datafile'),'string',[n e])

handles = sub_plotRxTx(handles);

guidata(hFig,handles);

stSettings  = getappdata(hFig,'stSettings');

sub_setUImenus(hFig,stSettings);
 
end
%--------------------------------------------------------------------------
% plots any Rx and Tx in handles.st
function handles = sub_plotRxTx(handles)

if ~isfield(handles,'st')
    return
end

stSettings  = getappdata(handles.hFigure,'stSettings');

st = handles.st;

delete(findobj(handles.hFigure,'tag','csemsites'))
delete(findobj(handles.hFigure,'tag','mtsites'))
delete(findobj(handles.hFigure,'tag','transmitters'))


% Plot sites:
if ~isempty(st.stCSEM) && isfield(st.stCSEM,'receivers')
    hRx = plot(st.stCSEM.receivers(:,2)/1d0,st.stCSEM.receivers(:,3)/1d0,...
        'linestyle','none',...
        'marker',stSettings.markerRxCSEM,...
        'markersize',stSettings.markersizeRxCSEM,...
        'markerfacecolor',stSettings.markerFaceColorRxCSEM,...
        'markeredgecolor',stSettings.markerEdgeColorRxCSEM,...
        'tag','csemsites','visible',stSettings.showRxCSEM);
     
end
if ~isempty(st.stMT) && isfield(st.stMT,'receivers')
    hRx = plot(st.stMT.receivers(:,2)/1d0,st.stMT.receivers(:,3)/1d0,...
        'linestyle','none',...
        'marker',stSettings.markerRxMT,...
        'markersize',stSettings.markersizeRxMT,...
        'markerfacecolor',stSettings.markerFaceColorRxMT,...
        'markeredgecolor',stSettings.markerEdgeColorRxMT,...
        'tag','mtsites','visible',stSettings.showRxMT);
    
end

% Plot transmitters:
if ~isempty( st.stCSEM) && isfield(st.stCSEM,'transmitters')
    hTx = plot( st.stCSEM.transmitters(:,2)/1d0, st.stCSEM.transmitters(:,3)/1d0,...
        'linestyle','none',...
        'marker',stSettings.markerTx,...
        'markersize',stSettings.markersizeTx,...
        'markerfacecolor',stSettings.markerFaceColorTx,...
        'markeredgecolor',stSettings.markerEdgeColorTx,...
        'tag','transmitters','markersize',5,'visible',stSettings.showTx);
  
end

% Plot DC electrodes:
if ~isempty( st.stDC) && isfield(st.stDC,'rx_electrodes') && isfield(st.stDC,'tx_electrodes')
    tt = [st.stDC.rx_electrodes(:,2) st.stDC.rx_electrodes(:,3); st.stDC.tx_electrodes(:,2) st.stDC.tx_electrodes(:,3)];
    tt = unique(tt,'rows');
    hTrodes = plot( tt(:,1), tt(:,2),...
        'linestyle','none',...
        'marker',stSettings.markerDC,...
        'markersize',stSettings.markersizeDC,...
        'markerfacecolor',stSettings.markerFaceColorDC,...
        'markeredgecolor',stSettings.markerEdgeColorDC,...
        'tag','dc_electrodes','visible',stSettings.showDC);
    
   
end

set(findobj(handles.hFigure,'tag','showRxCSEM'),'checked',stSettings.showRxCSEM)
set(findobj(handles.hFigure,'tag','showRxMT')  ,'checked',stSettings.showRxMT) 
set(findobj(handles.hFigure,'tag','showTx')    ,'checked',stSettings.showTx) 
set(findobj(handles.hFigure,'tag','showDC')    ,'checked',stSettings.showDC);
end

%--------------------------------------------------------------------------
% Menu callback function to change the visibility of some tagged items
function chgVis(~,~, hFig, sTag, sState)
    set( findobj( hFig, 'tag', sTag ), 'visible', sState );
end

%--------------------------------------------------------------------------
 function setIPFixedFree_Callback(hObject)

handles = guidata(hObject);

val = get(findobj(handles.hFigure,'tag','setAnisotropy'),'val');
str = get(findobj(handles.hFigure,'tag','setAnisotropy'),'string');
aniso = str{val};

if ~ismember(aniso,{'isotropic_ip';'isotropic_complex'})
    beep; disp('Model parameterization does not include IP, skipping');
    return
end
ifree = any(handles.model.freeparameter,2);
        
switch lower(aniso)
    case 'isotropic_ip'
        str = 'rho, eta, tau, c: free=1, fixed=0';
        defaultanswer = {'1 1 1 1'};
    case 'isotropic_complex'
        str = 'rho real, rho imaginary: free=1, fixed=0';
        defaultanswer = {'1 1'};        
end

options.Resize='on';
while 1
    answer = inputdlg(str,'Enter IP Settings:',1,defaultanswer,options);    
    if isempty(answer)
       return
    end

    vals = str2num(answer{1}); %#ok<ST2NM>

switch lower(aniso)
    case 'isotropic_ip'
        if  length(vals) ~=4
             h = errordlg(sprintf('Error, must enter four values: %g %g %g %g',vals));
            waitfor(h);   

        elseif any(~ismember(vals,[0 1]))
            h = errordlg(sprintf('Error, values should be 0 or 1: %g %g %g %g',vals));
            waitfor(h);

        else
            break
        end
    case 'isotropic_complex'
        if  length(vals) ~=2
             h = errordlg(sprintf('Error, must enter two values: %g %g',vals));
            waitfor(h);   

        elseif any(~ismember(vals,[0 1]))
            h = errordlg(sprintf('Error, values should be 0 or 1: %g %g',vals));
            waitfor(h);

        else
            break
        end     
end


end      

for i = 1:length(vals)
    handles.model.freeparameter(ifree,i) = vals(i); 
end

% Update plot:
sub_updateModelPlot(handles);  % saves h to guidata so no need to do that here again

          
end

 %--------------------------------------------------------------------------
 function setIPVals_Callback(hObject)

handles = guidata(hObject);

val = get(findobj(handles.hFigure,'tag','setAnisotropy'),'val');
str = get(findobj(handles.hFigure,'tag','setAnisotropy'),'string');
aniso = str{val};

if ~ismember(aniso,{'isotropic_ip';'isotropic_complex'})
    beep; disp('Model parameterization does not include IP, skipping');
    return
end

options.Resize='on';
ifree = any(handles.model.freeparameter,2);
str2 = '';
defaultanswer2 = '';

switch lower(aniso)
    
    case 'isotropic_ip' 
        str = sprintf('Free parameter eta, tau, C, ie: 0.1,0.1,0.1 \n Use -1 to not change a value.');
        defaultanswer = {'0.1 0.1 0.1'};        
        str2 = sprintf('Prejudice and weights for eta,tau,C: i.e., 0 1 0 1 0 1\n Use -1 to not change a value.');
        defaultanswer2 = {'0 1 0 1 0 1'};  
        
    case 'isotropic_complex'
        str = sprintf('Bulk set imaginary resistivity as X*real (e.g. set to 1d-6 to make it a million times smaller than real resistivity)');
        defaultanswer = {'1d-6'}; 
        str2 = sprintf('Prejudice and weight for imaginary rho: i.e., 1d-6 1 for minimizing imag(rho)  \n Use -1 to not change a value.');
        defaultanswer2 = {'0 0'};  
end


while 1
    
    ss = {str str2};
    df = {defaultanswer{:} defaultanswer2{:}};
    answer = inputdlg(ss,'Enter IP Settings:',1,df,options);

    
    if isempty(answer)
       return
    end

    vals = str2num(answer{1}); %#ok<ST2NM>

    switch lower(aniso)

        case 'isotropic_ip' 

        if length(vals) == 3

            if (vals(1) >= 0) 
                handles.model.resistivity(ifree,2) = vals(1);
            end
            if (vals(2) >= 0) 
                handles.model.resistivity(ifree,3) = vals(2);
            end
            if (vals(3) >= 0) 
                handles.model.resistivity(ifree,4) = vals(3);
            end
        end


        case 'isotropic_complex'
            
            if length(vals) == 1 && (vals(1) > 0) 
                handles.model.resistivity(ifree,2) = vals(1)*handles.model.resistivity(ifree,1);
            end         
    
    end

    vals2 = str2num(answer{2}); %#ok<ST2NM>

    if ~isempty(vals2)
        
        switch lower(aniso)

            case 'isotropic_ip' 

            if length(vals2) == 6
                
                for i = 1:3
                    % prejudice:
                    if (vals2(2*i-1) >= 0) % 1,3,5
                        handles.model.prejudice(ifree,2*i+1) = vals2(2*i-1); % 3,5,7
                    end
                    % weights:
                    if (vals2(2*i) >= 0) % 2,4,6
                        handles.model.prejudice(ifree,2*i+2) = vals2(2*i);  %4,6,8
                    end                
                end
            end
            
            case 'isotropic_complex'
            
                if length(vals2) == 2
                    % prejudice:
                    handles.model.prejudice(ifree,3) = vals2(1);
                     % weights:
                    handles.model.prejudice(ifree,4) = vals2(2);  
                end         

        end   
    end
    
    break
  
end

% Update plot:
sub_updateModelPlot(handles);  % saves h to guidata so no need to do that here again

                
 end

%--------------------------------------------------------------------------
function sub_print(hObject,~,hFig)
    
    handles = guidata(hFig);
    
    sBaseFile = strtrim(get(findobj(handles.hFigure,'tag','filenameroot'),'string'));  
    
    str = '';
    if ~isempty(sBaseFile)
        str = sprintf('%s',sBaseFile);
    end
    [file, path ] = uiputfile({'*.eps';'*.pdf';'*.png'},' Save plotMARE2DEM figure as',str);
    if file==0
        return
    end
    [~, n, e] = fileparts(file);
    
    sFile = fullfile(path,n);
    
    set(hFig, 'Pointer', 'watch' ); drawnow;
    
    if strcmpi(e,'.pdf')
        ext = 'pdf';
    else
        ext = 'eps';
    end
    
    % Prepared Mamba2D figure for printing properly:
    
    % (1) Make a copy of the figure object and work on that:
    hFigPrint = copyobj(hFig, groot);
    set(hFigPrint,'visible','off');
    
    % (2) Delete all UI objects:
    delete(findobj(hFigPrint,'type', 'uibuttongroup'));
    delete(findobj(hFigPrint,'type', 'uicontrol'));
    
    % (3) Adjust model axes and figure size:
    sshh = get(0,'showhiddenhandles');  % leave this set to ON!
    set(0,'showhiddenhandles','on'); % leave this set to ON!
    set(hFigPrint,'units','pixels');
    set(gca,'units','pixels');
    hcb = findobj(hFigPrint,'tag','Colorbar');
    set(hcb,'units','pixels');
    
    axp = get(gca,'outerposition');
    fgp = get(hFigPrint,'position');
    cbpos = get(hcb,'Position');
    
    newFigpos = [0 0 fgp(3)-axp(1)+cbpos(3)+20 fgp(4)-axp(2)+20];
    set(hFigPrint,'position',newFigpos)
    set(gca,'outerposition',[20 20 axp(3:4)])
 
    set(0,'showhiddenhandles','on');  % leave this set to ON!
    
    % Print it:
    if strcmpi(e,'.png')
        
        set(hFigPrint,'paperunits','points','units','points')
        pos = get(hFigPrint,'outerposition');
        set(hFigPrint,'paperposition',[0 0 pos(3:4)]);
        print(hFigPrint,file,'-dpng','-r300','-noui')
    else
          
        % Use vecrast to save surface as bitmap and annotations in vector format.
        vecrast(hFigPrint, sFile, 0, 'bottom', ext);
    end
    delete(hFigPrint);
    
    drawnow;
    
    % Display message:
    str = [n e];
    h = helpdlg(sprintf('Done saving image to file  %s', str),'Mamba2D Message:');
    set(h,'windowstyle','modal');
    uiwait(h)  
    
    set(hFig, 'Pointer', 'arrow' );
    
end

function Roughness_Callback(hObject, eventdata, handles)
    % === Roughness按钮核心回调：计算粗糙度+保存参数到GUI ===
    % 1. 从GUI的handles里提取现成的模型数据（不用读文件）
    if ~isfield(handles, 'model') || isempty(handles.model.nodes)
        errordlg('请先导入/创建模型，再计算粗糙度！','错误','modal');
        return;
    end
    
    model = handles.model;
    rho = model.resistivity;               % 电阻率模型
    nodes = model.nodes;                   % 节点坐标
    elements = model.DT.ConnectivityList;  % 三角网格单元
    neighbors = neighbors(model.DT);       % 单元相邻关系（MATLAB自带方法，不用额外计算）
    
    % 2. 提取惩罚截断线段（Penalty Cut，和原Mamba2D完全兼容）
    penalty_segs = [];
    if isfield(model, 'segments')
        [i,j] = find(model.segments == -1); % 标记为-1的就是惩罚截断线段
        penalty_segs = [i,j];
    end
    
    % 3. 调用你Roughness文件夹里的核心函数
    try
        [roughness_total, calc_time] = Roughness(rho, nodes, elements, neighbors, penalty_segs);
    catch ME
        errordlg(sprintf('粗糙度计算失败：%s', ME.message),'错误','modal');
        return;
    end
    
    % 4. 读取界面上的粗糙度权重参数（和你汉化的界面输入框对应）
    % 注意：这里的tag要和你界面上的输入框tag完全一致！
    y_weight = str2double(get(findobj(handles.hFigure,'tag','yRoughnessWeight'),'string'));
    z_weight = str2double(get(findobj(handles.hFigure,'tag','zRoughnessWeight'),'string'));
    cut_weight = str2double(get(findobj(handles.hFigure,'tag','penaltyCutWeight'),'string'));
    
    % 容错处理：如果输入框为空，用默认值
    if ~isfinite(y_weight), y_weight = 3; end
    if ~isfinite(z_weight), z_weight = 1; end
    if ~isfinite(cut_weight), cut_weight = 0.1; end
    
    % 5. 把参数和结果存入handles，供写入文件调用
    handles.roughness = struct();
    handles.roughness.total = roughness_total;
    handles.roughness.yzWeights = [y_weight, z_weight];
    handles.roughness.cutWeight = cut_weight;
    handles.roughness.penaltySegs = penalty_segs;
    guidata(hObject, handles); % 必须更新GUI数据，否则写入文件拿不到
    
    % 6. 结果展示
    msgbox(sprintf('模型粗糙度计算完成！\n总粗糙度：%.4f\n计算耗时：%.2f秒', roughness_total, calc_time), '计算完成');
    fprintf('=== 粗糙度计算结果 ===\n总粗糙度：%.4f\n水平权重：%.2f\n垂直权重：%.2f\n惩罚截断权重：%.2f\n', ...
        roughness_total, y_weight, z_weight, cut_weight);


    function calcRoughnessBtn_Callback(hObject, eventdata)
% === 粗糙度计算按钮的核心功能 ===
% 1. 安全获取GUI数据
try
    handles = guidata(hObject);
catch ME
    errordlg(sprintf('无法获取GUI数据：%s', ME.message), '错误', 'modal');
    return;
end

% 2. 逐层检查数据，避免报错
if ~isstruct(handles) || ~isfield(handles, 'model')
    errordlg('请先导入/创建模型！', '错误', 'modal');
    return;
end
if ~isstruct(handles.model) || isempty(handles.model.nodes) || ~isfield(handles.model, 'DT')
    errordlg('请先点击「三角网格」生成网格！', '错误', 'modal');
    return;
end

% 3. 提取模型数据
model = handles.model;
rho = model.resistivity;
nodes = model.nodes;
elements = model.DT.ConnectivityList;

% 4. 获取网格相邻关系
try
    neighbors = neighbors(model.DT);
catch ME
    errordlg(sprintf('无法获取网格相邻关系：%s', ME.message), '错误', 'modal');
    return;
end

% 5. 提取惩罚截断线段
penalty_segs = [];
if isfield(model, 'segments') && ~isempty(model.segments)
    try
        [i,j] = find(model.segments == -1);
        penalty_segs = [i,j];
    catch
        penalty_segs = [];
    end
end

% 6. 调用粗糙度计算函数
try
    [roughness_total, calc_time] = Roughness(rho, nodes, elements, neighbors, penalty_segs);
catch ME
    errordlg(sprintf('粗糙度计算失败！\n\n错误原因：%s\n\n错误位置：%s (第%d行)', ...
        ME.message, ME.stack(1).name, ME.stack(1).line), ...
        '计算错误', 'modal');
    return;
end

% 7. 结果展示
msgbox(sprintf('当前模型粗糙度计算完成！\n\n总粗糙度：%.4f\n计算耗时：%.2f秒', roughness_total, calc_time), '计算完成');
fprintf('\n=== 粗糙度计算结果 ===\n');
fprintf('总粗糙度：%.4f\n', roughness_total);
fprintf('计算耗时：%.2f秒\n', calc_time);
fprintf('========================\n\n');
end

end

function pushbutton13_Callback(hObject)
    addHoriz_Callback(hObject);
end

