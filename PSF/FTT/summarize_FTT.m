%% 
function [long,v_w,diff] = summarize_FTT(FTT,T_study,file_path)
T_study(isnat(T_study.Date),:) = [];
F = FTT;
F.user = string(extract(F.user,digitsPattern));
T_study_rep = vertcat(T_study,T_study);
T_study_rep = sortrows(T_study_rep,"SID","ascend");
T_study_rep = sortrows(T_study_rep,"StudyWeek","ascend");
T_study_rep = sortrows(T_study_rep,"Date","ascend");
T_study_rep = sortrows(T_study_rep,"StudyWeek","ascend");
T_study_rep = sortrows(T_study_rep,"SID","ascend");
T_study_rep.test_type = repmat(["Morning Testing";"Night Testing"],height(T_study),1);
T_study = T_study_rep;
try
    T_study = renamevars(T_study,"SID", "user");
end
T_study.user = string(T_study.user);
user = unique(T_study.user);
F.date = string(datetime(F.started_at/1000, "convertfrom","posixtime","Format","dd-MMM-uuuu","TimeZone","local"));
T = T_study;
T(or(and(T.Day == 1,T.test_type == "Morning Testing"),and(T.Day == 5,T.test_type == "Night Testing")),:) = [];
T_morning = F(F.test_type == "Morning Testing",:);
T_night = F(F.test_type == "Night Testing",:);
a = 1;
b = 2;
while a<height(T)
    sid = T{a,"user"};
    d_p = string(T{a,"Date"});
    t_n = T_night(and(T_night.user == sid,string(T_night.date) == d_p),:);
    if height(t_n) >=4
        target_set = unique(t_n.target);
        if length(target_set) == 1
            t_n = t_n(1:4,:);
            d_a = string(T{b,"Date"});
            t_m = T_morning(and(T_morning.user == sid,string(T_morning.date) == d_a),:);
            if height(t_m) == 0
            elseif height(t_m)>=4
                posix = unique(t_m.started_at);
                if length(posix) == 1 && height(t_m)>4
                    t_m = t_m(1:4,:);
                else
                    for i = 1:length(posix)
                        sample = t_m(t_m.started_at == posix(i),:);
                        target_0 = sample.target;
                        if contains(unique(string(t_n.target)),target_0(1))
                            t_m = sample;
                            break;
                        end
                    end
                end
            end
            if height(t_m)>4
                t_m = table;
            end

        else
            d_a = string(T{b,"Date"});
            t_m = T_morning(and(T_morning.user == sid,string(T_morning.date) == d_a),:);
            for i = 1:length(target_set)
                t_n_0 = t_n(string(t_n.target) == target_set(i),:);
                if height(t_m) == 0
                    t_n = t_n(end-3:end,:);
                elseif height(t_m)>=30
                    posix = unique(t_m.started_at);
                    if length(posix) == 1 && height(t_m)>4
                        t_m = t_m(1:4,:);
                    else
                        for i = 1:length(posix)
                            sample = t_m(t_m.started_at == posix(i),:);
                            target_0 = sample.target;
                            if contains(unique(string(t_n_0.target)),target_0(1))
                                t_m = sample;
                                t_n = t_n_0;
                                break;
                            end
                        end
                    end
                end
            end
        end
    else
        t_n = table;
        t_m = table;
    end
    c_names = ["score","error","test_trial","fastest_time","slowest_time","ave_time","std_time"];
    if height(t_m) == 0 || height(t_m)>4
        T{b,"target"} = "";
        for i = 1:4
            for j = 1:length(c_names)
                if c_names(j) == "test_trial"
                    T{b,append(c_names(j),"_",string(i))} = {[]};
                else
                   T{b,append(c_names(j),"_",string(i))} = nan;
                end
            end
        end
    else
        T{b,"target"} = string(t_m{1,"target"});
        for i = 1:height(t_m)
            for j = 1:length(c_names)
               T{b,append(c_names(j),"_",string(i))} = t_m{i,c_names(j)};
            end
        end

    end
    %for night
    if height(t_n) == 0 || height(t_n)>4
        T{a,"target"} = "";
        for i = 1:4
            for j = 1:length(c_names)
                if c_names(j) == "test_trial"
                    T{a,append(c_names(j),"_",string(i))} = {[]};
                else
                   T{a,append(c_names(j),"_",string(i))} = nan;
                end
            end
        end
    else 
        T{a,"target"} = string(t_n{1,"target"});
        for i = 1:height(t_n)
            for j = 1:length(c_names)
               T{a,append(c_names(j),"_",string(i))} = t_n{i,c_names(j)};
            end
        end

    end
    if T{b,"target"} ~= T{a,"target"}
        d_dtype = T.Properties.VariableNames(find(matches(T.Properties.VariableNames,"target")):end);
        c_dtype = d_dtype(contains(d_dtype,"test_trial"));
        s_dtype = d_dtype(contains(d_dtype,"target"));
        d_dtype = d_dtype(~contains(d_dtype,["target","test_trial"]));
        T{[a b],d_dtype} = nan;
        T{[a b],c_dtype} = {[]};
        T{[a b],"target"} = "did not match";
    end
    if a~=1
        if T{a,"target"} == T{a-2,"target"} && T{a,"target"} ~= "" && T{a,"StudyWeek"} == T{a-2,"StudyWeek"}
            d_dtype = T.Properties.VariableNames(find(matches(T.Properties.VariableNames,"target")):end);
            c_dtype = d_dtype(contains(d_dtype,"test_trial"));
            s_dtype = d_dtype(contains(d_dtype,"target"));
            d_dtype = d_dtype(~contains(d_dtype,["target","test_trial"]));
            T{[a b],d_dtype} = nan;
            T{[a b],c_dtype} = {[]};
            T{[a b],"target"} = "overlapped with previous session";
        end
    end

    a = a+2;
    b = b+2;
