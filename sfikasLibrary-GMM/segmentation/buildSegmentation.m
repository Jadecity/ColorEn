function [segmentation, modelParams, segmentationCont, segmentation5, segmentationCont5] = ...
    buildSegmentation(imageName, method, maxSegments, fvType, options, groundTruth)
% [segmentation, modelParams, segmentationCont] = 
%   buildSegmentation(imageName, method, maxSegments, fvType, options, groundTruth)
% 
% Returns a K-level segmentation, using 'method' to compute the
% segmentation. The input must be a 2d image, color or grey.
% 'SegmentationCont' stands for the segmentation done used the contextual
% mixing proportions 'pi'.
%
% imageName             Must be a jpeg filename or a matlab matrix,
%                       representing input.
% method                Choose segmentation algorithm. Options are
%                       'kmeans'      K-means.
%                       {'gmm'}       Gaussian mixture.
%                       'smm'         Student-t mixture.                       
%                       'svgmmClp'    Bayesian spatially-variant gmm, with
%                                       continuous line process.
%                       'svgmm'       Spatially-variant gmm, the 'DCASVFMM'
%                                       in Nikou07.
%                       'ncuts'       Normalized cuts, "best"
%                                       configuration.
% maxSegments           Maximum number of segments, default is 3.
% fvType                {'colour'}  Colour, juste.
%                       'coltex'    Colour and "Contrast" Blobworld 
%                                       texture feature (colour image)
%                       'coltexAlt' Colour and "Polarity"-"Anisotropy"
%                                       texture features (colour image)
%                       'coltexFull'Colour and all 3 Blobworld features
%                                       (colour image)
%                       'grey'      Grey intensity (mono image)
% options               Other options. So far are supported:
%                       'n'         _Don't_ normalize variates to mean = 0,
%                                   st.dev = 1 (default is to normalize).
%                       'g'         Do gridScan optimization.
%                       'z'         Do gridScan optimization also
%                                   on Z matrix, coupled with Pi.
%                       'm'         Do multiresolution optimization. This
%                                   may be used in conjuction with 'g'.
%                       'e'         Initialize line process using Martin's
%                                   boundary detector. ABANDONED
%                       'ee'        Keep line process values fixed to Martin's
%                                   boundary detector output. ABANDONED
%                       'h'         Resize input to 50% each dimension.
%                       'q'         Resize input to 25% each dimension.
% groundTruth           A ground truth K-level image. This allows a RAND score
%                        to be printed (when available)
% Examples
%   To segment using a 3-kernel gmm:
%       s = buildSegmentation('lenna_std.jpg');
%   Using a student-t mixture, 8-kernel model:
%       s = buildSegmentation('lenna_std.jpg', 'smm', 8);
%   Using continuous line-process, 8-kernel model, and Blobworld features:
%       s = buildSegmentation('lenna_std.jpg', 'svgmmClp', 8, 'coltex');
%   To print the Rand score / MCR error in each iteration, based on ground truth 'gt':
%       s = buildSegmentation('lenna_std.jpg', 'svgmm', [], [], gT);
%   
% See also
%       computeBlobworldFeatureVectors
% G.Sfikas 12 Nov 2007
% Revision 1. 31 Jan 2008
%          2. 5 Mar 2008
%          3. 1 Apr 2008 some extra 'options' support added.
%          4. 24 Oct 2008 extra 'options' added: 'coltexAlt' and
%               'coltexFull'.

dontNormalizeVariates = 0;
specialOptions = '';
resizeHalf = 0;
resizeQuarter = 0;
%%%% Input arguments preprocessing %%%%
if exist('options', 'var') == 1
    for oCount = 1:numel(options)
        switch lower(options(oCount))
            case {'n'}
                dontNormalizeVariates = 1;
            case {'g'}
                specialOptions = strcat(specialOptions, 'g');
            case {'z'}
                specialOptions = strcat(specialOptions, 'z');
            case {'m'}
                specialOptions = strcat(specialOptions, 'm');
            case {'e'}
                specialOptions = strcat(specialOptions, 'e');
            case {'h'}
                resizeHalf = 1;
            case {'q'}
                resizeQuarter = 1;
            otherwise
                fprintf('buildSegmentation: Unknown option "%s" parsed\n', options(oCount));
        end
    end
end
if exist('groundTruth', 'var') == 0
    groundTruth = [];
