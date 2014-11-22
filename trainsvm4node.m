function trainsvm4node( root, ftspace )
%TRAINSVM4NODE learn a svm for each inner node of tree from root
%   function trainsvm4node( root, ftspace )
%   any leaf node will be ignored, only inner node has a svm struct, tree
%   must be a binary tree
%   root: the node for which a svm is learned and attached to it
%   ftspace: feature space, each column is a feature vector of a point
%   Author: lvhao
%   Email:  lvhaoexp@163.com
%   Date: 2014-08-29

if isempty(root.left) || isempty(root.left)
    return;
end

npoints = root.left.data;
ppoints = root.right.data;
negative = ftspace(:, npoints)';
positive = ftspace(:, ppoints)';
labels = zeros( size(negative,1)+size(positive,1), 1);
labels(size(negative,1)+1:end, 1) = 1;

root.other.svm = svmtrain(labels, [negative;positive]);

trainsvm4node(root.left, ftspace);
trainsvm4node(root.right, ftspace);

end

