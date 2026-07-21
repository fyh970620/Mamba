function varargout = plotMARE2DEM_MT(varargin)
%
% GUI for plotting MT data and model response files for MARE2DEM
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

%
% Begin initialization code - DO NOT EDIT
gui_Singleton = 0;
gui_State = struct('gui_Name',       mfilename, ...
    'gui_Singleton',  gui_Singleton, ...
    'gui_OpeningFcn', @plotMARE2DEM_MT_OpeningFcn, ...
    'gui_OutputFcn',  @plotMARE2DEM_MT_OutputFcn, ...
    'gui_LayoutFcn',  [] , ...
    'gui_Callback',   []);
if nargin==1  && ischar(varargin{1}) % call with .resistivity file input only
    % don't str2func...
else
    if nargin && ischar(varargin{1})
        gui_State.gui_Callback = str2func(varargin{1});
    end
end
 
if nargout
    [varargout{1:nargout}] = gui_mainfcn(gui_State, varargin{:});
else
    gui_mainfcn(gui_State, varargin{:});
end
% End initialization code - DO NOT EDIT
end

%--------------------------------------------------------------------------
% --- Executes just before plotMARE2DEM_MT is made visible.
function plotMARE2DEM_MT_OpeningFcn(hObject, ~, handles, varargin)
% This function has no output args, see OutputFcn.
% hObject    handle to figure
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)
% varargin   command line arguments to plotMARE2DEM_MT (see VARARGIN)

% Choose default command line output for plotMARE2DEM_MT
handles.output = hObject;


set(findall(hObject,'tag','Standard.SaveFigure'),'enable','off');
set(findall(hObject,'tag','figMenuFileSave'),'enable','off');

% Magic numbers:
handles = sub_GetDefaults(handles);

% Get most recently used USER values:
handles = sub_getMRU(handles);

% Set 
if strcmpi(handles.sFreqAxisScale,'period')
    set(handles.freqAxisType,'value',1);
else
   set(handles.freqAxisType,'value',2); 
end

%-----------------%
% Appearance Menu %
%-----------------%
hFig = handles.figure1;
m40 =  uimenu(hFig,'Label','Appearance');

m10 = uimenu('Parent',m40,'Label','Model Response Color');
uimenu(m10,'Label','Same as data',  'callback', {@setModelResponseColor, hFig,'data'});
uimenu(m10,'Label','Black ',        'callback', {@setModelResponseColor, hFig,'k'});
uimenu(m10,'Label','Medium Gray  ',        'callback', {@setModelResponseColor, hFig,[0.5 0.5 0.5]});
uimenu(m10,'Label','Light Gray  ',        'callback', {@setModelResponseColor, hFig,[0.7 0.7 0.7]});

% Colormap control:
m10 = uimenu('Parent',m40,'Label','Line Colormap ');
uimenu(m10,'Label','Lines',  'callback', {@setColorMapLines, hFig,'lines'});
uimenu(m10,'Label','Jet',    'callback', {@setColorMapLines, hFig,'jet'} );
uimenu(m10,'Label','Hsv',    'callback', {@setColorMapLines, hFig,'hsv'} );
uimenu(m10,'Label','Prism',  'callback', {@setColorMapLines, hFig,'prism'}); 
uimenu(m10,'Label','Parula', 'callback', {@setColorMapLines, hFig,'parula'}); 
 
% Colormap control:
mCm = uimenu('Parent',m40,'Label','Matrix Colormap ');
%uimenu(mCm,'Label','Invert Colormap','callback', {@sub_setColorMap, hFig,'invert'},'tag','uimenu_cm');
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

m10 = uimenu('Parent',m40,'Label','Marker');
uimenu(m10,'Label','o',        'callback', {@setField, hFig,'marker','o'} );
uimenu(m10,'Label','+',        'callback', {@setField, hFig,'marker','+'} );
uimenu(m10,'Label','square',   'callback', {@setField, hFig,'marker','square'});
uimenu(m10,'Label','diamond',  'callback', {@setField, hFig,'marker','diamond'}); 

m10 = uimenu('Parent',m40,'Label','Marker Size');
uimenu(m10,'Label','larger',   'callback', {@setField, hFig,'markerSize','larger'} );
uimenu(m10,'Label','smaller',  'callback', {@setField, hFig,'markerSize','smaller'} );

m10 = uimenu('Parent',m40,'Label','Line Width');
uimenu(m10,'Label','thicker',   'callback', {@setField, hFig,'lineWidth','thicker'} );
uimenu(m10,'Label','thinner',   'callback', {@setField, hFig,'lineWidth','thinner'} );

m10 = uimenu('Parent',m40,'Label','Font Size');
uimenu(m10,'Label','larger',   'callback', {@setField, hFig,'fontSize','larger'} );
uimenu(m10,'Label','smaller',  'callback', {@setField, hFig,'fontSize','smaller'} );

uimenu('Parent',m40,'Label','Reset To Defaults', 'callback', {@sub_ResetDefaults, hFig'});

m40 =  uimenu('Label','Survey Geometry');
uimenu(m40,'Label','Map',                    'callback', {@plotSurveyMap, hFig, 'map'} );
uimenu(m40,'Label','Receiver Parameters',    'callback', {@plotSurveyMap, hFig, 'rx'} );
uimenu(m40,'Label','Transmitter Parameters',    'callback', {@plotSurveyMap, hFig, 'tx'} );

% Update handles structure
guidata(hObject, handles);

if ~isempty(varargin) && length(varargin)==1
    callFromExternal(varargin{1},hObject);
end

end

%--------------------------------------------------------------------------
function plotSurveyMap(~,~,hFig,sType)

handles = guidata(hFig);

if isempty(handles.st)
    return
end
handles.st.dataFile = handles.st.sFile;

% Call external routine:
plotMARE2DEM_SurveyLayout(sType,handles.st);
 
end


%--------------------------------------------------------------------------
function handles = sub_GetDefaults(handles)

    handles.sColorMap       = 'parula';
    handles.sLineColorMap   = 'lines';
    handles.fontSize        = 14; 
    handles.marker          = 'o';
    handles.lineWidth       = 1;
    handles.markerSize      = 4;
    handles.sModelResponseColor = 'data'; %'data' uses data colors, 'k' is black
    handles.sFreqAxisScale  = 'period'; % frequency or period
    handles.nGridPlotLimit = 100;   % plot up to this many stations on grid plot. 100 works well on my desktop. 
    
end

 %--------------------------------------------------------------------------
function handles = sub_ResetDefaults(~,~,hFig)
    
    handles = guidata(hFig);

    handles = sub_GetDefaults(handles);
    
    sub_saveMRU(handles);
     
    handles = plot_Callback(hFig, hFig, handles);
 
    guidata(hFig, handles);

    
end   
          
%--------------------------------------------------------------------------
function handles = sub_getMRU(handles)

    % Make the name of the mat file that holds the MRU
    [p, f] = fileparts( mfilename('fullpath') );
    sMRU = fullfile( p, [f '.mru'] );
    
    % If it exists, load it
    if exist( sMRU, 'file' )
        a = load( sMRU, '-mat');
        if ~isempty(a)
            handles.sColorMap       = a.sColorMap;
            handles.sLineColorMap   = a.sLineColorMap;
            handles.fontSize        = a.fontSize;
            handles.marker          = a.marker; 
            handles.lineWidth       = a.lineWidth; 
            handles.markerSize      = a.markerSize;   
            if isfield(a,'sModelResponseColor')
                handles.sModelResponseColor = a.sModelResponseColor;
            end
            if isfield(a,'sFreqAxisScale')
                handles.sFreqAxisScale = a.sFreqAxisScale;
            end               
        end
    end
    
    if strcmpi(handles.sFreqAxisScale,'period')
        set(handles.freqAxisType,'value',1);
    else
        set(handles.freqAxisType,'value',2);
    end    
    
end
%--------------------------------------------------------------------------
function sub_saveMRU(handles)

    % Make the name of the mat file that holds the MRU
    [p, f] = fileparts( mfilename('fullpath') );
    sMRU = fullfile( p, [f '.mru'] );

    sColorMap       = handles.sColorMap;
    sLineColorMap   = handles.sLineColorMap;
    fontSize        = handles.fontSize;
    marker          = handles.marker; 
    lineWidth       = handles.lineWidth; 
    markerSize      = handles.markerSize;         
    sModelResponseColor = handles.sModelResponseColor;
    sFreqAxisScale  = handles.sFreqAxisScale;
       
    % Save it, replacing any existing:
    save(sMRU, '-mat', ...
        'sColorMap',...
        'sLineColorMap',...
        'fontSize',...
        'marker',...
        'lineWidth',...
        'markerSize',...
        'sModelResponseColor',...
        'sFreqAxisScale');
        
end


%--------------------------------------------------------------------------
function setField(~,~,hFig,sField,sValue)

handles = guidata(hFig);

if strcmpi(sValue,'larger') || strcmpi(sValue,'thicker')
    sValue = handles.(sField) + max(1,handles.(sField)*0.1);
elseif strcmpi(sValue,'smaller') || strcmpi(sValue,'thinner')
    sValue = handles.(sField) - max(1,handles.(sField)*0.1);
end
if isnumeric(sValue)
    sValue = max(sValue,1); % Don't let it go to zero
end
handles.(sField) = sValue;

sub_saveMRU(handles);

handles = plotType_Callback(hFig, hFig, handles);

guidata(hFig, handles);

sub_saveMRU(handles);

end

%--------------------------------------------------------------------------
% --- Outputs from this function are returned to the command line.
function varargout = plotMARE2DEM_MT_OutputFcn(~, ~, handles)
% varargout  cell array for returning output args (see VARARGOUT);
% hObject    handle to figure
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)

% Get default command line output from handles structure
if ~isempty(handles)
    varargout{1} = handles.output;
end
end

  
 

%--------------------------------------------------------------------------
% --- Executes on button press in pushbutton1.
function loadFile_Callback(hObject, ~, handles) 
% hObject    handle to pushbutton1 (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)


% Select the file(s):
[sFile,sFilePath]  = uigetfile( {'*.data;*.resp;*.emdata;'}, 'Select a MARE2DEM data or response file:' ,'MultiSelect', 'on');
if isnumeric(sFile) && sFile ==0
    disp('No files selected for plotting, returning...')
    return
end

if iscell(sFile)
    lf = length(sFile);
else
    lf = 1;
end

set( handles.figure1, 'Pointer', 'watch' );
drawnow;

for i = 1:lf
    
    if ~iscell(sFile)
        thisFile     = sFile;
    else
        thisFile     = sFile{i};
    end
    
    % Read in the file:
    [handles, sMsg] = sub_loadAFile(handles,sFilePath,thisFile);
    
end

% Did we actually import anything?
if strcmpi(sMsg,'nodata')
    h = warndlg('No MT responses found, skipping!','Error','modal') ;
    waitfor(h)
    set( handles.figure1, 'Pointer', 'arrow' );        % progress pointer 
    return
elseif strcmpi(sMsg,'incompatible')
    set( handles.figure1, 'Pointer', 'arrow' );        % progress pointer 
    return
end

 
handles = sub_updateEverything(handles,hObject);

set( handles.figure1, 'Pointer', 'arrow' );        % progress pointer 

end

%--------------------------------------------------------------------------
function   handles = sub_updateEverything(handles,hObject)

% Update GUI components:
handles = sub_updateGUIComponents(handles);

% Receivers:
handles = sub_updateReceivers(handles);

% Update the plot:
handles = plotType_Callback(hObject, [], handles);

% Store data back into gui:
guidata(hObject, handles);


end

%--------------------------------------------------------------------------
function   handles = callFromExternal(filename,hObject) 

filename = m2d_getMostRecent(filename,'*.resp');

if isempty(filename)
    h = warndlg('Error, no MARE2DEM data file was found!','Error','modal') ;
    waitfor(h)
    close(hObject)
    return
end

[filepath, n, e] = fileparts(filename);
filename = strcat(n,e);
handles = guidata(hObject);
handles = sub_loadAFile(handles,filepath,filename);

% Did we actually import anything?
if ~isfield(handles,'st')
    h = warndlg('No MT data found in data file!','Error','modal') ;
    waitfor(h)
    close(hObject)
    return
end

handles = sub_updateEverything(handles,hObject);

end

%--------------------------------------------------------------------------
function [handles,sMsg] = sub_loadAFile(handles,filepath,filename)

st   = m2d_readEMData2DFile(fullfile(filepath,filename));

st.sFile        = filename;
st.sPath        = filepath;
st.bWaslog10    = false; % keep track of log10 amplitude data converted to linear 

% See if there's any MT data, if not skip:
if ~isfield(st.stMT,'receivers') ||  ~any(st.DATA(:,1) > 100 & st.DATA(:,1) < 140) % i.e. no MT responses (but possibly raw fields)
    sMsg = 'nodata';
    return
end

% If file has Real/Imaginary data formats, convert them to amplitude and
% phase:
st = convertRealImagToAmpPhs(st);

% If file has log10Amplitude data, convert it to amplitude:
st = convertlog10AmpToAmp(st);


% Make sure phases are within +-180 range:
lPhase = st.DATA(:,1) == 104 | st.DATA(:,1) == 106;
phase = st.DATA(lPhase,5);
lFlip = phase > 180;
phase(lFlip) = phase(lFlip) - 360;
lFlip = phase < -180;
phase(lFlip) = phase(lFlip) + 360;
st.DATA(lPhase,5) = phase;

if size(st.DATA,2) == 8
    phase = st.DATA(lPhase,7);
    lFlip = phase > 180;
    phase(lFlip) = phase(lFlip) - 360;
    lFlip = phase < -180;
    phase(lFlip) = phase(lFlip) + 360;
    st.DATA(lPhase,7) = phase;       
end

% Remap magnetic only receivers to corresponding E receivers when parallel
% E receivers separate from horizontal H receivers.  
lTipper      = st.DATA(:,1) >= 133 & st.DATA(:,1) <= 136;
lMTnontipper = st.DATA(:,1) >  100 & st.DATA(:,1) <  200 & ~lTipper;
[iRxTipper,~,ind] = unique(st.DATA(lTipper,4));
iRxNonTipper      = unique(st.DATA(lMTnontipper,4));

iRxTipperToNonTipper = zeros(size(iRxTipper));
if ~isempty(iRxTipperToNonTipper)
    for i = 1:length(iRxTipper)
        [lis,iis] = ismember(st.stMT.receivers(iRxTipper(i),1:3),st.stMT.receivers(iRxNonTipper,1:3),'rows');

        if lis
            iRxTipperToNonTipper(i) = iRxNonTipper(iis);
        else
            iRxTipperToNonTipper(i) = iRxTipper(i);
        end
    end
    st.DATA(lTipper,4) = iRxTipperToNonTipper(ind);
end

% Remove receivers that aren't used in st.DATA. This can be both
% extraneous receivers, but also the duplicate receivers used for
% horizontal B's (paired with slope parallel E's). Those duplicate
% receivers are only listed in the Tx column (for computing Z =
% E_parallel/H_horizontal).
lMT = st.DATA(:,1) > 100 & st.DATA(:,1) < 200;
iRx_used = unique(st.DATA(lMT,4)); % unique list of all Rx's used.
iRx_old_to_new(iRx_used) = 1:length(iRx_used);
st.stMT.receivers        = st.stMT.receivers(iRx_used,:);
st.stMT.receiverName     = st.stMT.receiverName(iRx_used);
iRx                      = st.DATA(lMT,4);
st.DATA(lMT,4)           = iRx_old_to_new(iRx); % remap to new Rx subset.


% Set dummy data to infinity
iNoData = st.DATA(:,5) == 0 & st.DATA(:,6) ==0 ;  
st.DATA(iNoData,5) = nan;
st.DATA(iNoData,6) = nan;


% Load in .flagged.mat file if available, otherwise initialize
% flagged array:
sFile = fullfile(filepath,sprintf('%s.flagged.mat',filename));
if exist(sFile,'file')
    % Ask user if they want to load this file:
    choice = questdlg('A data flag file exists, shall I use it?', ...
	'Data Flag File Detected', ...
	'Yes','No','Yes');
    if strcmpi(choice,'Yes')
        load(sFile);
    end
end    

% Check to make sure this iFlagged is of same size as current data array,
% just in case something has changed in the data file after the .flagged
% file was written:
 
if exist('iFlagged','var') && length(iFlagged) == size(st.DATA,1)
    st.iFlagged = iFlagged;
else
    st.iFlagged = false(size(st.DATA,1),1);
end

%
% Create data arrays that make plotting easier and faster:
%
st = sub_createFastArrays(st);


if isfield(handles,'st') && ~isempty(handles.st)
    
    % Check that new data file is compatible (same Rx,Tx,Freqs) as
    % existing:
    lMT = handles.st(1).DATA(:,1) > 100 & handles.st(1).DATA(:,1) < 200;
    lMTnew = st(1).DATA(:,1) > 100 & st(1).DATA(:,1) < 200;
    if   size(handles.st(1).DATA(lMT,:),1) ~= size(st.DATA(lMTnew,:),1) || ...
         size(handles.st(1).stMT.frequencies,1) ~= size(st.stMT.frequencies,1)
         sMsg = 'incompatible';
         waitfor(errordlg('Data file is not compatible with data already loaded.\n Needs same frequencies, receivers, number of data.','Error','modal'))
         return; 
         
    elseif ~all(all((handles.st(1).DATA(lMT,[1 2 4]) == st.DATA(lMTnew,[1 2 4])))) || ... % n.b. skipping Tx column for hybrid horizontal H used with titled Ey
            any(handles.st(1).stMT.frequencies(:) ~= st.stMT.frequencies(:))
        waitfor(errordlg('Data file is not compatible with data already loaded.\n Needs same frequencies, receivers, number of data.','Error','modal'))
        sMsg = 'incompatible';
        return; 
        
    end
    
    n = length(handles.st);
    handles.st(n+1) = st;
 
else
    
    handles.st = st;
end

% If file has a lot of receivers, switch plot type to pseudosection or profile
% since grid plot will be painfully slow:
if size(st.stMT.receivers,1) > 50
    
    % if only a few frequecies, use profile plot, else pseudosection:
    if length(st.stMT.frequencies) < 3 
       str =  'Profile plot';
    else
       str = 'Pseudosection';
    end
    
    h = findobj(handles.figure1,'tag','plotType');
    for i = 1:length(h.String)
        if strcmpi(h.String{i},str)
            h.Value = i;
            break;
        end
    end
   
