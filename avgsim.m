function [ avgs ] = avgsim( elenum, w )
%AVGSIM is to cal similarity between two clusters
%   function [ avgs ] = avgsim( ck, w )
%   elenum is the k-th cluster's capacity
%   w is the weight matrix
%   avgs is the output score of self similarity

avgs = 0.5*sum(sum(w))/elenum^3;

end

