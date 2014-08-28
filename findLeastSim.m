function [ goldnode ] = findLeastSim( root )
%FINDLEASTSIM used to find a node with smallest similarity
%   root: the node starting to search from
%   goldnode: the node with smallest similarity, [] if no such one

persistent gnode;
if isempty(root.left) && isempty(root.right)
    gnode = root;
    goldnode = gnode;
    return;
end

lnode = findLeastSim(root.left);
rnode = findLeastSim(root.right);

gnode = lnode;
if ~isempty(rnode)
    if isempty(gnode)
        gnode = rnode;
    else
        if gnode.other.sim < rnode.other.sim
            gnode = rnode;
        end
    end
end
goldnode = gnode;

end

