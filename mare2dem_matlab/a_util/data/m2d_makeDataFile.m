function m2d_makeDataFile(sOutFile,topo,filetype,stIn)
%
% m2d_makeDataFile(sOutFile,topography,filetype,st) creates a MARE2DEM data
% file for forward or inverse modeling using an input topography profile,
% receiver and transmitter positions, and data settings. This routine will
% optionally set receiver and transmitter vertical positions and tilt
% angles. This is a high level routine designed to be called from user
% scripts or data management GUI's. See the MARE2DEM Examples folder for
% showing how to use this for various MT and CSEM configurations.
%
% Kerry Key
% Lamont-Doherty Earth Observatory, Columbia University
%
% Inputs:
% 
%   sOutFile   :: name of the output MARE2DEM data file to output. 
%                 (e.g. survey.emdata) 
%
%   topography :: single depth value or an array of [y,z] for the
%                 topography to use for receiver placement. Note this
%                 should be the *same* topography data used to create the
%                 model in Mamba2D so that the receivers are precisely
%                 positioned with respect to the *modeled* topography.
%
%   filetype   :: 'forward' or 'inverse'.  If 'forward', expects
%                 forward data flags to be set in stMT and/or stCSEM
%                 substructures. If 'inverse', expects data and
%                 uncertainties are input in data arrays defined in the
%                 stMT and stCSEM substructures.
%
%   st         :: structure of structures containing parameters for MT and/or CSEM
%                 data. Note there are many optional fields in the MT and
%                 CSEM structures below. Some optional fields override
%                 others and that may not be apparent from the brief
%                 descriptions below. My advice is to check out the
%                 MARE2DEM example files to see how to correctly use this
%                 routine for various MT and CSEM configurations.
%  
%   -----------
%   | st.stMT | (optional) contains MT data settings  
%   ----------- 
%
%     st.stMT.frequencies  :: frequencies of data in Hz
%     st.stMT.rx_type      :: setting for receiver vertical position and tilts.
% 
%                             'land'       :: Rx put 0.1 m below topography with
%                                             horizontal Hy and slope parallel Ey
%                             'marine'     :: Rx put 0.1 m above topography with
%                                             slope parallel Hy and Ey
%                             'amphibious' :: 'land' where z > 0 and 'marine' where z < 0
%
%                             Note that these settings are for typical land
%                             and marine field practice. Land magnetometers
%                             are installed horizontal, while the electric
%                             dipoles are deployed along the topographic
%                             slope. Marine sensors are assumed to be
%                             aligned slope parallel rather than
%                             horizontal.
%     st.stMT.rx_y         :: receiver positions along the y axis
%     st.stMT.rx_z         :: (optional) receiver vertical positions. If not
%                             input, then receivers are positioned relative
%                             to the topography based on rx_type setting.
%                             **Only use this if you want to force the
%                             receiver postions to specific value(s).*** If
%                             rx_z input, the receiver beta angles (y
%                             tilts) are set to input rx_beta values (if
%                             input) or set to 0.
%     st.stMT.rx_beta      :: (optional) receiver beta (y tilt) angles (degrees).
%                             If not input, then tilt angle is determined
%                             from the topography.
%
%     st.stMT.rx_name      :: (optional) Cell array of receiver names.
%
%     For forward modeling, use these flags to specify which data types
%     to include in the data file:
%
%         st.stMT.lTE       :: if true, includes TE mode apparent resistivity and phase
%         st.stMT.lTM       :: if true, includes TM mode apparent resistivity and phase
%         st.stMT.lTipper   :: if true, includes TE mode tipper (amplitude,phase)
%         st.stMT.lTipperRealImag :: if true, includes TE mode tipper (real,imag)
%         st.stMT.lZDet     :: if true, includes impedance determinant as
%                              apparent resistivity and phase
%         st.stMT.lMTFields :: set to true to specify TE and TM field
%                              vectors in data file. Useful for studying MT 
%                              physics. 
%
%     For inversion, include any of these data arrays: (KWK to do: not yet implemented)
%
%         st.stMT.TE_apres         :: Lists of [irx,ifreq,data,standard_error]
%         st.stMT.TE_phase            where irx is receiver index and ifreq is frequency index.    
%         st.stMT.TM_apres            Units: apparent resistivity (linear ohm-m) and phase (degrees). 
%         st.stMT.TM_phase
%         st.stMT.tipper_real
%         st.stMT.tipper_imag 
%         st.stMT.tipper_amplitude
%         st.stMT.tipper_phase  
%         
%   -------------
%   | st.stCSEM | (optional) contains CSEM data settings 
%   ------------- 
%
%     st.stCSEM.frequencies  :: frequencies of data in Hz
%     st.stCSE.rx_type       :: setting for receiver vertical position and tilts.
% 
%                               'land'       :: Rx put 0.1 m below topography with
%                                               horizontal Hy and slope parallel Ey
%                               'marine'     :: Rx put 0.1 m above topography with
%                                               slope parallel Hy and Ey
%                               'amphibious' :: 'land' where z > 0 and 'marine' where z < 0
%
%                               Note that these settings are for typical
%                               land and marine field practice. Land
%                               magnetometers are installed horizontal,
%                               while the electric dipoles are deployed
%                               along the topographic slope. Marine sensors
%                               are assumed to be aligned slope parallel
%                               rather than horizontal. Tilt and z position
%                               can be overridden using rx_beta, rx_z (or
%                               rx_z_offset) inputs.
%     st.stCSEM.rx_y         :: (optional) receiver y positions. If not 
%                               input, then rx_r field (for constant-offset
%                               towed-receivers) is required.
%     st.stCSEM.rx_r         :: (optional for towed receivers) receiver     
%                               horizontal offsets from transmitter.
%                               receivers will be positioned 'behind' the
%                               transmitter based on tow direction implied
%                               by order of values in stCSEM.tx_y (i.e,
%                               rx_y will be set as tx_y +- rx_r). If there
%                               are n towed receiver offsets and m
%                               transmitter locations, the output data file
%                               will have n*m receivers. Note that this
%                               simply places receivers at rx_r
%                               *horizontal* distances behind transmitter
%                               and does not account for the array angles
%                               when towing up and down steep slopes.
%     st.stCSEM.rx_x         :: (optional) receiver x positions. If not 
%                               input, 0 is used.
%     st.stCSEM.rx_z         :: (optional) receiver vertical positions. If
%                               not input, then receivers are positioned
%                               relative to the topography based on
%                               rx_z_offset or else the rx_type setting.
%                               **Only use this if you want to force the
%                               receiver postions to specific value(s).***
%                               If rx_z input, the receiver beta angles (y
%                               tilts) are set to input rx_beta values (if
%                               input) or else to 0.
%     st.stCSEM.rx_z_offset  :: (optional) z position of receivers 
%                               relative to topography. Overrides rx_type
%                               based depth setting. 
%                               < 0 puts rx above topo (e.g. in sea) and 
%                               > 0 puts rx below topo (e.g. in ground).
%                               E.g., use this to set a constant tow
%                               altitude for towed EM receivers (e.g.
%                               rx_z_offset = -50 for towing 50 m above 
%                               seafloor).
%     st.stCSEM.rx_beta      :: (optional) receiver beta (y tilt) angle (degrees).
%                               If not input, then tilt angle is determined
%                               from the topography. 
%     st.stCSEM.rx_length    :: (optional) receiver electric dipole length. 
%                               If not input, a point dipole (0 m) is used.
%                               For most applications, a point dipole
%                               receiver is best. Only use non-zero dipole
%                               lengths when the Tx and Rx range is less
%                               than about 10 dipole lengths.
%                               Warning: it is up to the user to make sure
%                               the dipole length, tilt and location
%                               are compatible with the resistivity model.
%                               The code DOES NOT check if tilted 
%                               dipoles cut through topography or stick
%                               into the air etc, all of which could cause
%                               inadvertent poor modeling results. YOU HAVE
%                               BEEN WARNED TO NOT USE THIS FEATURE. 
%
%     st.stCSEM.rx_name      :: (optional) Cell array of receiver names.
%                           
%     st.stCSEM.tx_y         :: transmitter position along the y axis
%     st.stCSEM.tx_x         :: (optional) transmitter position along the 
%                               x axis (2D strike). If not input, 0 is
%                               used.
%     st.stCSEM.tx_z         :: (optional) transmitter vertical position.
%                               Required if tx_z_offset not input.
%     st.stCSEM.tx_z_offset  :: (optional) z position of transmitter 
%                               relative to topography. Only used when
%                               tx_z is not input.
%                               < 0 puts tx above topo (e.g. in sea) and 
%                               > 0 puts tx below topo (e.g. in ground) 
%     st.stCSEM.tx_length    :: (optional) transmitter electric dipole length. 
%                               If not input, a point dipole (0 m) is used.
%                               For most applications, a point dipole
%                               works best. Only use non-zero dipole
%                               lengths when the Tx and Rx range is less
%                               than about 10 dipole lengths.
%                               Warning: it is up to the user to make sure
%                               the dipole length, tilt and location
%                               are compatible with the resistivity model.
%                               The code DOES NOT check if tilted 
%                               dipoles cut through topography or stick
%                               into the air etc, all of which could cause
%                               inadvertent poor modeling results. YOU HAVE
%                               BEEN WARNED TO NOT USE THIS FEATURE. 
%     st.stCSEM.tx_type      :: (optional) dipole type: 'edipole' or
%                               'bdipole'. If not input, 'edipole' is
%                               assumed.    
%     st.stCSEM.tx_vector    :: (optional) transmitter vector direction. 
%                               Should only be used for forward modeling
%                               Options:
%                               'x','y','z','parallel','perpendicular'
%                               where parallel and perpendicular are with
%                               respect to the topography. Conventional
%                               inline dipole-dipole CSEM data should use
%                               'y' or 'parallel', whereas vertical marine
%                               dipoles (like that used by Petromarker)
%                               should use 'z' or 'perpendicular'.
%
%     st.stCSEM.tx_azimuth   :: (optional) transmitter azimuth. Horizontal
%                               angle defined positive clockwise from
%                               strike direction x towards y. Typical
%                               inline CSEM data has transmitters along the
%                               y axis with azimuth = +90º. If
%                               single value input, it is applied to all tx
%                               positions. Overrides tx_vector.
%     st.stCSEM.tx_dip       :: (optional) transmitter dip angle defined 
%                               positive down from the azimuth. Horizontal 
%                               transmitter has dip = 0º, downward pointing
%                               transmitter has dip = 90º. Overrides
%                               tx_vector.
%
%     st.stCSEM.tx_name      :: (optional) Cell array of transmitter names.
%
%     st.stCSEM.phaseConvention :: (optional) Phase 'lag' (default) of 'lead'
%                                  In the lag convention, phases grow
%                                  increasinly postive with range. In the
%                                  lead convention, phases grow increasinly
%                                  negative with range. The convention to use depends on arises from
%                                  the sign of the exponent in the Fourier
%                                  time-to-frequency transform
%   
%     st.stCSEM.min_range   :: (optional) min transmitter-receiver range
%     st.stCSEM.max_range   :: (optional) max transmitter-receiver range 
%                              These settings are used in generating a data
%                              file for forward modeling. They can be
%                              single values or arrays with specific min &
%                              max ranges for each frequency. It is
%                              recommended to set a minimum range of at
%                              least 100 m or more for conventional marine
%                              CSEM modeling since short offset data are
%                              mostly sensitive to seawater conductivity,
%                              and asking MARE2DEM to simulate this data
%                              will result in significantly longer run
%                              times due the fine meshing required for the
%                              sharp field gradients close to the
%                              transmitter source dipole "singularity". The
%                              maximum range setting can be used to omit
%                              far offsets where the CSEM fields are likely
%                              much smaller than practically measureable
%                              (say < 10^-17), and this can make MARE2DEM
%                              run more efficiently since it won't waste
%                              time trying to refine the mesh to generate
%                              accurate responses at long offsets.
%
%     For forward modeling, use these flags to specify which CSEM data
%     types to include in the data file. Not that the x,y,z components are
%     in the receiver reference frame, which depends on its rotation angles
%     (theta, alpha, beta).
%
%         st.stCSEM.lEx     :: if true, includes Ex amplitude and phase 
%         st.stCSEM.lEy     :: if true, includes Ey amplitude and phase
%         st.stCSEM.lEz     :: if true, includes Ez amplitude and phase
%         st.stCSEM.lBx     :: if true, includes Bx amplitude and phase 
%         st.stCSEM.lBy     :: if true, includes By amplitude and phase
%         st.stCSEM.lBz     :: if true, includes Bz amplitude and phase
%     
%       
%     For inversion, include any of these data arrays:                      (kwk: not yet implemented)
%
%         st.stCSEM.Ex_amp         :: Lists of [irx,ifreq,data,standard_error]
%         st.stCSEM.Ex_phase          where irx is receiver index and ifreq is frequency index    
%         st.stCSEM.Ey_amp            
%         st.stCSEM.Ey_phase       :: E field units: V/(Am^2) and phase (degrees)
%         st.stCSEM.Ez_amp            
%         st.stCSEM.Ez_phase
%         st.stCSEM.Bx_amp         :: B field units: T/(Am) and phase (degrees)
%         st.stCSEM.Bx_phase             
%         st.stCSEM.By_amp             
%         st.stCSEM.By_phase
%         st.stCSEM.Bz_amp            
%         st.stCSEM.Bz_phase 
%         
%   Other fields:
%
%   st.comment :: (optional) A string of text that will be written on the 
%                 second line of the data file.
%
%   st.stUTM   :: (optional) Structure for mapping the 2D geometry to UTM.
%                 Not used by MARE2DEM but could be useful for later mapping
%                 of the 2D data and model into map coordinates in external
%                 plotting routines.
%
%   stUTM has the following fields:
%
%   stUTM.grid                :: UTM grid zone (e.g., 11)
%   stUTM.hemi                :: UTM hemisphere ('N' or 'S') 
%   stUTM.north0, stUTM.east0 :: The location of position 0 in the 2D model
%   stUTM.theta               :: The 2D strike angle (i.e. the direction x
%                                points in the 2D model space. Note that the
%                                receiver line is along y (so at theta+90).

%
% kwk: To do list:
%
%      reciprocity flag - apply EM reciprocity to CSEM data if it results
%      in fewer transmitters (and thus faster forward computations).
%
%      inversion data handling
%       
% 
%--------------------------------------------------------------------------
stMT    = [];
stCSEM  = [];
d_mt    = [];
d_csem  = [];

%
% Make MT data parameters:
%
if isfield(stIn,'stMT')
    [st.stMT, d_mt, lerror] = make_mt_data(topo,filetype, stIn.stMT);
end 

%
% Make CSEM data parameters:
%
if isfield(stIn,'stCSEM')
    [st.stCSEM, d_csem, lerror] = make_csem_data(topo,filetype, stIn.stCSEM);
end 

%
% Finish up and write the output data file:
%
st.DATA     = [d_mt; d_csem];

if isfield(stIn,'stUTM')
    st.stUTM = stIn.stUTM;
end

if isfield(stIn,'comment')
    st.comment = stIn.comment;
else
    st.comment  = 'data parameters created with m2d_makeDataFile.m';
end 

m2d_writeEMData2DFile(sOutFile,st) 

end

%--------------------------------------------------------------------------
function [stMT,data,lerror] = make_mt_data(topo,filetype,stIn)
  
%
% Creates:
%   stMT.receivers = [xRx yRx zRx theta alpha beta];
%   stMT.frequencies
%   data array for MT data

    stMT   = [];
    data   = [];
    lerror = false;
    
 
    % Make MARE2DEM receiver array, accounting for land, marine and amphibious
    % options:
    [stMT,irx_mag] = sub_make_rx(topo,stIn,'MT');

    % Frequencies:
    if isfield(stIn,'frequencies') && ~isempty(stIn.frequencies)
        stMT.frequencies = stIn.frequencies;
    else
        waitfor(errordlg('Error: MT frequencies not input. Try again','m2d_makeDataFile error'));
        lerror = true;
        return
    end

    
    %
    % Create data parameter array:
    %
    if strcmpi(filetype,'inversion')  
        data = sub_mt_inv_data(stIn); % kwk debug: write this code
    else % forward data
        data = sub_mt_fwd_data(stIn,length(stMT.frequencies),irx_mag);  
    end
    
end

%--------------------------------------------------------------------------
 function  [stOut,irx_mag] = sub_make_towed_rx(topo,stIn,sType)

%
% Creates MARE2DEM receiver block towed streamer style CSEM data
%
% stIn fields used:
% rx_r,rz_z(opt),rz_z_offset(opt),rx_beta(opt),rx_type(opt),receiverName(opt)
% tx_y for Tx position
% sType: 'CSEM' used for receiver automatic name generation

    if isfield(stIn,'rx_r') && ~isempty(stIn.rx_r)
        rRx = stIn.rx_r(:);
    else
        waitfor(errordlg('Error: receiver r positions not input. Try again','m2d_makeDataFile error'));
        return
    end
    if isfield(stIn,'tx_y') && ~isempty(stIn.tx_y)
        yTx = stIn.tx_y(:);
    else
        waitfor(errordlg('Error: transmitter y positions not input. Try again','m2d_makeDataFile error'));
        return
    end    

    nTx = length(yTx);
    nRx = length(rRx)*nTx;
    
    % Assume yTx is in order (increasing or decreasing) of tow direction. 
    % So we diff yTx and then use that to place Rx's "behind" Tx as it is
    % towed.
   
    tow_sign = sign(mean(diff(yTx)));
    yRx = repmat(yTx(:)',length(rRx),1) - tow_sign*repmat(rRx(:),1,nTx);

    yRx = yRx(:);

    % Now set z position:

    % constant depth:
    if isfield(stIn,'rx_z') && ~isempty(stIn.rx_z) && length(stIn.rx_z) == 1

        % z position has been input, so use that and set beta tilt angle to
        % zero:
        zRx = stIn.rx_z*ones(size(yRx));
        beta = zeros(size(zRx)); 
        % z position has been input, so use that and set beta tilt angle to
        % zero:
        zRx = stIn.rx_z(:);
        beta = zeros(size(zRx)); 
        
    else % set depth relative to topographic surface
                 
        % KWK debug: note that there is a falacy here in that
        % receiver r is input and used to set y offsets, but then here we
        % adjust z position which changes actual range (with dy and dz
        % terms). For dyoffsets long compared to dz the change in r will be
        % small. For real data, the navigated y and z positions should be
        % used instead to enforce r. You have been warned. 

        % get topo depth and slope at yRx:    
        [z,slopeAngle,lOnNode] = m2d_parseTopo(topo,yRx);
      
        if isfield(stIn,'rx_z_offset') && ~isempty(stIn.rx_z_offset)
            
            if length(stIn.rx_z_offset) == 1
                stIn.rx_z_offset = stIn.rx_z_offset*ones(size(yRx));
            end
       
            zRx = z + stIn.rx_z_offset;
       
        else % use generic station 'type' setting:
            switch stIn.rx_type
                case 'land'
                    dz = 0.1; % below topo
                case 'marine'
                    dz = -0.1; % above topo
                case 'amphibious'
                    dz(z >  0) = -0.1;
                    dz(z <= 0) =  0.1;
            end

            zRx  = z + dz(:);
        end
        
        beta = slopeAngle;
     
    end
 
    % override if beta input:
    if isfield(stIn,'rx_beta') && ~isempty(stIn.rx_beta)
        if length(stIn.rx_beta) == 1
            stIn.rx_beta = stIn.rx_beta*ones(size(yRx));
        end
            
        beta = stIn.rx_beta(:);
    end
        
    theta  = zeros(size(zRx)); % other rotation angles set to zero
    alpha  = zeros(size(zRx));
    xRx    = zeros(size(zRx));
    
    stOut.receivers = [xRx yRx zRx theta alpha beta];  

    % override if user input Rx length:
    if isfield(stIn,'rx_length') && ~isempty(stIn.rx_length)
        if length(stIn.rx_length) == 1
            stIn.rx_length = stIn.rx_length*ones(length(rRx));
        end        
        
        rxlen = repmat(stIn.rx_length(:), 1, length(yTx));
        stOut.receivers = [xRx yRx zRx theta alpha beta rxlen(:)];
    end
         
    %
    % Receiver names: 
    %
    if isfield(stIn,'rx_name') && ~isempty(stIn.rx_name) && length(stIn.rx_name) == length(rRx)
        names = repmat(stIn.rx_name, 1, length(yTx));
        stOut.receiverName = names(:);
    else % assign some names
        ict = 0;
        for i = 1:length(yTx)
            for j = 1:length(rRx)
                fstr = sprintf('Rx%i_Tx%i',j,i);
                ict = ict + 1;
                stOut.receiverName{ict} = fstr;
            end
        end
    end
    
    irx_mag = 1:length(zRx);  % index of rx to use for magnetic fields. Defaults to same rx as E's.
 
 end

 %--------------------------------------------------------------------------
 function  [stOut,irx_mag] = sub_make_rx(topo,stIn,sType)

%
% Creates MARE2DEM receiver block for MT and CSEM data
%
% stIn fields used:
% rx_y,rz_z(opt),rz_z_offset(opt),rx_beta(opt),rx_type(opt),receiverName(opt)
% 
% sType: 'MT' or 'CSEM' used for receiver automatic name generation

    if isfield(stIn,'rx_y') && ~isempty(stIn.rx_y)
        yRx = stIn.rx_y(:);
    else
        waitfor(errordlg('Error: receiver y positions not input. Try again','m2d_makeDataFile error'));
        lerror = true;
        return
    end
    
    if isfield(stIn,'rx_z') && ~isempty(stIn.rx_z)
        
        if length(stIn.rx_z) == 1
            stIn.rx_z = stIn.rx_z*ones(size(yRx));
        end
        
        % z position has been input, so use that and set beta tilt angle to
        % zero:
        zRx = stIn.rx_z(:);
        beta = zeros(size(zRx)); 
        
    else % set depth relative to topographic surface
                 
        % get topo depth and slope at yRx:    
        [z,slopeAngle,lOnNode] = m2d_parseTopo(topo,yRx);
      
        if isfield(stIn,'rx_z_offset') && ~isempty(stIn.rx_z_offset)
            
            if length(stIn.rx_z_offset) == 1
                stIn.rx_z_offset = stIn.rx_z_offset*ones(size(yRx));
            end
       
            zRx = z + stIn.rx_z_offset;
       
        else % use generic station 'type' setting:
            switch stIn.rx_type
                case 'land'
                    dz = 0.1; % below topo
                case 'marine'
                    dz = -0.1; % above topo
                case 'amphibious'
                    dz(z >  0) = -0.1;
                    dz(z <= 0) =  0.1;
            end

            zRx  = z + dz(:);
        end
        
        beta = slopeAngle;
     
    end
 
    % override if beta input:
    if isfield(stIn,'rx_beta') && ~isempty(stIn.rx_beta)
        if length(stIn.rx_beta) == 1
            stIn.rx_beta = stIn.rx_beta*ones(size(yRx));
        end
            
        beta = stIn.rx_beta(:);
    end
        
    theta  = zeros(size(zRx)); % other rotation angles set to zero
    alpha  = zeros(size(zRx));
    xRx    = zeros(size(zRx));
    
    stOut.receivers = [xRx yRx zRx theta alpha beta];  

    % override if user input Rx length:
    if isfield(stIn,'rx_length') && ~isempty(stIn.rx_length)
        if length(stIn.rx_length) == 1
            stIn.rx_length = stIn.rx_length*ones(size(yRx));
        end        
        
        rxlen = stIn.rx_length(:);
        stOut.receivers = [xRx yRx zRx theta alpha beta rxlen];
    end
         
    %
    % Receiver names: 
    %
    if isfield(stIn,'rx_name') && ~isempty(stIn.rx_name)
        stOut.receiverName = stIn.rx_name;
    else % assign some names
        fstr = sprintf('%%s%%0%ii',ceil(log10(length(zRx)+1)));
        for i = 1:length(zRx)
             stOut.receiverName{i} = sprintf(fstr,sType,i);
        end
    end
    
    % 
    % Special case for land EM stations. Make separate receivers
    % to use for the horizontal magnetometers where tilt is non-zero
    irx_mag = 1:length(zRx);  % index of rx to use for magnetic fields. Defaults to same rx as E's.
    
    if isfield(stIn,'rx_type') && ~isempty(stIn.rx_type)
        % find tilted receivers on land:
        itilted = [];
        switch stIn.rx_type
            case 'land'
                itilted = find(beta~=0);

            case 'amphibious'
                itilted = find(beta~=0 & zRx <= 0);  % i.e. set horizontal mags only for land MT stations
        end
        
        n       = length(zRx);
        for i = length(itilted):-1:1

            irx                     = itilted(i);
            hrx                     = stOut.receivers(irx,:);
            hrx(6)                  = 0; % zero beta angle;
            stOut.receivers(n+i,:)  = hrx;
            str                     = stOut.receiverName{irx};
            stOut.receiverName{irx} = sprintf('%s',str);  % E field only
            stOut.receiverName{n+i} = sprintf('%s_B',str);
            irx_mag(irx)            = n + i;

        end
    end
 end

 
 
%--------------------------------------------------------------------------
 function  [stOut] = sub_make_tx(topo,stIn)

%
% Creates MARE2DEM transmitters block for CSEM data
%
% stIn fields used: tx_y,tz_z(opt), tx_azimuth(opt),tx_dip(opt),tx_length(opt),
%                   type, transmitterName
% 
    % yTx:
    if isfield(stIn,'tx_y') && ~isempty(stIn.tx_y)
        yTx = stIn.tx_y(:);
    else
        waitfor(errordlg('Error: transmitter y positions not input. Try again','m2d_makeDataFile error'));
        lerror = true;
        return
    end
    
    % xTx:
    if isfield(stIn,'tx_x') && ~isempty(stIn.tx_x)
        if length(stIn.tx_x) == 1
            stIn.tx_x = stIn.tx_x*ones(size(yTx));
        end
        xTx = stIn.tx_x(:);
    else
        xTx = zeros(size(yTx)); 
    end    
    
    % zTx:
    if isfield(stIn,'tx_z') && ~isempty(stIn.tx_z)
        
        if length(stIn.tx_z) == 1
            stIn.tx_z = stIn.tx_z*ones(size(yTx));
        end

        zTx = stIn.tx_z(:);
        
    else % set depth relative to topographic surface
                 
        if length(stIn.tx_z_offset) == 1
            stIn.tx_z_offset = stIn.tx_z_offset*ones(size(yTx));
        end
        [z,slopeAngle,lOnNode] = m2d_parseTopo(topo,yTx);
        zTx = z + stIn.tx_z_offset(:);

    end
    
    % Tx length:
    if isfield(stIn,'tx_length') && ~isempty(stIn.tx_length)
        if length(stIn.tx_length) == 1
            stIn.tx_length = stIn.tx_length*ones(size(yTx));
        end
        txlen = stIn.tx_length(:);
     
    else
       txlen = zeros(size(yTx)); % point dipole default
    end
    
    % intepret tx_vector and set azimuth and dip:
    if isfield(stIn,'tx_vector') && ~isempty(stIn.tx_vector) 
        [z,slopeAngle,lOnNode] = m2d_parseTopo(topo,yTx);
        switch lower(stIn.tx_vector)
            case 'x'
                azimuth = zeros(size(yTx));
                dip     = zeros(size(yTx));
            case 'y'
                azimuth = 90*ones(size(yTx));
                dip     = zeros(size(yTx));
            case 'z'
                azimuth = zeros(size(yTx));  
                dip     = 90*ones(size(yTx));               
            case 'parallel'
                azimuth = 90*ones(size(yTx)); 
                dip     = slopeAngle;  
            case 'perpendicular'
                azimuth = 90*ones(size(yTx)); 
                dip     = (slopeAngle+90); 
            otherwise
        end
        
    end
    
    
    % Override azimuth and dip, if input:
    if isfield(stIn,'tx_azimuth') && ~isempty(stIn.tx_azimuth)
        if length(stIn.tx_azimuth) == 1
            stIn.tx_azimuth = stIn.tx_azimuth*ones(size(yTx));
        end
        azimuth = stIn.tx_azimuth(:);
    end
    if isfield(stIn,'tx_dip') && ~isempty(stIn.tx_dip)
        if length(stIn.tx_dip) == 1
            stIn.tx_dip = stIn.tx_dip*ones(size(yTx));
        end
        dip = stIn.tx_dip(:);
    end   
    
    % Now set output transmitter array:
    stOut.transmitters = [xTx yTx zTx azimuth dip txlen];  

    % transmitter type: 
    if isfield(stIn,'tx_type') && ~isempty(stIn.tx_type)
        switch stIn.tx_type
            case {'edipole','bdipole'}
                    
            otherwise
                % error message...
                
        end

    else
        stIn.tx_type = 'edipole';      
    end
    for i = 1:length(zTx)
         stOut.transmitterType{i} = stIn.tx_type;    
    end
      

    %
    % Transmitter names: 
    %
    if isfield(stIn,'tx_name') && ~isempty(stIn.tx_name)
        stOut.transmitterName = stIn.tx_name;
    else % assign some names
        fstr = sprintf('Tx%%0%ii',ceil(log10(length(zTx)+1)));
        for i = 1:length(zTx)
             stOut.transmitterName{i} = sprintf(fstr,i);
        end
    end
 
  end
%--------------------------------------------------------------------------
function data = sub_mt_fwd_data(stIn,nf,irx_mag) 

    % preallocate for speed:

    n = 0;
    if isfield(stIn,'lTM') && stIn.lTM
        n = n + 2;
    end
    if isfield(stIn,'lTE') && stIn.lTE 
        n = n + 2;
    end
    if isfield(stIn,'lZDet') && stIn.lZDet
        n = n + 2;
    end    
    if isfield(stIn,'lTipper') && stIn.lTipper
        n = n + 2;
    end
    if isfield(stIn,'lMTFields') && stIn.lMTFields
        n = n + 12;  % 3 components, 2 fields, real & imag
    end    
    

    nRx = length(irx_mag);
    dp  = zeros(nf*nRx*n,6); % allocate maximum possible data parameters

    ict = 0;
    for ifreq = 1:nf

        for irx = 1:length(irx_mag)  

            itx = irx_mag(irx);  % here itx refers to the H receiver to use in Z = E/H and irx is the E receiver

            if isfield(stIn,'lTE') && stIn.lTE 
                dp(ict+1  ,1:4) = [123 ifreq itx irx];  % log10 apparent resistivity TE
                dp(ict+2  ,1:4) = [104 ifreq itx irx];  % phase TE
                ict = ict + 2;
            end

            if isfield(stIn,'lTM') && stIn.lTM
                dp(ict+1  ,1:4) = [125 ifreq itx irx]; % log10 apparent resistivity TM
                dp(ict+2  ,1:4) = [106 ifreq itx irx]; % phase TM
                ict = ict + 2;
            end
            if isfield(stIn,'lZDet') && stIn.lZDet
                dp(ict+1  ,1:4) = [129 ifreq itx irx]; % log10 apparent resistivity Z determinant
                dp(ict+2  ,1:4) = [110 ifreq itx irx]; % phase Z determinant
                ict = ict + 2;
            end
            if isfield(stIn,'lTipperRealImag') && stIn.lTipperRealImag
                dp(ict+1  ,1:4) = [133 ifreq itx itx];  % real tipper, note tipper uses mag station
                dp(ict+2  ,1:4) = [134 ifreq itx itx];  % imaginary tipper
                ict = ict + 2;
            end
            if isfield(stIn,'lTipper') && stIn.lTipper
                dp(ict+1  ,1:4) = [135 ifreq itx itx];  % tipper amplitude, note tipper uses mag station
                dp(ict+2  ,1:4) = [136 ifreq itx itx];  % tipper phase
                ict = ict + 2;
            end   
            if isfield(stIn,'lMTFields') && stIn.lMTFields
                dp(ict+1  ,1:4) = [151 ifreq irx irx]; % Ex real  
                dp(ict+2  ,1:4) = [152 ifreq irx irx]; % Ex imag   
                dp(ict+3  ,1:4) = [153 ifreq irx irx]; % Ey real    
                dp(ict+4  ,1:4) = [154 ifreq irx irx]; % Ey imag    
                dp(ict+5  ,1:4) = [155 ifreq irx irx]; % Ez real    
                dp(ict+6  ,1:4) = [156 ifreq irx irx]; % Ez imag    
                dp(ict+7  ,1:4) = [161 ifreq irx irx]; % Hx real    
                dp(ict+8  ,1:4) = [162 ifreq irx irx]; % Hx imag    
                dp(ict+9  ,1:4) = [163 ifreq irx irx]; % Hy real    
                dp(ict+10 ,1:4) = [164 ifreq irx irx]; % Hy imag    
                dp(ict+11 ,1:4) = [165 ifreq irx irx]; % Hz real    
                dp(ict+12 ,1:4) = [166 ifreq irx irx]; % Hz imag                   
                ict = ict + 12;
            end               
            
        end

    end

    data = dp(1:ict,:);
 
end
%--------------------------------------------------------------------------
function [stCSEM,data,lerror] = make_csem_data(topo,filetype,stIn)
  
%
% Creates:
%   stCSEM.receivers    = [x y z theta alpha beta length];
%   stCSEM.transmitters = [x y z azimuth dip length];
%   stCSEM.frequencies
%   data array

    stCSEM  = [];
    data    = [];
    lerror  = false;
    
    % Make MARE2DEM receiver array accounting for land, marine and amphibious
    % options:
    if isfield(stIn,'rx_r') && ~isempty(stIn.rx_r)  % towed rx at constant offsets
        [stRx,irx_mag] = sub_make_towed_rx(topo,stIn,'CSEM');  
    else
        [stRx,irx_mag] = sub_make_rx(topo,stIn,'Rx');
    end
    % Make MARE2DEM transmitter array:
    stTx = sub_make_tx(topo,stIn);
    
    % merge st's:
    mergestructs = @(x,y) cell2struct([struct2cell(stRx);struct2cell(stTx)],[fieldnames(stRx);fieldnames(stTx)]);
    stCSEM = mergestructs(stRx,stTx);
    
    % Frequencies:
    if isfield(stIn,'frequencies') && ~isempty(stIn.frequencies)
        stCSEM.frequencies = stIn.frequencies;
    else
        waitfor(errordlg('Error: stCSEM frequencies not input. Try again','m2d_makeDataFile error'));
        lerror = true;
        return
    end
    
    stCSEM.phaseConvention = 'lag';
    if isfield(stIn,'phaseConvention') && ~isempty(stIn.phaseConvention)
        stCSEM.phaseConvention = stIn.phaseConvention;
    end

    %
    % Create data parameter array:
    %
    if strcmpi(filetype,'inversion')  
        data = sub_csem_inv_data(stIn); % kwk debug: write this code
    else % forward data
        [stCSEM,data] = sub_csem_fwd_data(stIn,stCSEM,irx_mag);  
    end
     
end

%--------------------------------------------------------------------------
function [stCSEM, data] = sub_csem_fwd_data(stIn,stCSEM,irx_mag) 

% see em_parameters.inc for the magic numbers used below

    % If duplicate receivers were created for horizontal B fields (when E's are tilted), get rid of
    % them if B data not requested:
    if (~isfield(stIn,'lBx') || ~stIn.lBx) && ...
       (~isfield(stIn,'lBy') || ~stIn.lBy) && ...
       (~isfield(stIn,'lBz') || ~stIn.lBz) 
   
        lomit = irx_mag ~= [1:length(irx_mag)]; % true when B receiver different than E receiver
        stCSEM.receivers(irx_mag(lomit),:) = [];
        stCSEM.receiverName(irx_mag(lomit)) = [];
    end
    
    % create min and max range vectors for use in omit Rx-Tx pairs outside
    % limits:
    nf  = length(stCSEM.frequencies);
    min_range(1:nf) = 0;
    max_range(1:nf) = 1e300;
  
    if isfield(stIn,'min_range')  && ~isempty(stIn.min_range)
        min_range(1:nf) = stIn.min_range;
    end
    if isfield(stIn,'max_range')  && ~isempty(stIn.max_range)
        max_range(1:nf) = stIn.max_range;
    end   
    

    if isfield(stIn,'rx_r') && ~isempty(stIn.rx_r)  % towed rx at constant offsets
        
        bTowedArray = true;
        nRx = length(stIn.rx_r);

    else
        bTowedArray = false;
        nRx = size(stCSEM.receivers,1);
    end
 
    % preallocate for speed:
    n = 3*2*2; % three components * two fields * amplitude & phase
    
    nTx = size(stCSEM.transmitters,1);
   
   
    dp  = zeros(nf*nRx*nTx*n,6); % allocate maximum possible data parameters

    ict = 0;
    
    for ifreq = 1:nf
        
        for itx = 1:nTx
            
            for i = 1:nRx

                if bTowedArray
                    irx = i + (itx-1)*nRx;
                else
                    irx = i;
                end
                
                % Get 3D range and check min and max settings:
                dr = stCSEM.transmitters(itx,1:3) - stCSEM.receivers(irx,1:3);
                range = norm(dr,2);
                
                if range < min_range(ifreq) || range > max_range(ifreq)
                    continue % on to next irx without adding data parameters below
                end
                
                if isfield(stIn,'lEx') && stIn.lEx 
                    dp(ict+1  ,1:4) = [27 ifreq itx irx];  % log10 amplitude Ex
                    dp(ict+2  ,1:4) = [22 ifreq itx irx];  % phase Ex
                    ict = ict + 2;
                end
                if isfield(stIn,'lEy') && stIn.lEy 
                    dp(ict+1  ,1:4) = [28 ifreq itx irx];  % log10 amplitude Ey
                    dp(ict+2  ,1:4) = [24 ifreq itx irx];  % phase Ey
                    ict = ict + 2;
                end
                if isfield(stIn,'lEz') && stIn.lEz 
                    dp(ict+1  ,1:4) = [29 ifreq itx irx];  % log10 amplitude Ez
                    dp(ict+2  ,1:4) = [26 ifreq itx irx];  % phase Ez
                    ict = ict + 2;
                end   

                irx_B = irx_mag(irx); % in case B field requested using duplicate (but non tilted) Rx at same location as E reciever
                    
                if isfield(stIn,'lBx') && stIn.lBx 
                    dp(ict+1  ,1:4) = [37 ifreq itx irx_B];  % log10 amplitude Bx
                    dp(ict+2  ,1:4) = [32 ifreq itx irx_B];  % phase Bx
                    ict = ict + 2;
                end
                if isfield(stIn,'lBy') && stIn.lBy 
                    dp(ict+1  ,1:4) = [38 ifreq itx irx_B];  % log10 amplitude By
                    dp(ict+2  ,1:4) = [34 ifreq itx irx_B];  % phase By
                    ict = ict + 2;
                end
                if isfield(stIn,'lBz') && stIn.lBz 
                    dp(ict+1  ,1:4) = [39 ifreq itx irx_B];  % log10 amplitude Bz
                    dp(ict+2  ,1:4) = [36 ifreq itx irx_B];  % phase Bz
                    ict = ict + 2;
                end                 
            end

        end

    end

    data = dp(1:ict,:); % trim off excess
 
end