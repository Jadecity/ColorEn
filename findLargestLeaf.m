function [ goldnode ] = findLargestLeaf( root,gnode )
%FINDLARGESTLEAF Summary of this function goes here
%   Detailed explanation goes here
goldnode = [];
if isempty(root)
    goldnode = gnode;
    return;
end

if isempty(gnode)
    gnode = BinTreeNode();
    goldnode = gnode;
end

if ~isempty(root.left) || ~isempty(root.right)
    gnode = findLargestLeaf(root.left,gnode);
    gnode = findLargestLeaf(root.right,gnode);
    goldnode = gnode;
else
    if size(root.data,2) > size(gnode.data,2)
        gnode = root;
    end
    goldnode = gnode;
end

end

