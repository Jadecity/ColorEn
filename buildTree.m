function buildTree( root, ftspace, gweight, maptype )
%BUILDMAPTREE use feature space to build a mapping tree
%   function buildTree( ftspace, maptype )
%   maptype: either 'color' or 'luminance'
%   ftspace: feature space, each column is a feature vector of a point
%   gweight: a weight matrix of points, short for global weight
%   root: it is the root node of the mapping tree, with type
%   BinTreeNode
%   Author: lvhao
%   Email:  lvhaoexp@163.com
%   Date: 2014-08-28

if strcmp(maptype, 'color')
    loop = 300;
end
if strcmp(maptype, 'luminance')
    loop = 200;
end

for cnt=1:loop
    %find a suitable node to split
    least = findLeastSim(root);
    
    %if no child can be split, split root
    if isempty(least)
        %make weight matrix
        least = root;
    end

    weight = gweight(least.data(:), least.data(:));
    [c1, c2] = minmaxcut(weight);

    left = BinTreeNode();
    right = BinTreeNode();
    left.data = least.data(c1);
    right.data = least.data(c2);
    weight = gweight(left.data(:), left.data(:));
    left.other.sim = avgsim(left.data, weight);
    weight = gweight(right.data(:), right.data(:));
    right.other.sim = avgsim(right.data, weight);

    least.left = left;
    least.right = right;
end%end for loop

%learn an svm for each inner node
trainsvm4node(root, ftspace);


end