end
if nargin < 4
    fvType = 'colour';
    if nargin < 3
        maxSegments = 3;
        if nargin < 2
            method = 'gmm';
        end
    end
end
if isempty(method)
    method = 'gmm';
end
if isempty(maxSegments)
    maxSegments = 3;
end
if isempty(fvType)
    disp('buildSegmentation: Resetting "colour" as feature vector by default.');
    fvType = 'colour';
end
if isa(imageName, 'char')
    originalImage = imread(imageName);
else
    originalImage = imageName;
end
if size(size(originalImage)) < 3
    %Force greylevel mode
    disp('buildSegmentation: Resetting "grey" (grey-level intensities) as feature vector by default.');    
    fvType = 'grey';
end
%%%% Preprocess data %%%%
if resizeHalf == 1
    disp('buildSegmentation: Resizing input to 50%..');
    originalImage = imresize(originalImage,.5);
elseif resizeQuarter == 1
    disp('buildSegmentation: Resizing input to 25%..');
    originalImage = imresize(originalImage,.25);    
end
tic
imageSize = [size(originalImage, 1) size(originalImage, 2)];
if strcmp(fvType, 'coltex')
    X = double(convertJxN(computeBlobworldFeatureVectors(originalImage)));
    X = X([1 2 3 6], :);
elseif strcmp(fvType, 'coltexAlt')
    X = double(convertJxN(computeBlobworldFeatureVectors(originalImage)));
    X = X([1 2 3 4 5], :);
elseif strcmp(fvType, 'coltexFull')
    X = double(convertJxN(computeBlobworldFeatureVectors(originalImage)));
    X = X([1 2 3 4 5 6], :);
elseif strcmp(fvType, 'colour') || strcmp(fvType, 'color')
    X = double(convertJxN(originalImage));
elseif strcmp(fvType, 'grey')
    X = double(originalImage(:)');
end

if dontNormalizeVariates ~= 1
    %%%% Normalize data variates to mean = 0, std = 1 %%%%
    means = mean(X, 2)'; % Compute manually now.
    vars = std(X'); % Compute manually now.
    X = (X - means'*ones(1,size(X,2))) ./ (vars'*ones(1,size(X, 2)));
    if max(abs(std(X') - ones(size(std(X'))))) > 0.05
        disp('WARNING: Not all variates are normalized properly!!');
    end
