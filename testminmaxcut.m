data=[1 2 3;2 3 3;4 3 1; 9 8 9;8 7 8;10 9 9;2 3 4]';
simmat=squareform( 1./pdist(data') );
[d1, d2]=minmaxcut(simmat);
sim1=avgsim(size(data,2), simmat)
sim2=avgsim(size(data(:, d1),2), simmat(d1,d1))
sim3=avgsim(size(data(:, d2),2), simmat(d2, d2))

% root=BinTreeNode();
% root.other.sim=sim1;
% left=BinTreeNode();
% left.other.sim=sim2;
% right=BinTreeNode();
% right.other.sim=sim3;
% root.left=left;
% root.right=right;
% 
% node=findLeastSim(root, [])