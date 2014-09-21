function [m, covar, v, w, hyperparameters, film] = studentMixBayesian(X, K)
% Variational evaluation of latent variables' posterior distributions, in
% a fully*-Bayesian Student-t mixture model. This variational algorithm
% makes only the assumption of a mean-field approximation of the posterior:
% q(weights, means, precisions, zeta, upsilon) = 
%       q(weights, means, precisions) x q(zeta) x q(upsilon)
% and a choice of conjugate forms for the priors.
%
% Important notes:
%   *The only parameter we keep non-stochastic is v, ie degrees of
%   freedom for each kernel.
%   In 'gaussianMixBayesian', v is the scalar Wishart hyperparameter. Here
%   this hyperparamater is called 'h', whereas v now stands for the degrees
%   of freedom parameters.
%
% Examples:
%
% Arguments: (All output is with regard to the posterior)
% X     Observations. Each column is one observation.
% K     Number of kernels.
% hyperparameters   Struct containing:
%   m   'Mean' hyperparameters on Normal-Wishart posterior.
%   b   'Beta' hyperparameters on Normal-Wishart posterior.
%   W   'W' hyperparameters on Normal-Wishart posterior.
%   h   'h' hyperparameters on Normal-Wishart posterior.
%   a   'Alpha' hyperparameters on Dirichlet posterior.
% film   Visualization movie. Works only for d = 2 and visual = 'on'.
% See also:
%       gaussianMixBayesian, gaussianMixEmFit, studentMixEmFit
%
% Giorgos Sfikas, 24 Apr 2007

% disp('WARNING: a,b,m Priors set to medical mode (ICCV07) !');

visual = 'on';
[d N] = size(X);
if d ~= 2
    visual = 'off';
