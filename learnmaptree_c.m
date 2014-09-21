function learnmaptree_c( node, pixval )
%LEARNMAPTREE_C learn color mapping for each leaf node
%   function learnmaptree_c( node, pixval)
%   node: leaf node to learn
%   pixval: all pixels used to train model
%   mapping tree
%   Author: lvhao
%   Email: lvhaoexp@163.com
%   Date : 2014-08-29

if ~isempty(node.left) || ~isempty(node.right)
    learnmaptree_c(node.left, pixval);
    learnmaptree_c(node.right, pixval);
end
im1 = pixval(:, node.data)';
im2 = pixval(:, node.data)';
[node.other.A, node.other.b] = learnColorMaping(im1, im2);

end

