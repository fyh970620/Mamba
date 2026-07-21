function  Resistivity = readMARE2DEM_Resistivity(file,bNoData)
%
%
%读取MARE2DEM *.resistivity文件
%

%添加了仅读取设置而不读取数据的可选参数。这些文件中的一些会变得非常大，如果你想要的只是头文件，这会让它变得更快。
    if ~exist('bNoData','var') || isempty(bNoData)
        bNoData = false;
    elseif ischar(bNoData)
        bNoData = strncmpi( bNoData, 'n', 1 );  % 用于字符串“无数据”等
    end

    
    Resistivity = [];
    
    fid = fopen(file,'r');
    
    while ~ feof(fid)
        
     
        
        sLine = fgets( fid );
        [sCode, sValue] = strtok( sLine, ':' );
        sCode = lower(strtrim(sCode));
        if ~isempty(sValue)
         sValue(1) = [];    
        end
        % 如果该值中包含用户注释，则将其删除。
        sValue = strtrim( strtok(sValue, '!%') );
        
        % 我们有什么代码？
        switch (sCode)
            case {'format','version'}
                Resistivity.version = sValue;
            case {'model file'}
                Resistivity.modelFile = sValue;
            case {'data file'}
                Resistivity.dataFile = sValue;
            case {'settings file'}    
                Resistivity.settingsFile = sValue;
            case {'penalty file'}   
                Resistivity.penaltyFile = sValue;
            case {'maximum interations'}       
                Resistivity.maxIterations = sscanf(sValue,'%g',1);
            case {'bounds transform'}
                Resistivity.boundsTransform = sValue;
            case {'global bounds'}   
                ind = findstr(sValue,',');
                if ~isempty(ind) % 用空格替换逗号
                    sValue(ind) = ' ';
                end
                Resistivity.globalBounds = sscanf(sValue,'%g %g',2);
            case {'debug level','print level'}
                Resistivity.debugLevel = sscanf(sValue,'%i',1);
            case {'target misfit'}    
                Resistivity.targetMisfit = sscanf(sValue,'%g',1);
            case {'iteration'}  
                Resistivity.iteration = sscanf(sValue,'%i',1);
            case {'lagrange value'}     
                Resistivity.lagrange =  sscanf(sValue,'%g',1);
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
                if bNoData  % 除了数据，没有什么跟在此之后。 跳过它。
                    break;
                end
                
                Resistivity.numRegions = sscanf(sValue,'%i',1);
               
                switch Resistivity.anisotropy
                    case 'isotropic'
                        nrho = 1;
                        str ='%g';
                    case 'triaxial'
                        nrho = 3;
                        str ='%g%g%g';
                    case {'tix', 'tiy', 'tiz'}
                        nrho = 2;   
                        str ='%g%g';
                end
                
                Resistivity.resistivity   = zeros(Resistivity.numRegions,nrho);
                Resistivity.freeparameter = zeros(Resistivity.numRegions,nrho);
                Resistivity.prejudice     = zeros(Resistivity.numRegions,2*nrho);
                Resistivity.bounds        = zeros(Resistivity.numRegions,2*nrho);
                Resistivity.ratioPrej     = zeros(Resistivity.numRegions,nrho*(nrho-1));
                
                sLine = fgets(fid); % 一个注释行
                
                if strcmpi(Resistivity.version,'MARE2DEM_1.0') || nrho == 1
                    scstr = sprintf('%s%s%s%s%s%s%s','%*i',str,str,str,str,str,str);
                elseif nrho == 2  % 在2列上添加各向异性比率权重和首选项：
                    scstr = sprintf('%s%s%s%s%s%s%s%s','%*i',str,str,str,str,str,str,str);
                elseif nrho == 3 % 在3 x 2列上添加各向异性比率首选项：
                    scstr = sprintf('%s%s%s%s%s%s%s%s%s','%*i',str,str,str,str,str,str,str,str);
                end
                    
                for i = 1:Resistivity.numRegions
                     sLine = fgets(fid);       
                     vals = sscanf(sLine,scstr);
                     Resistivity.resistivity(i,1:nrho)   = vals(1:nrho);
                     Resistivity.freeparameter(i,1:nrho) = vals(nrho+[1:nrho]);
                     Resistivity.bounds(i,1:2*nrho)      = vals(2*nrho+[1:2*nrho]);
                     Resistivity.prejudice(i,1:2*nrho)   = vals(4*nrho+[1:2*nrho]);
                     if length(vals) > 6*nrho  % 即具有各向异性比率首选项的新格式
                        Resistivity.ratioPrej(i,1:nrho*(nrho-1)) = vals(6*nrho+1:end);
                     end
                end
                
            otherwise
              
            
        end
    end
    
   
    fclose(fid);
    
end