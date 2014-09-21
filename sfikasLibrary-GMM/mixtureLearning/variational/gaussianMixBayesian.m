function [m, covar, w, eZ, hyperparameters, film] = gaussianMixBayesian(X, K)
% Variational evaluation of latent variables' posterior distributions, in
% a fully-Bayesian Gaussian mixture model. This variational algorithm
% makes only the assumption of a mean-field approximation of the posterior:
% q(weights, means, precisions, zeta) = 
%       q(weights) x q(means, precisions) x q(zeta)
% and a choice of conjugate forms for the priors.
%
% Important notes:
%
% Examples:
%
% Arguments: (All output is with regard to the posterior)
% X     Observations. Each column is one observation.
% K     Number of kernels.
% hyperparemeters   Struct containing:
%   m   'Mean' hyperparameters on Normal-Wishart posterior.
%   b   'Beta' hyperparameters on Normal-Wishart posterior.
%   W   'W' hyperparameters on Normal-Wishart posterior.
%   v   'v' hyperparameters on Normal-Wishart posterior.
%   a   'Alpha' hyperparameters on Dirichlet posterior.
% film   Visualization movie. Works only for d = 2 and visual = 'on'.
% See also:
%       gaussianMixEmFit, studentMixEmFit
%
% Giorgos Sfikas, 29 Mar 2007
% Update: 22 Decembre 2008 : Changed output arguments a bit

% disp('WARNING: a,b,m Priors set to medical mode (ICCV07) !');
visual = 'on';
[d N] = size(X);
if d ~= 2
    visual = 'off';
