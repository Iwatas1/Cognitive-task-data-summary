T = readtable('OSPAN_preprocessed _yeh.csv');
T_study = readtable("K08_StudySheet_032524.xlsx"); %import csv using file path to raw csv file
not_need = {'id', 'user_id'};
T(:,not_need) = [];%eliminate columns that are not needed
T.problem_set = string(T.problem_set);
session = unique(T.problem_set);%divided into session
T.user = string(T.user);
user = unique(T.user); %recognizing different user
T.started_at_pst = datetime(T.started_at ./ 1000,'convertfrom','posixtime','TimeZone','America/Los_Angeles', 'Format','dd-MMM-yyyy HH:mm:ss'); %convert unixstamp into PST
T.time = timeofday(T.started_at_pst);
for i = 1:length(T.user)
    c = char(T.user(i));
    T.user(i) = string(c(end-2:end));
end
T_study.SID = string(T_study.SID);
user = unique(T.user);
%{
user = erase(user,["124", "125","126","127"]); only for k08
for i = 1:4
    user(17) = [];
end
%}
hours = hour(T.started_at_pst);
T.date = string(datetime(T.started_at_pst,"Format","dd-MMM-uuuu"));
%%
%for yeh
warning('off', 'all')
scores = table;
for i = 1:length(user)
    user_summary = table;
    t = T(T.user == user(i),:);
    days = unique(t.date);
    a = 1;
    for j = 1:length(days)
        day = t(t.date == days(j),:);
        for k = 1:height(day)
            a = 1;
            if length(day{k,'letters'}{1})>1
                sub = day(a:k,:);
                a = k + 1;
                answer = sub{end,'letters'}{1};
                input = sub{end,'user_letters'}{1};
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
                if sum(contains(string(sub.user_is_correct(1:end-1)),"True"))/ length(answer) > 0.5 %counts only if the math eqs accuracy is over 50%
                    row = table;
                    row{1,'user'} = user(i);
                    row{1,"date"} = days(j);
                    row{1,"problem_set"} = problem_set;
                    row{1,'dif_level'} = dif_level;
                    row{1, 'strict_score'} = strict_score;
                    row{1,'flex_score'} = flex_score;
                    row{1, 'missing_error'} = missing_error;
                    row{1, 'additional_error'} = additional_error;
                    scores = vertcat(scores,row);
                end
            end
        end
    end

end
scores;
per_day = table;
per_level = table;
for i = 1:length(user)
    user_summary = table;
    user_summary_1 = table;
    t = scores(scores.user == user(i), :);
    days = unique(t.date);
    user_summary.user = repelem(user(i), length(days),1);
    user_summary_1.user = repelem(user(i), length(days),1);
    for j = 1:length(days)
        day = t(t.date == days(j), :);
        user_summary{j,"date"} = days(j);
        user_summary_1{j,"date"} = days(j);
        easy = day(day.dif_level == 4,:);
        easy = vertcat(easy, day(day.dif_level == 5, :));
        hard = day(day.dif_level == 7,:);
        hard = vertcat(easy, day(day.dif_level == 8, :));
        user_summary{j,'strict_ave'} = mean(day.strict_score);
        user_summary{j,'strict_std'} = std(day.strict_score);
        user_summary{j,'flex_ave'} = mean(day.flex_score);
        user_summary{j,'flex_std'} = std(day.flex_score);
        user_summary{j,'miss_err_ave'} = mean(day.missing_error);
        user_summary{j,'miss_err_std'} = std(day.missing_error);
        user_summary{j,'add_err_ave'} = mean(day.additional_error);
        user_summary{j,'add_err_std'} = std(day.additional_error);
        %level
        user_summary_1{j,'strict_ave_easy'} = mean(easy.strict_score);
        user_summary_1{j,'strict_std_easy'} = std(easy.strict_score);
        user_summary_1{j,'flex_ave_easy'} = mean(easy.flex_score);
        user_summary_1{j,'flex_std_easy'} = std(easy.flex_score);
        user_summary_1{j,'miss_err_ave_easy'} = mean(easy.missing_error);
        user_summary_1{j,'miss_err_std_easy'} = std(easy.missing_error);
        user_summary_1{j,'add_err_ave_easy'} = mean(easy.additional_error);
        user_summary_1{j,'add_err_std_easy'} = std(easy.additional_error);
        user_summary_1{j,'strict_ave_hard'} = mean(hard.strict_score);
        user_summary_1{j,'strict_std_hard'} = std(hard.strict_score);
        user_summary_1{j,'flex_ave_hard'} = mean(hard.flex_score);
        user_summary_1{j,'flex_std_hard'} = std(hard.flex_score);
        user_summary_1{j,'miss_err_ave_hard'} = mean(hard.missing_error);
        user_summary_1{j,'miss_err_std_hard'} = std(hard.missing_error);
        user_summary_1{j,'add_err_ave_hard'} = mean(hard.additional_error);
        user_summary_1{j,'add_err_std_hard'} = std(hard.additional_error);
    end
    per_day = vertcat(per_day,user_summary);
    per_level = vertcat(per_level, user_summary_1);
