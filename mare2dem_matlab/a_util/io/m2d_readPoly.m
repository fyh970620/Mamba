%----------------------------------------------------------------------
function [nodes,segments,eles,holes,regions] = m2d_readPoly(file)
%
% Reads in a .poly PSLG file of the same format used for J Shewchuk's
% Triangle.c code.
%
% Kerry Key
% Scripps Institution of Oceanography
%
%
 
% initialize in case these are not read in:
eles    = [];
holes   = [];
regions = [];

% Open PSLG file
fid = fopen(file,'r');

% Read in nodes:
temp    = fscanf(fid,'%i %i %i %i\n',4);
nnodes   = temp(1);

% If nnodes ==0, then nodes are in separate file and a triangulation
% has already been computed.  So let's find the .node file, read it in
% and keep only the boundary nodes:
if nnodes ==0
    [p,n] =fileparts(file);
    filen = fullfile(p,n);
    fid2 = fopen(strcat(filen,'.node'),'r');
    if fid2 < 0;
        disp('error, no nodes defined')
        return
    end
    temp    = fscanf(fid2,'%i %i %i %i\n',4);
    nvert   = temp(1);
    natr    = temp(3);
    nbndmrk = temp(4);
    NODE    = fscanf(fid2,'%g',[ 3+natr+nbndmrk,nvert]);
    nodes   = NODE';
    
    fclose(fid2);
 
    nodes  = nodes(:,2:end);
    
    % READ .ele FILE:
    fid2     = fopen(strcat(filen,'.ele'),'r');
    temp    = fscanf(fid2,'%i %i %i\n',3);
    ntri    = temp(1);
    ndptri  = temp(2);
    natr    = temp(3);
    TRI     = fscanf(fid2,'%g',[1+ndptri+natr,ntri]);
    
    fclose(fid2);
    
    eles = TRI(2:5,:)';

else
    % This is a normal base .poly file
    
    natr    = temp(3);
    nbndmrk = temp(4);
    rstr = [];
    for i = 1:3+natr+nbndmrk
        rstr = sprintf('%s %%g',rstr);
    end
    rstr = strcat(rstr,'\n');
    nodes = fscanf(fid,rstr,[ 3+natr+nbndmrk,nnodes]);
    nodes = nodes(2:3,:)';
    
end

% Segments:
temp = fscanf(fid,'%g %g\n',2);
nsegs = temp(1);
if length(temp)==2
    natr = temp(2);
else
    natr = 0;
end
rstr = [];
for i = 1:3+natr
    rstr = sprintf('%s %%g',rstr);
end
rstr = strcat(rstr,'\n');
segs = fscanf(fid,rstr,[ 3+natr,nsegs]);
segments = segs(2:3+natr,:)';
%segmarkers = segs(4,:)';

% Holes:
nholes = fscanf(fid,'%i\n',1);
if nholes>0
    holes = fscanf(fid,'%i %g %g\n',[3 nholes] );
end

% Constraints
nconst = fscanf(fid,'%g',1);
const= fscanf(fid,'%g %g %g %g %g\n',[ 5,nconst]);
regions = const(2:end,:)';

% Close file:
fclose(fid);

end