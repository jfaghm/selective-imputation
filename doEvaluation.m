function doEvaluation(data_fname, miss_rate, cont_ind)
% Evaluate all existing imputation results for required dataset
    methods = {'SKNN', 'MI', 'LC', 'CF'};
    sknn_eval = [];sknn_cols = [];sknn_colConf = [];sknn_colRate = [];
    knn_eval = [];
    mi_eval = [];
    lc_eval = [];
    cf_eval = [];
    for m = 1:4
        method = methods{m};
        res_fname = sprintf('%s_%s_%s.mat',data_fname,num2str(miss_rate),method);
        if (~exist(res_fname,'file'))
            continue;
        end
        load(res_fname);
        % 'imput_values', 'conf_arr', 'truth_arr', 'rand_arr'

        % compute result and accuracy rate
        switch method
            case {'SKNN', 'LC'}
                rm_idx = imput_values==-1;
                imput_values = imput_values(~rm_idx);
                conf_arr = conf_arr(~rm_idx);
                truth_arr = truth_arr(~rm_idx);
                rand_arr = rand_arr(~rm_idx,:);
                
                rand_num = length(conf_arr);
                [conf_arr,I] = sort(conf_arr);
                res_arr = abs(imput_values(I) - truth_arr(I))/100;
                col_rand = rand_arr(:,2);
                col_rand = col_rand(I)';
                catig_idx = ~ismember(col_rand, cont_ind);
                nonzero_idx = res_arr~=0;
                res_arr(catig_idx & nonzero_idx) = 1;

                step = rand_num/20;
                conf_cuts = floor(0:step:rand_num);
                conf_cuts = conf_cuts(2:end);
                my_rates = zeros(1,20);
                for i = 1:20
                    cur_cut = conf_cuts(i);
                    my_rates(i) = 1 - sum(res_arr(1:cur_cut))/cur_cut;
                end
                my_cuts = (conf_cuts./rand_num)*20;

                if strcmp(method,'SKNN')
                    sknn_rates = my_rates;
                    sknn_cuts = my_cuts;
                    sknn_eval = [sknn_cuts; sknn_rates];
                    knn_cuts = [0 20];
                    knn_rates = [sknn_rates(i) sknn_rates(i)];
                    knn_eval = [knn_cuts; knn_rates];
                    
                    sknn_cols = unique(col_rand);
                    cols_num = length(sknn_cols);
                    sknn_colConf = zeros(1,cols_num);
                    sknn_colRate = zeros(1,cols_num);
                    for i = 1:cols_num
                        my_col = sknn_cols(i);
                        my_idx = col_rand == my_col;
                        sknn_colConf(i) = mean(conf_arr(my_idx));
                        sknn_colRate(i) = 1-sum(res_arr(my_idx))/sum(my_idx);
                    end
                    [sknn_colConf,I] = sort(sknn_colConf);
                    sknn_cols = sknn_cols(I);
                    sknn_colRate = sknn_colRate(I);
                else
                    lc_rates = my_rates;
                    lc_cuts = my_cuts;
                    lc_eval = [lc_cuts; lc_rates];
                end

            case 'MI'
                rm_idx = isnan(imput_values);
                imput_values = imput_values(~rm_idx);
                conf_arr = conf_arr(~rm_idx);
                truth_arr = truth_arr(~rm_idx);
                rand_arr = rand_arr(~rm_idx,:);
                
                res_arr = abs(imput_values - truth_arr)/100;
                col_rand = rand_arr(:,2);
                col_rand = col_rand';
                catig_idx = ~ismember(col_rand, cont_ind);
                nonzero_idx = res_arr~=0;
                res_arr(catig_idx & nonzero_idx) = 1;
                
                rand_num = length(conf_arr);
                conf_values = unique(conf_arr);
                conf_num = length(conf_values);
                mi_cuts = zeros(1,conf_num);
                mi_rates = zeros(1,conf_num);
                for i = 1:conf_num
                    cur_conf = conf_values(conf_num-i+1);
                    cur_conf_idx = conf_arr >= cur_conf;
                    mi_cuts(i) = sum(cur_conf_idx)/rand_num;
                    mi_rates(i) = 1 - sum(res_arr(cur_conf_idx))/sum(cur_conf_idx);
                end
                mi_cuts = mi_cuts*20;
                mi_eval = [mi_cuts; mi_rates];
            case 'CF'
                [rand_num,bins_num] = size(imput_values);
                col_rand = rand_arr(:,2);
                cf_cuts = zeros(1,bins_num);
                cf_rates = zeros(1,bins_num);
                for i = 1:bins_num
                    bin_vals = imput_values(:,i);
                    imput_idx = bin_vals~=-1;
                    cf_cuts(i) = (sum(imput_idx)/rand_num)*20;
                    res_arr = abs(bin_vals(imput_idx)' - truth_arr(imput_idx))/100;
                    col_arr = col_rand(imput_idx)';
                    catig_idx = ~ismember(col_arr, cont_ind);
                    nonzero_idx = res_arr~=0;
                    res_arr(catig_idx & nonzero_idx) = 1;
                    cf_rates(i) = 1 - sum(res_arr)/sum(imput_idx);
                end
                cf_eval = [cf_cuts; cf_rates];
        end
    end
    
    eval_fname = sprintf('%s_%s_eval.mat',data_fname,num2str(miss_rate));
    save(eval_fname,'sknn_eval','sknn_cols','sknn_colConf','sknn_colRate','knn_eval','mi_eval','lc_eval','cf_eval');
    
end