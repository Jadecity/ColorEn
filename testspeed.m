img = imread('res/images/1_H.jpg');
[rows, cols, chan] = size(img)
tic
b=exp(double(img));
toc
imgd = double(img);
tic
imgd_r = reshape(imgd, [rows*cols chan])';
imgd_r = reshape(imgd_r, [chan 1 rows*cols]);
toc
tic
imgd_rep = repmat(imgd_r, [1 500 1]);
toc
tic
ce = cell(1,500);