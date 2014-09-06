function hdl = ftclassify( ft, root )
%FTCLASSIFY find the corresponding leaf node of the feature vector
%   function ftclassify( ft, root )
%   ft: feature vector to be classified
%   root: root node of the trained tree
%   hdl: output handle of the respective leaf node
%   Author: lvhao
%   Email: lvhaoexp@163.com
%   Date : 2014-09-03

curnode = root;
while ~isempty( curnode.left ) && ~isempty( curnode.right )
  label = svmpredict( 1, ft, curnode.other.svm);
  if label == 0
    curnode = curnode.left;
  else
    curnode = curnode.right;
end

hdl = curnode;