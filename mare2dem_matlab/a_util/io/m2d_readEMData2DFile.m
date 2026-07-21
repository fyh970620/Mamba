% function st = m2d_readEMData2DFile(fileName, bSilent) 
%
% Utility function to read EMData_2.3 or EMResp_2.3 or earlier format files
% used in the MARE2DEM inversion code. 
%
% Outputs structure st with fields stUTM,stCSEM,stMT,stDC,DATA, depending
% on the file contents. If a response file, DATA has two extra columns
% for the model response and the residual.
%
% Kerry Key
% Lamont-Doherty Earth Observatory
%
% See m2d_writeEMData2DFile for a description of the fields in structure st. 
%
function   [varargout] = m2d_readEMData2DFile(fileName, bSilent )

if nargout ~= 1 && nargout ~= 4
    h = errordlg('Error: incorrect number of output arguments to m2d_readEMData2DFile. Try again.','m2d_readEMData2DFile.m Error');
    waitfor(h);
    varargout{nargout} = [];
    return;
end

[stUTM,stCSEM,stMT,stDC,DATA] = deal([]);


    % DGM 4/25/2012 - implement a silent mode so failure doesn't cause msgs
    if ~exist( 'bSilent', 'var' ) || isempty(bSilent)
        bSilent = false;        % old default is to talk
    elseif ischar(bSilent)
        bSilent = strncmpi( bSilent, 'S', 1 ); % 'Silent' or some shorter part thereof
    end
    
    stUTM.grid   = 0;
    stUTM.hemi   = 'N';
    stUTM.north0 = 0;
    stUTM.east0  = 0;
    stUTM.theta  = 0;

