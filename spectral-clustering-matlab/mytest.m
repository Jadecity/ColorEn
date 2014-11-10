tic
W = SimGraph_NearestNeighbors( cat(2,ftmap(:, 800:1000), ftmap(:,3000:3100)) ...
                               , 50, 1,  1);
toc
tic
C = SpectralClustering( W, 2, 3 );
toc