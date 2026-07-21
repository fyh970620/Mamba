function MARE2DEM_Memory_Predictor(varargin)
% MARE2DEM_Memory_Predictor(sModelFile,nNodes,nCoresPerNode)
% predicts the memory MARE2DEM will use to compute EM responses for the
% data and model referred to in file sModelFile, when run on nNodes with
% nCoresPerNode. 
%
% Alternatively, you can call this routine with the number of free model
% parameters (nParams) and number of data (nData) explicitly provided:
%
% MARE2DEM_Memory_Predictor(nParams,nData,nNodes,nCoresPerNode)
%
% This can be useful for understanding how large of a model and data set
% a given cluster setup can handle.
%
% Note that the total number of processing cores is nNodes*nCoresPerNode.
%
% This function is valid only for MARE2DEM version 24 May 2015
%
% Kerry Key
% Scripps Institution of Oceanography
%

% Sigsbee joint anisotropic inversion example:
% nData   = 61434;  
% nParams = 48816;
% nNodes   =  10;
% nCoresPerNode = 16;
 
% CSEM+MT Demo example
% nData   = 2630; 
% nParams = 8480;
% nNodes   =  1;
% nCoresPerNode = 4;
 

fprintf('\n%20s\n',   '---------- MARE2DEM Memory Usage Predictor ------------' )
fprintf('\n%20s\n',   '!!!!! Only valid for MARE2DEM version: 24 May 2015 !!!!' )


if nargin == 3 && isstr(varargin{1})
    sModelFile    = varargin{1};
    nNodes        = varargin{2};  
    nCoresPerNode = varargin{3};  

    % Read in model file:
    fprintf('\n%20s %s\n','Reading model file:',sModelFile);
    
    stResistivity = m2d_readResistivity(sModelFile);
    p = fileparts(sModelFile);
    nParams = max(stResistivity.freeparameter(:));

    % Read in data file:
    fprintf('%20s %s\n','Reading data file:',stResistivity.dataFile);
    [~,~,~,DATA] = m2d_readEMData2DFile(fullfile(p,stResistivity.dataFile), true);
    nData = size(DATA,1);

elseif nargin == 4
    nParams       = varargin{1};
    nData         = varargin{2};  
    nNodes        = varargin{3};  
    nCoresPerNode = varargin{4};  
else
    beep;
    disp('Error arguments to function MARE2DEM_Memory_Predictor')
    return
end
    



%-----------------
nbuser = 64;

nProc = nNodes*nCoresPerNode;
 
% --------------------------------
% get scalapack grid setup:
[nprow, npcol] = gridsetup(nProc);

% get optimal block size for the matrix:
nb = blockset( nbuser, nData,nParams, nprow, npcol);

for i =1:nprow
    for j = 1:npcol
        l_wj_nRow(i,j)  = numroc(nData,  nb,i-1,0,nprow);
        l_wj_nCols(i,j) = numroc(nParams,nb,j-1,0,npcol);

        l_wjtwj_nRow(i,j)  = numroc(nParams,nb,i-1,0,nprow);
        l_wjtwj_nCols(i,j) = numroc(nParams,nb,j-1,0,npcol);
    end
end


%-----------------------------------------


% Memory:
mem_WJ    = nData*nParams*8; %bytes
mem_WJTWJ = nParams^2*8; %bytes

mem_WJ_loc_Max = max(max(l_wj_nRow.*l_wj_nCols))*8;
mem_WJ_loc_Min = min(min(l_wj_nRow.*l_wj_nCols))*8;

mem_WJTWJ_loc_Max = max(max(l_wjtwj_nRow.*l_wjtwj_nCols))*8;
mem_WJTWJ_loc_Min = min(min(l_wjtwj_nRow.*l_wjtwj_nCols))*8;

% Display results:

