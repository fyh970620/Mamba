function st = m2d_addSyntheticNoise(st,stNoise)
%
% m2d_addSyntheticNoise(st,stNoise) adds synthetic Gaussian noise to the
% MARE2DEM response data in input structure st. 
% 
% Note: This is a low level workhorse function. Most users will want to 
% instead use function m2d_makeSyntheticData() since it 
% handles the required file i/o.
%
% Arguments:
%
%   st  - structure containing the MARE2DEM responses (MT and/or CSEM) read
%   in using m2d_readEMData2DFile.
%
%   stNoise  - structure specifying noise levels to use. You only need to
%              specify the fields for the data type in the input file 
%              (i.e. if you only have MT data, you only need to specify 
%              stNoise.mt.relNoise). Fields:
%
%     stNoise.mt.relNoise  - relative noise to add to MT responses
%                            (e.g. 0.05 means add 5% Gaussian noise). Note
%                            this is the relative error in apparent
%                            resistivity. Phase noise will be 0.5*relNoise.
%                            ( as can be shown by propagation of error from
%                            the impedance to app. res. and phase).
%       
%     stNoise.mt.relNoise_tipper - e.g. 1%
%
%     stNoise.mt.absNoise_tipper - e.g. 0.01
% 
%     stNoise.csem.relNoiseE - relative noise to add to CSEM electric field 
%                              responses (e.g. 0.05 means add 5% Gaussian noise).
%
%     stNoise.csem.minAmpE - Electric field responses below this amplitude 
%                            are omitted from the output data file.   
%                            KWK to do: NOT YET IMPLEMENTED
%                          
%     stNoise.csem.relNoiseB - relative noise to add to CSEM magnetic field 
%                              responses (e.g. 0.05 means add 5% Gaussian noise).
%
%     stNoise.csem.minAmpB - Magnetic field responses below this amplitude 
%                            are omitted from the output data file.
%                            KWK to do: NOT YET IMPLEMENTED
%
% Outputs:
%
%   st - structure copied from input structure st. 
%       Synthetic noisy data generated from the input forward responses 
%       (i.e. st.DATA(:,7) ) are copied into output data (st.DATA(:,5)) 
%       with standard error (st.DATA(:,6);
% 
%
% Kerry Key
% Lamont-Doherty Earth Observatory
%   

%
% Check input arguments
%
    % kwk debug: to code...

%
% Add noise to any input MT responses:
%
st = sub_mt_noise(st,stNoise);

%
% Add noise to any input CSEM responses:
%
st = sub_csem_noise(st,stNoise);

%
% Now trim off response data so that output st.DATA only has data
% parameters (columns 1:4) and the data and standard error (columns 5:6):
%
st.DATA = st.DATA(:,1:6);
 

%--------------------------------------------------------------------------
function st = sub_mt_noise(st,stNoise)

    % return if no MT data:
    if ~isfield(st,'stMT') || isempty(st.stMT)
        return
    end

    %
    % Peel off data and then add noise to various MT data types, if
    % present:
    %
    DATA = st.DATA;
 
    %
    % Log10 apparent resistivity:
    %
    ltype = ismember(DATA(:,1),[123 125 129]);  % TE, TM and det|Z| log10 ApRes    
     
    if any(ltype)
        d = DATA(ltype,7);
        [DATA(ltype,5), DATA(ltype,6)] = logamplitude_noise(d,stNoise.mt.relNoise);
    end
 
    
    %
    % Apparent resistivity:
    %
    ltype = ismember(DATA(:,1),[103 105 109]); % TE, TM and det|Z| ApRes    
    if any(ltype)
        d = DATA(ltype,7);
        [DATA(ltype,5), DATA(ltype,6)] = amplitude_noise(d,stNoise.mt.relNoise);
    end
 
    
    %
    % Phase:
    %
    ltype = ismember(DATA(:,1),[104 106 110]); % TE, TM and det|Z| phases
    
    if any(ltype)
        d = DATA(ltype,7);
        relNoise = stNoise.mt.relNoise/2; % note phase error is 1/2 apparent resistivity error since apres ~ Z^2
        [DATA(ltype,5), DATA(ltype,6)] = phase_noise(d,relNoise);
    end
 
    %  
    % Tipper:  Real and Imaginary
    %    
    ltype = DATA(:,1) == 133 | DATA(:,1) == 134;  % tipper amplitude and phase

    if any(ltype)

        l_re = DATA(:,1) == 133;   
        l_im = DATA(:,1) == 134;
 
        d_re = DATA(l_re,7); 
        d_im = DATA(l_im,7); 

        % check that data arrays are in expected pairs as real/imag in
        % subsequent rows
        
        if any( DATA(l_re,2:4) ~= DATA(l_im,2:4) )
            str1 = 'm2d_addSyntheticNoise: real & imaginary tipper data for ';
            str2 = 'a given receiver and period should be in subsequent';
            str3 = ' rows. Snythetic tipper data NOT generated, sorry! ';
            str = sprintf('%s\n%s\n%s',str1,str2,str3);
            h = warndlg('Error! ',str);
            set(h,'windowstyle','modal')
            waitfor(h);
            return

        end

        relNoise = stNoise.mt.relNoise_tipper;  
        absNoise = stNoise.mt.absNoise_tipper; 
        
        [DATA(l_re,5),DATA(l_re,6),DATA(l_im,5),DATA(l_im,6)] = ...
            real_imag_noise(d_re,d_im,relNoise,absNoise);
 
    end
    
    %  
    % Tipper: Amplitude and Phase 
    %
    ltype = DATA(:,1) == 135 | DATA(:,1) == 136;  % tipper amplitude and phase

    if any(ltype)
%         lamp = DATA(:,1) == 135;   
%         lphs = DATA(:,1) == 136;
%  
%         d_amp = DATA(lamp,7); 
%         d_phs = DATA(lphs,7); 
% 
%         relNoise = stNoise.mt.relNoise_tipper;  
%         
%         
%         [DATA(lamp,5), DATA(lamp,6)] = amplitude_noise(d_amp,relNoise);
%         [DATA(lphs,5), DATA(lphs,6)] = phase_noise(d_phs,relNoise);
        
        disp('warning: synthetic data code does not yet apply')
        disp('         stNoise.mt.absNoise_tipper absolute noise floor')
        % kwk to do: need to use amplitude noise to trim out low
        % amplitude tipper amplitude and phase pairs?
        %absNoise = stNoise.mt.absNoise_tipper;  
 
    end
    
    % Remove any nan data that was created for low amplitude tipper
    % real/imag or amplitude and phase pairs

    lNan = isnan(DATA(:,5));
    DATA(lNan,:) = [];

    %
    % Insert modified DATA into output structure:
    %
    st.DATA = DATA;
    
end

%--------------------------------------------------------------------------
function st = sub_csem_noise(st,stNoise)

    % KWK to do: 
    % 
    %  - need to add support for Real & Imag data
    %  - add support for absolute noise levels, which requires finding 
    %    paired phases so that phase associated with low amplitude data is 
    %    treated appropriately...
    %               

    % return if no CSEM data:
    if ~isfield(st,'stCSEM') || isempty(st.stCSEM)
        return
    end

  
    %
    % Peel off data and then add noise to various CSEM data types, if
    % present:
    %
    DATA = st.DATA;

    % Check for older relNoise vs newer relNoiseE and relNoiseB
    % specifications
    if ~isfield(stNoise.csem,'relNoiseE') && isfield(stNoise.csem,'relNoise')
        stNoise.csem.relNoiseE = stNoise.csem.relNoise;
    end
    if ~isfield(stNoise.csem,'relNoiseB') && isfield(stNoise.csem,'relNoise')
        stNoise.csem.relNoiseB = stNoise.csem.relNoise;
    end 
 

    %
    % Log10 amplitude E:  
    %
    ltype = ismember(DATA(:,1),[27,28,29] );     
     
    if any(ltype)
        d = DATA(ltype,7);
        [DATA(ltype,5),  DATA(ltype,6)] = logamplitude_noise(d,stNoise.csem.relNoiseE);  
    end

    %
    % Log10 amplitude B:  
    %
    ltype = ismember(DATA(:,1),[37,38,39] );     
     
    if any(ltype)
        d = DATA(ltype,7);
        [DATA(ltype,5),  DATA(ltype,6)] = logamplitude_noise(d,stNoise.csem.relNoiseB);  
    end
    
    %
    % amplitude E
    %
    ltype = ismember(DATA(:,1),[21,23,25]);   
     
    if any(ltype)     
        d = DATA(ltype,7);
        [DATA(ltype,5),  DATA(ltype,6)] = amplitude_noise(d,stNoise.csem.relNoiseE);  
    end

    %
    % amplitude B
    %
    ltype = ismember(DATA(:,1),[31,33,35]);   
     
    if any(ltype)     
        d = DATA(ltype,7);
        [DATA(ltype,5),  DATA(ltype,6)] = amplitude_noise(d,stNoise.csem.relNoiseB);  
    end    
        
    %
    % Phase E:
    %
    ltype = ismember(DATA(:,1),[22,24,26]);   
    
    if any(ltype)
        d = DATA(ltype,7);
        [DATA(ltype,5),  DATA(ltype,6)] = phase_noise(d,stNoise.csem.relNoiseE);  
    end

    %
    % Phase B:
    %
    ltype = ismember(DATA(:,1),[22,24,26,32,34,36]);   
    
    if any(ltype)
        d = DATA(ltype,7);
        [DATA(ltype,5),  DATA(ltype,6)] = phase_noise(d,stNoise.csem.relNoiseB);  
    end    
    
    %
    % Real and Imaginary E: 
    %
    ltype = ismember(DATA(:,1),1:6);  
    
    if any(ltype)
        beep;

        h = warndlg('Error! ','m2d_addSyntheticNoise does not yet support real & imaginary format data, sorry! ');
        set(h,'windowstyle','modal')
        waitfor(h);
        return
    end

    %
    % Real and Imaginary B: 
    %
    ltype = ismember(DATA(:,1),11:16);  
    
    if any(ltype)
        beep;

        h = warndlg('Error! ','m2d_addSyntheticNoise does not yet support real & imaginary format data, sorry! ');
        set(h,'windowstyle','modal')
        waitfor(h);
        return
    end    
    
    %
    % Insert modified DATA into output structure:
    %
    st.DATA = DATA;
    
end

%--------------------------------------------------------------------------
function [logamp, std]  = logamplitude_noise(logamp,relError)
    
    std = 0.4343*relError;  % log10 relative error  
    
    [logamp, std] = apply_noise(logamp,std);
    
end

%--------------------------------------------------------------------------
function [amp, std] = amplitude_noise(amp,relError)
    
    std = relError*abs(amp);  % convert relative to absolute error  
   
    [amp, std] = apply_noise(amp,std);
   
end

%--------------------------------------------------------------------------
function [phs, std] = phase_noise(phs,relError)
    
    std = relError*180/pi;
    
    [phs, std] = apply_noise(phs,std);
      
end

%--------------------------------------------------------------------------
function [real, rstd, imag, istd] = real_imag_noise(real,imag,relError,absError)
    
    amp = sqrt(real.^2 + imag.^2);
    
    std = relError*abs(amp);  % convert relative to absolute error  
    std(amp<absError) = nan;

    [real, rstd] = apply_noise(real,std);
    [imag, istd] = apply_noise(imag,std);

end 

%--------------------------------------------------------------------------
function [d, std] = apply_noise(d,std)
    
    % Generates and adds random Gaussian noise with standard deviation std
    % to input data d
          
    noise = randn(size(d)); % unit Gaussian noise
    
    % limit noise to 2 standard deviations in case randn was unlucky:
    iLarge        = abs(noise) > 2;     
    noise(iLarge) = sign(noise(iLarge))*2;
    
    % scale unit noise by std:
    noise = std.*noise;   
    
    % add noise:
    d = d + noise;
    
    std = std.*ones(size(d));
    
end

end

