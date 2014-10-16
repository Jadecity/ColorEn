function img_final = applyColorMapping( img, root )
%APPLYCOLORMAPPING do actually mapping of img according to the learned tree
%   function applyColorMapping( img, root )
%   img: image file to be enhanced, should be in RGB color space, M-by-N-by-3 dimension
%   root: root node of the trained tree
%   ftdb: universal feature database
%   img_final: enhanced img in RGB color space
%   Author: lvhao
%   Email: lvhaoexp@163.com
%   Date : 2014-09-03

%convert img to Lab color space
[ rownum, colnum, ~ ] = size( img );
img_lab = rgb2lab(img, 'srgb', 'D65/10');
img_2dim = reshape(img_lab, rownum*colnum, 3)';

%generate gradient map
[gx.l, gy.l] = gradient(img_lab(:,:,1));
[gx.a, gy.a] = gradient(img_lab(:,:,2));
[gx.b, gy.b] = gradient(img_lab(:,:,3));


%extract feature map
ftnum = 25;
ftmap = zeros(ftnum, rownum*colnum);
ftmap_first = pfeature(img_lab, gx, gy);

ftmap(1:20, :) = ftmap_first;
ftmap(21, :) = gx.l(:);
ftmap(22, :) = gy.l(:);
ftmap(23:25, :) = reshape(img_lab, rownum*colnum, 3)';

%build a histogram for all leaf node
leafs = buildLeafArray( root,[],[] );

%merge final color enhanced image
img_final = zeros( 3, rownum*colnum );
%for each pix in current seg, do color mapping
l = img_2dim(1,:);
a = img_2dim(2,:);
b = img_2dim(3,:);
Qi = cat(1,l.^2,a.^2,b.^2,l.*a,l.*b,a.*b,l,a,b);
for p=1:rownum*colnum
ft = ftmap( :, p );
lfnode = ftclassify( ft, root );
img_final(:,p) = bsxfun(@plus,Qi(:,p)'*lfnode.other.A', lfnode.other.b);
end

img_final = reshape(img_final', rownum, colnum, 3);
img_final = lab2rgb(img_final);