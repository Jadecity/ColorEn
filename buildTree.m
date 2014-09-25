function buildTree( root, ftspace,  maptype )
%BUILDMAPTREE use feature space to build a mapping tree
%   function buildTree( ftspace, maptype )
%   maptype: either 'color' or 'luminance'
%   ftspace: feature space, each column is a feature vector of a point
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

gweight = squareform(pdist(ftspace'));
for cnt=1:loop
    display(sprintf('itr: %d',cnt));
    tic
    %find a suitable node to split
    least = findLargestLeaf(root,[]);
    clear gnode;
    display(sprintf('Data to split: %d', size(least.data,2)));
    
    %if no child can be split, split root
    if isempty(least)
        least = root;
    end

    if size(least.data, 2) < 10
        continue;
    end
    weight = gweight(least.data, least.data);
    %weight = SimGraph_Full(ftspace(:, least.data), 100);
%     [c1, c2] = minmaxcut(weight);
    Cluster = SpectralClustering(weight, 2, 3);
    Cluster = logical(Cluster);
    left = BinTreeNode();
    right = BinTreeNode();
    left.data = least.data(Cluster(:,1));
    right.data = least.data(Cluster(:,2));
    least.left = left;
    least.right = right;
    
    display(sprintf('Data left: %d', size(left.data,2)));
    display(sprintf('Data right: %d', size(right.data,2)));
    toc
end%end for loop

%learn an svm for each inner node
display('training svm');
tic
trainsvm4node(root, ftspace);
toc

end