function m2d_mergeDataFiles(cFilesToMerge,sOutputFileName,varargin)
% m2d_mergeDataFiles(cFilesToMerge,sOutputFileName) merges two or more
% MARE2DEM data files into a single file. This is typically used for
% creating a file for joint inversion of MT and CSEM data after running
% separate inversion of each data type. But this routine has no
% restrictions and simply merges *all* the files in input cell array
% cFilesToMerge.
%
% Arguments:
%
%   cFilesToMerge - cell array of the files to merge. Include the full or
%                   relative path in the file names if they're not in the
%                   directory you call this function from. 
% 
%                   Example:
%                   cFilesToMerge = {'mt.emdata','csem.emdata','mt2.emdata'}
% 
%   sOutputFileName - name (optionally inlcuding the path) of the file to
%                     save the merged data to. Example: 'mt_csem.emdata'.
%
%  bKeepDuplicateRx - (optional) Set to true to keep duplicate receivers.
%                     This is useful for synthetic towed streamer data 
%                     where Rx locations are duplicated as array moves down
%                     the profile. 
%
% Notes:
%
%       If the data files contain the optional UTM position and 2D strike
%       azimuth (which are only used for external plotting), then ALL files
%       must have the exact same UTM position and azimuth.
%
%       When merging data of like type (MT, CSEM etc) this routine will
%       look for common receivers (and transmitters) and blend them
%       together, so that the resulting merged data file will not have any
%       duplicate receivers of a given type. 
%
%
%  *** Does NOT yet handle DC resistivity data files ***
%
% Kerry Key 
% Lamont-Doherty Earth Observatory
% BlueGreen Geophysics
%   

if length(cFilesToMerge) < 2
    str = sprintf('Need at least two files for merging. \n\n Try again bucko!');
    hErr = errordlg(str,'m2d_mergeDataFiles Error','modal');
    waitfor(hErr)
    return
end

bKeepDuplicateRx = false;
if nargin > 2
    bKeepDuplicateRx = varargin{1};
end

% Read in the first file:
stOut = m2d_readEMData2DFile(cFilesToMerge{1});

for i = 2:length(cFilesToMerge)
    
    % Read next file:
    st = m2d_readEMData2DFile(cFilesToMerge{i});
    
    % Check for DATA array:
    if isempty(st.DATA)
        str = sprintf('Error with data file %s.\n No data present in the file!\n\n Try again bucko!',cFilesToMerge{i});
        hErr = errordlg(str,'m2d_mergeDataFiles Error','modal');
        waitfor(hErr)
        return
    end    

    % Check that the UTM0 and 2D strike are identical:
    if  st.stUTM.north0 ~= stOut.stUTM.north0 || ...
        st.stUTM.east0  ~= stOut.stUTM.east0  || ...
        st.stUTM.theta  ~= stOut.stUTM.theta 
    
        str = sprintf('Error, disagreement found in the UTM northing or easting or 2D strike angle for the merged files. They must be the same. \n\nTry again bucko!');
        hErr = errordlg(str,'m2d_mergeDataFiles Error','modal');
        waitfor(hErr)
        return
    end

    % Merge it:
    stOut = merge(stOut,st,bKeepDuplicateRx);

end

% Save:
stOut.sComment = sprintf('Merged data file created with m2d_mergeDataFiles.m on %s',datestr(now));
m2d_writeEMData2DFile(sOutputFileName,stOut) 

end

