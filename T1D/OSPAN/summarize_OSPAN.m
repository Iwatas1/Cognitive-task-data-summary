function [a,b,c,e,f] = summarize_OSPAN(OSPAN,study_cog,file_path)
T = OSPAN;
T.problem_set = string(T.problem_set);
T.started_at_pst = datetime(T.started_at ./ 1000,'convertfrom','posixtime','TimeZone','America/Los_Angeles', 'Format','dd-MMM-yyyy HH:mm:ss'); %convert unixstamp into PST
T.time = timeofday(T.started_at_pst);
study_cog.SID = string(study_cog.SID);
user = unique(study_cog.SID);%recognizing different user
hours = hour(T.started_at_pst);
T{hours < 15,"AMPM"} = "AM"; %change accordingly
T{hours >= 15,"AMPM"} = "PM";
T.date = string(datetime(T.started_at_pst,"Format","dd-MMM-uuuu"));
T.letters = string(T.letters);
T.letter = string(T.letter);
T.user_letters = string(T.user_letters);
scores = table;
for i = 1:height(study_cog)   
    t = T(T.user == study_cog{i,"SID"},:);
    d = t(t.date == string(study_cog{i,"Date"}),:);
    test = d(d.AMPM == study_cog{i,"AMPM"},:);
    a = 1;
    if height(test) == 0
        row = study_cog(i,:);
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
           
            row = study_cog(i,:);
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
for i = 1:height(study_cog)
    t = scores(scores.SID == study_cog{i,"SID"},:); 
    d = t(string(t.Date) == string(study_cog{i,"Date"}),:);
    d = d(d.AMPM == study_cog{i,"AMPM"}, :);
    d(isnan(d.dif_level),:) = [];
    easy = d(d.dif_level <= 5,:);
    math_easy = 100 - sum(easy{:,"flag_both"})/(height(easy))*100;
    hard = d(d.dif_level >= 6,:);
    math_hard = 100 - sum(hard{:,"flag_both"})/(height(hard))*100;

    row_day = study_cog(i,:);
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
    row_diff = study_cog(i,:);
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
b = copy;
per_diff = b;
session = copy.AMPM;
session(or(and(copy.Sleep_Wake_condition == 1,session == "PM"),and(copy.Sleep_Wake_condition == 0,session == "AM"))) = "S1";
session(session~="S1") = "S2";
copy.AMPM = session;
b = renamevars(copy,"AMPM","Session");

copy = b;
SID = unique(copy.SID);
swc = unique(copy.Sleep_Wake_condition);
ampm = unique(copy.Session);
copy(:,contains(copy.Properties.VariableNames,["Week","Date","Day","day"])) = [];
ind = find(matches(copy.Properties.VariableNames,"Session"))+1;
wide = table;
for i = 1:length(SID)
    t = copy(copy.SID == SID(i),:);
    for j = 1:length(swc)
        t_c = t(t.Sleep_Wake_condition == swc(j),:);
        row = t_c(1,1:ind - 2);
        for k = 1:length(ampm)
            t_ampm = t_c(t_c.Session == ampm(k),:);
            col_names = string(t_ampm.Properties.VariableNames(ind:end));
            if ampm(k) == "S1"
                for l = 1:length(col_names)
                    col_names(l) = append(col_names(l),"_S1");
                end
            else
                for l = 1:length(col_names)
                    col_names(l) = append(col_names(l),"_S2");
                end
            end
            t_ampm = renamevars(t_ampm,t_ampm.Properties.VariableNames(ind:end),col_names);
            row = [row t_ampm(1,ind:end)];
        end
        wide = [wide;row];
    end
end
e = wide;
OVN = table;
for i = 1:length(SID)
    t = copy(copy.SID == SID(i),:);
    for j = 1:length(swc)
        t_c = t(t.Sleep_Wake_condition == swc(j),:);
        row = t_c(1,1:ind-2);
        am = t_c(t_c.Session == "S1",ind:end);
        pm = t_c(t_c.Session == "S2",ind:end);
        dif = pm - am;
        row = [row dif];
        OVN = [OVN ; row];
    end
end
OVN(:,contains(OVN.Properties.VariableNames,"std")) = [];
col_names = string(OVN.Properties.VariableNames(ind:end));
for i = 1:length(col_names)
    col_names(i) = append(col_names(i),"_Ov_perf_diff");
end
OVN = renamevars(OVN,OVN.Properties.VariableNames(ind:end),col_names);
f = OVN;

if ~exist(append(file_path,'\Cog_Tasks\postprocessed\OSPAN\'),'dir')
    mkdir(append(file_path,'\Cog_Tasks\postprocessed\OSPAN\'))
end

b.Date = month(b.Date,'long');
b(:,["Blurghbo","Burst_Day_"]) = [];
writetable(c,append(file_path,'\Cog_Tasks\postprocessed\OSPAN\OSPAN_long.xlsx'));
writetable(e,append(file_path,'\Cog_Tasks\postprocessed\OSPAN\OSPAN_wide.xlsx'));
writetable(a,append(file_path,'\Cog_Tasks\postprocessed\OSPAN\OSPAN_scores.xlsx'));
writetable(b,append(file_path,'\Cog_Tasks\postprocessed\OSPAN\OSPAN_difficulties.xlsx'));
writetable(b,append(file_path,'\Cog_Tasks\Cogtask data.xlsx'),'sheet','OSPAN');
writetable(b,append(file_path,'\T1D master data.xlsx'),'sheet','OSPAN');
save(append(file_path,'\Cog_Tasks\postprocessed\OSPAN\OSPAN_scores.mat'),"a");
save(append(file_path,'\Cog_Tasks\postprocessed\OSPAN\OSPAN_difficulties.mat'),"b");
writetable(f,append(file_path,'\Cog_Tasks\postprocessed\OSPAN\OSPAN_overnight.xlsx'));

end