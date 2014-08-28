function [ alpha, beta ] = learnLumMapping( im1, im1g, im2g )
%LEARNLUMMAPPING 
%   im1 is the low quality image with three channels: im1.l,im1.a,im1.b
%   im1g and im2g are the gradient map of luminance channel
[rows, cols] = size(im1.l);
A = zeros(rows*cols, 2);
B = zeros(rows*cols, 1);

row = 1;
for r=1:rows
    for c=1:cols
        A(row, :) = [log(im1.l(r,c)), 1];
        B(row) = log(abs(im1g(r,c))/abs(im2g(r,c)));
        row = row + 1;
    end
end
res = (A\B)';
alpha = res(2);
beta = res(1);

end

