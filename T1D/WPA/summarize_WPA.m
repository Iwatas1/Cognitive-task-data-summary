function [x,z,OVN] = summarize_WPA(WPA_pre,study_cog,file_path)
T = WPA_pre;
S = study_cog;
T.test_type = string(T.test_type);
T{contains(T.test_type,"Train"),"test_type"} = "Training";
T{~contains(T.test_type,"Train"),"test_type"} = "Testing";
T{and(hour(T.date) < 15,hour(T.date) > 4), "AMPM"} = "AM";
T{~and(hour(T.date) < 15,hour(T.date) > 4), "AMPM"} = "PM";
SID = unique(S.SID);
S2 = S(or(and(S.Sleep_Wake_condition ==1,S.AMPM == "AM"),and(S.Sleep_Wake_condition == 0,S.AMPM == "PM")),:);
S1 = S(~or(and(S.Sleep_Wake_condition ==1,S.AMPM == "AM"),and(S.Sleep_Wake_condition == 0,S.AMPM == "PM")),:);
long = table;
for i = 1:length(SID)
    t = T(T.SID == SID(i),:);
    s1 = S1(S1.SID == SID(i),:);
    s2 = S2(S2.SID == SID(i),:);
    sd_1 = string(s1.Date);
    sd_2 = string(s2.Date);
    if length(sd_1) ~= length(sd_2)
        disp("dates missing from Study Sheet")
    else
        for j = 1:length(sd_2)
            t_2 = t(and(string(t.date) == sd_2(j),t.test_type == "Testing"),:);
            t_1 = t(and(string(t.date) == sd_1(j),t.test_type == "Training"),:);
            match = false;
            
            if height(t_2) == 0
                if height(t_1) > 30
                    t_1 = t_1(t_1.started_at == max(t_1.started_at),:);
                end
            elseif height(t_1) > 30 || height(t_2) > 30
                timestamp_2 = unique(t_2.started_at);
                for k = 1:length(timestamp_2)
                    t_2_0 = t_2(t_2.started_at == timestamp_2(k),:);
                    timestamp_1 = unique(t_1.started_at);
                    if ~isempty(timestamp_1)
                        for l = 1:length(timestamp_1)
                            t_1_0 = t_1(t_1.started_at == timestamp_1(l),:);
                            if sum(ismember(t_1_0{1,"wordpair_sets"}{1},t_2_0{1,"wordpair_sets"}{1})) > 50
                                t_1 = t_1_0;
                                t_2 = t_2_0;
                                break;
                            end
                        end
                    end
                end
            end
            if height(t_2) > 30 || height(t_1) > 30
                t_2
                t_1
                return
            end
            %}
            long = [long;WPA_scoring(t_1,s1(j,:));WPA_scoring(t_2,s2(j,:))];
            clear t_2 t_1
        end
        
            
    end
    clear t s1 s2 sd_1 sd_2
end
clear T S S1 S2
session_2 = or(and(long.Sleep_Wake_condition ==1,long.AMPM == "AM"),and(long.Sleep_Wake_condition == 0,long.AMPM == "PM"));
long{session_2,"AMPM"} = "S2";
long{~session_2,"AMPM"} = "S1";
long = renamevars(long,"AMPM","Session");
long.d_prime = nan(height(long),1);
long{:,"wordpair_matching"} = "matches";
s1 = long(long.Session == "S1",:);
s2 = long(long.Session == "S2",:);

H = (s1.same_c + .5)./(s1.same_c+s1.same_ic+1);
FA = (s1.diff_ic + .5)./(s1.diff_c+s1.diff_ic+1);
d_prime = norminv(H) - norminv(FA);
long{long.Session == "S1","d_prime"} = d_prime;
clear sig mu z_s_c z_d_ic d_prime

H = (s2.same_c + .5)./(s2.same_c+s2.same_ic+1);
FA = (s2.diff_ic + .5)./(s2.diff_c+s2.diff_ic+1);
d_prime = norminv(H) - norminv(FA);
long{long.Session == "S2","d_prime"} = d_prime;
clear sig mu z_s_c z_d_ic d_prime

for i = 1:height(s1)
    if class(s1{i,"wordpair_sets"}{1}) == "double" || class(s2{i,"wordpair_sets"}{1}) == "double"
        long{2*i - 1,"wordpair_matching"} = "missing/incomplete";
        long{2*i,"wordpair_matching"} = "missing/incomplete";
    elseif sum(ismember(s2{i,"wordpair_sets"}{1},s1{i,"wordpair_sets"}{1})) < 55
        long{2*i -1,"wordpair_matching"} = "did not match";
        long{2*i,"wordpair_matching"} = "did not match";
    end
end
long{long.wordpair_matching ~= "matches","unusable_data"} = 1;

long{long.same_c+long.diff_ic>27,"TaskPerf_flag_all_same"} = true;
long{long.same_ic+long.diff_c>27,"TaskPerf_flag_all_diff"} = true;
x = long;

