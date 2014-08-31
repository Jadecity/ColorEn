%this file is the main file containing the train procedure
%   Author: lvhao
%   Email: lvhaoexp@163.com
%   Date: 2014-08-30

clear
%total 100 images
trainImgFolder = 'res/images'
%for each image pair
tic
rownum = 512;
colnum = 512;
ftnum = 28;
for num = 1:1
    %read in images
    imLname = strcat(trainImgFolder, '/',num2str(num),'_L.jpg');
    imHname = strcat(trainImgFolder, '/',num2str(num),'_H.jpg');
    imL = imread(imLname);
    imH = imread(imHname);
    colorTransform = makecform('srgb2lab');
    imL_lab = single(applycform(imL, colorTransform));
    imH_lab = single(applycform(imH, colorTransform));
    
    %create gradient map
    [gLx.l, gLy.l] = gradient(imL_lab(:,:,1));
    [gLx.a, gLy.a] = gradient(imL_lab(:,:,2));
    [gLx.b, gLy.b] = gradient(imL_lab(:,:,3));
    [gHx.l, gHy.l] = gradient(imH_lab(:,:,1));
    [gHx.a, gHy.a] = gradient(imH_lab(:,:,2));
    [gHx.b, gHy.b] = gradient(imH_lab(:,:,3)); 
    ftmap = zeros(rownum, colnum, ftnum);
    ftmap_first = pfeature(imL_lab, gLx, gLy);
    ftmap(:,:,1:23) = ftmap_first;
    ftmap(:,:,24) = gHx.l;
    ftmap(:,:,25) = gHy.l;
    ftmap(:,:,26:28) = imH_lab;
    clear ftmap_first
end
toc