end



sMsg = 'aokay';

end

%--------------------------------------------------------------------------
function  st = sub_createFastArrays(st)
 
% Creates an array useful for faster data plotting:

 
Cmps = unique(st.DATA(:,1));

% here only get MT data:
Cmps = Cmps(Cmps>=100);

nRx =  size(st.stMT.receivers,1);
nFq = size(st.stMT.frequencies,1);

indRx = st.DATA(:,4); % easy case Rx are Rx!

for i = 1:length(Cmps)
    
    st.Cmps(i).Cmp   = Cmps(i);
    st.Cmps(i).d     = nan(nRx,nFq); % data
    st.Cmps(i).e     = nan(nRx,nFq); % uncertainty
    st.Cmps(i).m     = nan(nRx,nFq); % model response
    st.Cmps(i).r     = nan(nRx,nFq); % normalized residual
    st.Cmps(i).iData = nan(nRx,nFq); % index to DATA array 
 
    
    for iFq = 1:nFq
        
        lCmp = st.DATA(:,1) == Cmps(i) & st.DATA(:,2) == iFq;
        
        if any(lCmp)
            
          
            iRx  = indRx(lCmp);
            ind  = sub2ind(size(st.Cmps(i).d ),iRx,iFq*ones(size(iRx)));
            
            st.Cmps(i).d(ind)   = st.DATA(lCmp,5);
            st.Cmps(i).e(ind)   = st.DATA(lCmp,6);
            st.Cmps(i).iRx(ind) = st.DATA(lCmp,4); 
            st.Cmps(i).iData(ind) = find(lCmp);
            if size(st.DATA,2) >= 8
                st.Cmps(i).m(ind) = st.DATA(lCmp,7);
                st.Cmps(i).r(ind) = st.DATA(lCmp,8);
            end
            
        end 
    end  
end

%
% Set some flags for this file:
%
 st.lHasData = true;
if all(st.DATA(:,5) == 0) || all(~isfinite(st.DATA(:,5)))
    st.lHasData = false;
end
st.lHasModelResponse = false;
if size(st.DATA,2) >= 8
    if any(st.DATA(:,7) ~= 0) || any(isfinite(st.DATA(:,7)))
        st.lHasModelResponse = true;
    end
end

end
%--------------------------------------------------------------------------
function hColors  = sub_setColors(hd,hColors,iMode,lineColors)

if isempty( hColors{iMode})

    nC = 0;
    for i = 1:length(hColors)
        if ~isempty( hColors{i})
            nC = nC + size(hColors{i},1);
        end
    end
 
    hColors{iMode} = lineColors(nC+1:nC+length(hd),:);
 

end

% Now apply colors:
for i = 1:length(hd)
    hd(i).Color           = hColors{iMode}(i,:);
    hd(i).MarkerFaceColor = hColors{iMode}(i,:);
end

    
    

end
%--------------------------------------------------------------------------
function   handles = sub_updateGUIComponents(handles)

% File listbox:
sNames = {handles.st.sFile };
set(handles.fileListbox,'string',sNames,'value',length(sNames));

% Frequency listbox:
sF ={};
if ~isempty(handles.st) && isfield(handles.st,'stMT') 
    freqs =   handles.st(1).stMT.frequencies; 
    sF = num2cell(freqs);
end
set(handles.frequencyListbox,'string',sF,'value',1:length(sF));
    
% Data components:
handles.sComponents = sub_getDataComponents(handles);

iTipper = find(strcmpi(handles.sComponents,'Mzy (TE)'));
val = 1:length(handles.sComponents);

% if apres and tipper, default to apres plotting:
if length(val) > 1 && any(iTipper)
    val (iTipper) = [];
end
set(handles.componentsListbox,'string',handles.sComponents,'value',val)



% Update plot type options:
if ~isempty(handles.st)
    
    nRx = size(handles.st(1).stMT.receivers,1);

    if handles.st(1).lHasData && handles.st(1).lHasModelResponse

        if nRx > 1
            handles.plotType.String = { 'Grid plot' 'Single plot' 'Profile plot' 'Pseudosection' 'Misfit breakdown'};%  'Uncertainty %'}; %everything
        else
            handles.plotType.String = { 'Grid plot' 'Single plot' 'Misfit breakdown' };% 'Uncertainty %'}; % no matrix plotting
        end
        
    else % only has data or only has model response:

        % KWK debug: code will be udpated to include 'Uncertainty %' option
        % in the future but commenting out to eliminate the editor's
        % suggestions & warnings

        if  nRx > 1
            %if handles.st(1).lHasData % data but no model response:
                handles.plotType.String =  { 'Grid plot' 'Single plot' 'Profile plot' 'Pseudosection' };% 'Uncertainty %' }; % lines and matrix
            %else % only model response:
            %    handles.plotType.String = { 'Grid plot' 'Single plot' 'Profile plot' 'Pseudosection' };% lines and matrix
            %end
                    
    

        else % only one receiver
            %if handles.st(1).lHasData
                handles.plotType.String = {'Grid plot' 'Single plot'};%  'Uncertainty %' }; % lines only
            %else
            %   handles.plotType.String = {'Grid plot' 'Single plot'  }; % lines only 
            %end
        end
        
    end

end


end


%--------------------------------------------------------------------------
function handles = sub_updateReceivers( handles)

%  ***Assumes that all st().stMT have same receiver array***

sRx ={};

if ~isempty(handles.st)
   
    rx = handles.st(1).stMT.receivers(:,2);

    for i = length(rx):-1:1    
        sRx{i} =  sprintf('%6.1f m %s ',rx(i),handles.st(1).stMT.receiverName{i}  );  
    end       
end

set(handles.receiverListbox,'listboxtop',1);
set(handles.receiverListbox,'string',(sRx),'value',1:length(sRx));


end

%--------------------------------------------------------------------------
function unloadFiles_Callback(hObject, eventdata, handles) 
% hObject    handle to pushbutton2 (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)

selected = get(handles.fileListbox,'value');

if isempty(selected) || ~isfield(handles,'st') || isempty(handles.st)
    return
end

% Update the listbox:
handles.st(selected) =[];
sNames = {handles.st.sFile };
set(handles.fileListbox,'string',sNames,'value',max(0,size(sNames,1)));

% Store data back into gui:
guidata(hObject, handles);


% turn off the brush data if on:
brush off;
hID = findall(handles.figure1,'tag','dataID');

hh = hID(isprop(hID,'BrushData'));
set(hh,'BrushData',[]);

set(findobj(handles.figure1,'tag','brushData'),'BackgroundColor',[0.929412 0.929412 0.929412]);

% refresh plot:
handles = sub_updateGUIComponents(handles);
handles = sub_updateReceivers(handles);
handles = sub_setShowButtons(handles,'on'); 
handles = updateRMS(handles);
handles = plot_Callback(hObject, eventdata, handles);



% Store data back into gui:
guidata(hObject, handles);

end
 
 
% -------------------------------------------------------------------------
function handles = brushData_Callback(hObject, ~, handles)

 h = brush(handles.figure1);
 
 % Only allowing brushing when single data file is plotted:
 iFiles = handles.fileListbox.Value;

 if strcmpi(get(h,'enable'),'off')
    if length(iFiles)>1
        beep;
        errordlg('Please select a single data file first!',' Error:','modal');
        return
     end    
     brush on;
     set(h,'color',[1 0 0]); %[1 0 1])
     set(hObject,'backgroundcolor',[0 1 0]);
 else
     brush off;
     hID = findall(handles.figure1,'tag','dataID');
     hh  = hID(isprop(hID,'BrushData'));
     set(hh,'BrushData',[]);
     hID = findall(handles.figure1,'tag','errorBar');
     hh  = hID(isprop(hID,'BrushData'));
     set(hh,'BrushData',[]);    
     set(hObject,'BackgroundColor',[0.929412 0.929412 0.929412]);
      
 end
 
end


% -------------------------------------------------------------------------
function handles = toggleData_Callback(hObject, eventdata, handles)

iFile = get(handles.fileListbox,'value');
iFile = iFile(1);
if isempty(iFile) || ~isfield(handles,'st') || isempty(handles.st)
    return
end

% is this a toggle ON or OFF call:
sCall = get(hObject,'string');

% brush amplitude and phase or independently?
iVal = get(findobj(handles.figure1,'tag','brushMode'),'value');
if iVal == 1
    brushMode = 'joint';
else
    brushMode = 'independent';
end

% Find brushed data:
hID = findall(handles.figure1,'tag','dataID');

hh = hID(isprop(hID,'BrushData'));
   
if isempty(hh)
    return;
end 

in   =  get(hh,'userdata');
bd   =  get(hh,'BrushData');
    
if ~iscell(bd)
    bd = {bd};
    in = {in};
end

% Get list of everything:
iToggle =[];
for i = 1:length(in)    
    new = in{i}(bd{i} >0);
    iToggle  = [iToggle; new(:)];
end
iToggle = unique(iToggle);
iToggle = iToggle(~isnan(iToggle)); % strip out any nans from missing data values

if ~isempty(bd)
    switch sCall
        case 'Toggle On'
            handles.st(iFile).iFlagged(iToggle)  = false;

            if strcmpi(brushMode,'joint')
               % find phase data at same iTx,iRx and iFreq and turn it on:
                inds = handles.st(iFile).DATA(iToggle,2:4);
                [LIA] = (ismember(handles.st(iFile).DATA(:,2:4),inds,'rows')) &  handles.st(iFile).DATA(:,1) >= 100;    
                handles.st(iFile).iFlagged(LIA) = false;
            end
 
        case 'Toggle Off'
 
            handles.st(iFile).iFlagged(iToggle) = true;

            if strcmpi(brushMode,'joint')
                % find phase data at same iTx,iRx and iFreq and turn it on:
                inds = handles.st(iFile).DATA(iToggle,2:4);
                LIA  = (ismember(handles.st(iFile).DATA(:,2:4),inds,'rows')) &  handles.st(iFile).DATA(:,1) >= 100;    
                handles.st(iFile).iFlagged(LIA) = true;  
            end

       
    end
    
end
 
% now redraw the plot:
 
    handles = plot_Callback(hObject, eventdata, handles);
 
    updateRMS(handles);
    
    % Update handles structure
    guidata(hObject, handles);

end
% -------------------------------------------------------------------------
function handles = saveNewFile_Callback(hObject, eventdata, handles)

if isempty(handles.st)
    return
end

% Use first selected file:
iFile = get(handles.fileListbox,'value');
iFile = iFile(1);
if isempty(iFile) || ~isfield(handles,'st') || isempty(handles.st)
    return
end

set( handles.figure1, 'Pointer', 'watch' );
drawnow;

% Get name for file:
[sFile,sPath, filterindex] = uiputfile( '*', 'Save editted MARE2DEM data as:');

% Save new data file
if filterindex > 0
    outputFileName = fullfile(sPath,sFile);
    
    st =  handles.st(iFile);
    
    if st.bWaslog10 
         st = convertAmpTolog10Amp(st);
    end
   
    iFlagged = st.iFlagged;
 
    
    st.DATA = st.DATA(~iFlagged,1:6);% just save data, not model response
    % since this is typically used to remove bad/noisy data during inversion
    st.comment = 'Data editted using plotMARE2DEM_MT.m';
   
    m2d_writeEMData2DFile(outputFileName,st)
    
    % Save a .flagged file using INPUT file name, not new file since the
    % iFlagged array pertains to the original data:
    outputFileName = fullfile(st.sPath,sprintf('%s.flagged.mat',st.sFile));
    save(outputFileName, 'iFlagged');
end
    


set( handles.figure1, 'Pointer', 'arrow' );
drawnow;


end 
%--------------------------------------------------------------------------
% receiver listbox select callback:
function receiverListbox_Callback(hObject, eventdata, handles) %#ok<DEFNU>

% get selected receivers:
iRx  = get(handles.receiverListbox,'value');

if isempty(iRx)
    return
end


% Update the plots:
handles = plot_Callback(hObject, eventdata, handles);
 
end

% -------------------------------------------------------------------------
function handles = plot_Callback(hObject, ~, handles)

% First get some of the GUI values to pass to the plotting functions: 

% Get data files to plot:
iFiles = get(handles.fileListbox,'value');

% Delete any existing axes:
if isfield(handles,'hAxes')
    try
        delete(handles.hAxes);
    end
    handles.hAxes = [];
end
%delete(findobj(handles.figure1,'tag','hAxMT'));
delete(findobj(handles.figure1,'type','axes'));  % kwk: delete all axes everytime

% if no files, return
if isempty(iFiles) || ~isfield(handles,'st') || isempty(handles.st)
    return
end
 
handles.iFiles = iFiles;

% Get the plot type:
cPlotTypes = lower(strtrim(get(handles.plotType,'string')));
sPlotType =  cPlotTypes{get(handles.plotType,'value')};

% Add line legend to file names if 2 files selected and appropriate
% plotType:
handles.lineStyles = {'-' '--' ':' '-.'};
 
cFiles = get(handles.fileListbox,'string');

icnt = 0;
for i = 1:length(cFiles)    

    if length(iFiles) > 1 && ismember(lower(sPlotType),{'grid plot' 'single plot' 'profile plot'})
        if ismember(i,iFiles)
            icnt = icnt + 1;
            cFiles{i} = sprintf('%s %s',handles.st(i).sFile,handles.lineStyles{icnt});
        else
            cFiles{i} = handles.st(i).sFile;
        end
    else
        cFiles{i} = handles.st(i).sFile;
    end
end
set(handles.fileListbox,'string',cFiles);

% Get frequencies to plot:
iFreqs = get(handles.frequencyListbox,'value');
nFreqs = get(handles.frequencyListbox,'string');
handles.nFreqs = nFreqs(iFreqs);


% Get components to plot:
iComps = get(handles.componentsListbox,'value');
sComps = get(handles.componentsListbox,'string');
handles.sComps = sComps(iComps);

% Tipper check: sComps can have either tipper or impedances but not both at
% same time:
if any(strcmpi(handles.sComps,'Mzy (TE)'))
    iTipper = find(strcmpi(sComps,'Mzy (TE)'));
    set(handles.componentsListbox,'value',iTipper); 
    handles.sComps = sComps(iTipper);
end  

% Get receivers to plot:
handles.iRx   = get(handles.receiverListbox,'value');

% Period or frequency:
val = get(handles.freqAxisType,'value');
if val == 1
    handles.lUsePeriod = true;
    handles.xlab = 'Period (s)';
    ff = 1./str2double(handles.nFreqs);
   
else
    handles.lUsePeriod = false;
    handles.xlab = 'Frequency (Hz)';
    ff = str2double(handles.nFreqs);
   
end
ff = log10(ff);
df = max([ 1  max(ff) - min(ff)]);
buf = 0.025;
handles.xlims = 10.^[min(ff) - buf*df max(ff) + buf*df];

switch sPlotType

    case 'grid plot'
        
        handles = sub_makeGridPlot(handles);
        
    case 'single plot'
         
        handles = sub_makeSinglePlot(handles);

    case {'profile plot','pseudosection','misfit breakdown'}
        
        % For profile and pseudosections, the x axis is:
        val = get(handles.xaxisMenu,'value');
        if val == 1
            handles.lUseRxPosition = true;
            handles.xlab = 'km';
            yy = handles.st(iFiles(1)).stMT.receivers(handles.iRx,2);
            dy = max([ 1  max(yy) - min(yy)]);
            buf = 0.025;
            handles.xlims = [min(yy) - buf*dy max(yy) + buf*dy]/1d3;
        else
            handles.lUseRxPosition = false;
            handles.xlab = '';
            buf = 0.025;
            dx  = buf*length(handles.iRx);
            handles.xlims = [1-dx length(handles.iRx)+dx ];
        end
        switch sPlotType
            case 'profile plot'
                handles = sub_makeProfilePlot(handles);
            case 'pseudosection'
                handles = sub_makePseudosectionPlot(handles);
            case 'misfit breakdown' 
                handles = sub_plotMisfitBreakDown(handles);
        end
        

        
    case 'uncertainty %'
        beep;
        disp('kwk note: still left to do!')
        
end
 

% Store data back into gui:
guidata(hObject, handles);

end
%--------------------------------------------------------------------------
function handles = sub_plotMisfitBreakDown(handles)


if isfield(handles,'hAxes')
    delete(handles.hAxes)
end
delete(findobj(handles.figure1,'type','axes'));

if ~isfield(handles,'st')
    return
end

set( handles.figure1, 'Pointer', 'watch' );
drawnow;

% only one file:
iFile   = get(handles.fileListbox,'value');
iFile   = iFile(1);
st      = handles.st(iFile);


% Make sure there are model responses available:
if size(st.DATA,2) ~= 8 
    return
end

% Try getting target RMS misfit by reading in corresponding .resistivity
% file:
targetMisfit = [];
try
    [~,n]    = fileparts(st.sFile);
    sResFile = fullfile(st.sPath,strcat(n,'.resistivity'));
    stRes    = m2d_readResistivity(sResFile,false);
    targetMisfit = stRes.targetMisfit;
catch
end

if st.bWaslog10 % reapply log10 (yes this is a kludge...)
    st = convertAmpTolog10Amp(st);
end

% All good, move on:
sDataCodeLookupTable = m2d_getDataCodeLookupTable();

lShowOffData = get(findobj(handles.figure1,'tag','showOffData'),'value');


% Create three axes (misfit by site, misfit by type, misfit by period):

m = 3;
n = 1;
lColorbar = false;
[posX,posY,widX,widY]= getRowColPositions(handles,m,n,lColorbar);    

posRx   = [ posX(1) posY(3) widX(1) widY(3)];
hSite = axes(handles.figure1,'units','pixels','Position', posRx,'tag','hAxes');

posFreq   = [posX(1) posY(2) widX(1) widY(2)];
hPeriod = axes(handles.figure1,'units','pixels','Position', posFreq,'tag','hAxes');

% m = 3;
% n = 2;
% lColorbar = false;
% [posX,posY,widX,widY]= getRowColPositions(handles,m,n,lColorbar); 
posComp  = [posX(1) posY(1) widX(1) widY(1)];
hType   = axes(handles.figure1,'units','pixels','Position', posComp,'tag','hAxes');

 
handles.hAxes = [hSite hPeriod hType]';

