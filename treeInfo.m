function info = treeInfo( root )
%TREEINFO store infor of tree to info
%   function info = treeInfo( root )
%   Detailed explanation goes here

persistent inf;
if isempty(inf)
    inf.inode = 0;
    inf.leaf = 0;
end
if isempty(root.left) && isempty(root.right)
    inf.leaf = inf.leaf + 1;
else
    inf.inode = inf.inode + 1;
    treeInfo(root.left);
    treeInfo(root.right);
end

info = inf;

end

