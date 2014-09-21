%this file is the main file containing the train procedure
%   Author: lvhao
%   Email: lvhaoexp@163.com
%   Date: 2014-08-30

clc;
clear all;

trainImgFolder = 'res/images/training';
imgnum = 7;
ftnum = 31;
wdim_max = 20000;

display('start building feature map');
tic
%for each image pair, get feature
colorTransform = makecform('srgb2lab');
for num = 1:imgnum
    %read in images
    imLname = strcat(trainImgFolder, '/',num2str(num),'_LD.jpg');
    imHname = strcat(trainImgFolder, '/',num2str(num),'_HD.jpg');
    imL = imread(imLname);
    imH = imread(imHname);
    [rownum, colnum, ~] = size(imL);
    %do color space stransform
    imL_lab = applycform(im2double(imL), colorTransform);
    imH_lab = applycform(im2double(imH), colorTransform);
    imL_2dim = reshape(imL_lab, rownum*colnum, 3);
    imH_2dim = reshape(imH_lab, rownum*colnum, 3);
    
    %create gradient map
    [gLx.l, gLy.l] = gradient(imL_lab(:,:,1));
    [gLx.a, gLy.a] = gradient(imL_lab(:,:,2));
    [gLx.b, gLy.b] = gradient(imL_lab(:,:,3));
    [gHx.l, gHy.l] = gradient(imH_lab(:,:,1));
    [gHx.a, gHy.a] = gradient(imH_lab(:,:,2));
    [gHx.b, gHy.b] = gradient(imH_lab(:,:,3));
    
    region = (num-1)*rownum*colnum+1:num*rownum*colnum;
    ftmap_first = pfeature(imL_lab, gLx, gLy);
    ftmap(1:23, region) = ftmap_first;
    ftmap(24, region) = gHx.l(:);
    ftmap(25, region) = gHy.l(:);
    ftmap(26:28, region) = imH_2dim';
    %not part of feature, only to embed pixel information
    ftmap(29:31, region) = imL_2dim';
    clear ftmap_first;
end
toc
%pick 20000 points to train model
pixselected = randperm(rownum*colnum*imgnum, wdim_max);
newftmap = ftmap(:, pixselected);

%train mapping tree, point is numbered by the same rule with matlab when 
%dealing with matrix elements
root = BinTreeNode();
root.data = 1:wdim_max;
gweight = zeros(wdim_max, wdim_max);
display('getting weight matrix');
tic
for c = 1:wdim_max
    gweight(c,c:end) = sqrt(sum(bsxfun(@minus, newftmap(1:28,c:end), newftmap(1:28,c)).^2)/ftnum);
end
gweight = gweight + gweight';
toc

display('building tree');
tic
buildTree(root, newftmap(1:28,:), gweight, 'color');
toc

display('learning mapping');
tic
learnmaptree_c(root, newftmap(29:31,:));
toc
%clear all big variables, left only tree root and save root
clearvars -except root;
save root.mat root;
