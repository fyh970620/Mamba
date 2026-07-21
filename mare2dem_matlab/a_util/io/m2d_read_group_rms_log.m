function st = m2d_read_group_rms_log(sFile)

%   
% Open the file

fid = fopen(sFile,'r');

if fid < 0
    h = errordlg(sprintf('Error opening file: %s \n File not found!',sFile),'m2d_read_group_rms_log.m Error');
    waitfor(h);    
    return;
end

% Get header line:

sLine = fgets(fid);

st.headers = strtrim(split(sLine,','));
 
% read data:


st.rmslog = fscanf(fid,'%g',[length(st.headers),inf])';
 
fclose(fid);

end