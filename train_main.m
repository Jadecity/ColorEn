%this file is the main file containing the train procedure
%   Author: lvhao
%   Email: lvhaoexp@163.com
%   Date: 2014-08-30

clc;
clear all;

trainImgFolder = 'res/images/training3';
imgnum = 7;
%ftnum = 31;
wdim_max = 20000;


if ~exist('ftmap.mat', 'file')
    display('start building feature map');
    tic
    %for each image pair, get feature
    cnt=1;
    for num = 1:imgnum
        %read in images
        imLname = strcat(trainImgFolder, '/mx-',num2str(num),'-2.jpg');
        imHname = strcat(trainImgFolder, '/mx-',num2str(num),'-reg2-3.jpg');
        imL = imread(imLname);
        imH = imread(imHname);
        [rownum, colnum, ~] = size(imL);
        %do color space stransform
        imL_lab = rgb2lab(imL);
        imH_lab = rgb2lab(imH);
        imL_2dim = reshape(imL_lab, rownum*colnum, 3);
        imH_2dim = reshape(imH_lab, rownum*colnum, 3);

        %create gradient map
        [gLx.l, gLy.l] = gradient(imL_lab(:,:,1));
        [gLx.a, gLy.a] = gradient(imL_lab(:,:,2));
        [gLx.b, gLy.b] = gradient(imL_lab(:,:,3));
        [gHx.l, gHy.l] = gradient(imH_lab(:,:,1));
        [gHx.a, gHy.a] = gradient(imH_lab(:,:,2));
        [gHx.b, gHy.b] = gradient(imH_lab(:,:,3));

        region = (cnt-1)*rownum*colnum+1:cnt*rownum*colnum;
        ftmap_first = pfeature(imL_lab, gLx, gLy);
        ftmap(1:20, region) = ftmap_first;
        ftmap(21, region) = gHx.l(:);
        ftmap(22, region) = gHy.l(:);
        ftmap(23:25, region) = imH_2dim';
        %not part of feature, only to embed pixel information
        ftmap(26:28, region) = imL_2dim';
        cnt = cnt + 1;
        clear ftmap_first;
    end
    toc
    save ftmap.mat ftmap;
else
    display('start loading feature map');
    load ftmap.mat;
end

%pick 20000 points to train model
[~, c] = find(isnan(ftmap));
ftmap(:,c) = [];%remove all columns containing Nan
ftmap(:, all(ftmap==0,1)) = [];%remove all zeros columns
pixselected = randperm(size(ftmap,2), wdim_max);
newftmap = ftmap(:, pixselected);

%train mapping tree, point is numbered by the same rule with matlab when 
%dealing with matrix elements
root = BinTreeNode();
root.data = 1:wdim_max;

display('building tree');
tic
buildTree(root, newftmap(1:25,:), 'color');
toc

display('learning mapping');
tic
learnmaptree_c(root, newftmap(23:28,:));
toc
%clear all big variables, left only tree root and save root
clearvars -except root newftmap;
save roots\root-mx2-mx3.mat root;
save newftmap.mat newftmap;
