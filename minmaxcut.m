function [ ds1, ds2 ] = minmaxcut( w )
%use minmaxcut from Chris Ding and Xiaofeng He to cluster data
%   [ds1, ds2] = minmaxcut( w )
%   ds1, ds2 are column vectors contains element indexes of each class
%   w is a weight matrix
D = diag( sum(w) );
w_hat = ( D^(-0.5) )* w *( D^(-0.5) );
[V, ~] = eigs( w_hat , 2);

%output data point index to ds1 and ds2
ds1 = find(V(:,2) > 0);
ds2 = find(V(:,2) < 0);
end