function trianglepath = Mamba2D_TrianglePath()
%
% Automatically finds the correct triangle.c executable for Mac and PC
% systems. Linux users will need to add their own executable and link below
%
% NOTE: You need to make sure the /Mamba2D/a_util folder is on Matlab's
% search path. See the help documnentation pages for "Using the Set Path Dialog Box"
%
thisMachine = computer;

switch  lower(thisMachine)

    case 'maci64'  % Mac OS X
        % use the executable in this folder
        trianglepath = which('triangle_osx.');

    case {'win32' 'win64' 'pcwin64' 'pcwin'}  % Windows PC: 
         % use the executable in this folder
        trianglepath =  which('triangle.exe');
        
    case {'glnx86' 'glnxa64' }  % Linux

        % *************************************
        % *****!!! HERE HERE HERE HERE!!!******
        % ******* Hey you linux user **********
        % For example, you could use trianglepath = 'which('triangle_linux'); 
        % if triangle_linux is the executable        
        trianglepath =  which('triangle');
        if isempty(trianglepath)
             trianglepath =  which('triangle.');
        end
        
        if ~isdeployed() && isempty(trianglepath)
            str = sprintf('Linux user: Please add the path to the triangle.c executable to the file Mamba2D_TrianglePath.m');
            beep;
            h = errordlg(str,'Triangle.c error');
            waitfor(h);
            
            % Help the user out by opening this file for them:
            open Mamba2D_TrianglePath.m
            
        end

end

 