end
per_day;
per_level;
%%
wide = table;
for i = 1:length(user)
    user_summary = table;
    t = per_level(per_level.user == user(i),:);
    days = unique(t.date);
    user_summary{1,"user"} = user(i);
    for j = 1:length(days)
        day = t(t.date == days(j),:);
        name = append('strict_ave_easy_',string(j));
        user_summary{1, name} = day{1, "strict_ave_easy"};
        name = append("strict_ave_hard_",string(j));
        user_summary{1, name} = day{1,"strict_ave_hard"};
        name = append("flex_ave_easy_",string(j));
        user_summary{1, name} = day{1,"flex_ave_easy"};
        name = append("flex_ave_hard_",string(j));
        user_summary{1, name} = day{1,"flex_ave_hard"};
    end

    if width(user_summary) > width(wide) && i ~= 1
        mis = setdiff(user_summary.Properties.VariableNames,wide.Properties.VariableNames);
        for j = 1:length(mis)
            wide{:,mis{j}} = nan(height(wide),1);
        end
    elseif width(user_summary) < width(wide)
        mis = setdiff(wide.Properties.VariableNames,user_summary.Properties.VariableNames);
        for j = 1:length(mis)
            user_summary{1,mis{j}} = nan;
        end
    end
    wide = vertcat(wide,user_summary);
end
wide;
col_names = ["user"];
for i = 1:(width(wide)-1)/4
    col_names(end + 1) = append('strict_ave_easy_',string(i));
    col_names(end + 1) = append("strict_ave_hard_",string(i));
    col_names(end + 1) = append("flex_ave_easy_",string(i));
    col_names(end + 1) = append("flex_ave_hard_",string(i));
end
wide = wide(:,col_names);
%%
writetable(wide,"C:\Users\230Student01\Desktop\ospan\ospan_wide_yeh.csv" )
writetable(scores, "C:\Users\230Student01\Desktop\ospan\ospan_long_yeh.csv")
writetable(per_day, "C:\Users\230Student01\Desktop\ospan\ospan_per_day_yeh.csv")
writetable(per_level, "C:\Users\230Student01\Desktop\ospan\ospan_per_level_yeh.csv")

