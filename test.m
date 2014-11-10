load roots/root.mat;
trainImgFolder = 'res/images/training2';
imL = imread(strcat(trainImgFolder , '/7_HD.jpg'));
tic
imfinal = applyColorMapping(imL, root);
toc
imwrite(imfinal, strcat(trainImgFolder, '/7-en.jpg'));

% $$$ imL = imread(strcat(trainImgFolder , '/8_HD.jpg'));
% $$$ tic
% $$$ imfinal = applyColorMapping(imL, root);
% $$$ toc
% $$$ imwrite(imfinal, strcat(trainImgFolder, '/8-en.jpg'));
% $$$ 
% $$$ imL = imread(strcat(trainImgFolder , '/9_HD.jpg'));
% $$$ tic
% $$$ imfinal = applyColorMapping(imL, root);
% $$$ toc
% $$$ imwrite(imfinal, strcat(trainImgFolder, '/9-en.jpg'));