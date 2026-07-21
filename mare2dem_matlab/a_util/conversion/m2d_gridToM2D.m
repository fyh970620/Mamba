function m2d_gridToM2D(Y,Z,Rho,paddingY,paddingZ,sFolder,sModelName,sDataFile )
% function  m2d_gridToM2D(Y,Z,Rho,paddingY,paddingZ,sFolder,sModelName,sDataFile )
%
% Function to create a MARE2DEM model from an input 2D grid of values
% (y,z,resistivity). 
%
% Assumes grid is overlain by an air layer. Outer ground padding resisivity
% is assigned to be the mean of the grid's log10 resisivity. 
%
% Inputs:
% 
% Y,Z,Rho - 2D grid of position, depth and resisivity in meters and ohm-m.
%           Y values must vary along the columns and every row is same, whereas 
%           Z values vary by row and each column is the same. Rho(i,j) values
%           are for Z(i),Y(j)
%
%           This code assumes Y,Z are the grid center points so MARE2DEM grid cells
%           are centered about these points using the grid point spacings as cell
%           widths.
% 
% paddingY,paddingZ - padding in meters to add outside the grid. Air is
%                     added above and ground added to the left right and 
%                     below. Ground padding is se to the log10 mean of                              
%                     the grid values.
%
% sFolder         - folder to write files into
%
% sModelName      - name of model to use for all files (without .0.resistivity)
% sDataFile       - name of corresponding data file (e.g. survey.emdata)
%
%
% Kerry Key
% Lamont-Doherty Earth Observatory, Columbia University
% 
% October 2019 - initial version
%

sAnisotropy = 'isotropic';
nrho = 1;


% Given input grid and padding, make nodes, segments and region labels for entire model:
[Nodes,Segs,Regions,Res] = sub_make_Nodes_Segs_Regions(Y,Z,Rho,paddingY,paddingZ);


% Get st strucure for writing .resistivity file:
if ~isempty(sDataFile)
    [~,n,e] = fileparts(sDataFile); % strip of any leading path
else
    n =[];
    e =[];
end

st.dataFile         = sprintf('%s%s',n,e);
st.resistivityFile  = fullfile(sFolder,sprintf('%s.0.resistivity',sModelName));
st.polyFile         = sprintf('%s.poly',sModelName);
st.settingsFile     = 'mare2dem.settings';
st.targetMisfit     = 1.0 ;
 
st.sRoughnessPenaltyMethod        = 'gradient';
st.yzPenaltyWeights               = [3 1];
st.penaltyCutWeight               = 0.1;
st.anisotropyPenaltyWeight        = 0;
st.anisotropyRatioRoughnessWeight = 1;

st.rmsThreshold     = 0.85;
st.lagrange         = 5;
st.roughness        = [];
st.misfit           = []; 
st.anisotropy       = sAnisotropy;
st.resistivity      = zeros(length(Res),nrho);
st.freeparameter    = zeros(length(Res),nrho);
st.bounds           = zeros(length(Res),2*nrho);
st.prejudice        = zeros(length(Res),2*nrho);
st.ratioPrej        = zeros(length(Res),nrho*(nrho-1));
st.numRegions       = length(Res);
st.globalBounds     = 10.^[-1 5];  % Remember, resistivity in files is always given in linear not log scaling.
st.resistivity(:)   = Res;

%
% Save a resistivity file:
%
bOverwrite = true; % we don't care if we are overwritting existing files...
m2d_writeResistivity(st,bOverwrite);

%
% Save Poly file:
%
holes = [];

attributes = [Regions [1:size(Regions,1)]' -1*ones(size(Regions,1),1)];
m2d_writePoly(fullfile(sFolder,st.polyFile),Nodes,Segs,holes,attributes)

 

%
% Make a default mare2dem.settings file:
%
% Create mare2dem.settings file:
%
sFile = fullfile(sFolder,st.settingsFile);

m2d_writeSettingsFile(sFile,1.0,10,10,10,1,1,false);
 
%

%--------------------------------------------------------------------------
function [Nodes,Segs,Regions,Res] = sub_make_Nodes_Segs_Regions(Y,Z,Rho,paddingY,paddingZ)

    dY = diff(Y,1,2);
    dZ = diff(Z,1,1);

    Yc =  [ Y  Y(:,end)] - [ dY(:,1) dY -dY(:,end)]/2;
    Yc(end+1,:) = Yc(end,:);
    Zc =  [ Z; Z(end,:)] - [ dZ(1,:); dZ; -dZ(end,:)]/2;
    Zc(:,end+1) = Zc(:,end);

    nY = size(Yc,2);
    nZ = size(Zc,1);
    Yc = Yc';
    Zc = Zc';

    Nodes = [Yc(:) Zc(:)];

    % make horizontal segments:
    irow = [[1:nY-1]'  [2:nY]' ];

    segs = [];
    for i = 1:nZ % repeat for each Z 
        segs = [segs; irow+nY*(i-1)];
    end

    % make vertical segments:
    icol = [ [1:nY:nY*(nZ-1)]' [nY+1:nY:nY*nZ]'];
    for i = 1:nY % repeat for each Z 
        segs = [segs; icol+(i-1)];
    end
    
        

    % Add boundary box nodes and segments.
    % Also adds segments from top of grid section to model left and right
    % sides. region above assumed to be air
    % so add six nodes counter clockwise from upper left corner of model:
    minY = min(Yc(:));
    maxY = max(Yc(:));
    minZ = min(Zc(:));
    maxZ = max(Zc(:));
    Nodes = [  minY - paddingY minZ - paddingZ;
               minY - paddingY minZ;
               minY - paddingY maxZ + paddingZ;
               maxY + paddingY maxZ + paddingZ;
               maxY + paddingY minZ;
               maxY + paddingY minZ - paddingZ;
               Nodes];
    segs = [ 1 2; 2 3; 3 4; 4 5; 5 6; 6 1;  segs+6];
    segs = [ 2 7; 5 6+nY;  segs];  % connect sides to top of central grid:

    Segs(:,1:2) = segs;
    Segs(:,3) = 1;
    clear segs
    
    % plot check:
    % figure;
    % y0 = Nodes(Segs(:,1),1);
    % y1 = Nodes(Segs(:,2),1);
    % z0 = Nodes(Segs(:,1),2);
    % z1 = Nodes(Segs(:,2),2);
    % plot([y0 y1]',[z0 z1]','-')
    % hold on;
    % plot(Y,Z,'r.');
    % axis ij;
    
    % Make regions labels using cell centers:
    Regions = [reshape(Y',numel(Y),1) reshape(Z',numel(Z),1)];
    
    Res = [reshape(Rho',numel(Rho),1)];   
    
    % Add air and ground padding to region labels and Res array:
    Regions = [Regions; 
               minY - paddingY+.1 minZ - paddingZ+.1; 
               minY - paddingY+.1 minZ+.1];
    
    meanRho = 10.^mean(log10(Rho(:)));  
    Res = [ Res; 1d12; meanRho];    

end

end