%   
% Open the file and check the version:
%

    fid = fopen(fileName,'r');
    
    if fid < 0
        h = errordlg(sprintf('Error opening file: %s \n File not found!',fileName),'m2d_readEMData2DFile.m Error');
        waitfor(h);    
        varargout{nargout} = [];
        return;
    end

 %
 % Loop through the file and decode the lines read in:
 %
    while ~feof(fid)
        
   
        % Get the current line & break up the code / value pair
        sLine = fgets( fid );
        [sCode, sValue] = strtok( sLine, ':' );
        sCode = lower(strtrim(sCode));
        if ~isempty(sValue)
            sValue(1) = [];     % remove the leading token
        end
        % If there is a user comment in the value, eliminate it.
        sValue = strtrim( strtok(sValue, '!%') );
        
        % Which code do we have?
        
        
        switch (sCode)
        case {'format','version'}
            sFileFormat = strtrim(lower(sValue));
            switch(sFileFormat)
            case {'emdata_2.0', 'emdata_2.1', 'emdata_2.2', 'emdata_2.3'}
                sFileType = 'data';
            case {'emresp_2.0', 'emresp_2.1', 'emresp_2.2', 'emresp_2.3'}
                sFileType = 'response';
            otherwise
                if ~bSilent
                    h = errordlg(sprintf('Unsupported format: %s',sFileFormat),'m2d_readEMData2DFile.m Error');
                    waitfor(h);
                end
                fclose(fid);    
                return;
            end 


        
        case {'utm of x,y origin (n,e,theta)'
                'utm'
                'origin'
            'utm of x,y origin (utm zone, n, e, 2d strike)'}
            % textscan below works with both these examples
            %       49 S 7805394 712557 114
            %       49S 7805394 712557 114
            if ~isempty(strtrim(sValue))
                c = textscan( sValue, '%d %s %f %f %f' );
                stUTM.grid      = c{1};
                a = c{2};
                stUTM.hemi      = a{1};
                stUTM.north0    = c{3};
                stUTM.east0     = c{4};
                stUTM.theta     = c{5};
            end
        case {'phase convention'}
            stCSEM.phaseConvention = sValue;

        case {'reciprocity used'}
            stCSEM.reciprocityUsed = sValue;
            
        case {'# transmitters','#transmitters'}
            
            nTx = str2double(sValue);
            nTxReadin = 0;
            stCSEM.transmitters = zeros(nTx,7);  % X Y Z Azimuth Dip Length CorrectionFlag
            
            
           % Now read in the transmitters:
            while nTxReadin < nTx
                 sLine0 = fgets( fid );
                 
                 [sLine, lComment] = parseLine(sLine0);
                 
                 if ~lComment
                     nTxReadin = nTxReadin + 1;
   
                 
                    switch(sFileFormat)    
                        
                    case {'emdata_2.1','emresp_2.1'}
                        
                        % read in x,y,z,azimuth,dip 
                        stCSEM.transmitters(nTxReadin,1:5) = sscanf(sLine,'%g %g %g %g %g');                                                                            
                        sType = char(sscanf(sLine0,'%*g %*g %*g %*g %*g %s'))';
                        stCSEM.transmitterType{nTxReadin} = sType;                         
                        sName = char(sscanf(sLine0,'%*g %*g %*g %*g %*g %*s %s'))';                         
                        stCSEM.transmitterName{nTxReadin} = sName;
                    
                    case {'emdata_2.2','emresp_2.2'}
                        
                        % read in x,y,z,azimuth,dip, length
                        stCSEM.transmitters(nTxReadin,1:6) = sscanf(sLine,'%g %g %g %g %g %g');                                                                            
                        sType = char(sscanf(sLine0,'%*g %*g %*g %*g %*g %*g %s'))';
                        stCSEM.transmitterType{nTxReadin} = sType;                         
                        sName = char(sscanf(sLine0,'%*g %*g %*g %*g %*g %*g %*s %s'))';                         
                        stCSEM.transmitterName{nTxReadin} = sName;                 

                    case {'emdata_2.3','emresp_2.3'} % adds SolveCorr column at end
                        
                        % read in x,y,z,azimuth,dip,length,SolveCorr
                        stCSEM.transmitters(nTxReadin,1:7) = sscanf(sLine,'%g %g %g %g %g %g %g %*s %*s');                                                                            
                        sType = char(sscanf(sLine0,'%*g %*g %*g %*g %*g %*g %*g %s'))';
                        stCSEM.transmitterType{nTxReadin} = sType;                         
                        sName = char(sscanf(sLine0,'%*g %*g %*g %*g %*g %*g %*g %*s %s'))';                         
                        stCSEM.transmitterName{nTxReadin} = sName;     
                 
                        
                    otherwise % older formats
                        
                        % read in x,y,z,azimuth,dip 
                        stCSEM.transmitters(nTxReadin,1:5) = sscanf(sLine,'%g %g %g %g %g');                                                                            
                        sType = char(sscanf(sLine0,'%*g %*g %*g %*g %*g %s'))';
                        stCSEM.transmitterType{nTxReadin} = sType; 
                        stCSEM.transmitterName{nTxReadin} = ' ';
                    end
                    
                 end
                            
            end
            
        case {'# csem time offsets'}
            
            nTimeOffsets = str2double(sValue);

            nReadin = 0;
            stCSEM.timeOffsets = [];
            
            % Now read in the frequencies:
            while nReadin < nTimeOffsets
                 sLine = fgets( fid );

                 [sLine, lComment] = parseLine(sLine);

                 if ~lComment
                     temp = sscanf(sLine,'%g');
                     nReadin = nReadin + length(temp);
                     % 
                     stCSEM.timeOffsets(end+1:nReadin,1) = temp;
                 end

            end     
            
        case {'# tdem waveform points'}
            
            nPtsWaveform = str2double(sValue);

            nReadin = 0;
            stCSEM.tdemWaveform = [];
            
            % Now read in the frequencies:
            while nReadin < 2*nPtsWaveform
                 sLine = fgets( fid );

                 [sLine, lComment] = parseLine(sLine);

                 if ~lComment
                     temp = sscanf(sLine,'%g %g');
                     nReadin = nReadin + length(temp);
                     % 
                     stCSEM.tdemWaveform(end+1,1:2) = temp;
                 end

            end              
            
        case {'# csem frequencies'}
            
            nFreq = str2double(sValue);

            nFreqReadin = 0;
            stCSEM.frequencies = [];
            
            % Now read in the frequencies:
            while nFreqReadin < nFreq
                 sLine = fgets( fid );

                 [sLine, lComment] = parseLine(sLine);

                 if ~lComment
                     temp = sscanf(sLine,'%g');
                     nFreqReadin = nFreqReadin + length(temp);
                     % 
                     stCSEM.frequencies(end+1:nFreqReadin,1) = temp;
                 end

            end     
 
            

         case {'# csem receivers'}
             
            nRxCSEM = str2double(sValue);
            
            nRxReadin = 0;
            stCSEM.receivers = zeros(nRxCSEM,8); % x,y,z,theta,alpha,beta,length,SolveCorr
            % 
            while nRxReadin < nRxCSEM
                 sLine0 = fgets( fid );

                 [sLine, lComment] = parseLine(sLine0);

                 if ~lComment
                    
                    nRxReadin = nRxReadin + 1;
                    stCSEM.receiverName{nRxReadin} = num2str(nRxReadin); % initialize to site number, overwritten if name given  
                    
                    switch(sFileFormat)
                    case {'emdata_2.0','emresp_2.0'}

                        temp = sscanf(sLine,'%g',6);   
                        stCSEM.receivers( nRxReadin,1:6) = temp;
                        
                    case {'emdata_2.1','emresp_2.1'}
                         
                        temp = sscanf(sLine,'%g',6);  
                        stCSEM.receivers( nRxReadin,1:6) = temp; 
                        sName = char(sscanf(sLine0,'%*g %*g %*g %*g %*g %*g %s'))';
                        if ~isempty(sName)
                            stCSEM.receiverName{nRxReadin}         = sName; 
                        end

                    case {'emdata_2.2','emresp_2.2'}
                         
                        temp = sscanf(sLine,'%g',7); %x y z theta alpha beta length  
                        stCSEM.receivers( nRxReadin,1:7) = temp; 
                        sName = char(sscanf(sLine0,'%*g %*g %*g %*g %*g %*g %*g %s'))';
                        if ~isempty(sName)
                            stCSEM.receiverName{nRxReadin}         = sName; 
                        end
                        
                    case {'emdata_2.3','emresp_2.3'} % adds SolveCorr column  
                         
                        temp = sscanf(sLine,'%g %g %g %g %g %g %g %g',8); %x y z theta alpha beta length correctionFlag  *name
                        stCSEM.receivers( nRxReadin,1:8) = temp; 
                        sName = char(sscanf(sLine0,'%*g %*g %*g %*g %*g %*g %*g %*g %s'))';
                        if ~isempty(sName)
                            stCSEM.receiverName{nRxReadin}         = sName; 
                        end   
                        
                    end 
                    
                 end

            end  
            
         case {'csem receiver names'} % legacy code to support older format....
           
            % only for 2.0 format...
            
            stCSEM.receiverName = cell(nRxCSEM,1);
     
            % initialize to site number:
            for i = 1:nRxCSEM
               stCSEM.receiverName{i} = num2str(i);
            end
            
            nRxReadin = 0;

          
            while nRxReadin < nRxCSEM
                 sLine = fgets( fid );

                 [sLine, lComment] = parseLine(sLine);

                 if ~lComment
                    
                    nRxReadin = nRxReadin + 1;
                    stmp = strtrim(sLine);
                    stCSEM.receiverName{nRxReadin} = stmp;
                    
                 end

            end   
            
        case {'# mt frequencies'}
            
            nFreq = str2double(sValue);

            nFreqReadin = 0;
            stMT.frequencies = zeros(nFreq,1);
            
            % Now read in the frequencies:
            while nFreqReadin < nFreq
                 sLine = fgets( fid );

                 [sLine, lComment] = parseLine(sLine);

                 if ~lComment
                     temp = sscanf(sLine,'%g');
                     
                     % 
                     stMT.frequencies(nFreqReadin+[1:length(temp)]) = temp;
                     nFreqReadin = nFreqReadin + length(temp);
                 end

            end     
 
            

         case {'# mt receivers'}
             
            nRxMT = str2double(sValue);
            
            nRxReadin = 0;
            stMT.receivers = zeros(nRxMT,6);
            stMT.receiverName =  cell(nRxMT,1); 
             
            
            % 
            while nRxReadin < nRxMT
                 sLine0 = fgets( fid );

                 [sLine, lComment] = parseLine(sLine0);
                
                 if ~lComment
                     
                     nRxReadin = nRxReadin + 1;
                    
                    stMT.receiverName{nRxReadin} = num2str(nRxReadin); % initialize to site number, overwritten if name given  
                    switch(sFileFormat)
                        
                    case {'emdata_2.0','emresp_2.0'}

                        temp = sscanf(sLine,'%g',6);            
                        stMT.receivers( nRxReadin,1:6) = temp;
                        stMT.receivers( nRxReadin,7)   = 0; % no static option in older format
                        
                         
                    case {'emdata_2.1','emresp_2.1'}
                         
                        sType = char(sscanf(sLine0,'%*g %*g %*g %*g %*g %*g %*g %s'))';
                        if ~isempty(sType)
                            stMT.receiverName{nRxReadin}         = sType; 
                        end
                        temp = sscanf(sLine,'%g',7);   
                        stMT.receivers( nRxReadin,1:7) = temp; 
                        
                    
                    case {'emdata_2.2','emdata_2.3','emresp_2.2','emresp_2.3'}
                         
                        temp = sscanf(sLine,'%g',8); %x y z theta alpha beta iSolvestatic length  
                        stMT.receivers( nRxReadin,1:8) = temp; 
                        sName = char(sscanf(sLine0,'%*g %*g %*g %*g %*g %*g %*g %*g %s'))';
                        if ~isempty(sName)
                            stMT.receiverName{nRxReadin}         = sName; 
                        end
                    end              
                    
                 end

            end  
            
         case {'mt receiver names'}
            
             % only for 2.0 format...
            stMT.receiverName = cell(nRxMT,1);

            nRxReadin = 0;

          
            while nRxReadin < nRxMT
                 sLine = fgets( fid );

                 [sLine, lComment] = parseLine(sLine);

                 if ~lComment
                    
                    nRxReadin = nRxReadin + 1;
                    stmp = strtrim(sLine);
                    stMT.receiverName{nRxReadin} = stmp;
                    
                 end

            end   
        
        %
        % DC resistivity inputs:    
        %
        case {'# dc transmitter electrodes'}
            
            nTxE = str2double(sValue);
            
            stDC.tx_electrodes = zeros(nTxE,3);
           
            nRead = 0;
            while nRead < nTxE
                 sLine0 = fgets( fid );
                 [sLine, lComment] = parseLine(sLine0);
                 if ~lComment
                    nRead = nRead + 1;     
                    stDC.tx_electrodes( nRead,1:3) = sscanf(sLine,'%g',3);
                 end
            end  
                        
            
        case {'# dc transmitters'}
            
            nTx = str2double(sValue);
            
            stDC.transmitters = zeros(nTx,2);
           
            nRead = 0;
            while nRead < nTx
                 sLine0 = fgets( fid );
                 [sLine, lComment] = parseLine(sLine0);
                 if ~lComment
                    nRead = nRead + 1;     
                    stDC.transmitters( nRead,1:2) = sscanf(sLine,'%i',2);
                 end
            end         
            
        case {'# dc receiver electrodes'}
            
            nRxE = str2double(sValue);
            
            stDC.rx_electrodes = zeros(nRxE,3);
           
            nRead = 0;
            while nRead < nRxE
                 sLine0 = fgets( fid );
                 [sLine, lComment] = parseLine(sLine0);
                 if ~lComment
                    nRead = nRead + 1;     
                    stDC.rx_electrodes( nRead,1:3) = sscanf(sLine,'%g',3);
                 end
            end  
        
        
        case {'# dc receivers'}

            nRx = str2double(sValue);
            
            stDC.receivers = zeros(nRx,2);
           
            nRead = 0;
            while nRead < nRx
                 sLine0 = fgets( fid );
                 [sLine, lComment] = parseLine(sLine0);
                 if ~lComment
                    nRead = nRead + 1;     
                    stDC.receivers( nRead,1:2) = sscanf(sLine,'%i',2);
                 end
            end  


        case {'# data','#data'}
            
            % First allocate the data arrays:
            
            
            nData= str2double(sValue);

            nDataReadin = 0;
            if strcmpi(sFileType,'data')
                nColumns = 6;
            elseif  strcmpi(sFileType,'response')
                nColumns = 8;
            end
            DATA = zeros(nData,nColumns);

          
            fposData = ftell(fid);
            
            lGood = false;
            try % fast read
                
                %skip comment line:
                sLine = fgets( fid );
                
                % then read data:
                [DATA,count] = fscanf(fid,'%g',[nColumns nData]);
                DATA = DATA';
                
                if count == nData*nColumns
                    lGood = true;
                
                else % try reading without skipping comment line:
                    fseek(fid,fposData,'bof');
                    [DATA,count] = fscanf(fid,'%g',[nColumns nData]);
                    DATA = DATA';
                    if count == nData*nColumns
                        lGood = true;
                    end
                    
                end
                
            end
               
            if ~lGood % as a backup try a slow read where each line is parsed for any comment text:
                
                % rewind:
                fseek(fid,fposData,'bof');
                
                while nDataReadin < nData
                     sLine = fgets( fid );

                     [sLine, lComment] = parseLine(sLine);

                     if ~lComment

                         nDataReadin = nDataReadin + 1;
                         DATA(nDataReadin,:) =  sscanf(sLine,'%g');

                     end

                end  
            end
            
            break
             
            
        otherwise % ignore other fields since they're not needed for ploting

       
        
        end % switch
    end % while

    % Close file:
    fclose(fid);

    if ~isempty(stCSEM) && ~isfield(stCSEM,'reciprocityUsed')     
        stCSEM.reciprocityUsed = [];
    end
    
    % Create output:
    if nargout == 1 % new way to call code with single strucutre output:
        st.stUTM  = stUTM;
        st.stCSEM = stCSEM;
        st.stMT   = stMT;
        st.stDC   = stDC;
        st.DATA   = DATA;
        st.dataFile = fileName;
        
        varargout{1} = st;
        
    elseif nargout == 4 % old way before code supported DC resistivity:
        varargout{1} = stUTM;
        varargout{2} = stCSEM;
        varargout{3} = stMT;
        varargout{4} = DATA;    
    end
    
