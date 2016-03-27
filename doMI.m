function [imput_arr, truth_arr, conf_arr, rand_arr] = doMI(data_fname, miss_rate)
% Only collect conclusion from the result of R package Mice, rather than run MI
    imput_arr = [];
    truth_arr = [];
    conf_arr = [];
    switch data_fname
        case 'adult_data.txt'
            R_root = 'MI_R_result/adult/adult_data_';
        case 'census_data.txt'
            R_root = 'MI_R_result/census/census_data_';
        otherwise
                fprintf('Not appliable for not default dataset.\n');
                return;
    end
    if (~ismember(miss_rate,[0.01 0.05 0.1]))
        fprintf('Only appliable for miss_rate = [0.01 0.05 0.1].\n')
        return;
    end
    
    rate_str = num2str(miss_rate*100);
    Rres_name = sprintf('%s%s_Rres.txt',R_root,rate_str);
    if ~exist(Rres_name,'file');
        fprintf('No result files found! \n');
        return;
    end
    
    % get & clear data 
    data = load(data_fname);
    nan_idx = logical(sum(isnan(data),2));
    data = data(~nan_idx,:);
    % get normalization steps
    [~,col_num] = size(data);
    step_arr = zeros(1,col_num);
    min_arr = zeros(1,col_num);
    for i = 1:col_num
        cur_max = max(data(:,i));
        cur_min = min(data(:,i));
        cur_step = (cur_max - cur_min)/100;
        if cur_step==0
            cur_min = 0;
            cur_step = cur_max/100;
        end
        min_arr(i) = cur_min;
        step_arr(i) = cur_step;
    end
    
    % get imput_data
    imput_data = load(Rres_name);
    % get miss_stamp
    Rdata_name = sprintf('%s%s.txt',R_root,rate_str);
    miss_data = load(Rdata_name);
    miss_stamp = isnan(miss_data);
    
    [rand_row,~] = find(miss_stamp); rand_row = sort(rand_row);
    [rand_col,~] = find(miss_stamp');
    rand_arr = [rand_row, rand_col];
    
    data_trans = data';
    imput_data_trans = imput_data';
    truth_arr = data_trans(miss_stamp')';
    imput_arr = imput_data_trans(miss_stamp')';
    
    % normalize truth_arr and imput_arr
    res_min_arr = min_arr(rand_col);
    res_step_arr = step_arr(rand_col);
    truth_arr = (truth_arr - res_min_arr)./res_step_arr;
    imput_arr = (imput_arr - res_min_arr)./res_step_arr;
    
    % compute conf
    M = 7;
    conf_mat = -inf(size(imput_data));
    for i = 1:col_num
        vfile_name = sprintf('%s%s_v%d.txt',R_root,rate_str,i);
        
        v_res = load(vfile_name);
        cur_miss_idx = miss_stamp(:,i);
        if isempty(v_res)
            conf_mat(cur_miss_idx,i) = 0;
            continue;
        end
        
        vote_mat = bsxfun(@eq,v_res,imput_data(cur_miss_idx,i));
        cur_purt = sum(vote_mat,2)/M;
        conf_mat(cur_miss_idx,i) = cur_purt;
    end
    conf_mat_trans = conf_mat';
    conf_arr = conf_mat_trans(miss_stamp')';
end