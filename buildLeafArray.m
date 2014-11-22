function [arr, idxout] = buildLeafArray( root, prearr, idx )
%BUILDLEAFARRAY build a vector contains leaf node handles
%   function arr = buildLeafArray( root )
%   root: root node of the tree
%   arr: output vector, contains leaf node handles
%   Author: lvhao
%   Email: lvhaoexp@163.com
%   Date: 2014-09-03
if isempty( idx )
    idx = 0;
end
if isempty( prearr )
  prearr = BinTreeNode();
end
arr = prearr;
idxout =  idx;

if isempty( root.left ) && isempty( root.right )
  idx = idx + 1;
  root.other.idx = idx;
  prearr(idx) = root;
  arr = prearr;
  idxout = idx;
  return;
end

if ~isempty( root.left )
  [arr, idxout] = buildLeafArray( root.left,  arr, idxout);
end

if ~isempty( root.right )
  [arr, idxout] = buildLeafArray( root.right, arr, idxout );
end

end
