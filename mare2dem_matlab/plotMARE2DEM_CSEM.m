function varargout = plotMARE2DEM_CSEM(varargin)
%
% GUI for plotting CSEM data and model response files for MARE2DEM
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
% at the Lamont-Doherty Earth Observatory, Columbia University.
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


% Begin initialization code - DO NOT EDIT
gui_Singleton = 0;
gui_State = struct('gui_Name',       mfilename, ...
    'gui_Singleton',  gui_Singleton, ...
    'gui_OpeningFcn', @plotMARE2DEM_CSEM_OpeningFcn, ...
    'gui_OutputFcn',  @plotMARE2DEM_CSEM_OutputFcn, ...
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
% --- Executes just before plotMARE2DEM_CSEM is made visible.
function plotMARE2DEM_CSEM_OpeningFcn(hObject, ~, handles, varargin)
% This function has no output args, see OutputFcn.
% hObject    handle to figure
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)
% varargin   command line arguments to plotMARE2DEM_CSEM (see VARARGIN)

% Choose default command line output for plotMARE2DEM_CSEM
handles.output = hObject;

hFig = handles.figure1;

% Disable the "save" button on the figure file menu so users can't
% overwrite the original .fig file. 
set(hFig, 'menubar', 'none', 'toolbar', 'none');
 
% Get fixed defualts
handles = sub_GetDefaults(handles);

% Get most recently used USER values:
handles = sub_getMRU(handles);


%-----------------%
% File menu %
%-----------------%
% Create the menu
hMenu = uimenu( hFig, 'Label', '&File' );
uimenu( hMenu, 'Label', '&Save .fig...', 'Callback', {@sub_Save, hFig},'accelerator','s' );
%uimenu( hMenu, 'Label', '&Print image to file...', 'Callback', {@sub_print, hFig}, 'Separator', 'on','accelerator','p');
uimenu( hMenu, 'Label', 'E&xit', 'Callback', {@sub_Close, hFig}, 'Separator', 'on','accelerator','w' );


%-----------------%
% Appearance Menu %
%-----------------%
m40 =  uimenu('Label','Appearance');

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
uimenu(m10,'Label','Parula',   'callback', {@setColorMapLines, hFig,'parula'}); 
 uimenu(m10,'Label','Turbo',   'callback', {@setColorMapLines, hFig,'turbo'}); 
 
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

m10 = uimenu('Parent',m40,'Label','Marker Size');
uimenu(m10,'Label','larger',   'callback', {@setField, hFig,'markerSize','larger'} );
uimenu(m10,'Label','smaller',  'callback', {@setField, hFig,'markerSize','smaller'} );

m10 = uimenu('Parent',m40,'Label','Line Width');
uimenu(m10,'Label','thicker',   'callback', {@setField, hFig,'lineWidth','thicker'} );
uimenu(m10,'Label','thinner',  'callback', {@setField,  hFig,'lineWidth','thinner'} );

m10 = uimenu('Parent',m40,'Label','Font Size');
uimenu(m10,'Label','larger',   'callback', {@setField, hFig,'fontSize','larger'} );
uimenu(m10,'Label','smaller',  'callback', {@setField, hFig,'fontSize','smaller'} );

