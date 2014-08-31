function [ fvec ] = pfeature( dataset,  gx, gy )
%PFEATURE create a feature vector of pixea at (r,c) in dataset
%   r, row num, count from 1
%   c, column num, count from 1
%   dataset, a M-by-N-by-3 matrix represents an image in lab color space
%   fvec, the created feature vector, 23-by-M*N, 23 is the feature
%   length
%   author: lvhao
%   email:  lvhaoexp@163.com
%   created   2014-08-14 

%get the first three moments of a 7-by-7 window
fdim = 23;
[rows, cols, ~] = size(dataset);
fvec = zeros(fdim, rows*cols );
cnt = 1;
for c = 4:1:cols-3
    for r = 4:1:rows-3
        wnd.l = dataset(r-3:r+3, c-3:c+3,1);
        wnd.a = dataset(r-3:r+3, c-3:c+3,2);
        wnd.b = dataset(r-3:r+3, c-3:c+3,3);

        %get correlation matrix feature, using cosine distance
        swnd = zeros(3, 8);
        swnd(1,:) = [ dataset(r-1, c-1:c+1,1), dataset(r, c-1, 1), dataset(r, c+1,1), dataset(r+1, c-1:c+1,1)];
        swnd(2,:) = [ dataset(r-1, c-1:c+1,2), dataset(r, c-1, 2), dataset(r, c+1,2), dataset(r+1, c-1:c+1,2)];
        swnd(3,:) = [ dataset(r-1, c-1:c+1,3), dataset(r, c-1, 3), dataset(r, c+1,3), dataset(r+1, c-1:c+1,3)];
        
        %fill in feature vector
        fvec(1:9, cnt) = [
            mean(mean(wnd.l)),mean( mean(power(wnd.l, 2))), mean(mean(power(wnd.l, 3))),...
            mean(mean(wnd.a)), mean(mean(power(wnd.a, 2))), mean(mean(power(wnd.a, 3))),...
            mean(mean(wnd.b)), mean(mean(power(wnd.b, 2))), mean(mean(power(wnd.b, 3)))
            ];
        fvec(10:15, cnt) = [gx.l(r,c),gy.l(r,c),gx.a(r,c),gy.a(r,c),gx.b(r,c),gy.b(r,c)];
        fvec(16:23, cnt) = [dataset(r,c,1), dataset(r,c,2),dataset(r,c,3)]*swnd;
    end
end

end

