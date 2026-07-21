function sFile = m2d_getMostRecent(sFile,sExt)
%
% Checks sFile for 'newest' code word and if so retrieves the newest file
% with extension in string sExt.
%
% sExt should be '*.resistivity' or '*.resp'
%
% sFile returns empty is 'newest' used but not sExt files found.
%
    
    switch lower(sFile)
    
        case {'lastiter','last','newest'}
            % Get all files
            files = dir(sExt);
            
            % Remove any hidden sExt files (these are sometimes introduced by
            % CyberDuck, not sure why)
            bKeep = logical(1:length(files));
            for i = 1:length(files)
                if files(i).name(1) =='.'
                    bKeep(i) = false;
                end
            end
            files = files(bKeep);
            
            % Now sort them by date:
            for i = 1:length(files)
                files(i).date = datenum(files(i).date);
            end
            [temp, isort] = sort([files.date]); %#ok<*ASGLU>
            isort = fliplr(isort); % descending order
            if isempty(isort)
                sFile = [];
                return
            end
            sFile = files(isort(1)).name;
            
    end