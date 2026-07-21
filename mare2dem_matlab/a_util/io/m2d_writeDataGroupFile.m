% function  m2d_writeDataGroupFile(outputFileName,st) 
% 
% Utility function to write out an EMDataGroup_1.0 format file used by the
% MARE2DEM code
%
% This is an optional file that can be used to bin data into groups for set
% data weights used in joint inversion of multiple EM data types, or to
% balance the same data types when there is a larger volume of data for
% e.g. towed CSEM than seafloor CSEM. 
%               
%
% Input arguments:
%
% outputFilename            :: String containing the full name and path of 
%                              the file to  write out. Typically this is 
%                              something like 'line2b.emdata_group'.
%
% st is a structure with the fields:
% 
% st.comment                   :: Any string of text you want added to the
%                              second line of the data file. (optional)
%
% st.groupNames               :: cell array of strings to use for group
%                                names. e.g. {'MT', 'seafloor CSEM', 'Vulcans'}
%
% st.groupIndices             :: array of integers specifying group indices
%                                for each datum. This list must have the
%                                same length as the number of data given in
%                                the corresponding data file. Values must
%                                be in the range of 1:length(st.groupNames).
%


function  m2d_writeDataGroupFile(varargin)


if nargin <= 1
    h = errordlg('Error: not enough inputs to m2d_writeDataGroupFile. Try again.','m2d_writeDataGroupFile.m Error');
    waitfor(h);
    return;
end
 
outputFileName = varargin{1};
st = varargin{2};

%  
% Create the output Data group file:
%

fid = fopen(outputFileName,'w');

% denote format:
fprintf(fid,'Format:  EMDataGroup_1.0\n');

% Print comment line:
if isfield(st,'comment') && ~isempty(st.comment)
    fprintf(fid,'!%s\n', st.comment);
end

% Print group names:
if isfield(st,'groupNames') && ~isempty(st.groupNames)

    fprintf(fid,'# groups:    %i\n',length(st.groupNames));
    for i = 1:length(st.groupNames)
      fprintf(fid,'%s\n',st.groupNames{i});
    end
 
else
    error('Input structure needs st.groupNames field!')
end

% Print group indices
if isfield(st,'groupIndices') && ~isempty(st.groupIndices)

    % Check to make sure all indices agree with number of names:
    if max(st.groupIndices) > length(st.groupNames)
 
        fprintf('# groups:    %i\n',length(st.groupNames));
        fprintf('Max(groupIndices): %i\n',max(st.groupIndices))
        
        error('Group indices exceed the number of input group names! ')
    end
    if min(st.groupIndices) < 1
        error('Group indices need to be greater than 0! ')
    end    

    % Now write out values:

    fprintf(fid,'# data:    %i\n',length(st.groupIndices));
    fprintf(fid,'%g\n',st.groupIndices);
    
 
else
    error('Input structure needs st.groupIndices field!')
end

% All done, let's close the file:
    fclose(fid);
    return;

end