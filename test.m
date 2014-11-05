load roots/root-mx2-mx3.mat;
trainImgFolder = 'res/images/training3';
%imL = imread(strcat(trainImgFolder , '/mx-8-2.jpg'));
%tic
%imfinal = applyColorMapping(imL, root);
%toc
%imwrite(imfinal, strcat(trainImgFolder, '/mx-8-2-en.jpg'));

%imL = imread(strcat(trainImgFolder , '/mx-9-2.jpg'));
%tic
%imfinal = applyColorMapping(imL, root);
%toc
%imwrite(imfinal, strcat(trainImgFolder, '/mx-9-2-en.jpg'));

imL = imread(strcat(trainImgFolder , '/mx-10-2.jpg'));
tic
imfinal = applyColorMapping(imL, root);
toc
imwrite(imfinal, strcat(trainImgFolder, '/mx-10-2-en.jpg'));