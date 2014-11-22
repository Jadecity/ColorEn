function [ patchidx ] = randpatch( imgsz, roi, n, patchsz )
%RANDPATCH select n patches from roi(region of interest)
%   input : 
%       imgsz: such as [2 3], 2 rows and 3 cols
%       roi: region of interest, [2 3;4 5],start from (2,3),
%       to(4,5)
%       n: the number of patches
%       patchsz: size of patch, [5 5] for example,
%   output:
%       patchidx: a 1-by-n cells, each cell contains index of patch
%       pixels
    
xs = datasample(roi(1,1):roi(2,1)-patchsz(1) + 1, n, 'Replace', true);
ys = datasample(roi(1,2):roi(2,2)-patchsz(2) + 1, n, 'Replace', true);
xe = xs + patchsz(1) - 1;
ye = ys + patchsz(2) - 1;
patchidx = cell(1, n);
for m=1:n
    [X, Y] = meshgrid(xs(m):xe(m), ys(m):ye(m));
    X = X(:);
    Y = Y(:);
    idx = sub2ind(imgsz, X, Y);
    patchidx{m} = idx;
end

end

