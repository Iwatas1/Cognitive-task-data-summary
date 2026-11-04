function [x,y,z] = summarize_RST(RST,T_study,file_path)
cfg = study_config();
R = RST;
R.started_at_pst = datetime(R.started_at / 1000, 'convertfrom','posixtime','TimeZone','America/Los_Angeles', 'Format','dd-MMM-yyyy HH:mm:ss');
R.finished_at_pst = datetime(R.finished_at /1000, 'convertfrom','posixtime','TimeZone','America/Los_Angeles', 'Format','dd-MMM-yyyy HH:mm:ss');
R{ismember(R.user, cfg.ms_timestamp_ids),"started_at_pst"} = datetime(R{ismember(R.user, cfg.ms_timestamp_ids),"started_at"}/1000, 'convertfrom','posixtime','TimeZone','Europe/Berlin', 'Format','dd-MMM-yyyy HH:mm:ss');
R{ismember(R.user, cfg.ms_timestamp_ids),"finished_at_pst"} = datetime(R{ismember(R.user, cfg.ms_timestamp_ids),"finished_at"}/1000, 'convertfrom','posixtime','TimeZone','Europe/Berlin', 'Format','dd-MMM-yyyy HH:mm:ss');
R.type = string(R.type);
R.mode = string(R.mode);
R.placementType = string(R.placementType);
T_study.SID = string(T_study.SID);

hours = hour(R.started_at_pst);


