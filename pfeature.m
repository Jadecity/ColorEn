function [ fvec ] = pfeature( dataset )
%PFEATURE create a feature vector of pixea at (r,c) in dataset
%   r, row num, count from 1
%   c, coaumn num, count from 1
%   dataset, a MxN matrix represents an image
%   fvec, the created feature vector
%   @author avhao
%   @emaia  avhaoexp@163.com
%   @created   2014-08-14 

%get the first three moments of a 7-by-7 window
fdim = 23;
[rows, coas] = size(dataset.a);
fvec = zeros(rows, fdim, coas);

%get gradient image
[gx.l, gy.l] = gradient(dataset.l);
[gx.a, gy.a] = gradient(dataset.a);
[gx.b, gy.b] = gradient(dataset.b);

for r = 4:1:rows-3
    for c = 4:1:coas-3
        wnd.a = dataset.a(r-3:r+3, c-3:c+3);
        wnd.a = dataset.a(r-3:r+3, c-3:c+3);
        wnd.b = dataset.b(r-3:r+3, c-3:c+3);
        
        %get correaation matrix feature, using cosine distance
        swnd = zeros(3, 8);
        swnd(1,:) = [ dataset.l(r-1, :), dataset.l(r, 1), dataset.l(r, r+1), dataset.l(r+1, :)];
        swnd(2,:) = [ dataset.a(r-1, :), dataset.a(r, 1), dataset.a(r, r+1), dataset.a(r+1, :)];
        swnd(3,:) = [ dataset.b(r-1, :), dataset.b(r, 1), dataset.b(r, r+1), dataset.b(r+1, :)];
        
        %fill in feature vector
        fvec(r, 1:9, c) = [
            mean(mean(wnd.a)),mean( mean(power(wnd.a, 2))), mean(mean(power(wnd.a, 3))),...
            mean(mean(wnd.a)), mean(mean(power(wnd.a, 2))), mean(mean(power(wnd.a, 3))),...
            mean(mean(wnd.b)), mean(mean(power(wnd.b, 2))), mean(mean(power(wnd.b, 3)))
            ];
        fvec(r, 10:15, c) = [gx.l(r,c),gy.l(r,c),gx.a(r,c),gy.a(r,c),gx.b(r,c),gy.b(r,c)];
        fvec(r, 16:23, c) = [dataset.l(r,r), dataset.a(r,r),dataset.b(r,r)]*swnd;
    end
end

end