fprintf('\n%20s\n', 'Configuration:' )
fprintf('\n%20s %i\n','# data:',nData)
fprintf('%20s %i\n','# params:',nParams)
fprintf('%20s %i\n','# of nodes:',nNodes)
fprintf('%20s %i\n','# of cores/node:',nCoresPerNode)
fprintf('%20s %i\n','total processors:',nProc)
fprintf('%20s %i x %i\n','Processor grid:',nprow,npcol)

fprintf('\n%20s\n',' Occam Arrays and Memory Requirements:')
fprintf('\n%32s %s\n',' Distributed WJ size:')
fprintf('%i x %i\n',max(max(l_wj_nRow)),max(max(l_wj_nCols)))

fprintf('%32s %s\n',' Distributed WJTWJ size:')
fprintf('%i x %i\n',max(max(l_wjtwj_nRow)),max(max(l_wjtwj_nCols)))

% fprintf('\n%32s %s\n',' ','     GB:')
% fprintf('%32s %8.2g\n','WJ:',mem_WJ/1024^3);
% %fprintf('%20s %8.2g\n','WJTWJ:',mem_WJTWJ/1024^3); 
% 
% fprintf('%32s %8.3g\n','Distributed WJ (max):',mem_WJ_loc_Max/1024^3); 
% %fprintf('%20s %8.3g\n','WJ_loc min',mem_WJ_loc_Min/1024^3); 
% 
% fprintf('%32s %8.3g\n','Distributed WJTWJ (max):',mem_WJTWJ_loc_Max/1024^3);
% %fprintf('%20s %8.3g\n','WJTWJ_loc min',mem_WJTWJ_loc_Min/1024^3);  

mem_Fudge = 1.7; % accounts for current code's field arrays viz "d"
fprintf('\n%38s %8.3g %s\n','Max memory needed by manager process:',(mem_WJ)/1024^3*mem_Fudge ,'GB'); 
fprintf('%38s %8.3g %s\n','Max memory needed by worker process:',(mem_WJTWJ_loc_Max*2)/1024^3,'GB');  

fprintf('%38s %8.3g %s\n','Total memory per worker node:',(mem_WJTWJ_loc_Max*2)*nCoresPerNode/1024^3,'GB');  

fprintf('\n%20s\n',' Finite Element Code Memory Needs (not coded):')
fprintf('\n%32s\n',' Generally about 100-500 MB for meshes with')
fprintf('%32s\n\n\n',' 10,000-100,000 nodes.')
end

%-----------------------------------------
% scalapack grid setup:

function [nprow, npcol] = gridsetup(nProc)

sqrtnp = floor( sqrt( (nProc) ) + 1 );
for i=1:sqrtnp
    if(mod(nProc,i) == 0) 
        nprow = i;
    end
end 

npcol = nProc/nprow;
end

function nb = blockset( nbuser, m,n, nprow, npcol)
% !
% !     This subroutine try to choose an optimal block size
% !     for the distributed matrix.
% !
% !     Written by Carlo Cavazzoni, CINECA
% !
%       integer :: m, n
%       integer nb, nprow, npcol, nbuser
%  
      nb = floor(min ( [m/nprow n/npcol]));
      if nbuser > 0
        nb = min ( [nb nbuser] );
      end
      nb = max([nb 1]);
end

function  nout = numroc( N, NB, IPROC, ISRCPROC, NPROCS)

       MYDIST = mod( NPROCS+IPROC-ISRCPROC, NPROCS );
  
       NBLOCKS = floor(N / NB);
% *
% *     Figure the minimum number of rows/cols a process can have
% *
      NUMROC = floor(NBLOCKS/NPROCS) * NB;
% *
% *     See if there are any extra blocks
% *
       EXTRABLKS = mod( NBLOCKS, NPROCS );
% *
% *     If I have an extra block
% *
       if MYDIST < EXTRABLKS 
           NUMROC = NUMROC + NB;
% *
% *         If I have last block, it may be a partial block
% *
       elseif  MYDIST == EXTRABLKS 
           NUMROC = NUMROC + mod( N, NB );
       end
       
       nout = NUMROC;
end
