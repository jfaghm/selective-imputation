function [imput_mat] = doCF(data, rand_arr, cont_ind, cf_bars)
% Colaborative Filtering method
    [row_num, col_num] = size(data);
    row_rand = rand_arr(:,1);
    col_rand = rand_arr(:,2);
    rand_num = length(row_rand);
    cf_bars = [cf_bars inf];
    bins_num = length(cf_bars);

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
    
    imput_mat = -inf(rand_num, bins_num);
    
    t = 1;
    timer_arr = zeros(1,miss_row_num);
    for i = 1:miss_row_num
        tic;
        cur_row = miss_row(i);
        cur_data = data(cur_row,:);
        cur_row_miss = miss_stamp(cur_row,:);
        
        % compute distance
        minus_mat = bsxfun(@minus, data, cur_data);
        nanzero_idx = minus_mat~=0;
        minus_mat(catig_stamp & nanzero_idx) = 100;
        minus_mat(miss_stamp) = 100;
        minus_mat(:,cur_row_miss) = 100;
        minus_mat(cur_row,:) = 0;
        dist_arr = sqrt(sum(minus_mat.^2,2));
        
        cur_row_miss_num = sum(cur_row_miss);
        cur_row_miss = find(cur_row_miss);
        for k = 1:bins_num
            cur_bin = cf_bars(k);
            cur_nn_idx = dist_arr<=cur_bin;
            if (find(cur_nn_idx)==cur_row)
                imput_mat(t:(t+cur_row_miss_num-1),k) = -1;
                continue;
            end
            
            for j = 1:cur_row_miss_num
                cur_col = cur_row_miss(j);
                truth_idx = ~miss_stamp(cur_nn_idx,cur_col);
                if (sum(truth_idx)==0)
                    imput_mat(t+j-1,k) = -1;
                    continue;
                end
                
                nn_values = data(cur_nn_idx,cur_col);
                nn_values = nn_values(truth_idx);
                % compute current imputation value
                
                if (cont_tag(cur_col))
                    cur_imp_val = mean(nn_values);
                else
                    my_cati = [unique(nn_values); 101];
                    h = histcounts(nn_values, my_cati);
                    [~,max_cati] = max(h);
                    cur_imp_val = my_cati(max_cati);
                end
                imput_mat(t+j-1,k) = cur_imp_val;
            end
            
        end
        t = t+cur_row_miss_num;
        
        timer_arr(i) = toc;
        if mod(i,500)==0
            time = sum(timer_arr(1:i));
            left_time = (time/i)*(miss_row_num-i);
            c=clock;c=c(4:6);
            percentage = num2str(round((i/miss_row_num)*100,2));
            fprintf('%d:%d:%d %s%s completed using %dh %dm %ds, about %dh %dm %ds left \n', ...
                c(1), c(2), floor(c(3)), percentage, '%',...
                floor(time/3600), floor(rem(time,3600)/60), floor(rem(rem(time,3600),60)),...
                floor(left_time/3600), floor(rem(left_time,3600)/60), floor(rem(rem(left_time,3600),60)));
        end
    end
    time = sum(timer_arr);
    c=clock;c=c(4:6);
    fprintf('%d:%d:%d Completed! Using %dh %dm %ds in total \n', ...
        c(1), c(2), floor(c(3)), floor(time/3600), floor(rem(time,3600)/60), floor(rem(rem(time,3600),60)));

end