%%
%for k08
scores = table;
for i = 1:length(user)
    user_summary = table;
    user_initial = table;
    t = T(T.user == user(i), :);
    study = T_study(T_study.SID == user(i),:);
    user_initial = study;
    a = 1;
    for j = 1:height(user_initial)
        user_summary(a, :) =  user_initial(j,:);
        a = a + 1;
        user_summary(a, :) =  user_initial(j,:);
        a = a + 1;
    end
    for j = 1:height(user_summary)
        if mod(j,2) == 1
            user_summary{j, "AMPM"} = "AM";
        else
            user_summary{j, "AMPM"} = "PM";
        end
        date = string(user_summary{j,"Date"}); 
        day = t(t.date == date,:);
        if user_summary{j, "AMPM"} == "AM"
            day = day(hour(day.started_at_pst)<12,:);
        else
            day = day(hour(day.started_at_pst) >= 12, :);
        end
        if height(day) == 0
            row = user_summary(j,:);
            row{1,"problem_set"} = nan;
            row{1,'dif_level'} = nan;
            row{1, 'strict_score'} = nan;
            row{1,'flex_score'} = nan;
            row{1, 'missing_error'} = nan;
            row{1, 'additional_error'} = nan;
            scores = vertcat(scores,row);
        end

        a = 1;
        for k = 1:height(day)
            if length(day{k,'letters'}{1})>1
                sub = day(a:k,:);
                a = k + 1;
                answer = sub{end,'letters'}{1};
                input = sub{end,'user_letters'}{1};
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
                if sum(contains(string(sub.user_is_correct(1:end-1)),"True"))/ length(answer) > 0.5 %counts only if the math eqs accuracy is over 50%
                    row = user_summary(j,:);
                    row{1,"problem_set"} = problem_set;
                    row{1,'dif_level'} = dif_level;
                    row{1, 'strict_score'} = strict_score;
                    row{1,'flex_score'} = flex_score;
                    row{1, 'missing_error'} = missing_error;
                    row{1, 'additional_error'} = additional_error;
                    scores = vertcat(scores,row);
                end
            end
        end
    end
end
per_day = table;
per_level = table;
for i = 1:length(user)
    user_summary = table;
    user_summary_1 = table;
    t = scores(scores.SID == user(i), :);
    t.Date = string(t.Date);
    study = T_study(T_study.SID == user(i), :);
    user_initial = study;
    a = 1;
    for j = 1:height(user_initial)
        user_summary(a, :) =  user_initial(j,:);
        user_summary_1(a, :) =  user_initial(j,:);
        a = a + 1;
        user_summary(a, :) =  user_initial(j,:);
        user_summary_1(a, :) =  user_initial(j,:);
        a = a + 1;
    end
    for j = 1:height(user_summary)
        if mod(j,2) == 1
            user_summary{j, "AMPM"} = "AM";
            user_summary_1{j, "AMPM"} = "AM";
        else
            user_summary{j, "AMPM"} = "PM";
            user_summary_1{j, "AMPM"} = "PM";
        end
        date = string(user_summary{j,"Date"}); 
        day = t(t.Date == date,:);
        day = day(day.AMPM == user_summary{j, "AMPM"}, :);
        easy = day(day.dif_level == 4,:);
        easy = vertcat(easy, day(day.dif_level == 5, :));
        hard = day(day.dif_level == 7,:);
        hard = vertcat(easy, day(day.dif_level == 8, :));
        user_summary{j,'strict_ave'} = mean(day.strict_score);
        user_summary{j,'strict_std'} = std(day.strict_score);
        user_summary{j,'flex_ave'} = mean(day.flex_score);
        user_summary{j,'flex_std'} = std(day.flex_score);
        user_summary{j,'miss_err_ave'} = mean(day.missing_error);
        user_summary{j,'miss_err_std'} = std(day.missing_error);
        user_summary{j,'add_err_ave'} = mean(day.additional_error);
        user_summary{j,'add_err_std'} = std(day.additional_error);
        %level
        user_summary_1{j,'strict_ave_easy'} = mean(easy.strict_score);
        user_summary_1{j,'strict_std_easy'} = std(easy.strict_score);
        user_summary_1{j,'flex_ave_easy'} = mean(easy.flex_score);
        user_summary_1{j,'flex_std_easy'} = std(easy.flex_score);
        user_summary_1{j,'miss_err_ave_easy'} = mean(easy.missing_error);
        user_summary_1{j,'miss_err_std_easy'} = std(easy.missing_error);
        user_summary_1{j,'add_err_ave_easy'} = mean(easy.additional_error);
        user_summary_1{j,'add_err_std_easy'} = std(easy.additional_error);
        user_summary_1{j,'strict_ave_hard'} = mean(hard.strict_score);
        user_summary_1{j,'strict_std_hard'} = std(hard.strict_score);
        user_summary_1{j,'flex_ave_hard'} = mean(hard.flex_score);
        user_summary_1{j,'flex_std_hard'} = std(hard.flex_score);
        user_summary_1{j,'miss_err_ave_hard'} = mean(hard.missing_error);
        user_summary_1{j,'miss_err_std_hard'} = std(hard.missing_error);
        user_summary_1{j,'add_err_ave_hard'} = mean(hard.additional_error);
        user_summary_1{j,'add_err_std_hard'} = std(hard.additional_error);
    end
    per_day = vertcat(per_day,user_summary);
    per_level = vertcat(per_level, user_summary_1);
