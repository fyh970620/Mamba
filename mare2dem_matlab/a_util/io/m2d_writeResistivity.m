function [status, varargout] = m2d_writeResistivity(st,bOverwrite)  
% [status    ] = m2d_writeResistivity(st,bOverwrite) 
% [status, st] = m2d_writeResistivity(st,bOverwrite) returns 
% st.freeparameter is updated here with the parameter number.
%
% Writes out MARE2DEM .resistivity file using fields in structure st.
%
% See code for st entries needed.
%
 

[~,~,e] = fileparts(st.resistivityFile);

if ~strcmpi(e,'.resistivity') % enforce .resistivity extension
    st.resistivityFile = strcat(st.resistivityFile,'.resistivity'); % the 0 is to denote iteration 0
end

if ~bOverwrite
    if exist(fullfile('./',st.resistivityFile),'file')
        choice = questdlg('Warning: The MARE2DEM .resistivity file already exists, shall I overwrite it?','Warning! ', 'Yes','No','No');
        switch choice
            case 'No'

                display('Not saving resistivity file...')
                status = false;
                return
        end
    end
end

status = true;

fid = fopen(st.resistivityFile,'W');
fprintf(fid,'Format:                         %-32s ! input \n','mare2dem_1.1');
fprintf(fid,'Model File:                     %-32s ! input \n',st.polyFile);
fprintf(fid,'Data File:                      %-32s ! input \n',st.dataFile);
if isfield(st,'sDataGroupFile') && ~isempty(st.sDataGroupFile)
    fprintf(fid,'Data Group File:                %-32s ! opt. input \n',st.sDataGroupFile);
end  
if isfield(st,'sJointInvWeightType') && ~isempty(st.sJointInvWeightType)
    fprintf(fid,'Joint inversion weight:         %-32s ! opt. input.(unity, data_count, misfit_balanced_data_count(def))\n',st.sJointInvWeightType);
end     
fprintf(fid,'Settings File:                  %-32s ! input \n',st.settingsFile);
%fprintf(fid,'Penalty File:               %-32s ! input\n',st.penaltyFile);deprecated Nov 2020. Now generated on the fly in mare2dem
if ~isfield(st,'maxiterations')
    st.maxiterations = 100;
end
fprintf(fid,'Maximum Iterations:             %-32i ! opt. input \n',st.maxiterations);
fprintf(fid,'Bounds Transform:               %-32s ! opt. input \n','bandpass');

bstr = sprintf('%s, %s',strip(sprintf('%15.10g',st.globalBounds(1))),strip(sprintf('%15.10g',st.globalBounds(2))));
fprintf(fid,'Global Bounds:                  %-32s ! opt. input \n',bstr);
fprintf(fid,'Roughness Penalty Method:       %-32s ! opt. input (gradient or first_difference)  \n',st.sRoughnessPenaltyMethod);
str = sprintf('%s, %s',strip(sprintf('%15.10g',st.yzPenaltyWeights(1))),strip(sprintf('%15.10g',st.yzPenaltyWeights(2))));
fprintf(fid,'Roughness Weights (y,z):        %-32s ! opt. input (e.g. 3.0,1.0). \n',str);
fprintf(fid,'Penalty Cut Weight:             %-32s ! opt. input (e.g. 0.1) \n',num2str(st.penaltyCutWeight));

if isfield(st,'bRoughnessWithPrejudice') && st.bRoughnessWithPrejudice
    str = 'yes';
else
    str = 'no';
end
fprintf(fid,'Roughness With Prejudice:       %-32s ! opt. input (yes or no). Yes uses norm: || R(m-m_prej)||^2  \n',str);

if ~isfield(st,'betaMGS')
    st.betaMGS = 0;
end
fprintf(fid,'Min. Gradient Support Weight:   %-32s ! opt. input (e.g. 0.01) 0 means no MGS\n',num2str(st.betaMGS));    
if ~strcmpi(st.anisotropy,'isotropic') && ~strcmpi(st.anisotropy,'isotropic_ip') && ~strcmpi(st.anisotropy,'isotropic_complex')
    fprintf(fid,'Aniso. Penalty Weight:          %-32s ! opt. input (e.g. 1.0) 0 means no penalty. weight*||m_v-m_h||^2 \n',num2str(st.anisotropyPenaltyWeight));    
    fprintf(fid,'Aniso. Ratio Roughness Weight:  %-32s ! opt. input (e.g. 1.0) 0 means no penalty. weight*||R(m_v-m_h)||^2 \n',num2str(st.anisotropyRatioRoughnessWeight));    
end
 
fprintf(fid,'Print Level:                    %-32i ! opt. input  \n',1);
fprintf(fid,'Target Misfit:                  %-32s ! require for inversion) \n',num2str(st.targetMisfit));
fprintf(fid,'Misfit Decrease Threshold:      %-32g ! opt. input (0 <= n < 1). Iteration ends if RMS < n*Starting_RMS \n',0.85);
fprintf(fid,'Converge Slowly:                %-32s ! opt. input. Target misfit = max(n*Starting_RMS, Target Misfit) for each iteration \n','no');
fprintf(fid,'Log10 Lagrange Value:           %-32g ! input/output (required for inversion) \n',5);  % note that we don't output any input
fprintf(fid,'Model Roughness:                %-32s ! output from inversion \n',' ');    %  values for these since user may have modified the model here!
fprintf(fid,'Model Misfit:                   %-32s ! output from inversion \n',' ');
fprintf(fid,'Date/Time:                      %-32s ! output from inversion \n',datestr(now));


