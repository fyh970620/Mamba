function plotMARE2DEM_SurveyLayout(sType,st)



% Read in data file if not present:

if ~exist('st','var') || isempty(st)
 
    % Select the file(s):
    [sFile,sFilePath]  = uigetfile( {'*.data;*.resp;*.emdata;'}, 'Select a MARE2DEM data or response file:' ,'MultiSelect', 'off');
    if isnumeric(sFile) && sFile ==0
        disp('No file selected for plotting, returning...')
        return
    end

    st.dataFile = fullfile(sFilePath,sFile);
    
    st   = m2d_readEMData2DFile(st.dataFile);
    
end

    % Magic numbers used here:
    fontSize = 16;
    lineWidth = 1;

    nSizeMax = [1800 1200];

    [nMon] = m2d_getMonitorPosition();

    nSize(1) = min([nMon(1,3),nSizeMax(1)]);
    nSize(2) = min([nMon(1,4),nSizeMax(2)]);

    hMap =   m2d_newFigure(nSize);

    set(gca,'fontsize',fontSize);

    
    switch lower(sType)
        case 'map'
            plotMARE2DEM_SurveyMap(st);
        case 'rx'
            plotRxParams(st);
        case 'tx'
            plotTxParams(st);
    end


    function plotMARE2DEM_SurveyMap(st)



    % We want a map in UTM coordinates with the survey line plotted at the
    % correct angle:
    n0 = st.stUTM.north0;
    e0 = st.stUTM.east0;
    theta = st.stUTM.theta; % direction for 2D conductivity strike x, model is along y, so add 90º for survey line direction
    c = cosd(theta);
    s = sind(theta);
    R = [c -s; s c];

    hRx = [];
    hTx = [];
    hMT = [];
    hobs = [];
    legstr =[];

    lMT = false;
    lCSEM = false;

    % CSEM receivers:
    if ~isempty(st.stCSEM) && isfield(st.stCSEM,'receivers')

        lCSEM = true;

        Rx = R*st.stCSEM.receivers(:,1:2)';
        Rx(1,:) = Rx(1,:) + n0;
        Rx(2,:) = Rx(2,:) + e0;
        hRx = plot(Rx(2,:)/1d3,Rx(1,:)/1d3,'.','tag','csem');
        hold on;
        hobs = [hobs; hRx(1)];
        legstr{end+1} = 'CSEM Receivers';

        % CSEM transmitters:
        Tx = R* st.stCSEM.transmitters(:,1:2)';

        Tx(1,:) = Tx(1,:) + n0;
        Tx(2,:) = Tx(2,:) + e0;
        hTx = plot(Tx(2,:)/1d3,Tx(1,:)/1d3,'.','tag','tx');
        hold on;
        hobs = [hobs; hTx(1)];
        legstr{end+1} = 'Transmitters';
    end


    % MT receivers:
    if ~isempty(st.stMT) && isfield(st.stMT,'receivers')

        lMT = true;

        Rx = R* st.stMT.receivers(:,1:2)';
        Rx(1,:) = Rx(1,:) + n0;
        Rx(2,:) = Rx(2,:) + e0;
        hMT = plot(Rx(2,:)/1d3,Rx(1,:)/1d3,'.','tag','mt');
        hold on;
        hobs = [hobs; hMT(1)];
        legstr{end+1} = 'MT receivers';


    end

    ax = axis;

    if isfield(st,'nodes')

    % Plot a line for the 2D model:
        ymin = min(st.nodes(:,1));
        ymax = max(st.nodes(:,1));
        nLine = R(1,2)*[ymin ymax] + n0;
        eLine = R(2,2)*[ymin ymax] + e0;
        hModel = plot(eLine/1d3,nLine/1d3,'k-','linewidth',lineWidth);
        hobs = [hobs; hModel];
        legstr{end+1} = '2D Model';
        axis(ax);
    end

    % Appearance adjustments:
    axis equal;
    grid on;
    title(st.dataFile,'interpreter','none')
    legend(hobs,legstr);
    ylabel('Northing (km)')
    xlabel('Easting (km)');
    set(findobj(hMap,'type','axes')   ,'fontsize',fontSize);


    set(findobj( hMap,'tag','tx'),'marker','x','color','r','markerfacecolor','none','markersize',8);
    if lMT && lCSEM
       set(findobj( hMap,'tag','csem'),'marker','o','color','b','markerfacecolor','b','markersize',4);
       set(findobj( hMap,'tag','mt'),'marker','o','color','g','markerfacecolor','g','markersize',8);
    else
       set(findobj( hMap,'tag','csem'),'marker','o','color','b','markerfacecolor','b','markersize',6);
       set(findobj( hMap,'tag','mt'),'marker','o','color','b','markerfacecolor','b','markersize',6);
    end


    end


    %--------------------------------------------------------------------------
    function plotTxParams(st)

    if ~isfield(st.stCSEM,'transmitters')
       return; 
    end

    % Magic numbers used here:
    fontSize = 16;
    lineWidth = 1;
    markerSize = 6;
 
    hobs = [];
    legstr =[];


    % CSEM transmitters:


    subplot(5,1,1); 
    hCSEM = plot(st.stCSEM.transmitters(:,2)/1d3,st.stCSEM.transmitters(:,1)/1d3,'bo','markersize',markerSize,'markerfacecolor','b');
    hold on;
    subplot(5,1,2); 
    hCSEM = plot(st.stCSEM.transmitters(:,2)/1d3,st.stCSEM.transmitters(:,2)/1d3,'bo','markersize',markerSize,'markerfacecolor','b');
    hold on;
    subplot(5,1,3); 
    hCSEM = plot(st.stCSEM.transmitters(:,2)/1d3,st.stCSEM.transmitters(:,3)/1d3,'bo','markersize',markerSize,'markerfacecolor','b');
    hold on;
    subplot(5,1,4); 
    ang = st.stCSEM.transmitters(:,4);
    mA = mean(ang);
    ang(ang > mA+180) = ang(ang > mA+180)-360;
    ang(ang < mA-180) = ang(ang < mA-180)+360;
    %ang(ang>180) = ang(ang>180)-360;
    hCSEM = plot(st.stCSEM.transmitters(:,2)/1d3,ang,'bo','markersize',markerSize,'markerfacecolor','b');
    hold on;
    subplot(5,1,5); 
    ang = st.stCSEM.transmitters(:,5);
    %ang(ang>180) = ang(ang>180)-360;
    mA = mean(ang);
    ang(ang > mA+180) = ang(ang > mA+180)-360;
    ang(ang < mA-180) = ang(ang < mA-180)+360;
    hCSEM = plot(st.stCSEM.transmitters(:,2)/1d3,ang,'bo','markersize',markerSize,'markerfacecolor','b');
    hold on;




    subplot(5,1,1);
    ylabel('x (km)')
    title(sprintf('Transmitter Parameters:  %s',st.dataFile),'interpreter','none')
    subplot(5,1,2);
    ylabel('y (km)')
    subplot(5,1,3);
    ylabel('z (km)')
    set(gca,'ydir','rev')
    subplot(5,1,4);
    ylabel('azimuth (deg)')
    subplot(5,1,5);
    ylabel('dip (deg)')


    xlabel('Transmitter y position (km)')


    set(findobj(hMap,'type','axes')   ,'fontsize',fontSize);

    end

    %--------------------------------------------------------------------------
    function plotRxParams(st)

    if ~isfield(st.stCSEM,'receivers') && ~isfield(st.stMT,'receivers')
       return; 
    end

    % Magic numbers used here:
    markerSize = [4 8];
 
    hobs = [];
    legstr =[];


    lMT = false;
    lCSEM = false;

    % CSEM receivers:
    if ~isempty(st.stCSEM) && isfield(st.stCSEM,'receivers') && ~isempty(st.stCSEM.receivers)


        subplot(6,1,1); 
        hCSEM = plot(st.stCSEM.receivers(:,2)/1d3,st.stCSEM.receivers(:,1)/1d3,'.','tag','csem');
        hold on;
        subplot(6,1,2);  
        hCSEM = plot(st.stCSEM.receivers(:,2)/1d3,st.stCSEM.receivers(:,2)/1d3,'.','tag','csem');
        hold on;
        subplot(6,1,3); 
        hCSEM = plot(st.stCSEM.receivers(:,2)/1d3,st.stCSEM.receivers(:,3)/1d3,'.','tag','csem');
        hold on;
        subplot(6,1,4); 
        ang = st.stCSEM.receivers(:,4);
        %ang(ang>180) = ang(ang>180)-360;
        mA = mean(ang);
        ang(ang > mA+180) = ang(ang > mA+180)-360;
        ang(ang < mA-180) = ang(ang < mA-180)+360;
        hCSEM = plot(st.stCSEM.receivers(:,2)/1d3,ang,'.','tag','csem');
        hold on;
        subplot(6,1,5); 
        ang = st.stCSEM.receivers(:,5);
        %ang(ang>180) = ang(ang>180)-360;
        mA = mean(ang);
        ang(ang > mA+180) = ang(ang > mA+180)-360;
        ang(ang < mA-180) = ang(ang < mA-180)+360;
        hCSEM = plot(st.stCSEM.receivers(:,2)/1d3,ang,'.','tag','csem');
        hold on;
        subplot(6,1,6); 
        ang = st.stCSEM.receivers(:,6);
        %ang(ang>180) = ang(ang>180)-360;
        mA = mean(ang);
        ang(ang > mA+180) = ang(ang > mA+180)-360;
        ang(ang < mA-180) = ang(ang < mA-180)+360;
        hCSEM = plot(st.stCSEM.receivers(:,2)/1d3,ang,'.','tag','csem');
        hold on;
        hobs = [hobs; hCSEM(1)];
        legstr{end+1} = 'CSEM receivers';

        lCSEM = true;
    end


    % MT receivers:
    if  ~isempty(st.stMT) && isfield(st.stMT,'receivers') && ~isempty(st.stMT.receivers)

        subplot(6,1,1); 
        hMT = plot(st.stMT.receivers(:,2)/1d3,st.stMT.receivers(:,1)/1d3,'.','tag','mt');
        hold on;
        subplot(6,1,2); 
        hMT = plot(st.stMT.receivers(:,2)/1d3,st.stMT.receivers(:,2)/1d3,'.','tag','mt');
        hold on;
        subplot(6,1,3); 
        hMT = plot(st.stMT.receivers(:,2)/1d3,st.stMT.receivers(:,3)/1d3,'.','tag','mt');
        hold on;
        subplot(6,1,4); 
        ang = st.stMT.receivers(:,4);
        ang(ang>180) = ang(ang>180)-360;
        hMT = plot(st.stMT.receivers(:,2)/1d3,ang,'.','tag','mt');
        hold on;
        subplot(6,1,5); 
        ang = st.stMT.receivers(:,5);
        ang(ang>180) = ang(ang>180)-360;
        hMT = plot(st.stMT.receivers(:,2)/1d3,ang,'.','tag','mt');
        hold on;
        subplot(6,1,6); 
        ang = st.stMT.receivers(:,6);
        ang(ang>180) = ang(ang>180)-360;
        hMT = plot(st.stMT.receivers(:,2)/1d3,ang,'.','tag','mt');
        hold on;
        hobs = [hobs; hMT(1)];
        legstr{end+1} = 'MT receivers';

        lMT = true;
    end

    subplot(6,1,1);
    ylabel('x (km)')
    title(sprintf('Receiver Parameters: %s',st.dataFile),'interpreter','none')
    subplot(6,1,2);
    ylabel('y (km)')
    subplot(6,1,3);
    ylabel('z (km)')
    set(gca,'ydir','rev')
    subplot(6,1,4);
    ylabel('theta (deg)')
    subplot(6,1,5);
    ylabel('alpha (deg)')
    subplot(6,1,6);
    ylabel('beta (deg)')
    xlabel('Receiver y Position (km)')
    subplot(6,1,6);
    legend(hobs,legstr);
    set(findobj(hMap,'type','axes')   ,'fontsize',fontSize);

    if lMT && lCSEM
       set(findobj( hMap,'tag','csem'),'marker','o','color','b','markerfacecolor','b','markersize',4);
       set(findobj( hMap,'tag','mt'),'marker','o','color','r','markerfacecolor','none','markersize',8);
    else
       set(findobj( hMap,'tag','csem'),'marker','o','color','b','markerfacecolor','b','markersize',4);
       set(findobj( hMap,'tag','mt'),'marker','o','color','b','markerfacecolor','b','markersize',4);
    end

    end

end

 
