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

dist = 1./pdist(ftspace');
dist(all(dist==Inf, 1)) = 0;%replace Inf to 0
gweight = squareform(dist);
root.other.sim = avgsim(size(root.data,2), gweight);
for cnt=1:loop
    display(sprintf('----itr: %d',cnt));
    tic
    %find a suitable node to split
    least = findLeastSim(root,[]);
    clear gnode;
    display(sprintf('Data to split: %d', size(least.data,2)));
    display(sprintf('Data sim: %d', least.other.sim));
    
    %if no child can be split, split root
    if isempty(least)
        least = root;
    end

    if size(least.data, 2) < 10
        least.other.toosmall=true;
        continue;
    end
    weight = gweight(least.data, least.data);
    %weight = SimGraph_Full(ftspace(:, least.data), 100);
    [c1, c2] = minmaxcut(weight);
%     Cluster = SpectralClustering(weight, 2, 3);
%     Cluster = logical(Cluster);
    left = BinTreeNode();
    right = BinTreeNode();
    left.data = least.data(c1);
    right.data = least.data(c2);
    left.other.sim = avgsim(size(c1,1), gweight(left.data, left.data));
    right.other.sim = avgsim(size(c2,1), gweight(right.data, right.data));
    left.other.weight = sum(sum(gweight(left.data, left.data)));
    right.other.weight = sum(sum(gweight(right.data, right.data)));
    left.other.depth = least.other.depth + 1;
    right.other.depth = left.other.depth;
    least.left = left;
    least.right = right;
    
    display(sprintf('Data left: %d', size(left.data,2)));
    display(sprintf('Data right: %d', size(right.data,2)));
    display(sprintf('Data left weight: %d', left.other.weight));
    display(sprintf('Data right weight: %d', right.other.weight));
    display(sprintf('Data left sim: %d', left.other.sim));
    display(sprintf('Data right sim: %d', right.other.sim));
    toc
end%end for loop

%learn an svm for each inner node
display('training svm');
tic
trainsvm4node(root, ftspace);
toc

end