end
% Prior distribution "initialization"
allDataMean = mean(X, 2);
allDataCov = cov(X');
% Random mean priors
m0 = sqrtm(allDataCov) * randn(d, K) + allDataMean * ones(1, K);
% m0 = [-1.35 -0.0261 0.7908];
% FIN - Random initialization
% Deterministic initialization for prior means -- K-means
% m0 = deterministicKmeans(X, K);
% FIN - Deterministic initialization
W0 = zeros(d, d, K);
for j = 1:K
    W0(:,:,j) = K^2 * inv(allDataCov);
end
m = m0;
b0 = 1 * ones(1, K); %This used to be broader (close to 0)
b = b0;
W = W0;
v0 = d * ones(1, K);
v = v0;
a0 = 1e-2 * ones(1, K);
% a0 = [361736 963419 647135];
a = a0;


if strcmp(visual, 'off')
    film = [];
else
    figure;
    hold off;
    axis normal;
    axis manual;
    drawDataAndKernels(X, m, v, W, a);
    film(1) = getframe();
end
disp('VB iteration  LowerBound        Average LB      BIncrease   ');
disp('------------------------------------------------------------');
% Cycle these steps until convergence of variational lower bound
for iteration = 1:80;
    % STEP 1: Compute expectations
    eMahalanobis = zeros(N, K);
    elogLambda = zeros(1, K);
    elogP = zeros(1, K);
    logR = zeros(N, K);
    eZ = zeros(N, K);
    statN = zeros(1, K);
    statXCov = zeros(d, d, K);
    for j = 1:K
        eMahalanobis(:, j) = d * inv(b(j) + eps) + ...
            v(j) * mahalanobis(X, m(:,j), inv(W(:,:,j)))';
        %TODO: The calculation above contains an inv(inv(.))
        elogLambda(j) = d * log(2) + logdet(W(:,:,j)) + ...
            sum(digamma(0.5*(v(j) + 1 - (1:d))));
        elogP(j) = digamma(a(j)) - digamma(sum(a));
        logR(:,j) = elogP(j) + 0.5*elogLambda(j) ...
            - 0.5*eMahalanobis(:, j);
    end
    % Instead of the following two lines:
    %     R = exp(logR);
    %     eZ2 = R ./ ((sum(R, 2))*ones(1, K));
    % I use the code below (until 'FIN')
    pseudoR = zeros(size(logR));
    for j = 1:K
        for k = 1:K
            pseudoR(:, k) = logR(:, k) - logR(:, j);
        end
        eZ(:, j) = 1 ./ sum(exp(pseudoR), 2);
    end     
    % FIN
    %"Convenient" statistics
    statN = sum(eZ, 1);
    statXMean = (X * eZ) ./ (ones(d, 1) * (statN + eps));
    for j = 1:K
        statXCov(:,:,j) = inv(statN(j) + eps) * ( ...
                (X - statXMean(:, j)*ones(1,N))* ...
                sparse(1:N, 1:N, eZ(:, j)', N, N) * ...
                (X - statXMean(:, j)*ones(1,N))' );
    end
    % STEP 2: Compute posterior hyperparameters
    for j = 1:K
        a(j) = a0(j) + statN(j);
        b(j) = b0(j) + statN(j);
        m(:, j) = inv(b(j)) * (b0(j) * m0(:, j) + statN(j)*statXMean(:, j));
        newW = inv( inv(W0(:,:,j)) + statN(j)*statXCov(:,:,j) + ...
            ( (b0(j)*statN(j)) / (b0(j) + statN(j) + eps) ) * ...
            (statXMean(:,j) - m0(:,j)) * (statXMean(:,j) - m0(:,j))' );
        if rcond(newW) > 1e3 * eps
            W(:, :, j) = newW;
        end
        v(j) = v0(j) + statN(j);
    end
    % STEP 3: Compute variational lower bound and check for convergence
    % logp(X|Z, mu, Lambda)
    lowerBound = 0.5 * statN * ( elogLambda - (d./b) - d*log(2*pi) )';
    for j = 1:K
        lowerBound = lowerBound - 0.5 * statN(j) * v(j) * ...
            ( trace(statXCov(:,:,j) * W(:,:,j)) + ...
                (statXMean(:, j) - m(:, j))' * W(:,:,j) * (statXMean(:, j) - m(:, j)) );
    end
    % logp(Z|pi)
    lowerBound = lowerBound + sum( eZ * elogP' );
    % logp(pi)
    lowerBound = lowerBound + gammaln(sum(a0)) - sum(gammaln(a0)) + ...
        (a0 - 1) * elogP';
    % logp(mu, Lambda)
    lowerBound = lowerBound + 0.5 * sum( d * log(inv(2*pi)*b0) + elogLambda ...
        -d * (b0 ./ b) ) + 0.5 * (v0 - d - 1) * elogLambda';
    for j = 1:K
        lowerBound = lowerBound - 0.5 *  v(j) * ...
            (b0(j) * (m(:, j) - m0(:, j))' * W(:,:,j) * (m(:, j) - m0(:, j)) + ...
            trace(inv(W0(:,:,j)) * W(:,:,j)) );
        lowerBound = lowerBound + logWishartConstant(W0(:,:,j), v0(j));
    end
    % logq(Z)
    posteriorEntropy = sum(sum(eZ .* log(eZ + eps)));
    % logq(pi)
    posteriorEntropy = posteriorEntropy + gammaln(sum(a)) - sum(gammaln(a)) + ...
        (a - 1) * elogP';
    % logq(mu, Lambda)
    posteriorEntropy = posteriorEntropy + sum( 0.5*elogLambda + 0.5*d*log(b*inv(2*pi)) - 0.5*d);
    for j = 1:K
        posteriorEntropy = posteriorEntropy + logWishartConstant(W(:,:,j), v(j));
        posteriorEntropy = posteriorEntropy + 0.5*(v(j) - d - 1)*elogLambda(j) - 0.5*v(j)*d;
    end
    lowerBound = lowerBound - posteriorEntropy;
    % Type some statistics.
    if iteration > 1
        LBchangeRatio = (lowerBound - prev) / abs(prev);
        prev = lowerBound;
    else
        LBchangeRatio = 0;
        prev = lowerBound;
    end
    disp(sprintf('%3d           %3.2f         %2.5f      %2.5f%%', ...
            iteration, lowerBound, lowerBound/N, LBchangeRatio*100));
    if iteration > 1 && LBchangeRatio < 1e-4
        break;
    end
    %
    if strcmp(visual, 'on')
        drawDataAndKernels(X, m, v, W, a);
        film(iteration+1) = getframe();
    end
end
% End
hyperparameters = struct('m', m, 'b', b, 'W', W, 'v', v, 'a', a);
covar = zeros(size(W));
for j = 1:K
    covar(:,:,j) = inv(v(j)*W(:,:,j));
end
w = a / sum(a);
return;

function drawDataAndKernels(X, m, v, W, a)
[d K] = size(m);
scatter(X(1, :), X(2, :));
covar = zeros(d, d, K);
for j = 1:K
    covar(:,:,j) = inv(v(j)*W(:,:,j));
end
w = a / sum(a);
for j = 1:K
    if w(j) > 1e-2
        draw_ellipse(m(:,j), 6*w(j)*covar(:,:,j), 'r');
    end
end
return;

function B = logWishartConstant(W, v)
d = size(W, 1);
B = - (0.5*v*logdet(W) + ...
            0.5*v*d*log(2) + 0.25*d*(d-1)*log(pi) + ...
            sum(gammaln(0.5*(v + 1 - (1:d)))) );
return;