end
long = table;
for i = 1:length(user)
    t = per_level(per_level.SID == user(i),:);
    SW = unique(t.StudyWeek);
    for j = 1:length(SW)
        sw = t(t.StudyWeek == SW(j),:);
        long{end+1,"SID"} = user(i);
        long{end, "SW"} = SW(j);
        days = unique(sw.Day);
        for k = 1:length(days)
            day = sw(sw.Day == k,:);
            s_e = append("strict_ave_easy_", string(k));
            s_h = append("strict_ave_hard_", string(k));
            f_e = append("flex_ave_easy_", string(k));
            f_h = append("flex_ave_hard_", string(k));
            AMPM = unique(day.AMPM);
            for l = 1:length(AMPM)
                time = day(day.AMPM == AMPM(l), :);
                s_e_t = append(s_e, '_', AMPM(l));
                s_h_t = append(s_h, '_', AMPM(l));
                f_e_t = append(f_e, '_', AMPM(l));
                f_h_t = append(f_h, '_', AMPM(l));
                long{end, s_e_t} = time{1,"strict_ave_easy"};
                long{end, s_h_t} = time{1, "strict_ave_hard"};
                long{end, f_e_t} = time{1,"flex_ave_easy"};
                long{end, f_h_t} = time{1, "flex_ave_hard"};
            end
        end
    end
end
dif = table;
AMPM = ["AM", "PM"];
for i = 1:height(long)
    dif{end+1, 1:2} = long{i, 1:2};
    for j = 1:7
        strict_easy = append("dif_", string(j+1), "_strict_easy");
        strict_hard = append("dif_", string(j+1), "_strict_hard");
        AM_easy = append("strict_ave_easy_",string(j+1), "_AM");
        PM_easy = append("strict_ave_easy_",string(j), "_PM");
        AM_hard = append("strict_ave_hard_",string(j+1), "_AM");
        PM_hard = append("strict_ave_hard_",string(j), "_PM");
        dif{end, strict_easy} = long{i,AM_easy} - long{i,PM_easy};
        dif{end, strict_hard} = long{i,AM_hard} - long{i,PM_hard};
        flex_easy = append("dif_", string(j+1), "_flex_easy");
        flex_hard = append("dif_", string(j+1), "_flex_hard");
        AM_easy = append("flex_ave_easy_",string(j+1), "_AM");
        PM_easy = append("flex_ave_easy_",string(j), "_PM");
        AM_hard = append("flex_ave_hard_",string(j+1), "_AM");
        PM_hard = append("flex_ave_hard_",string(j), "_PM");
        dif{end, flex_easy} = long{i,AM_easy} - long{i,PM_easy};
        dif{end, flex_hard} = long{i,AM_hard} - long{i,PM_hard};
    end
end
dif = renamevars(dif, ["Var1", "Var2"], ["SID", "SW"])
dif.SW = str2double(dif.SW)

%%
writetable(dif, "C:\Users\230Student01\Desktop\ospan\ospan_difference.csv")

%%
%main code

%per problem set
    user_summary_4 = table;
    prb_set = unique(t.problem_set);
    for k = 1:length(prb_set)
        set = t(t.problem_set == prb_set(k), :);
        strict_ave = mean(set.strict_score);
        strict_std = std(set.strict_score);
        flex_ave = mean(set.flex_score);
        flex_std = std(set.flex_score);
        miss_err_ave = mean(set.missing_error);
        miss_err_std = std(set.missing_error);
        add_err_ave = mean(set.additional_error);
        add_err_std = std(set.additional_error);
        row = {user(i),prb_set(k),strict_ave,strict_std,flex_ave,flex_std,miss_err_ave,miss_err_std,add_err_ave,add_err_std};
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