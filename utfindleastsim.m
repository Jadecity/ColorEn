root = BinTreeNode();
root.other.sim = 8;
root.left = BinTreeNode();
root.left.other.sim = 9;
root.right = BinTreeNode();
root.right.other.sim = 7;
right = root.right;
right.left = BinTreeNode();
right.left.other.sim = 4;
right.right = BinTreeNode();
right.right.other.sim = 10;

node = findLeastSim(root);
node

%test passed