function varargout = pickPointsFromSEGY(varargin)
%PICKPOINTSFROMSEGY M-file for pickPointsFromSEGY.fig
%      PICKPOINTSFROMSEGY, by itself, creates a new PICKPOINTSFROMSEGY or raises the existing
%      singleton*.
%
%      H = PICKPOINTSFROMSEGY returns the handle to a new PICKPOINTSFROMSEGY or the handle to
%      the existing singleton*.
%
%      PICKPOINTSFROMSEGY('Property','Value',...) creates a new PICKPOINTSFROMSEGY using the
%      given property value pairs. Unrecognized properties are passed via
%      varargin to pickPointsFromSEGY_OpeningFcn.  This calling syntax produces a
%      warning when there is an existing singleton*.
%
%      PICKPOINTSFROMSEGY('CALLBACK') and PICKPOINTSFROMSEGY('CALLBACK',hObject,...) call the
%      local function named CALLBACK in PICKPOINTSFROMSEGY.M with the given input
%      arguments.
%
%      *See GUI Options on GUIDE's Tools menu.  Choose "GUI allows only one
%      instance to run (singleton)".
%
% See also: GUIDE, GUIDATA, GUIHANDLES

% Edit the above text to modify the response to help pickPointsFromSEGY

% Last Modified by GUIDE v2.5 29-Aug-2013 13:55:45

% Begin initialization code - DO NOT EDIT
gui_Singleton = 0;
gui_State = struct('gui_Name',       mfilename, ...
                   'gui_Singleton',  gui_Singleton, ...
                   'gui_OpeningFcn', @pickPointsFromSEGY_OpeningFcn, ...
                   'gui_OutputFcn',  @pickPointsFromSEGY_OutputFcn, ...
                   'gui_LayoutFcn',  [], ...
                   'gui_Callback',   []);
if nargin && ischar(varargin{1})
   gui_State.gui_Callback = str2func(varargin{1});
end

if nargout
    [varargout{1:nargout}] = gui_mainfcn(gui_State, varargin{:});
else
    gui_mainfcn(gui_State, varargin{:});
end
% End initialization code - DO NOT EDIT


% --- Executes just before pickPointsFromSEGY is made visible.
function pickPointsFromSEGY_OpeningFcn(hObject, ~, handles, varargin)
% This function has no output args, see OutputFcn.
% hObject    handle to figure
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)
% varargin   unrecognized PropertyName/PropertyValue pairs from the
%            command line (see VARARGIN)

% Choose default command line output for pickPointsFromSEGY
handles.output = hObject;
handles.points = [];

% Update handles structure
guidata(hObject, handles);

% UIWAIT makes pickPointsFromSEGY wait for user response (see UIRESUME)
% uiwait(handles.figure1);


% --- Outputs from this function are returned to the command line.
function varargout = pickPointsFromSEGY_OutputFcn(~, ~, handles)
% varargout  cell array for returning output args (see VARARGOUT);
% hObject    handle to figure
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)

% Get default command line output from handles structure
varargout{1} = handles.output;


% --- Executes on button press in selectDataFile.
function selectDataFile_Callback(hObject, ~, handles)
% hObject    handle to selectDataFile (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)



% Select a MARE2DEM data file:
[sFile,sFilePath]  = uigetfile( {'*.data;*.resp;*.emdata;'}, 'Select a MARE2DEM data or response file:' ,'MultiSelect', 'off');
if isnumeric(sFile) && sFile ==0
    disp('No files selected for plotting, returning...')
    return
end
set(handles.dataFileName,'string',sFile)
 
%    
% Read in the file:
%
[stUTM stCSEM stMT stDATA]   = readEMData2DFile(fullfile(sFilePath,sFile));
 
%
% Add receivers to plot:
%
delete(findobj(hObject,'tag','rx'));
delete(findobj(hObject,'tag','tx'));

