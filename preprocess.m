function outData = preprocess(inData)
    nan_idx = logical(sum(isnan(inData),2));
    outData = inData(~nan_idx,:);
    clear inData;
    
    % normalization to [0 100]
    [~,attr_num] = size(outData);
    for i = 1:attr_num
        cur_step = (max(outData(:,i)) - min(outData(:,i)))/100;
        if (cur_step==0)
            outData(:,i) = 100;
        else
            outData(:,i) = (outData(:,i) - min(outData(:,i)))/cur_step;
        end
    end
end