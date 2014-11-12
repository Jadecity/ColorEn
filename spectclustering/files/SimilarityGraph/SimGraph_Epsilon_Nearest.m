function W = SimGraph_Epsilon_Nearest(M, epsilon, Type, sigma)
% SimGraph_Epsilon_Nearest Returns epsilon similarity graph
%   Returns adjacency matrix for an k-Nearest Neighbors 
%   similarity graph
%
%   'M' - A d-by-n matrix containing n d-dimensional data points
%   'k' - Number of neighbors
%   'Type' - Type if kNN Graph
%      1 - Normal
%      2 - Mutual
%   'sigma' - Parameter for Gaussian similarity function. Set
%      this to 0 for an unweighted graph. Default is 1.
%
%   Author: Ingo Buerk
%   Year  : 2011/2012
%   Bachelor Thesis

if nargin < 3
   ME = MException('InvalidCall:NotEnoughArguments', ...
       'Function called with too few arguments');
   throw(ME);
end

if ~any(Type == (1:2))
   ME = MException('InvalidCall:UnknownType', ...
       'Unknown similarity graph type');
   throw(ME);
end

n = size(M, 2);

% Preallocating memory is impossible, since we don't know how
% many non-zero elements the matrix is going to contain
indi = [];
indj = [];
inds = [];

for ii = 1:n
    % Compute i-th column of distance matrix
    dist = distEuclidean(repmat(M(:, ii), 1, n), M);
    
    % Find distances smaller than epsilon (unweighted)
    dist = (dist < epsilon);
    
    % Now save the indices and values for the adjacency matrix
    lastind  = size(indi, 2);
    count    = nnz(dist);
    [~, col] = find(dist);
    
    indi(1, lastind+1:lastind+count) = ii;
    indj(1, lastind+1:lastind+count) = col;
    inds(1, lastind+1:lastind+count) = 1;
end

% Create sparse matrix
W = sparse(indi, indj, inds, n, n);

clear indi indj inds dist lastind count col v;

% Construct either normal or mutual graph
if Type == 1
    % Normal
    W = max(W, W');
else
    % Mutual
    W = min(W, W');
end

if nargin < 4 || isempty(sigma)
    sigma = 1;
end

% Unweighted graph
if sigma == 0
    W = (W ~= 0);
    
% Gaussian similarity function
elseif isnumeric(sigma)
    W = spfun(@(W) (simGaussian(W, sigma)), W);
    
else
    ME = MException('InvalidArgument:NotANumber', ...
        'Parameter epsilon is not numeric');
    throw(ME);
end

end