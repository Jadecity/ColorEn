function [ fvec ] = pfeature( dataset,  gx, gy )
%PFEATURE create a feature vector of pixea at (r,c) in dataset
%   r, row num, count from 1
%   c, column num, count from 1
%   dataset, a M-by-N-by-3 matrix represents an image in lab color space
%   fvec, the created feature vector, 23-by-M*N, 23 is the feature
%   length
%   this function runs in 2.7seconds when input is 512*512
%   author: lvhao
%   email:  lvhaoexp@163.com
%   created   2014-08-14 

%get the first three moments of a 7-by-7 window
fdim = 20;
winsz = 7;
[rows, cols, ~] = size(dataset);
fvec = zeros(fdim, rows*cols );
imgPadded = padarray(dataset, [3 3],'symmetric','both');


imgp.l = imgPadded(:,:,1);
imgp.a = imgPadded(:,:,2);
imgp.b = imgPadded(:,:,3);
casimg.l = zeros(rows, cols, winsz^2);
casimg.a = zeros(rows, cols, winsz^2);
casimg.b = zeros(rows, cols, winsz^2);
casimg.l(:,:,1) = dataset(:,:,1);
casimg.a(:,:,1) = dataset(:,:,2);
casimg.b(:,:,1) = dataset(:,:,3);

cnt = 2;
tic
for n=-3:3
    for m=-3:3
        if m==0 && n==0
            continue;
        end
        casimg.l(:,:,cnt) = imgp.l(4+n:3+n+rows,4+m:3+m+cols);
        casimg.a(:,:,cnt) = imgp.a(4+n:3+n+rows,4+m:3+m+cols);
        casimg.b(:,:,cnt) = imgp.b(4+n:3+n+rows,4+m:3+m+cols);
	
        cnt = cnt + 1;
    end
end
toc

%power and normalize data
ncasimg2.l = std( casimg.l, 1, 3 );
ncasimg2.a = std( casimg.a, 1, 3 );
ncasimg2.b = std( casimg.b, 1, 3 );
ncasimg3.l = skewness_coloren( casimg.l, 1, 3 );
ncasimg3.a = skewness_coloren( casimg.a, 1, 3 );
ncasimg3.b = skewness_coloren( casimg.b, 1, 3 );
ncasimg.l  = mean( casimg.l, 3 );
ncasimg.a  = mean( casimg.a, 3 );
ncasimg.b  = mean( casimg.b, 3 );


fvec(1:9,:) = reshape(cat(3,ncasimg.l, ncasimg2.l,ncasimg3.l,...
					ncasimg.a, ncasimg2.a, ncasimg3.a,...
					ncasimg.b, ncasimg2.b, ncasimg3.b...
				), [rows*cols, 9])';
fvec(10:15, :) = reshape(cat(3, gx.l, gy.l, gx.a, gy.a, gx.b, gy.b...
				), [rows*cols, 6])';
cnt = 1;

dist = cat(3, imgPadded(3:2+rows, 3:2+cols,:), imgPadded(3:2+rows, 5:4+cols,:)...
                ,imgPadded(5:4+rows, 3:2+cols,:), imgPadded(5:4+rows, 5:4+cols,:));
dist2 = reshape(dist, [rows*cols, 12])';
corrcell = cellfun(@colorCorrMat, num2cell(dist2, 1), 'UniformOutput', false);
corrmat = cell2mat(corrcell);
fvec(15:20, :) = corrmat;


end