end
    
%--------------------------------------------------------------------------    
function  [sLine lComment] = parseLine(sLine)
%--------------------------------------------------------------------------  
%
% Function to identify whether a line is a comment or not.
% Also strips off comments at end of a line of data.
%
% Kerry Key
% Scripps Institution of Oceanography
%
%-------------------------------------------------------------------------
    lComment = false;
    
    sLine = strtrim(sLine);
    if isempty(sLine)
        lComment = true;
        return
    end
    
    for iFrom = 1:length(sLine)
        if ~strcmp(sLine(iFrom),' ')
            break 
        end
    end
    sLine = sLine(iFrom:end);
    %sLine = strjust(sLine,'left');  % this one liner is cleaner, but the iFrom stuff above is faster, go figure...
    
    iFrom = 1;
    % Test to see if line is a comment
    if iFrom > length(sLine) || strcmp(sLine(iFrom),'%') || strcmp(sLine(iFrom),'!') || all(sLine == ' ') || isempty(sLine)
        lComment = true;
        return
    end
    
    % Trim off any comments at the end:
    iTo = length(sLine);
    iFrom = strfind(sLine,'%');
    if ~isempty(iFrom) && iFrom(1) < iTo
        sLine(iFrom:iTo) = '';
    end
     iTo = length(sLine);
    iFrom = strfind(sLine,'!');
    if ~isempty(iFrom) && iFrom(1) < iTo
        sLine(iFrom:iTo) = '';
    end   
    
    % finally, convert an 1d12 type numbers to 1e12:
    sLine = strrep(sLine,'d','e');
    
     
end