trainImgFolder = 'res/images';

imH = imread(strcat(trainImgFolder , '/Hi/1_H512.jpg'));
imL = imread(strcat(trainImgFolder , '/Low/1_L512.jpg'));
imH_g = rgb2gray(imH);
imL_g = rgb2gray(imL);

[opti, metric] = imregconfig( 'Multimodal');
registered = imregister( imL_g, imH_g, 'rigid', opti, metric);
imshowpair(registered,imH_g);