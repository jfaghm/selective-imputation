function [imput_arr, conf_arr] = doLC(data, rand_arr, cont_ind, dist_bar)
% Linear Clustering method
    [row_num, col_num] = size(data);
    row_rand = rand_arr(:,1);
    col_rand = rand_arr(:,2);
    rand_num = length(row_rand);
    imput_mat = spalloc(row_num, col_num, rand_num);
    conf_mat = spalloc(row_num, col_num, rand_num);

    [miss_row,miss_row_cuts] = unique(row_rand);
    miss_row_num = length(miss_row);
    miss_row_cuts = [miss_row_cuts; rand_num+1];
    
    miss_stamp = false(row_num, col_num);
    for i = 1:miss_row_num
        cur_row = miss_row(i);
        ss = miss_row_cuts(i);
        ee = miss_row_cuts(i+1)-1;
        cur_cols = col_rand(ss:ee);
        miss_stamp(cur_row,cur_cols) = true;
    end

    cont_tag = false(1,col_num);
    cont_tag(cont_ind) = true;
    cont_stamp = repmat(cont_tag,row_num,1);
    catig_stamp = ~cont_stamp;

    % build up clusters
    cluster_arr = zeros(row_num, 1);
    rownum_arr = 1:row_num;
    cur_cluster = 1;
    unset_idx = cluster_arr==0;
    while (sum(unset_idx)>0)
        if (sum(unset_idx)==1)
            cur_row = find(unset_idx);
        else
            cur_row = randsample(find(unset_idx),1);
        end
        cur_data = data(cur_row,:);
        cur_row_miss = miss_stamp(cur_row,:);
        unset_rownum_arr = rownum_arr(unset_idx);
        
        % compute distance
        minus_mat = bsxfun(@minus, data(unset_idx,:), cur_data);
        nanzero_idx = minus_mat~=0;
        minus_mat(catig_stamp(unset_idx,:) & nanzero_idx) = 100;
        minus_mat(miss_stamp(unset_idx,:)) = 100;
        minus_mat(:,cur_row_miss) = 100;
        minus_mat(sum(unset_idx(1:cur_row)),:) = 0;

        dist_arr = sqrt(sum(minus_mat.^2,2));
        top_idx = dist_arr <= dist_bar;
        cur_rownum = unset_rownum_arr(top_idx);
        
        % set current cluster
        cluster_arr(cur_rownum) = cur_cluster;
        cur_cluster = cur_cluster+1;
        unset_idx = cluster_arr==0;
        
        % impute missing values in curren cluster
        % and evaluate each confidence
        cur_miss_stamp = miss_stamp(cur_rownum,:);
        cur_miss_tag = logical(sum(cur_miss_stamp,1));
        for j = 1:col_num
            if (~cur_miss_tag(j))
                continue;
            end
            
            nn_miss_stamp = cur_miss_stamp(:,j);
            if (sum(~nn_miss_stamp)==0)
                imput_mat(cur_rownum, j) = -1;
                conf_mat(cur_rownum, j) = inf;
                continue;
            end
            
            nn_values = data(cur_rownum,j);
            nn_values = nn_values(~nn_miss_stamp);
            
            % compute current column's imputation values
            my_cati = [unique(nn_values); 101];
            h = histcounts(nn_values, my_cati);
            if (cont_tag(j))
                cur_imp_val = mean(nn_values);
            else
                [~,max_cati] = max(h);
                cur_imp_val = my_cati(max_cati);
            end
            if cur_imp_val==0
                imput_mat(cur_rownum(nn_miss_stamp), j) = -2;
            else
                imput_mat(cur_rownum(nn_miss_stamp), j) = cur_imp_val;
            end
            
            % compute current column's confidence value (etp)
            cur_prob_distr = h/sum(h);
            temp = log2(cur_prob_distr); temp(temp==-Inf)=0;
            cur_etp_val = -sum(cur_prob_distr.*temp);
            if cur_etp_val==0
                conf_mat(cur_rownum(nn_miss_stamp), j) = -2;
            else
                conf_mat(cur_rownum(nn_miss_stamp), j) = cur_etp_val;
            end
        end
    end

    imput_mat = imput_mat';
    imput_arr = full(imput_mat(find(imput_mat)))';
    imput_arr(imput_arr==-2) = 0;
    conf_mat = conf_mat';
    conf_arr = full(conf_mat(find(conf_mat)))';
    conf_arr(conf_arr==-2) = 0;
end
