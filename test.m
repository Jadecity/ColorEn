trainImgFolder = 'res/images/training';
imL = imread(strcat(trainImgFolder , '/8_HD.jpg'));
imfinal = applyColorMapping(imL, root);
