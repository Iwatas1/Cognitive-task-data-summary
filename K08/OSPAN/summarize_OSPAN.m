function [a,b,c,d,e,f,no_count] = summarize_OSPAN(OSPAN,T_study,file_path)
cfg = study_config();
T = OSPAN;
T_study(isnat(T_study.Date),:) = [];
T.problem_set = string(T.problem_set);
T.started_at_pst = datetime(T.started_at ./ 1000,'convertfrom','posixtime','TimeZone','America/Los_Angeles', 'Format','dd-MMM-yyyy HH:mm:ss'); %convert unixstamp into PST
T{ismember(T.user, cfg.ms_timestamp_ids),"started_at_pst"} = datetime(T{ismember(T.user, cfg.ms_timestamp_ids),"started_at"} ./ 1000,'convertfrom','posixtime','TimeZone','Europe/Berlin', 'Format','dd-MMM-yyyy HH:mm:ss');
T.time = timeofday(T.started_at_pst);
T_study.SID = string(T_study.SID);
user = unique(T_study.SID);%recognizing different user
hours = hour(T.started_at_pst);
T{:,"AMPM"} = "PM";
T{and(hours > 4,hours < 15),"AMPM"} = "AM"; %change accordingly
T.date = string(datetime(T.started_at_pst,"Format","dd-MMM-uuuu"));
T_study_rep = table;
for i = 1:height(T_study)
    T_study_rep = vertcat(T_study_rep,horzcat(repelem(T_study(i,:),2,1),{"AM","PM"}.'));
end
T_study_rep = renamevars(T_study_rep,T_study_rep.Properties.VariableNames{end},"AMPM");
T.letters = string(T.letters);
T.letter = string(T.letter);
T.user_letters = string(T.user_letters);
scores = table;

for i = 1:height(T_study_rep)   
    t = T(T.user == T_study_rep{i,"SID"},:);
    d = t(t.date == string(T_study_rep{i,"Date"}),:);
    test = d(d.AMPM == T_study_rep{i,"AMPM"},:);
    if height(test) == 0 && T_study_rep{i,"AMPM"} == "PM"
        d = t(and(t.date == string(T_study_rep{i,"Date"}+day(1)),hour(t.started_at_pst)<4),:);
        test = d(d.AMPM == T_study_rep{i,"AMPM"},:);
    end
    a = 1;
    if height(test) == 0
        row = T_study_rep(i,:);
        row{1,"timestamp"} = nan;
        row{1,"problem_set"} = nan;
        row{1,'dif_level'} = nan;
        row{1,"answer"} = string(nan);
        row{1,"input"} = string(nan);
        row{1, 'strict_score'} = nan;
        row{1,'flex_score'} = nan;
        row{1, 'missing_error'} = nan;
        row{1, 'extra_letters'} = nan;
        row{1,"math_accuracy"} = nan;
        row{1,"missed_loc"} = {[]};
        row{1,"missed_num"} = nan;
        row{1,"math_incorrect_loc"} = {[]};
        row{1,"math_incorrect_num"} = nan;
        %row{1,"math_pass"} = 0;
        row{1,"math_accuracy0"} = nan;
        row{1,"answer_true"} = nan;
        row{1,"answer_false"} = nan;
        row{1,"answer_miss"} = nan;
        scores = vertcat(scores,row);
    end
    
    sitting = table;
    for k = 1:height(test)
        if length(char(test{k,'letters'}))>1
            sub = test(a:k,:);
            a = k + 1;
            answer = char(sub{end,'letters'});
            input = char(sub{end,'user_letters'});
            problem_set = sub{end, 'problem_set'};
            dif_level = length(answer);
            strict_score = 0;
            missing_error = 0;
            additional_error = 0;
            flex_score = 0;
            for l = 1:length(answer) %flex scoring
                if contains(string(input),string(answer(l)))
                    flex_score = flex_score + 1;
                end
            end
            additional_error = length(input) - flex_score; %additional error
            flex_score = flex_score / length(answer) * 100;
            missing_error = 100 - flex_score;
            if length(answer) > length(input) %equal the size of input for strict scoring
                d = length(answer) - length(input);
                for b = 1:d 
                    input = append(input,'/');
                end
            end
            for l = 1:length(answer) %strict scoring
                if answer(l) == input(l)
                    strict_score = strict_score + 1;
                end
            end
            strict_score = strict_score / length(answer) * 100;
           
            row = T_study_rep(i,:);
            row{1,"timestamp"} = sub.started_at(1);
            row{1,"problem_set"} = problem_set;
            row{1,'dif_level'} = dif_level;
            row{1,"answer"} = string(answer);
            row{1,"input"} = string(input);
            row{1, 'strict_score'} = strict_score;
            row{1,'flex_score'} = flex_score;
            row{1, 'missing_error'} = missing_error;
            row{1, 'extra_letters'} = additional_error;
            row{1,"math_accuracy"} = sum(contains(string(sub.user_is_correct(1:end-1)),"True"))/ length(answer);
            row{1,"missed_loc"} = {find(sub.choice == "missed")};
            row{1,"missed_num"} = length(find(sub.choice == "missed"));
            row{1,"math_incorrect_loc"} = {find(sub.user_is_correct == "False")};
            row{1,"math_incorrect_num"} = length(find(sub.user_is_correct == "False"));
            %row{1,"math_pass"} = 1;
            row{1,"math_accuracy0"} = sum(string(sub.user_is_correct) == "True")/length(answer)*100;
            row{1,"answer_true"} = sum(string(sub.choice) == "True")/length(answer)*100;
            row{1,"answer_false"} = sum(string(sub.choice) == "False")/length(answer)*100;
            row{1,"answer_miss"} = sum(string(sub.choice) == "missed")/length(answer)*100;

            sitting = vertcat(sitting,row);
        end
    end
    if height(sitting)>15
        stamps = unique(sitting.timestamp);
        for k = length(stamps)
            s = sitting(sitting.timestamp == stamps(k),:);
            unique_answer = unique(s.answer);
            ss = s(1:15,:);
            if all(ismember(unique_answer,ss.answer(1:15)))
                 scores = [scores;ss];
            else
                s
                ss
                return
            end
        end
    elseif height(sitting)~= 0
        scores = [scores;sitting];
    end
end
scores{:,"suspect_flag"} = 0;
scores{or(scores.answer_miss >=50,scores.math_accuracy0 <= 50),"suspect_flag"} = 1;
scores{:,"yes_skip"} = nan;
scores{scores.suspect_flag == 1,"yes_skip"} = scores{scores.suspect_flag == 1,"answer_true"}+scores{scores.suspect_flag == 1,"answer_miss"};
scores{:,"no_skip"} = nan;
scores{scores.suspect_flag == 1,"no_skip"} = scores{scores.suspect_flag == 1,"answer_false"}+scores{scores.suspect_flag == 1,"answer_miss"};
scores.check_value_n = -0.011.* scores.no_skip.^2 + 0.96.*scores.no_skip+23;
scores.check_value_y = -0.0094.* scores.yes_skip.^2 + 0.75.*scores.yes_skip+28;
scores{:,"flag_n"} = false;
scores{:,"flag_y"}  = false;
scores{scores.math_accuracy0 - scores.check_value_n <= 0,"flag_n"} = true;
scores{scores.math_accuracy0 - scores.check_value_y <= 0,"flag_y"}  = true;
scores{:,"flag_both"} = false;
scores{:,"flag_either"}  = false;
scores{and(scores.flag_n == true,scores.flag_y == true),"flag_both"} = true;
scores{or(scores.flag_n == true,scores.flag_y == true),"flag_either"} = true;
%no_count = scores(or(scores.flag_n == true,scores.flag_y == true),:);
a = scores;
copy = scores(isnan(scores.timestamp),:);

for i = 1:height(copy)
    sid = scores(scores.SID == copy{i,"SID"},:);
    if copy{i,"AMPM"} == "AM"
        t = sid(and(sid.AMPM == "PM",sid.Date == copy{i,"Date"}),:);
        if height(t) > 15
            t
            return
        end
    else
        am = sid(and(sid.AMPM == "AM",sid.Date == copy{i,"Date"}),:);
        pm = sid(and(sid.AMPM == "PM",sid.Date == copy{i,"Date"}+day(1)),:);
        if height(am)>15 
            scores = [scores;repelem(copy(i,1:find(matches(copy.Properties.VariableNames,"AMPM"))),15,1) am(am.timestamp == max(am.timestamp),find(matches(copy.Properties.VariableNames,"AMPM"))+1:end)];
            datetime(max(am.timestamp)/1000,'convertfrom','posixtime','timezone','local')
            return
        end
        if height(pm)>15
            pm
            return
        end
    end
end
per_day = table;
per_diff = table;
for i = 1:height(T_study_rep)
    t = scores(scores.SID == T_study_rep{i,"SID"},:); 
    d = t(string(t.Date) == string(T_study_rep{i,"Date"}),:);
    d = d(d.AMPM == T_study_rep{i,"AMPM"}, :);
    d(isnan(d.dif_level),:) = [];
    easy = d(d.dif_level <= 5,:);
    math_easy = 100 - sum(easy{:,"flag_both"})/(height(easy))*100;
    hard = d(d.dif_level >= 6,:);
    math_hard = 100 - sum(hard{:,"flag_both"})/(height(hard))*100;

    row_day = T_study_rep(i,:);
    row_day{end,'strict_ave'} = mean(d.strict_score);
    row_day{end,'strict_std'} = std(d.strict_score);
    row_day{end,'flex_ave'} = mean(d.flex_score);
    row_day{end,'flex_std'} = std(d.flex_score);
    row_day{end,'miss_err_ave'} = mean(d.missing_error);
    row_day{end,'miss_err_std'} = std(d.missing_error);
    row_day{end,'extra_let_ave'} = mean(d.extra_letters);
    row_day{end,'extra_let_std'} = std(d.extra_letters);
    per_day = vertcat(per_day,row_day);
    %level
    row_diff = T_study_rep(i,:);
    row_diff{end,'strict_ave_easy'} = mean(easy.strict_score);
    row_diff{end,'strict_std_easy'} = std(easy.strict_score);
    %row_diff{end,'strict_ave_easy_raw'} = mean(easy0.strict_score);
    %row_diff{end,'strict_std_easy_raw'} = std(easy0.strict_score);    
    row_diff{end,'flex_ave_easy'} = mean(easy.flex_score);
    row_diff{end,'flex_std_easy'} = std(easy.flex_score);
    row_diff{end,'miss_err_ave_easy'} = mean(easy.missing_error);
    row_diff{end,'miss_err_std_easy'} = std(easy.missing_error);
    row_diff{end,'add_err_ave_easy'} = mean(easy.extra_letters);
    row_diff{end,'add_err_std_easy'} = std(easy.extra_letters);
    row_diff{end,'strict_ave_hard'} = mean(hard.strict_score);
    row_diff{end,'strict_std_hard'} = std(hard.strict_score);
    %row_diff{end,'strict_ave_hard_raw'} = mean(hard0.strict_score);
    %row_diff{end,'strict_std_hard_raw'} = std(hard0.strict_score);
    row_diff{end,'flex_ave_hard'} = mean(hard.flex_score);
    row_diff{end,'flex_std_hard'} = std(hard.flex_score);
    row_diff{end,'miss_err_ave_hard'} = mean(hard.missing_error);
    row_diff{end,'miss_err_std_hard'} = std(hard.missing_error);
    row_diff{end,'add_err_ave_hard'} = mean(hard.extra_letters);
    row_diff{end,'add_err_std_hard'} = std(hard.extra_letters);
    row_diff{end,'math_effort_easy'} = math_easy;
    row_diff{end,'math_effort_hard'} = math_hard;
    %row_diff{end,"height"} = [height(d),height(easy),height(hard)];
    per_diff = vertcat(per_diff,row_diff);
end
b = per_diff;
c = per_day;
copy = c;
AM = copy(copy.AMPM == "AM",:);
PM = copy(copy.AMPM == "PM",:);
ind = find(matches(copy.Properties.VariableNames,"AMPM")) + 1;
for i = ind:width(copy)
    col = AM{:,i};
    col = col(~isnan(col));
    range = std(col)*3;
    u_bound = mean(col) + range;
    l_bound = mean(col) - range;
    col(or(col>u_bound,col<l_bound)) = nan;
    AM{~isnan(AM{:,i}),i} = col;
    col = PM{:,i};
    col = col(~isnan(col));
    range = std(col)*3;
    u_bound = mean(col) + range;
    l_bound = mean(col) - range;
    col(or(col>u_bound,col<l_bound)) = nan;
    PM{~isnan(PM{:,i}),i} = col;

end
copy(copy.AMPM == "AM",:) = AM;
copy(copy.AMPM == "PM",:) = PM;
c = copy;
copy = b;
AM = copy(copy.AMPM == "AM",:);
PM = copy(copy.AMPM == "PM",:);
ind = find(matches(copy.Properties.VariableNames,"AMPM")) + 1;
for i = ind:width(copy)
    col = AM{:,i};
    col = col(~isnan(col));
    range = std(col)*3;
    u_bound = mean(col) + range;
    l_bound = mean(col) - range;
    col(or(col>u_bound,col<l_bound)) = nan;
    AM{~isnan(AM{:,i}),i} = col;
    col = PM{:,i};
    col = col(~isnan(col));
    range = std(col)*3;
    u_bound = mean(col) + range;
    l_bound = mean(col) - range;
    col(or(col>u_bound,col<l_bound)) = nan;
    PM{~isnan(PM{:,i}),i} = col;
end
copy(copy.AMPM == "AM",:) = AM;
copy(copy.AMPM == "PM",:) = PM;
missing = copy(and(or(and(copy.Day == 1,copy.AMPM == "PM"),and(copy.Day == 8, copy.AMPM == "AM")),isnan(copy.strict_ave_easy)),:);
for i = 1:height(missing)
    fill = copy(and(copy.SID == missing{i,"SID"},and(copy.Day == missing{i,"Day"},copy.AMPM ~= missing{i,"AMPM"})),:);
    missing(i,find(matches(missing.Properties.VariableNames,"strict_ave_easy")):end) = fill(1,find(matches(missing.Properties.VariableNames,"strict_ave_easy")):end);
end
copy(and(or(and(copy.Day == 1,copy.AMPM == "PM"),and(copy.Day == 8, copy.AMPM == "AM")),isnan(copy.strict_ave_easy)),:) = missing;
b = copy;
per_diff = b;
%per_diff(isnat(per_diff.Date),:) = [];
SID = unique(per_diff.SID);
wide_AMPM = table;
for i = 1:length(SID)
    t = per_diff(per_diff.SID == SID(i),:);
    weeks = unique(t.StudyWeek);
    weeks(isnan(weeks)) = [];
    for j = 1:length(weeks)
        sw = t(t.StudyWeek == weeks(j),:);
        am = sw(sw.AMPM == "AM",:);
        pm = sw(sw.AMPM == "PM",:);
        if height(am) > 8 || height(pm) > 8
            am = am(1:8,:);
            pm = pm(1:8,:);
        %elseif height(am) == 0
           % am = 
        end
        row_am = am(1,["SID","StudyWeek","AMPM"]);
        row_pm = pm(1,["SID","StudyWeek","AMPM"]);
        for k = 1:8
            r = am(k,width(T_study)+2:end); 
            col_names = r.Properties.VariableNames;
            r_0 = pm(k,width(T_study)+2:end); 
            col_names_0 = r_0.Properties.VariableNames;
            for l = 1:length(col_names)
                col_names{l} = append(col_names{l},'_',string(k));
                col_names_0{l} = append(col_names_0{l},'_',string(k));
            end
            r = renamevars(r,r.Properties.VariableNames,string(col_names));
            row_am = horzcat(row_am,r);
            r_0 = renamevars(r_0,r_0.Properties.VariableNames,string(col_names));
            row_pm = horzcat(row_pm,r_0);
        end
        wide_AMPM = vertcat(wide_AMPM,row_am,row_pm);
    end
end
d = wide_AMPM;
copy = wide_AMPM;
AM = copy(copy.AMPM == "AM",:);
PM = copy(copy.AMPM == "PM",:);
missing = PM(isnan(PM{:,4}),:);
missing{:,contains(missing.Properties.VariableNames,"_1")} = AM{isnan(PM{:,4}),contains(missing.Properties.VariableNames,"_1")};
PM(isnan(PM{:,4}),:) = missing;
missing = AM(isnan(AM{:,end}),:);
missing{:,contains(missing.Properties.VariableNames,"_8")} = PM{isnan(AM{:,end}),contains(missing.Properties.VariableNames,"_8")};
AM(isnan(AM{:,end}),:) = missing;
copy(copy.AMPM == "AM",:) = AM;
copy(copy.AMPM == "PM",:) = PM;
wide_AMPM = copy;
d = wide_AMPM;
SID = unique(copy.SID);
wide = table;
for i = 1:length(SID)
    t = copy(copy.SID == SID(i),:);
    sw = unique(t.StudyWeek);
    for j = 1:length(sw)
        t_w = t(t.StudyWeek == sw(j),:);
        am = t_w(t_w.AMPM == "AM",4:end);
        pm = t_w(t_w.AMPM == "PM",4:end);
        row = t_w(1,["SID","StudyWeek"]);
        col_names = am.Properties.VariableNames;
        am_cols = col_names;
        pm_cols = col_names;
        for k = 1:length(col_names)
            am_cols{k} = append(col_names{k},"_AM");
            pm_cols{k} = append(col_names{k},"_PM");
        end
        am = renamevars(am,col_names,string(am_cols));
        pm = renamevars(pm,col_names,string(pm_cols));
        row = horzcat(row,am,pm);
        wide = vertcat(wide,row);
    end
end
e = wide;
copy = e;
copy(:,contains(copy.Properties.VariableNames,["_1_AM","_8_PM"])) = [];
col_names = copy.Properties.VariableNames(3:end);
num_pat = extract(col_names,digitsPattern);
uniq_num = unique(num_pat);
reorder = copy(:,1:2);
for i = 1:length(uniq_num)
    reorder = horzcat(reorder,copy(:,col_names(string(num_pat) == uniq_num(i))));
end
e = reorder;
copy = b;
%copy(isnat(copy.Date),:) = [];
user = unique(copy.SID);
OSPAN_diff = table;
for i = 1:length(user)
    t = copy(copy.SID == user(i),:);
    w = unique(t.StudyWeek);
    for j = 1:length(w)
        t_w = t(t.StudyWeek == w(j),:);
        t_w([1,end],:) = [];
        row = table;
        row{end+1,"user"} = user(i);
        row{end,"StudyWeek"} = w(j);
        k = 1;
        n = 1;
        while k < height(t_w)
            pair = t_w(k:k+1,width(T_study)+2:end);
            p_diff = pair(end,:) - pair(end-1,:);
            col_names = string(p_diff.Properties.VariableNames);
            for l = 1:length(col_names)
                col_names(l) = append(col_names(l),"_Ov_perf_Night",string(n));
            end
            p_diff = renamevars(p_diff,p_diff.Properties.VariableNames,col_names);
            n = n+1;
            k = k+2;
            row = horzcat(row,p_diff);
        end
        OSPAN_diff = vertcat(OSPAN_diff,row);
    end
end
f = OSPAN_diff;
a(isnat(a.Date),:) = [];
b(isnat(b.Date),:) = [];
c(isnat(c.Date),:) = [];
if ~exist(append(file_path,'\output\cog_tasks\OSPAN\'))
    mkdir(append(file_path,'\output\cog_tasks\OSPAN\'))
end

b.Date = month(b.Date,'long');
b(:,["Blurghbo","Burst_Day_"]) = [];
c(or(and(c.Day == 1,c.AMPM == "AM"),and(c.Day == 8,c.AMPM == "PM")),:) = [];
b(or(and(b.Day == 1,b.AMPM == "AM"),and(b.Day == 8,b.AMPM == "PM")),:) = [];
writetable(c,append(file_path,'\Cog_Tasks\postprocessed\OSPAN\OSPAN_long.xlsx'));
writetable(e,append(file_path,'\Cog_Tasks\postprocessed\OSPAN\OSPAN_wide.xlsx'));
writetable(a,append(file_path,'\Cog_Tasks\postprocessed\OSPAN\OSPAN_scores.xlsx'));
writetable(b,append(file_path,'\Cog_Tasks\postprocessed\OSPAN\OSPAN_difficulties.xlsx'));
writetable(b,append(file_path,'\Cog_Tasks\Cogtask data.xlsx'),'sheet','OSPAN');
writetable(b,append(file_path,'K08 master data.xlsx'),'sheet','OSPAN');
save(append(file_path,'\Cog_Tasks\postprocessed\OSPAN\OSPAN_scores.mat'),"a");
save(append(file_path,'\Cog_Tasks\postprocessed\OSPAN\OSPAN_difficulties.mat'),"b");
writetable(d,append(file_path,'\Cog_Tasks\postprocessed\OSPAN\OSPAN_wide_AMPM.xlsx'));
writetable(f,append(file_path,'\Cog_Tasks\postprocessed\OSPAN\OSPAN_summary.xlsx'));
%writetable(no_count,append(file_path,'\Cog_Tasks\postprocessed\OSPAN\OSPAN_excluded.xlsx'));
end