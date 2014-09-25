function [ A, b ] = learnColorMaping( im1, im2 )
%LEARNCOLORMAPING used to learn a color mapping
%   function [ A, b ] = learnColorMaping( im1, im2 )
%   imL: low quality image pixels, N-by-3, Lab in sequence
%   imH: high quality image pixels, N-by-3, Lab in sequence
%   im1 and im2 are registered so that pixels are corresponding
%   c = AQj+b,where Qj=(L^2,a^2,b^2,La,Lb,ab,L,a,b)

[rows, ~] = size(im1);
Q = zeros(rows, 10);
C = zeros(rows, 3);

row = 1;
for r = 1:rows
    l = im1(r,1);
    a = im1(r,2);
    b = im1(r,3);
    Q(r, :) = [l^2,a^2,b^2,l*a,l*b,a*b,l,a,b, 1];
    C(r, :) = im2(r,:);
end

res = (Q\C)';
A = res(:, 1:9);
b = res(:, 10)';

end