function [ A, b ] = learnColorMaping( im1, im2 )
%LEARNCOLORMAPING used to learn a color mapping
%   im1 is the low quality image
%   im2 is the high quality images
%   im1 and im2 are registered so that pixels are corresponding
%   c = AQj+b,where Qj=(L^2,a^2,b^2,La,Lb,ab,L,a,b)

[rows, cols] = size(im1.l);
Q = zeros(rows*cols, 10);
C = zeros(rows*cols, 3);

row = 1;
for r = 1:rows
    for c = 1:cols
        l = im1.l(r,c);
        a = im1.a(r,c);
        b = im1.b(r,c);
        Q(row, :) = [l^2,a^2,b^2,l*a,l*b,a*b,l,a,b, 1];
        C(row, :) = [im2.l(r,c),im2.a(r,c),im2.b(r,c)];
        row = row + 1;
    end
end

res = (Q\C)';
A = res(:, 1:9);
b = res(:, 10)';

end