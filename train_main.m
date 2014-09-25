%this file is the main file containing the train procedure
%   Author: lvhao
%   Email: lvhaoexp@163.com
%   Date: 2014-08-30

clc;
clear all;

trainImgFolder = 'res/images/training';
imgnum = 7;
ftnum = 23;
wdim_max = 20000;

display('start building feature map');
tic
%for each image pair, get feature
for num = 1:imgnum
    %read in images
    imLname = strcat(trainImgFolder, '/',num2str(num),'_LD.jpg');
    imHname = strcat(trainImgFolder, '/',num2str(num),'_HD.jpg');
    imL = imread(imLname);
    imH = imread(imHname);
    [rownum, colnum, ~] = size(imL);
    %do color space stransform
    imL_lab = rgb2lab(imL, 'srgb', 'D65/10');
    imH_lab = rgb2lab(imH, 'srgb', 'D65/10');
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
    ftmap(1:15, region) = ftmap_first;
    ftmap(16, region) = gHx.l(:);
    ftmap(17, region) = gHy.l(:);
    ftmap(18:20, region) = imH_2dim';
    %not part of feature, only to embed pixel information
    ftmap(21:23, region) = imL_2dim';
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
% gweight = zeros(wdim_max, wdim_max);
display('getting weight matrix');
% tic
% % gweight = SimGraph_NearestNeighbors(newftmap(1:28, :),20, 1, 1); 
% gweight = SimGraph_Full(newftmap(1:28, :), 200); 
% toc

display('building tree');
tic
buildTree(root, newftmap(1:20,:), 'color');
toc

display('learning mapping');
tic
learnmaptree_c(root, newftmap(18:23,:));
toc
%clear all big variables, left only tree root and save root
clearvars -except root newftmap;
save root.mat root;
save newftmap.mat newftmap;
