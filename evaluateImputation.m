function evaluateImputation(data_fname,cont_ind,method,varargin)
% This function is to evaluate performance of any candidate imputation method.
% Any text data input is acceptable, but we recommand to use the two default datasets:
% adult_data.txt census_data.txt
% ### Due to protect privacy, we do NOT provide clinic data and the corresponding results. ###
% Please do NOT move their location and use particular cont_ind for the default datasets.
% Any missing rate is acceptable, but we reccomand to use 0.01, 0.05 or 0.1,
% because MI is only available for the three rates.

% Example:
% evaluateImputation('adult_data.txt',[1 3 5 11 12 13],'SKNN',0.1);
% evaluateImputation('census_data.txt',[1 3 4 6 17 18 19 25 31 37 39 40 41],'MI');
% evaluateImputation('xxx_data.txt',[x x x],'CF',0.01,true,[]);

%-- Arguments --%
% [1] data_fname: data file name, a string. 
% data is a M*N matrix with each row as an instance and each column as an attribute.

% [2] cont_ind: continuous indicator, a 1*n arry containing unrepeated integers in [1 N]
% that indicates which of the N attributs are continuous, and the others are disceret
% e.g. for a 5-dimentional dataset, [1 2 5] means the 1st, 2nd and 5th 
% attrbutes of the data are continuous values, and others are discrete.
% Please use the following cont_ind for default three datasets:
% adult_data.txt: [1 3 5 11 12 13]
% census_data.txt: [1 3 4 6 17 18 19 25 31 37 39 40 41]

% [3] method: a string to indicate adopt method.
% SKNN: selective imputation with KNN; MI: multiple imputation;
% LC: linear clustering; CF: collaborative filtering; KNN: unweighted mean KNN

%-- Optional Arguments --%
% [4] miss_rate: Missing Rate, a scalar in interval (0,1), with default value 0.05

% [5] get_bars_tag: Whether calculate distance bars for CF, a logical value
% False is the default setting.
% By false, an estimated cf_bars will be applied, which doesn't guarentee appropriate display for CF;
% BY true, the accurate cf_bars will be calculated, which is relatively time consuming.
% cf_bars will be displayed in std output.

% [6] cf_bars: Specify distances bars for CF, a 1*20 increasing numeric array.
% CF will use the 20 distance bars to calculate 20 results respectively.
% If in right format, cf_bars will be applied, otherwise get_bars_tag will take effect.
% Note: the distance bars should be normalized distances, which means
% calculated over the normalized data with each attribute have values in [0 100]

% Both [5] and [6] are not appliable for the three default datasets.


if (~ischar(data_fname))
    fprintf('Data File Name: string\n)');
    return;
end
data = load(data_fname);

col_num = size(data,2);
if ~isnumeric(cont_ind)
    cont_ind_tag = false;
else
    tag1 = sum(mod(cont_ind,1)) == 0;
    tag2 = sum(cont_ind>=1 & cont_ind<=col_num) == length(cont_ind);
    tag3 = length(unique(cont_ind)) == length(cont_ind);
    cont_ind_tag = tag1 & tag2 & tag3;
end
if ( ~ismatrix(data) || ~cont_ind_tag || ~ischar(method))
    fprintf('Input Requirement:\n Data: M*N numeric matrix, Continuous Indicator: 1*n integer array n<=N, Method: string\n')
    return;
end
cont_ind = sort(cont_ind);

switch data_fname
    case 'adult_data.txt'
        my_cont_ind = [1 3 5 11 12 13];
    case 'census_data.txt'
        my_cont_ind = [1 3 4 6 17 18 19 25 31 37 39 40 41];
    otherwise
        my_cont_ind = [];
end

if ~isempty(my_cont_ind)
    wrong_idx = ~bsxfun(@eq,my_cont_ind,cont_ind);
    if (sum(wrong_idx)>0)
        fprintf('Continuous Indicator for %s should be [%s] \n',data_fname,num2str(my_cont_ind));
        return;
    end
end

if ( ~ismember(method, {'SKNN','KNN','MI','LC','CF'}))
    fprintf('Method should be in [SKNN, KNN, MI, LC, CF]\n');
    return;
end

if (nargin>=4)
    miss_rate = varargin{1};
    if ( ~isscalar(miss_rate) || miss_rate<=0 || miss_rate >=1)
        fprintf('Warning: Missing Rate must be in (0,1)! By default Missing Rate = 0.05\n');
        miss_rate = 0.05;
    end
else
    miss_rate = 0.05;
    fprintf('By default Missing Rate = 0.05\n');
end

cf_bars = [];
get_bars_tag = false;
if strcmp(method,'CF')
    if (nargin>=6)
        cf_bars = varargin{3};
        cf_bars = sort(cf_bars(:))';
        if ( ~isnumeric(cf_bars) || length(cf_bars)~=20 || sum(isnan(cf_bars)))
            cf_bars = [];
            fprintf('Warning: Invalid Distance Bins! Ignore...\n');
        end
    end
    
    if (isempty(cf_bars) && nargin>=5)
        get_bars_tag = varargin{2};
        if ( ~islogical(get_bars_tag))
            fprintf('Warning: get_bins_tag must be logical! By default using false.\n')
            get_bars_tag = false;
        end
    elseif(isempty(cf_bars))
        fprintf('By default get_bars_tag = false\n');
    end

end

% preprocessing
data = preprocess(data);

% random missing value
rand_arr = random_miss(data, miss_rate);

% do imputation
doImputation(data_fname, data, miss_rate, rand_arr, cont_ind, method, get_bars_tag, cf_bars);

% evaluation: plot AC (acuracy and completion) curve 
doEvaluation(data_fname, miss_rate, cont_ind);
displayAC(data_fname, miss_rate, method, cont_ind);
% evaluation: plot Attributes CV (Confidence value)

end

