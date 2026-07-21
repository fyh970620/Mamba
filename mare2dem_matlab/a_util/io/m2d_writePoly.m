function  m2d_writePoly(sFile,nodes,segments,holes,attributes)
%
% Writes a .poly PSLG file of the same format used for J Shewchuk's
% Triangle.c code.
%
% Inputs:
%
% nodes(x,y)
% segments(inode1,inode2,boundaryMarkers)
% holes(x,y)
% attributes(x,y,att,areaConstraint)
%
%
% Kerry Key
% Scripps Institution of Oceanography
%

 
fid = fopen(sFile,'W');

% Nodes:
nnodes = size(nodes,1);
nbdmarks = size(nodes,2)-2;
fprintf(fid,'%i 2 0 %i\n',nnodes,nbdmarks);
 
for i = 1:nnodes
    fprintf(fid,'%i %.16g %.16g %.16g %.16g',i,nodes(i,:));   
    fprintf(fid,'\n');
end

% Segments:
nsegs = size(segments,1);
nbdmarks = size(segments,2)-2;  
%  fprintf(fid,'# SEGMENTS: \n');
fprintf(fid,'%i %i \n',nsegs,nbdmarks); % #segs, #boundary markers
for i = 1:nsegs
    fprintf(fid,'%i ',i,segments(i,:));
    fprintf(fid,'\n');
end
 
% Holes:
nHoles = size(holes,1);
fprintf(fid,'%i\n',nHoles);
if nHoles > 0
    for i = 1:nHoles
        fprintf(fid,'%i %.16g %.16g\n',i,holes(i,:));    
    end
end

% Attribute and Area contraints:
fprintf(fid,'%i\n',size(attributes,1));
for i = 1:size(attributes,1)
    fprintf(fid,'%i %.16g %.16g %g %g\n',i, attributes(i,:) );  
end
 
% Close file
fclose(fid);

end