if ~exist([file_path '\Cog_Tasks\postprocessed\WPA\'],'dir')
    mkdir([file_path '\Cog_Tasks\postprocessed\WPA\'])
end
x.Date = month(x.Date,'long');
x(:,["Blurghbo","Burst_Day_"]) = [];
writetable(x,[file_path '\Cog_Tasks\postprocessed\WPA\WPA_long.xlsx']);
save([file_path '\Cog_Tasks\postprocessed\WPA\WPA_long.mat'],'x');
writetable(x,[file_path '\Cog_Tasks\Cogtask data.xlsx'],'sheet','WPA')
writetable(x,[file_path '\T1D master data.xlsx'],'sheet','WPA')
% WPA_diff = table;
% for i = 1:length(user)
%     t = copy_0(copy_0.user == user(i),:);
%     t = sortrows(t,"StudyWeek","ascend");
%     for j = 1:2:height(t)
%         row = table;
%         row{end+1,"user"} = user(i);
%         row{end,"StudyWeek"} = t{j,"StudyWeek"};
%         p_diff = t(j,4:end) - t(j+1,4:end);
%         col_names = string(p_diff.Properties.VariableNames);
%         for k = 1:length(col_names)
%             c = char(col_names(k));
%             c_0 = c(1:end-2);
%             col_names(k) = append(c_0,"_Ov_perf_diff_Night",c(end));
%         end
%         p_diff = renamevars(p_diff,p_diff.Properties.VariableNames,col_names);
%         row = horzcat(row,p_diff);
%         WPA_diff = vertcat(WPA_diff,row);
%     end
% 
% end
% diff = WPA_diff;
% writetable(WPA_diff,append(file_path,'\Cog_Tasks\postprocessed\WPA\WPA_summary.xlsx'));
%wide wide format
T = x;
T(:,contains(T.Properties.VariableNames,["confidence_rate","wordpair_matching","unsuable_data"])) = [];
wide = table;
for i = 1:length(SID)
    t = T(T.SID == SID(i),:);
    swc = unique(t.Sleep_Wake_condition);
    ampm = unique(t.Session);
    for j = 1:length(swc)
        t_c = t(t.Sleep_Wake_condition == swc(j),:);
        row = t_c(1,1:width(study_cog)-1);
        for k = 1:length(ampm)
            t_ampm = t_c(t_c.Session == ampm(k),:);
            if ampm(k) == "S1"
                col_names = string(t_ampm.Properties.VariableNames(width(study_cog)+1:end));
                for l = 1:length(col_names)
                    col_names(l) = append(col_names(l),"_S1");
                end
                t_ampm = renamevars(t_ampm,t_ampm.Properties.VariableNames(width(study_cog)+1:end),col_names);
            else
                col_names = string(t_ampm.Properties.VariableNames(width(study_cog)+1:end));
                for l = 1:length(col_names)
                    col_names(l) = append(col_names(l),"_S2");
                end
                t_ampm = renamevars(t_ampm,t_ampm.Properties.VariableNames(width(study_cog)+1:end),col_names);
            end
            if height(t_ampm)>1
                t_ampm
            end
            row = [row t_ampm(1,width(study_cog)+1:end)];
        end
        wide = [wide;row];
    end
end
wide(:,contains(wide.Properties.VariableNames,["Week","Date","Day","day","sets"])) = [];
z = wide;
writetable(z,append(file_path,'\Cog_Tasks\postprocessed\WPA\WPA_wide.xlsx'));

T = x;
T(:,contains(T.Properties.VariableNames,["Week","Date","Day","day","unsuable_data","matching","confidence"])) = [];
ind = find(matches(T.Properties.VariableNames,"wordpair_sets")) + 1;
swc = unique(T.Sleep_Wake_condition);
OVN = table;
for i = 1:length(SID)
    t = T(T.SID == SID(i),:);
    for j = 1:length(swc)
        t_c = t(t.Sleep_Wake_condition == swc(j),:);
        row = t_c(1,1:ind - 3);
        am = t_c(t_c.Session == "S1",ind:end);
        pm = t_c(t_c.Session == "S2",ind:end);
        dif = pm - am;
        row = [row dif];
        OVN = [OVN;row];
    end
end
col_names = string(OVN.Properties.VariableNames(find(matches(OVN.Properties.VariableNames,"Sleep_Wake_condition"))+1:end));
for i = 1:length(col_names)
    col_names(i) = append(col_names(i),"_Ov_perf_diff");
end
OVN = renamevars(OVN,OVN.Properties.VariableNames(find(matches(OVN.Properties.VariableNames,"Sleep_Wake_condition"))+1:end), col_names);
writetable(OVN,append(file_path,'\Cog_Tasks\postprocessed\WPA\WPA_overnight.xlsx'));
end