end
copy = T;
long = T;
%{
a = T
%a(isnat(a.Date),:) = [];
SID = unique(a.user);
trial = table;
for i = 1:length(SID)
    t = a(a.user == SID(i),:);
    w = unique(t.StudyWeek);
    for j = 1:length(w)
        t_w = t(t.StudyWeek == w(j),:);
        row_m = table;
        row_m{end+1,"user"} = SID(i);
        row_m{end,"Study_week"} = w(j);
        row_m{end,"test_type"} = "Morning Testing";
        m = t_w(string(t_w.test_type) == "Morning Testing",width(T_study)+2:end);
        for k = 1:height(m)
            r = m(k,:);
            col_names = string(r.Properties.VariableNames);
            for l = 1:length(col_names)
                col_names(l) = append(col_names(l),"_",string(k));
            end
            r = renamevars(r,r.Properties.VariableNames,col_names);
            row_m = horzcat(row_m,r);
        end
        row_n = table;
        row_n{end+1,"user"} = SID(i);
        row_n{end,"Study_week"} = w(j);
        row_n{end,"test_type"} = "Night Testing";
        n = t_w(string(t_w.test_type) == "Night Testing",width(T_study)+2:end);
        for k = 1:height(n)
            r = n(k,:);
            col_names = string(r.Properties.VariableNames);
            for l = 1:length(col_names)
                col_names(l) = append(col_names(l),"_",string(k));
            end
            r = renamevars(r,r.Properties.VariableNames,col_names);
            row_n = horzcat(row_n,r);
        end
        trial = vertcat(trial,row_m,row_n);
    end
end
B = trial(:,contains(trial.Properties.VariableNames,["fastest","slowest","ave_time","std_time"]));
for i = 1:width(B)
    col = B{:,i} == 0;
    B{col,i} = nan;
end
trial(:,contains(trial.Properties.VariableNames,["fastest","slowest","ave_time","std_time"])) = B;
wide = trial
%}

copy = long;
%copy(isnat(copy.Date),:) = [];
user = unique(copy.user);
FTT_diff = table;
for i = 1:4
    fix = ["fastest_time_","slowest_time_","ave_time_","std_time_"];
    for j = 1:length(fix)
        fix(j) = append(fix(j),string(i));
    end
    copy{copy{:,contains(copy.Properties.VariableNames,append("score_",string(i)))} == 0, fix} = nan;
