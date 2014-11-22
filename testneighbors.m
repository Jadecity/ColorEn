load ftmap;
data = ftmap(:, 1:100000);
for neighbor=10:20:100
    tic
    gen_nn_distance( data', neighbor, 10000, 0);
    toc
end

    
    
