T = readtable('C:\Users\230Student01\Desktop\ospan\OSPAN_preprocessed (1).csv'); %import csv using file path to raw csv file
not_need = {'id', 'user_id'};
T(:,not_need) = [];%eliminate columns that are not needed
T.problem_set = string(T.problem_set);
session = unique(T.problem_set);%divided into session
T.user = string(T.user);
user = unique(T.user); %recognizing different user
date_time = datetime(T.started_at ./ 1000,'convertfrom','posixtime','TimeZone','America/Los_Angeles', 'Format','dd-MMM-yyyy HH:mm:ss'); %convert unixstamp into PST
T.time = timeofday(date_time);
date_time.Format = 'yyyy-MM-dd';
date_time =string(date_time);
T.date = datetime(date_time);
user = 
%%
user()
t =T(T.user == user(5), :);
a = 1;
day = unique(t.date)
%%
%main code
score = table;
columns = {'user','SW', 'date','time', 'AM/PM','dif_level', 'strict_score', 'flex_score','missing_error', 'additional_error','problem_set'};
for i = 1:length(user) %first round of preprosessing
    t = T(T.user == user(i), :);
    a = 1;
    day = unique(t.date);%assigning SWs
    w = 1;
    if length(day) < 8
        for j = 1:length(day)
            t{t.date == day(j),'SW'} = w;
        end
    else 
        for j = 1:length(day)
            if sum(contains(string(day),string(day(j) + days(0:7)))) == 8
                week = day(j) + days(0:7);
                for k = 1:length(week);
                    t{t.date == week(k),'SW'} = w;
                end
                w = w + 1;
            end
        end
    end
    t = sortrows(t,"date","ascend");
    for j = 1:height(t) %separaing per each letters
        if length(t{j,'letters'}{1})>1
            sub = t(a:j,:);
            a = j + 1;
            if hours(sub{1,'time'}) < 12 %distinguishing AM and PM
                AMPM  = "AM";
            else
                AMPM = "PM";
            end
            answer = sub{end,'letters'}{1};
            input = sub{end,'user_letters'}{1};
            dif_level = length(answer);
            strict_score = 0;
            missing_error = 0;
            additional_error = 0;
            flex_score = 0;
            for k = 1:length(answer) %flex scoring
                if contains(string(input),string(answer(k)))
                    flex_score = flex_score + 1;
                end
            end
            additional_error = length(input) - flex_score; %additional error
            flex_score = flex_score / length(answer) * 100;
            missing_error = 100 - flex_score;
            if length(answer) > length(input) %equal the size of input for strict scoring
                d = length(answer) - length(input);
                for k = 1:d 
                    input = append(input,'/');
                end
            end
            for k = 1:length(answer) %strict scoring
                if answer(k) == input(k)
                    strict_score = strict_score + 1;
                end
            end
            strict_score = strict_score / length(answer) * 100;
            if sum(contains(string(sub.user_is_correct(1:end-1)),"True"))/ length(answer) > 0.5 %counts only if the math eqs accuracy is over 50%
                row = {user(i),sub{1,'SW'},sub{1,'date'},sub{1,'time'}, AMPM, dif_level, strict_score, flex_score, missing_error, additional_error,sub.problem_set(1)};
                score = vertcat(score, row);
            end
        end

    end
end
score.Properties.VariableNames = columns;
%data summary table
summary_dif_level = table;
summary_SW = table;
summary_day = table;
summary_prb_set = table;
columns_1 = {'user','dif_level','strict_ave','strict_std','flex_ave','flex_std','miss_err_ave','miss_err_std','add_err_ave','add_err_std'};
columns_2 = {'user','SW','strict_ave','strict_std','flex_ave','flex_std','miss_err_ave','miss_err_std','add_err_ave','add_err_std'};
columns_3 = {'user','study_day','strict_ave','strict_std','flex_ave','flex_std','miss_err_ave','miss_err_std','add_err_ave','add_err_std'};
columns_4 = {'user','problem_set','strict_ave','strict_std','flex_ave','flex_std','miss_err_ave','miss_err_std','add_err_ave','add_err_std'};
for i = 1:length(user)
    t = score(score.user == user(i),:);
    user_summary_1 = table;
