function applyColorMapping( img, root, ftdb )
%APPLYCOLORMAPPING do actually mapping of img according to the learned tree
%   function applyColorMapping( img, root )
%   img: image file to be enhanced, should be in RGB color space, M-by-N-by-3 dimension
%   root: root node of the trained tree
%   ftdb: universal feature database
%   Author: lvhao
%   Email: lvhaoexp@163.com
%   Date : 2014-09-03

%convert img to Lab color space
[ rownum, colnum, ~ ] = size( img );
colorTransform = makecform('srgb2lab');
img_lab = single(applycform(img, colorTransform));
img_2dim = reshape(img_lab, rownum*colnum, 3);

%generate gradient map
[gx.l, gy.l] = gradient(img_lab(:,:,1));
[gx.a, gy.a] = gradient(img_lab(:,:,2));
[gx.b, gy.b] = gradient(img_lab(:,:,3));


%extract feature map
ftmap = zeros(ftnum, rownum*colnum);
ftmap_first = pfeature(img_lab, gx, gy);
ftmap(1:23, :) = ftmap_first;
ftmap(24, :) = gx.l(:);
ftmap(25, :) = gy.l(:);
ftmap(26, :) = reshape(img_lab(:,:,1), 1, rownum*colnum);


%soft segmented image
sfimg = softseg( img, ftdb );

[rows, cols, K] = size(sfimg);

%build a histogram for all leaf node
leafs = buildLeafArray( root );

%for each edit, find out pixels with probability > 0.5
for k = 1:K
  pixpos = find( sfimg(:,:, k) > 0.5 );
  hist = zeros( size(leafs) );
  
  %for current segment, build voting histogram
  
  
end