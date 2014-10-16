function [ A, b ] = learnColorMaping( im1, im2 )
%LEARNCOLORMAPING used to learn a color mapping
%   function [ A, b ] = learnColorMaping( im1, im2 )
%   imL: low quality image pixels, 3-by-N, Lab in sequence
%   imH: high quality image pixels, 3-by-N, Lab in sequence
%   im1 and im2 are registered so that pixels are corresponding
%   c = AQj+b,where Qj=(L^2,a^2,b^2,La,Lb,ab,L,a,b)

cols = size(im1,2);
Q = zeros(10, cols);
C = zeros(3, cols);

for c = 1:cols
    l = im1(1,c);
    a = im1(2,c);
    b = im1(3,c);
    Q(:, c) = [l^2,a^2,b^2,l*a,l*b,a*b,l,a,b, 1]';
    C(:, c) = im2(:,c);
end
if rank(Q) < min(size(Q))
    res = (pinv(Q')*C')';
else
    res = (Q'\C')';
end

A = res(:, 1:9);
b = res(:, 10)';

end