function [ avgs ] = avgsim( ck, w )
%AVGSIM is to cal similarity between two clusters
%   function [ avgs ] = avgsim( ck, w )
%   ck is the k-th cluster's index,[1,2,3] for examples
%   w is the weight matrix
%   avgs is the output score of self similarity

wnd = w(ck, ck);
avgs = sum(sum(wnd))/(size(ck,2)^2);

end

