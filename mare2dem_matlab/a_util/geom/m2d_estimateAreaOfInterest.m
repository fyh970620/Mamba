%--------------------------------------------------------------------------
function [ylim,zlim] = m2d_estimateAreaOfInterest(st)
    
    [ylim,zlim] = deal([]);
    survey = [];
    if isfield(st,'stCSEM') && ~isempty(st.stCSEM) && isfield(st.stCSEM,'receivers')
        survey = [survey; st.stCSEM.receivers(:,2:3)];
        survey = [survey; st.stCSEM.transmitters(:,2:3)];
    end
    if isfield(st,'stMT') && ~isempty(st.stMT)
        survey = [survey; st.stMT.receivers(:,2:3)];
    end
    if isfield(st,'stDC') && ~isempty(st.stDC)
        survey = [survey; st.stDC.tx_electrodes(:,2:3)];
        survey = [survey; st.stDC.rx_electrodes(:,2:3)];
    end    
  
        
    if ~isempty(survey)

        % Rx and Tx extent:
        ymin = min(survey(:,1));
        ymax = max(survey(:,1));
        zmin = min(survey(:,2));
        zmax = max(survey(:,2));
        dy = ymax - ymin;
        dz = zmax - zmin;
        
        [ymin_free,ymax_free,zmin_free,zmax_free ] = deal([]);
         
        if isfield(st,'nodes')  % when Mamba2D calls this there is no mesh in st (but there is when called from plotMARE2DEM)...
                
            % get extent of free parameters too:
            lFree    = all(st.freeparameter(st.TriIndex,:) > 0, 2);

            if ~isempty(lFree)
                Tris     = st.TR.ConnectivityList(lFree,:);
                TriIndex = st.TriIndex(lFree);
                verts = unique(Tris(:));   

                points = st.TR.Points(verts,:);

                ymin_free = min(points(:,1));
                ymax_free = max(points(:,1));
                zmin_free = min(points(:,2));
                zmax_free = max(points(:,2));        

            end

        end
        
        % Now decide what to do:

        % Check for single Rx location:
        if dy ==0 && dz ==0  % single site, make a 2 x 2 km rectangle centered on station

            ylim = [ymin-1000 ymin+1000];
            zlim = [zmin-1000 zmin+1000];

            if ~isempty(zmin_free)  % if inversion model, show the whole shebang
                ylim = [ymin_free ymax_free]; 
                zlim = [zmin_free zmax_free];
            end
        else

            % If dy >> dz, assume this is an MT or CSEM profile:  

            if dy > 2*dz

                ylim = [ymin-dy/10 ymax+dy/10];  % 10% buffer on left and right sides.
                zlim = [zmin-dy/10 zmax + dy*3/4]; % zmax is 75% survey width


            % If no MT data and CSEM data present, make max depth max Rx-Tx
            % offset:
                if isfield(st,'DATA') && isempty(st.stMT) && ~isempty(st.stCSEM) && isfield(st.stCSEM,'receivers')

                   lCSEM = st.DATA(:,1) < 100;
                   iTx = st.DATA(lCSEM,3);
                   iRx = st.DATA(lCSEM,4);

                   r = max(abs(st.stCSEM.receivers(iRx,2)-st.stCSEM.transmitters(iTx,2)));

                   zlim(1) = zmin-r/10;
                   zlim(2) = zmax+r;  % note this would be too small for coincient loop or zero offset TDEM soundings...

                end


                % Now check for inversion parameters above the receivers, which
                % could imply a crosswell model. If so, adjust minimum depth so
                % depth range is symmetrix about zmin and zmax:
                if ~isempty(zmin_free) && zmin_free < zlim(1)
                    zlim = [zmin - dy/4 zmax+dy/4];
                end



            else  % just make a square around everything:

                dr = max([dy dz]);

                if dy > dz

                    ylim = [ymin-dr/10 ymax+dr/10];  % so width is dy2 = dy+2*dr/10

                    dd = dy-dz;
                    zlim = [zmin-dd/2-dr/10 zmax+dd/2+dr/10 ];    % height is then dz = dy2 = dy+2/dr/10

                else

                    zlim = [zmin-dr/10 zmax+dr/10];  %  height is dy2 = dy+2*dr/10

                    dd = dz-dy;
                    ylim = [ymin-dd/2-dr/10 ymax+dd/2+dr/10 ];    % width is then dz = dy2 = dy+2/dr/10
                end

            end
        end

    else
        if isfield(st,'nodes')
            ylim = [min(st.nodes(:,1)) max(st.nodes(:,1))];
            zlim = [min(st.nodes(:,2)) max(st.nodes(:,2))];
        end
    end
     
end