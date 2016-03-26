function rand_arr = random_miss(data, miss_rate)
    [N, M] = size(data);
    rand_n = floor(miss_rate*N*M);
    row_rand = randsample(N, rand_n, true);
    col_rand = randsample(M, rand_n, true);
    A = [row_rand col_rand];
    A = unique(A,'rows');
    true_n = size(A,1);
    while (true_n<rand_n)
        row_rand = randsample(N, (rand_n-true_n), true);
        col_rand = randsample(M, (rand_n-true_n), true);
        B = [row_rand col_rand]; A = [A; B];
        A = unique(A,'rows');
        true_n = size(A,1);
    end
    %row_rand = A(:,1);
    %col_rand = A(:,2);
    rand_arr = A;
end