fprintf(fid,'Anisotropy:                     %-32s ! input \n',st.anisotropy);

nRegions = size(st.resistivity,1);

fprintf(fid,'Number of regions:              %-32i ! input \n',nRegions);

str1 = sprintf('%-8s ','!#');

switch lower(st.anisotropy)
    case 'isotropic'
        rstr = sprintf('%-13s','Rho');
        nper = 1;
        strf = sprintf('%-10s','Param ');
        stb  = sprintf('%-13s','Lower','Upper');
        stp  = sprintf('%-13s','Prej','Weight'); 
    case 'isotropic_ip'  % Cole-Cole model
        rstr = sprintf('%-13s','Rho','Eta','Tau','C');
        nper = 4;
        strf = sprintf('%-10s','ParamRho','ParamEta','ParamTau','ParamC');
        stb  = sprintf('%-13s','Lower Rho','Upper Rho','Lower Eta','Upper Eta','Lower Tau','Upper Tau','Lower C','Upper C');
        stp  = sprintf('%-13s','Prej','Weight','Prej','Weight','Prej','Weight','Prej','Weight'); 
    case 'isotropic_complex'    
        rstr = sprintf('%-13s','Rho Real','Rho Imag');
        nper = 2;
        strf = sprintf('%-10s','ParamReal','ParamImag'); 
        stb  = sprintf('%-13s','Lower Real','Upper Real','Lower Imag','Upper Imag');
        stp  = sprintf('%-13s','Prej Real','Weight','Prej Imag','Weight'); 
    case 'triaxial'
        rstr = sprintf('%-13s','Rho-x','Rho-y','Rho-z');
        nper = 3;
        strf = sprintf('%-10s','Param x','Param y','Param z');  
        stb  = sprintf('%-13s','Lower x','Upper x','Lower y','Upper y','Lower z','Upper z');
        stp  = sprintf('%-13s','Prej x','Weight','Prej y','Weight','Prej z','Weight');    
    case 'tix'
        rstr = sprintf('%-13s','Rho-x','Rho-yz');
        nper = 2;
        strf = sprintf('%-10s','Param x','Param yz'); 
        stb  = sprintf('%-13s','Lower x','Upper x','Lower yz','Upper yz');
        stp  = sprintf('%-13s','Prej x','Weight','Prej yz','Weight');
    case 'tiy'
        rstr = sprintf('%-13s','Rho-y','Rho-xz');
        nper = 2;
        strf = sprintf('%-10s','Param y','Param xz');      
        stb  = sprintf('%-13s','Lower y','Upper y','Lower xy','Upper xz');
        stp  = sprintf('%-13s','Prej y','Weight','Prej xz','Weight');
    case 'tiz'
        rstr = sprintf('%-13s','Rho-z','Rho-h');
        nper = 2;
        strf = sprintf('%-10s','Param z','Param h'); 
        stb  = sprintf('%-13s','Lower z','Upper z','Lower h','Upper h');
        stp  = sprintf('%-13s','Prej z','Weight','Prej h','Weight');
    case 'tiz_ratio'
        rstr = sprintf('%-13s','Rho-z','Rho z/h');
        nper = 2;
        strf = sprintf('%-10s','Param z','Param z/h'); 
        stb  = sprintf('%-13s','Lower z','Upper z','Lower z/h','Upper z/h');
        stp  = sprintf('%-13s','Prej z','Weight','Prej z/h','Weight');        
end
fprintf(fid,'%s %s %s %s %s\n',str1,rstr,strf,stb,stp);

nfree = 0;

% write out params for each region. Also create a listing of all free
% parameter numbers for each region to output from this function for
% latter use in the penalty matrix generation:

for i = 1:nRegions
    if any(st.freeparameter(i,:) > 0)
        % ifree = nfree+(1:nper);
        
        % fix for case when some anisotropic or IP parameters are free and
        % others are fixed parameters:
        lFree = st.freeparameter(i,:) > 0;
        cnt   = nfree + cumsum(lFree);
        ifree = cnt.*lFree;

        sfree = sprintf('%-10i', ifree );
        nfree = max(ifree);
    else
        sfree = sprintf('%-10i', zeros(nper,1));
        ifree = zeros(1,nper);
    end
    srho  = sprintf('%-13.7g', st.resistivity(i,:)   );
    
    sprej = sprintf('%-13.7g', st.prejudice(i,:)     );
    sbnds = sprintf('%-13.7g', st.bounds(i,:)        );
 
    fprintf(fid,'%-9i %s %s %s %s\n',i,srho,sfree,sbnds, sprej);
    
    st.freeparameter(i,:)  = ifree;
end


fclose(fid);

if nargout == 2
    varargout{1} = st;
end

end