%--------------------------------------------------------------------------
function st1 = merge(st1,st2,bKeepDuplicateRx)
% merges st2 into st1
 
    %
    % MT:
    %
    if isfield(st2,'stMT') && ~isempty(st2.stMT) 
    
        % extract MT data:
        lMT = st2.DATA(:,1) > 100 & st2.DATA(:,1) < 200;
        DATA = st2.DATA(lMT,:);
    
        % Check if MT data not yet present in receiving array:
        if isfield(st1,'stMT') && isempty(st1.stMT) 
    
            % easy insert:
            st1.stMT = st2.stMT;
     
        else  % more complicated merge into existing MT data
    
            % frequencies
            [st1.stMT.frequencies, ind_freq] = mergearrays(st1.stMT.frequencies,st2.stMT.frequencies);
            DATA(:,2) = ind_freq(DATA(:,2));

            % receivers:
            [st1.stMT.receivers, ind_rx] = mergearrays(st1.stMT.receivers,st2.stMT.receivers);
            DATA(:,3) = ind_rx(DATA(:,3));
            DATA(:,4) = ind_rx(DATA(:,4));

           % receiverName:
            st1.stMT.receiverName(ind_rx) = st2.stMT.receiverName;
            
        end

        % Now merge DATA:
        [st1.DATA ,~] = mergearrays(st1.DATA, DATA);

    end

    %
    % CSEM:
    %
    if isfield(st2,'stCSEM') && ~isempty(st2.stCSEM) 
    
        % extract CSEM data:
        lCSEM = st2.DATA(:,1) < 100;
        DATA = st2.DATA(lCSEM,:);
    
        % Check if CSEM data not yet present in receiving array:
        if isfield(st1,'stCSEM') && isempty(st1.stCSEM) 
    
            % easy insert:
            st1.stCSEM = st2.stCSEM;
    
        else  % more complicated merge into existing CSEM data
    
            %  First check phase convention
            if ~strcmpi(st1.stCSEM.phaseConvention,st2.stCSEM.phaseConvention)
                str = sprintf('Sorry, CSEM merge need to use same phase convention. Stopping.');
                hErr = errordlg(str,'m2d_mergeDataFiles Error','modal');
                waitfor(hErr)
                return
            end 
    
             % frequencies
            [st1.stCSEM.frequencies, ind_freq] = mergearrays(st1.stCSEM.frequencies,st2.stCSEM.frequencies);
            DATA(:,2) = ind_freq(DATA(:,2));

            % transmitters

            % need to be careful about respecting transmitterType, so we
            % add in transmittType as boolean in last column
            lType       = cellfun(@(x) all(x == 'edipole'),st1.stCSEM.transmitterType); % binary since either 'edipole' or 'bdipole'
            A           = st1.stCSEM.transmitters;
            A(:,end+1)  = lType;
            
            lType       = cellfun(@(x) all(x == 'edipole'),st2.stCSEM.transmitterType); % binary since either 'edipole' or 'bdipole'
            B           = st2.stCSEM.transmitters;
            B(:,end+1)    = lType;

            [A, ind_tx] = mergearrays(A,B);
            st1.stCSEM.transmitters = A(:,1:end-1);
            lTypeA = logical(A(:,end));

            st1.stCSEM.transmitterType(lTypeA)  = {'edipole'};
            st1.stCSEM.transmitterType(~lTypeA) = {'bdipole'};

            DATA(:,3) = ind_tx(DATA(:,3));
            
            % transmitterName:
            st1.stCSEM.transmitterName(ind_tx) = st2.stCSEM.transmitterName;
 
            % receivers:
            if bKeepDuplicateRx
                ict = size(st1.stCSEM.receivers,1);
                st1.stCSEM.receivers = [st1.stCSEM.receivers;st2.stCSEM.receivers];
                ind_rx = ict+1:size(st1.stCSEM.receivers,1);
                st1.stCSEM.receiverName(ind_rx) = st2.stCSEM.receiverName;
                DATA(:,4) = ind_rx(DATA(:,4));
            else

                [st1.stCSEM.receivers, ind_rx] = mergearrays(st1.stCSEM.receivers,st2.stCSEM.receivers);
                DATA(:,4) = ind_rx(DATA(:,4));
        
                % receiverName:
                st1.stCSEM.receiverName(ind_rx) = st2.stCSEM.receiverName;
            end
        end

        % Now merge DATA:
        [st1.DATA ,~] = mergearrays(st1.DATA, DATA);
 

    end


    %
    % DC: KWK to do
    %
    if isfield(st2,'stDC') && ~isempty(st2.stDC)
        str = sprintf('Sorry, DC data merging not yet supported. Stopping.');
        hErr = errordlg(str,'m2d_mergeDataFiles Error','modal');
        waitfor(hErr)
        return
    
        % Check if DC no present already:
        if isfield(st1,'stDC') && isempty(st1.stDC) 

            % easy insert:
            st1.stCSEM = st2.stCSEM;
            st1.DATA =  [st1.DATA; st2.DATA];
        else
            % KWK: insert DC merge code here
    
        end
    
    end

end

%--------------------------------------------------------------------------
    function [C,IB] = mergearrays(A,B)
% merged B into A returning C. IB is of length(B) with
% mapping of B indices into indices of C
%
% KWK debug: note that union below will remove duplicates in A and that can
% cause unintended side effects the use of mergearrays for Rx and Tx arrays
% with duplicates (like for synhetic modeling of towed receiver arrays with
% even spacings that align as the array moves). Fix TBD...
%
    if iscell(A)
         C = union(A,B,'stable');
         [~,IB] = ismember(B,C);
    else
         C = union(A,B,'stable','rows');
         [~,IB] = ismember(B,C,'rows');
    end
   
    
end


