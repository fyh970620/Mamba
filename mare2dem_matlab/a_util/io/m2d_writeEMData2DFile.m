% function  m2d_writeEMData2DFile(outputFileName,st) 
% 
% Utility function to write out an EMData_2.3 format file used by the
% MARE2DEM code
%
% Warning:  MARE2DEM has a few advanced "special case" features that
% most users should NEVER use:
%
% finite dipole lengths :: Do not use finite length dipoles for MT stations
% and do so with great caution for CSEM modeling. It is up to the user to
% make sure the dipole length, tilt and location are compatible with the
% resistivity model structure. The code DOES NOT check if tilted dipoles
% cut through topography or stick into the air etc, all of which will
% cause inadvertent poor modeling results. 
% 
% solvecorr :: The CSEM receiver and transmitter data corrections columns
% should be left set to 0. These are special experimental features that
% generally do not work.
%
% YOU HAVE BEEN WARNED TO NOT USE THESE FEATURES. DO SO AT YOUR OWN PERIL.
%                                
%
% Kerry Key
% Lamont-Doherty Earth Observatory
%
% Input arguments:
%
% outputFilename            :: String containing the full name and path of 
%                              the file to  write out. Typically this is 
%                              something like 'line2b.emdata'.
%
% st is a structure with the fields:
% 
% comment                   :: Any string of text you want added to the
%                              second line of the data file. (optional)
%
% stUTM:  Structure for mapping the 2D geometry to UTM. Use 0 if you
%         don't need this. stUTM has the following fields:
%
%   stUTM.grid                :: UTM grid zone (e.g., 11)
%   stUTM.hemi                :: UTM hemisphere ('N' or 'S') 
%   stUTM.north0, stUTM.east0 :: The location of position 0 in the 2D model
%   stUTM.theta               :: The 2D strike angle (i.e. the direction x
%                                points in the 2D model space. Note that the
%                                receiver line is along y (so at theta+90).
%
% stCSEM: Structure containing CSEM transmitter and receiver parameters.
%         If there is no CSEM data, leave this structure empty on input.
%         stCSEM has the following fields:
%
%   stCSEM.phaseConvention    :: 'lag' or 'lead'
%   stCSEM.reciprocityUsed    :: 'yes' or 'no'  This is only used for plotting
%                                 not by MARE2DEM. Optional.
%   stCSEM.transmitters       :: Array of Tx parameters. One row per
%                                transmitter of 
%                                [x y z azimuth dip length solvecorr].
%                                Azimuth if the angle from x, so typically 90
%                                for inline transmitters. Dip is the angle
%                                positive down of the transmitter lead
%                                electrode. Note that the "length" field is
%                                optional, and 0 will be used if this is not
%                                present to ensure backwards compatibility
%                                with older file formats. The last column  
%                                specifies an optional "solvecorr" flag to use 
%                                during inversion (most user should NEVER use 
%                                this feature and leave it set to 0.)
%
%   stCSEM.transmitterType    :: Cell array identifying the dipole type for 
%                                each row of the .transmitters. Type can be 
%                                'edipole' or 'bdipole'.
%   stCSEM.transmitterName    :: Cell array of CSEM transmitter names. (optional)
%   stCSEM.frequencies        :: Frequencies of the CSEM data
%   stCSEM.timeOffsets        :: Time-offsets of the CSEM data
%   stCSEM.receivers          :: Array of CSEM receivers. One row per receiver
%                                containing [x y z theta alpha beta length solvecorr]
%                                *Note that the "length" field is
%                                optional, and 0 will be used if this is not
%                                present to ensure backwards compatibility
%                                with older file formats. Length refers to
%                                the electric field dipole length and is
%                                ignored for magnetic components (i.e. they
%                                are assumbed to be point receivers).
%                                The last column  specifies an optional
%                                "solvecorr" flag to use 
%                                during inversion (most user should NEVER use 
%                                this feature and leave it set to 0.)
%   stCSEM.receiverName       :: Cell array of CSEM receiver names. (optional)
%
% stDC:   Structure containing DC transmitter and receiver parameters.
%         If there is no DC data, leave this structure empty on input.
%         stDC has the following fields:
%
%   stDC.rx_electrodes       :: Array of receiver electrode locations [x y z]
%   stDC.tx_electrodes       :: Array of transmitter electrode locations [x y z]
%   stDC.receivers           :: Array of electrode index pairs that 
%                               comprise a DC receiver pair. [M N]
%   stDC.transmitters        :: Array of electrode index pairs that 
%                               comprise a DC transmitter. [A B]
%   stDC.receiverName        :: Cell array of DC receiver names. (optional)
%   stDC.transmitterName     :: Cell array of DC transmitter names. (optional)
% 
%
% stMT:   Structure containing MT transmitter and receiver parameters.
%         If there is no MT data, leave this structure empty on input.
%         stMT has the following fields
%
%   stMT.frequencies          :: Frequencies of the MT data
%   stMT.receivers            :: Array of MT receivers. One row per receiver
%                                containing [x y z theta alpha beta length iSolveStatic]
%                                Set iSolveStatic = 1 to invert for TE and TM
%                                static shifts.
%                                *Note that the "length" field is
%                                optional, and 0 will be used if this is not
%                                present to ensure backwards compatibility
%                                with older file formats.
%   stMT.receiverName         :: Cell array of MT receiver names. (optional)
% 
% DATA                        :: Block of the data with indices to the
%                                transmitters, frequencies and receivers.
%                                Each row is
%                                [type freq# Tx# Rx# Data Std_Error] 
%                                where the first four values are integers
%                                pointing to the particular arrays for that
%                                data type (CSEM or MT).
%
% For more details, see the data format description on the MARE2DEM website.
%

function  m2d_writeEMData2DFile(varargin)

[comment,stUTM,stCSEM,stMT,stDC,DATA] = deal([]);

if nargin <= 1
    h = errordlg('Error: not enough inputs to m2d_writeEMData2DFile. Try again.','m2d_writeEMData2DFile.m Error');
    waitfor(h);
    return;
end
 
outputFileName = varargin{1};

if nargin == 2 % new input format with only filename and st structure input. 
    % break out the fields:
    st = varargin{2};

    if isfield(st,'comment')
        comment = st.comment;
    end
    if isfield(st,'stUTM')
        stUTM = st.stUTM;
    end  
    if isfield(st,'stCSEM')
        stCSEM = st.stCSEM;
    end       
    if isfield(st,'stMT')
        stMT = st.stMT;
    end   
    if isfield(st,'stDC')
        stDC = st.stDC;
    end   
    if isfield(st,'DATA')
        DATA = st.DATA;
    end
    
elseif nargin == 6 % old version before DC resistivity support added
  comment = varargin{2};
  stUTM   = varargin{3};
  stCSEM  = varargin{4};
  stMT    = varargin{5};
  DATA    = varargin{6};
end
    


%  
% Create the output Data file:
%

fid = fopen(outputFileName,'w');
if size(DATA,2)==6
    fprintf(fid,'Format:  EMData_2.3\n');
elseif size(DATA,2)==4 % forward data request with missing dummy values, add 0's
    fprintf(fid,'Format:  EMData_2.3\n');     
    DATA(:,5:6) = 0;    
elseif size(DATA,2)==8
    fprintf(fid,'Format:  EMResp_2.3\n');
else
    return
end

% Print comment line:
if ~isempty(comment)
    fprintf(fid,'!%s\n', comment);
end

%--------------------------------------------------------------------------
% UTM section:
%--------------------------------------------------------------------------
 
% Print datum transformation info:
if ~isempty(stUTM)
    fprintf(fid,'UTM of x,y origin (UTM zone, N, E, 2D strike): %d %s %14.6f %14.6f %6g\n' ...
           , stUTM.grid,stUTM.hemi, stUTM.north0, stUTM.east0, stUTM.theta);
end

%--------------------------------------------------------------------------
% MT section: (before CSEM section since it will generally be short)
%--------------------------------------------------------------------------  
if ~isempty(stMT)
 
    % Frequencies:
    fprintf(fid,'# MT Frequencies:    %i\n',length(stMT.frequencies));
    for i = 1:length(stMT.frequencies)
      fprintf(fid,'%.14g\n',stMT.frequencies(i));
    end
    
    % Receivers:
    fprintf(fid,'# MT Receivers:      %i\n',size(stMT.receivers,1));
    fprintf(fid,'%1s %22s %22s %22s %9s %9s %9s %10s %11s %4s\n','!','X','Y','Z','Theta','Alpha','Beta','Length','SolveStatic','Name');
    
    for i = 1:size(stMT.receivers,1)  % Note that this code is funky cuz it haz to support older formats...
       
        if isfield(stMT,'receiverName') && ~isempty(stMT.receiverName)
            sName = stMT.receiverName{i};
        else
            sName = '';
        end
        if length(stMT.receivers(i,:)) >= 7
            eLength = stMT.receivers(i,7);
        else
            eLength = 0; % point dipole
        end        
        if length(stMT.receivers(i,:)) == 8
            iStatic = stMT.receivers(i,8);
        else
            iStatic = 0;
        end
        fprintf(fid,'  %22.15g %22.15g %22.15g %9.2f %9.2f %9.2f %10.5g %11i %s\n', stMT.receivers(i,1:6),eLength,iStatic, sName);    
    end
end

%--------------------------------------------------------------------------
% CSEM section:
%--------------------------------------------------------------------------
if ~isempty(stCSEM) && isfield(stCSEM,'transmitters')
    
    fprintf(fid,'Phase Convention: %s\n',stCSEM.phaseConvention);
    
    if isfield(stCSEM,'reciprocityUsed')
        fprintf(fid,'Reciprocity Used: %s\n',stCSEM.reciprocityUsed);
%     else
%         fprintf(fid,'Reciprocity Used: \n');
    end
    
    % Time offsets: (for TDEM modeling only...)
    if  isfield(stCSEM,'timeOffsets')
        fprintf(fid,'# CSEM Time Offsets:    %i\n',length(stCSEM.timeOffsets));
        for i = 1:length(stCSEM.timeOffsets)
            fprintf(fid,'%.14g\n',stCSEM.timeOffsets(i));
        end        
    end
    
    % Source waveform: (for TDEM modeling only...)
    if  isfield(stCSEM,'tdemWaveform')
        fprintf(fid,'# TDEM waveform points:    %i\n',size(stCSEM.tdemWaveform,1));
        for i = 1:size(stCSEM.tdemWaveform,1)
            fprintf(fid,'%.14g %.14gf\n',stCSEM.tdemWaveform(i,:));
        end        
    end    
    
    % Frequencies:
    if  isfield(stCSEM,'frequencies')
        fprintf(fid,'# CSEM Frequencies:    %i\n',length(stCSEM.frequencies));
        for i = 1:length(stCSEM.frequencies)
            fprintf(fid,'%.14g\n',stCSEM.frequencies(i));
        end
    end
    
    % Transmitters:
    nTx = size(stCSEM.transmitters,1);
    fprintf(fid,'# Transmitters:   %i\n',nTx);
    fprintf(fid,'%1s %22s %22s %22s %9s %9s %10s %10s %10s %4s\n','!','X','Y','Z','Azimuth','Dip','Length','SolveCorr','Type','Name');
    
    if size(stCSEM.transmitters,2) < 7
       stCSEM.transmitters(:,7) = 0; % this pads with 0 columns in case Length and SolveCorrect columns are missing from older file formats.
    end
    for i = 1:nTx    
        if isfield(stCSEM,'transmitterName') && ~isempty(stCSEM.transmitterName)
            sName = stCSEM.transmitterName{i};
        else
            sName = '';
        end     
        fprintf(fid,'  %22.15g %22.15g %22.15g %9.2f %9.2f %10.5g %10i %10s %s\n',...
                stCSEM.transmitters(i,1:7),stCSEM.transmitterType{i},sName);
    end
    
    % Receivers:
    fprintf(fid,'# CSEM Receivers:      %i\n',size(stCSEM.receivers,1));
    fprintf(fid,'%1s %22s %22s %22s %9s %9s %9s %10s %11s %4s\n','!','X','Y','Z','Theta','Alpha','Beta','Length','SolveCorr','Name');
    
    if size(stCSEM.receivers,2) < 8
       stCSEM.receivers(:,8) = 0; % this pads with 0 columns in case Length and SolveCorr columns are missing from older file formats.
    end
    
    for i = 1:size(stCSEM.receivers,1)  % Note that this code is funky cuz it haz to support older formats...
        
        if isfield(stCSEM,'receiverName') && ~isempty(stCSEM.receiverName)
            sName = stCSEM.receiverName{i};
        else
            sName = '';
        end
 
        fprintf(fid,'  %22.15g %22.15g %22.15g %9.2f %9.2f %9.2f %10.5g %11i %s\n',...
                stCSEM.receivers(i,1:8),sName);
    end
    
end

%--------------------------------------------------------------------------
% DC section:
%--------------------------------------------------------------------------
if ~isempty(stDC) && isfield(stDC,'transmitters')
    

    % DC transmitter electrodes:
    nTx = size(stDC.tx_electrodes,1);
    fprintf(fid,'# DC Transmitter Electrodes:   %i\n',nTx);
    fprintf(fid,'%1s %22s %22s %22s\n','!','X','Y','Z' );
    
    for i = 1:nTx    
        fprintf(fid,'%22.15g %22.15g %22.15g\n',stDC.tx_electrodes(i,1:3));
    end  
    
    % DC Transmitters:
    nTx = size(stDC.transmitters,1);
    fprintf(fid,'# DC Transmitters:   %i\n',nTx);
    fprintf(fid,'%1s %12s %12s %12s\n','!','Electrode A','Electrode B','Name' );
    
    for i = 1:nTx  
        if isfield(stDC,'transmitterName') && ~isempty(stDC.transmitterName)
            sName = stDC.transmitterName{i};
        else
            sName = '';
        end
        fprintf(fid,'%12i %12i %12s\n',stDC.transmitters(i,1:2),sName);
    end    
    
    % DC receiver electrodes:
    nRx = size(stDC.rx_electrodes,1);
    fprintf(fid,'# DC Receiver Electrodes:   %i\n',nRx);
    fprintf(fid,'%1s %22s %22s %22s\n','!','X','Y','Z' );
    
    for i = 1:nRx    
        fprintf(fid,'%22.15g %22.15g %22.15g\n',stDC.rx_electrodes(i,1:3));
    end        
    
    % DC receivers:
    nRx = size(stDC.receivers,1);
    fprintf(fid,'# DC Receivers:   %i\n',nRx);
    fprintf(fid,'%1s %12s %12s %12s\n','!','Electrode M','Electrode N','Name' );
    
    for i = 1:nRx    
        if isfield(stDC,'receiverName') && ~isempty(stDC.receiverName)
            sName = stDC.receiverName{i};
        else
            sName = '';
        end
        fprintf(fid,'%12i %12i %12s\n',stDC.receivers(i,1:2),sName);
    end        
end

%--------------------------------------------------------------------------
% DATA section:
%--------------------------------------------------------------------------  


% Write out the data:
    fprintf(fid,'# Data:       %i\n',length(DATA(:,1)));
    if size(DATA,2)==6
        fprintf( fid, '!  Type  Freq #    Tx #    Rx #              Data            StdErr\n' );
        fprintf( fid, '%7d %7d %7d %7d %20.15g %20.15g\n', DATA' );
    elseif size(DATA,2)==8
        fprintf( fid, '!  Type  Freq #    Tx #    Rx #              Data            StdErr       Response       Residual\n' );
        fprintf( fid, '%7d %7d %7d %7d %22.15g %22.15g %20.15g %20.15g \n', DATA' );
    else
        error('DATA block has the wrong number of columns.')
    end

% All done, let's close the file:
    fclose(fid);
    return;
end
