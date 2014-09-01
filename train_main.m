%this file is the main file containing the train procedure
%   Author: lvhao
%   Email: lvhaoexp@163.com
%   Date: 2014-08-30

clear
%total 100 images
trainImgFolder = 'res/images';
%for each image pair
tic
rownum = 100;
colnum = 100;
ftnum = 28;
wdim_max = 10000;
for num = 1:1
    %read in images
    imLname = strcat(trainImgFolder, '/',num2str(num),'_L100.jpg');
    imHname = strcat(trainImgFolder, '/',num2str(num),'_H100.jpg');
    imL = imread(imLname);
    imH = imread(imHname);
    colorTransform = makecform('srgb2lab');
    imL_lab = single(applycform(imL, colorTransform));
    imH_lab = single(applycform(imH, colorTransform));
    imL_2dim = reshape(imL_lab, rownum*colnum, 3);
    imH_2dim = reshape(imH_lab, rownum*colnum, 3);
    
    %create gradient map
    [gLx.l, gLy.l] = gradient(imL_lab(:,:,1));
    [gLx.a, gLy.a] = gradient(imL_lab(:,:,2));
    [gLx.b, gLy.b] = gradient(imL_lab(:,:,3));
    [gHx.l, gHy.l] = gradient(imH_lab(:,:,1));
    [gHx.a, gHy.a] = gradient(imH_lab(:,:,2));
    [gHx.b, gHy.b] = gradient(imH_lab(:,:,3)); 
    ftmap = zeros(ftnum, rownum*colnum);
    ftmap_first = pfeature(imL_lab, gLx, gLy);
    ftmap(1:23, :) = ftmap_first;
    ftmap(24, :) = gHx.l(:);
    ftmap(25, :) = gHy.l(:);
    ftmap(26, :) = reshape(imH_lab(:,:,1), 1, rownum*colnum);
    clear ftmap_first;
end
toc
root = BinTreeNode();
%point is numbered by the same rule with matlab when dealing with matrix
%elements
root.data = 1:rownum*colnum;
gweight = zeros(wdim_max, wdim_max);
for c = 1:rownum*colnum
    gweight(c,c:end) = abs(acos(ftmap(:,c)'*ftmap(:,c:end)));
end
buildTree(root, ftmap, gweight, 'color');
learnmaptree_c(root, imL_2dim, imH_2dim);

%clear all big variables, left only tree root
clear cnt;
clear imL_2dim imH_2dim ftmap gweight imL imH imL_lab imH_lab gLx gLy gHx gHy;
