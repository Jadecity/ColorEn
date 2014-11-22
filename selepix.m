function [pixselected] = selepix(img, seg_num, maxpixels)
%function [pixselected] = selepix(img, seg_num, maxpixels)
%    img: rgb image to select
%    seg_num: total segmentation number
%    maxpixels: # of pixels that can be selected from this image

addpath(genpath('superpixels64'));
if ~exist('cncut')
    addpath('yu_imncut');
end

imggray = im2double( rgb2gray(img) );
img = im2double(img);
N = size(img,1);
M = size(img,2);

% Number of superpixels coarse/fine.
N_sp=200;
%N_sp2=1000;
N_sp2=seg_num;
% Number of eigenvectors.
N_ev=40;

if ~exist('spsegs.mat', 'file')
    % ncut parameters for superpixel computation
    diag_length = sqrt(N*N + M*M);
    par = imncut_sp;
    par.int=0;
    par.pb_ic=1;
    par.sig_pb_ic=0.05;
    par.sig_p=ceil(diag_length/50);
    par.verbose=0;
    par.nb_r=ceil(diag_length/60);
    par.rep = -0.005;  % stability?  or proximity?
    par.sample_rate=0.2;
    par.nv = N_ev;
    par.sp = N_sp;

    % Intervening contour using mfm-pb
    fprintf('running PB\n');
    [emag,ephase] = pbWrapper(img,par.pb_timing);
    emag = pbThicken(emag);
    par.pb_emag = emag;
    par.pb_ephase = ephase;
    clear emag ephase;

    st=clock;
    fprintf('Ncutting...');
    [Sp,Seg] = imncut_sp(img,par);

    st=clock;
    fprintf('Fine scale superpixel computation...');
    Sp2 = clusterLocations(Sp,ceil(N*M/N_sp2));
    fprintf(' took %.2f minutes\n',etime(clock,st)/60);
    spsegs = {Seg, Sp, Sp2};
    %    save spsegs.mat spsegs;
    clear spsegs;
else
    %load spsegs;
    Seg = spsegs{1};
    Sp = spsegs{2};
    Sp2 = spsegs{3};
end

%for visualization
I_sp = segImage(img,Sp);
I_sp2 = segImage(img,Sp2);
I_seg = segImage(img,Seg);

%random select patches from segmentations
patchnum = ceil( maxpixels/ceil(N*M/N_sp2) );
pixselected = cell(1, patchnum+1);%the last one is edge pixels
Labels = unique(Sp2);
seleLabels = datasample(Labels, patchnum, 'Replace', false);
I_sp2r = reshape(I_sp2, N*M, 3);
for p=1:patchnum
     pixselected{p} = find(Sp2 == seleLabels(p));
     I_sp2r(pixselected{p},:) = repmat([1 0 0], numel(pixselected{p}), 1);
end

%%extract fuzzy edges
%first extract gradient
Gx = [-1 1];
Gy = Gx';
Ix = conv2(imggray,Gx,'same');
Iy = conv2(imggray,Gy,'same');
%then specify fuzzy inference system
edgeFIS = newfis('edgeDetection');
edgeFIS = addvar(edgeFIS,'input','Ix',[-1 1]);
edgeFIS = addvar(edgeFIS,'input','Iy',[-1 1]);
%Specify a zero-mean Gaussian membership function for each input
sx = 0.1; sy = 0.1;
edgeFIS = addmf(edgeFIS,'input',1,'zero','gaussmf',[sx 0]);
edgeFIS = addmf(edgeFIS,'input',2,'zero','gaussmf',[sy 0]);
%Specify the intensity of the edge-detected image as an output of edgeFIS
edgeFIS = addvar(edgeFIS,'output','Iout',[0 1]);
%Specify the triangular membership functions, white and black, for Iout.
wa = 0.1; wb = 1; wc = 1;
ba = 0; bb = 0; bc = .7;
edgeFIS = addmf(edgeFIS,'output',1,'white','trimf',[wa wb wc]);
edgeFIS = addmf(edgeFIS,'output',1,'black','trimf',[ba bb bc]);
%Add rules to make a pixel white if it belongs to a uniform
%region. Otherwise, make the pixel black
r1 = 'If Ix is zero and Iy is zero then Iout is white';
r2 = 'If Ix is not zero or Iy is not zero then Iout is black';
r = char(r1,r2);
edgeFIS = parsrule(edgeFIS,r);
%Evaluate the output of the edge detector for each row of pixels in
%I using corresponding rows of Ix and Iy as inputs
Ieval = zeros(size(imggray));% Preallocate the output matrix
for ii = 1:size(imggray,1)
    Ieval(ii,:) = evalfis([(Ix(ii,:));(Iy(ii,:));]',edgeFIS);
end
%save edges.mat Ieval;
minIeval = min(Ieval(:));
maxIeval = max(Ieval(:));
pixselected{end} = find( Ieval<0.5*(minIeval+maxIeval) );
I_sp2r(pixselected{end},:) = repmat([0 1 0], numel(pixselected{end}), ...
                                  1);
I_sp2r = reshape(I_sp2r, [N M 3]);
% $$$ figure;
% $$$ subplot(1,4,1);
% $$$ imshow(img);
% $$$ subplot(1,4,2);
% $$$ imshow(I_sp);
% $$$ subplot(1,4,3);
% $$$ imshow(I_sp2);
% $$$ subplot(1,4,4);
% $$$ imshow(I_sp2r);
% $$$ figure; 
% $$$ image(Ieval,'CDataMapping','scaled'); 
% $$$ colormap('gray');
% $$$ title('Edge Detection Using Fuzzy Logic');
end