function [x,y,z] = summarize_RST(RST,study_cog,file_path)
R = RST;
R.started_at_pst = datetime(R.started_at / 1000, 'convertfrom','posixtime','TimeZone','America/Los_Angeles', 'Format','dd-MMM-yyyy HH:mm:ss');
R.finished_at_pst = datetime(R.finished_at /1000, 'convertfrom','posixtime','TimeZone','America/Los_Angeles', 'Format','dd-MMM-yyyy HH:mm:ss');
R.type = string(R.type);
R.mode = string(R.mode);
R.placementType = string(R.placementType);
hours = hour(R.started_at_pst);
R{hours < 15,"AMPM"} = "AM";
R{or(hours>=15,hours<4),"AMPM"} = "PM";
R.date = datetime(R.started_at_pst,"Format","dd-MMM-uuuu");
R.reactiontime_ms = R{:,'decisionTime'} - R{:,'startTime'};
R.reactiontime_ms = second(datetime(R.reactiontime_ms ./ 1000,'convertfrom','posixtime','Format','dd-MMM-yyyy HH:mm:ss.SSSSSSS'))*1000;
R = R(R.mode == "test",:);

warning('off', 'all')
copy = study_cog;
R.user = double(R.user);

for i = 1:height(copy)
    user_summary = R(R.user == copy{i,"SID"},:);
    d = user_summary(string(user_summary.date) == string(copy{i,"Date"}),:);
    test = d(d.AMPM == copy{i,"AMPM"},:);
    same = test(test.type == "same", :);
    dif = test(test.type == "different", :);
    both = test(test.type == "both", :);
    both_con = both(both.placementType == "congruent",:);
    both_inc = both(both.placementType == "incongruent", :);
    a = same.reactiontime_ms;
    a = a(~isnan(a));
    copy{i,'congruent_score'} = sum(same.isCorrect == 1)/height(same)*100;
    copy{i,'congruent_time_ave'} = mean(a);
    copy{i,'congruent_time_std'} = std(a);
    a = dif.reactiontime_ms;
    a = a(~isnan(a));
    copy{i,'incongruent_score'} = sum(dif.isCorrect == 1)/height(dif)*100;
    copy{i, 'incongruent_time_ave'} = mean(a);
    copy{i, 'incongruent_time_std'} = std(a);
    a = both.reactiontime_ms;
    a = a(~isnan(a));
    copy{i,'mix_score'} = sum(both.isCorrect == 1)/height(both)*100;
    copy{i, 'mix_total_time_ave'} = mean(a);
    copy{i, 'mix_total_time_std'} = std(a);
    a = both_inc.reactiontime_ms;
    a = a(~isnan(a));
    copy{i,'mix_incongruent_time_ave'} = mean(a);
    copy{i,'mix_incongruent_time_std'} = std(a);
    a = both_con.reactiontime_ms;
    a = a(~isnan(a));
    copy{i, 'mix_congruent_time_ave'} = mean(a);
    copy{i, 'mix_congruent_time_std'} = std(a);
    copy{i,'congruent_time_dif'} = copy{i, 'mix_congruent_time_ave'} - copy{i,'congruent_time_ave'};
    copy{i,'incongruent_time_dif'} = copy{i, 'mix_incongruent_time_ave'} - copy{i,'incongruent_time_ave'};
end
long = copy;
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
    range = std(AM{:,i})*3;
    u_bound = mean(col) + range;
    l_bound = mean(col) - range;
    col(or(col>u_bound,col<l_bound)) = nan;
    AM{~isnan(AM{:,i}),i} = col;
    col = PM{:,i};
    col = col(~isnan(col));
    range = std(PM{:,i})*3;
    u_bound = mean(col) + range;
    l_bound = mean(col) - range;
    col(or(col>u_bound,col<l_bound)) = nan;
    PM{~isnan(PM{:,i}),i} = col;
end
RST_long(RST_long.AMPM == "AM",:) = AM;
RST_long(RST_long.AMPM == "PM",:) = PM;
x = RST_long;
session = x.AMPM;
session(or(and(x.Sleep_Wake_condition == 1,session == "PM"),and(x.Sleep_Wake_condition == 0,session == "AM"))) = "S1";
session(session~="S1") = "S2";
x.AMPM = session;
x = renamevars(x,"AMPM","Session");
x.Date = month(x.Date,'long');
x(:,["Blurghbo","Burst_Day_"]) = [];
writetable(x,append(rst_path,'RST_long.xlsx'));
writetable(x,append(file_path,'\Cog_Tasks\Cogtask data.xlsx'),'sheet','RST');
writetable(x,append(file_path,'\T1D master data.xlsx'),'sheet','RST');
save(append(rst_path,'RST_long.mat'),'x');

copy = x;
%long(isnat(long.Date),:) = [];
SID = unique(long.SID);
wide = table;   
swc = unique(copy.Sleep_Wake_condition);
ampm = unique(copy.Session);
for i = 1:length(SID)
    t = copy(copy.SID == SID(i),:);
    for j = 1:length(swc)
        t_c = t(t.Sleep_Wake_condition == swc(j),:);
        row = t_c(1,1:width(study_cog)-1);
        for k = 1:length(ampm)
            t_ampm = t_c(t_c.Session == ampm(k),:);
            col_names = string(t_ampm.Properties.VariableNames(width(study_cog)+1:end));
            if ampm(k) == "S1"
                for l = 1:length(col_names)
                    col_names(l) = append(col_names(l),"_S1");
                end
            else
                for l = 1:length(col_names)
                    col_names(l) = append(col_names(l),"_S2");
                end
            end
            t_ampm = renamevars(t_ampm,t_ampm.Properties.VariableNames(width(study_cog)+1:end),col_names);
            if height(t_ampm) > 1
                t_ampm
            end
            row = [row t_ampm(1,width(study_cog)+1:end)];

        end
        wide = [wide;row];
    end
end
wide(:,contains(wide.Properties.VariableNames,["Week","Date","Day","day"])) = [];
y = wide;
save(append(rst_path,'RST_wide.xlsx'),'y');

copy = x;
ind = find(matches(x.Properties.VariableNames,"Session")) + 1;
OVN = table;
for i = 1:length(SID)
    t = copy(copy.SID == SID(i),:);
    for j = 1:length(swc)
        t_c = t(t.Sleep_Wake_condition == swc(j),:);
        row = t_c(1,1:ind-2);
        am = t_c(t_c.Session == "S1",ind:end);
        pm = t_c(t_c.Session == "S2",ind:end);
        dif = pm - am;
        col_names = string(dif.Properties.VariableNames);
        for k = 1:length(col_names)
            col_names(k) = append(col_names(k),"_Ov_perf_diff");
        end
        dif = renamevars(dif,dif.Properties.VariableNames,col_names);
        row = [row dif];
        OVN = [OVN;row];
    end
    
end
OVN(:,contains(OVN.Properties.VariableNames,["Week","Date","Day","day","std"])) = [];
z = OVN;
writetable(z,append(rst_path,'RST_overnight.xlsx'));
end