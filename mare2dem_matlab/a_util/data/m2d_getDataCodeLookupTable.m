    
function sDataCodeLookupTable = getDataCodeLookupTable()
    
    sDataCodeLookupTable    = cell(136,2);
    sDataCodeLookupTable(:) = {''};
    
    % CSEM formats
    sDataCodeLookupTable(1,1:2) = {'Ex' 'Real'};
    sDataCodeLookupTable(2,1:2) = {'Ex' 'Imaginary'};
    sDataCodeLookupTable(3,1:2) = {'Ey' 'Real'};
    sDataCodeLookupTable(4,1:2) = {'Ey' 'Imaginary'}; 
    sDataCodeLookupTable(5,1:2) = {'Ez' 'Real'};
    sDataCodeLookupTable(6,1:2) = {'Ez' 'Imaginary'};
    
    sDataCodeLookupTable(11,1:2) = {'Bx' 'Real'};
    sDataCodeLookupTable(12,1:2) = {'Bx' 'Imaginary'};
    sDataCodeLookupTable(13,1:2) = {'By' 'Real'};
    sDataCodeLookupTable(14,1:2) = {'By' 'Imaginary'}; 
    sDataCodeLookupTable(15,1:2) = {'Bz' 'Real'};
    sDataCodeLookupTable(16,1:2) = {'Bz' 'Imaginary'};
    
    sDataCodeLookupTable(21,1:2) = {'Ex' 'Amplitude'};
    sDataCodeLookupTable(22,1:2) = {'Ex' 'Phase'};
    sDataCodeLookupTable(23,1:2) = {'Ey' 'Amplitude'};
    sDataCodeLookupTable(24,1:2) = {'Ey' 'Phase'}; 
    sDataCodeLookupTable(25,1:2) = {'Ez' 'Amplitude'};
    sDataCodeLookupTable(26,1:2) = {'Ez' 'Phase'};
    sDataCodeLookupTable(27,1:2) = {'Ex' 'Log10 Amplitude'};
    sDataCodeLookupTable(28,1:2) = {'Ey' 'Log10 Amplitude'};
    sDataCodeLookupTable(29,1:2) = {'Ez' 'Log10 Amplitude'};
    
    sDataCodeLookupTable(31,1:2) = {'Bx' 'Amplitude'};
    sDataCodeLookupTable(32,1:2) = {'Bx' 'Phase'};
    sDataCodeLookupTable(33,1:2) = {'By' 'Amplitude'};
    sDataCodeLookupTable(34,1:2) = {'By' 'Phase'}; 
    sDataCodeLookupTable(35,1:2) = {'Bz' 'Amplitude'};
    sDataCodeLookupTable(36,1:2) = {'Bz' 'Phase'};
    sDataCodeLookupTable(37,1:2) = {'Bx' 'Log10 Amplitude'};
    sDataCodeLookupTable(38,1:2) = {'By' 'Log10 Amplitude'};
    sDataCodeLookupTable(39,1:2) = {'Bz' 'Log10 Amplitude'};    
    
    sDataCodeLookupTable(41,1:2) = {'Ep' 'PEmax'};
    sDataCodeLookupTable(42,1:2) = {'Ep' 'PEmin'};
    sDataCodeLookupTable(43,1:2) = {'Bp' 'PEmax'};
    sDataCodeLookupTable(44,1:2) = {'Bp' 'PEmin'}; 
    
    % MT formats:
    sDataCodeLookupTable(103,1:2) = {'Zxy (TE)' 'ApRes'};
    sDataCodeLookupTable(104,1:2) = {'Zxy (TE)' 'Phase'};
    sDataCodeLookupTable(105,1:2) = {'Zyx (TM)' 'ApRes'};
    sDataCodeLookupTable(106,1:2) = {'Zyx (TM)' 'Phase'}; 

    
    sDataCodeLookupTable(113,1:2) = {'Zxy (TE)' 'Real'};
    sDataCodeLookupTable(114,1:2) = {'Zxy (TE)' 'Imaginary'};
    sDataCodeLookupTable(115,1:2) = {'Zyx (TM)' 'Real'};
    sDataCodeLookupTable(116,1:2) = {'Zyx (TM)' 'Imaginary'}; 
    
    sDataCodeLookupTable(123,1:2) = {'Zxy (TE)' 'log10(ApRes)'};
    sDataCodeLookupTable(125,1:2) = {'Zyx (TM)' 'log10(ApRes)'};

    sDataCodeLookupTable(109,1:2) = {'Det |Z|' 'ApRes'};
    sDataCodeLookupTable(110,1:2) = {'Det |Z|' 'Phase'};
    sDataCodeLookupTable(129,1:2) = {'Det |Z|' 'log10(ApRes)'};

    sDataCodeLookupTable(133,1:2) = {'Mzy (TE)' 'Real'};   % TE mode magetic tipper
    sDataCodeLookupTable(134,1:2) = {'Mzy (TE)' 'Imaginary'};

    sDataCodeLookupTable(135,1:2) = {'Mzy (TE)' 'Amplitude'};   % TE mode magetic tipper
    sDataCodeLookupTable(136,1:2) = {'Mzy (TE)' 'Phase'};
    
   
    sDataCodeLookupTable(151,1:2) = {'Ex' 'Real'};
    sDataCodeLookupTable(152,1:2) = {'Ex' 'Imaginary'};
    sDataCodeLookupTable(153,1:2) = {'Ey' 'Real'};
    sDataCodeLookupTable(154,1:2) = {'Ey' 'Imaginary'}; 
    sDataCodeLookupTable(155,1:2) = {'Ez' 'Real'};
    sDataCodeLookupTable(156,1:2) = {'Ez' 'Imaginary'};
    
    sDataCodeLookupTable(161,1:2) = {'Hx' 'Real'};
    sDataCodeLookupTable(162,1:2) = {'Hx' 'Imaginary'};
    sDataCodeLookupTable(163,1:2) = {'Hy' 'Real'};
    sDataCodeLookupTable(164,1:2) = {'Hy' 'Imaginary'}; 
    sDataCodeLookupTable(165,1:2) = {'Hz' 'Real'};
    sDataCodeLookupTable(166,1:2) = {'Hz' 'Imaginary'};    
    