set( handles.hAxes,'box','on')

% remove non MT part of data to make code simpler:

if lShowOffData
    lMT = st.DATA(:,1) >= 100;
else
    lMT = st.DATA(:,1) >= 100 & ~st.iFlagged;
end

st.DATA = st.DATA(lMT,:);


sTypeStr = cell(length(handles.sComponents),1);
lAmp = false(length(st.DATA(:,1)),length(handles.sComponents));
lPhs = false(length(st.DATA(:,1)),length(handles.sComponents));
nMisfitAmpPhsM(1:2*length(handles.sComponents)) = inf;
 

for iComp = 1:length(handles.sComponents)
    
    if strcmpi( handles.sComponents{iComp}(1:3),'mzy')
     
        if any( [st.Cmps.Cmp] == 135 ) ||  any([st.Cmps.Cmp] == 136 )
            iCompCodeAmp = find(strcmp(sDataCodeLookupTable(:,2),'Amplitude') & strcmp(sDataCodeLookupTable(:,1),handles.sComponents(iComp)));
            iCompCodePhs = find(strcmp(sDataCodeLookupTable(:,2),'Phase') & strcmp(sDataCodeLookupTable(:,1),handles.sComponents(iComp)));
            sTypeStr{2*iComp-1}  = sprintf(' %s Amp', handles.sComponents{iComp}); 
            sTypeStr{2*iComp   } = sprintf(' %s Phs', handles.sComponents{iComp}); 
        elseif any( [st.Cmps.Cmp] == 133) ||  any([st.Cmps.Cmp] == 134 )
            iCompCodeAmp = find(strcmp(sDataCodeLookupTable(:,2),'Real') & strcmp(sDataCodeLookupTable(:,1),handles.sComponents(iComp)));
            iCompCodePhs = find(strcmp(sDataCodeLookupTable(:,2),'Imaginary') & strcmp(sDataCodeLookupTable(:,1),handles.sComponents(iComp)));
            sTypeStr{2*iComp-1}  = sprintf(' %s Real', handles.sComponents{iComp}); 
            sTypeStr{2*iComp   } = sprintf(' %s Imag', handles.sComponents{iComp});        
        end   
   
        
    else

        if st.bWaslog10
            iCompCodeAmp = (find(strcmp(sDataCodeLookupTable(:,2),'log10(ApRes)') & strcmp(sDataCodeLookupTable(:,1),handles.sComponents(iComp))));
        else 
            iCompCodeAmp = find(strcmp(sDataCodeLookupTable(:,2),'ApRes') & strcmp(sDataCodeLookupTable(:,1),handles.sComponents(iComp)));
        end

        iCompCodePhs = find(strcmp(sDataCodeLookupTable(:,2),'Phase') & strcmp(sDataCodeLookupTable(:,1),handles.sComponents(iComp)));
    
        
        sTypeStr{2*iComp-1}  = sprintf(' %s Ap.Res.', handles.sComponents{iComp}); 
        sTypeStr{2*iComp   } = sprintf(' %s Phase', handles.sComponents{iComp}); 
    
    end
    lAmp(:,iComp) = st.DATA(:,1) == iCompCodeAmp;
    lPhs(:,iComp) = st.DATA(:,1) == iCompCodePhs;
    
    
    nMisfitAmpPhsM(2*iComp-1) = getMisfit( st.DATA(lAmp(:,iComp),8));
    nMisfitAmpPhsM(2*iComp  ) = getMisfit( st.DATA(lPhs(:,iComp),8));
    
end          