uimenu('Parent',m40,'Label','Reset To Defaults', 'callback', {@sub_ResetDefaults, hFig'},'separator','on');

m40 =  uimenu('Label','Survey Geometry');
uimenu(m40,'Label','Map',                    'callback', {@plotSurveyMap, hFig, 'map'} );
uimenu(m40,'Label','Receiver Parameters',    'callback', {@plotSurveyMap, hFig, 'rx'} );
uimenu(m40,'Label','Transmitter Parameters', 'callback', {@plotSurveyMap, hFig, 'tx'} );

% Update handles structure
guidata(hObject, handles);


if ~isempty(varargin) && length(varargin)==1
    callFromExternal(varargin{1},hObject);
end


end


%--------------------------------------------------------------------------
function plotSurveyMap(~,~,hFig,sType)


handles = guidata(hFig);

handles.st(1).dataFile = handles.st(1).sFile;

% Call external routine:
plotMARE2DEM_SurveyLayout(sType,handles.st(1));

 
end

%--------------------------------------------------------------------------
function handles = sub_GetDefaults(handles)

    handles.sColorMap       = 'parula';
    handles.sLineColorMap   = 'lines';
    handles.fontSize        = 14; 
    %handles.marker          = 'o';
    handles.lineWidth       = 1;
    handles.markerSize      = 4;
    handles.sModelResponseColor = 'data'; %'data' uses data colors, 'k' is black
end

 %--------------------------------------------------------------------------
function handles = sub_ResetDefaults(~,~,hFig)
    
    handles = guidata(hFig);

    handles = sub_GetDefaults(handles);
    
    sub_saveMRU(handles);
     
    handles = plotType_Callback(hFig, hFig, handles);

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
            handles.lineWidth       = a.lineWidth; 
            handles.markerSize      = a.markerSize;    
            if isfield(a,'sModelResponseColor')
                handles.sModelResponseColor = a.sModelResponseColor;
            end
        end
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
    lineWidth       = handles.lineWidth; 
    markerSize      = handles.markerSize;         
    sModelResponseColor = handles.sModelResponseColor;
    
    % Save it, replacing any existing:
    save(sMRU, '-mat', ...
        'sColorMap',...
        'sLineColorMap',...
        'fontSize',...
        'lineWidth',...
        'markerSize',...
        'sModelResponseColor');
        
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

for i = 1:length(handles.hAxes)
    
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
    case {'response lines' 'uncertainty %'}
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
    case {'response lines' 'uncertainty %'}
        handles = plot_Callback(hObject, hObject, handles);
end

guidata(hFig, handles);

sub_saveMRU(handles);

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
 
handles = plotType_Callback(hFig, hFig, handles);

guidata(hFig, handles);

sub_saveMRU(handles);

end

%--------------------------------------------------------------------------
% --- Outputs from this function are returned to the command line.
function varargout = plotMARE2DEM_CSEM_OutputFcn(hObject, eventdata, handles)
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
%    set(sb.ProgressBar,  'Value',i);
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
    h = warndlg('No CSEM data found, skipping!','Error','modal') ;
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
handles = sub_updateReceivers(handles);
handles = sub_updateTransmitters(handles);
handles = sub_updateGathers(handles);

% Update the plot:
handles = plotType_Callback(hObject, [], handles);

% Store data back into gui:
guidata(hObject, handles);

end

%--------------------------------------------------------------------------
function   handles = callFromExternal(filename,hObject)
 
filename = m2d_getMostRecent(filename,'*.resp');

if isempty(filename)
    h = warndlg('Error, no MARE2DEM data file was found','Error','modal') ;
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
    h = warndlg('No CSEM data found in data file, closing!','Error','modal') ;
    waitfor(h)
    close(hObject)
    return
end

handles = sub_updateEverything(handles,hObject);

end

%--------------------------------------------------------------------------
function   [handles,sMsg] = sub_loadAFile(handles,filepath,filename)

st = m2d_readEMData2DFile(fullfile(filepath,filename));

st.sFile        = filename;
st.sPath        = filepath;
st.bWaslog10    = false; % keep track of log10 amplitude data converted to linear 


% See if there's any CSEM data, if not skip:
if ~isfield(st.stCSEM,'receivers')
    sMsg = 'nodata';
    return
end

% If file has Real/Imaginary data formats, convert them to amplitude and
% phase:
st = convertRealImagToAmpPhs(st);

% If file has log10Amplitude data, convert it to amplitude:
st = convertlog10AmpToAmp(st);

iNoData = st.DATA(:,5) == 0 & st.DATA(:,6) ==0 ;  % Set dummy data to infinity so FWD model responses can be plotted without data
st.DATA(iNoData,5) = inf;
st.DATA(iNoData,6) = inf;


%KWK debug: this will soon be replaced by allowing user to save the plotMARE2DEM_CSEM session in a
%.mat file

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
 
if exist('iFlagged') && length(iFlagged) == size(st.DATA,1)
    st.iFlagged = iFlagged;
else
    st.iFlagged = false(size(st.DATA,1),1);
end

%
% Check for Towed Array data:
%
% Here we assume a unique Rx location is used for each Rx-Tx pair.
% Unfortunately DataMan will sometimes lump Rx locations together if
% locations are same to within some tolerance, so DM output files might not
% work here...
%
st.lTowedArray = false;
nRx = size(st.stCSEM.receivers,1);
nTxPerRx = zeros(nRx,1);

nTx = size(st.stCSEM.transmitters,1);
for iTx = 1:nTx
    
    % [type freq# Tx# Rx# Data Std_Error] 
    lCheck = st.DATA(:,3) == iTx & st.DATA(:,1) < 100; %&& DATA(:,2) == iFq;
    
    iRx = unique(st.DATA(lCheck,4));
    if any(iRx)
        nTxPerRx (iRx) =  nTxPerRx(iRx) + 1;
    end
end 

if (max(nTxPerRx)) == 1  && nTx > 1 % each receiver has only 1 Tx position, so towed array data
    st.lTowedArray = true;
end
 

%
% Create data arrays that make plotting easier and faster:
%
st = sub_createFastArrays(st);


if isfield(handles,'st') && ~isempty(handles.st)
    
    % Check that new data file is compatible (same Rx,Tx,Freqs) as
    % existing:
    
    if   size(handles.st(1).stCSEM.receivers,1) ~= size(st.stCSEM.receivers,1) || ...
         size(handles.st(1).stCSEM.transmitters,1) ~= size(st.stCSEM.transmitters,1) || ...
         size(handles.st(1).stCSEM.frequencies,1) ~= size(st.stCSEM.frequencies,1)
         sMsg = 'incompatible';
         waitfor(errordlg('Data file is not compatible with data already loaded','Error','modal'))
         return;  %kwk debug: put eror message here
         
    elseif any(handles.st(1).stCSEM.receivers(:) ~= st.stCSEM.receivers(:)) || ...
            any(any(handles.st(1).stCSEM.transmitters(:,1:3) ~= st.stCSEM.transmitters(:,1:3))) || ...
            any(handles.st(1).stCSEM.frequencies(:) ~= st.stCSEM.frequencies(:))
        waitfor(errordlg('Data file is not compatible with data already loaded','Error','modal'))
        sMsg = 'incompatible';
        return;  %kwk debug: put eror message here
        
    end
    
    n = length(handles.st);
    handles.st(n+1) = st;
 
else
    
    handles.st = st;
end

% Default is y profile, but here check for borehold or other z varying
% data:
dy  = max(st.stCSEM.receivers(:,2)) - min(st.stCSEM.receivers(:,2));
dz  = max(st.stCSEM.receivers(:,3)) - min(st.stCSEM.receivers(:,3));
if dz > dy
    
    %handles.sXa = handles.xaxisMenu.String(handles.xaxisMenu.Value);

    %handles.xaxisMenu.String
    
    for i = 1:length(handles.xaxisMenu.String)
        if strcmpi(handles.xaxisMenu.String{i},'Z position')
            handles.xaxisMenu.Value = i;
            break;
        end
    end
   
 

end



sMsg = 'aokay';

end

%--------------------------------------------------------------------------
function  st = sub_createFastArrays(st)

if st.lTowedArray

    for iRx = size(st.stCSEM.receivers,1):-1:1

        sRx = strtok(st.stCSEM.receiverName{iRx}(3:end),'_');
        st.iTowedArrayRxNum(iRx,1) = sscanf(sRx,'%g',1);

    end

    nRxPerTx = max(st.iTowedArrayRxNum);

    indRx = st.iTowedArrayRxNum(st.DATA(:,4));    
    
    % Store receiver offsets and dipole lengths  to use later:
    lCSEM = st.DATA(:,1) < 100;
    dCSEM = st.DATA(lCSEM,:);
    irx = st.iTowedArrayRxNum(dCSEM(:,4));  
    [~,iu] = unique(irx);
    st.stCSEM.towedArrayOffsets      = st.stCSEM.transmitters(dCSEM(iu,3),2) - st.stCSEM.receivers(dCSEM(iu,4),2);
    st.stCSEM.towedArrayDipoleLength = st.stCSEM.receivers(irx(iu),7);
    st.stCSEM.towedArrayRxIndex      = irx(iu);
  
else
    nRxPerTx = size(st.stCSEM.receivers,1);
    indRx = st.DATA(:,4); % easy case Rx are Rx!

end
 
Cmps = unique(st.DATA(:,1));

% here only get CSEM data:
Cmps = Cmps(Cmps<100);

nRx = nRxPerTx;
nTx = size(st.stCSEM.transmitters,1);
nFq = size(st.stCSEM.frequencies,1);

for i = 1:length(Cmps)
    
    st.Cmps(i).Cmp   = Cmps(i);
    st.Cmps(i).d     = nan(nRx,nTx,nFq); % data
    st.Cmps(i).e     = nan(nRx,nTx,nFq); % uncertainty
    st.Cmps(i).m     = nan(nRx,nTx,nFq); % model response
    st.Cmps(i).r     = nan(nRx,nTx,nFq); % normalized residual
    st.Cmps(i).iData = nan(nRx,nTx,nFq); % index to DATA array 
 
    
    for iFq = 1:nFq
        
        lCmp = st.DATA(:,1) == Cmps(i) & st.DATA(:,2) == iFq;
        
        if any(lCmp)
            
            iTx  = st.DATA(lCmp,3);
            iRx  = indRx(lCmp);
            iFqq = iFq*ones(size(iTx));
            ind  = sub2ind(size(st.Cmps(i).d ),iRx,iTx,iFqq);
            
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
function   handles = sub_updateGUIComponents(handles)

% File listbox:
sNames = {handles.st.sFile };
set(handles.fileListbox,'string',sNames,'value',length(sNames));

% Frequency listbox:
if isfield(handles.st,'stCSEM') && ~isempty(handles.st)
    freqs = handles.st(1).stCSEM.frequencies;
    %set(handles.frequencyListbox,'string',num2cell(freqs),'value',[1:length(freqs)]);
    set(handles.frequencyListbox,'string',num2cell(freqs),'value',1); % only show 1 frequency at a time, by default
else
     set(handles.frequencyListbox,'string','');  
end

% Data components:
handles.sComponents = sub_getDataComponents(handles);
set(handles.componentsListbox,'listboxtop',1); 
set(handles.componentsListbox,'string',handles.sComponents(:),'value',1:length(handles.sComponents))

% Update plot type options:
if ~isempty(handles.st)
    
    nTx = size(handles.st(1).stCSEM.transmitters,1);
    nRx = size(handles.st(1).stCSEM.receivers,1);

    if handles.st(1).lHasData && handles.st(1).lHasModelResponse
        
        if nTx > 1 && nRx > 1
            handles.plotType.String = {'Response Lines' ...
                                       'Response Matrix: position versus range' ....
                                       'Response Matrix: receivers versus transmitters'  ...
                                       'Misfit Breakdown' 'Uncertainty %'}; %everything
        else
            handles.plotType.String = {'Response Lines'  'Misfit Breakdown' 'Uncertainty %'}; % no matrix plotting
        end
        
    else
        if nTx > 1 && nRx > 1
            if handles.st(1).lHasData
                handles.plotType.String = {'Response Lines' ...
                                           'Response Matrix: receivers versus transmitters'  ...
                                           'Response Matrix: position versus range' ....
                                          'Uncertainty %' };% lines and matrix
            else
                handles.plotType.String = {'Response Lines' ...
                                           'Response Matrix: receivers versus transmitters'  ...
                                           'Response Matrix: position versus range' ....
                                          };% lines and matrix
            end
                
        else
            if handles.st(1).lHasData
                handles.plotType.String = {'Response Lines' 'Uncertainty %' }; % lines only
            else
               handles.plotType.String = {'Response Lines' }; % lines only 
            end
        end
        
    end

end

end

%--------------------------------------------------------------------------
function handles = sub_setShowButtons(handles,sSet)

switch lower(sSet)
    
    case 'on'

    % Turn on/off data, model and response buttons as dictated by the input data
    % file:
    if isfield(handles,'st') && ~isempty(handles.st)
        if any([handles.st(:).lHasData])
            handles.showData.Value = 1;
            handles.showData.Enable = 'on';
        else
            handles.showData.Value = 0;
            handles.showData.Enable = 'off';
        end
        if any([handles.st(:).lHasModelResponse]) 
            handles.showModelResponse.Value = 1;
            handles.showModelResponse.Enable = 'on';
        else
            handles.showModelResponse.Value = 0;
            handles.showModelResponse.Enable = 'off';
        end
        if any([handles.st(:).lHasData]) && any([handles.st(:).lHasModelResponse]) 
            handles.showResiduals.Value = 1;
            handles.showResiduals.Enable = 'on';
        else
            handles.showResiduals.Value = 0; 
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
function handles = sub_updateReceivers( handles)

%  ***Assumes that all st().stCSEM have same receiver array***

sRx ={};

if ~isempty(handles.st)
    if handles.st(1).lTowedArray

        handles.rxSelectorText.String = 'Rx: #,Offset,Length:';

        rx  = handles.st(1).stCSEM.towedArrayOffsets;
        dl  = handles.st(1).stCSEM.towedArrayDipoleLength;
        ind = handles.st(1).stCSEM.towedArrayRxIndex; 
        for i = length(rx):-1:1
            sRx{i} =  sprintf('%3i:%5.1f km %4.1f m',ind(i),rx(i)/1000,dl(i)); % sRx = num2str(rx/1d3);
        end       

    
    else
        rx = handles.st(1).stCSEM.receivers(:,2);
        handles.rxSelectorText.String = sprintf('Receiver:\n #, y, length');
        
        dl = handles.st(1).stCSEM.receivers(:,7);
        
        for i = length(rx):-1:1
            if abs(rx(i)) < 100
                sRx{i} =  sprintf('%3i:%5.1f m %4.1f m',i,rx(i),dl(i)); % sRx = num2str(rx/1d3);
            else
                
                sRx{i} =  sprintf('%3i:%5.1f km %4.1f m',i,rx(i)/1000,dl(i)); % sRx = num2str(rx/1d3);
            end
        end       
        
    end
 

end

set(handles.receiverListbox,'listboxtop',1);
set(handles.receiverListbox,'string',(sRx),'value',1:length(sRx));

end

%--------------------------------------------------------------------------
function handles = sub_updateTransmitters( handles)

%  ***Assumes that all st().stCSEM have same transmitter array***

sTx = {};

if ~isempty(handles.st)
    tx = handles.st(1).stCSEM.transmitters(:,2);
    azi = handles.st(1).stCSEM.transmitters(:,4);
    dip = handles.st(1).stCSEM.transmitters(:,5);
    dl = handles.st(1).stCSEM.transmitters(:,6);
    for i = length(tx):-1:1;
        if abs(tx(i)) < 100
            sTx{i} =  sprintf('%.2f m %.1fº %.1fº %.1f m',tx(i),azi(i),dip(i),dl(i)); % s 
        else
            sTx{i} =  sprintf('%.1f km %.1fº %.1fº %.1f m',tx(i)/1000,azi(i),dip(i),dl(i)); % s 
            
        end
    end
end

handles.txSelectorText.String =  sprintf('Transmitter:\n y, Azi,Dip, length');

set(handles.transmitterListbox,'listboxtop',1);
set(handles.transmitterListbox,'string',sTx,'value',1:length(sTx));

end

%--------------------------------------------------------------------------
function handles = sub_updateGathers(handles)

nTx = size(handles.st(1).stCSEM.transmitters,1);
nRx = size(handles.st(1).stCSEM.receivers,1);
        
if handles.st(1).lTowedArray
    if nTx > 1
        handles.gatherMenu.String = {'Towed Array' 'Transmitters'};
    else
        handles.gatherMenu.String = {'Transmitters'};
    end
    handles.gatherMenu.Value = 1;
else
    handles.gatherMenu.Value = 1;
    if nRx == 1
        handles.gatherMenu.String = {'Receivers'};
    elseif nTx == 1
        handles.gatherMenu.String = {'Transmitters'};
    else
        handles.gatherMenu.String = {'Receivers' 'Transmitters'};
        if nRx > nTx
            handles.gatherMenu.Value = 2;
        end
    end
    
end

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

sFiles = get(handles.fileListbox,'string');


% Update the listbox:
handles.st(selected) = [];
sNames = {handles.st.sFile };
set(handles.fileListbox,'string',sNames,'value',max(0,size(sNames,1)));

%Store data back into gui:
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
handles = sub_updateTransmitters(handles);
handles = plot_Callback(hObject, eventdata, handles);
handles = updateRMS(handles);

% Store data back into gui:
guidata(hObject, handles);
end

%--------------------------------------------------------------------------
% --- Executes on selection change in fileListbox.
function fileListbox_Callback(~, ~, ~)
% hObject    handle to fileListbox (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)

% Hints: contents = cellstr(get(hObject,'String')) returns fileListbox contents as cell array
%        contents{get(hObject,'Value')} returns selected item from fileListbox
end

%--------------------------------------------------------------------------
% receiver listbox select callback:
function receiverListbox_Callback(hObject, eventdata, handles)

% get selected receivers:
iRx  = get(handles.receiverListbox,'value');

if isempty(iRx)
    return
end

 

% Update the plots:
handles = plot_Callback(hObject, eventdata, handles);
end

%--------------------------------------------------------------------------
% receiver listbox select callback:
function transmitterListbox_Callback(hObject, eventdata, handles)

% get selected receivers:
iTx  = get(handles.transmitterListbox,'value');

if isempty(iTx)
    return
end

 

% Update the plots:
handles = plot_Callback(hObject, eventdata, handles);
end

% -------------------------------------------------------------------------
function handles = brushData_Callback(hObject, eventdata, handles)

 h = brush(handles.figure1);
 
 % Only allowing brushing when single data file is plotted:
 iFiles = handles.fileListbox.Value;

 
 if strcmpi(get(h,'enable'),'off')
    if length(iFiles)>1
        beep;
        h = errordlg('Please select a single data file first!',' Error:','modal');
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
    iToggle  = [iToggle;in{i}(bd{i} >0)];
end
iToggle = unique(iToggle);
iToggle = iToggle(~isnan(iToggle));

if ~isempty(bd)
    switch sCall
        case 'Toggle On'
            handles.st(iFile).iFlagged(iToggle)  = false;

            if strcmpi(brushMode,'joint')
               % find phase data at same iTx,iRx and iFreq and turn it on:
                inds = handles.st(iFile).DATA(iToggle,2:4);
                [LIA] = (ismember(handles.st(iFile).DATA(:,2:4),inds,'rows')) &  handles.st(iFile).DATA(:,1) < 100;    
                handles.st(iFile).iFlagged(LIA) = false;
            end
 
        case 'Toggle Off'
 
            handles.st(iFile).iFlagged(iToggle) = true;

            if strcmpi(brushMode,'joint')
                % find phase data at same iTx,iRx and iFreq and turn it on:
                inds = handles.st(iFile).DATA(iToggle,2:4);
                LIA  = (ismember(handles.st(iFile).DATA(:,2:4),inds,'rows')) &  handles.st(iFile).DATA(:,1) < 100;    
                handles.st(iFile).iFlagged(LIA) = true;  
            end

       
    end
    
end
 
% now redraw the plot:
 
 handles = plot_Callback(hObject, eventdata, handles);
 
end

% -------------------------------------------------------------------------
function handles = sub_Save(~, ~, hFig)


try
   
    
    handles = guidata(hFig);
    
    if ~isfield(handles,'st')
        return
    end
    iFile = get(handles.fileListbox,'value');
    iFile = iFile(1);

    sDefault = fullfile(handles.st(iFile).sPath, sprintf('%s.fig',handles.st(iFile).sFile));

    [file, path] = uiputfile({'*.fig';'*'}, 'Save plotMARE2DEM_CSEM figure as',sDefault);
    if file==0
        return
    end

    
    set(hFig, 'Pointer', 'watch' ); drawnow;
      
    file = fullfile(path,file);
    saveas(hFig,file,'fig')
   
    
    % Display message:
    h = helpdlg(sprintf('Done writing plotMARE2DEM_CSEM figure file: \n %s', file),'plotMARE2DEM_CSEM Message:');
    set(h,'windowstyle','modal');
    uiwait(h)
 
    set(hFig, 'Pointer', 'arrow' );
 
    
catch Me

    echo off;

    waitfor( errordlg( {
        'Error saving plotMARE2DEM_CSEM figure!'
        ' '
        Me.identifier
        Me.message
        } ) );
        
end


end

%----------------------------------------------------------------------
function sub_Close( ~, ~, hFig )

%     bChanged = getappdata(hFig,'bChanged');
%     st = get( hFig, 'UserData' );
%     if bChanged
%         sBtn = questdlg( 'Save changes before exit?', 'plotMARE2DEM_CSEM' ...
%             , 'Yes', 'No', 'Cancel', 'Yes' );
%         if strcmpi( sBtn, 'yes' )
%             sub_save([],[],hFig);
%  
%         elseif ~strcmpi( sBtn, 'no' )
%             return;
%         end
%     end
   % If we get here, then closing the dialog is OK.
    delete( hFig );
            
    
    return;
end % sub_Close

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
    
    st.DATA = st.DATA(~iFlagged,1:6); % just save data, not model response
    % since this is typically used to remove bad/noisy data during inversion
    st.comment = 'Data editted using plotMARE2DEM_CSEM.m';
    m2d_writeEMData2DFile(outputFileName,st)

    % Save a .flagged file using INPUT file name, not new file since the
    % iFlagged array pertains to the original data:
    outputFileName = fullfile(st.sPath,sprintf('%s.flagged.mat',st.sFile));
    save(outputFileName, 'iFlagged');
end
    


set( handles.figure1, 'Pointer', 'arrow' );
drawnow;


end

% -------------------------------------------------------------------------
function handles = sub_plotMisfitBreakDown(hObject,handles)

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

if st.bWaslog10 % reapply log10 (yes this is a kludge...)
    st = convertAmpTolog10Amp(st);
end

% All good, move on:
sDataCodeLookupTable = m2d_getDataCodeLookupTable();

lShowOffData = get(findobj(handles.figure1,'tag','showOffData'),'value');

%
% Draw the four axes (Rx position, Tx position, Range, Frequency):
% 


m = 3;
n = 1;
lColorbar = false;
[posX,posY,widX,widY]= getRowColPositions(handles,m,n,lColorbar);    

posRx   = [ posX(1) posY(3) widX(1) widY(3)];
hRx = axes('units','pixels','Position', posRx,'tag','hAxes');

posTx   = [posX(1) posY(2) widX(1) widY(2)];
hTx = axes('units','pixels','Position', posTx,'tag','hAxes');

m = 3;
n = 2;
[posX,posY,widX,widY]= getRowColPositions(handles,m,n,lColorbar); 

posRange   = [posX(1) posY(1) widX(1) widY(1)];
hRange = axes('units','pixels','Position', posRange,'tag','hAxes');

posFreq   = [posX(2) posY(1) widX(2) widY(1)];
hFreq = axes('units','pixels','Position', posFreq,'tag','hAxes');

handles.hAxes = [hRx hTx hRange hFreq ];



set( handles.hAxes,'box','on')

% remove non CSEM part of data to make code simpler:

if lShowOffData
    lCSEM = st.DATA(:,1) < 100;
else
    lCSEM = st.DATA(:,1) < 100 & ~st.iFlagged;
end

st.DATA = st.DATA(lCSEM,:);


sTypeStr = cell(length(handles.sComponents),1);
lAmp = false(length(st.DATA(:,1)),length(handles.sComponents));
lPhs = false(length(st.DATA(:,1)),length(handles.sComponents));
nMisfitAmpPhsM(1:2*length(handles.sComponents)) = inf;


for iComp = 1:length(handles.sComponents)
    if st.bWaslog10
        iCompCodeAmp = (find(strcmp(sDataCodeLookupTable(:,2),'Log10 Amplitude') & strcmp(sDataCodeLookupTable(:,1),handles.sComponents(iComp))));
    else 
        iCompCodeAmp = (find(strcmp(sDataCodeLookupTable(:,2),'Amplitude') & strcmp(sDataCodeLookupTable(:,1),handles.sComponents(iComp))));         
    end
    
    iCompCodePhs = find(strcmp(sDataCodeLookupTable(:,2),'Phase') & strcmp(sDataCodeLookupTable(:,1),handles.sComponents(iComp)));
   
       % Check for pmax and pmin if nothing found:
    if isempty(iCompCodeAmp) && isempty(iCompCodePhs) && strcmpi(handles.sComponents(iComp),'ep')
   
        iCompCodeAmp = (find(strcmpi(sDataCodeLookupTable(:,2),'pemax') & strcmp(sDataCodeLookupTable(:,1),handles.sComponents(iComp)))); 
        iCompCodePhs = (find(strcmpi(sDataCodeLookupTable(:,2),'pemin') & strcmp(sDataCodeLookupTable(:,1),handles.sComponents(iComp))));   

        sTypeStr{2*iComp-1}  = sprintf(' %s PE Max ', handles.sComponents{iComp}); 
        sTypeStr{2*iComp   } = sprintf(' %s PE Min', handles.sComponents{iComp}); 
    
    else
       
        sTypeStr{2*iComp-1}  = sprintf(' %s Amplitude ', handles.sComponents{iComp});
        sTypeStr{2*iComp   } = sprintf(' %s Phase', handles.sComponents{iComp}); 
    
    end
    
    lAmp(:,iComp) = st.DATA(:,1) == iCompCodeAmp;
    lPhs(:,iComp) = st.DATA(:,1) == iCompCodePhs;
    
    nMisfitAmpPhsM(2*iComp-1) = getMisfit( st.DATA(lAmp(:,iComp),8));
    nMisfitAmpPhsM(2*iComp  ) = getMisfit( st.DATA(lPhs(:,iComp),8));

    
end


 
%
% Misfit by Receiver position:
%
nMisfitAmpPhsR = zeros(length(st.stCSEM.receivers(:,1)),2*length(handles.sComponents));

lUsed= false(length(st.stCSEM.receivers(:,1)));
for iComp = 1:length(handles.sComponents)  
 
    for iRx = 1:length(st.stCSEM.receivers(:,1))
        lRx = st.DATA(:,4) == iRx;
 
        nMisfitAmpPhsR(iRx,2*iComp-1) = getMisfit( st.DATA(lAmp(:,iComp)&lRx,8));
        nMisfitAmpPhsR(iRx,2*iComp  ) = getMisfit( st.DATA(lPhs(:,iComp)&lRx,8));

        if any(lRx) 
            lUsed(iRx) = true;
        end
    end
end

 
handles.lUseRxPosition = true;
% Get position scale:
x  = st.stCSEM.receivers(:,1)/1d3;
y  = st.stCSEM.receivers(:,2)/1d3;
z  = st.stCSEM.receivers(:,3)/1d3;
% normal CSEM data is along y axis, but for crosswell its along z mostly,
% so use whichever has the bigger range:
if max(y)-min(y) > max(z)-min(z) || length(y) == 1
    xd = y;
    handles.xlab = 'Rx Y Position (km)';
else
    xd = z;
    handles.xlab = 'Rx Z Position (km)';
end

xd = xd(lUsed);
nMisfitAmpPhsR = nMisfitAmpPhsR(lUsed,:); 

% Catch for duplicate xd values, add some random noise:
xd = xd+1d-4*randn(size(xd)); % cm level noise..

axes(hRx);

% Get colors to use:
 
barColors = lines(size(nMisfitAmpPhsR,2));

if length(xd) < 100
    if length(xd)==1
        hRx = bar([xd*.95 xd xd*1.05],[nan nan; nMisfitAmpPhsR ; nan nan]);
    else
        hRx = bar(xd,nMisfitAmpPhsR);
    end
    for i = 1:length(hRx)
        hRx(i).FaceColor = barColors(i,:);
    end
    
else
     hRx =  plot(xd,nMisfitAmpPhsR,'marker','o','markersize',handles.markerSize,'linestyle','none');

    for i = 1:length(hRx)
        hRx(i).Color = barColors(i,:);
        hRx(i).MarkerFaceColor = barColors(i,:);
    end
end

lUsed = ~isnan(max(nMisfitAmpPhsR));

axis tight
ylabel('RMS') 
xlabel(handles.xlab)
legend(hRx(lUsed),sTypeStr(lUsed))
shading flat
grid on;

%
% Misfit by Transmitter:
%
nMisfitAmpPhsT= zeros(length(st.stCSEM.receivers(:,1)),2*length(handles.sComponents));

lUsed= false(length(st.stCSEM.transmitters(:,1)));
for iComp = 1:length(handles.sComponents)
 
    for iTx = 1:length(st.stCSEM.transmitters(:,1))
        lTx = st.DATA(:,3) == iTx;
 
        nMisfitAmpPhsT(iTx,2*iComp-1) = getMisfit( st.DATA(lAmp(:,iComp)&lTx,8));
        nMisfitAmpPhsT(iTx,2*iComp  ) = getMisfit( st.DATA(lPhs(:,iComp)&lTx,8));

        if any(lTx) 
            lUsed(iTx) = true;
        end
    end
end

 
handles.lUseTxPosition = true;

% Get position scale:
x  = st.stCSEM.transmitters(:,1)/1d3;
y  = st.stCSEM.transmitters(:,2)/1d3;
z  = st.stCSEM.transmitters(:,3)/1d3;
% normal CSEM data is along y axis, but for crosswell its along z mostly,
% so use whichever has the bigger range:
if max(y)-min(y) > max(z)-min(z)
    xd = y;
    handles.xlab = 'Tx Y Position (km)';
else
    xd = z;
    handles.xlab = 'Tx Z Position (km)';
end

xd = xd(lUsed);
nMisfitAmpPhsT = nMisfitAmpPhsT(lUsed,:); 

% Catch for duplicate xd values, add some random noise:
xd = xd+1d-4*randn(size(xd)); % cm level noise..

axes(hTx);

barColors = lines(size(nMisfitAmpPhsT,2));
if length(xd) < 100
    hTx = bar(xd,nMisfitAmpPhsT);
    for i = 1:length(hTx)
        hTx(i).FaceColor = barColors(i,:);
    end
else
     hTx =  plot(xd,nMisfitAmpPhsT,'marker','o','markersize',handles.markerSize,'linestyle','none');

    for i = 1:length(hRx)
        hTx(i).Color = barColors(i,:);
        hTx(i).MarkerFaceColor = barColors(i,:);
    end
end

lUsed = ~isnan(max(nMisfitAmpPhsT,[],1));


axis tight
ylabel('RMS') 
xlabel(handles.xlab)
legend(hTx(lUsed),sTypeStr(lUsed))
shading flat
grid on;
 

%
% Misfit by Rx-Tx offset range:
%
 
if st.lTowedArray
    % use offsets of towed receivers for the bins:
    
    nBins = max(st.iTowedArrayRxNum);
    
    nMisfitAmpPhsRange(nBins,1:length(sTypeStr)) = inf;
    
    iRx = st.DATA(:,4);
    iTx = st.DATA(:,3);
    rng = abs(st.stCSEM.transmitters(iTx,2)-st.stCSEM.receivers(iRx,2));
    
    
    iTowedRxNum = st.iTowedArrayRxNum(iRx);
    
    [~,iu] = unique(iTowedRxNum);
    branges = rng(iu);
    
    for iComp = 1:length(handles.sComponents) 

        for iRange = 1:nBins
            
            lRanges = iTowedRxNum == iRange;

            nMisfitAmpPhsRange(iRange,2*iComp-1) = getMisfit( st.DATA(lAmp(:,iComp)&lRanges,8));
            nMisfitAmpPhsRange(iRange,2*iComp  ) = getMisfit( st.DATA(lPhs(:,iComp)&lRanges,8));
        end
    end  
    
    handles.xlab = 'Y Range (km)';
    
    bBad = isnan(sum(nMisfitAmpPhsRange,2));
    nMisfitAmpPhsRange(bBad,:) =[];

    [branges,isort]= sort(branges);
    nMisfitAmpPhsRange = nMisfitAmpPhsRange(isort,:);
  
    % catch for close by PGS midpoint ranges:
    db = diff(branges);
    ismall = find(db < 1);
    if ~isempty(ismall)
        branges = (branges(ismall) + branges(ismall+1))/2;
        nMisfitAmpPhsRange  = sqrt( (nMisfitAmpPhsRange (ismall,:).^2 + nMisfitAmpPhsRange (ismall+1,:).^2)/2);
    end
    
else
    
    % Nodal Rx data, make some arbitary range bins:
    itx = st.DATA(:,3);
    irx = st.DATA(:,4);
    rxyz = st.stCSEM.transmitters(itx,1:3) - st.stCSEM.receivers(irx,1:3);
    dx = max(rxyz(:,1)) - min(rxyz(:,1));
    dy = max(rxyz(:,2)) - min(rxyz(:,2));
    dz = max(rxyz(:,3)) - min(rxyz(:,3));
    
    % usual CSEM data is along y, but check here and use axis with largest
    % range (e.g. use z for crosswell data):
    if dy >= dz && dy >= dx
        Ranges = rxyz(:,2);
        handles.xlab = 'Y Range (km)';
    elseif dz >= dy && dz >= dx
        Ranges = rxyz(:,3);
        handles.xlab = 'Z Range (km)';
    else
       Ranges =  rxyz(:,1); 
       handles.xlab = 'X Range (km)';
    end

    minR   = min(Ranges);
    maxR   = max(Ranges);
    nBins  = 20;
    ranges = linspace(minR-.01,maxR,nBins+1);
   
    nMisfitAmpPhsRange(nBins,1:length(sTypeStr)) = inf;

    for iComp = 1:length(handles.sComponents)

        for iRange = 1:length(ranges)-1
            lRanges = Ranges > ranges(iRange) & Ranges <= ranges(iRange+1);

            nMisfitAmpPhsRange(iRange,2*iComp-1) = getMisfit( st.DATA(lAmp(:,iComp)&lRanges,8));
            nMisfitAmpPhsRange(iRange,2*iComp  ) = getMisfit( st.DATA(lPhs(:,iComp)&lRanges,8));
        end
    end
    
    branges = (ranges(1:end-1) + ranges(2:end) ) / 2;
    
    
end

% get rid of ranges without data:
bBad = isnan(sum(nMisfitAmpPhsRange,2));
nMisfitAmpPhsRange(bBad,:) =[];
branges(bBad) = [];
axes(hRange); 

 
hb = bar(branges/1d3,nMisfitAmpPhsRange,1);
barColors = lines(size(nMisfitAmpPhsRange,2));
for i = 1:length(hb)
    hb(i).FaceColor = barColors(i,:);
end

axis tight;
ylabel('RMS') 
grid on;
xlabel(handles.xlab)
shading flat

%
% Misfit by frequency:
%
nMisfitAmpPhsF(1:length(sTypeStr)) = inf;
 
for iComp = 1:length(handles.sComponents)  
 
    for iFreq = 1:length(st.stCSEM.frequencies)
        lFreq = st.DATA(:,2) == iFreq;
        
        nMisfitAmpPhsF(iFreq,2*iComp-1) = getMisfit( st.DATA(lAmp(:,iComp)&lFreq,8));
        nMisfitAmpPhsF(iFreq,2*iComp  ) = getMisfit( st.DATA(lPhs(:,iComp)&lFreq,8));
    end
end
ff = st.stCSEM.frequencies;
handles.xlab = 'Frequency (Hz)';
 
ff = log10(ff);

axes(hFreq); 
hb = bar(nMisfitAmpPhsF);
barColors = lines(size(nMisfitAmpPhsF,2));
for i = 1:length(hb)
    hb(i).FaceColor = barColors(i,:);
end 
ylabel('RMS') 
xlabel(handles.xlab)
%legend(sTypeStr)
clear str;
for i = 1:length(st.stCSEM.frequencies)
    str{i} = sprintf('%.3g',st.stCSEM.frequencies(i));
end
set(hFreq, 'xtick',1:length(ff),'xticklabel',str);
axis tight
set(hFreq,'tag','frequency')

shading flat
grid on;

%
% Increase font size:
%
set( handles.hAxes,'fontsize',handles.fontSize)

set(handles.hAxes,'tickdir','out','TickLength', [0.0100 0.0250]/2)


%
% All done, return to normal mode:
%
set( handles.figure1, 'Pointer', 'arrow' );

drawnow 
 

% Store data back into gui:
guidata(hObject, handles);

end 
%--------------------------------------------------------------------------
function nMisfit = getMisfit(resid)
 
nMisfit = sqrt ( sum(resid.^2) / length(resid) );

end
% -------------------------------------------------------------------------
function handles = plot_Callback(hObject, eventdata, handles)

set( handles.figure1, 'Pointer', 'watch' );
 
drawnow;

% Get X axis units:
handles.sXa = handles.xaxisMenu.String(handles.xaxisMenu.Value);

try 

% If matrix plot:
if strcmpi(handles.plotType.String{handles.plotType.Value},'response matrix: position versus range') ...
|| strcmpi(handles.plotType.String{handles.plotType.Value},'response matrix: receivers versus transmitters')
    handles = plotMatrix_Callback(hObject, eventdata, handles);
    handles.figure1.Pointer = 'arrow';
    drawnow 
    return;
end

% Add line legend to file names if 2 files selected and appropriate
% plotType:
handles.lineStyles = {'-' '--' ':' '-.'};


% Get data files to plot:
iFiles = handles.fileListbox.Value;
if isempty(iFiles) || ~isfield(handles,'st') || isempty(handles.st)
    if isfield(handles,'hAxes')
        delete(handles.hAxes)
        handles.hAxes = [];
    end
    handles.figure1.Pointer = 'arrow';
    drawnow;
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

    if length(iFiles) > 1 && ismember(lower(sPlotType),{'response lines'})
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

% Make the plot:
handles = sub_makeAmpPhsPlot(handles);

% Update the RMS display, if data and model responses present for current
% file:
updateRMS(handles);

catch Me

 
%         echo off;
% 
%         waitfor( errordlg( {
%             'Error in plotMARE2DEM_CSEM:'
%             ' '
%             Me.identifier
%             Me.message
%             } ) );
         handles.figure1.Pointer = 'arrow';
        return
    
end

handles.figure1.Pointer = 'arrow';
drawnow 


% Store data back into gui:
guidata(hObject, handles);


end

%--------------------------------------------------------------------------
function handles = updateRMS(handles)

% use first data file selected, if more than 1 have been selected:
iFile = get(handles.fileListbox,'value');
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

lCSEM = DATA(~iFlagged,1) < 100;
 
rms = sqrt(sum(r(lCSEM).^2)./length(r(lCSEM)));
set(findobj(handles.figure1,'tag','onDataRMS'),'str',sprintf('%8.3f',rms))
end

%--------------------------------------------------------------------------
function handles = sub_makeAmpPhsPlot(handles)

% Delete any existing plots:

if isfield(handles,'hAxes')
    delete(handles.hAxes)
end
delete(findobj(handles.figure1,'type','axes'));

lShowResiduals = handles.showResiduals.Value; 
lShowModel     = handles.showModelResponse.Value; 
lShowData      = handles.showData.Value; 

if ~lShowResiduals && ~lShowData && ~lShowModel
    return
end
lUncertainty = false;
if strcmpi(handles.plotType.String(handles.plotType.Value),'Uncertainty %')
    lUncertainty    = true;
    lShowModel      = false;
    lShowResiduals  = false;
end
 
lShowOffData  = get(findobj(handles.figure1,'tag','showOffData'),'value');

fontSize      = handles.fontSize;
markers       = {'o' 's' 'd'};
markerSize    = handles.markerSize;
lineWidth     = handles.lineWidth;
sLineColorMap = handles.sLineColorMap;

% Get the data structure from the selected file:
st = handles.st(handles.iFiles);

figure(handles.figure1);


iFreqsSelected  = handles.frequencyListbox.Value;
iRxSelected     = handles.receiverListbox.Value;
iTxSelected     = handles.transmitterListbox.Value;
sComps          = handles.componentsListbox.String(handles.componentsListbox.Value);
sGather         = handles.gatherMenu.String(handles.gatherMenu.Value);


switch lower(sGather{1})
    case {'transmitters'}
        str = 'Receiver';
    case {'receivers' }
        str = 'Transmitter';
    case {'towed array'}
        str = 'Midpoint';
        iRxSelected = handles.st(1).stCSEM.towedArrayRxIndex(iRxSelected);
end  
        
switch lower(handles.sXa{1})

    case 'y position'

        xlab = sprintf('%s Y Position (km)',str);
    
    case 'z position'
        
        xlab = sprintf('%s Z Position (km)',str);
        
    case 'y range'
        xlab = 'Y Range (km)';
        
    case 'z range'
        xlab = 'Z Range (km)';
        
    case 'y range: in-tow, out-tow'

        switch lower(sGather{1})
            case {'transmitters'}
                xlab = 'Y Range Rx - Tx (km)';
            case {'receivers','towed array'}
                xlab = 'Y Range Tx - Rx  (km)';
        end  
                
    case 'z range: in-tow, out-tow'

        switch lower(sGather{1})
            case {'transmitters'}
                xlab = 'Z Range Rx - Tx (km)';
            case {'receivers','towed array'}
                xlab = 'Z Range Tx - Rx  (km)';
        end  
        
end

% Create Amplitude and Phase axes:
 
if lShowResiduals && (lShowData || lShowModel) && ~lUncertainty
 
    m = 2;
    n = 2;
    lColorbar = false;
    [posX,posY,widX,widY]= getRowColPositions(handles,m,n,lColorbar);    
    
    posAmp      = [ posX(1) posY(2) widX(1) widY(2)];
    posAmpRes   = [ posX(1) posY(1) widX(1) widY(1)];
    
    posPhs      = [ posX(2) posY(2) widX(2) widY(2)];
    posPhsRes   = [ posX(2) posY(1) widX(2) widY(1)];
 
    hAmp        = axes('units','pixels','Position', posAmp,'tag','hAxes');
    hPhs        = axes('units','pixels','Position', posPhs,'tag','hAxes');
    hAmpRes     = axes('units','pixels','Position', posAmpRes,'tag','hAxes');
    hPhsRes     = axes('units','pixels','Position', posPhsRes,'tag','hAxes');
    handles.hAxes = [hAmp hAmpRes hPhs hPhsRes];

    xlabel(hAmpRes,xlab)
    xlabel(hPhsRes,xlab)
    
elseif lShowResiduals && ~lShowData && ~lShowModel  && ~lUncertainty % plot residuals only
 
    m = 2;
    n = 1;
    lColorbar = false;
    [posX,posY,widX,widY]= getRowColPositions(handles,m,n,lColorbar);
   
    posAmpRes  = [ posX(1) posY(2) widX(1) widY(2)];
    posPhsRes  = [ posX(1) posY(1) widX(1) widY(1)];
    
    hAmpRes = axes('units','pixels','Position', posAmpRes,'tag','hAxes');
    hPhsRes = axes('units','pixels','Position', posPhsRes,'tag','hAxes');
    handles.hAxes = [hAmpRes hPhsRes];
    
    hAmp = [];
    hPhs = [];
    

    title(hAmpRes,'Amplitude')
    title(hPhsRes,'Phase')
    
    %xlabel(hAmpRes,xlab)
    xlabel(hPhsRes,xlab)
    
else

    m = 2;
    n = 1;
    lColorbar = false;
    [posX,posY,widX,widY]= getRowColPositions(handles,m,n,lColorbar);
   
    posAmp  = [ posX(1) posY(2) widX(1) widY(2)];
    posPhs  = [ posX(1) posY(1) widX(1) widY(1)];
    
    hAmp = axes('units','pixels','Position', posAmp,'tag','hAxes');
    hPhs = axes('units','pixels','Position', posPhs,'tag','hAxes');
    handles.hAxes = [hAmp hPhs];
    
    xlabel(hAmp,xlab)
    xlabel(hPhs,xlab)
    
    hAmpRes = [];
    hPhsRes = [];
   
%     title(hAmp,'Amplitude')
%     title(hPhs,'Phase')
    
end

set(handles.hAxes,'visible','off');  


if ~isempty(hAmp)
    if lUncertainty
        ylabel(hAmp,'Amplitude Uncertainty (%)')
        set(hAmp,'yscale','log')
    else
        ylabel(hAmp,'Amplitude (V/Am^2, T/Am)')
        set(hAmp,'yscale','log')
    end
end
if ~isempty(hPhs)
    if strcmpi(st(1).stCSEM.phaseConvention,'lag')
        set(hPhs,'ydir','rev');
        ylabel(hPhs,'Phase Lag')
    else
        ylabel(hPhs,'Phase Lead')
    end
    if lUncertainty
        set(hPhs,'ydir','normal','yscale','log')
        ylabel(hPhs,'Phase Uncertainty (%)')
    end
end
if ~isempty(hAmpRes)
    ylabel(hAmpRes,'Normalized Residual')
    ylabel(hPhsRes,'Normalized Residual')
end

set( handles.hAxes,'nextplot','add')

set( handles.hAxes,'fontsize',fontSize,'box','on')

sDataCodeLookupTable = m2d_getDataCodeLookupTable();

lineStyles = {'-' '--' ':' '-.'};

minXd = realmax;
maxXd = realmin;

% Loop over handles.iFiles (selected file)
if ~isempty(hAmp)
    iColorIndexPhsStart = hPhs.ColorOrderIndex;
    iColorIndexAmpStart = hAmp.ColorOrderIndex;

    iColorIndexPhs  = hPhs.ColorOrderIndex;
    iColorIndexAmp  = hAmp.ColorOrderIndex;
else
    iColorIndexPhsStart = hPhsRes.ColorOrderIndex;
    iColorIndexAmpStart = hAmpRes.ColorOrderIndex;

    iColorIndexPhs  = hPhsRes.ColorOrderIndex;
    iColorIndexAmp  = hAmpRes.ColorOrderIndex;
end

for iFile = 1:length(st)
    
    if length(st)>1
        sLegFile = st(iFile).sFile;
    else
        sLegFile = '';
    end
    if ~isempty(hAmp)
        hPhs.ColorOrderIndex = iColorIndexPhsStart;
        hAmp.ColorOrderIndex = iColorIndexAmpStart;
    else
        hPhsRes.ColorOrderIndex = iColorIndexPhsStart;
        hAmpRes.ColorOrderIndex = iColorIndexAmpStart;
    end
 
 
    % Loop over components:
    for iCmp = 1:length(st(iFile).Cmps)
        
        if length(st(iFile).Cmps)>1
            sLegCmp = sDataCodeLookupTable{ st(iFile).Cmps(iCmp).Cmp,1};
        else
            sLegCmp = '';
        end

        % Is this component selected for plotting?
        if ismember(sDataCodeLookupTable( st(iFile).Cmps(iCmp).Cmp,1),sComps)
        
            % Yes, pull out data:
            d   =  st(iFile).Cmps(iCmp).d(iRxSelected,iTxSelected,iFreqsSelected);
            e   =  st(iFile).Cmps(iCmp).e(iRxSelected,iTxSelected,iFreqsSelected);
            m   =  st(iFile).Cmps(iCmp).m(iRxSelected,iTxSelected,iFreqsSelected);
            r   =  st(iFile).Cmps(iCmp).r(iRxSelected,iTxSelected,iFreqsSelected);
            id  =  st(iFile).Cmps(iCmp).iData(iRxSelected,iTxSelected,iFreqsSelected);        
         
            iRx = st(iFile).DATA(id(~isnan(id)),4);
            xRx = nan(size(d));
            
            iTx = st(iFile).DATA(id(~isnan(id)),3);
            xTx = nan(size(d));
        
            
        % Get Y and Z position depending on request x axis:
            switch lower(handles.sXa{1})

                case {'z position','z range','z range: in-tow, out-tow'}

                    xRx(~isnan(id)) =  st(iFile).stCSEM.receivers(iRx,3);
                    xTx(~isnan(id)) =  st(iFile).stCSEM.transmitters(iTx,3);
                    
                otherwise % assume normal y spanning survey
                    xRx(~isnan(id)) =  st(iFile).stCSEM.receivers(iRx,2);
                    xTx(~isnan(id)) =  st(iFile).stCSEM.transmitters(iTx,2);
                
            end


            % Fill in any missing values between first and list present
            % values:
            for i = 1:size(xRx,2)
                lGood = ~isnan(xRx(:,i));
                iGood = find(lGood);
                xg = xRx(lGood,i);
                if length(xg)>1
                    xRx(:,i) = interp1(iGood , xg,1:length(xRx(:,i)));
                end
            end
            for i = 1:size(xTx,2)
                lGood = ~isnan(xTx(:,i));
                iGood = find(lGood);
                xg = xTx(lGood,i);
                if length(xg)>1
                    xTx(:,i) = interp1(iGood , xg,1:length(xTx(:,i)));
                end
            end            
            switch lower(sGather{1})
                
                case 'transmitters'

                    xRange = xRx - xTx;
                    xPos   = xRx;

                case 'receivers'

                    d  = permute(d,[2 1 3]);
                    e  = permute(e,[2 1 3]);
                    m  = permute(m,[2 1 3]);
                    r  = permute(r,[2 1 3]);
                    id = permute(id,[2 1 3]);
                    
                    xRange = permute((xTx - xRx),[2 1 3]);
                    xPos   = permute(xTx,[2 1 3]);

                case 'towed array'
                     
                    xRange = permute(xTx - xRx,[2 1 3]);
                    xPos   = permute((xTx + xRx)/2,[2 1 3]); % Plot at midpoint
                    
                    d  = permute(d,[2 1 3]);
                    e  = permute(e,[2 1 3]);
                    m  = permute(m,[2 1 3]);
                    r  = permute(r,[2 1 3]); 
                    id = permute(id,[2 1 3]);
                    
            end                              
                            
            % Get x axis data:            
            switch lower(handles.sXa{1})
                
                case {'y position','z position' }
                     
                    % nothing to do since xPos already set
                    
                case {'y range: in-tow, out-tow','z range: in-tow, out-tow'}
                    xPos = (xRange);
 
                case {'y range','z range'}
                    xPos = abs(xRange);          
                   
            end
                   
            xPos = xPos/1000;
            
           
            % If there is only 1 Tx or 1 Rx and multiple freqs, color by
            % frequency:
            if size(d,1) == 1 || size(d,2) == 1 && size(d,3) > 1
                lColorByFreq = true;
                cm = feval(sLineColorMap,size(d,3));
                lColorByComp = false; 
                
            % Or if there is only 1 Tx or Rx and multiple components, color by component type:     
            elseif size(d,1) == 1 || size(d,2) == 1 &&  length(sComps)>1
                lColorByComp = true; 
                lColorByFreq = false;
                cm = feval(sLineColorMap,length(sComps));
            else
                lColorByFreq = true;
                lColorByComp = false; 
                cm = feval(sLineColorMap,size(d,2));
            end
            
            if ~isempty(hAmp)
                hAmp.ColorOrder = cm;
                hPhs.ColorOrder = cm;
            end
            if ~isempty(hAmpRes)
                hAmpRes.ColorOrder = cm;
                hPhsRes.ColorOrder = cm;
            end
            
            % Is this amplitude or phase data?
            if  any(isfinite(id(:)))
                
                for iFreq = 1:size(d,3)    
                    
                    % Get frequency text for legend:
                    if size(d,3) > 1
                        sLegFreq = sprintf('%s Hz',handles.frequencyListbox.String{handles.frequencyListbox.Value(iFreq)});
                    else
                        sLegFreq = '';
                    end
        
                    
                    % Each frequency gets a different marker:
                    marker = markers{mod(iFreq-1,length(markers))+1};
              
                    xd = squeeze(xPos(:,:,iFreq));
                    xr = squeeze(xRange(:,:,iFreq));
                    yd = squeeze(d(:,:,iFreq));
                    ym = squeeze(m(:,:,iFreq));
                    ye = squeeze(e(:,:,iFreq));
                    yr = squeeze(r(:,:,iFreq));
                    thisId = squeeze(id(:,:,iFreq));
                    
                    lGood = ~isnan(yd);
                    minXd = min([ min(xd(lGood)),minXd]);
                    maxXd = max([ max(xd(lGood)),maxXd]);
                    
                    % Interpolate 'missing' model data points so that lines
                    % are always plotted when there are missing points for
                    % various Rx and Tx positions:
                    
                    switch lower(handles.sXa{1})

                    case 'y range'

                    otherwise

                        for i = 1:size(xd,2)
                            lyGood = ~isnan(yd(:,i)); % catch nan's in xd where no data for this iRx,iTx.

                            if any(lyGood) && length(find(lyGood))>1
                                if strcmpi(sDataCodeLookupTable{st(iFile).Cmps(iCmp).Cmp,2},'amplitude')  
                                    ym(:,i) = 10.^interp1(xd(lyGood,i),log10(ym(lyGood,i)),xd(:,i));
                                else
                                    ym(:,i) = interp1(xd(lyGood,i),ym(lyGood,i),xd(:,i));
                                end
                            end
                        end

                    end

                    if strcmpi(sGather,'Towed Array')
                        xr = xr*0;  % set range to zero so phase unwrapping behaves sanely
                    end
                    
                    if lColorByFreq
                        
                        % Do nothing, let color keep changing
                         lstyle = lineStyles{mod(iFile-1,length(lineStyles))+1}; % use line styles for files
                    
                    elseif lColorByComp
 
                         % Do nothing, let color keep changing
                         lstyle = lineStyles{mod(iFile-1,length(lineStyles))+1}; % use line styles for files
                                           
                    else
                        % Make sure each frequency uses the same colors.
                        if ~isempty(hAmp)
                            hPhs.ColorOrderIndex = iColorIndexPhs;
                            hAmp.ColorOrderIndex = iColorIndexAmp;
                        else
                            hPhsRes.ColorOrderIndex = iColorIndexPhs;
                            hAmpRes.ColorOrderIndex = iColorIndexAmp;
                        end
                       
                        % but change the line style:                                       
                        lstyle = lineStyles{mod(iFile-1,length(lineStyles))+1}; % use this for 1 freq multiple files
                                             
                    end
       
                    %
                    % Check for any flagged data:
                    %
                    
                    lFlagged = false(size(thisId));
                    lFlagged(~isnan(thisId)) =  st(iFile).iFlagged(thisId(~isnan(thisId))); 
                    
                    [ydOn,ydOff]     = deal(yd);
                    ydOn(lFlagged)   = nan;
                    ydOff(~lFlagged) = nan;
                    [yeOn,yeOff]     = deal(ye);
                    yeOn(lFlagged)   = nan;
                    yeOff(~lFlagged) = nan;
                    [ymOn,ymOff]     = deal(ym);
                    ymOn(lFlagged)   = nan;
                    ymOff(~lFlagged) = nan;
                    [yrOn,yrOff]     = deal(yr);
                    yrOn(lFlagged)   = nan;
                    yrOff(~lFlagged) = nan;     
      
                    
                    switch lower(sDataCodeLookupTable{ st(iFile).Cmps(iCmp).Cmp,2})

                    
                        case {'amplitude','pemax'}
                            if ~isempty(hAmp)
                                iColorIndex = hAmp.ColorOrderIndex;
                            else
                                iColorIndex = hAmpRes.ColorOrderIndex;
                            end
                            
                            % Data amplitudes:

                            
                            if lShowData
                                                                        
                                if lUncertainty
                                       
                                    ydOn  = yeOn./ydOn*100;
                                    ydOff = yeOff./ydOff*100;
                                    ye    = nan*ye;
                                    yeOn  = nan*yeOn;
                                    yeOff = nan*yeOff;
                            
                                end
                                
                                hAD = semilogy(hAmp,xd,ydOn,'marker',marker,'markersize',markerSize,'linestyle','none','visible','off'); 
                                for i = 1:length(hAD) 
                                    set(hAD(i),'userdata',thisId(:,i),'tag','dataID');
                                end
                                
                                for i = 1:length(hAD) 
                                    hAD(i).MarkerFaceColor= hAD(i).Color;
                                end
                                
                                handles.hdta = hAD;
                                
                                for i = length(hAD):-1:1

                                    switch lower(sGather{1})

                                        case 'transmitters'
                                            gatherStr = sprintf('Tx #%i',iTxSelected(i));
                                        case 'receivers'
                                            gatherStr = sprintf('Rx #%i',iRxSelected(i));
                                        case 'towed array'
                                            gatherStr = sprintf('Offset #%i',iRxSelected(i));

                                    end   

                                     h(i).DisplayName = sprintf('Data %s %s %s %s',sLegFile,sLegCmp,sLegFreq,gatherStr);
                                end
                                
                                if ~lUncertainty
 
                                    % Error bars:
                                    if st(iFile).bWaslog10                          
                                        logErr = ye./ydOn*.4343;
                                        yUpper = 10.^(log10(ydOn)+logErr);
                                        yLower = 10.^(log10(ydOn)-logErr);

                                    else 
                                        yUpper = ydOn+ye;
                                        yLower = ydOn-ye;
                                    end

                                    iNeg = yLower <= 0;
                                    if any(iNeg)
                                        logErr = ye(iNeg)./ydOn(iNeg)*.4343;
                                        yLower(iNeg) = 10.^(log10(ydOn(iNeg)) - logErr);
                                    end
                                    yLower(yLower < 0 ) = ydOn(yLower < 0) *.000001;

                                    hAmp.ColorOrderIndex =  iColorIndex;

                                    xe(:,:,3) = xd;
                                    xe(:,:,2) = xd;
                                    xe(:,:,1) = xd;
                                    ye(:,:,3) = nan*yUpper;
                                    ye(:,:,2) = yUpper;
                                    ye(:,:,1) = yLower;
                                    xe = permute(xe,[3,1,2]);
                                    ye = permute(ye,[3,1,2]);

                                    ye =  reshape(ye,[3*size(xd,1),size(xd,2)]);
                                    xe =  reshape(xe,[3*size(xd,1),size(xd,2)]);

                                    h = semilogy(hAmp,xe,ye,'-','lineWidth',1,'DisplayName','','HandleVisibility','on','visible','off','tag','errorBar');
                                    clear xe ye
                             
                                    for i = 1:length(h) 
                                        if length(hAD)>1
                                            ih = i;
                                        else
                                            ih = 1;
                                        end
                                        h(i).Color= hAD(ih).Color;
                                    end
                                
                                    % Flagged data:
                                    if lShowOffData
                                        h = semilogy(hAmp,xd,ydOff,'marker','x','markersize',4,'linestyle','none','visible','off'); 
                                        for i = 1:length(h) 
                                            set(h(i),'userdata',thisId(:,i),'tag','dataID','color',hAD(i).MarkerFaceColor)                                
                                        end
                                    end

                                end
                            end
                            
                            % Model amplitudes:

                            if lShowModel                             

                                if any(isfinite(ymOn(:)))

                                    hAmp.ColorOrderIndex =  iColorIndex;
                                    if lShowOffData % plot evertything
                                        h = semilogy(hAmp,xd,ym,lstyle,'linewidth',lineWidth,'visible','off');
                                    else
                                        h = semilogy(hAmp,xd,ymOn,lstyle,'linewidth',lineWidth,'visible','off');
                                    end

                                    for i = 1:length(h)
                                        set(h(i),'userdata',thisId(:,i),'tag','dataID');
                                    end
                                    if ~strcmpi(handles.sModelResponseColor,'data')
                                        for i = 1:length(h)
                                            set(h(i),'color',handles.sModelResponseColor);
                                        end
                                    end

                                    for i = length(h):-1:1

                                        switch lower(sGather{1})

                                            case 'transmitters'
                                                gatherStr = sprintf('Tx #%i',iTxSelected(i));
                                            case 'receivers'
                                                gatherStr = sprintf('Rx #%i',iRxSelected(i));
                                            case 'towed array'
                                                gatherStr = sprintf('Offset #%i',iRxSelected(i));

                                        end   

                                         h(i).DisplayName = sprintf('Model %s %s %s %s',sLegFile,sLegCmp,sLegFreq,gatherStr);
                                    end



                                end
                            end

                            
                            % Normalized Residuals:
                            
                            if lShowResiduals
                                   
                                hAmpRes.ColorOrderIndex =  iColorIndex;

                                h = plot(hAmpRes,xd,yrOn,'marker',marker,'markersize',markerSize,'linestyle','none','visible','off');
                                
                                for i = 1:length(h) 
                                    set(h(i),'userdata',thisId(:,i),'tag','dataID');
                                end
                                
                                for i = 1:length(h)
                                    h(i).MarkerFaceColor=h(i).Color;
                                end
                                
                               % Flagged data:
                                if lShowOffData
                                    h = semilogy(hAmpRes,xd,yrOff,'marker','x','markersize',4,'linestyle','none','visible','off'); 
                                    for i = 1:length(h) 
                                        set(h(i),'userdata',thisId(:,i),'tag','dataID');
                                    end
                                end
                                
                                
                            end

                        case 'phase'

                            if ~isempty(hPhs)
                                iColorIndex = hPhs.ColorOrderIndex;
                            else
                                iColorIndex = hPhsRes.ColorOrderIndex;
                            end                           
                  
                            % Data phase:
                            
                            if lShowData
                                
                                if lUncertainty
                                    ydOn  = abs(yeOn*pi/180*100);
                                    ydOff = abs(yeOff*pi/180*100);
                                    ye    = nan*ye;
                                else

                                    % Need to unwrap here...
                                    ydOn = sub_unwrapPhaseWithRange(xr,ydOn,st(iFile).stCSEM.phaseConvention);
                                
                                end
                                
                                hPD = plot(hPhs,xd,ydOn,'marker',marker,'markersize',markerSize,'linestyle','none','visible','off');  
                   
                                for i = 1:length(hPD)
                                    set(hPD(i),'userdata',thisId(:,i),'tag','dataID')
                                end
                                
                                for i = 1:length(hPD)
                                    hPD(i).MarkerFaceColor=hPD(i).Color;
                                end

                                if ~lUncertainty
                                    
                                    % Error bars:                        
                                    yUpper = ydOn+ye;
                                    yLower = ydOn-ye;

                                    xe(:,:,3) = xd;
                                    xe(:,:,2) = xd;
                                    xe(:,:,1) = xd;
                                    ye(:,:,3) = nan*yUpper;
                                    ye(:,:,2) = yUpper;
                                    ye(:,:,1) = yLower;
                                    xe = permute(xe,[3,1,2]);
                                    ye = permute(ye,[3,1,2]);

                                    ye =  reshape(ye,[3*size(xd,1),size(xd,2)]);
                                    xe =  reshape(xe,[3*size(xd,1),size(xd,2)]);

                                    hPhs.ColorOrderIndex =  iColorIndex; 

                                    h = plot(hPhs,xe,ye,'-','lineWidth',1,'HandleVisibility','on','visible','off','tag','errorBar');  
                                    clear xe ye
                                    for i = 1:length(h) 
                                        if length(hPD)>1
                                            ih = i;
                                        else
                                            ih = 1;
                                        end
                                        h(i).Color= hPD(ih).Color;
                                    end
                                
                                    
                                    % Flagged data:
                                    if lShowOffData
                                        ydOff = sub_unwrapPhaseWithRange(xr,ydOff,st(iFile).stCSEM.phaseConvention);
                                        h = plot(hPhs,xd,ydOff,'marker','x','markersize',4,'linestyle','none','visible','off'); 
                                        for i = 1:length(h) 
                                            set(h(i),'userdata',thisId(:,i),'tag','dataID','color',hPD(i).MarkerFaceColor)
                                        end
                                    end
                                
                                end
                            end
                            
                            % Model phase:
                            if lShowModel
                                
                                if any(isfinite(ym(:)))
                                    
                                    hPhs.ColorOrderIndex =  iColorIndex;
                                 
                                    if lShowOffData % plot evertything
                                        ym = sub_unwrapPhaseWithRange(xr,ym,st(iFile).stCSEM.phaseConvention);
                                        h = plot(hPhs,xd,ym,lstyle,'linewidth',lineWidth,'visible','off');
                                    else
                                        ymOn = sub_unwrapPhaseWithRange(xr,ymOn,st(iFile).stCSEM.phaseConvention);
                                        h = plot(hPhs,xd,ymOn,lstyle,'linewidth',lineWidth,'visible','off');
                                    end
                                    for i = 1:length(h) 
                                        set(h(i),'userdata',thisId(:,i),'tag','dataID');
                                    end
                                    
                                    if ~strcmpi(handles.sModelResponseColor,'data');
                                        for i = 1:length(h)
                                            set(h(i),'color',handles.sModelResponseColor);
                                        end
                                    end
                                    
                                end
                            end
                            
                          % Phase Residuals:
                            
                            if lShowResiduals                                                              
                                hPhsRes.ColorOrderIndex =  iColorIndex;

                                h = plot(hPhsRes,xd,yrOn,'marker',marker,'markersize',markerSize,'linestyle','none','visible','off'); 
                                for i = 1:length(h) 
                                    set(h(i),'userdata',thisId(:,i),'tag','dataID');
                                end
                                
                                for i = 1:length(h)
                                    h(i).MarkerFaceColor=h(i).Color;
                                end
                                
                                % Flagged data:
                                if lShowOffData
                                    h = semilogy(hPhsRes,xd,yrOff,'marker','x','markersize',4,'linestyle','none','visible','off'); 
                                    for i = 1:length(h) 
                                        set(h(i),'userdata',thisId(:,i),'tag','dataID');
                                    end
                                end                                
                                
                            end
                            
                     
                    end

                end
            
            end
            
        end
    
    end
end
 
if  maxXd ~= realmin  && minXd ~= realmax % if non data or all nan data, then these will have initialization values, skip setting limits
    for i = 1:length(handles.hAxes)
        dr = maxXd - minXd;
        if dr > 0 
            set(handles.hAxes(i),'XLim',[minXd-dr*.01; maxXd+dr*.01;]); %min(min(xPos)),max(max(xPos))]);
        end
    end
end

set(handles.hAxes,'visible','on')

set(findobj(gcf,'tag','dataID'),'visible','on');
set(findobj(gcf,'tag','errorBar'),'visible','on');

 
% DGM 1/23/2015 Put a line at ZERO on each of the residual plots so that bias
% can be easily seen. (Requested by users.) Do this AFTER the plots are fully
% assembled and linked so that the full xlim is set. Put the line object UNDER
% the data.

if lShowResiduals && ~lUncertainty
    uistack( plot( hAmpRes, xlim(hAmpRes), [0 0], '--k' ...
                 , 'HitTest', 'off', 'tag', 'zeroline', 'DisplayName', '' ) ...
           , 'bottom' );

    
    uistack( plot( hPhsRes, xlim(hPhsRes), [0 0], '--k' ...
                 , 'HitTest', 'off', 'tag', 'zeroline', 'DisplayName', '' ) ...
           , 'bottom' );
       
    ylA = abs(get(hAmpRes,'ylim'));
    ylP = abs(get(hPhsRes,'ylim'));
     
    yl = max([ylA(:);ylP(:)]);
    
    set(hAmpRes,'ylim',yl*[-1.05 1.05] ); % DGM don't put points right on the border! [-yl yl] );       
    set(hPhsRes,'ylim',yl*[-1.05 1.05] ); % DGM don't put points right on the border! [-yl yl] ); 
    
    linkaxes([hAmpRes hPhsRes] ,'y')
end
 
if lUncertainty   
    yp = get(hPhs,'ylim');
    ya = get(hAmp,'ylim');
    
    yl = [min([yp(1) ya(1)]) max([yp(2) ya(2)])];
    set(hPhs,'ylim',yl);
    set(hAmp,'ylim',yl);

end
 
linkaxes(handles.hAxes,'x')  
for i = 1:length(handles.hAxes)
    handles.hAxes(i).XGrid = 'on';
    handles.hAxes(i).YGrid = 'on';
end

end
 
% -------------------------------------------------------------------------
 function [posX,posY,widX,widY]= getRowColPositions(handles,m,n,lColorbar)
% one position function to rule them all...


    
    figPos  = handles.figure1.Position;
    toolPos = handles.UIpanel.Position; 
    
    if lColorbar
        dxcb = 60;
    else dxcb = 0;
    end
    
    dx0 = 40;
   
    x0  = toolPos(1)+toolPos(3) + dx0; 
   
    y0 = 20;
     
    wTotal = figPos(3)-x0;
    hTotal = figPos(4)-y0;

    rowH = hTotal/m;
    colW = wTotal/n;
    
    dy = 30; 
    dx = 40;
    
    % Row positions:
    for i = m:-1:1
        posY(i) = y0 + (i-1)*rowH + dy;
        widY(i) = rowH - 2*dy;
    end
    for i = n:-1:1
        posX(i) = x0 + (i-1)*colW + dx;
        widX(i) = colW - 2*dx - dxcb;
    end
    
 end
%--------------------------------------------------------------------------
function handles = plotMatrix_Callback(hObject, eventdata, handles)

 
% Delete any existing plots:
if isfield(handles,'hAxes')
    delete(handles.hAxes)
end
delete(findobj(handles.figure1,'type','axes'));

% Get single data file to plot:
iFile = get(handles.fileListbox,'value');
iFile = iFile(1);
if isempty(iFile) || ~isfield(handles,'st') || isempty(handles.st)
    return
end

% Get the data structure from the selected file:
st = handles.st(iFile);

%
% Check that there are more than one Tx and Rx, if not return:
% 
if size(st.stCSEM.receivers,1) == 1 || size(st.stCSEM.transmitters,1) == 1
    % This case should never happen since the new Jan 2016 code removes Matrix
    % plotting option when nRx or nTx == 1.
   return
end
    
% Get show buttons:
lShowResiduals = handles.showResiduals.Value; 
lShowModel     = handles.showModelResponse.Value; 
lShowData      = handles.showData.Value; 

lShowOffData = get(findobj(handles.figure1,'tag','showOffData'),'value');
 
% Get frequency and component to plot:
iFreq = get(handles.frequencyListbox,'value');

iComp = get(handles.componentsListbox,'value');
sComp = get(handles.componentsListbox,'string');
sComp = sComp(iComp);

fontSize  = handles.fontSize;



% Check for specific plot type:
h = findobj(handles.figure1,'tag','plotType');
str = get(h,'String');
val = get(h,'Value');
plotType =str{val};

switch lower(plotType)
 
    case 'response matrix: receivers versus transmitters'
        sGather = 'tx_vs_rx';
        xstr = 'Receiver #';
        ystr = 'Transmitter #';
        
    case 'response matrix: position versus range'
 

        sGather   = handles.gatherMenu.String{handles.gatherMenu.Value};
        if st.lTowedArray 
            sGather = 'towed array';
            xstr = 'Transmitter Y Position (km)';
            ystr = 'Y Range (km)';
                        
        else
        
            switch lower(handles.sXa{1})

                case {'y position','y range: in-tow, out-tow','y range'}
                    
                    switch lower(sGather)

                    case 'transmitters'
                        xstr = 'Transmitter Y Position (km)';
                        ystr = 'Y Range (km)';
                    case 'receivers'
                        xstr = 'Receiver Y Position (km)';
                        ystr = 'Y Range (km)';
                    end

                case {'z position','z range: in-tow, out-tow','z range'}
                    
                    switch lower(sGather)

                    case 'transmitters'
                        xstr = 'Transmitter Z Position (km)';
                        ystr = 'Z Range (km)';
                    case 'receivers'
                        xstr = 'Receiver Z Position (km)';
                        ystr = 'Z Range (km)';
                    end

            end               
        
        end
       
end

figure(handles.figure1);

%
% Create Axes:
%
m = lShowResiduals + lShowData + lShowModel;
if m == 0
    return
end
n = 2;
if m == 1
    m = 2;
    n = 1;
end
lColorbar = true;

[posX,posY,widX,widY]= getRowColPositions(handles,m,n,lColorbar);
 
[hAmpD, hAmpM, hAmpR, hPhsD, hPhsM, hPhsR] = deal([]);

if lShowResiduals && lShowData && lShowModel
    
    posAmpD  = [ posX(1) posY(3) widX(1) widY(3)];
    posAmpM  = [ posX(1) posY(2) widX(1) widY(2)];
    posAmpR  = [ posX(1) posY(1) widX(1) widY(1)];
    posPhsD  = [ posX(2) posY(3) widX(2) widY(3)];
    posPhsM  = [ posX(2) posY(2) widX(2) widY(2)];
    posPhsR  = [ posX(2) posY(1) widX(2) widY(1)];
    hAmpD = axes('units','pixels','Position', posAmpD,'tag','hAxes');
    hAmpM = axes('units','pixels','Position', posAmpM,'tag','hAxes');
    hAmpR = axes('units','pixels','Position', posAmpR,'tag','hAxes');
    hPhsD = axes('units','pixels','Position', posPhsD,'tag','hAxes');
    hPhsM = axes('units','pixels','Position', posPhsM,'tag','hAxes');
    hPhsR = axes('units','pixels','Position', posPhsR,'tag','hAxes');
 
    xlabel(hAmpR,xstr)
    xlabel(hPhsR,xstr)
    ylabel(hAmpD,ystr)
    ylabel(hAmpM,ystr)
    ylabel(hAmpR,ystr)  
    
elseif lShowResiduals && lShowData 

    posAmpD  = [ posX(1) posY(2) widX(1) widY(2)];
    posAmpR  = [ posX(1) posY(1) widX(1) widY(1)];
    posPhsD  = [ posX(2) posY(2) widX(2) widY(2)];
    posPhsR  = [ posX(2) posY(1) widX(2) widY(1)];
    hAmpD = axes('units','pixels','Position', posAmpD,'tag','hAxes');
    hAmpR = axes('units','pixels','Position', posAmpR,'tag','hAxes');
    hPhsD = axes('units','pixels','Position', posPhsD,'tag','hAxes');
    hPhsR = axes('units','pixels','Position', posPhsR,'tag','hAxes');

    xlabel(hAmpR,xstr)
    xlabel(hPhsR,xstr)
    ylabel(hAmpD,ystr)
    ylabel(hAmpR,ystr)  
    
elseif lShowResiduals && lShowModel

    posAmpM  = [ posX(1) posY(2) widX(1) widY(2)];
    posAmpR  = [ posX(1) posY(1) widX(1) widY(1)];
    posPhsM  = [ posX(2) posY(2) widX(2) widY(2)];
    posPhsR  = [ posX(2) posY(1) widX(2) widY(1)];
    hAmpM = axes('units','pixels','Position', posAmpM,'tag','hAxes');
    hAmpR = axes('units','pixels','Position', posAmpR,'tag','hAxes');
    hPhsM = axes('units','pixels','Position', posPhsM,'tag','hAxes');
    hPhsR = axes('units','pixels','Position', posPhsR,'tag','hAxes');
  
    xlabel(hAmpR,xstr)
    xlabel(hPhsR,xstr)
    ylabel(hAmpM,ystr)
    ylabel(hAmpR,ystr)    
    
elseif lShowData && lShowModel

    posAmpD  = [ posX(1) posY(2) widX(1) widY(2)];
    posAmpM  = [ posX(1) posY(1) widX(1) widY(1)];
    posPhsD  = [ posX(2) posY(2) widX(2) widY(2)];
    posPhsM  = [ posX(2) posY(1) widX(2) widY(1)];
    hAmpD = axes('units','pixels','Position', posAmpD,'tag','hAxes');
    hAmpM = axes('units','pixels','Position', posAmpM,'tag','hAxes');
    hPhsD = axes('units','pixels','Position', posPhsD,'tag','hAxes');
    hPhsM = axes('units','pixels','Position', posPhsM,'tag','hAxes');
   
    xlabel(hAmpM,xstr)
    xlabel(hPhsM,xstr)
    ylabel(hAmpD,ystr)
    ylabel(hAmpM,ystr)
    
elseif lShowData 

    posAmpD  = [ posX(1) posY(2) widX(1) widY(2)];
    posPhsD  = [ posX(1) posY(1) widX(1) widY(1)];
    hAmpD = axes('units','pixels','Position', posAmpD,'tag','hAxes');
    hPhsD = axes('units','pixels','Position', posPhsD,'tag','hAxes');
    
    xlabel(hAmpD,xstr)
    xlabel(hPhsD,xstr)
    ylabel(hAmpD,ystr)
    
elseif lShowModel

    posAmpM  = [ posX(1) posY(2) widX(1) widY(2)];
    posPhsM  = [ posX(1) posY(1) widX(1) widY(1)];
    hAmpM = axes('units','pixels','Position', posAmpM,'tag','hAxes');
    hPhsM = axes('units','pixels','Position', posPhsM,'tag','hAxes');
    
    xlabel(hAmpM,xstr)
    xlabel(hPhsM,xstr)
    ylabel(hAmpM,ystr)
    
elseif lShowResiduals

    posAmpR  = [ posX(1) posY(2) widX(1) widY(2)];
    posPhsR  = [ posX(1) posY(1) widX(1) widY(1)];
    hAmpR = axes('units','pixels','Position', posAmpR,'tag','hAxes');
    hPhsR = axes('units','pixels','Position', posPhsR,'tag','hAxes');
    
    xlabel(hAmpR,xstr)
    xlabel(hPhsR,xstr)
    ylabel(hAmpR,ystr)
     
end

handles.hAxes = [hAmpD hAmpM hAmpR hPhsD hPhsM hPhsR];
 
set(handles.hAxes,'fontsize',fontSize,'box','on','ydir','rev','tickdir','out','TickLength', [0.0100 0.0250]/2,'visible','off')

linkaxes(handles.hAxes,'xy')

cm = m2d_colormaps(handles.sColorMap);
colormap(cm);
 

% Always plot residuals with the anomaly colormap:
if ~isempty(hAmpR)
    cm = m2d_colormaps('D1');
    colormap(hAmpR,cm);
end
if ~isempty(hPhsR)
    cm = m2d_colormaps('D1');
    colormap(hPhsR,cm);
end

for i = 1:length(handles.hAxes)
    colorbar('peer',handles.hAxes(i))
    handles.hAxes(i).Color = [.9 .9 .9]; % gray background
end

set(handles.hAxes,'layer','top','box','on');

% Store data back into gui:
guidata(hObject, handles);

sDataCodeLookupTable = m2d_getDataCodeLookupTable(); 

% Loop over components:
for iCmp = 1:length(st.Cmps)

    % Is this component selected for plotting?
    if ismember(sDataCodeLookupTable( st.Cmps(iCmp).Cmp,1),sComp)

        % Yes, pull out data:
        d   =  squeeze(st.Cmps(iCmp).d(:,:,iFreq));  
        m   =  squeeze(st.Cmps(iCmp).m(:,:,iFreq));
        r   =  squeeze(st.Cmps(iCmp).r(:,:,iFreq));
        id  =  squeeze(st.Cmps(iCmp).iData(:,:,iFreq));
        
        switch lower(sGather)  % set xRange and xPos:

            case 'transmitters'

                switch lower(handles.sXa{1})

                case {'y position','y range: in-tow, out-tow','y range'}
                    [tt,rr] = meshgrid(st.stCSEM.transmitters(:,2),st.stCSEM.receivers(:,2));

                    xRange = (rr-tt)/1d3;
                    xPos   = st.stCSEM.transmitters(:,2)/1d3;
                
                case {'z position','z range: in-tow, out-tow','z range'}

                    [tt,rr] = meshgrid(st.stCSEM.transmitters(:,3),st.stCSEM.receivers(:,3));
                    xRange = (rr-tt)/1d3;
                    xPos   = st.stCSEM.transmitters(:,3)/1d3;
                end
                    
            case 'receivers'

                d = d';
                m = m';
                r = r';
                id = id';
                
                switch lower(handles.sXa{1})
                    
                case {'y position','y range: in-tow, out-tow','y range'}
                    [tt,rr] = meshgrid(st.stCSEM.transmitters(:,2),st.stCSEM.receivers(:,2));
                    xRange = (tt-rr)'/1d3;
                    xPos   = st.stCSEM.receivers(:,2)/1d3;
                
                    
                case {'z position','z range: in-tow, out-tow','z range'}
                    [tt,rr] = meshgrid(st.stCSEM.transmitters(:,3),st.stCSEM.receivers(:,3));
                    xRange = (tt-rr)'/1d3;
                    xPos   = st.stCSEM.receivers(:,3)/1d3;
                end
                

            case 'towed array'

                %xRange = xRx - xTx;
                
              
                iRx = st.DATA(:,4);
                iTx = st.DATA(:,3);
                
                yRx = st.stCSEM.receivers(:,2);
                
                id2 = id;
                id2(isnan(id2)) = 1;
                
                yRx = yRx(iRx(id2));
                yRx(isnan(id)) = nan;
                
                yTx = st.stCSEM.transmitters(:,2);
                yTx = yTx(iTx(id2));
                yTx(isnan(id)) = nan;
                
                xRange = abs(yTx-yRx)/1d3;
                xPos   = st.stCSEM.transmitters(:,2)/1d3;
                
            case 'tx_vs_rx'
                
                d = d';
                m = m';
                r = r';
                id = id';
                
                iRx =  1:length(st.stCSEM.receivers(:,2));
                iTx = 1:length(st.stCSEM.transmitters(:,2));
                
                [~,xRange] = meshgrid(iRx,iTx);
                xPos = iRx;
                
                
        end                              
        [X,Y] = deal(zeros(4,numel(xRange)));

        lUse = false(size(d));
        
        lFlagged = false(numel(xRange),1);
        ID = zeros(numel(xRange),1);
        
        dx = diff(xPos);
        dx(end+1) = dx(end);
        dy = diff(xRange,1,1);
        dy(end+1,:) = dy(end,:);

        
        nAdded = 0;
        
        % Make patches:
        for j = 1:size(xRange,2)
            for i = 1:size(xRange,1)
                if ~isnan(d(i,j)) ||  ~isnan(m(i,j))

                    nAdded = nAdded + 1;

                    X(1,nAdded) = xPos(j) - dx(j)/2;
                    X(2,nAdded) = xPos(j) - dx(j)/2;
                    X(3,nAdded) = xPos(j) + dx(j)/2;
                    X(4,nAdded) = xPos(j) + dx(j)/2;

                    Y(1,nAdded) = xRange(i,j) - dy(i,j)/2;
                    Y(2,nAdded) = xRange(i,j) + dy(i,j)/2;
                    Y(3,nAdded) = xRange(i,j) + dy(i,j)/2;
                    Y(4,nAdded) = xRange(i,j) - dy(i,j)/2;      
                    
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
        
        
        lFlagged = lFlagged(1:nAdded);
        ID = ID(1:nAdded);
   
        switch lower(sDataCodeLookupTable{ st.Cmps(iCmp).Cmp,2})

            case 'amplitude'

                if lShowData
                    
                    C = log10(abs(d(lUse)));
                   
                    axes(hAmpD);
                    patch(X(:,~lFlagged),Y(:,~lFlagged),C(~lFlagged));
                    title('Data log10(Amplitude)')
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
                    axes(hAmpM);
                    
                    patch(X(:,~lFlagged),Y(:,~lFlagged),C(~lFlagged));
                     
                    title('Model log10(Amplitude)')
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
                    axes(hAmpR);
                    
                    patch(X(:,~lFlagged),Y(:,~lFlagged),C(~lFlagged)); 
                    
                    title('Amplitude Residual')
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

                if lShowData

                    d = sub_unwrapPhaseWithRange(xRange,d,st.stCSEM.phaseConvention);
                    C = d(lUse);
                    axes(hPhsD);
                    patch(X(:,~lFlagged),Y(:,~lFlagged),C(~lFlagged)); 
                    title('Data Phase')
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
                    m = sub_unwrapPhaseWithRange(xRange,m,st.stCSEM.phaseConvention);  
                    C = m(lUse);
                    axes(hPhsM);
                    patch(X(:,~lFlagged),Y(:,~lFlagged),C(~lFlagged)); 
                    title('Model Phase') 
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
                    axes(hPhsR);
                    patch(X(:,~lFlagged),Y(:,~lFlagged),C(~lFlagged)); 
                    title('Phase Residual')
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


% Link axis color scales:
 
linkprop([hAmpD hAmpM],'clim');
linkprop([hPhsD hPhsM],'clim');

% Update the RMS display, if data and model responses present for current
% file:
updateRMS(handles);

set(handles.hAxes,'visible','on')
linkaxes(handles.hAxes,'x')

end 


%--------------------------------------------------------------------------
function  p = sub_unwrapPhaseWithRange(r,p,sPhaseConvention,varargin)

ptol = 25;
if strcmpi(sPhaseConvention,'lag')
    p(p<-ptol) = p(p<-ptol) + 360;
else
    p(p>ptol) = p(p>ptol) - 360;
end
 
 
for iCol = 1:size(p,2)
    

    ineg = r(:,iCol) < 0;

    if any(ineg);
        [rn, isort] = sort(abs(r(ineg,iCol)));
        pn = p(ineg,iCol);
        pn = pn(isort);
        pn = 180/pi*unwrap(pn*pi/180);

        pref = [];
        if nargin ==4
            pref = varargin{1};
        end

        if ~isempty(pref)
            pref = pref(ineg);
            pref = pref(isort);

            % DGM 2/12/2013 - phase wrapping when trying to match resp to data is
            % not working. Replaced with this.
            dNow    = abs( pn - pref );
            dUp     = abs( (pn + 360) - pref );
            dDown   = abs( (pn - 360) - pref );

            iMoveUp = (dUp < dNow);
            iMoveDn = (dDown < dNow);
            pn(iMoveUp) = pn(iMoveUp) + 360;
            pn(iMoveDn) = pn(iMoveDn) - 360;
            % Below doesn't work
            %         r0 = sum(abs(pref-pn));
            %         rp = sum(abs(pref-(pn+360)));
            %         rm = sum(abs(pref-(pn-360)));
            %         if rp < r0 & rm < r0
            %             if rp < rm
            %                 pn = pn + 360;
            %             else
            %                 pn = pn - 360;
            %             end
            %         elseif rp < r0
            %             pn = pn + 360;
            %         elseif rm < r0
            %             pn = pn - 360;
            %         end
        end
        ii = find(ineg);
        p(ii(isort),iCol) = pn;

    end

    ipos = r(:,iCol)>=0;
    if any(ipos)
        [rn isort] = sort(abs(r(ipos,iCol)));
        pn = p(ipos,iCol);
        pn = pn(isort);
        pn = 180/pi*unwrap(pn*pi/180);

        pref = [];
        if nargin ==4
            pref = varargin{1};
        end

        if ~isempty(pref)
            pref = pref(ipos);
            pref = pref(isort);

            % DGM 2/12/2013 - phase wrapping when trying to match resp to data is
            % not working. Replaced with this.
            dNow    = abs( pn - pref );
            dUp     = abs( (pn + 360) - pref );
            dDown   = abs( (pn - 360) - pref );

            iMoveUp = (dUp < dNow);
            iMoveDn = (dDown < dNow);
            pn(iMoveUp) = pn(iMoveUp) + 360;
            pn(iMoveDn) = pn(iMoveDn) - 360;
            % Below doesn't work
            %         r0 = sum(abs(pref-pn));
            %         rp = sum(abs(pref-(pn+360)));
            %         rm = sum(abs(pref-(pn-360)));
            %         if rp < r0 & rm < r0
            %             if rp < rm
            %                 pn = pn + 360;
            %             else
            %                 pn = pn - 360;
            %             end
            %         elseif rp < r0
            %             pn = pn + 360;
            %         elseif rm < r0
            %             pn = pn - 360;
            %         end
        end

        ii = find(ipos);
        p(ii(isort),iCol) = pn;

    end

end
% ptol = 0;
% if strcmpi(sPhaseConvention,'lag')
%     p(p<-ptol) = p(p<-ptol) + 360;
% else
%     p(p>ptol) = p(p>ptol) - 360;
% end
end


%--------------------------------------------------------------------------
function  st = convertRealImagToAmpPhs(st)

pairs = [ 1 2; 3 4; 5 6; 11 12; 13 14; 15 16];

amph = pairs+20;

for ip = 1:length(pairs)
    
%Type        Freq#          Tx#          Rx#          Data      StdError      Response      Residual
    codes = pairs(ip,:);
    i1 = st.DATA(:,1) == codes(1);
    i2 = st.DATA(:,1) == codes(2);
    
    if any(i1)  
        i1 = find(i1);
        i2 = find(i2);
        for i = 1:length(i1)
            ind = st.DATA(i1(i),2:4);
            imatch = find( st.DATA(i2,2) == ind(1) & st.DATA(i2,3) == ind(2) &st.DATA(i2,4) == ind(3));
            
            % Data:
            rd = st.DATA(i1(i),5);
            id = st.DATA(i2(imatch),5);
            re = st.DATA(i1(i),6);
            ie = st.DATA(i2(imatch),6);
            
            amp = sqrt(rd^2 + id^2);
            phs = atan2(id,rd)*180/pi;

            
            st.DATA(i1(i),5)      = amp;
            st.DATA(i2(imatch),5) = phs;
            
            % assume real and imaginary data have equal error bars based on
            % amplitude, so then:
            amp_se = re;
            phs_se = amp_se/amp*180/pi;
            
            st.DATA(i1(i),6)      = amp_se;
            st.DATA(i2(imatch),6) = phs_se;
            
            % data codes:
            st.DATA(i1(i),1) = amph(ip,1);
            st.DATA(i2(imatch),1) = amph(ip,2);
            
            if length(st.DATA(i1(i),:)) == 8
                
                % Response:
                rd = st.DATA(i1(i),7);
                id = st.DATA(i2(imatch),7);
                amp = sqrt(rd^2 + id^2);
                phs = atan2(id,rd)*180/pi;
                st.DATA(i1(i),7)      = amp;
                st.DATA(i2(imatch),7) = phs;
                
            end
           
            
        end
        
      
    elseif any(i2)  % imaginary data only? convert to amplitude for plotting...this is DualEM data
    
        st.DATA(i2,5) = abs(st.DATA(i2,5));
        
        st.DATA(i2,1) = amph(ip,1);
          
            
        if length(st.DATA(1,:)) == 8
            st.DATA(i2,7) = abs(st.DATA(i2,7));
        end

    end
end
end

%--------------------------------------------------------------------------
function   st = convertlog10AmpToAmp(st)

codes = [ 27 28 29 37 38 39];

newcodes = [ 21 23 25 31 33 35 ] ;

i2 = st.DATA(:,5)~= 0 & st.DATA(:,6)~=0 ; % if both data and uncertainty are 0, then this is dummy data for generating fwd responses

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
        
        st.bWaslog10  = true;
        
    end
end



end


%--------------------------------------------------------------------------
function   st = convertAmpTolog10Amp(st)

codes = [ 21 23 25 31 33 35 ] ;

newcodes = [ 27 28 29 37 38 39]; 

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
        
        % onvert model response too
        if size(st.DATA,2) == 8
            st.DATA(iMod,7)      = log10(st.DATA(iMod,7));
        end
        % Change all codes:
        st.DATA(i1,1) = newcodes(ip);
    end
end
 

end


%--------------------------------------------------------------------------
function sComponents = sub_getDataComponents(handles)

iCodes = [];
for iFile = 1:length(handles.st)
    iCodes =[iCodes; handles.st(iFile).DATA(:,1)];
end
iCodes = unique(iCodes);

sComponents = {};
sDataCodeLookupTable = m2d_getDataCodeLookupTable();
for i = 1:length(iCodes)
    iCode = iCodes(i);
    if iCode < 101 % skip MT data
        sComponents{end+1} = sDataCodeLookupTable{iCode,1}   ;
    else
      %  fprintf('Not coded for this data type, ignoring it for now: %i\n',iCodes(i));
    end
end

sComponents = unique(sComponents);
end

%--------------------------------------------------------------------------
% --- Executes on button press in showResiduals.
function showResiduals_Callback(~, ~, ~)
% hObject    handle to showResiduals (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)

% Hint: get(hObject,'Value') returns toggle state of showResiduals
end

%--------------------------------------------------------------------------
% --- Executes on button press in plotType_Callback.
function handles = plotType_Callback(hObject, eventdata, handles)


set( handles.figure1, 'Pointer', 'watch' );
drawnow;

h = findobj(handles.figure1,'tag','plotType');
str = get(h,'String');
val = get(h,'Value');

plotType =str{val};

switch lower(plotType)
    case {'response lines' 'uncertainty %'}
        
        handles = sub_setShowButtons(handles,'on');
        
        set(handles.frequencyListbox,'enable','on');
        set(handles.componentsListbox,'enable','on');
        set(handles.gatherMenu,'enable','on');
        
        % turn on multiselect again:
        set(handles.fileListbox,'max',2,'listboxtop',1);
        set(handles.frequencyListbox,'max',2,'listboxtop',1);
        set(handles.componentsListbox,'max',2,'listboxtop',1);
        set(handles.xaxisMenu,'enable','on');
        set(handles.receiverListbox,'enable','on');
        set(handles.transmitterListbox,'enable','on');
        
        
        handles = plot_Callback(hObject, eventdata, handles);
        
        
    case { 'response matrix: position versus range','response matrix: receivers versus transmitters'}
        
        handles = sub_setShowButtons(handles,'on');

        set(handles.gatherMenu,'enable','on'); % leave this on since useful for Tx vs Rx gather for dealing with reciprocity
        set(handles.componentsListbox,'enable','on');
        set(handles.frequencyListbox,'enable','on');
        
        iFiles = get(handles.fileListbox,'value');
        set(handles.fileListbox,'max',1,'listboxtop',1,'value',iFiles(1));
        
        iFreqs = get(handles.frequencyListbox,'value');
        set(handles.frequencyListbox,'max',1,'listboxtop',1,'value',iFreqs(1));
        
        iComps = get(handles.componentsListbox,'value');
        set(handles.componentsListbox,'max',1,'listboxtop',1,'value',iComps(1));
        
        set(handles.xaxisMenu,'enable','on'); % leave on for selecting between Y and Z ranges
        set(handles.receiverListbox,'enable','off');
        set(handles.transmitterListbox,'enable','off');
        
        %handles = plotMatrix_Callback(hObject, eventdata, handles);
        handles = plot_Callback(hObject, eventdata, handles);
        
    case 'misfit breakdown'
        
        handles = sub_setShowButtons(handles,'off');
 
        
        set(handles.gatherMenu,'enable','off');
        set(handles.componentsListbox,'enable','off');
        set(handles.xaxisMenu,'enable','off');
        set(handles.frequencyListbox,'enable','off');
        set(handles.receiverListbox,'enable','off');
        set(handles.transmitterListbox,'enable','off');

        % do it:
        handles = sub_plotMisfitBreakDown(hObject,handles);

end

% Update the RMS display, if data and model responses present for current
% file:
updateRMS(handles);

set( handles.figure1, 'Pointer', 'arrow' );
drawnow;
end

%--------------------------------------------------------------------------
function resize_Callback(hObject, ~, handles)
%R2015b
 

% Resize tool panel:
figPos  = handles.figure1.Position;
toolPos = handles.UIpanel.Position;

handles.UIpanel.Position = [toolPos(1) figPos(4)-toolPos(4) toolPos(3:4)];
 
% Get plot type to handle special cases:
h = findobj(handles.figure1,'tag','plotType');
str = get(h,'String');
val = get(h,'Value');
plotType =str{val};
    
% Update the axes positions too:
if isfield(handles,'st') && ~isempty(handles.st) 
    nAxes = length(handles.hAxes);
   
    if nAxes == 2
        m = 2;
        n = 1;
    elseif nAxes == 4
        m = 2;
        n = 2;
    elseif nAxes == 6
        m = 3;
        n = 2;
    end
       
    % need special case here for misfit breakdown...
 
    
    lMisfit = false;
    switch lower(plotType)
        case {'response lines' 'uncertainty %'}
            lColorbar = false;

        case 'misfit breakdown'
            lColorbar = false;
            lMisfit = true;
            
        case {'response matrix: receivers versus transmitters', 'response matrix: position versus range' }
            lColorbar = true;

        otherwise
            beep;
            disp('case not yet defined in resize_Callback()')

    end
    
    if ~lMisfit
    
        [posX,posY,widX,widY]= getRowColPositions(handles,m,n,lColorbar);

        ict = 0;
        % move through hAxes which is by column:
        for j = 1:n
            for i = 1:m
                ict = ict + 1;
               % set(handles.hAxes(ict),'ActivePositionProperty','position')
                handles.hAxes(ict).Position = [ posX(j) posY(m+1-i) widX(j) widY(m+1-i)];
            end
        end
    else
        
        [posX,posY,widX,widY]= getRowColPositions(handles,3,1,lColorbar);
        handles.hAxes(1).Position = [ posX(1) posY(3) widX(1) widY(3)];
        handles.hAxes(2).Position = [ posX(1) posY(2) widX(1) widY(2)];
        [posX,posY,widX,widY]= getRowColPositions(handles,3,2,lColorbar);
        handles.hAxes(3).Position = [ posX(1) posY(1) widX(1) widY(1)];
        handles.hAxes(4).Position = [ posX(2) posY(1) widX(2) widY(1)];
        
    end
    
    
    
end

 

end
