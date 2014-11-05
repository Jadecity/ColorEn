function  ftclassify2( ft, root )
%FTCLASSIFY2 find the corresponding leaf node of the feature vector
%   function ftclassify2( ft, root )
%   ft: feature vector2 to be classified
%   root: root node of the trained tree
%   Author: lvhao
%   Email: lvhaoexp@163.com
%   Date : 2014-11-05

curnode = root;
if ~isempty( curnode.left ) && ~isempty( curnode.right ) && ...
                                            ~isempty(curnode.data) ...
    %not leaf and have data to classify
    ft2 = ft(:, curnode.data);
    label = svmpredict( ones(size(ft2, 2), 1), ft2', curnode.other.svm);
    curnode.left.data = root.data( ~logical(label) ); % 0 to right
    curnode.right.data = root.data( logical(label) ); % 1 to left
    
    ftclassify2( ft, curnode.left );
    ftclassify2( ft, curnode.right );

end

end