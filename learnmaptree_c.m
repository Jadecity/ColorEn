function learnmaptree_c( node, pixval )
%LEARNMAPTREE_C learn color mapping for each leaf node
%   function learnmaptree_c( node, pixval)
%   node: leaf node to learn
%   pixval: all pixels used to train model
%   mapping tree
%   Author: lvhao
%   Email: lvhaoexp@163.com
%   Date : 2014-08-29
if isempty(node)
    return;
end

if ~isempty(node.left) || ~isempty(node.right)%inner node
    learnmaptree_c(node.left, pixval);
    learnmaptree_c(node.right, pixval);
end
if isempty(node.left) && isempty(node.right)%leaf node
    im1 = pixval(4:6, node.data);%low quality image
    im2 = pixval(1:3, node.data);%high quality image
    [node.other.A, node.other.b] = learnColorMaping(im1, im2);
end

end