end
%%%% Segment %%%%
m = []; covar = []; w = []; z = []; u = []; 
v = []; beta = []; likelihood = []; omega = [];
switch lower(method)
    case {'kmeans'}
        fprintf('buildSegmentation: _Using %d kernel K-means_\n', maxSegments);
        [m w segmentation] = deterministicKmeans(X, maxSegments);
        segmentation = reshape(segmentation, imageSize);
    case {'gmm'}
        fprintf('buildSegmentation: _Using %d kernel Gaussian MM_\n', maxSegments)
        [m, covar, w, z] = gaussianMixEmFit(X, maxSegments);
        [junk segmentation] = max(z); segmentation = uint8(reshape(segmentation, imageSize));
    case {'smm'}
        fprintf('buildSegmentation: _Using %d kernel Student-t MM_\n', maxSegments)
        [m, covar, v, w, z] = studentMixEmFit(X, maxSegments);
        [junk segmentation] = max(z); segmentation = uint8(reshape(segmentation, imageSize));        
    case {'svgmmclp'}
        fprintf('buildSegmentation: _Using %d kernel Spatially variant Gmm with Continuous lp (Student t cliques)_\n', maxSegments)
        [m, covar, w, z, u, v, beta, likelihood, w5, z5] = gaussianMixBayesianContinuousLp(X, maxSegments, imageSize, ...
            groundTruth, specialOptions); % edgemapMartin(originalImage));
        [junk segmentation] = max(z); segmentation = uint8(reshape(segmentation, imageSize));
        [junk segmentationCont] = max(w); segmentationCont = uint8(reshape(segmentationCont, imageSize));
        [junk segmentation5] = max(z5); segmentation5 = uint8(reshape(segmentation5, imageSize));
        [junk segmentationCont5] = max(w5); segmentationCont5 = uint8(reshape(segmentationCont5, imageSize));        
    case {'svgmmlp'}
        fprintf('buildSegmentation: _Using %d kernel Spatially variant Gmm with line process_\n', maxSegments)
        [m, covar, w, z, u, v, beta, likelihood, w5, z5] = gaussianMixBayesianLp(X, maxSegments, imageSize, ...
            groundTruth, specialOptions); % edgemapMartin(originalImage));
        [junk segmentation] = max(z); segmentation = uint8(reshape(segmentation, imageSize));        
        [junk segmentationCont] = max(w); segmentationCont = uint8(reshape(segmentationCont, imageSize));
        [junk segmentation5] = max(z5); segmentation5 = uint8(reshape(segmentation5, imageSize));
        [junk segmentationCont5] = max(w5); segmentationCont5 = uint8(reshape(segmentationCont5, imageSize));                
    case {'svgmm'}
        fprintf('buildSegmentation: _Using %d kernel Spatially variant Gmm (Directed, class adaptive)_\n', maxSegments);
        [m, covar, w, z, u] = gaussianMixDCASV(X, maxSegments, imageSize, groundTruth);
        [junk segmentation] = max(z); segmentation = uint8(reshape(segmentation, imageSize));   
        [junk segmentationCont] = max(w); segmentationCont = uint8(reshape(segmentationCont, imageSize));
    case {'vbgmm'}
        fprintf('buildSegmentation: _Using %d kernel Variational Bayes Gmm_\n', maxSegments);
        [m, covar, w, z] = gaussianMixBayesian(X, maxSegments);
        [junk segmentation] = max(z'); segmentation = uint8(reshape(segmentation, imageSize));   
    case {'ncuts'}
        fprintf('buildSegmentation: _Using %d kernel Ncuts method_\n', maxSegments);
        segmentation = ncut_multiscale(reshape(X', [imageSize(1) imageSize(2) size(X,1)]), maxSegments);
        segmentation = reshape(segmentation, imageSize);
    case {'nombre'}
        fprintf('buildSegmentation: _Using %d kernel Nombre model\n', maxSegments);
        [m, covar, w, z, u, v, beta, omega, likelihood, w5, z5] = gaussianMixNombre(X, maxSegments, imageSize, groundTruth);
        [junk segmentation] = max(z); segmentation = uint8(reshape(segmentation, imageSize));
        [junk segmentationCont] = max(w); segmentationCont = uint8(reshape(segmentationCont, imageSize));
        [junk segmentation5] = max(z5); segmentation5 = uint8(reshape(segmentation5, imageSize));
        [junk segmentationCont5] = max(w5); segmentationCont5 = uint8(reshape(segmentationCont5, imageSize));                
    case {'nombreNoNombre'}
        fprintf('buildSegmentation: _Using %d kernel Nombre model w/out number of classes selection\n', K);
        [m, covar, w, z] = gaussianMixNombre2(X, maxSegments, imageSize, groundTruth);
        [junk segmentation] = max(z); segmentation = uint8(reshape(segmentation, imageSize));
        [junk segmentationCont] = max(w); segmentationCont = uint8(reshape(segmentationCont, imageSize));                                
    case {'nombreNoMRF'}
        fprintf('buildSegmentation: _Using %d kernel Nombre model w/out MRF\n', K);
        [m, covar, w, z] = gaussianMixNombre3(X, maxSegments, imageSize, groundTruth);
        [junk segmentation] = max(z); segmentation = uint8(reshape(segmentation, imageSize));
    case {'newtoy'}
        fprintf('buildSegmentation: Warning: Using an experimental method\n');
        [m, covar, w, z, u, v, beta, omega, likelihood, w5, z5] = ...
            gaussianMixNombre(X, maxSegments, imageSize, groundTruth, buildAdjacencyMatrix(imageSize));
        [junk segmentation] = max(z); segmentation = uint8(reshape(segmentation, imageSize));
        [junk segmentationCont] = max(w); segmentationCont = uint8(reshape(segmentationCont, imageSize));        
    case {'newtoy2'}
        fprintf('buildSegmentation: _Using %d kernel Nombre model\n', maxSegments);
        [m, covar, w, z, u, v, beta, omega, likelihood] = EXPgaussianMixNombre(X, maxSegments, imageSize, groundTruth);
        [junk segmentation] = max(z); segmentation = uint8(reshape(segmentation, imageSize));        
    otherwise
        error('buildSegmentation: Error! Unknown method');
end

modelParams = struct('m', m, 'covar', covar, 'w', w, 'z', z, 'u', u, 'v', v, ...
    'beta', beta, 'omega', omega, 'likelihood', likelihood);
toc
return;