end
%%% Prior distribution "initialization"
allDataMean = mean(X, 2);
allDataCov = cov(X');
% Random mean priors
m0 = sqrtm(allDataCov) * randn(d, K) + allDataMean * ones(1, K);
% m0 = [-1.35 -0.0261 0.7908];
% m0 = allDataMean * ones(1, K);
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
h0 = d * ones(1, K);
h = h0;
a0 = 1e-2 * ones(1, K);
% a0 = [361736 963419 647135];
a = a0;
%%% Deterministic parameter initialization
v = 9 * ones(1, K);
ga = 0.5 * ones(N, 1) * v;
gb = 0.5 * ones(N, 1) * v;
%

if strcmp(visual, 'off')
    film = [];
else
    figure;
    hold off;
    axis normal;
    axis manual;
    drawDataAndKernels(X, m, h, W, a, v);
    film(1) = getframe();
end
disp('VB iteration  LowerBound        Average LB      BIncrease   ');
disp('------------------------------------------------------------');
% Cycle these steps until convergence of variational lower bound
lowerBound = -inf; %DEBUG <-
eZ = inv(N) * ones(N, K);
eMahalanobis = zeros(N, K);
elogLambda = zeros(1, K);
elogP = zeros(1, K);
logR = zeros(N, K);
statN = zeros(1, K);
statNz = zeros(1, K);
statXCov = zeros(d, d, K);
statXMean = zeros(d, K);
% Compute initial expecations 
eU = ga ./ (gb + eps);
elogU = digamma(ga) - log(gb);
for j = 1:K
    eMahalanobis(:, j) = d * inv(b(j) + eps) + ...
        h(j) * mahalanobis(X, m(:,j), inv(W(:,:,j)))';
    %TODO: The calculation above contains an inv(inv(.))
    elogLambda(j) = d * log(2) + logdet(W(:,:,j)) + ...
        sum(digamma(0.5*(h(j) + 1 - (1:d))));
    elogP(j) = digamma(a(j)) - digamma(sum(a));
    logR(:,j) = elogP(j) + 0.5*elogLambda(j) ...
        - 0.5 * eU(:, j) .* eMahalanobis(:, j);
end
logR = logR + 0.5 * d * (elogU);
pseudoR = zeros(size(logR));
for j = 1:K
    for k = 1:K
        pseudoR(:, k) = logR(:, k) - logR(:, j);
    end
    eZ(:, j) = 1 ./ sum(exp(pseudoR), 2);
end
for iteration = 1:200;
    % STEP: Compute posterior hyperparameters
    % Compute q*(Z)
    for j = 1:K
        logR(:,j) = elogP(j) + 0.5*elogLambda(j) ...
            - 0.5 * eU(:, j) .* eMahalanobis(:, j);
    end
    logR = logR + 0.5 * d * (elogU);
    pseudoR = zeros(size(logR));
    for j = 1:K
        for k = 1:K
            pseudoR(:, k) = logR(:, k) - logR(:, j);
        end
        eZ(:, j) = 1 ./ sum(exp(pseudoR), 2);
    end
%     %DEBUG -- START
%     lowerBound1 = computeLB(eZ, eU, elogU, elogLambda, eMahalanobis, ...
%     elogP, a0, b0, h0, m0, W0, a, b, h, m, W, v, ga, gb, N, K, d, lowerBound);
%     if lowerBound1 < lowerBound
%         disp('Z!!');
%     end
%     lowerBound = lowerBound1;
%     %DEBUG -- FIN
    % Compute q*(U) & new expectations
    ga = 0.5 * (d * eZ + ones(N, 1) * v);
    gb = 0.5 * (eMahalanobis .* eZ + ones(N, 1) * v);
     %ga = 0.5 * (eZ .* ((d-2) + ones(N, 1) * v) + 2);
     %gb = 0.5 * (eZ .* (eMahalanobis + ones(N, 1) * v)) + eps;
    eU = ga ./ (gb + eps);
    elogU = digamma(ga) - log(gb);
    % Compute 'convenient' statistics depending only on X, Z, U
    % Here, z * u is used as a weight.
    statNz = sum(eZ, 1);
    statN = sum(eZ .* eU, 1);
    statXMean = (X * (eZ .* eU) ) ./ (ones(d, 1) * (statN + eps));
    for j = 1:K
        statXCov(:,:,j) = inv(statN(j) + eps) * ( ...
                (X - statXMean(:, j)*ones(1,N))* ...
                sparse(1:N, 1:N, eZ(:, j)' .* eU(:, j)', N, N) * ...
                (X - statXMean(:, j)*ones(1,N))' );
    end
%     %DEBUG -- START
%     lowerBound1 = computeLB(eZ, eU, elogU, elogLambda, eMahalanobis, ...
%     elogP, a0, b0, h0, m0, W0, a, b, h, m, W, v, ga, gb, N, K, d, lowerBound);
%     if lowerBound1 < lowerBound
%         disp('U!!');
%     end
%     lowerBound = lowerBound1;
%     %DEBUG -- FIN
    % Compute q*(pi) & new expectations
    for j = 1:K
        a(j) = a0(j) + statNz(j);
        elogP(j) = digamma(a(j)) - digamma(sum(a));
    end
%     %DEBUG -- START
%     lowerBound1 = computeLB(eZ, eU, elogU, elogLambda, eMahalanobis, ...
%     elogP, a0, b0, h0, m0, W0, a, b, h, m, W, v, ga, gb, N, K, d, lowerBound);
%     if lowerBound1 < lowerBound
%         disp(sprintf('PI!! -- decrease by %f', lowerBound - lowerBound1));
%     end
%     lowerBound = lowerBound1;
%     %DEBUG -- FIN
    % Compute q*(mu, Lambda) & new expectations
    for j = 1:K
        b(j) = b0(j) + statN(j);
        h(j) = h0(j) + statNz(j);
        m(:, j) = inv(b(j)) * (b0(j) * m0(:, j) + statN(j)*statXMean(:, j));
        newW = inv( inv(W0(:,:,j)) + statN(j)*statXCov(:,:,j) + ...
            ( (b0(j)*statN(j)) / (b0(j) + statN(j)) ) * ...
            (statXMean(:,j) - m0(:,j)) * (statXMean(:,j) - m0(:,j))' );
        if rcond(newW) > 1e3 * eps
            W(:, :, j) = newW;
        end
    end
    for j = 1:K
        eMahalanobis(:, j) = d * inv(b(j) + eps) + ...
            h(j) * mahalanobis(X, m(:,j), inv(W(:,:,j)))';
        %TODO: The calculation above contains an inv(inv(.))
        elogLambda(j) = d * log(2) + logdet(W(:,:,j)) + ...
            sum(digamma(0.5*(h(j) + 1 - (1:d))));
    end
%     %DEBUG -- START
%     lowerBound1 = computeLB(eZ, eU, elogU, elogLambda, eMahalanobis, ...
%     elogP, a0, b0, h0, m0, W0, a, b, h, m, W, v, ga, gb, N, K, d, lowerBound);
%     if lowerBound1 < lowerBound
%         disp('MU-LAMBDA!!');
%     end
%     lowerBound = lowerBound1;
%     %DEBUG -- FIN
    % STEP: Compute non-stochastic parameters &
    % recompute q*(U), which depends on v. (?) NOT
    for j = 1:K
%         if statNz(j) == 0
%             vconstant = 1 + inv(N) * ( ...
%             sum(elogU(:, j) - eU(:, j)) );
%             v(j) = bisection(vconstant);
%             continue;
%         end
%         vconstant = 1 + inv(statNz(j)) * ( ...
%             eZ(:, j)' * (elogU(:, j) - eU(:, j)) );
        vconstant = 1 + inv(N) * ( ...
            sum(elogU(:, j) - eU(:, j)) );
        v(j) = bisection(vconstant);
    end
%     %DEBUG -- START
%     lowerBound1 = computeLB(eZ, eU, elogU, elogLambda, eMahalanobis, ...
%     elogP, a0, b0, h0, m0, W0, a, b, h, m, W, v, ga, gb, N, K, d, lowerBound);
%     if lowerBound1 < lowerBound
%         disp('V!!');
%     end
%     lowerBound = lowerBound1;
%     %DEBUG -- FIN
 
    % STEP 3: Compute variational lower bound and check for convergence
    % logp(X|mu, Lambda, Z, U)
    lowerBound = sum(sum(eZ .* (-0.5*d*log(2*pi) + 0.5*d*elogU + ...
        0.5*ones(N,1)*elogLambda - 0.5*eU.*eMahalanobis)));
    % logp(Z|pi)
    lowerBound = lowerBound + sum( eZ * elogP' );
    % logp(pi)
    lowerBound = lowerBound + gammaln(sum(a0)) - sum(gammaln(a0)) + ...
        (a0 - 1) * elogP';
    % logp(mu, Lambda)
    lowerBound = lowerBound + 0.5 * sum( d * log(inv(2*pi)*b0) + elogLambda ...
        -d * (b0 ./ b) ) + 0.5 * (h0 - d - 1) * elogLambda';
    for j = 1:K
        lowerBound = lowerBound - 0.5 * h(j) * ...
            (b0(j) * (m(:, j) - m0(:, j))' * W(:,:,j) * (m(:, j) - m0(:, j)) + ...
            trace(inv(W0(:,:,j)) * W(:,:,j)) );
        lowerBound = lowerBound + logWishartConstant(W0(:,:,j), h0(j));
    end
    % logp(U|v)
    lowerBound = lowerBound + N * sum( -gammaln(0.5*v) + 0.5*v.*log(0.5*v) ) + ...
        sum( elogU * (0.5*v-1)' - eU * (0.5*v)' );
    % logq(Z)
    posteriorEntropy = sum(sum(eZ .* log(eZ + eps)));
    % logq(pi)
    posteriorEntropy = posteriorEntropy + gammaln(sum(a)) - sum(gammaln(a)) + ...
        (a - 1) * elogP';
    % logq(mu, Lambda)
    posteriorEntropy = posteriorEntropy + sum( 0.5*elogLambda + 0.5*d*log(b*inv(2*pi)) - 0.5*d);
    for j = 1:K
        posteriorEntropy = posteriorEntropy + logWishartConstant(W(:,:,j), h(j));
        posteriorEntropy = posteriorEntropy + 0.5*(h(j) - d - 1)*elogLambda(j) - 0.5*h(j)*d;
    end
    % logq(U)
    posteriorEntropy = posteriorEntropy - sum(sum( ...
        gammaln(ga) - (ga - 1) .* digamma(ga) -log(gb) + ga));
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
    
    if strcmp(visual, 'on')
        drawDataAndKernels(X, m, h, W, a, v);
        film(iteration+1) = getframe();
    end
end
% End
hyperparameters = struct('m', m, 'b', b, 'W', W, 'h', h, 'a', a);
covar = zeros(size(W));
for j = 1:K
    covar(:,:,j) = inv(h(j)*W(:,:,j));
end
w = a / sum(a);
return;

function drawDataAndKernels(X, m, h, W, a, v)
[d K] = size(m);
covar = zeros(d, d, K);
scatter(X(1, :), X(2, :));
for j = 1:K
    covar(:,:,j) = inv(h(j)*W(:,:,j));
end
w = a / sum(a);
for j = 1:K
%     if v(j) > 2
%         w(j) = w(j) * v(j) * inv(v(j) - 2);
%     end
    if w(j) > 1e-2
        draw_ellipse(m(:,j), 6*w(j)*covar(:,:,j), ...
            [1 - exp(-0.1*v(j)) 0 exp(-0.1*v(j))]);
    end
end
return;

function res = bisection(k)
%Init
leftbound = 10e-3;
rightbound = 10;
if k >= 0
    res = 1; %FIX -- TEMPORARY
    disp('!');
    return; 
end
while 1
    if log(0.5*rightbound) - psi(0.5*rightbound) + k > 0
        rightbound = rightbound*2;
    else
        break;
    end
end
%Start
iter = 0;
while 1
    x = 0.5 * (leftbound + rightbound);
    y = log(0.5*x) - psi(0.5*x) + k;
    if abs(y) < 1e-3
        res = x;
        break;
    elseif y > 0
        leftbound = x;
    elseif y < 0
        rightbound = x;
    end
    iter = iter+1;
end %of while
return;

function B = logWishartConstant(W, v)
d = size(W, 1);
B = - (0.5*v*logdet(W) + ...
            0.5*v*d*log(2) + 0.25*d*(d-1)*log(pi) + ...
            sum(gammaln(0.5*(v + 1 - (1:d)))) );
return;

function lowerBound = computeLB(eZ, eU, elogU, elogLambda, eMahalanobis, ...
    elogP, a0, b0, h0, m0, W0, a, b, h, m, W, v, ga, gb, N, K, d, old)
    lowerBound = sum(sum(eZ .* (-0.5*d*log(2*pi) + 0.5*d*elogU + ...
        0.5*ones(N,1)*elogLambda - 0.5*eU.*eMahalanobis)));
    % logp(Z|pi)
    lowerBound = lowerBound + sum( eZ * elogP' );
    % logp(pi)
    lowerBound = lowerBound + gammaln(sum(a0)) - sum(gammaln(a0)) + ...
        (a0 - 1) * elogP';
    % logp(mu, Lambda)
    lowerBound = lowerBound + 0.5 * sum( d * log(inv(2*pi)*b0) + elogLambda ...
        -d * (b0 ./ b) ) + 0.5 * (h0 - d - 1) * elogLambda';
    for j = 1:K
        lowerBound = lowerBound - 0.5 * h(j) * ...
            (b0(j) * (m(:, j) - m0(:, j))' * W(:,:,j) * (m(:, j) - m0(:, j)) + ...
            trace(inv(W0(:,:,j)) * W(:,:,j)) );
        lowerBound = lowerBound + logWishartConstant(W0(:,:,j), h0(j));
    end
    % logp(U|v)
    lowerBound = lowerBound + N * sum( -gammaln(0.5*v) + 0.5*v.*log(0.5*v) ) + ...
        sum( elogU * (0.5*v-1)' - eU * (0.5*v)' );
    % logq(Z)
    posteriorEntropy = sum(sum(eZ .* log(eZ + eps)));
    % logq(pi)
    posteriorEntropy = posteriorEntropy + gammaln(sum(a)) - sum(gammaln(a)) + ...
        (a - 1) * elogP';
    % logq(mu, Lambda)
    posteriorEntropy = posteriorEntropy + sum( 0.5*elogLambda + 0.5*d*log(b*inv(2*pi)) - 0.5*d);
    for j = 1:K
        posteriorEntropy = posteriorEntropy + logWishartConstant(W(:,:,j), h(j));
        posteriorEntropy = posteriorEntropy + 0.5*(h(j) - d - 1)*elogLambda(j) - 0.5*h(j)*d;
    end
    % logq(U)
    posteriorEntropy = posteriorEntropy - sum(sum( ...
        gammaln(ga) - (ga - 1) .* digamma(ga) -log(gb) + ga));
    lowerBound = lowerBound - posteriorEntropy;
    

    if lowerBound < old
%         keyboard;
    end

return;