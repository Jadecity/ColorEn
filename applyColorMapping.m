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
colorTransform = makecform('srgb2lab');
img_lab = single(applycform(double(img), colorTransform));
img_2dim = reshape(img_lab, rownum*colnum, 3);

%generate gradient map
[gx.l, gy.l] = gradient(img_lab(:,:,1));
[gx.a, gy.a] = gradient(img_lab(:,:,2));
[gx.b, gy.b] = gradient(img_lab(:,:,3));


%extract feature map
ftnum = 26;
ftmap = zeros(ftnum, rownum*colnum);
ftmap_first = pfeature(img_lab, gx, gy);

ftmap(1:23, :) = ftmap_first;
ftmap(24, :) = gx.l(:);
ftmap(25, :) = gy.l(:);
ftmap(2628, :) = reshape(img_lab, rownum*colnum, 3)';

%soft segmented image
K = 8;
[ L, modelparams ] = buildSegmentation( img, 'gmm', K );
rgb = label2rgb(L);
imshow(rgb);
sfimg = modelparams.z;

%build a histogram for all leaf node
leafs = buildLeafArray( root );

kimgs = cell(1,K);
%for each edit, find out pixels with probability > 0.5
for k = 1:K
  pixpos = find( sfimg(k, :) > 0.5 );
  hist = zeros( size(leafs) );
  
  %for current segment, build voting histogram
  %for each pixel feature, vote in histogram
  for p=pixpos
    ft = ftmap( :, p );
    lfnode = ftclassify( ft, root );
    hist( lfnode.other.idx ) = hist( lfnode.other.idx ) + 1;
  end

  %find first three mappings
  hist = hist/sum(hist);
  [st, ind] = sort( hist, 'descend' );
  
  %for each pix in current seg, do color mapping

    l = img_2dim(pixpos, 1);
    a = img_2dim(pixpos, 2);
    b = img_2dim(pixpos, 3);
    Qi = [l^2;a^2;b^2;l*a;l*b;a*b;l;a;b; 1];

    kimgs{k}(pixpos, :) = st(1)*( leafs(ind(1)).other.A*Qi + leafs(ind(1)).other.b)+...
    st(2)*( leafs(ind(2)).other.A*Qi + leafs(ind(2)).other.b)+...
    st(3)*( leafs(ind(3)).other.A*Qi + leafs(ind(3)).other.b);
end

%merge final color enhanced image
img_final = zeros( rownum, colnum, 3 );
for k=1:K
  img_final = img_final + sfimg(:,:,k).*kimgs{k};
end

colorTransform = makecform('lab2srgb');
img_final = uint8(applycform( img_final, colorTransform));