if ~isempty(stCSEM)
    
    axes(handles.axes1);
    
    hRx = plot(stCSEM.receivers(:,2)/1d3,stCSEM.receivers(:,3)/1d3,'kv',...
        'markersize',6,...
        'markerfacecolor','w',...
        'markeredgecolor','k',...
        'tag','rx');

     hTx = plot( stCSEM.transmitters(:,2)/1d3, stCSEM.transmitters(:,3)/1d3,'wo',...
        'tag','tx','markersize',5,'markerfacecolor','w','markeredgecolor','k');

    
    axes(handles.mapAxes);
    

    % Plot as UTM position

 
   
    n0 = stUTM.north0;
    e0 = stUTM.east0;
    theta = stUTM.theta; % direction for 2D conductivity strike x, model is along y, so add 90º for survey line direction
    c = cosd(theta);
    s = sind(theta);
    R = [c -s; s c];
 
        
    Rx = stCSEM.receivers(:,1:2)*R';

    Rx(:,1) = Rx(:,1) + n0;
    Rx(:,2) = Rx(:,2) + e0;

    hRx = plot(Rx(:,2)/1d3,Rx(:,1)/1d3,'kv',...  % (:,2) is receiver y and (:,1) is receiver x
    'markersize',6,...
    'markerfacecolor','w',...
    'markeredgecolor','k',...
    'tag','rx');     

    Tx = stCSEM.transmitters(:,1:2)*R';

    Tx(:,1) = Tx(:,1) + n0;
    Tx(:,2) = Tx(:,2) + e0;

     hTx = plot(Tx(:,2)/1d3, Tx(:,1)/1d3,'wo',...
        'tag','tx','markersize',5,'markerfacecolor','w','markeredgecolor','k');
    
    
end
if ~isempty(stMT)
    
    hRx = plot(stMT.receivers(:,2)/1d3,stMT.receivers(:,3)/1d3,'kv',...
    'markersize',8,...
    'markerfacecolor','w',...
    'markeredgecolor','k',...
    'tag','rx');

    axes(handles.mapAxes);
    
    n0 = stUTM.north0;
    e0 = stUTM.east0;
    theta = stUTM.theta; % direction for 2D conductivity strike x, model is along y, so add 90º for survey line direction
    c = cosd(theta);
    s = sind(theta);
    R = [c -s; s c];
 
        
    Rx = stMT.receivers(:,1:2)*R';

    Rx(:,1) = Rx(:,1) + n0;
    Rx(:,2) = Rx(:,2) + e0;

    hRx = plot(Rx(:,2)/1d3,Rx(:,1)/1d3,'kv',...
    'markersize',6,...
    'markerfacecolor','w',...
    'markeredgecolor','k',...
    'tag','rx');        
end

