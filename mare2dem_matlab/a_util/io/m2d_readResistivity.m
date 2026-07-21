function Resistivity = m2d_readResistivity(file,bNoData)
%
%
% Reads in a MARE2DEM *.resistivity file
%
% Kerry Key
% Scripps Institution of Oceanography
% University of California, San Diego
%
%
% KK 30 July 2013 - Added support for new MARE2DEM_1.1 format
%
% DGM 6/28 - added optional param to only read settings and not data. Some of
% these files get really large and if all you want is the header, this makes it
% a LOT faster.

    if ~exist('bNoData','var') || isempty(bNoData)
        bNoData = false;
    elseif ischar(bNoData)
        bNoData = strncmpi( bNoData, 'n', 1 );  % for string "No Data" and such
    end

  %  fprintf('\n%-32s %s\n','Reading Resistivity file:',file)
    
    Resistivity = [];
    Resistivity.sDataGroupFile = [];
    Resistivity.sJointInvWeightType = []; 
    
    Resistivity.boundsTransform = [];
    Resistivity.globalBounds = [];
    Resistivity.convergeSlowly = [];
    Resistivity.globalBounds = [];
    
    Resistivity.sRoughnessPenaltyMethod = [];
    Resistivity.yzPenaltyWeights = [];
    Resistivity.penaltyCutWeight = [];
    Resistivity.bRoughnessWithPrejudice = false;
    Resistivity.betaMGS = 0;
    Resistivity.anisotropyPenaltyWeight = [];
    Resistivity.anisotropyRatioRoughnessWeight = [];
   
    fid = fopen(file,'r');
    
    while ~ feof(fid)
        
        % Get Code : Value pairs:
        
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
                Resistivity.version = sValue;
            case {'model file','poly file'}
                Resistivity.polyFile = sValue;
            case {'data file'}
                Resistivity.dataFile = sValue;

            case 'data group file'
                Resistivity.sDataGroupFile = strtrim(lower(sValue));
            case 'joint inversion weight'
                Resistivity.sJointInvWeightType = strtrim(lower(sValue));

            case {'settings file'}    
                Resistivity.settingsFile = sValue;
            case {'penalty file'}   
                Resistivity.penaltyFile = sValue;  % depracated nov 2020, but leaving here for backwards compatibility
            case {'maximum interations'}       
                Resistivity.maxIterations = sscanf(sValue,'%g',1);
            case {'bounds transform'}
                Resistivity.boundsTransform = sValue;
            case {'global bounds'}   
                ind = findstr(sValue,',');
                if ~isempty(ind) % replace comma with space
                    sValue(ind) = ' ';
                end
                Resistivity.globalBounds = sscanf(sValue,'%g %g',2);
            case {'roughness penalty method'}     
                Resistivity.sRoughnessPenaltyMethod = sValue;
            case {'roughness weights (y,z)'}  
                ind = findstr(sValue,',');
                if ~isempty(ind) % replace comma with space
                    sValue(ind) = ' ';
                end
                Resistivity.yzPenaltyWeights = sscanf(sValue,'%g %g',2);
            case {'penalty cut weight'}  
                Resistivity.penaltyCutWeight = sscanf(sValue,'%g',1);
            case {'roughness with prejudice'}      
                switch sValue
                    case 'yes'
                        Resistivity.bRoughnessWithPrejudice = true;
                    otherwise
                        Resistivity.bRoughnessWithPrejudice = false;     
                end
            case {'min. gradient support weight'}  
                Resistivity.betaMGS = sscanf(sValue,'%g',1);    
            case {'aniso. penalty weight'}
                Resistivity.anisotropyPenaltyWeight = sscanf(sValue,'%g',1);
            case {'aniso. ratio roughness weight'}
                Resistivity.anisotropyRatioRoughnessWeight = sscanf(sValue,'%g',1);
            case {'debug level','print level'}
                Resistivity.debugLevel = sscanf(sValue,'%i',1);
            case {'target misfit'}    
                Resistivity.targetMisfit = sscanf(sValue,'%g',1);
            case {'iteration'}  
                Resistivity.iteration = sscanf(sValue,'%i',1);
            case {'lagrange value','log10 lagrange value'}     
                Resistivity.log10lagrange =  sscanf(sValue,'%g',1);
            case {'model roughness'}  
                Resistivity.roughness =  sscanf(sValue,'%g',1);
            case {'model misfit'}   
                Resistivity.misfit =  sscanf(sValue,'%g',1);
            case {'date/time'}
                Resistivity.dateAndTime =  sValue;
            case {'inversion method'}
                Resistivity.inversionMethod =  lower(sValue);  
            case {'fixed mu cut'}   
                Resistivity.fixedMuCut =  sscanf(sValue,'%g',1);     
            case {'converge slowly'}    
                Resistivity.convergeSlowly = lower(sValue); 
            case {'misfit decrease threshold'}    
                Resistivity.rmsThreshold = sscanf(sValue,'%g',1);            
            case {'anisotropy'} 
                Resistivity.anisotropy = sValue;
            case {'number of regions'}     
                if bNoData  % nothing follows this but data. skip it.
                    break;
                end
                
                Resistivity.numRegions = sscanf(sValue,'%i',1);
               
                switch Resistivity.anisotropy
                    case 'isotropic'
                        nrho = 1;
                        str ='%g';
                    case 'isotropic_ip' % Cole-Cole model
                        nrho = 4;
                        str ='%g%g%g%g';
                    case 'triaxial'
                        nrho = 3;
                        str ='%g%g%g';
                    case {'tix', 'tiy', 'tiz','isotropic_complex','tiz_ratio'}
                        nrho = 2;   
                        str ='%g%g';
                end
                scstr = sprintf('%s%s%s%s%s%s','%*i',str,str,str,str,str,str); %rho,param#,lower,upper,prej,prej_weight
                
                Resistivity.resistivity   = zeros(Resistivity.numRegions,nrho);
                Resistivity.freeparameter = zeros(Resistivity.numRegions,nrho);
                Resistivity.prejudice     = zeros(Resistivity.numRegions,2*nrho);
                Resistivity.bounds        = zeros(Resistivity.numRegions,2*nrho);

                sLine = fgets(fid); % a comment line
 
                
% Slow:                
%                 for i = 1:Resistivity.numRegions
%                      sLine = fgets(fid);       
%                      vals = sscanf(sLine,scstr);
%                      Resistivity.resistivity(i,1:nrho)   = vals(1:nrho);
%                      Resistivity.freeparameter(i,1:nrho) = vals(nrho+[1:nrho]);
%                      Resistivity.bounds(i,1:2*nrho)      = vals(2*nrho+[1:2*nrho]);
%                      Resistivity.prejudice(i,1:2*nrho)   = vals(4*nrho+[1:2*nrho]);

%                 end
% Fast for large files:
                vals = fscanf(fid,'%g');
                vals = reshape(vals,length(vals)/Resistivity.numRegions,Resistivity.numRegions)';         
                Resistivity.resistivity(:,1:nrho)   = vals(:,1+[1:nrho]);
                Resistivity.freeparameter(:,1:nrho) = vals(:,1+nrho+[1:nrho]);
                Resistivity.bounds(:,1:2*nrho)      = vals(:,1+2*nrho+[1:2*nrho]);
                Resistivity.prejudice(:,1:2*nrho)   = vals(:,1+4*nrho+[1:2*nrho]);
                       
            case 'maximum iterations'
                 
            otherwise
                fprintf('Ignoring uninterpretable line in .resistivity file: \n %s\n',sCode)
            
        end
    end
    
   
    fclose(fid);
    
end