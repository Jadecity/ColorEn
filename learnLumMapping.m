function [ alpha, beta ] = learnLumMapping( im1, im1g, im2g )
%LEARNLUMMAPPING 
%   im1 is the low quality image with only luminance channels, N-by-1
%   column vector
%   im1g and im2g are the gradient map of luminance channel
[rows, ~] = size(im1);
A = zeros(rows, 2);
B = zeros(rows, 1);

row = 1;
for r=1:rows
    A(row, :) = [log(im1(r)), 1];
    B(row) = log(abs(im1g(r))/abs(im2g(r)));
end
res = (A\B)';
alpha = res(2);
beta = res(1);

end