R{hours < 15,"AMPM"} = "AM";
R{or(hours>=15,hours<4),"AMPM"} = "PM";
R.date = datetime(R.started_at_pst,"Format","dd-MMM-uuuu");
R.time = R{:,'decisionTime'} - R{:,'startTime'};
R.time = second(datetime(R.time ./ 1000,'convertfrom','posixtime','Format','dd-MMM-yyyy HH:mm:ss.SSSSSSS'))*1000;
R = R(R.mode == "test",:);
R = R(R.isCorrect == 1,:);
T_study_rep = table;
for i = 1:height(T_study)
    T_study_rep = vertcat(T_study_rep, horzcat(repelem(T_study(i,:),2,1),{"AM","PM"}.'));
end
T_study_rep = renamevars(T_study_rep,T_study_rep.Properties.VariableNames{end},"AMPM");
T_study_rep(or(and(T_study_rep.Day == 1,T_study_rep.AMPM == "AM"),and(T_study_rep.Day == 5,T_study_rep.AMPM == "PM")),:) = [];
T_study_rep(ismember(T_study_rep.SID, cfg.rst_excluded_ids),:) = [];

warning('off', 'all')
for i = 1:height(T_study_rep)
    user_summary = R(R.user == T_study_rep{i,"SID"},:);
    d = user_summary(string(user_summary.date) == string(T_study_rep{i,"Date"}),:);
    test = d(d.AMPM == T_study_rep{i,"AMPM"},:);
    same = test(test.type == "same", :);
    dif = test(test.type == "different", :);
    both = test(test.type == "both", :);
    both_con = both(both.placementType == "congruent",:);
    both_inc = both(both.placementType == "incongruent", :);
    a = same.time;
    a = a(~isnan(a));
    T_study_rep{i,'congruent_time_ave'} = mean(a);
    T_study_rep{i,'congruent_time_std'} = std(a);
    a = dif.time;
    a = a(~isnan(a));
    T_study_rep{i, 'incongruent_time_ave'} = mean(a);
    T_study_rep{i, 'incongruent_time_std'} = std(a);
    a = both.time;
    a = a(~isnan(a));
    T_study_rep{i, 'mix_total_time_ave'} = mean(a);
    T_study_rep{i, 'mix_total_time_std'} = std(a);
    a = both_inc.time;
    a = a(~isnan(a));
    T_study_rep{i,'mix_incongruent_time_ave'} = mean(a);
    T_study_rep{i,'mix_incongruent_time_std'} = std(a);
    a = both_con.time;
    a = a(~isnan(a));
    T_study_rep{i, 'mix_congruent_time_ave'} = mean(a);
    T_study_rep{i, 'mix_congruent_time_std'} = std(a);
    T_study_rep{i,'congruent_time_dif'} = T_study_rep{i, 'mix_congruent_time_ave'} - T_study_rep{i,'congruent_time_ave'};
    T_study_rep{i,'incongruent_time_dif'} = T_study_rep{i, 'mix_incongruent_time_ave'} - T_study_rep{i,'incongruent_time_ave'};
end
long = T_study_rep;
x = long;
x(isnat(x.Date),:) = [];
cog_path = append(file_path,'\Cog_Tasks\postprocessed\');
if ~exist(cog_path)
    mkdir(cog_path)
end
rst_path = append(cog_path,'RST\');
if  ~exist(rst_path)
    mkdir(rst_path)
end

%getting rid of data that is 3 standard deviation away from the mean
RST_long = x;
AM = RST_long(RST_long.AMPM == "AM",:);
PM = RST_long(RST_long.AMPM == "PM",:);
ind = find(matches(RST_long.Properties.VariableNames,"AMPM")) + 1;
for i = ind:width(AM)
    col = AM{:,i};
    col = col(~isnan(col));
    range = std(col)*3;   % was std(AM{:,i}): NaN if the column has any NaN, so nothing was ever removed
    u_bound = mean(col) + range;
    l_bound = mean(col) - range;
    col(or(col>u_bound,col<l_bound)) = nan;
    AM{~isnan(AM{:,i}),i} = col;
    col = PM{:,i};
    col = col(~isnan(col));
    range = std(col)*3;   % same fix as AM
    u_bound = mean(col) + range;
    l_bound = mean(col) - range;
    col(or(col>u_bound,col<l_bound)) = nan;
    PM{~isnan(PM{:,i}),i} = col;
end
RST_long(RST_long.AMPM == "AM",:) = AM;
RST_long(RST_long.AMPM == "PM",:) = PM;
x = RST_long;
x.Date = month(x.Date,'long');
x(:,["Blurghbo","Burst_Day_"]) = [];
writetable(x,append(rst_path,'RST_long.xlsx'));
writetable(x,append(file_path,'\Cog_Tasks\Cogtask data.xlsx'),'sheet','RST')
writetable(x,append(file_path,'\PSF master data.xlsx'),'sheet','RST')

%long(isnat(long.Date),:) = [];
SID = unique(long.SID);
wide = table;
for i = 1:length(SID)
    t = long(long.SID == SID(i),:);
    weeks = unique(t.StudyWeek);
    for j = 1:length(weeks)
        sw = t(t.StudyWeek == weeks(j),:);
        row = sw(1,["SID","StudyWeek"]);
        am = sw(sw.AMPM == "AM",:);
        pm = sw(sw.AMPM == "PM", :);
        if height(am)>4
            am = am(2:5,:);
        end
        if height(pm)>4
            pm = pm(1:4,:);
        end
        col_names = string(am.Properties.VariableNames(find(matches(am.Properties.VariableNames,"AMPM"))+1:end));
        % am/pm are capped at 4 rows above (4 nights per week), so the loop
        % must stop at 4. Missing sessions get a NaN row so every week has
        % the same columns (vertcat below needs that).
        nNights = 4;
        blank = array2table(nan(1,numel(col_names)),'VariableNames',col_names);
        for k = 1:nNights
            if k <= height(am), am_r = am(k,col_names); else, am_r = blank; end
            if k <= height(pm), pm_r = pm(k,col_names); else, pm_r = blank; end
            am_r = renamevars(am_r,col_names,col_names+append("_AM_",string(k+1)));
            pm_r = renamevars(pm_r,col_names,col_names+append("_PM_",string(k)));
            row = horzcat(row,pm_r,am_r);
        end
        wide = vertcat(wide,row);
    end
end
y = wide;
writetable(wide,append(rst_path,'RST_wide.xlsx'));

copy = long;
%copy(isnat(copy.Date),:) = [];
RST_diff = table;
SID = unique(copy.SID);
for i = 1:length(SID)
    t = copy(copy.SID == SID(i),:);
    w = unique(t.StudyWeek);
    for j = 1:length(w)
        t_w = t(t.StudyWeek == w(j),:);
        if height(t_w) == 16
            t_w([1 end],:) = [];
        end
        row = table;
        row{end+1,"SID"} = SID(i);
        row{end,"StudyWeek"} = w(j);
        k = 1;
        n = 1;
        while k < height(t_w)
            pair = t_w(k:k+1,width(T_study)+2:end);
            pair(:,contains(pair.Properties.VariableNames,"_std")) = [];
            p_diff = pair(end,:) - pair(end-1,:); %AM - PM
            col_names = string(p_diff.Properties.VariableNames);
            for l = 1:length(col_names)
                col_names(l) = append(col_names(l),"_Ov_perf_diff_Night",string(n));
            end
            p_diff = renamevars(p_diff,p_diff.Properties.VariableNames,col_names);
            n = n+1;
            k = k+2;
            row = horzcat(row,p_diff);
        end
        RST_diff = vertcat(RST_diff,row);
    end
end
z = RST_diff;
writetable(RST_diff,append(rst_path,'RST_summary.xlsx'));
end