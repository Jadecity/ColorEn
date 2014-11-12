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

usesoft = true;
%convert img to Lab color space
[ rownum, colnum, ~ ] = size( img );
img_lab = rgb2lab(img);

%do normalization
img_lab = img_lab/100;
lumavg = mean2(img_lab(:,:,1));
img_lab(:,:,1) = img_lab(:,:,1)*0.65/lumavg;
img_2dim = reshape(img_lab, rownum*colnum, 3)';

%generate gradient map
%init gradient kernel
sobelHE = [-0.25 -0.5 -0.25;
           0 0 0;
           0.25 0.5 0.25];
sobelVE = [0.25 0 -0.25;
           0.5 0 -0.5;
           0.25 0 -0.25];
%create gradient map
%pad image with symmetric method along edges
imgpadded = zeros(rownum+2, colnum+2, 3);
imgpadded(2:rownum+1, 2:colnum+1, :) = img_lab;
imgpadded([1,end],2:colnum+1, :) = img_lab([2,end-1], :, :);
imgpadded(2:rownum+1,[1,end], :) = img_lab(:, [2,end-1], :);
imgpadded(1,1, :) = img_lab(2,2, :);
imgpadded(end,end, :) = img_lab(end-1, end-1, :);
imgpadded(1,end,:) = img_lab(2, end-1, :);
imgpadded(end,1,:) = img_lab(end-1, 2, :);
gx.l = conv2( imgpadded(:,:,1), sobelVE, 'same');
gy.l = conv2( imgpadded(:,:,1), sobelHE, 'same');
gx.a = conv2( imgpadded(:,:,2), sobelVE, 'same');
gy.a = conv2( imgpadded(:,:,2), sobelHE, 'same');
gx.b = conv2( imgpadded(:,:,3), sobelVE, 'same');
gy.b = conv2( imgpadded(:,:,3), sobelHE, 'same');
gx.l = gx.l(2:rownum+1, 2:colnum+1);
gy.l = gy.l(2:rownum+1, 2:colnum+1);
gx.a = gx.a(2:rownum+1, 2:colnum+1);
gy.a = gy.a(2:rownum+1, 2:colnum+1);
gx.b = gx.b(2:rownum+1, 2:colnum+1);
gy.b = gy.b(2:rownum+1, 2:colnum+1);

%extract feature map
ftnum = 15;
ftmap = zeros(ftnum+5, rownum*colnum);
ftmap_first = pfeature(img_lab, gx, gy);

ftmap(1:ftnum, :) = ftmap_first;
ftmap(ftnum+1, :) = gx.l(:);
ftmap(ftnum+2, :) = gy.l(:);
ftmap(ftnum+3:ftnum+5, :) = reshape(img_lab, rownum*colnum, 3)';

%build a histogram for all leaf node
leafs = buildLeafArray( root,[],[] );
leafsz = numel(leafs);

%for each pix in current seg, do color mapping
l = img_2dim(1,:);
a = img_2dim(2,:);
b = img_2dim(3,:);
Qi = cat(1,l.^2,a.^2,b.^2,l.*a,l.*b,a.*b,l,a,b);
img_final = zeros( 3, rownum*colnum );
if usesoft
    %init final color enhanced image
    K = 5;
    kimgs = cell(1,K);

    %get soft segment
    segs = softseg(img_lab*100, K);
    
    for k=1:K
        kimgs{k} = img_2dim;
        %clear root data items
        for p=1:leafsz
            leafs(p).data = [];
        end    

        %first vote for mappings
        selected = find(segs{k} >= 0.5)';
        if ~isempty(selected)
            hist = zeros( size(leafs) );

            root.data = selected;
            ftclassify2( ftmap, root );
            for p=1:leafsz
                hist( p ) = numel( leafs(p).data );
            end

            %hist = hist/sum(hist);
            [sorted, ind] = sort( hist, 'descend' );
            save(strcat(num2str(k),'ind.mat'), 'ind');
            sorted(1:3) = sorted(1:3)/sum(sorted(1:3));
            save(strcat(num2str(k),'sorted.mat'), 'sorted');
            %then for selected pixels, do mapping
% $$$             kimgs{k}(:,selected) = sorted(1)*( bsxfun(@plus,leafs(ind(1)).other.A*Qi(:,selected), leafs(ind(1)).other.b') )+...
% $$$             sorted(2)*( bsxfun(@plus,leafs(ind(2)).other.A*Qi(:,selected), leafs(ind(2)).other.b' ) )+...
% $$$                 sorted(3)*( bsxfun(@plus,leafs(ind(3)).other.A*Qi(:,selected), ...
% $$$                                    leafs(ind(3)).other.b' ) );
%           it proves that this method works fine
            kimgs{k}(:,:) = sorted(1)*( bsxfun(@plus,leafs(ind(1)).other.A*Qi(:,:), leafs(ind(1)).other.b') )+...
            sorted(2)*( bsxfun(@plus,leafs(ind(2)).other.A*Qi(:,:), leafs(ind(2)).other.b' ) )+...
                sorted(3)*( bsxfun(@plus,leafs(ind(3)).other.A*Qi(:,:), ...
                                   leafs(ind(3)).other.b' ) );
        end

        %merge K images to one
        img_final = img_final + repmat(segs{k}(:)', 3, 1).*kimgs{k}; 
    end
end
if ~usesoft
     %clear root data items
     for p=1:leafsz
         leafs(p).data = [];
     end
     root.data = 1:rownum*colnum;
     ftclassify2( ftmap, root );
     for p=1:leafsz
         p
         leafs(p).other.A
         leafs(p).other.b
         leafs(p).data
         img_final(:,leafs(p).data) = bsxfun(@plus,leafs(p).other.A*Qi(:,leafs(p).data), leafs(p).other.b');
     end
end

img_final = reshape(img_final', rownum, colnum, 3);
%do normalization back
img_final(:,:,1) = img_final(:,:,1)*lumavg/0.65;
img_final = img_final*100;
img_final = lab2rgb(img_final);
