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

maxloop = 500;
if strcmp(maptype, 'color')
    loop = 300;
end
if strcmp(maptype, 'luminance')
    loop = 200;
end

%dist = 1./pdist(ftspace');
%dist(all(dist==Inf, 1)) = 0;%replace Inf to 0
%gweight = squareform(dist);
ftdim = size(ftspace, 2);
maxneibor = ceil(0.025*ftdim);
neibor = maxneibor;
weight = SimGraph_NearestNeighbors( ftspace, neibor, 1,  1);
root.other.sim = full( avgsim(size(root.data,2), weight) );
realcnt = 0;
for cnt=1:maxloop
    if realcnt > loop
        break;
    end
    display(sprintf('----itr: %d, realcnt: %d',cnt, realcnt));
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

    if size(least.data, 2) < 20
        least.other.toosmall=true;
        continue;
    end
    if cnt ~= 1
        if numel(least.data) < maxneibor
            weight = SimGraph_Full(ftspace(:,least.data), 1);
        else
            neibor = maxneibor;
            weight = SimGraph_NearestNeighbors( ftspace(:,least.data), ...
                                                neibor, 1, 1);
        end
    end
    
    Cluster = SpectralClustering(weight, 2, 3);
    c1 = logical( Cluster(:,1) );
    c2 = logical( Cluster(:,2) );
%    [c1, c2] = minmaxcut(weight);
%     Cluster = SpectralClustering(weight, 2, 3);
%     Cluster = logical(Cluster);
    left = BinTreeNode();
    right = BinTreeNode();
    left.data = least.data(c1);
    right.data = least.data(c2);
    left.other.sim = full( avgsim(size(c1,1), weight(c1, c1)) );
    right.other.sim = full( avgsim(size(c2,1), weight(c2, c2)) );
    left.other.weight = full( sum(sum(weight(c1, c1))) );
    right.other.weight = full( sum(sum(weight(c2, c2))) );
    left.other.depth = least.other.depth + 1;
    right.other.depth = left.other.depth;
    least.left = left;
    least.right = right;
    
    realcnt = realcnt + 1;
    display(sprintf('Data left: %d', size(left.data,2)));
    display(sprintf('Data right: %d', size(right.data,2)));
    display(sprintf('Data left weight: %d', left.other.weight ...
                    ));
    display(sprintf('Data right weight: %d', right.other.weight ...
                    ));
    display(sprintf('Data left sim: %d', left.other.sim ));
    display(sprintf('Data right sim: %d',right.other.sim ));
    toc
end%end for loop

%learn an svm for each inner node
display('training svm');
tic
trainsvm4node(root, ftspace);
toc

end