axes(handles.axes1);
set(gca,'fontsize',12')
xlabel('Position (km)')
ylabel('Depth (km)');

axes(handles.mapAxes);
axis equal;
set(gca,'fontsize',12')
ylabel('Northing (km)')
xlabel('Easting (km)');

handles.stUTM = stUTM;


%
% If data file loaded successfully, enable the select segy file button:
%
 set(handles.selectSegyFile,'enable','on');  
 

guidata(hObject,handles)
 
    
% --- Executes on button press in selectSegyFile.
function selectSegyFile_Callback(hObject, ~, handles)
% hObject    handle to selectSegyFile (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)

% Ask for the SEGY file:
[ff pp] = uigetfile('*.segy;*.sgy', 'Select  a Depth Migrated SEGY File (.segy,.sgy):');

if ff <= 0
    return
end
sFile  = fullfile(pp,ff);


% read in Segy file:
h = waitbar(.25,'Reading in segy file, please be patient...');
    
[Data,SegyTraceHeaders,SegyHeader]=ReadSegy(sFile);

set(handles.segyFileName,'string',ff)

delete(h)

% Bundle the required components into a structure:
handles.segy.Data = Data;
handles.segy.cdpX = [SegyTraceHeaders.cdpX];
handles.segy.cdpY = [SegyTraceHeaders.cdpY];
handles.segy.time = SegyHeader.time;

clear Data SegyTraceHeaders SegyHeader


%
% Plot it:
%
makeSegyPlot(handles)
axes(handles.axes1);
axis tight;

guidata(hObject,handles)
 

%--------------------------------------------------------------------------
function  makeSegyPlot(handles)

hsegy = findobj(gcf,'tag','segy');

if isempty(handles.segy.Data)
    return
end

delete(findobj(gcf,'tag','segy'))
     
axes(handles.axes1);
ax = axis;

zScale  = str2double(get(handles.depthConversion,'string'));
xyScale = str2double(get(handles.xyConversion,'string'));

 
col = handles.segy.Data;

% Project this onto the model axes:
% cdpX = east, cpdY = north
dn = ([handles.segy.cdpY]*xyScale - handles.stUTM.north0)/1d3;
de = ([handles.segy.cdpX]*xyScale - handles.stUTM.east0 )/1d3;
c = cosd(handles.stUTM.theta);
s = sind(handles.stUTM.theta);
R = [c s; -s c];
rotated = R*[dn; de];
x = rotated(1,:);
y = rotated(2,:);

z = [handles.segy.time]*zScale;


% add it to the MARE2DEM plot:
axes(handles.axes1)
hss = imagesc(y,z,col);

axis(ax);

anomalyColorMap;
colorbar;
 

set(hss,'tag','segy');
uistack(hss,'bottom');

% add segyy line to the map:

axes(handles.mapAxes);
delete(findobj(gcf,'tag','segyMap'))
plot([handles.segy.cdpX]*xyScale/1d3,[handles.segy.cdpY]*xyScale/1d3,'r-','tag','segyMap');     

axes(handles.axes1);
 
% --- Executes on button press in selectDataFile.
function depthConversion_Callback(hObject, ~, handles)
% hObject    handle to selectDataFile (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)
  makeSegyPlot(handles)
  axis tight;
 
% --- Executes during object creation, after setting all properties.
function depthConversion_CreateFcn(hObject, ~, ~)
% hObject    handle to depthConversion (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    empty - handles not created until after all CreateFcns called

% Hint: edit controls usually have a white background on Windows.
%       See ISPC and COMPUTER.
if ispc && isequal(get(hObject,'BackgroundColor'), get(0,'defaultUicontrolBackgroundColor'))
    set(hObject,'BackgroundColor','white');
end



function xyConversion_Callback(hObject, eventdata, handles)
% hObject    handle to xyConversion (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)

% Hints: get(hObject,'String') returns contents of xyConversion as text
%        str2double(get(hObject,'String')) returns contents of xyConversion as a double

% --- Executes during object creation, after setting all properties.
  makeSegyPlot(handles)
  axis tight;
 
  
function xyConversion_CreateFcn(hObject, ~, ~)
% hObject    handle to xyConversion (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    empty - handles not created until after all CreateFcns called

% Hint: edit controls usually have a white background on Windows.
%       See ISPC and COMPUTER.
if ispc && isequal(get(hObject,'BackgroundColor'), get(0,'defaultUicontrolBackgroundColor'))
    set(hObject,'BackgroundColor','white');
end


%--------------------------------------------------------------------------
function anomalyColorMap(~,~)
%
% Anomaly color map goes from red (-) to white (0) to blue (+)
% Useful for plotting variations from a reference model.
%
% Kerry Key
% Scripps Institution of Oceanography
%
% Dec 10, 2010.  Oh how we love the last work day before the AGU
% meeting...
%
%
colormap( flipud( ...
    [    0         0    1.0000
    0.0312    0.0312    1.0000
    0.0625    0.0625    1.0000
    0.0938    0.0938    1.0000
    0.1250    0.1250    1.0000
    0.1562    0.1562    1.0000
    0.1875    0.1875    1.0000
    0.2188    0.2188    1.0000
    0.2500    0.2500    1.0000
    0.2812    0.2812    1.0000
    0.3125    0.3125    1.0000
    0.3438    0.3438    1.0000
    0.3750    0.3750    1.0000
    0.4062    0.4062    1.0000
    0.4375    0.4375    1.0000
    0.4688    0.4688    1.0000
    0.5000    0.5000    1.0000
    0.5312    0.5312    1.0000
    0.5625    0.5625    1.0000
    0.5938    0.5938    1.0000
    0.6250    0.6250    1.0000
    0.6562    0.6562    1.0000
    0.6875    0.6875    1.0000
    0.7188    0.7188    1.0000
    0.7500    0.7500    1.0000
    0.7812    0.7812    1.0000
    0.8125    0.8125    1.0000
    0.8438    0.8438    1.0000
    0.8750    0.8750    1.0000
    0.9062    0.9062    1.0000
    0.9375    0.9375    1.0000
    0.9688    0.9688    1.0000
    1.0000    1.0000    1.0000
    0.9951    0.9729    0.9677
    0.9901    0.9459    0.9355
    0.9852    0.9188    0.9032
    0.9803    0.8917    0.8710
    0.9753    0.8646    0.8387
    0.9704    0.8376    0.8065
    0.9655    0.8105    0.7742
    0.9605    0.7834    0.7419
    0.9556    0.7564    0.7097
    0.9507    0.7293    0.6774
    0.9457    0.7022    0.6452
    0.9408    0.6751    0.6129
    0.9359    0.6481    0.5806
    0.9309    0.6210    0.5484
    0.9260    0.5939    0.5161
    0.9211    0.5669    0.4839
    0.9161    0.5398    0.4516
    0.9112    0.5127    0.4194
    0.9063    0.4856    0.3871
    0.9013    0.4586    0.3548
    0.8964    0.4315    0.3226
    0.8915    0.4044    0.2903
    0.8865    0.3774    0.2581
    0.8816    0.3503    0.2258
    0.8767    0.3232    0.1935
    0.8717    0.2961    0.1613
    0.8668    0.2691    0.1290
    0.8619    0.2420    0.0968
    0.8569    0.2149    0.0645
    0.8520    0.1879    0.0323
    0.8471    0.1608         0] ) );
 


% --- Executes on button press in savePoints.
function savePoints_Callback(hObject, eventdata, handles)
% hObject    handle to savePoints (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)




if isempty(handles.points) 
    return
end

%
%
% 

sFile = get(handles.outputFileName,'string');

points = handles.points(:,1:2);
points = points*1000; % convert from km to m

save(sFile,'points','-ascii');



function outputFileName_Callback(hObject, eventdata, handles)
% hObject    handle to outputFileName (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)

% Hints: get(hObject,'String') returns contents of outputFileName as text
%        str2double(get(hObject,'String')) returns contents of outputFileName as a double


% --- Executes during object creation, after setting all properties.
function outputFileName_CreateFcn(hObject, eventdata, handles)
% hObject    handle to outputFileName (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    empty - handles not created until after all CreateFcns called

% Hint: edit controls usually have a white background on Windows.
%       See ISPC and COMPUTER.
if ispc && isequal(get(hObject,'BackgroundColor'), get(0,'defaultUicontrolBackgroundColor'))
    set(hObject,'BackgroundColor','white');
end


% --- Executes on button press in deleteLast.
function deleteLast_Callback(hObject, eventdata, handles)
% hObject    handle to deleteLast (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)

hPoints = findobj(handles.figure1,'tag','points');

if isempty(hPoints) 
    return
end

delete(findobj(handles.figure1,'tag','pointsLine'));
delete(findobj(handles.figure1,'tag','points'));
handles.points = handles.points(1:end-1,:);
hPoint = plot(handles.points(:,1),handles.points(:,2),'.','color','k');
set(hPoint,'tag','points');
hLine = plot(handles.points(:,1),handles.points(:,2),'-','color','k');
set(hLine,'tag','pointsLine');  
 


guidata(hObject,handles);


% --- Executes on button press in pickThePoints.
function pickThePoints_Callback(hObject, eventdata, handles)
% hObject    handle to pickThePoints (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)

bgColor = get(hObject,'BackgroundColor');

set(hObject,'BackgroundColor','g');

selectedColor = 'g';
normalColor ='k';
lineColor ='k';

but = 1;
lastNode =[];

if  isempty(handles.points)
    selected = [];
else
    selected = size(handles.points(:,3),1);
    set(handles.points(selected,3),'color',selectedColor)
end

while but == 1
    
    [xi,yi, but] = getpoints(1,handles);
    
    if selected
        set(handles.points(selected,3),'color',normalColor);
        selected =[];
    end
    if but~=1
        break
    end
    
    ax = axis;
    if xi < ax(1) || xi > ax(2) || yi < ax(3) || yi > ax(4)
        break
    end
    
    hPoint = plot(xi,yi,'.','color',selectedColor);
    set(hPoint,'tag','points');

    handles.points(end+1,:) = [xi yi hPoint]; 
    
    delete(findobj(hObject,'tag','pointsLine'));
    hLine = plot(handles.points(:,1),handles.points(:,2),'-','color',lineColor);
    set(hLine,'tag','pointsLine');  
        
    selected = size(handles.points,1);
    
    guidata(hObject,handles);
    
end  % while loop
 
set(hObject,'BackgroundColor',bgColor);

%----------------------------------------------------------------------
function varargout = getpoints(N,handles)
% returns index of closest node
% handles
% x0,y0 location to find closest node to
%----------------------------------------------------------------------

k = waitforbuttonpress;
t = get(handles.axes1,'currentpoint');
x = t(1,1);
y = t(2,2);
k = get(gcf,'selectiontype');
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

% Make sure model axes is still the current axes:
axes (handles.axes1)
 
% --- Executes on button press in clearPoints.
function clearPoints_Callback(hObject, eventdata, handles)
% hObject    handle to clearPoints (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)

delete(findobj(handles.figure1,'tag','points'));
delete(findobj(handles.figure1,'tag','pointsLine'));
handles.points = [];

guidata(hObject,handles);