end
T = copy;
copy{:,"CRSeqSum"} = copy{:,"score_1"} + copy{:,"score_2"} + copy{:,"score_3"} + copy{:,"score_4"};
copy{:,"CRSeqAve"} = copy{:,"CRSeqSum"}/4;
RT = mean(copy{:,contains(copy.Properties.VariableNames,"ave_time_")}.').';
copy{:,"RTAve"} = RT;
for i = 1:length(user)
    t = copy(copy.user == user(i),:);
    w = unique(t.StudyWeek);
    for j = 1:length(w)
        t_w = t(t.StudyWeek == w(j),:);
        row = table;
        row{end+1,"user"} = user(i);
        row{end,"StudyWeek"} = w(j);
        a = 1;
        for k = 1:height(t_w)
            if mod(k,2) ~= 0 
                row{end, append("CRSeqAve_Night",string(a))} = t_w{k,"CRSeqAve"};
                row{end, append("CRSeqSum_Night",string(a))} = t_w{k,"CRSeqSum"};
            else
                row{end, append("CRSeqAve_Morning",string(a+1))} = t_w{k,"CRSeqAve"};
                row{end, append("CRSeqSum_Morning",string(a+1))} = t_w{k,"CRSeqSum"};
                a = a+1;
            end
        end
        k = 1;
        n = 1;
        while k < height(t_w)
            pair = t_w(k:k+1,"RTAve");
            p_diff = pair(end,:) - pair(end-1,:);
            p_diff = renamevars(p_diff,p_diff.Properties.VariableNames,append("RT_Ov_perf_Night",string(n)));
            n = n+1;
            k = k+2;
            row = horzcat(row,p_diff);
        end
        FTT_diff = vertcat(FTT_diff,row);
    end
end
copy = T;
SID = unique(copy.user);
wide_wide = table;
for i = 1:length(SID)
    t = copy(copy.user == SID(i),:);
    w = unique(t.StudyWeek);
    for j = 1:length(w)
        t_w = t(t.StudyWeek == w(j),:);
        row = table;
        row{end+1, "SID"} = SID(i);
        row{end,"StudyWeek"} = w(j);
        m = t_w(t_w.test_type == "Morning Testing",find(matches(t_w.Properties.VariableNames,"target")):end);
        for k = 1:height(m)
            r = m(k,:);
            col_names = string(r.Properties.VariableNames);
            for l = 1:length(col_names)
                col_names(l) = append(col_names(l),"_AM_",string(k+1));
            end
            r = renamevars(r,r.Properties.VariableNames,col_names);
            row = horzcat(row,r);
        end

        n = t_w(t_w.test_type == "Night Testing", find(matches(t_w.Properties.VariableNames,"target")):end);
        for k = 1:height(n)
            r = n(k,:);
            col_names = string(r.Properties.VariableNames);
            for l = 1:length(col_names)
                col_names(l) = append(col_names(l),"_PM_",string(k));
            end
            r = renamevars(r,r.Properties.VariableNames,col_names);
            row = horzcat(row,r);
        end
        wide_wide = vertcat(wide_wide, row);
    end
end
copy = wide_wide;
reorder = copy(:,["SID","StudyWeek"]);
col_names = copy.Properties.VariableNames(3:end);
num_pat = extractAfter(col_names,"M_");
uniq_num = unique(num_pat);
for i = 1:length(uniq_num)
    reorder = horzcat(reorder,copy(:,col_names(matches(num_pat,uniq_num(i)))));
end
v_w = reorder;
diff = FTT_diff;
long(isnat(long.Date),:) = [];
long.Date = month(long.Date,'long');
long(:,["Blurghbo","Burst_Day_"]) = [];
writetable(long,append(file_path,'\Cog_Tasks\Cogtask data.xlsx'),'sheet','FTT');
writetable(long,append(file_path,'\PSF master data.xlsx'),'sheet','FTT');
writetable(long,append(file_path,'\Cog_Tasks\postprocessed\FTT\FTT_long.xlsx'));
save(append(file_path,'\Cog_Tasks\postprocessed\FTT\FTT_long.mat'),"long");
%writetable(wide,append(file_path,'\output\cog_tasks\FTT\FTT_wide_AMPM.csv'));
writetable(v_w,append(file_path,'\Cog_Tasks\postprocessed\FTT\FTT_wide.xlsx'));
writetable(FTT_diff,append(file_path,'\Cog_Tasks\postprocessed\FTT\FTT_summary.xlsx'));
end