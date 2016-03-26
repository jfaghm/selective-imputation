function doImputation(data_fname, data, miss_rate, rand_arr, cont_ind, method, varargin)
% To excute imputation using required method
    save_fname = sprintf('%s_%s_%s.mat',data_fname,num2str(miss_rate),method);
    if (exist(save_fname,'file'))
        return;
    end

    col_num = size(data,2);
    row_rand = rand_arr(:,1);
    col_rand = rand_arr(:,2);
    data_trans = data';
    truth_arr = data_trans((row_rand-1)*col_num + col_rand)';
    
    cf_dist_bars = {...
    [100.3645  100.5529  100.7638  100.9768  101.2705  101.6005  102.0496  102.6355  104.1455  144.6897  150.4072  159.8908  166.3221  171.8974  177.1871  182.4688  188.1682  195.0255  205.2133  305.3094],...
    [100.1493  100.7839  111.9006  141.4253  141.4734  141.6021  142.0325  147.5021  173.3152  203.3301  224.8580  245.0400  245.1799  246.2618  250.3665  265.3692  267.3366  283.3406  286.9641  361.0777],...
    [100.0508  141.4290  150.3086  173.3625  185.2698  200.8936  223.6089  244.1964  256.6413  269.0863  282.8709  299.5496  316.2283  335.9484  358.5553  374.7362  390.3366  408.3041  411.1566  430.2870]};
    switch data_fname
        case 'clinic_data.txt'
            my_bars = cf_dist_bars{1}; dist_bar = my_bars(15);
        case 'adult_data.txt'
            my_bars = cf_dist_bars{2}; dist_bar = my_bars(15);
        case 'census_data.txt'
            my_bars = cf_dist_bars{3}; dist_bar = my_bars(15);
        otherwise
            my_bars = []; 
            % estimate a distance bar
            dist_bar = (sqrt(col_num)*80-100)*15/19+100;
    end
    
    switch method 
        case 'SKNN'
            [imput_values, conf_arr] = doSKNN(data, rand_arr, cont_ind);
        case 'KNN'
            method = 'SKNN';
            save_fname = sprintf('%s_%s_%s.mat',data_fname,num2str(miss_rate),method);
            if (exist(save_fname,'file'))
                return;
            else
                [imput_values, conf_arr] = doSKNN(data, rand_arr, cont_ind);
            end
        case 'MI'
            [imput_values, truth_arr, conf_arr, rand_arr] = doMI(data_fname, miss_rate);
            if isempty(imput_values)
                return;
            end
        case 'LC'
            [imput_values, conf_arr] = doLC(data, rand_arr, cont_ind, dist_bar);
        case 'CF'
            if isempty(my_bars)
                my_bars = varargin{2};
            end
            if isempty(my_bars)
                get_bars_tag = varargin{1};
                my_bars = get_bars(data, cont_ind, get_bars_tag);
            end
            display(my_bars);
            imput_values = doCF(data, rand_arr, cont_ind, my_bars);
            conf_arr = [];
        otherwise
            fprintf('Error!\n');
            return;
    end

    save(save_fname, 'imput_values', 'conf_arr', 'truth_arr', 'rand_arr');
end

function my_bars = get_bars(data, cont_ind, tag)
    [row_num, col_num] = size(data);
    
    if (~tag)
        % estimate a group of distance bins
        max_bar = sqrt(col_num)*80;
        min_bar = 100;
        my_bars = min_bar:((max_bar-min_bar)/19):max_bar;
        return;
    end
    
    % tag==true calculate bins
    if (row_num > 10000)
        data = data(randsample(row_num,10000),:);
        row_num = 10000;
    end
    
    rand_arr = random_miss(data, 0.05);
    row_rand = rand_arr(:,1);
    col_rand = rand_arr(:,2);

    [miss_row,miss_row_cuts] = unique(row_rand);
    miss_row_num = length(miss_row);
    miss_row_cuts = [miss_row_cuts; miss_row_num+1];
    
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
    
    dist_mat = -inf(miss_row_num, row_num);
    for i = 1:miss_row_num
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
        dist_mat(i,:) = dist_arr(:);
    end
    
    min_arr = min(dist_mat,[],2);
    min_bars = quantile(min_arr,19);
    whole_bars = quantile(dist_mat(:),19);
        
    my_bars = sort([min_bars(2:2:18) max(min_arr) whole_bars(2:2:18) max(dist_mat(:))]);
    fprintf('Get Bins:\n');
    display(my_bars);
end