% Get colors to use:
 
 
%
% Misfit by mode:
%
axes(hType);
hb = bar(1:length(nMisfitAmpPhsM), nMisfitAmpPhsM',.1);
barColors = lines(size(nMisfitAmpPhsM,2));
for i = 1:length(hb)
    hb(i).FaceColor = barColors(i,:);
end

set( gca,'XTick',(1:length(sTypeStr)),'XTickLabel', sTypeStr );
ylabel('RMS') 
set(hType,'fontsize',handles.fontSize-4);
shading flat

if ~isempty(targetMisfit)
    ax = axis;
    hold on;
    plot(ax(1:2),[targetMisfit targetMisfit],'k--');
    hh = get(gca,'children'); % put line behind bars - no pun intended.
    set(gca,'children',[hh(2:end) hh(1)]);
end

%xticklabel_rotate;

%
% Misfit by frequency/period:
%
nMisfitAmpPhsF(1:length(sTypeStr)) = inf;
 
for iComp = 1:length(handles.sComponents)
 
    for iFreq = 1:length(st.stMT.frequencies)
        lFreq = st.DATA(:,2) == iFreq;
        
        nMisfitAmpPhsF(iFreq,2*iComp-1) = getMisfit( st.DATA(lAmp(:,iComp)&lFreq,8));
        nMisfitAmpPhsF(iFreq,2*iComp  ) = getMisfit( st.DATA(lPhs(:,iComp)&lFreq,8));
    end
end
ff = st.stMT.frequencies;
handles.xlab = 'log10 Frequency (Hz)';
if handles.lUsePeriod
    ff = 1./ff;
    handles.xlab = 'log10 Period (s)';
end
ff = log10(ff);

% plot only frequencies that are used:
lKeep = any(isfinite(nMisfitAmpPhsF),2);
ff = ff(lKeep);
nMisfitAmpPhsF = nMisfitAmpPhsF(lKeep,:);


axes(hPeriod);

if length(ff) > 40  % too many frequencies, plot as dots instead:
    hb = plot(ff,nMisfitAmpPhsF,'.','markersize',16);
    set(hPeriod,'xtick',sort(ff));
    if ~handles.lUsePeriod
        set(hPeriod,'xdir','reverse'); % so high frequency (shallow) on left, low freq (deeper sensitivity) on right
    end
        
else
   
    hb = bar(1:length(ff),nMisfitAmpPhsF);
    set(hPeriod,'xtick',1:length(ff));
    barColors = lines(size(nMisfitAmpPhsF,2));
    for i = 1:length(hb)
        hb(i).FaceColor = barColors(i,:);
    end
    
end

axis tight

ylabel('RMS') 
xlabel(handles.xlab)
hd = get(gca,'children'); % put line behind bars - no pun intended.
shading flat

if ~isempty(targetMisfit)
    ax = axis;
    hold on;
    plot(ax(1:2),[targetMisfit targetMisfit],'k--');
    hh = get(gca,'children'); % put line behind bars - no pun intended.
    set(gca,'children',[hh(2:end); hh(1)]);
end
legend(hb,sTypeStr)

if handles.lUsePeriod
   if ff(1) > ff(end)
      set(gca,'xdir','rev')  % so long period on the right
   end
else
   if ff(1) < ff(end)
      set(gca,'xdir','rev')  % so low frequency on the right
   end    
end

xlab ={};
for i = 1:length(ff)
    xlab{i} = sprintf('%.3g',ff(i));
end


set(hPeriod,'xticklabel',xlab);
if length(xlab) > 10 
    xticklabel_rotate;
end



%
% Misfit by site:
%
nMisfitAmpPhsR = zeros(length(st.stMT.receivers(:,1)),2*length(handles.sComponents));

lUsed= false(length(st.stMT.receivers(:,1)));
for iComp = 1:length(handles.sComponents)
 
    for iRx = 1:length(st.stMT.receivers(:,1))
        lRx = st.DATA(:,4) == iRx;
 
        nMisfitAmpPhsR(iRx,2*iComp-1) = getMisfit( st.DATA(lAmp(:,iComp)&lRx,8));
        nMisfitAmpPhsR(iRx,2*iComp  ) = getMisfit( st.DATA(lPhs(:,iComp)&lRx,8));

        if any(lRx) 
            lUsed(iRx) = true;
        end
    end
end

val = get(handles.xaxisMenu,'value');
if val == 1
    handles.lUseRxPosition = true;
    handles.xlab = 'Position (km)';
    xd  = st.stMT.receivers(:,2)/1d3;
else
    handles.lUseRxPosition = false;
    handles.xlab = 'Receiver';
    xd = 1:length(st.stMT.receivers(:,1)); 
   
end

xd = xd(lUsed);
nMisfitAmpPhsR = nMisfitAmpPhsR(lUsed,:); 


 
if length(xd) > 1 % only plot if more than one station:


    axes(hSite);

    hb = bar(xd,nMisfitAmpPhsR);
    barColors = lines(size(nMisfitAmpPhsR,2));
    for i = 1:length(hb)
        hb(i).FaceColor = barColors(i,:);
    end

    ylabel('RMS')  
    axis tight
    xlabel(handles.xlab)
    hd = get(gca,'children'); % put line behind bars - no pun intended.
   
    
    shading flat

    if ~handles.lUseRxPosition
        set(hSite,'xtick',1:length(st.stMT.receivers(:,1)));
        xlab = st.stMT.receiverName;
        set(hSite,'xticklabel',xlab);
        hSite.TickLabelInterpreter ='none'; % don't apply tex conversion in case name has underscore, e.g. s_01  
        if size(xlab,1) > 8 
            xticklabel_rotate;
        end
    end


    if ~isempty(targetMisfit)
        ax = axis;
        hold on;
        plot(ax(1:2),[targetMisfit targetMisfit],'k--');
        hh = get(gca,'children'); % put line behind bars - no pun intended.
        set(gca,'children',[hh(2:end); hh(1)]);
    end
    legend(hb,sTypeStr)
    
else
    set(hSite,'visible','off');
end

set(findobj(hSite,'type','text'),'interpreter','none'); % to stop site names from using latex interpreter


%
% Increase font size:
%
set( handles.hAxes,'fontsize',handles.fontSize,'xgrid','on','ygrid','on')

set(handles.hAxes,'tickdir','out','TickLength', [0.0100 0.0250]/2)


%
% All done, return to normal mode:
%
set( handles.figure1, 'Pointer', 'arrow' );

drawnow 
 

end


%--------------------------------------------------------------------------
function nMisfit = getMisfit(resid)
 
nMisfit = sqrt ( sum(resid.^2) / length(resid) );

end

% -------------------------------------------------------------------------
 function [posX,posY,widX,widY]= getRowColPositions(handles,m,n,lColorbar)
 
% one position function to rule them all...
   
    figPos  = handles.figure1.Position;
    toolPos = handles.UIpanel.Position; 
    
    if lColorbar
        dxcb = 40;
    else
        dxcb = 0;
    end
    
    dx0 = 50;
   
    x0  = toolPos(1)+toolPos(3) + dx0; 
   
    y0   = 50;
    yTop = 0; 
    
    wTotal = figPos(3)-x0;
    hTotal = figPos(4)-y0-yTop;

    if m <= 3
        dy = 50;  % vertical space between axes
        dx = 50;  % horizontal space between axes
    else
        dy = 160/m; 
        dx = dy; 
    end
 
    rowH = hTotal/m;
    colW = wTotal/n;
    
    
    % Row positions:
    for i = m:-1:1
        posY(i) = y0 + (i-1)*rowH; % + dy;
        widY(i) = rowH - dy;
    end
    % Column positions:
    for i = n:-1:1
        posX(i) = x0 + (i-1)*colW; % + dx;
        widX(i) = colW - dx - dxcb;
    end
    
 end
%--------------------------------------------------------------------------
function handles = sub_makeGridPlot(handles)

lShowResiduals = false; 
lShowModel     = handles.showModelResponse.Value & strcmpi(handles.showModelResponse.Enable,'on'); 
lShowData      = handles.showData.Value          & strcmpi(handles.showData.Enable,'on');
lShowOffData   = get(findobj(handles.figure1,'tag','showOffData'),'value');


iFreqsSelected  = handles.frequencyListbox.Value;
iRxSelected     = handles.receiverListbox.Value;
 
% Catch for large number of stations selected:
if length(iRxSelected) > handles.nGridPlotLimit
    iRxSelected = iRxSelected(1:handles.nGridPlotLimit);
    handles.receiverListbox.Value = iRxSelected;
    disp('plotMARE2DEM_MT: too many stations selected, reverting to smaller subset. See handles.nGridPlotLimit default')
end

%check for Tipper: 
bTipperAP = false;
bTipperRI = false;
if any(strcmpi(handles.sComps,'Mzy (TE)'))
    % Check for Real & Imag or Amp & Phs
    if any( [handles.st(1).Cmps.Cmp] == 135 ) ||  any([handles.st(1).Cmps.Cmp] == 136 )
        bTipperAP = true;
    elseif any( [handles.st(1).Cmps.Cmp] == 133) ||  any([handles.st(1).Cmps.Cmp] == 134 )
        bTipperRI = true;
    end   
end  

set( handles.figure1, 'Pointer', 'watch' );
drawnow

% Create Amplitude and Phase axes:
nPlots = length(iRxSelected);
nRows  = 2*floor(sqrt(nPlots));
nCols  = ceil(nPlots/floor(sqrt(nPlots)));

nPlotsLastRow = nPlots - (nRows/2-1)*nCols;

if nCols == 0
    return
end

[posX,posY,widX,widY]= getRowColPositions(handles,nRows,nCols,false);

hAmp = gobjects(nPlots,1);
hPhs = gobjects(nPlots,1);
handles.hAxes = gobjects(nRows,nCols);
 

for iPlot = 1:nPlots

    iRow = 2*ceil(iPlot/nCols)-1;
    iCol = iPlot - nCols*floor((iPlot-1)/nCols);

    % Move apparent resistivity and phase axes closer together:
    fudgeY = 0;
    if nRows > 2
      fudgeY = 60/nRows;    
    end
    
    posAmp      = [ posX(iCol) posY(nRows+1-iRow)-fudgeY  widX(iCol) widY(nRows+1-iRow)+fudgeY  ];
    posPhs      = [ posX(iCol) posY(nRows+1-iRow-1)       widX(iCol) widY(nRows+1-iRow-1)+fudgeY ];    
    
 
    hAmp(iPlot) = axes( handles.figure1,'units','pixels','position', posAmp,'fontsize',handles.fontSize,'box','on','tag','hAxMT','visible','on');  
    hPhs(iPlot) = axes( handles.figure1,'units','pixels','position', posPhs,'fontsize',handles.fontSize,'box','on','tag','hAxMT','visible','on'); 
    
    set(hAmp(iPlot),'xticklabel','');
    if iCol > 1
        set([hAmp(iPlot) hPhs(iPlot)],'yticklabel','');
    else
        if bTipperRI
            ylabel(hAmp(iPlot),'Real')
            ylabel(hPhs(iPlot),'Imag')
        elseif bTipperAP    
            ylabel(hAmp(iPlot),'Amplitude')
            ylabel(hPhs(iPlot),'degrees','verticalalignment','bottom'); 
        else
            ylabel(hAmp(iPlot),'ohm-m','verticalalignment','middle')
            ylabel(hPhs(iPlot),'degrees','verticalalignment','bottom'); 
        end

    end
    
    if iRow == nRows-1 || (iRow == nRows-3 & iCol > nPlotsLastRow)
        xlabel(hPhs(iPlot),handles.xlab)
    else
        set([hAmp(iPlot) hPhs(iPlot)],'xticklabel',[]);
    end
    
    handles.hAxes(iRow  ,iCol) = hAmp(iPlot);
    handles.hAxes(iRow+1,iCol) = hPhs(iPlot);
    
end

 
if bTipperRI
    set(hAmp,'xscale','log','yscale','lin');
    set(hPhs,'xscale','log','yscale','lin');
    set([hAmp hPhs],'ytick',[-2:0.2:2],'XMinorTick','on' );   
elseif bTipperAP    
    set(hAmp,'xscale','log','yscale','log');
    set(hPhs,'xscale','log','yscale','lin');
    %set([hAmp hPhs],'ytick',[-2:0.2:2],'XMinorTick','on' );     
    
else
    set(hAmp,'xscale','log','yscale','log');
    set(hPhs,'xscale','log','ylim',[0 90]);
    set(hAmp,'ytick',10.^(-6:6),'XMinorTick','on' ); 
end  
 
set( [hAmp; hPhs] ,'nextplot','add','xlim',handles.xlims,'xtick',10.^(-6:6),'XMinorTick','on'  )
 

sDataCodeLookupTable = m2d_getDataCodeLookupTable();

%drawnow;

lineStyles = handles.lineStyles;
thisMarker = handles.marker;
markerSize = handles.markerSize;
lineWidth  = handles.lineWidth;

maxAmp = -inf;
minAmp = inf;
maxPhs = -inf;
minPhs = inf;
 
for iFile = 1:length(handles.iFiles)
    
    ind = mod(iFile-1,size(lineStyles,2))+1;
    
    thisLineStyle = lineStyles{ind};
 
    st = handles.st(handles.iFiles(iFile));
  
    for iComp = 1:length(st.Cmps)  %handles.sComps)
   
        sMode = sDataCodeLookupTable(st.Cmps(iComp).Cmp,1);
                
        switch sMode{:}
        case 'Zyx (TM)'
            lineColor = 'r';

        case 'Zxy (TE)'
            lineColor = 'b';

        case 'Det |Z|'
            lineColor = 'k'; 

        case 'Mzy (TE)'
            lineColor = 'b';
            bThisIsTipper = true;
        end
            
        if ~any(ismember(handles.sComps,sMode))
            continue;
        end
 
        sType = sDataCodeLookupTable(st.Cmps(iComp).Cmp,2);
  
        D  = st.Cmps(iComp).d(iRxSelected,iFreqsSelected);
        E  = st.Cmps(iComp).e(iRxSelected,iFreqsSelected);
        R  = st.Cmps(iComp).r(iRxSelected,iFreqsSelected);
        M  = st.Cmps(iComp).m(iRxSelected,iFreqsSelected);
        ID = st.Cmps(iComp).iData(iRxSelected,iFreqsSelected);
          
     
        xd = st.stMT.frequencies(iFreqsSelected);
        if handles.lUsePeriod
            xd = 1./xd;
        end     
       [xd, ixsort] = sort(xd);
        
        D  = D(:,ixsort);
        E  = E(:,ixsort);
        M  = M(:,ixsort);
        ID = ID(:,ixsort);
       
        %
        % Check for any flagged data:
        %

        lFlagged = false(size(ID));
        lFlagged(~isnan(ID)) =  st.iFlagged(ID(~isnan(ID))); 

        [ydOn,ydOff]     = deal(D);
        ydOn(lFlagged)   = nan;
        ydOff(~lFlagged) = nan;
        [yeOn,yeOff]     = deal(E);
        yeOn(lFlagged)   = nan;
        yeOff(~lFlagged) = nan;
        [ymOn,ymOff]     = deal(M);
        ymOn(lFlagged)   = nan;
        ymOff(~lFlagged) = nan;
        [yrOn,yrOff]     = deal(R);
        yrOn(lFlagged)   = nan;
        yrOff(~lFlagged) = nan;   
        
        switch lower(sType{:})
            
            case {'apres','real','amplitude'}

                maxAmp = max([maxAmp;D(:);M(:)],[],1,'omitnan');
                minAmp = min([minAmp;D(:);M(:)],[],1,'omitnan');

            case {'phase','imaginary'}

                maxPhs = max([maxPhs;D(:);M(:)],[],1,'omitnan');
                minPhs = min([minPhs;D(:);M(:)],[],1,'omitnan');   
                
        end

        hd = [];
        hm = [];
        hr = [];
                  
        for iPlot = 1:nPlots
           
            switch lower(sType{:})

                case {'apres','amplitude'}

                    if lShowData

                        hd = loglog(hAmp(iPlot),xd,ydOn(iPlot,:),'marker',thisMarker,'markersize',markerSize,'color',lineColor,'markerfacecolor',lineColor,'LineStyle','none');
                        set(hd,'userdata',ID(iPlot,:)','tag','dataID');
                        
                        yUpper = ydOn(iPlot,:) + yeOn(iPlot,:);
                        yLower = ydOn(iPlot,:) - yeOn(iPlot,:);
                        iNeg = yLower < 0;
                        if any(iNeg)
                            logErr = yeOn(iPlot,iNeg)./ydOn(iPlot,iNeg)*.4343;
                            yLower(iNeg) = 10.^(log10(ydOn(iPlot,iNeg)) - logErr);
                        end
                        yLower(yLower < 0 ) = ydOn(yLower < 0) *.000001;   

                      
                        he  = loglog(hAmp(iPlot),[xd xd]',[yLower; yUpper],'-','linewidth',lineWidth,'color',lineColor);
                         
                        % Flagged data:
                        if lShowOffData
                            h = loglog(hAmp(iPlot),xd,ydOff(iPlot,:),'marker','x','markersize',4,'linestyle','none','color',lineColor); 
                            set(h,'userdata',ID(iPlot,:)','tag','dataID')                                
                            
                        end 

                    end

                    if lShowModel

                        if lShowOffData % plot evertything
                            lp = ~isnan(M(iPlot,:));
                            hm = loglog(hAmp(iPlot),xd(lp),M(iPlot,lp),'marker','none','LineStyle',thisLineStyle,'linewidth',lineWidth,'color',lineColor);
                        else
                            lp = ~isnan(ymOn(iPlot,:));
                            hm = loglog(hAmp(iPlot),xd(lp),ymOn(iPlot,lp),'marker','none','LineStyle',thisLineStyle,'linewidth',lineWidth,'color',lineColor);
                        end
                        set(hm,'userdata',ID(iPlot,lp)','tag','dataID');
                        
                        if ~strcmpi(handles.sModelResponseColor,'data')
                            for i = 1:length(hm)
                                set(hm(i),'color',handles.sModelResponseColor);
                            end
                        end
                         
                    end

                    % Title:
                    thisRxName = st.stMT.receiverName{iRxSelected(iPlot)};
                        if nRows > 4
                        sVA = 'top';
                        else
                        sVA = 'bottom';
                    end
                    title(hAmp(iPlot),sprintf('%s', thisRxName),'verticalalignment',sVA,'interpreter','none');

                case {'phase','imaginary'}

                    if lShowData

                        hd = semilogx(hPhs(iPlot),xd,ydOn(iPlot,:),'marker',thisMarker,'markersize',markerSize,'LineStyle','none','color',lineColor,'markerfacecolor',lineColor);
                        set(hd,'userdata',ID(iPlot,:)','tag','dataID');

                        yUpper = ydOn(iPlot,:) + yeOn(iPlot,:);
                        yLower = ydOn(iPlot,:) - yeOn(iPlot,:);
 
                        he  = semilogx(hPhs(iPlot),[xd xd]',[yUpper; yLower],'-','linewidth',lineWidth,'color',lineColor);


                        % Flagged data:
                        if lShowOffData
                            h = semilogx(hPhs(iPlot),xd,ydOff(iPlot,:),'marker','x','markersize',4,'linestyle','none','color',lineColor); 
                            set(h,'userdata',ID(iPlot,:)','tag','dataID')                                
                             
                        end   

                    end

                    if lShowModel

                        if lShowOffData % plot evertything
                            lp = ~isnan(M(iPlot,:));
                            hm = semilogx(hPhs(iPlot),xd(lp),M(iPlot,lp),'marker','none','markersize',markerSize,'LineStyle',thisLineStyle,'linewidth',lineWidth,'color',lineColor);
                        else
                            lp = ~isnan(ymOn(iPlot,:));
                            hm = semilogx(hPhs(iPlot),xd(lp),ymOn(iPlot,lp),'marker','none','markersize',markerSize,'LineStyle',thisLineStyle,'linewidth',lineWidth,'color',lineColor);                     
                        end
                        set(hm,'userdata',ID(iPlot,lp)','tag','dataID');
                    
                        
                        if ~strcmpi(handles.sModelResponseColor,'data')
                            for i = 1:length(hm)
                                set(hm(i),'color',handles.sModelResponseColor);
                            end
                        end
                        
                    end
                    
                    
                case 'real'
                    
                     if lShowData

                        hd = semilogx(hAmp(iPlot),xd,ydOn(iPlot,:),'marker',thisMarker,'markersize',markerSize,'LineStyle','none','color',lineColor,'markerfacecolor',lineColor);
                        set(hd,'userdata',ID(iPlot,:)','tag','dataID');

                        yUpper = ydOn(iPlot,:) + yeOn(iPlot,:);
                        yLower = ydOn(iPlot,:) - yeOn(iPlot,:);
 
                        he  = semilogx(hAmp(iPlot),[xd xd]',[yUpper; yLower],'-','linewidth',lineWidth,'color',lineColor);


                        % Flagged data:
                        if lShowOffData
                            h = semilogx(hAmp(iPlot),xd,ydOff(iPlot,:),'marker','x','markersize',4,'linestyle','none','color',lineColor); 
                            set(h,'userdata',ID(iPlot,:)','tag','dataID')                                
                             
                        end   

                    end

                    if lShowModel

                        if lShowOffData % plot evertything
                            lp = ~isnan(M(iPlot,:));
                            hm = semilogx(hAmp(iPlot),xd(lp),M(iPlot,lp),'marker','none','markersize',markerSize,'LineStyle',thisLineStyle,'linewidth',lineWidth,'color',lineColor);
                        else
                            lp = ~isnan(ymOn(iPlot,:));
                            hm = semilogx(hAmp(iPlot),xd(lp),ymOn(iPlot,lp),'marker','none','markersize',markerSize,'LineStyle',thisLineStyle,'linewidth',lineWidth,'color',lineColor);                     
                        end
                        set(hm,'userdata',ID(iPlot,lp)','tag','dataID');
                    
                        if ~strcmpi(handles.sModelResponseColor,'data')
                            for i = 1:length(hm)
                                set(hm(i),'color',handles.sModelResponseColor);
                            end
                        end
                        
                    end       

                otherwise
                    fprintf('This type not yet support in grid plotting: %s\n',sType{:})
            end % switch
        
        end % iPlot
        
    end


end % Loop over files

if bTipperRI

    if isfinite([minPhs maxPhs])
    
        mn = min([minPhs,minAmp]);
        mx = max([maxPhs,maxAmp]);
        if mx - mn == 0
            mx = mx+.5;
            mn = mn-.5;
        end
        r = mx - mn;
        pad = 0.05;
        
        set(hAmp,'ylim', [mn-r*pad mx+r*pad]);
        set(hPhs,'ylim', [mn-r*pad mx+r*pad]);
    end 

else
    
 
    if isfinite([minAmp maxAmp])
        mn = floor(log10(minAmp));
        mx = ceil(log10(maxAmp));
        if mx - mn == 0
            mx = mx+.5;
            mn = mn-.5;
        end
        set(hAmp,'ylim', 10.^[mn mx]);
    end

    if isfinite([minPhs maxPhs])
        mn = floor((minPhs));
        mx = ceil((maxPhs));
        if mx - mn == 0
            mx = 90;
            mn = 0;
        else
            mx = ceil(mx/45)*45;
            mn = floor(mn/45)*45;
        end
        set(hPhs,'ylim', [mn mx]);
    end 
end


 if nPlots < 20
        
    handles.linkXlim = linkprop([hAmp(1:nPlots);hPhs(1:nPlots)],'xlim'); 
  
    handles.linkAmpYlim = linkprop(hAmp(1:nPlots),'ylim');
    handles.linkPhsYlim = linkprop(hPhs(1:nPlots),'ylim');
end

if ~handles.lUsePeriod  % so "shallow" sensitive data is on left and deeper sensitivity is on the right:
    set([hAmp(1:nPlots);hPhs(1:nPlots)],'xdir','rev');
end

xt = get(hAmp(nPlots),'xtick');
set(hAmp(1:nPlots),'xtick',xt,'xlim',handles.xlims,'visible','on','xgrid','on','ygrid','on'); 
set(hPhs(1:nPlots),'xtick',xt,'xlim',handles.xlims,'visible','on','xgrid','on','ygrid','on'); 
 
set( handles.figure1, 'Pointer', 'arrow' );
drawnow;

end
%--------------------------------------------------------------------------
function handles = sub_makeSinglePlot(handles)
 
lShowResiduals = handles.showResiduals.Value     & strcmpi(handles.showResiduals.Enable,'on');
lShowModel     = handles.showModelResponse.Value & strcmpi(handles.showModelResponse.Enable,'on'); 
lShowData      = handles.showData.Value          & strcmpi(handles.showData.Enable,'on');
lShowOffData   = get(findobj(handles.figure1,'tag','showOffData'),'value');

%check for Tipper: 
 
bTipperAP = false;
bTipperRI = false;
if any(strcmpi(handles.sComps,'Mzy (TE)'))
    % Check for Real & Imag or Amp & Phs
    if any( [handles.st(1).Cmps.Cmp] == 135 ) ||  any([handles.st(1).Cmps.Cmp] == 136 )
        bTipperAP = true;
    elseif any( [handles.st(1).Cmps.Cmp] == 133) ||  any([handles.st(1).Cmps.Cmp] == 134 )
        bTipperRI = true;
    end   
end  

set( handles.figure1, 'Pointer', 'watch' );
drawnow

 
% Create Amplitude and Phase axes:
 
nRows = 0;
nCols = 0;
if lShowData || lShowModel
    nRows = 1;
    nCols = 1;
end
if lShowResiduals == 1
    nRows = nRows + 1;
    nCols = 2;
else
    nRows = 2;
end   

if nCols == 0
    return
end

[posX,posY,widX,widY]= getRowColPositions(handles,nRows,nCols,false);

% Either 2 x 1 (no residuals or only residuals),  2 x 2 plot (w/residuals), 
posAmp = [];
posPhs = [];
posAmpRes = [];
posPhsRes = [];

if nRows == 2 && nCols == 2
    posAmp      = [ posX(1) posY(2) widX(1) widY(2)];
    posAmpRes   = [ posX(1) posY(1) widX(1) widY(1)];
    posPhs      = [ posX(2) posY(2) widX(1) widY(2)];
    posPhsRes   = [ posX(2) posY(1) widX(1) widY(1)];
else
    if lShowResiduals
        posAmpRes   = [ posX(1) posY(1) widX(1) widY(1)];
        posPhsRes   = [ posX(2) posY(1) widX(1) widY(1)];    
    else
        posAmp      = [ posX(1) posY(2) widX(1) widY(2)];
        posPhs      = [ posX(1) posY(1) widX(1) widY(1)];        
    end
end

hAmp = [];
hPhs = [];
hAmpRes = [];
hPhsRes = [];

if ~isempty(posAmp)
    hAmp = axes(handles.figure1,'units','pixels','position', posAmp,'tag','hAxMT');
    if bTipperRI
        ylabel(hAmp,'Real')
        set(hAmp, 'xscale','log', 'yscale','lin');
    elseif bTipperAP    
        ylabel(hAmp,'Amplitude')
        set(hAmp, 'xscale','log', 'yscale','log');        
    else
        ylabel(hAmp,'ohm-m')
        set(hAmp, 'xscale','log', 'yscale','log');
    end
    
end
if ~isempty(posPhs)
    hPhs = axes(handles.figure1,'units','pixels','position', posPhs,'tag','hAxMT');
    if bTipperRI
        ylabel(hPhs,'Imag')
        set(hPhs, 'xscale','log', 'yscale','lin');
    elseif bTipperAP    
        ylabel(hPhs,'degrees')
        set(hPhs,'xscale','log', 'yscale','lin'); 
    else    
        ylabel(hPhs,'degrees')
        set(hPhs, 'xscale','log', 'ylim',[0 90]);
    end
end
if ~isempty(posAmpRes)
    hAmpRes = axes(handles.figure1,'units','pixels','position', posAmpRes,'tag','hAxMT');
    ylabel(hAmpRes,'Normalized Residual')
    set(hAmpRes, 'xscale','log');
end
if ~isempty(posPhsRes)
    hPhsRes = axes(handles.figure1,'units','pixels','position', posPhsRes,'tag','hAxMT');
    ylabel(hPhsRes,'Normalized Residual')
    set(hPhsRes, 'xscale','log');
end

if isempty(posAmpRes) && isempty(posPhsRes)
    handles.hAxes = [hAmp; hPhs];
else
    handles.hAxes = [hAmp hPhs; hAmpRes hPhsRes];
end
set( handles.hAxes,'fontsize',handles.fontSize,'box','on')
 

%set(handles.hAxes,'visible','off');  

for i = 1:length(handles.hAxes(:))
    xlabel( handles.hAxes(i),handles.xlab)
end

set( handles.hAxes,'nextplot','add')

set(handles.hAxes,'xlim',handles.xlims,'tag','hAxes' );  
  
sDataCodeLookupTable = m2d_getDataCodeLookupTable();
 
iFreqsSelected  = handles.frequencyListbox.Value;
iRxSelected     = handles.receiverListbox.Value;

maxCnt =   length(handles.sComps)*length(iRxSelected);
 

lineStyles = handles.lineStyles;
thisMarker = handles.marker;
markerSize = handles.markerSize;
lineWidth  = handles.lineWidth;


lineColors = feval(handles.sLineColorMap,maxCnt);

ilcnt     = 0;
leghandle = zeros(maxCnt,1);
legstr    = cell(maxCnt,1);

hColorsApr = cell(3,1);
hColorsPhs = cell(3,1);


for iFile = 1:length(handles.iFiles)
    
    ind = mod(iFile-1,size(lineStyles,2))+1;
    
    thisLineStyle = lineStyles{ind};


 
    st = handles.st(handles.iFiles(iFile));
  
    for iComp = 1:length(st.Cmps)  %handles.sComps)
   
        sMode = sDataCodeLookupTable(st.Cmps(iComp).Cmp,1);

        if ~any(ismember(handles.sComps,sMode))
            continue;
        end
        

        % Get iMode for line appearance:
        [~,iMode] = ismember(sMode,handles.sComps);

        % if only a single file, modify line styles bae on sMode
%         if length(handles.iFiles) == 1
%              thisLineStyle = lineStyles{iMode};
%         end


        sType = sDataCodeLookupTable(st.Cmps(iComp).Cmp,2);
  
        D  = st.Cmps(iComp).d(iRxSelected,iFreqsSelected);
        E  = st.Cmps(iComp).e(iRxSelected,iFreqsSelected);
        R  = st.Cmps(iComp).r(iRxSelected,iFreqsSelected);
        M  = st.Cmps(iComp).m(iRxSelected,iFreqsSelected);
        ID = st.Cmps(iComp).iData(iRxSelected,iFreqsSelected);
          
     
        xd = st.stMT.frequencies(iFreqsSelected);
        if handles.lUsePeriod
            xd = 1./xd;
        end     
       [xd, ixsort] = sort(xd);
        
        D  = D(:,ixsort)';
        E  = E(:,ixsort)';
        R  = R(:,ixsort)';
        M  = M(:,ixsort)';
        ID = ID(:,ixsort)';
        
        %
        % To keep model response plots as lines when some values are
        % missing (i.e. nans at some periods), we use linear interpolation:
        %
        for i = 1:size(M,2)
            lnan = isnan(M(:,i));
            if ~all(lnan)
                M(lnan,i) = interp1(xd(~lnan),M(~lnan,i),xd(lnan));
            end
        end
        
       
        %
        % Check for any flagged data:
        %

        lFlagged = false(size(ID));
        lFlagged(~isnan(ID)) =  st.iFlagged(ID(~isnan(ID))); 

        [ydOn,ydOff]     = deal(D);
        ydOn(lFlagged)   = nan;
        ydOff(~lFlagged) = nan;
        [yeOn,yeOff]     = deal(E);
        yeOn(lFlagged)   = nan;
        yeOff(~lFlagged) = nan;
        [ymOn,ymOff]     = deal(M);
        ymOn(lFlagged)   = nan;
        ymOff(~lFlagged) = nan;
        [yrOn,yrOff]     = deal(R);
        yrOn(lFlagged)   = nan;
        yrOff(~lFlagged) = nan;     

        hd = [];
        hm = [];
        hr = [];
               
           
        switch lower(sType{:})
            
            case {'apres','amplitude'}
                
                if lShowData
                     
                    hd = semilogy(hAmp,xd,ydOn,'marker',thisMarker,'markersize',markerSize,'LineStyle','none');
                    for i = 1:length(hd) 
                        set(hd(i),'userdata',ID(:,i)','tag','dataID');
                    end
                                                    
                    hColorsApr = sub_setColors(hd,hColorsApr,iMode,lineColors);
                    
                    set(hAmp,'nextplot','add','yScale','log')
                    
                    yUpper = ydOn+yeOn;
                    yLower = ydOn-yeOn;
                    iNeg = yLower < 0;
                    if any(iNeg)
                        logErr = yeOn(iNeg)./ydOn(iNeg)*.4343;
                        yLower(iNeg) = 10.^(log10(ydOn(iNeg)) - logErr);
                    end
                    yLower(yLower < 0 ) = ydOn(yLower < 0) *.000001;   
                    
                    clear he;
                    for i = 1:size(ydOn,2)
                        yL = yLower(:,i);
                        yU = yUpper(:,i);
                        he  = semilogy(hAmp,[xd xd]',[yL yU]','-','linewidth',lineWidth,'color',hd(i).Color);
                    end
  
                    % Flagged data:
                    if lShowOffData
                        h = semilogy(hAmp,xd,ydOff,'marker','x','markersize',4,'linestyle','none'); 
                        for i = 1:length(h) 
                            set(h(i),'userdata',ID(:,i)','tag','dataID','color',hd(i).MarkerFaceColor)                                
                        end
                    end 

                end
                
                if lShowModel
                        
                    if lShowOffData % plot evertything
                        hm = semilogy(hAmp,xd,M,'marker','none','LineStyle',thisLineStyle,'linewidth',lineWidth);
                    else
                        hm = semilogy(hAmp,xd,ymOn,'marker','none','LineStyle',thisLineStyle,'linewidth',lineWidth);
                    end

                    for i = 1:length(hm)
                        set(hm(i),'userdata',ID(:,i)','tag','dataID');
                    end
              
                    hColorsApr = sub_setColors(hm,hColorsApr,iMode,lineColors);

                    set(hAmp,'nextplot','add','yScale','log')
                    
                end
                
                if lShowResiduals
                    
                    hr = plot(hAmpRes,xd,yrOn,'marker',thisMarker,'markersize',markerSize,'LineStyle','none');
                                                   
                    for i = 1:length(hr) 
                        set(hr(i),'userdata',ID(:,i)','tag','dataID');
                    end
                                                    
                    hColorsApr = sub_setColors(hr,hColorsApr,iMode,lineColors);
                    
                    set(hAmpRes,'nextplot','add')

                    % Flagged data:
                    if lShowOffData
                        h = semilogy(hAmpRes,xd,yrOff,'marker','x','markersize',4,'linestyle','none'); 
                        for i = 1:length(h) 
                            set(h(i),'userdata',ID(:,i)','tag','dataID');
                        end
                    end                    
                end
                
                
                % Legend:
 
                if ~isempty(hm)
                     lh = hm;
                elseif ~isempty(hd)
                     lh = hd;
                else
                     lh = hr;                        
                end
                
              
                
                [~, n,e] = fileparts(st.sFile);     
                
                thisFile = strcat(n,e);
                
                for i = 1:length(lh)
                    ilcnt = ilcnt + 1;
                    
                    legstr{ilcnt}   = sprintf('%s %s %s ',sMode{:},st.stMT.receiverName{iRxSelected(i)},thisFile);
             
                    leghandle(ilcnt) = lh(i);
            
                end
             
            case {'phase','imaginary'}
       
                if lShowData
                     
                    hd = plot(hPhs,xd,ydOn,'marker',thisMarker,'markersize',markerSize,'LineStyle','none');
                    for i = 1:length(hd) 
                        set(hd(i),'userdata',ID(:,i)','tag','dataID');
                    end
                    
                    hColorsApr = sub_setColors(hd,hColorsApr,iMode,lineColors);
                    
                    set(hAmp,'nextplot','add')                   
                    
                    yUpper = ydOn+yeOn;
                    yLower = ydOn-yeOn;
                    
                    clear he;
                    for i = 1:size(D,2)
                        yL = yLower(:,i);
                        yU = yUpper(:,i);
                        he  = plot(hPhs,[xd xd]',[yL yU]','-','linewidth',lineWidth,'color',hd(i).Color);
                    end
                    
                    % Flagged data:
                    if lShowOffData
                        h = plot(hPhs,xd,ydOff,'marker','x','markersize',4,'linestyle','none'); 
                        for i = 1:length(h) 
                            set(h(i),'userdata',ID(:,i)','tag','dataID','color',hd(i).MarkerFaceColor)                                
                        end
                    end   
                    
                end
                
                if lShowModel
                    
                    if lShowOffData % plot evertything
                        hm = plot(hPhs,xd,M,'marker','none','markersize',markerSize,'LineStyle',thisLineStyle,'linewidth',lineWidth);
                    else
                        hm = plot(hPhs,xd,ymOn,'marker','none','markersize',markerSize,'LineStyle',thisLineStyle,'linewidth',lineWidth);                        
                    end
                    for i = 1:length(hm)
                        set(hm(i),'userdata',ID(:,i)','tag','dataID');
                    end
                    
                    hColorsApr = sub_setColors(hm,hColorsApr,iMode,lineColors);
                    
                    set(hPhs,'nextplot','add')
                    
                end
                
                if lShowResiduals
                    
                    hr = plot(hPhsRes,xd,yrOn,'marker',thisMarker,'markersize',markerSize,'LineStyle','none');
                    for i = 1:length(hr) 
                        set(hr(i),'userdata',ID(:,i)','tag','dataID');
                    end 
                    
                    hColorsApr = sub_setColors(hr,hColorsApr,iMode,lineColors);
                    
                    set(hPhsRes,'nextplot','add')

                    % Flagged data:
                    if lShowOffData
                        h = plot(hPhsRes,xd,yrOff,'marker','x','markersize',4,'linestyle','none'); 
                        for i = 1:length(h) 
                            set(h(i),'userdata',ID(:,i)','tag','dataID');
                        end
                    end     
                    
                end
                
            case 'real'
                
                if lShowData
                     
                    hd = plot(hAmp,xd,ydOn,'marker',thisMarker,'markersize',markerSize,'LineStyle','none');
                    for i = 1:length(hd) 
                        set(hd(i),'userdata',ID(:,i)','tag','dataID');
                    end
                    
                    hColorsApr = sub_setColors(hd,hColorsApr,iMode,lineColors);
                    
                    set(hAmp,'nextplot','add')                   
                    
                    yUpper = ydOn+yeOn;
                    yLower = ydOn-yeOn;
                    
                    clear he;
                    for i = 1:size(D,2)
                        yL = yLower(:,i);
                        yU = yUpper(:,i);
                        he  = plot(hAmp,[xd xd]',[yL yU]','-','linewidth',lineWidth,'color',hd(i).Color);
                    end
                    
                    % Flagged data:
                    if lShowOffData
                        h = plot(hAmp,xd,ydOff,'marker','x','markersize',4,'linestyle','none'); 
                        for i = 1:length(h) 
                            set(h(i),'userdata',ID(:,i)','tag','dataID','color',hd(i).MarkerFaceColor)                                
                        end
                    end   
                    
                end
                
                if lShowModel
                    
                    if lShowOffData % plot evertything
                        hm = plot(hAmp,xd,M,'marker','none','markersize',markerSize,'LineStyle',thisLineStyle,'linewidth',lineWidth);
                    else
                        hm = plot(hAmp,xd,ymOn,'marker','none','markersize',markerSize,'LineStyle',thisLineStyle,'linewidth',lineWidth);                        
                    end
                    for i = 1:length(hm)
                        set(hm(i),'userdata',ID(:,i)','tag','dataID');
                    end
                    
                    hColorsApr = sub_setColors(hm,hColorsApr,iMode,lineColors);
                    
                    set(hAmp,'nextplot','add')
                    
                end
                
                if lShowResiduals
                    
                    hr = plot(hAmpRes,xd,yrOn,'marker',thisMarker,'markersize',markerSize,'LineStyle','none');
                    for i = 1:length(hr) 
                        set(hr(i),'userdata',ID(:,i)','tag','dataID');
                    end 
                    
                    hColorsApr = sub_setColors(hr,hColorsApr,iMode,lineColors);
                    
                    set(hAmpRes,'nextplot','add')

                    % Flagged data:
                    if lShowOffData
                        h = plot(hAmpRes,xd,yrOff,'marker','x','markersize',4,'linestyle','none'); 
                        for i = 1:length(h) 
                            set(h(i),'userdata',ID(:,i)','tag','dataID');
                        end
                    end     
                    
                end
                
                
                % Legend:
 
                if ~isempty(hm)
                     lh = hm;
                elseif ~isempty(hd)
                     lh = hd;
                else
                     lh = hr;                        
                end
                                
                [~, n,e] = fileparts(st.sFile);     
                
                thisFile = strcat(n,e);
                
                for i = 1:length(lh)
                    ilcnt = ilcnt + 1;
                    
                    legstr{ilcnt}   = sprintf('%s %s %s ',sMode{:},st.stMT.receiverName{iRxSelected(i)},thisFile);
             
                    leghandle(ilcnt) = lh(i);
            
                end                
                
            otherwise
                fprintf('This type not yet support in single plot mode: %s\n',sType)
        end
        
        
        
    end
    
    if iFile == 1
        if ~isempty(hd)
            hd1 = hd;
        elseif ~isempty(hm)
            hm1 = hm; 
        else
            hr1 = hr;
        end
    end

end % Loop over files


if bTipperRI && ~isempty(hAmp) && ~isempty(hPhs)
    ylA = get(hAmp,'ylim');
    ylP = get(hPhs,'ylim');
    ylower = min([ylA ylP]);
    yupper = max([ylA ylP]);
    set(hAmp,'ylim',[ylower yupper] ); 
    set(hPhs,'ylim',[ylower yupper] );  
        
else
    
    if ~isempty(hAmp)
        yl = get(hAmp,'ylim');
        if ~bTipperRI
            ylower = 10.^floor(log10(yl(1)));
            yupper = 10.^ceil(log10(yl(2)));
        end
        set(hAmp,'ylim',[ylower yupper] );   
    end
    if ~isempty(hPhs)
        yl = get(hPhs,'ylim');
        ylower = floor(yl(1)/45)*45  ;
        yupper = ceil(yl(2)/45)*45  ;
        set(hPhs,'ylim',[ylower yupper] );  
    end
    
end

if lShowResiduals

    uistack( plot( hAmpRes, xlim(hAmpRes), [0 0], '--k' ...
                 , 'HitTest', 'off', 'tag', 'zeroline', 'DisplayName', '' )  , 'bottom' );

    
    uistack( plot( hPhsRes, xlim(hPhsRes), [0 0], '--k' ...
                 , 'HitTest', 'off', 'tag', 'zeroline', 'DisplayName', '' )  , 'bottom' );
              
    ylA = abs(get(hAmpRes,'ylim'));
    ylP = abs(get(hPhsRes,'ylim'));
     
    yl = max([ylA(:);ylP(:)]);
    
    set(hAmpRes,'ylim',yl*[-1.05 1.05] );  
    set(hPhsRes,'ylim',yl*[-1.05 1.05] );  
    
    linkaxes([hAmpRes hPhsRes] ,'y')
  
end

if ~handles.lUsePeriod  % so "shallow" sensitive data is on left and deeper sensitivity is on the right:
    set([hAmp;hPhs],'xdir','rev');
    if lShowResiduals
        set([hAmpRes;hPhsRes],'xdir','rev');
    end
end
 
if ~isempty(leghandle) && ilcnt < 20
    hl = legend(leghandle(1:ilcnt),legstr(1:ilcnt),'interpreter','none');
    set(hl,'edgecolor','w'); 
end

set(handles.hAxes,'xlim',handles.xlims ,'xgrid','on','ygrid','on');  

linkaxes(handles.hAxes,'x')

set(handles.hAxes,'visible','on');  

set( handles.figure1, 'Pointer', 'arrow' );
drawnow;

end

%-------------------------------------------------------------------------
function handles = sub_makePseudosectionPlot(handles)
 
lShowResiduals = handles.showResiduals.Value     & strcmpi(handles.showResiduals.Enable,'on');
lShowModel     = handles.showModelResponse.Value & strcmpi(handles.showModelResponse.Enable,'on'); 
lShowData      = handles.showData.Value          & strcmpi(handles.showData.Enable,'on');
lShowOffData   = get(findobj(handles.figure1,'tag','showOffData'),'value');
 
nComps         = length(handles.sComps);
 
 %check for Tipper: 
bTipperAP = false;
bTipperRI = false;
if any(strcmpi(handles.sComps,'Mzy (TE)'))
    % Check for Real & Imag or Amp & Phs
    if any( [handles.st(1).Cmps.Cmp] == 135 ) ||  any([handles.st(1).Cmps.Cmp] == 136 )
        bTipperAP = true;
    elseif any( [handles.st(1).Cmps.Cmp] == 133) ||  any([handles.st(1).Cmps.Cmp] == 134 )
        bTipperRI = true;
    end   
end  



% Get the data structure:
st = handles.st(handles.iFiles(1));
sDataCodeLookupTable = m2d_getDataCodeLookupTable();

if size(st.DATA,2) < 8
    lShowModel     = false;
    lShowResiduals = false;
end

if ~lShowModel && ~lShowData && ~lShowResiduals
    return
end

set( handles.figure1, 'Pointer', 'watch' );
drawnow;

% Create Amplitude and Phase axes:
nCols = nComps*2; % column for rho, column for phase
nRows = 0;
if lShowData
    nRows = nRows + 1;
end
if lShowModel == 1  
    nRows = nRows + 1;
end
if lShowResiduals == 1
    nRows = nRows + 1;
end    

lColorbar = false;
[posX,posY,widX,widY]= getRowColPositions(handles,nRows,nCols,lColorbar);

%
ict  = 0;
hAmp = gobjects(nRows,nCols/2);
hPhs = gobjects(nRows,nCols/2); 
handles.hAxes = gobjects(nRows,nCols);

for iCol = 1:2:nCols
    ict = ict+1;  
    
    % Amplitude plots:
    for iRow = 1:nRows
        
        posAmp = [ posX(iCol)   posY(nRows-iRow+1) widX(iCol)   widY(nRows-iRow+1)];
        posPhs = [ posX(iCol+1) posY(nRows-iRow+1) widX(iCol+1) widY(nRows-iRow+1)];
        
        hAmp(iRow,ict) = axes(handles.figure1,'units','pixels','position', posAmp,'tag','hAxMT');  
        
        hCb = colorbar('peer',hAmp(iRow,ict));
       
        if bTipperAP 
            hCb.Label.String = 'log10(amplitude)';  
        elseif bTipperRI 
            hCb.Label.String = 'Tipper Real';      
        else
            hCb.Label.String = 'log10(ohm-m)';    
        end
        if lShowResiduals && iRow == nRows
           hCb.Label.String = 'normalized residual';   
        end
        
        hPhs(iRow,ict) = axes(handles.figure1,'units','pixels','position', posPhs,'yticklabel',[],'tag','hAxMT');  

        hCb = colorbar('peer',hPhs(iRow,ict));
        hCb.Label.String = 'degrees';
        if bTipperRI 
            hCb.Label.String = 'Tipper Imag';   
        end
        if lShowResiduals && iRow == nRows
           hCb.Label.String = 'normalized residual';   
        end
        
        if iCol > 1
            set(hAmp(iRow,ict),'yticklabel',[]);
        else
            if handles.lUsePeriod 
                ylabel(hAmp(iRow,ict),'log10 Period (s)')
            else
                ylabel(hAmp(iRow,ict),'log10 Frequency (Hz)')    
            end
        end
        if iRow ~= nRows
            set(hAmp(iRow,ict),'xticklabel',[]);
            set(hPhs(iRow,ict),'xticklabel',[]);
        else
            xlabel(hPhs(iRow,ict),handles.xlab);
            xlabel(hAmp(iRow,ict),handles.xlab)
        end
     
        handles.hAxes(iRow,iCol)   = hAmp(iRow,ict);
        handles.hAxes(iRow,iCol+1) = hPhs(iRow,ict);
        
    end
end
 

cm = m2d_colormaps(handles.sColorMap);
colormap(cm);
 

backGroundColor = [.9 .9 .9];

set(handles.hAxes,'layer','top','box','on','tickdir','out','TickLength',[.005 .005],'color',backGroundColor);
set(handles.hAxes,'xlim',handles.xlims,'Visible','on','fontsize',handles.fontSize,'color',backGroundColor);  


if handles.lUsePeriod
    set(handles.hAxes,'ydir','rev')
end

iColCnt = 0;

lColApRes = false(length(st.Cmps),1);
% Loop over components:
for iCmp = 1:length(st.Cmps)

    % Is this component selected for plotting?
    sComp = sDataCodeLookupTable{st.Cmps(iCmp).Cmp,1};
    if ismember(sComp,handles.sComps)

        iColCnt = iColCnt + 1;    
        
        % Yes, pull out data:
        d   =  squeeze(st.Cmps(iCmp).d);  
        m   =  squeeze(st.Cmps(iCmp).m);
        r   =  squeeze(st.Cmps(iCmp).r);
        id  =  squeeze(st.Cmps(iCmp).iData);
        
        % Get x position:
        if handles.lUseRxPosition
            xPos = st.stMT.receivers(:,2);
            xPos = xPos /1d3;
            xPos = unique(xPos);

        else
            xPos = (1:length( st.stMT.receivers(:,2)))';
        end        
        
        % Sort arrays based on x position, if needed:
        [xPos, ixsort] = sort(xPos);
        
        d = d(ixsort,:);
        r = r(ixsort,:);
        m = m(ixsort,:);    
        
        % Get y positions:
        yPos = st.stMT.frequencies;
        if handles.lUsePeriod
            yPos = 1./yPos;
        end
        yPos = log10(yPos);        
        
        % Array for color patch positions:
        [X,Y] = deal(zeros(4,length(xPos)*length(yPos)));

        lUse = false(size(d));
        
        lFlagged = false(length(xPos)*length(yPos),1);
        ID       = zeros(length(xPos)*length(yPos),1);
        
        dx = diff(xPos);
        %dx(end+1) = dx(end);
        dy = diff(yPos);
        %dy(end+1) = dy(end);
     
        xm = [xPos(1)-dx(1)/2; xPos(1:end-1) + dx/2; xPos(end) + dx(end)/2];
        ym = [yPos(1)-dy(1)/2; yPos(1:end-1) + dy/2; yPos(end) + dy(end)/2];
        
        nAdded = 0;
        
        % Make patches:
        for j = 1:size(d,2)  % Columns for frequencies
            for i = 1:size(d,1)  % rows for Rx
                if ~isnan(d(i,j)) ||  ~isnan(m(i,j))

                    nAdded = nAdded + 1;

                    X(1,nAdded) = xm(i); % xPos(i) - dx(i)/2;  % left 
                    X(2,nAdded) = xm(i); % xPos(i) - dx(i)/2;  % left 
                    X(3,nAdded) = xm(i+1); % xPos(i) + dx(i)/2;  % right 
                    X(4,nAdded) = xm(i+1); % xPos(i) + dx(i)/2;  % right

                    Y(1,nAdded) = ym(j); %yPos(j) - dy(j)/2;  % bottom
                    Y(2,nAdded) = ym(j+1); %yPos(j) + dy(j)/2;  % top
                    Y(3,nAdded) = ym(j+1); %yPos(j) + dy(j)/2;  % top 
                    Y(4,nAdded) = ym(j); %yPos(j) - dy(j)/2;  % bottom    
                    
                    lUse(i,j) = true;
                    ID(nAdded) = id(i,j);
                    
                    if ~isnan(id(i,j))
                        
                        if st.iFlagged(id(i,j)) 
                            lFlagged(nAdded) = true;
                        end
                    else 
                        fprintf('this i,j has nan id?: %i %i\n',i,j)
                    end

                end

            end
        end
   
        X        = X(:,1:nAdded);
        Y        = Y(:,1:nAdded);
        lFlagged = lFlagged(1:nAdded);
        ID       = ID(1:nAdded);
 
        switch lower(sDataCodeLookupTable{ st.Cmps(iCmp).Cmp,2})

            case {'apres','amplitude'}
                
                iRowCnt = 0;

                lColApRes(iColCnt) = true;
                        
                if lShowData
                    
                    iRowCnt = iRowCnt + 1;
                    axes(handles.hAxes(iRowCnt,iColCnt));
                      
                    C = log10(abs(d(lUse)));
 
                    patch(X(:,~lFlagged),Y(:,~lFlagged),C(~lFlagged));
                    if any(strcmpi(handles.sComps,'Mzy (TE)'))
                        title(sprintf(' Data Tipper %s',sComp))  
                    else
                        title(sprintf(' Data App. Res. %s',sComp))
                    end
                    axis tight
                    shading flat;
                    
                    hold on;
                    
                    if lShowOffData
                        patch(X(:,lFlagged),Y(:,lFlagged),C(lFlagged));
                        shading flat
                        plot(mean(X(:,lFlagged),1),mean(Y(:,lFlagged),1),'kx','markersize',4,'handlevisibility','off'); 
                    end    
                    
                    % Dummy plot dots for flagging data on or off:
                    h = plot(mean(X,1),mean(Y,1),'linestyle','none','marker','none');
                    set(h,'userdata',ID,'tag','dataID');            
                     
                       
                end
                
                if lShowModel

                    C = log10(abs(m(lUse)));
                    
                    iRowCnt = iRowCnt + 1;
                    axes(handles.hAxes(iRowCnt,iColCnt));
                    
                    patch(X(:,~lFlagged),Y(:,~lFlagged),C(~lFlagged));
                    if any(strcmpi(handles.sComps,'Mzy (TE)'))
                        title(sprintf(' Model Tipper %s',sComp))  
                    else
                        title(sprintf(' Model App. Res. %s',sComp))
                    end                     
                  
                    axis tight
                    shading flat;  
                    
                    hold on;
                    if lShowOffData
                        patch(X(:,lFlagged),Y(:,lFlagged),C(lFlagged));
                        shading flat
                        plot(mean(X(:,lFlagged),1),mean(Y(:,lFlagged),1),'kx','markersize',4,'handlevisibility','off'); 
                    end                   
                    
                    % Dummy plot dots for flagging data on or off:
                    h = plot(mean(X,1),mean(Y,1),'linestyle','none','marker','none');
                    set(h,'userdata',ID,'tag','dataID');     

                end

                if lShowResiduals

                    C = r(lUse);
                    
                    iRowCnt = iRowCnt + 1;
                    axes(handles.hAxes(iRowCnt,iColCnt));
                    
                    patch(X(:,~lFlagged),Y(:,~lFlagged),C(~lFlagged)); 
                    
                    if any(strcmpi(handles.sComps,'Mzy (TE)'))
                        title(sprintf(' Residual Tipper %s',sComp))  
                    else
                        title(sprintf(' Residual App. Res. %s',sComp))
                    end      
                    
                    axis tight
                    shading flat;
                    mx = max([abs(min(C)) abs(max(C))]);
                    caxis([-mx mx])
                    
                    hold on;
                    if lShowOffData
                        patch(X(:,lFlagged),Y(:,lFlagged),C(lFlagged));
                        shading flat
                        plot(mean(X(:,lFlagged),1),mean(Y(:,lFlagged),1),'kx','markersize',4,'handlevisibility','off'); 
                    end                    
                    
                    
                    % Dummy plot dots for flagging data on or off:
                    h = plot(mean(X,1),mean(Y,1),'linestyle','none','marker','none');
                    set(h,'userdata',ID,'tag','dataID'); 
                   
                end

            case 'phase'
                
                iRowCnt = 0;

                if lShowData

                    C = d(lUse);
                    
                    iRowCnt = iRowCnt + 1;
                    axes(handles.hAxes(iRowCnt,iColCnt));
                    
                    patch(X(:,~lFlagged),Y(:,~lFlagged),C(~lFlagged)); 
                    title(sprintf(' Data Phase %s',sComp))
                    axis tight
                    shading flat;
                    
                    hold on;
                    
                    if lShowOffData
                        patch(X(:,lFlagged),Y(:,lFlagged),C(lFlagged));
                        shading flat
                        plot(mean(X(:,lFlagged),1),mean(Y(:,lFlagged),1),'kx','markersize',4,'handlevisibility','off'); 
                    end  
                    
                    % Dummy plot dots for flagging data on or off:
                    h = plot(mean(X,1),mean(Y,1),'linestyle','none','marker','none');
                    set(h,'userdata',ID,'tag','dataID'); 
                   
                end
                
                if lShowModel
                    
                    iRowCnt = iRowCnt + 1;
                    axes(handles.hAxes(iRowCnt,iColCnt));
                    
                    C = m(lUse);
                  
                    patch(X(:,~lFlagged),Y(:,~lFlagged),C(~lFlagged)); 
                    title(sprintf(' Model Phase %s',sComp))
                    axis tight
                    shading flat;  
                    
                    hold on;
              
                    if lShowOffData
                        patch(X(:,lFlagged),Y(:,lFlagged),C(lFlagged));
                        shading flat
                        plot(mean(X(:,lFlagged),1),mean(Y(:,lFlagged),1),'kx','markersize',4,'handlevisibility','off'); 
                    end    
                    
                    % Dummy plot dots for flagging data on or off:
                    h = plot(mean(X,1),mean(Y,1),'linestyle','none','marker','none');
                    set(h,'userdata',ID,'tag','dataID'); 
                   
                end

                if lShowResiduals

                    C = r(lUse);
                    
                    iRowCnt = iRowCnt + 1;
                    axes(handles.hAxes(iRowCnt,iColCnt));
                    
                    patch(X(:,~lFlagged),Y(:,~lFlagged),C(~lFlagged)); 
                    title(sprintf(' Residual Phase %s',sComp))
                    axis tight
                    shading flat;
                    mx = max([abs(min(C)) abs(max(C))]);
                    caxis([-mx mx])
                    
                    hold on;
                     
                    if lShowOffData
                        patch(X(:,lFlagged),Y(:,lFlagged),C(lFlagged));
                        shading flat
                        plot(mean(X(:,lFlagged),1),mean(Y(:,lFlagged),1),'kx','markersize',4,'handlevisibility','off'); 
                    end    
                    
                    % Dummy plot dots for flagging data on or off:
                    h = plot(mean(X,1),mean(Y,1),'linestyle','none','marker','none');
                    set(h,'userdata',ID,'tag','dataID'); 
                   
                end


        end  

    end
end

  iColsApRes = find(lColApRes);
  iColsPhs   = find(~lColApRes);
    
if lShowData && lShowModel % link color scale limits:
    
    for i = 1:size(handles.hAxes,2)
        ca1 = caxis(handles.hAxes(1,i));
        ca2 = caxis(handles.hAxes(2,i));
        
        caxis(handles.hAxes(1,i),[min(([ca1(1) ca2(1)])) max(abs([ca1(2) ca2(2)]))])
        caxis(handles.hAxes(2,i),[min(([ca1(1) ca2(1)])) max(abs([ca1(2) ca2(2)]))])
        linkprop(handles.hAxes(1:2,i),'clim');
        
    end
    
end

if lShowResiduals

    cm = m2d_colormaps('D1');
    for i = 1:length(handles.hAxes(end,:))
        colormap(handles.hAxes(end,i),cm);
    end
    cMin =  inf;
    cMax = -inf;
    for i = 1:size(handles.hAxes,2)
        ca = caxis(handles.hAxes(end,i));
        cMin = min([ca(1) cMin]);
        cMax = max([ca(2) cMax]);
    end 
    for i = 1:size(handles.hAxes,2)
        caxis(handles.hAxes(end,i),[cMin cMax])
    end
    linkprop(handles.hAxes(end,:),'clim');
        
end

set(handles.hAxes,'xlim',handles.xlims);

if ~handles.lUseRxPosition
    
%     lRxPlotted = a(lUse,2);
%     set(handles.hAxes(end,:),'xtick',1:length(st.stMT.receivers(lRxPlotted,1)));
%     xlab = st.stMT.receiverName(lRxPlotted);
    set(handles.hAxes(end,:),'xtick',1:length(st.stMT.receivers(:,1)));
    xlab = st.stMT.receiverName;
    set(handles.hAxes(end,:),'xticklabel',xlab);
    if size(xlab,1) > 6
        for i = 1:length(handles.hAxes(end,:))
            axes(handles.hAxes(end,i));
            xticklabel_rotate;
        end
    end
end


%set(handles.hAxes,'visible','on')
linkaxes(handles.hAxes,'x')


set(handles.hAxes,'Visible','on');  
 
set( handles.figure1, 'Pointer', 'arrow' );
drawnow;

end


%--------------------------------------------------------------------------
function handles = sub_makeProfilePlot(handles)

lShowResiduals = handles.showResiduals.Value     & strcmpi(handles.showResiduals.Enable,'on');
lShowModel     = handles.showModelResponse.Value & strcmpi(handles.showModelResponse.Enable,'on'); 
lShowData      = handles.showData.Value          & strcmpi(handles.showData.Enable,'on'); 
lShowOffData   = get(findobj(handles.figure1,'tag','showOffData'),'value');

%check for Tipper: 
bTipperAP = false;
bTipperRI = false;
if any(strcmpi(handles.sComps,'Mzy (TE)'))
    % Check for Real & Imag or Amp & Phs
    if any( [handles.st(1).Cmps.Cmp] == 135 ) ||  any([handles.st(1).Cmps.Cmp] == 136 )
        bTipperAP = true;
    elseif any( [handles.st(1).Cmps.Cmp] == 133) ||  any([handles.st(1).Cmps.Cmp] == 134 )
        bTipperRI = true;
    end   
end  

% Create Amplitude and Phase axes:
 
nRows = 0;
nCols = 0;
if lShowData || lShowModel
    nRows = 1;
    nCols = 1;
end
if lShowResiduals == 1
    nRows = nRows + 1;
    nCols = 2;
else
    nRows = 2;
end   

if nCols == 0
    return
end

[posX,posY,widX,widY]= getRowColPositions(handles,nRows,nCols,false);

% Either 2 x 1 (no residuals or only residuals),  2 x 2 plot (w/residuals), 
posAmp = [];
posPhs = [];
posAmpRes = [];
posPhsRes = [];

if nRows == 2 && nCols == 2
    posAmp      = [ posX(1) posY(2) widX(1) widY(2)];
    posAmpRes   = [ posX(1) posY(1) widX(1) widY(1)];
    posPhs      = [ posX(2) posY(2) widX(1) widY(2)];
    posPhsRes   = [ posX(2) posY(1) widX(1) widY(1)];
else
    if lShowResiduals
        posAmpRes   = [ posX(1) posY(1) widX(1) widY(1)];
        posPhsRes   = [ posX(2) posY(1) widX(1) widY(1)];    
    else
        posAmp      = [ posX(1) posY(2) widX(1) widY(2)];
        posPhs      = [ posX(1) posY(1) widX(1) widY(1)];        
    end
end

hAmp = [];
hPhs = [];
hAmpRes = [];
hPhsRes = [];

if ~isempty(posAmp)
    hAmp = axes(handles.figure1,'units','pixels','position', posAmp,'tag','hAxMT');
    
    if bTipperRI
        ylabel(hAmp,'Real')
        set(hAmp,'yscale','lin');
    elseif bTipperAP    
        ylabel(hAmp,'Amplitude')
        set(hAmp, 'yscale','log');        
    else
        ylabel(hAmp,'ohm-m')
        set(hAmp,'yscale','log');
    end
    
end
if ~isempty(posPhs)
    hPhs = axes(handles.figure1,'units','pixels','position', posPhs,'tag','hAxMT');  
    
    if bTipperRI
        ylabel(hPhs,'Imag')
        set(hPhs, 'yscale','lin');
    elseif bTipperAP    
        ylabel(hPhs,'degrees')
        set(hPhs,'yscale','lin'); 
    else    
        ylabel(hPhs,'degrees')
        set(hPhs,'ylim',[0 90]);
    end
    
end
if ~isempty(posAmpRes)
    hAmpRes = axes(handles.figure1,'units','pixels','position', posAmpRes,'tag','hAxMT');
    ylabel(hAmpRes,'Normalized Residual')
end
if ~isempty(posPhsRes)
    hPhsRes = axes(handles.figure1,'units','pixels','position', posPhsRes,'tag','hAxMT');
    ylabel(hPhsRes,'Normalized Residual')
end

handles.hAxes = [hAmp hPhs; hAmpRes hPhsRes];
set( handles.hAxes,'fontsize',handles.fontSize,'box','on')
 
for i = 1:length(handles.hAxes(:))
    xlabel( handles.hAxes(i),handles.xlab)
end

set( handles.hAxes,'nextplot','add')

set(handles.hAxes,'xlim',handles.xlims,'tag','hAxes' );  
  
sDataCodeLookupTable = m2d_getDataCodeLookupTable();
 
iFreqsSelected  = handles.frequencyListbox.Value;
iRxSelected     = handles.receiverListbox.Value;
sComps          = handles.componentsListbox.String(handles.componentsListbox.Value); 

maxCnt =   length(handles.sComps)*length(iFreqsSelected);

set( handles.figure1, 'Pointer', 'watch' );
drawnow;

lineStyles = handles.lineStyles;
thisMarker = handles.marker;
markerSize = handles.markerSize;
lineWidth  = handles.lineWidth;

lineColors = feval(handles.sLineColorMap,maxCnt);

ilcnt     = 0;
leghandle = zeros(maxCnt,1);
legstr    = cell(maxCnt,1);

hColorsApr = cell(2,1);
hColorsPhs = cell(2,1);

for iFile = 1:length(handles.iFiles)
    
    ind = mod(iFile-1,size(lineStyles,2))+1;
    
    thisLineStyle = lineStyles{ind};
 
    st = handles.st(handles.iFiles(iFile));
  
    for iComp = 1:length(st.Cmps)  %handles.sComps)
   
        sMode = sDataCodeLookupTable(st.Cmps(iComp).Cmp,1);
        
        % Get iMode for line appearance:
        [~,iMode] = ismember(sMode,handles.sComps);
        
        if ~any(ismember(handles.sComps,sMode))
            continue;
        end
 
        sType = sDataCodeLookupTable(st.Cmps(iComp).Cmp,2);
  
        D  = st.Cmps(iComp).d(iRxSelected,iFreqsSelected);
        E  = st.Cmps(iComp).e(iRxSelected,iFreqsSelected);
        R  = st.Cmps(iComp).r(iRxSelected,iFreqsSelected);
        M  = st.Cmps(iComp).m(iRxSelected,iFreqsSelected);
        ID = st.Cmps(iComp).iData(iRxSelected,iFreqsSelected);
        
        if handles.lUseRxPosition
            xd = st.stMT.receivers(iRxSelected,2)/1d3;
        else
            xd = [1:length(iRxSelected)]';
        end   
        
        frequencies = st.stMT.frequencies(iFreqsSelected);
        
        [xd, ixsort] = sort(xd);
        
        D  = D(ixsort,:);
        E  = E(ixsort,:);
        R  = R(ixsort,:);
        M  = M(ixsort,:);
        ID = ID(ixsort,:);
       
        %
        % Check for any flagged data:
        %

        lFlagged = false(size(ID));
        lFlagged(~isnan(ID)) =  st.iFlagged(ID(~isnan(ID))); 

        [ydOn,ydOff]     = deal(D);
        ydOn(lFlagged)   = nan;
        ydOff(~lFlagged) = nan;
        [yeOn,yeOff]     = deal(E);
        yeOn(lFlagged)   = nan;
        yeOff(~lFlagged) = nan;
        [ymOn,ymOff]     = deal(M);
        ymOn(lFlagged)   = nan;
        ymOff(~lFlagged) = nan;
        [yrOn,yrOff]     = deal(R);
        yrOn(lFlagged)   = nan;
        yrOff(~lFlagged) = nan;     

        hd = [];
        hm = [];
        hr = [];
               
           
        switch lower(sType{:})
            
            case {'apres','amplitude'}
                
                if lShowData
                     
                    hd = semilogy(hAmp,xd,ydOn,'marker',thisMarker,'markersize',markerSize,'LineStyle','none');
                    for i = 1:length(hd) 
                        set(hd(i),'userdata',ID(:,i),'tag','dataID');
                    end
                                                    
                    hColorsApr = sub_setColors(hd,hColorsApr,iMode,lineColors);
                    
                    set(hAmp,'nextplot','add','yScale','log')
                    
                    yUpper = ydOn+yeOn;
                    yLower = ydOn-yeOn;
                    iNeg = yLower < 0;
                    if any(iNeg)
                        logErr = yeOn(iNeg)./ydOn(iNeg)*.4343;
                        yLower(iNeg) = 10.^(log10(ydOn(iNeg)) - logErr);
                    end
                    yLower(yLower < 0 ) = ydOn(yLower < 0) *.000001;   
                    
                    clear he;
                    for i = 1:size(ydOn,2)
                        yL = yLower(:,i);
                        yU = yUpper(:,i);
                        he  = semilogy(hAmp,[xd xd]',[yL yU]','-','linewidth',lineWidth,'color',hd(i).Color);
                    end
  
                    % Flagged data:
                    if lShowOffData
                        h = semilogy(hAmp,xd,ydOff,'marker','x','markersize',4,'linestyle','none'); 
                        for i = 1:length(h) 
                            set(h(i),'userdata',ID(:,i),'tag','dataID','color',hd(i).MarkerFaceColor)                                
                        end
                    end 

                end
                
                if lShowModel
                    clear hm;
                    for i = 1:size(M,2)  % loop to deal with data frequency by frequency so that 
                                         % missing data can be skipped and lines plotted unbroken
                        mm = M(:,i);
                        lGood = ~isnan(mm);
                        mm = mm(lGood);
                        mx = xd(lGood);
                        
                        mmOn = ymOn(:,i);
                        lGood = ~isnan(mm);
                        mmOn = mmOn(lGood);
                        mxOn = xd(lGood);
                        if lShowOffData % plot evertything
                            hm(i) = semilogy(hAmp,mx,mm,'marker','none','LineStyle',thisLineStyle,'linewidth',lineWidth);
                        else
                            hm(i) = semilogy(hAmp,mxOn,ymOn,'marker','none','LineStyle',thisLineStyle,'linewidth',lineWidth);
                        end
                    end

                    for i = 1:length(hm)
                        set(hm(i),'userdata',ID(:,i),'tag','dataID');
                    end
              
                    hColorsApr = sub_setColors(hm,hColorsApr,iMode,lineColors);

                    set(hAmp,'nextplot','add','yScale','log')
                    
                end
                
                if lShowResiduals
                    
                    hr = plot(hAmpRes,xd,yrOn,'marker',thisMarker,'markersize',markerSize,'LineStyle','none');
                                                   
                    for i = 1:length(hr) 
                        set(hr(i),'userdata',ID(:,i),'tag','dataID');
                    end
                                                    
                    hColorsApr = sub_setColors(hr,hColorsApr,iMode,lineColors);
                    
                    set(hAmpRes,'nextplot','add')

                    % Flagged data:
                    if lShowOffData
                        h = semilogy(hAmpRes,xd,yrOff,'marker','x','markersize',4,'linestyle','none'); 
                        for i = 1:length(h) 
                            set(h(i),'userdata',ID(:,i),'tag','dataID');
                        end
                    end                    
                end
                
                
                % Legend:
 
                if ~isempty(hm)
                     lh = hm;
                elseif ~isempty(hd)
                     lh = hd;
                else
                     lh = hr;                        
                end
              
                
                
                [~, n,e] = fileparts(st.sFile);     
                
                thisFile = strcat(n,e);
                
                for i = 1:length(lh)
                    ilcnt = ilcnt + 1;
                    if handles.lUsePeriod 
                        ff =  1./frequencies(i);
                        legstr{ilcnt} = sprintf('%s, %g s, %s ',sMode{:},ff,thisFile);
                    else
                        ff =  frequencies(i);
                        legstr{ilcnt} = sprintf('%s, %g Hz, %s ',sMode{:},ff,thisFile);
                    end

                    leghandle(ilcnt) = lh(i);
                end
             
            case 'phase'
       
                if lShowData
                     
                    hd = plot(hPhs,xd,ydOn,'marker',thisMarker,'markersize',markerSize,'LineStyle','none');
                    for i = 1:length(hd) 
                        set(hd(i),'userdata',ID(:,i),'tag','dataID');
                    end
                    
                    hColorsApr = sub_setColors(hd,hColorsApr,iMode,lineColors);
                    
                    set(hAmp,'nextplot','add')                   
                    
                    yUpper = ydOn+yeOn;
                    yLower = ydOn-yeOn;
                    
                    clear he;
                    for i = 1:size(D,2)
                        yL = yLower(:,i);
                        yU = yUpper(:,i);
                        he  = plot(hPhs,[xd xd]',[yL yU]','-','linewidth',lineWidth,'color',hd(i).Color);
                    end
                    
                    % Flagged data:
                    if lShowOffData
                        h = plot(hPhs,xd,ydOff,'marker','x','markersize',4,'linestyle','none'); 
                        for i = 1:length(h) 
                            set(h(i),'userdata',ID(:,i),'tag','dataID','color',hd(i).MarkerFaceColor)                                
                        end
                    end   
                    
                end
                
                if lShowModel
                    clear hm;
                    for i = 1:size(M,2)  % loop to deal with data frequency by frequency so that 
                                         % missing data can be skipped and lines plotted unbroken
                        mm = M(:,i);
                        lGood = ~isnan(mm);
                        mm = mm(lGood);
                        mx = xd(lGood);
                        
                        mmOn = ymOn(:,i);
                        lGood = ~isnan(mm);
                        mmOn = mmOn(lGood);
                        mxOn = xd(lGood);
                        if lShowOffData % plot evertything
                            hm(i) = plot(hPhs,mx,mm,'marker','none','markersize',markerSize,'LineStyle',thisLineStyle,'linewidth',lineWidth);
                        else
                            hm(i) = plot(hPhs,mxOn,mmOn,'marker','none','markersize',markerSize,'LineStyle',thisLineStyle,'linewidth',lineWidth);                        
                        end
                    end
                    for i = 1:length(hm)
                        set(hm(i),'userdata',ID(:,i),'tag','dataID');
                    end
                    
                    hColorsApr = sub_setColors(hm,hColorsApr,iMode,lineColors);
                    
                    set(hPhs,'nextplot','add')
                    
                end
                
                if lShowResiduals
                    
                    hr = plot(hPhsRes,xd,yrOn,'marker',thisMarker,'markersize',markerSize,'LineStyle','none');
                    for i = 1:length(hr) 
                        set(hr(i),'userdata',ID(:,i),'tag','dataID');
                    end 
                    
                    hColorsApr = sub_setColors(hr,hColorsApr,iMode,lineColors);
                    
                    set(hPhsRes,'nextplot','add')

                    % Flagged data:
                    if lShowOffData
                        h = plot(hPhsRes,xd,yrOff,'marker','x','markersize',4,'linestyle','none'); 
                        for i = 1:length(h) 
                            set(h(i),'userdata',ID(:,i),'tag','dataID');
                        end
                    end     
                    
                end
                
            %case     
                
            otherwise
                fprintf('This type not yet support in profile plotting: %s\n',sType)
        end
        
        
    end
    
    if iFile == 1
        if ~isempty(hd)
            hd1 = hd;
        elseif ~isempty(hm)
            hm1 = hm; 
        else
            hr1 = hr;
        end
    end

end % Loop over files

if ~isempty(hAmp)
    yl = get(hAmp,'ylim');
    ylower = 10.^floor(log10(yl(1)));
    yupper = 10.^ceil(log10(yl(2)));
    set(hAmp,'ylim',[ylower yupper] );   
end
if ~isempty(hPhs)
    yl = get(hPhs,'ylim');
    ylower = floor(yl(1)/45)*45  ;
    yupper = ceil(yl(2)/45)*45  ;
    set(hPhs,'ylim',[ylower yupper] );  
end

if ~handles.lUseRxPosition
    set(handles.hAxes(end,:),'xtick',1:length(st.stMT.receivers(iRxSelected,1)));
    xlab = st.stMT.receiverName(iRxSelected);
    set(handles.hAxes(end,:),'xticklabel',xlab);
    if size(xlab,1) > 6
        for i = 1:length(handles.hAxes(end,:))
            axes(handles.hAxes(end,i));
            xticklabel_rotate;
        end
    end
end


if lShowResiduals

    uistack( plot( hAmpRes, xlim(hAmpRes), [0 0], '--k' ...
                 , 'HitTest', 'off', 'tag', 'zeroline', 'DisplayName', '' )  , 'bottom' );

    
    uistack( plot( hPhsRes, xlim(hPhsRes), [0 0], '--k' ...
                 , 'HitTest', 'off', 'tag', 'zeroline', 'DisplayName', '' )  , 'bottom' );
              
    ylA = abs(get(hAmpRes,'ylim'));
    ylP = abs(get(hPhsRes,'ylim'));
     
    yl = max([ylA(:);ylP(:)]);
    
    set(hAmpRes,'ylim',yl*[-1.05 1.05] ); % DGM don't put points right on the border! [-yl yl] );       
    set(hPhsRes,'ylim',yl*[-1.05 1.05] ); % DGM don't put points right on the border! [-yl yl] ); 
    
    linkaxes([hAmpRes hPhsRes] ,'y')
  
end
 


if ~isempty(leghandle) && ilcnt < 20
    hl = legend(leghandle(1:ilcnt),legstr(1:ilcnt),'interpreter','none');
    set(hl,'edgecolor','w'); 
end

set(handles.hAxes,'xlim',handles.xlims,'xgrid','on','ygrid','on' );  

linkaxes(handles.hAxes,'x')


set(handles.hAxes,'visible','on');  

set( handles.figure1, 'Pointer', 'arrow' );
drawnow;

end

%--------------------------------------------------------------------------
function  st = convertRealImagToAmpPhs(st)

% assumes data contains full set of pairs of re & im and not single re or im
% values.

pairs = [  113 114; 115 116; 133 134]; % TE re&im, TM re&im
amph  = [pairs(1:2,:)-10; pairs(3,:)+2];

mu0   = 4*pi*1d-7;

for ip = 1:length(pairs)
    
%Type        Freq#          Tx#          Rx#          Data      StdError      Response      Residual
    codes = pairs(ip,:);
    i1 = st.DATA(:,1) == codes(1); % find pais
    i2 = st.DATA(:,1) == codes(2);
    
    if any(i1)
        i1 = find(i1);
        i2 = find(i2);
        for i = 1:length(i1)
            ind = st.DATA(i1(i),2:4);
            % find im value with same freq,tx,rx indices:
            imatch = find( st.DATA(i2,2) == ind(1) & st.DATA(i2,3) == ind(2) &st.DATA(i2,4) == ind(3));
            
            % Data:
            rd = st.DATA(i1(i),5);
            id = st.DATA(i2(imatch),5);
            re = st.DATA(i1(i),6);
            %ie = st.DATA(i2(imatch),6);
            
            % if TM mode, move from third quadrant to first quadrant prior
            % to phase computation (puts nominal phase at 45 degrees
            % rathern than -135)
            if codes(1) == 115
                rd = -rd;
                id = -id;
            end
            
            if codes(1) < 133  % apparent resistivity and phase
                % Convert impedance to apparent resistivity and phase:
                freq = st.stMT.frequencies(ind(1));
                
                apres = (rd^2 + id^2) ./ (mu0*2*pi*freq);
                phase = atan2d(id,rd);
                 
                st.DATA(i1(i),5)      = apres;
                st.DATA(i2(imatch),5) = phase;
                
                % real and imaginary impedances have equal variances (unless a
                % mistake has been made by user...), therefore:
                
                apres_se = 2*sqrt(apres/(mu0*2*pi*freq))*re;  % See Wheelock 2012, A.19
                phase_se = apres_se/(2*apres)*180/pi;
                
                st.DATA(i1(i),6)      = apres_se;
                st.DATA(i2(imatch),6) = phase_se;
          
                
                % Convert model response if available:
                if length(st.DATA(i1(i),:)) == 8
                    
                    % Response:
                    rd = st.DATA(i1(i),7);
                    id = st.DATA(i2(imatch),7);
                    
                    apres = (rd^2 + id^2) ./ (mu0*2*pi*freq);
                    phase = atan2d(id,rd);
                    st.DATA(i1(i),7)      = apres;
                    st.DATA(i2(imatch),7) = phase;
                    
                end
         
                      
                % Lastly modify the data codes:
                st.DATA(i1(i),1)      = amph(ip,1);
                st.DATA(i2(imatch),1) = amph(ip,2);

            else  % Tipper amp & phase

                amp = sqrt(rd^2 + id^2);
                phase = atan2d(id,rd);
                 
                st.DATA(i1(i),5)      = amp;
                st.DATA(i2(imatch),5) = phase;
                
                % real and imaginary impedances have equal variances (unless a
                % mistake has been made by user...), therefore:
                
                amp_se =   re;   
                phase_se = re/amp*180/pi;
                
                st.DATA(i1(i),6)      = amp_se;
                st.DATA(i2(imatch),6) = phase_se;
                
                % Convert model response if available:
                if length(st.DATA(i1(i),:)) == 8
                    
                    % Response:
                    rd = st.DATA(i1(i),7);
                    id = st.DATA(i2(imatch),7);
                    
                    amp = sqrt(rd^2 + id^2);
                    phase = atan2d(id,rd);
                 
                    st.DATA(i1(i),7)      = amp;
                    st.DATA(i2(imatch),7) = phase;
                    
                end
                % Lastly modify the data codes:
                st.DATA(i1(i),1)      = amph(ip,1);
                st.DATA(i2(imatch),1) = amph(ip,2);
            end
            
        end
        
    end
end

end

%--------------------------------------------------------------------------
function   st = convertlog10AmpToAmp(st)

codes = [ 123 125 129]; %log10 apres TE, TM and Z determinant

newcodes = codes - 20;  %apres


i2 = st.DATA(:,5)~= 0 & st.DATA(:,6)~=0 ;

for ip = 1:length(codes)
    
    thiscode = codes(ip);
    i1 = st.DATA(:,1) == thiscode;
    
    if any(i1)
         
        % Data, only mod non-null data:       
        iMod = i1 & i2;
        
        d = st.DATA(iMod,5);
        de = st.DATA(iMod,6);
        
        amp = 10.^d ;
        st.DATA(iMod,5)      = amp;
        st.DATA(iMod,6)      = de/.4343.*amp;
        
        % Change all model responses:
        if length(st.DATA(1,:)) == 8
            % Response: 
            rd = st.DATA(i1,7);
            st.DATA(i1,7)      = 10.^rd;
        end
        % Change all codes:
        st.DATA(i1,1) = newcodes(ip);
    end
end

st.bWaslog10  = true;

end


%--------------------------------------------------------------------------
function   st = convertAmpTolog10Amp(st)

codes = [ 103 105 109 ] ;

newcodes = codes + 20;  %log10 apres

i2 = st.DATA(:,5)~= 0 & st.DATA(:,6)~=0 ;

for ip = 1:length(codes)
    
    thiscode = codes(ip);
    i1 = st.DATA(:,1) == thiscode;
    
    if any(i1)
         
        % Data, only mod non-null data:       
        iMod = i1 & i2;
        
        d = st.DATA(iMod,5);
        de = st.DATA(iMod,6);
        
        st.DATA(iMod,5)      = log10(d);
        st.DATA(iMod,6)      = de./d*.4343;
        
        % Change all model responses:
        if length(st.DATA(1,:)) == 8
            % Response: 
            st.DATA(iMod,7)      = log10(st.DATA(iMod,7));
        end
        
        % Change all codes:
        st.DATA(i1,1) = newcodes(ip);
    end
end
 

end

%--------------------------------------------------------------------------
function sComponents = sub_getDataComponents(handles)

% If not using reciprocity, then take the DATA type numbers at face value:
iCodes = [];
for iFile = 1:length(handles.st)
    iCodes =[iCodes; handles.st(iFile).DATA(:,1)]; %#ok<AGROW>
end
iCodes = unique(iCodes);

sComponents = {};
sDataCodeLookupTable = m2d_getDataCodeLookupTable();
for i = 1:length(iCodes)
    iCode = iCodes(i);
    if iCode > 100 % only display MT data
        sComponents{end+1} = sDataCodeLookupTable{iCode,1}   ; %#ok<AGROW>
    else
       % fprintf('Not coded for this data type, ignoring it for now: %i\n',iCodes(i));
    end
end

sComponents = unique(sComponents);
end
 

%--------------------------------------------------------------------------
% --- Executes on button press in plotType_Callback.
function handles = plotType_Callback(hObject, eventdata, handles) %#ok<DEFNU>

set( handles.figure1, 'Pointer', 'watch' );
drawnow;

if get(handles.freqAxisType,'value') == 1
    handles.sFreqAxisScale = 'period';
else
    handles.sFreqAxisScale = 'frequency';
end



h = findobj(handles.figure1,'tag','plotType');
str = get(h,'String');
val = get(h,'Value');

plotType = lower(str{val});

switch plotType
    
    case 'grid plot'

        set(handles.fileListbox,'max',2,'listboxtop',1);
        set(handles.frequencyListbox,'max',2,'listboxtop',1);
        
        % Select all rx:
        nRx = length(get(handles.frequencyListbox,'string'));
        set(handles.frequencyListbox,'value',1:nRx)
        set(handles.frequencyListbox,'enable','on');
        set(handles.receiverListbox,'enable','on');
        set(handles.componentsListbox,'enable','on')
        set(handles.componentsListbox,'max',2,'listboxtop',1);
       
        set(handles.xaxisMenu,'enable','off');
        set(handles.freqAxisType,'enable','on');
        set(handles.TElegend,'Visible','on');
        set(handles.TMlegend,'Visible','on');
        set(handles.ZDetlegend,'Visible','on');
    

        handles = sub_setShowButtons(handles,'on');        
        set(handles.showResiduals,'enable','off');
          
        handles = plot_Callback(hObject, eventdata, handles);       
        
        
    case 'single plot'
         
        set(handles.fileListbox,'max',2,'listboxtop',1);
        set(handles.frequencyListbox,'max',2,'listboxtop',1);
        
        % Select all frequencies:
        nRx = length(get(handles.frequencyListbox,'string'));
        set(handles.frequencyListbox,'value',1:nRx)
        
        set(handles.frequencyListbox,'enable','on');
        set(handles.receiverListbox,'enable','on');
        set(handles.componentsListbox,'enable','on')
        
        set(handles.xaxisMenu,'enable','off');
        set(handles.freqAxisType,'enable','on');
        
        set(handles.componentsListbox,'max',2,'listboxtop',1);
        set(handles.TElegend,'Visible','off');
        set(handles.TMlegend,'Visible','off');
        set(handles.ZDetlegend,'Visible','off');

        %set(handles.showResiduals,'enable','on');
        handles = sub_setShowButtons(handles,'on');
        
        handles = plot_Callback(hObject, eventdata, handles);

                
    case 'profile plot'
        
        set(handles.fileListbox,'max',2,'listboxtop',1);
        set(handles.frequencyListbox,'max',2,'listboxtop',1);
        set(handles.componentsListbox,'max',2,'listboxtop',1);
        set(handles.componentsListbox,'enable','on')        
        set(handles.frequencyListbox,'enable','on');

        % Select all receivers:
        nRx = length(get(handles.receiverListbox,'string'));
        set(handles.receiverListbox,'enable','on','value',1:nRx);
        set(handles.xaxisMenu,'enable','on');
        set(handles.freqAxisType,'enable','on');
        set(handles.TElegend,'Visible','off');
        set(handles.TMlegend,'Visible','off');
        set(handles.ZDetlegend,'Visible','off');

        handles = sub_setShowButtons(handles,'on');
        
        handles = plot_Callback(hObject, eventdata, handles);
        
    case 'pseudosection'
     
        vals = get(handles.fileListbox,'value');
        set(handles.fileListbox,'max',1,'listboxtop',1,'value',vals(1));
        
        % select all Rx then turn off selectability:
        nRx = length(get(handles.receiverListbox,'string'));
        set(handles.receiverListbox,'enable','on','value',1:nRx);
        set(handles.receiverListbox,'enable','off');
        
        % select all freqs then turn off selectability:
        nF = length(get(handles.frequencyListbox,'string'));
        set(handles.frequencyListbox,'enable','on','value',1:nF);
        set(handles.frequencyListbox,'enable','off');
        set(handles.componentsListbox,'enable','on')
        
        set(handles.xaxisMenu,'enable','on');
        set(handles.freqAxisType,'enable','on');
        set(handles.showResiduals,'enable','on');
        
        set(handles.TElegend,'Visible','off');
        set(handles.TMlegend,'Visible','off');
        set(handles.ZDetlegend,'Visible','off');
        
        handles = sub_setShowButtons(handles,'on');  
        
        handles = plot_Callback(hObject, eventdata, handles);
        
    case 'misfit breakdown'  % 4 bars per station
               
        % Select one data file:
        vals = get(handles.fileListbox,'value');
        set(handles.fileListbox,'max',1,'listboxtop',1,'value',vals(1));
        
        set(handles.receiverListbox,'enable','off');
        set(handles.frequencyListbox,'enable','off');
        set(handles.componentsListbox,'enable','off')
        set(handles.xaxisMenu,'enable','on');
        set(handles.freqAxisType,'enable','on');
        
        set(handles.TElegend,'Visible','off');
        set(handles.TMlegend,'Visible','off');
        set(handles.ZDetlegend,'Visible','off');
        
        handles = sub_setShowButtons(handles,'off');
        
        handles = plot_Callback(hObject, eventdata, handles);
        
        
end

% Update the RMS display, if data and model responses present for current
% file:
updateRMS(handles);

sub_saveMRU(handles);

set( handles.figure1, 'Pointer', 'arrow' );
drawnow;

end

%--------------------------------------------------------------------------
function handles = updateRMS(handles)

% use first data file selected, if more than 1 have been selected:
iFile = get(handles.fileListbox,'value');
if isempty(iFile)
    return
end
iFile = iFile(1);
if isempty(iFile) || ~isfield(handles,'st') || isempty(handles.st)
    return
end

DATA = handles.st(iFile).DATA;
iFlagged = handles.st(iFile).iFlagged;

if size(DATA,2) <= 6  % data file with no responses
    set(findobj(handles.figure1,'tag','onDataRMS'),'str',' ')
    return
end

r  = DATA(~iFlagged,8);

lMT = DATA(~iFlagged,1) > 100;
 
rms = sqrt(sum(r(lMT).^2)./length(r(lMT)));
set(findobj(handles.figure1,'tag','onDataRMS'),'str',sprintf('%8.3f',rms))
end

%--------------------------------------------------------------------------
function handles = sub_setShowButtons(handles,sSet)

switch lower(sSet)
    
    case 'on'

    % Turn on/off data, model and response buttons as dictated by the input data
    % file:
    if isfield(handles,'st') && ~isempty(handles.st)
        if any([handles.st(:).lHasData])
            %handles.showData.Value = 1;
            handles.showData.Enable = 'on';
        else
            %handles.showData.Value = 0;
            handles.showData.Enable = 'off';
        end
        if any([handles.st(:).lHasModelResponse])  
            %handles.showModelResponse.Value = 1;
            handles.showModelResponse.Enable = 'on';
        else
            %handles.showModelResponse.Value = 0;
            handles.showModelResponse.Enable = 'off';
        end
        if all([handles.st(:).lHasModelResponse]) && all([handles.st(:).lHasData])
            %handles.showResiduals.Value = 1;
            handles.showResiduals.Enable = 'on';
        else
            %handles.showResiduals.Value = 0; 
            handles.showResiduals.Enable = 'off';
        end

    end
    
    case 'off'
        
        set(handles.showData,'enable','off');
        set(handles.showModelResponse,'enable','off');
        set(handles.showResiduals,'enable','off');        
end

end

%--------------------------------------------------------------------------
function sub_display_colormaps(varargin)
    m2d_colormaps('display_all');
end

%--------------------------------------------------------------------------
function sub_setColorMap(~,~,hFig,sColorMap)

handles = guidata(hFig);
handles.sColorMap = sColorMap;

cm = m2d_colormaps(sColorMap);
 
for i = 1:length(handles.hAxes(:))
    
    if any(strfind( lower(handles.hAxes(i).Title.String),'residual')) 
        continue
    end

    colormap(handles.hAxes(i),cm);

end

guidata(hFig, handles);

sub_saveMRU(handles);

end

%--------------------------------------------------------------------------
function setColorMapLines(~,~,hFig,sColorMap)

handles = guidata(hFig);
handles.sLineColorMap = sColorMap;

 
hObject = findobj(hFig,'tag','plotType');
str = get(hObject,'String');
val = get(hObject,'Value');

plotType =str{val};

switch lower(plotType)
    case {'single plot' 'profile plot'}
        handles = plot_Callback(hObject, hObject, handles);
end

guidata(hFig, handles);

sub_saveMRU(handles);

end

%--------------------------------------------------------------------------
function setModelResponseColor(~,~,hFig,sColor)

handles = guidata(hFig);
handles.sModelResponseColor= sColor;

 
hObject = findobj(hFig,'tag','plotType');
str = get(hObject,'String');
val = get(hObject,'Value');

plotType =str{val};

switch lower(plotType)
    case {'grid plot'}
        handles = plot_Callback(hObject, hObject, handles);
end

guidata(hFig, handles);

sub_saveMRU(handles);

end

%--------------------------------------------------------------------------

function hText = xticklabel_rotate(XTick,rot,varargin)
%hText = xticklabel_rotate(XTick,rot,XTickLabel,varargin)     Rotate XTickLabel
%
% Syntax: xticklabel_rotate
%
% Input:    
% {opt}     XTick       - vector array of XTick positions & values (numeric) 
%                           uses current XTick values or XTickLabel cell array by
%                           default (if empty) 
% {opt}     rot         - angle of rotation in degrees, 90° by default
% {opt}     XTickLabel  - cell array of label strings
% {opt}     [var]       - "Property-value" pairs passed to text generator
%                           ex: 'interpreter','none'
%                               'Color','m','Fontweight','bold'
%
% Output:   hText       - handle vector to text labels
%
% Example 1:  Rotate existing XTickLabels at their current position by 90°
%    xticklabel_rotate
%
% Example 2:  Rotate existing XTickLabels at their current position by 45° and change
% font size
%    xticklabel_rotate([],45,[],'Fontsize',14)
%
% Example 3:  Set the positions of the XTicks and rotate them 90°
%    figure;  plot([1960:2004],randn(45,1)); xlim([1960 2004]);
%    xticklabel_rotate([1960:2:2004]);
%
% Example 4:  Use text labels at XTick positions rotated 45° without tex interpreter
%    xticklabel_rotate(XTick,45,NameFields,'interpreter','none');
%
% Example 5:  Use text labels rotated 90° at current positions
%    xticklabel_rotate([],90,NameFields);
%
% Note : you can not RE-RUN xticklabel_rotate on the same graph. 
%



% This is a modified version of xticklabel_rotate90 by Denis Gilbert
% Modifications include Text labels (in the form of cell array)
%                       Arbitrary angle rotation
%                       Output of text handles
%                       Resizing of axes and title/xlabel/ylabel positions to maintain same overall size 
%                           and keep text on plot
%                           (handles small window resizing after, but not well due to proportional placement with 
%                           fixed font size. To fix this would require a serious resize function)
%                       Uses current XTick by default
%                       Uses current XTickLabel is different from XTick values (meaning has been already defined)

% Brian FG Katz
% bfgkatz@hotmail.com
% 23-05-03
% Modified 03-11-06 after user comment
%	Allow for exisiting XTickLabel cell array
% Modified 03-03-2006 
%   Allow for labels top located (after user comment)
%   Allow case for single XTickLabelName (after user comment)
%   Reduced the degree of resizing
% Modified 11-jun-2010
%   Response to numerous suggestions on MatlabCentral to improve certain
%   errors.

% Other m-files required: cell2mat
% Subfunctions: none
% MAT-files required: none
%
% See also: xticklabel_rotate90, TEXT,  SET

% Based on xticklabel_rotate90
%   Author: Denis Gilbert, Ph.D., physical oceanography
%   Maurice Lamontagne Institute, Dept. of Fisheries and Oceans Canada
%   email: gilbertd@dfo-mpo.gc.ca  Web: http://www.qc.dfo-mpo.gc.ca/iml/
%   February 1998; Last revision: 24-Mar-2003

% check to see if xticklabel_rotate has already been here (no other reason for this to happen)
if isempty(get(gca,'XTickLabel')),
    error('xticklabel_rotate : can not process, either xticklabel_rotate has already been run or XTickLabel field has been erased')  ;
end

% if no XTickLabel AND no XTick are defined use the current XTickLabel
%if nargin < 3 & (~exist('XTick') | isempty(XTick)),
% Modified with forum comment by "Nathan Pust" allow the current text labels to be used and property value pairs to be changed for those labels
if (nargin < 3 || isempty(varargin{1})) & (~exist('XTick') | isempty(XTick)),
	xTickLabels = get(gca,'XTickLabel')  ; % use current XTickLabel
	if ~iscell(xTickLabels)
		% remove trailing spaces if exist (typical with auto generated XTickLabel)
		temp1 = num2cell(xTickLabels,2)         ;
		for loop = 1:length(temp1),
			temp1{loop} = deblank(temp1{loop})  ;
		end
		xTickLabels = temp1                     ;
	end
varargin = varargin(2:length(varargin));	
end

% if no XTick is defined use the current XTick
if (~exist('XTick') | isempty(XTick)),
    XTick = get(gca,'XTick')        ; % use current XTick 
end

%Make XTick a column vector
XTick = XTick(:);

if ~exist('xTickLabels'),
	% Define the xtickLabels 
	% If XtickLabel is passed as a cell array then use the text
	if (length(varargin)>0) & (iscell(varargin{1})),
        xTickLabels = varargin{1};
        varargin = varargin(2:length(varargin));
	else
        xTickLabels = num2str(XTick);
	end
end    

if length(XTick) ~= length(xTickLabels),
    error('xticklabel_rotate : must have same number of elements in "XTick" and "XTickLabel"')  ;
end

%Set the Xtick locations and set XTicklabel to an empty string
set(gca,'XTick',XTick,'XTickLabel','')

if nargin < 2,
    rot = 90 ;
end

% Determine the location of the labels based on the position
% of the xlabel
hxLabel = get(gca,'XLabel');  % Handle to xlabel
xLabelString = get(hxLabel,'String');

% if ~isempty(xLabelString)
%    warning('You may need to manually reset the XLABEL vertical position')
% end

set(hxLabel,'Units','data');
xLabelPosition = get(hxLabel,'Position');
y = xLabelPosition(2);

%CODE below was modified following suggestions from Urs Schwarz
y=repmat(y,size(XTick,1),1);
% retrieve current axis' fontsize
fs = get(gca,'fontsize');

% Place the new xTickLabels by creating TEXT objects
hText = text(XTick, y, xTickLabels,'fontsize',fs);

% Rotate the text objects by ROT degrees
%set(hText,'Rotation',rot,'HorizontalAlignment','right',varargin{:})
% Modified with modified forum comment by "Korey Y" to deal with labels at top
% Further edits added for axis position
xAxisLocation = get(gca, 'XAxisLocation');  
if strcmp(xAxisLocation,'bottom')  
    set(hText,'Rotation',rot,'HorizontalAlignment','right',varargin{:})  
else  
    set(hText,'Rotation',rot,'HorizontalAlignment','left',varargin{:})  
end

% Adjust the size of the axis to accomodate for longest label (like if they are text ones)
% This approach keeps the top of the graph at the same place and tries to keep xlabel at the same place
% This approach keeps the right side of the graph at the same place 

set(get(gca,'xlabel'),'units','data')           ;
    labxorigpos_data = get(get(gca,'xlabel'),'position')  ;
set(get(gca,'ylabel'),'units','data')           ;
    labyorigpos_data = get(get(gca,'ylabel'),'position')  ;
set(get(gca,'title'),'units','data')           ;
    labtorigpos_data = get(get(gca,'title'),'position')  ;

set(gca,'units','pixel')                        ;
set(hText,'units','pixel')                      ;
set(get(gca,'xlabel'),'units','pixel')          ;
set(get(gca,'ylabel'),'units','pixel')          ;

origpos = get(gca,'position')                   ;

% textsizes = cell2mat(get(hText,'extent'))       ;
% Modified with forum comment from "Peter Pan" to deal with case when only one XTickLabelName is given. 
x = get( hText, 'extent' );  
if iscell( x ) == true  
    textsizes = cell2mat( x ) ;  
else  
    textsizes = x;  
end  

largest =  max(textsizes(:,3))                  ;
longest =  max(textsizes(:,4))                  ;

laborigext = get(get(gca,'xlabel'),'extent')    ;
laborigpos = get(get(gca,'xlabel'),'position')  ;

labyorigext = get(get(gca,'ylabel'),'extent')   ;
labyorigpos = get(get(gca,'ylabel'),'position') ;
leftlabdist = labyorigpos(1) + labyorigext(1)   ;

% assume first entry is the farthest left
leftpos = get(hText(1),'position')              ;
leftext = get(hText(1),'extent')                ;
leftdist = leftpos(1) + leftext(1)              ;
if leftdist > 0,    leftdist = 0 ; end          % only correct for off screen problems

% botdist = origpos(2) + laborigpos(2)            ;
% newpos = [origpos(1)-leftdist longest+botdist origpos(3)+leftdist origpos(4)-longest+origpos(2)-botdist]  
%
% Modified to allow for top axis labels and to minimize axis resizing
if strcmp(xAxisLocation,'bottom')  
    newpos = [origpos(1)-(min(leftdist,labyorigpos(1)))+labyorigpos(1) ...
            origpos(2)+((longest+laborigpos(2))-get(gca,'FontSize')) ...
            origpos(3)-(min(leftdist,labyorigpos(1)))+labyorigpos(1)-largest ...
            origpos(4)-((longest+laborigpos(2))-get(gca,'FontSize'))]  ;
else
    newpos = [origpos(1)-(min(leftdist,labyorigpos(1)))+labyorigpos(1) ...
            origpos(2) ...
            origpos(3)-(min(leftdist,labyorigpos(1)))+labyorigpos(1)-largest ...
            origpos(4)-(longest)+get(gca,'FontSize')]  ;
end
set(gca,'position',newpos)                      ;

% readjust position of text labels after resize of plot
set(hText,'units','data')                       ;
for loop= 1:length(hText)
    set(hText(loop),'position',[XTick(loop), y(loop)])  ;
end

% adjust position of xlabel and ylabel
laborigpos = get(get(gca,'xlabel'),'position')  ;
set(get(gca,'xlabel'),'position',[laborigpos(1) laborigpos(2)-longest 0])   ;

% switch to data coord and fix it all
set(get(gca,'ylabel'),'units','data')                   ;
set(get(gca,'ylabel'),'position',labyorigpos_data)      ;
set(get(gca,'title'),'position',labtorigpos_data)       ;

set(get(gca,'xlabel'),'units','data')                   ;
    labxorigpos_data_new = get(get(gca,'xlabel'),'position')  ;
set(get(gca,'xlabel'),'position',[labxorigpos_data(1) labxorigpos_data_new(2)])   ;


% Reset all units to normalized to allow future resizing
set(get(gca,'xlabel'),'units','normalized')          ;
set(get(gca,'ylabel'),'units','normalized')          ;
set(get(gca,'title'),'units','normalized')          ;
set(hText,'units','normalized')                      ;
set(gca,'units','normalized')                        ;

if nargout < 1
    clear hText
end

end



%--------------------------------------------------------------------------
function resize_Callback(hObject, ~, handles)
%R2015b

% Resize tool panel:
figPos  = handles.figure1.Position;
toolPos = handles.UIpanel.Position;

handles.UIpanel.Position = [toolPos(1) figPos(4)-toolPos(4) toolPos(3:4)];
 
% Update the axes positions too:
if isfield(handles,'st') && ~isempty(handles.st) 
 
    m = size(handles.hAxes,1);
    n = size(handles.hAxes,2);
      
    h = findobj(handles.figure1,'tag','plotType');
    str = get(h,'String');
    val = get(h,'Value');

    plotType =str{val};    
    
    lColorbar = false; 
    switch lower(plotType)
        case 'pseudosection'
            lColorbar = true;
    end
 
    
    [posX,posY,widX,widY]= getRowColPositions(handles,m,n,lColorbar);

    fudgeY = 0;
    switch  lower(plotType)
        case 'grid plot'
        nRows = size(handles.hAxes,1);    
        if nRows> 2
            fudgeY = 60/nRows;    
        end
    end
    
    for j = 1:n
        for i = 1:m
            
            % yOffset to deal with grid plot where apparent resistivity and
            % phase axes should be closer together than rows between
            % stations:
            yOffset = 0;
            if rem(i,2) ~= 0
                yOffset = fudgeY;
            end
            
            if isprop(handles.hAxes(i,j),'units')  % this deals with missing axes when there are fewer plots than available grid slots (i.e. less than nRows by nCols)
                set(handles.hAxes(i,j),'units','pixels','position',[ posX(j) posY(m+1-i)-yOffset widX(j) widY(m+1-i)+fudgeY]);
            end
        end
    end
    
end

end
