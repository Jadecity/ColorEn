%this file is the main file containing the train procedure
%   Author: lvhao
%   Email: lvhaoexp@163.com
%   Date: 2014-08-30

clc;
clear all;

trainImgFolder = 'res/images/training2';
imgnum = 1;
ftnum = 15;

%init gradient kernel
sobelHE = [-0.25 -0.5 -0.25;
           0 0 0;
           0.25 0.5 0.25];
sobelVE = [0.25 0 -0.25;
           0.5 0 -0.5;
           0.25 0 -0.25];


if ~exist('ftmap.mat', 'file')
    display('start building feature map');
    tic
    %for each image pair, get feature
    region = [0];
    for num = 1:imgnum
        %read in images
        imLname = strcat(trainImgFolder, '/',num2str(num),'_HD.jpg');
        imHname = strcat(trainImgFolder, '/',num2str(num),'_HD2.jpg');
        imL = imread(imLname);
        imH = imread(imHname);
        [rownum, colnum, ~] = size(imL);
        %do color space stransform
        imL_lab = rgb2lab(imL);
        imH_lab = rgb2lab(imH);
        %do normalization
        imL_lab = imL_lab/100;
        imH_lab = imH_lab/100;
        lumavg_L = mean2( imL_lab(:,:,1) );
        lumavg_H = mean2( imH_lab(:,:,1) );
        imL_lab(:,:,1) = imL_lab(:,:,1)*0.65/lumavg_L;
        imH_lab(:,:,1) = imH_lab(:,:,1)*0.65/lumavg_H;
        imL_2dim = reshape(imL_lab, rownum*colnum, 3);
        imH_2dim = reshape(imH_lab, rownum*colnum, 3);
            
        %create gradient map
        %pad image with symmetric method along edges
        imgpadded_L = zeros(rownum+2, colnum+2, 3);
        imgpadded_L(2:rownum+1, 2:colnum+1, :) = imL_lab;
        imgpadded_L([1,end],2:colnum+1, :) = imL_lab([2,end-1], :, :);
        imgpadded_L(2:rownum+1,[1,end], :) = imL_lab(:, [2,end-1], :);
        imgpadded_L(1,1, :) = imL_lab(2,2, :);
        imgpadded_L(end,end, :) = imL_lab(end-1, end-1, :);
        imgpadded_L(1,end,:) = imL_lab(2, end-1, :);
        imgpadded_L(end,1,:) = imL_lab(end-1, 2, :);
        
        imgpadded_H = zeros(rownum+2, colnum+2, 3);
        imgpadded_H(2:rownum+1, 2:colnum+1, :) = imH_lab;
        imgpadded_H([1,end],2:colnum+1, :) = imH_lab([2,end-1], :, :);
        imgpadded_H(2:rownum+1,[1,end], :) = imH_lab(:, [2,end-1], :);
        imgpadded_H(1,1, :) = imH_lab(2,2, :);
        imgpadded_H(end,end, :) = imH_lab(end-1, end-1, :);
        imgpadded_H(1,end,:) = imH_lab(2, end-1, :);
        imgpadded_H(end,1,:) = imH_lab(end-1, 2, :);

        gLx.l = conv2( imgpadded_L(:,:,1), sobelVE, 'same');
        gLy.l = conv2( imgpadded_L(:,:,1), sobelHE, 'same');
        gLx.a = conv2( imgpadded_L(:,:,2), sobelVE, 'same');
        gLy.a = conv2( imgpadded_L(:,:,2), sobelHE, 'same');
        gLx.b = conv2( imgpadded_L(:,:,3), sobelVE, 'same');
        gLy.b = conv2( imgpadded_L(:,:,3), sobelHE, 'same');
        gHx.l = conv2( imgpadded_H(:,:,1), sobelVE, 'same');
        gHy.l = conv2( imgpadded_H(:,:,1), sobelHE, 'same');
        gHx.a = conv2( imgpadded_H(:,:,2), sobelVE, 'same');
        gHy.a = conv2( imgpadded_H(:,:,2), sobelHE, 'same');
        gHx.b = conv2( imgpadded_H(:,:,3), sobelVE, 'same');
        gHy.b = conv2( imgpadded_H(:,:,3), sobelHE, 'same');
        gLx.l = gLx.l(2:rownum+1, 2:colnum+1);
        gLy.l = gLy.l(2:rownum+1, 2:colnum+1);
        gLx.a = gLx.a(2:rownum+1, 2:colnum+1);
        gLy.a = gLy.a(2:rownum+1, 2:colnum+1);
        gLx.b = gLx.b(2:rownum+1, 2:colnum+1);
        gLy.b = gLy.b(2:rownum+1, 2:colnum+1);
        gHx.l = gHx.l(2:rownum+1, 2:colnum+1);
        gHy.l = gHy.l(2:rownum+1, 2:colnum+1);
        gHx.a = gHx.a(2:rownum+1, 2:colnum+1);
        gHy.a = gHy.a(2:rownum+1, 2:colnum+1);
        gHx.b = gHx.b(2:rownum+1, 2:colnum+1);
        gHy.b = gHy.b(2:rownum+1, 2:colnum+1);
        
        region = (num-1)*rownum*colnum+1:num*rownum*colnum;
        ftmap_first = pfeature(imL_lab, gLx, gLy);
        ftmap(1:ftnum, region) = ftmap_first;
        ftmap(ftnum+1, region) = gHx.l(:);
        ftmap(ftnum+2, region) = gHy.l(:);
        ftmap(ftnum+3:ftnum+5, region) = imH_2dim';
        %not part of feature, only to embed pixel information
        ftmap(ftnum+6:ftnum+8, region) = imL_2dim';

        clear ftmap_first;
    end
    toc
    save ftmap.mat ftmap;
else
    display('start loading feature map');
    load ftmap.mat;
end

%pick wdim_max points to train model
[~, c] = find(isnan(ftmap));
ftmap(:,c) = [];%remove all columns containing Nan
ftmap(:, all(ftmap==0,1)) = [];%remove all zeros columns
% $$$ pixselected = randperm(size(ftmap,2), wdim_max);

newftmap = ftmap;

%train mapping tree, point is numbered by the same rule with matlab when 
%dealing with matrix elements
root = BinTreeNode();
root.data = 1:size(newftmap, 2);

display('building tree');
tic
buildTree(root, newftmap(1:ftnum+5,:), 'color');
toc

display('learning mapping');
tic
learnmaptree_c(root, newftmap(end-5:end,:));
toc
%clear all big variables, left only tree root and save root
clearvars -except root newftmap;
save roots/root.2.mat root;
save newftmap.mat newftmap;
