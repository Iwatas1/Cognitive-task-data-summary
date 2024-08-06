T_study = readtable("C:\Users\230Student01\Desktop\RST\K08_StudySheet_032524.xlsx");
T = readtable("Rule_switch_processed.csv")
T.started_at_pst = datetime(T.started_at / 1000, 'convertfrom','posixtime','TimeZone','America/Los_Angeles', 'Format','dd-MMM-yyyy HH:mm:ss');
T.finished_at_pst = datetime(T.finished_at /1000, 'convertfrom','posixtime','TimeZone','America/Los_Angeles', 'Format','dd-MMM-yyyy HH:mm:ss');
no_need = {'id', 'user_id'};
T(:,no_need) = [];
T.user = string(T.user);
for i = 1:length(T.user)
    c = char(T.user(i));
    T.user(i) = string(c(end-2:end));
end
T.type = string(T.type);
T.mode = string(T.mode);
T.placementType = string(T.placementType);
T_study.SID = string(T_study.SID);

user = unique(T.user)
%%
%only for K08
user = erase(user,["124", "125","126","127"]);
for i = 1:4
    user(17) = [];
end

T.date = string(datetime(T.started_at_pst,"Format","dd-MMM-uuuu"));
T.time = T{:,'decisionTime'} - T{:,'startTime'};
T.time = second(datetime(T.time ./ 1000,'convertfrom','posixtime','Format','dd-MMM-yyyy HH:mm:ss.SSSS')) * 1000;
%%
%for k08
warning('off', 'all')
test_summary = table;
user_summary = table;
for i = 1:length(user)
    user_summary = table;
    t = T(T.user == user(i), :);
    study = T_study(T_study.SID == user(i),:); 
    user_summary = study(:,1:4);
    for j = 1:height(user_summary)
        date = string(user_summary{j,"Date"});
        day = t(t.date == date,:);
        same = day(day.type == "same", :);
        dif = day(day.type == "different", :);
        both = day(day.type == "both", :);
        both_con = both(both.placementType == "congruent",:);
        both_inc = both(both.placementType == "incongruent", :);
        user_summary{j,'congruent_time_ave'} = mean(same.time);
        user_summary{j,'congruent_time_std'} = std(same.time);
        user_summary{j, 'incongruent_time_ave'} = mean(dif.time);
        user_summary{j, 'incongruent_time_std'} = std(dif.time);
        user_summary{j, 'mix_time_ave'} = mean(both.time);
        user_summary{j, 'mix_time_std'} = std(both.time);
        user_summary{j,'mix_incongruent_time_ave'} = mean(both_inc.time);
        user_summary{j, 'mix_congruent_time_ave'} = mean(both_con.time);
        user_summary{j,'mix_incongruent_time_std'} = std(both_inc.time);
        user_summary{j, 'mix_congruent_time_std'} = std(both_con.time);
        user_summary{j,'congruent_time_dif'} = user_summary{j, 'mix_congruent_time_ave'} - user_summary{j,'congruent_time_ave'};
        user_summary{j,'incongruent_time_dif'} = user_summary{j, 'mix_incongruent_time_ave'} - user_summary{j,'incongruent_time_ave'};
    end
    test_summary = vertcat(test_summary, user_summary);

end
%%
%for yeh
warning('off','all');
yeh = table;
for i = 1:length(user)
    user_summary = table;
    t = T(T.user == user(i), :);
    days = unique(t.date);
    user_summary.user = repelem(user(i),length(days),1);
    for j = 1:length(days)
        day = t(t.date == days(j),:);
        user_summary{j,"date"} = days(j);
        same = day(day.type == "same", :);
        dif = day(day.type == "different", :);
        both = day(day.type == "both", :);
        both_con = both(both.placementType == "congruent",:);
        both_inc = both(both.placementType == "incongruent", :);
        user_summary{j,'congruent_time_ave'} = mean(same.time);
        user_summary{j,'congruent_time_std'} = std(same.time);
        user_summary{j, 'incongruent_time_ave'} = mean(dif.time);
        user_summary{j, 'incongruent_time_std'} = std(dif.time);
        user_summary{j, 'mix_time_ave'} = mean(both.time);
        user_summary{j, 'mix_time_std'} = std(both.time);
        user_summary{j,'mix_incongruent_time_ave'} = mean(both_inc.time);
        user_summary{j, 'mix_congruent_time_ave'} = mean(both_con.time);
        user_summary{j,'mix_incongruent_time_std'} = std(both_inc.time);
        user_summary{j, 'mix_congruent_time_std'} = std(both_con.time);
    end
    yeh = vertcat(yeh, user_summary);
end
yeh
writetable(yeh,"C:\Users\230Student01\Desktop\RST\RST_summary_yeh.csv")
%%
writetable(test_summary,"C:\Users\230Student01\Desktop\RST\RST_summary.csv")