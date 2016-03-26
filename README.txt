This demo is to evaluate and compare 5 candidate imputation methods:
SKNN: selective imputation with KNN, KNN: unweighted mean KNN, MI: multiple imputation, LC: linear clustering, and CF: collaborative filtering.

Although any text data input is acceptable by this demo, we recommend to use the three default datasets:
adult_data.txt, census_data.txt, and clinic_data.txt.
Please do NOT change the file locations.
Please unzip MI_R_result.zip to the current folder.

===== Command Example =====
evaluateImputation('adult_data.txt',[1 3 5 11 12 13],'SKNN',0.1);
evaluateImputation('census_data.txt',[1 3 4 6 17 18 19 25 31 37 39 40 41],'MI');
evaluateImputation('clinic_data.txt',[8 11],'LC',0.01);
evaluateImputation('xxx_data.txt',[x x x],'CF',0.01,true,[]);
Please check Function Introduction to understand the arguments.


===== Behavior =====
This demo will display the evaluation of requested imputation method within a GUI, including the AC curve, attribute list and top / bottom 5 confident attributes, but the last two contents are only appliable for SKNN, and will only be displayed when SKNN or KNN has been completed.
Checking the "Compare All Methods" can display all existing AC curves provided by different methods.
The result of each running will be saved as a .mat file. E.g. clinic_data.txt_0.05_MI.mat is the result of MI method on clinic data with missing rate = 0.05. The evaluation will uses all existing results, therefore to regenerate a result please remove the corresponding result file.
We implemented MI method in R using the package Mice, and provide R result files. So in this demo we only collect and evaluate the R results, rather than implement MI here. Only miss_rate=0.01, 0.05 or 0.1 are allowed for MI.
Because clinic_data.txt is too large to run (1779966 complete records), we provided its all result files directly and suggest not to regenerate. E.g. To run SKNN method using clinic data on a 24-cores server with 140G memory, it cost 26h, 170h, and 280h wrt miss_rate=0.01, 0.05 and 0.1 respectively. We got the results by adopting parallel computing.
By running SKNN, KNN and LC, the remaining running time will be displayed real-timely.


===== Function Introduction =====
1. evaluateImputation(data_fname, cont_ind, method, [optional arguments: miss_rate, get_bins_tag])
The main function.
-- Arguments --
[1] data_fname: data file name, a string. 
data is a M*N matrix with each row as an instance and each column as an attribute.

[2] cont_ind: continuous indicator, a 1*n arry containing unrepeated integers in [1 N] that indicates which of the N attributs are continuous, and the others are disceret
e.g. for a 5-dimentional dataset, [1 2 5] means the 1st, 2nd and 5th attrbutes of the data are continuous values, and others are discrete.
Please use the following cont_ind for default three datasets:
adult_data.txt: [1 3 5 11 12 13]
census_data.txt: [1 3 4 6 17 18 19 25 31 37 39 40 41]
clinic_data.txt: [8 11]

[3] method: a string to indicate adopt method.
SKNN: selective imputation with KNN; MI: multiple imputation; LC: linear clustering; CF: collaborative filtering; KNN: unweighted mean KNN

-- Optional Arguments --
[4] miss_rate: Missing Rate, a scalar in interval (0,1), with default value 0.05

[5] get_bars_tag: Whether calculate distance bars for CF, a logical value
False is the default setting.
By false, an estimated cf_bars will be applied, which doesn't guarentee appropriate display for CF;
BY true, the accurate cf_bars will be calculated, which is relatively time consuming.
cf_bars will be displayed in std output.

[6] cf_bars: Specify distances bars for CF, a 1*20 increasing numeric array.
CF will use the 20 distance bars to calculate 21 results respectively (the last one is without setting any bar).
If in right format, cf_bars will be applied, otherwise get_bars_tag will take effect.
Note: the distance bars should be normalized distances, which means calculated over the normalized data with each attribute have values in [0 100]

Both [5] and [6] are not appliable for the three default datasets.

2. doImputation(data_fname, data, miss_rate, rand_arr, cont_ind, method, [optional arguments: get_bars_tag, cf_bars])
This function is for calling the imputation function corresponding to required method.
-- Arguments --
[4] rand_arr: rand_num*2 matrix.
rand_num is the number of random missing values, the first column of rand_arr is the row indexes of these missing values, and the second column is their column indexes in the data matrix.
Please refer to function evaluateImputation() for the other arguments.

3. [imput_arr, conf_arr] = doSKNN(data, rand_arr, cont_ind)
This function is to excute Selective KNN method.
-- Output --
[1] imput_arr: a 1*rand_num array, the filled missing values by using SKNN imputation method.
[2] conf_arr: a 1*rand_num array, the confidence values corresponding to each filled value.
Here we using entrpty to evaluate the confidence.

4. [imput_arr, conf_arr] = doLC(data, rand_arr, cont_ind, dist_bar)
This function is to excute Linear Clustering method
-- Input Arguments --
[1] dist_bar: a scalar to indicate the distance bar used in LC method.
This bar is the 15th value of cf_bars.
-- Output --
[1] imput_arr: a 1*rand_num array, the filled missing values by using LC imputation method.
[2] conf_arr: a 1*rand_num array, the confidence values corresponding to each filled value.
Here we using entrpty to evaluate the confidence.

5.[imput_mat] = doCF(data, rand_arr, cont_ind, cf_bars)
This function is to excute Colaborative Filtering method
-- Output --
[1] imput_mat: a rand_num*21 matrix, the filled missing values by using CF imputation method.
In imput_mat, each row corresponds to one missing value, and the 21 columns contains the values filled by using 21 distance bars (the last one is without any bar).

6. [imput_arr, truth_arr, conf_arr, rand_arr] = doMI(data_fname, miss_rate)
This function only collect conclusion from the result of R package Mice, rather than run MI. We use M=7 in Mice.
-- Output --
[1] imput_arr: a 1*rand_num array, the filled missing values by using LC imputation method.
[2] conf_arr: a 1*rand_num array, the confidence values corresponding to each filled value.
Here we using the purity of selected value over all candidate filled values to evaluate the confidence.

7. doEvaluation(data_fname, miss_rate, cont_ind)
This function evaluates all existing imputation results for required dataset and missing rate

8. displayAC(data_fname, miss_rate, method, cont_ind)
This function displays the AC curve required in a GUI and can compare the evaluations of all existing imputation results.

