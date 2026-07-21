% function st = m2d_readDataGroupFile(fileName) 
%
% Utility function to read EMDataGroup_1.0 format file used by the
% MARE2DEM code
%
%
% See m2d_writeDataGroupFile for a description of the fields in structure st. 
%
function st = m2d_readDataGroupFile(fileName, bSilent )
 
st = [];

%   
% Open the file and check the version:
%

    fid = fopen(fileName,'r');
    
    if fid < 0
        h = errordlg(sprintf('Error opening file: %s \n File not found!',fileName),'m2d_readDataGroupFile.m Error');
        waitfor(h);    
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
                case {'emdatagroup_1.0'}
            otherwise
                if ~bSilent
                    h = errordlg(sprintf('Unsupported format: %s',sFileFormat),'m2d_readDataGroupFile.m Error');
                    waitfor(h);
                end
                fclose(fid);    
                return;
            end 

      
        case {'# groups'}
            
            nGroups = str2double(sValue);
            st.groupNames = cell(nGroups);

            nRead = 0;
           % Now read in the group names:
            while nRead < nGroups
                 sLine0 = fgets( fid );
                 
                 [sLine, lComment] = parseLine(sLine0);
                 
                 if ~lComment
                 
                    nRead = nRead + 1;
   
                    st.groupNames{nRead} = sLine;
                       
                 end
                            
            end
 

        case {'# data','#data'}
            
   
            nData = str2double(sValue);
 
            %skip comment line:
            sLine = fgets( fid );
            
            % then read data:
            [st.groupIndices,count] = fscanf(fid,'%g',nData);
                
        otherwise % ignore other fields since they're not needed 

        
        end % switch
    end % while

    % Check that indices don't exceed number of group names:
    if max(st.groupIndices) > length(st.groupNames)
 
        fprintf('# groups:    %i\n',length(st.groupNames));
        fprintf('Max(groupIndices): %i\n',max(st.groupIndices))
        
        error('Group indices exceed the number of input group names! ')
    end

    if min(st.groupIndices) < 1
        error('Group indices need to be greater than 0! ')
    end

    % Close file:
    fclose(fid);
    
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