%score summary per level
    dif = unique(t.dif_level);
    for j = 1:length(dif)
        level = t(t.dif_level == dif(j), :);
        strict_ave = mean(level.strict_score);
        strict_std = std(level.strict_score);
        flex_ave = mean(level.flex_score);
        flex_std = std(level.flex_score);
        miss_err_ave = mean(level.missing_error);
        miss_err_std = std(level.missing_error);
        add_err_ave = mean(level.additional_error);
        add_err_std = std(level.additional_error);
        row = {user(i),dif(j),strict_ave,strict_std,flex_ave,flex_std,miss_err_ave,miss_err_std,add_err_ave,add_err_std};
        user_summary_1 = vertcat(user_summary_1, row);
    end
    user_summary_1.Properties.VariableNames = columns_1;
    user_summary_1 = sortrows(user_summary_1,"dif_level","ascend");
    summary_dif_level = vertcat(summary_dif_level, user_summary_1);
%score per SW
    user_summary_2 = table;
    SW = unique(t.SW);
    for j = 1:length(SW)
        week = t(t.SW == SW(j), :);
        strict_ave = mean(week.strict_score);
        strict_std = std(week.strict_score);
        flex_ave = mean(week.flex_score);
        flex_std = std(week.flex_score);
        miss_err_ave = mean(week.missing_error);
        miss_err_std = std(week.missing_error);
        add_err_ave = mean(week.additional_error);
        add_err_std = std(week.additional_error);
        row = {user(i),SW(j),strict_ave,strict_std,flex_ave,flex_std,miss_err_ave,miss_err_std,add_err_ave,add_err_std};
        user_summary_2 = vertcat(user_summary_2, row);
    end
    user_summary_2.Properties.VariableNames = columns_2;
    user_summary_2 = sortrows(user_summary_2,"SW","ascend");
    summary_SW = vertcat(summary_SW, user_summary_2);
%score per day
    user_summary_3 = table;
    day = unique(t.date);
    for j = 1:length(day)
        study_day = t(t.date == day(j), :);
        strict_ave = mean(study_day.strict_score);
        strict_std = std(study_day.strict_score);
        flex_ave = mean(study_day.flex_score);
        flex_std = std(study_day.flex_score);
        miss_err_ave = mean(study_day.missing_error);
        miss_err_std = std(study_day.missing_error);
        add_err_ave = mean(study_day.additional_error);
        add_err_std = std(study_day.additional_error);
        row = {user(i),string(day(j)),strict_ave,strict_std,flex_ave,flex_std,miss_err_ave,miss_err_std,add_err_ave,add_err_std};
        user_summary_3 = vertcat(user_summary_3, row);
    end
    user_summary_3.Properties.VariableNames = columns_3;
    user_summary_3.study_day = datetime(user_summary_3.study_day);
    user_summary_3 = sortrows(user_summary_3,"study_day","ascend");
    summary_day = vertcat(summary_day, user_summary_3);
%per problem set
    user_summary_4 = table;
    prb_set = unique(t.problem_set);
    for j = 1:length(prb_set)
        set = t(t.problem_set == prb_set(j), :);
        strict_ave = mean(set.strict_score);
        strict_std = std(set.strict_score);
        flex_ave = mean(set.flex_score);
        flex_std = std(set.flex_score);
        miss_err_ave = mean(set.missing_error);
        miss_err_std = std(set.missing_error);
        add_err_ave = mean(set.additional_error);
        add_err_std = std(set.additional_error);
        row = {user(i),prb_set(j),strict_ave,strict_std,flex_ave,flex_std,miss_err_ave,miss_err_std,add_err_ave,add_err_std};
        user_summary_4 = vertcat(user_summary_4, row);
    end
    user_summary_4.Properties.VariableNames = columns_4;
    user_summary_4 = sortrows(user_summary_4,"problem_set","ascend");
    summary_prb_set = vertcat(summary_prb_set, user_summary_4);
end

%exporting to csv file
directory = 'C:\Users\230Student01\Desktop\ospan';
tables = {score, summary_dif_level, summary_SW, summary_day, summary_prb_set}
filenames= {'ospan_scores.csv','ospan_summary_dif_level.csv','ospan_summary_SW.csv','ospan_summary_day.csv','ospan_summary_problem_set.cev'};
for i = 1:length(filenames)
    path  = fullfile(directory,filenames{i});
    writetable(tables{i},path);

    
end