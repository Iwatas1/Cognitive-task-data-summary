function a = WPA_scoring(t,study)
a = study;
if height(t)~=0
    a.wordpair_sets = t{1,"wordpair_sets"};
    a.same_c = height(t(and(t.rearranged == 0,t.isCorrect == 1),:));
    a.same_ic = height(t(and(t.rearranged == 0,t.isCorrect == 0),:));
    a.diff_c = height(t(and(t.rearranged == 1,t.isCorrect == 1),:));
    a.diff_ic = height(t(and(t.rearranged == 1,t.isCorrect == 0),:));
    a.same_c_ave_confidence_rate = mean(t{and(t.rearranged == 0,t.isCorrect == 1),"confidence_rate"});
    a.same_ic_ave_confidence_rate = mean(t{and(t.rearranged == 0,t.isCorrect == 0),"confidence_rate"});
    a.diff_c_ave_confidence_rate = mean(t{and(t.rearranged == 1,t.isCorrect == 1),"confidence_rate"});
    a.diff_ic_ave_confidence_rate = mean(t{and(t.rearranged == 1,t.isCorrect == 0),"confidence_rate"});
else
    a.wordpair_sets = cell(1,1);
    a.same_c = nan;
    a.same_ic = nan;
    a.diff_c = nan;
    a.diff_ic = nan;
    a.same_c_ave_confidence_rate = nan;
    a.same_ic_ave_confidence_rate = nan;
    a.diff_c_ave_confidence_rate = nan;
    a.diff_ic_ave_confidence_rate = nan;
end
end

