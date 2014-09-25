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
fdim = 15;
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

casimg2.l = casimg.l.^2;
casimg2.a = casimg.a.^2;
casimg2.b = casimg.b.^2;
casimg3.l = casimg2.l.*casimg.l;
casimg3.a = casimg2.a.*casimg.a;
casimg3.b = casimg2.b.*casimg.b;
%power and normalize data
ncasimg2.l = mat2gray(mean( casimg2.l, 3 ));
ncasimg2.a = mat2gray(mean( casimg2.a, 3 ));
ncasimg2.b = mat2gray(mean( casimg2.b, 3 ));
ncasimg3.l = mat2gray(mean( casimg3.l, 3 ));
ncasimg3.a = mat2gray(mean( casimg3.a, 3 ));
ncasimg3.b = mat2gray(mean( casimg3.b, 3 ));
ncasimg.l  = mat2gray(mean( casimg.l, 3 )); 
ncasimg.a  = mat2gray(mean( casimg.a, 3 ));
ncasimg.b  = mat2gray(mean( casimg.b, 3 ));


fvec(1:9,:) = reshape(cat(3,ncasimg.l, ncasimg2.l,ncasimg3.l,...
					ncasimg.a, ncasimg2.a, ncasimg3.a,...
					ncasimg.b, ncasimg2.b, ncasimg3.b...
				), [rows*cols, 9])';
fvec(10:15, :) = reshape(cat(3, gx.l, gy.l, gx.a, gy.a, gx.b, gy.b...
				), [rows*cols, 6])';
cnt = 1;
% for idx = 1:rows*cols

% cut 8 dimension when its meaning unkown
% for m = -1:1
%     for n=-1:1
%     %get correlation matrix feature, using Eul distance
%     if m==0 && n==0
%         continue;
%     end
%     dist = sqrt(sum((dataset-imgPadded(4+m:3+m+rows, 4+n:3+n+cols,:)).^2, 3)/3);
%     fvec(15+cnt, :) = dist(:);
%     cnt = cnt + 1;
%     end
% end

end

