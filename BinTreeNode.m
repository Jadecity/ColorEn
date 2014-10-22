classdef BinTreeNode < handle
    %BINTREENODE represents the node of a binary tree
    %   data holds content of current node
    %   right holds the handle of right child
    %   left holds the handle of left child
    %   node doesn't holds its parrent handle, thus it's one-direction tree
    %   node, and tree root should be stored independently.
    %   @author lvhao
    %   @email  lvhaoexp@163.com
    %   @created   2014-08-14
    
    properties
        data;
        right;
        left;
        other;
    end
    
    methods
        function obj = BinTreeNode()
            obj.data = [];
            obj.right = [];
            obj.left = [];
            obj.other = [];
            obj.other.toosmall=false;
            obj.other.depth = 0;
        end
    end
    
end

