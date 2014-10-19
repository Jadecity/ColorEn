function [ goldnode ] = findLeastSim( root, gnode )
%FINDLEASTSIM used to find a node with smallest similarity
%   root: the node starting to search from
%   goldnode: the node with smallest similarity, [] if no such one
goldnode = [];
if isempty(root)
    goldnode = gnode;
    return;
end

if isempty(gnode)
    gnode = BinTreeNode();
    gnode.other.sim=Inf;
    goldnode = gnode;
end

if ~isempty(root.left) || ~isempty(root.right)
    gnode = findLeastSim(root.left,gnode);
    gnode = findLeastSim(root.right,gnode);
    goldnode = gnode;
else
    if ~root.other.toosmall && root.other.sim < gnode.other.sim
        gnode = root;
    end
    goldnode = gnode;
end

end

