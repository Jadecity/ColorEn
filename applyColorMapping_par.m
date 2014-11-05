function img_final = applyColorMapping_par( img, root )
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

%init final color enhanced image
K = 5;
img_final = zeros( 3, rownum*colnum );
kimgs = cell(1,K);

%get soft segment
segs = softseg(img_lab, K);

%for each pix in current seg, do color mapping
l = img_2dim(1,:);
a = img_2dim(2,:);
b = img_2dim(3,:);
Qi = cat(1,l.^2,a.^2,b.^2,l.*a,l.*b,a.*b,l,a,b);
for k=1:K
    kimgs{k} = img_2dim;
    %first vote for mappings
    selected = find(segs{k} >= 0.5)';
    rec = zeros( size(selected) );
    
    ftmap_s = ftmap(:,selected);
    parfor p=1:size(selected, 2)
        ft = ftmap_s( :, p );
        lfnode = ftclassify( ft, root );
        %hist( lfnode.other.idx ) = hist( lfnode.other.idx ) + 1;
        rec(p) = lfnode.other.idx;
    end
    rec_std = sort(rec);
    hist = histc(rec_std, 1:size(leafs, 2));
    hist = hist/sum(hist);
    [sorted, ind] = sort( hist, 'descend' );
    %then for each selected pixel, do mapping
    if ~isempty(selected)
        kimgs{k}(:, selected) = sorted(1)*( bsxfun(@plus,leafs(ind(1)).other.A*Qi(:,selected), leafs(ind(1)).other.b') )+...
        sorted(2)*( bsxfun(@plus,leafs(ind(2)).other.A*Qi(:, selected), leafs(ind(2)).other.b' ) )+...
        sorted(3)*( bsxfun(@plus,leafs(ind(3)).other.A*Qi(:, selected), leafs(ind(3)).other.b' ) );
    end

    %merge K images to one
    img_final(:,:) = img_final + repmat(segs{k}(:)', 3, 1).*kimgs{k}; 
end

img_final = reshape(img_final', rownum, colnum, 3);
img_final = lab2rgb(img_final);
