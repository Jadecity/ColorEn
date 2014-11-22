load roots/root.2.mat;
trainImgFolder = 'res/images/training2';
imL = imread(strcat(trainImgFolder , '/1_HD.jpg'));
tic
imfinal = applyColorMapping(imL, root);
toc
imwrite(imfinal, strcat(trainImgFolder, '/1-en.jpg'));

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