function t = overnight_scoring(s2,data_exist,sub)
if data_exist == false %only evaluating the S2
    sub{1,"CT1T2"} = nan;
    sub{1,"CT1WT2"} = nan;
    sub{1,"WT1CT2"} = nan;
    sub{1,"WT1T2"} = nan;

    sub{1,"improvement_rate"} = nan;
    sub{1,"deterioration_rate"} = nan;

    sub{1,"ave_distance_difference"} = nan; %this includes the one that you get it wrong on S1 but correct on S2
    sub{1,"std_distance_difference"} = nan;
    sub{1,"ave_correctness_change"} = nan;
    sub{1,"std_correctness_change"} = nan;
else
    sub{1,"CT1T2"} = sum(and(s2.first_test_correct,s2.second_test_correct));
    sub{1,"CT1WT2"} = sum(and(s2.first_test_correct,~s2.second_test_correct));
    sub{1,"WT1CT2"} = sum(and(~s2.first_test_correct,s2.second_test_correct));
    sub{1,"WT1T2"} = sum(and(~s2.first_test_correct,~s2.second_test_correct));

    sub{1,"improvement_rate"} = sub{1,"WT1CT2"}/height(s2);
    sub{1,"deterioration_rate"} = sub{1,"CT1WT2"}/height(s2);

    sub{1,"ave_distance_difference"} = mean(s2.response_distance); %this includes the one that you get it wrong on S1 but correct on S2
    sub{1,"std_distance_difference"} = std(s2.response_distance);
    sub{1,"ave_correctness_change"} = mean(s2.correctness_change_numeric);
    sub{1,"std_correctness_change"} = std(s2.correctness_change_numeric);
end
t = sub;
end
