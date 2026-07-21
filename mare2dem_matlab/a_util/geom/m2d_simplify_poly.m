
function [nodes,segments] = m2d_simplify_poly(nodes,segments) 
%
% Cleans up polygon arrays by removing any self connected nodes and
% removes interior nodes along collinear segments.
%

%  Make sure there are no self-connected node segments:
segments =  segments - diag(diag(segments)); % i.e., enforce 0 diagonal

% Find nodes connected bu *only* two co-linear segments and remove those
% nodes and update the segment list. This preserves the geometry of the
% poly mesh but removed unnecessary nodes.
    
% test for collinearity and remove middle nodes. 
i2 = find(sum(segments~=0,2) == 2); 
lCollinear = false(size(i2));
tol = 1d-10;
for i = 1:length(i2)
    [~,j] = find(segments(i2(i),:)); % find first node with only two segments
    P  = nodes([i2(i) j],:);
    lCollinear(i) = rank(bsxfun(@minus, P, P(1,:)), tol) < 2; 
    % from http://blogs.mathworks.com/loren/2008/06/06/collinearity/#comment-29479
end
iNodeRemove = i2(lCollinear);

if ~isempty(iNodeRemove)
    for i = iNodeRemove(:)' % kwk: force to be row vector so i iterates through columns

         [~,j,v] = find(segments(i,:)); % find first node with only two segments

         % remove old segments i to j(1) and i to j(2)
        segments(i,j(1)) = 0;
        segments(j(1),i) = 0;
        segments(i,j(2)) = 0;
        segments(j(2),i) = 0;        
        % connect endpoints with new segment:
        segments(j(1),j(2)) = min(v); % min(v) to preserve -1 values for penalty cut segments. 
        segments(j(2),j(1)) = min(v);

    end

    % finally remove collinear node(s) from nodes and adjacency matrix:
    nodes(iNodeRemove,:) = [];
    segments(iNodeRemove,:) = [];
    segments(:,iNodeRemove) = [];
end

end

