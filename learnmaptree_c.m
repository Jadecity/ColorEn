function learnmaptree_c( node, imL, imH )
%LEARNMAPTREE_C learn color mapping for each leaf node
%   function learnmaptree_c( node, imL, imH)
%   node: leaf node to learn
%   imL: low quality image pixels, N-by-3, Lab in sequence
%   imH: high quality image pixels, N-by-3, Lab in sequence
%   mapping tree
%   Author: lvhao
%   Email: lvhaoexp@163.com
%   Date : 2014-08-29

if ~isempty(node.left) || ~isempty(node.right)
    learnmaptree_c(node.left, imL, imH);
    learnmaptree_c(node.right, imL, imH);
end
im1 = imL(node.data, :);
im2 = imH(node.data, :);
[node.other.A, node.other.b] = learnColorMaping(im1, im2);

end

