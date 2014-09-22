trainImgFolder = 'res/images/training';
imL = imread(strcat(trainImgFolder , '/8_LD.jpg'));
imfinal = applyColorMapping(imL, root);
