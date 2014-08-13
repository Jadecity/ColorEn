%this is a unit test for minmaxcut function
%   Lv Hao, Email: lvhaoexp@163.com
%   2014-08-13 Created
clear;

p4 = [1, 2];
p2 = [1, 3];
p3 = [8, 9];
p1 = [8, 8];
dist12 = pdist([p1;p2]);
dist13 = pdist([p1;p3]);
dist14 = pdist([p1;p4]);
dist23 = pdist([p2;p3]);
dist24 = pdist([p2;p4]);
dist34 = pdist([p3;p4]);

w = [0, dist12, dist13, dist14;
     dist12, 0, dist23, dist24; 
     dist13, dist23, 0, dist34; 
     dist14, dist24, dist34, 0];
[V, Q] = minmaxcut(w);
V
Q
