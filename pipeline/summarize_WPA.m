function [x,z,a,diff] = summarize_WPA(WPA_morning,WPA_train,T_study,file_path)
WPA_train(:,"wpa_training") = [];
T = vertcat(WPA_morning,WPA_train(:,WPA_morning.Properties.VariableNames));
copy = T;
time = unique(copy.started_at);
new = table;
for i = 1:length(time)
    t = copy(copy.started_at == time(i),:);
    if height(t)>30
        if length(unique(t.choiceTime)) < 31
            t = t(1:30,:);
        else
            t
            return
        end
    end
    t{:,"wordpair_sets"} = {[t.wordpair(:,1).' t.wordpair(:,2).']};
    new = [new;t];
end
T = new;
study_cog = [T_study;T_study];
study_cog = sortrows(study_cog,["SID","StudyWeek","Day"]);
study_cog.AMPM = repmat(["AM";"PM"],height(study_cog)/2,1);
study_cog(or(and(study_cog.AMPM == "AM",study_cog.Day == 1),and(study_cog.AMPM == "PM",study_cog.Day == 5)),:) = [];
S = study_cog;
T.test_type = string(T.test_type);
T = renamevars(T,"user","SID");
T.SID = double(T.SID);
T{T.confidence == "HIGH","confidence_rate"} = 3;
T{T.confidence == "MODERATE","confidence_rate"} = 2;
T{T.confidence == "LOW","confidence_rate"} = 1;
T{contains(T.test_type,"Train"),"test_type"} = "Training";
T{~contains(T.test_type,"Train"),"test_type"} = "Testing";
T{and(hour(T.date) < 15,hour(T.date) > 4), "AMPM"} = "AM";
T{~and(hour(T.date) < 15,hour(T.date) > 4), "AMPM"} = "PM";
SID = unique(S.SID);
S2 = S(S.AMPM == "AM",:);
S1 = S(S.AMPM ~= "AM",:);
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
                    match = false;
                    if ~isempty(timestamp_1)
                        for l = 1:length(timestamp_1)
                            t_1_0 = t_1(t_1.started_at == timestamp_1(l),:);
                            if sum(ismember(t_1_0{1,"wordpair_sets"}{1},t_2_0{1,"wordpair_sets"}{1})) > 50
                                t_1 = t_1_0;
                                t_2 = t_2_0;
                                match = true;
                                break;
                            end
                        end
                    end
                    if match == true
                        break;
                    end
                end
            end
            if length(unique(t_2.AMPM))>1 || length(unique(t_2.started_at))>1
                t_2 = t_2(t_2.AMPM == "AM",:);
                t_2 = t_2(t_2.started_at == min(t_2.started_at),:);
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

session_2 = long.AMPM == "AM";
long{session_2,"AMPM"} = "S2";
long{~session_2,"AMPM"} = "S1";
long = renamevars(long,"AMPM","Session");
long.d_prime = nan(height(long),1);
long{:,"wordpair_matching"} = "matches";
s1 = long(long.Session == "S1",:);
s2 = long(long.Session == "S2",:);

sig = std(s1.same_c(~isnan(s1.same_c)));
mu = mean(s1.same_c(~isnan(s1.same_c)));
z_s_c = (s1.same_c - mu) ./ sig;
sig = std(s1.diff_ic(~isnan(s1.diff_ic)));
mu = mean(s1.diff_ic(~isnan(s1.diff_ic)));
z_d_ic = (s1.diff_ic - mu) ./ sig;
d_prime = z_s_c - z_d_ic;
long{long.Session == "S1","d_prime"} = d_prime;
clear sig mu z_s_c z_d_ic d_prime

sig = std(s2.same_c(~isnan(s2.same_c)));
mu = mean(s2.same_c(~isnan(s2.same_c)));
z_s_c = (s2.same_c - mu) ./ sig;
sig = std(s2.diff_ic(~isnan(s2.diff_ic)));
mu = mean(s2.diff_ic(~isnan(s2.diff_ic)));
z_d_ic = (s2.diff_ic - mu) ./ sig;
d_prime = z_s_c - z_d_ic;
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
long = renamevars(long,"Session","AMPM");
long{long.AMPM == "S1","AMPM"} = "PM";
long{long.AMPM == "S2","AMPM"} = "AM";
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
%{
T_morning.test_type = string(T_morning.test_type);
T_night.test_type = string(T_night.test_type);
T_night(:,"wpa_training") = [];

T = vertcat(T_morning,T_night);
response = WPA_long;
w = width(response);
first = true;
for i = 1:height(response)
    u = WPA_long{i,"SID"};
    tt = WPA_long{i,"test_type"};
    d = WPA_long{i,"Date"};
    t = T(T.user == u,:);
    t = t(t.test_type == tt, :);
    t = t(string(t.date) == string(d),:);
    if height(t) ~= 0 
        row = t(1,5:end-6);
        col_names = row.Properties.VariableNames;
        for j = 1:length(col_names)
            col_names{j} = append(col_names{j},"_1");
        end
        row = renamevars(row,row.Properties.VariableNames,string(col_names));
        for j = 2:height(t)
            new_r = t(j,6:end-6);
            col_names = new_r.Properties.VariableNames;
            for k = 1:length(col_names)
                col_names{k} = append(col_names{k},"_",string(j));
            end
            new_r = renamevars(new_r,new_r.Properties.VariableNames,string(col_names));
    
            row = horzcat(row,new_r);
        end
        response(i,w+1:w+width(row)) = row;
        if first == true
            col_names = response.Properties.VariableNames(w+1:end);
            response = renamevars(response,col_names,row.Properties.VariableNames);
            first = false;
        end
    end
end
for i = width(WPA_long)+1:width(response)
    z = response(isnan(response.same_c),:);
    if class(z{1,i}) == "double" 
        z{z{:,i}==0,i} = nan;
    end
    response(isnan(response.same_c),:) = z;
end
response(:,contains(response.Properties.VariableNames,"word_pairs")) = [];
y = response;
writetable(response,append(file_path,'\output\cog_tasks\WPA\WPA_long_with_responses.csv'));
%}
WPA_wide = table;
for i = 1:length(SID)
    t = long(long.SID == SID(i),:);
    w = unique(t.StudyWeek);
    for j = 1:length(w)
        t_w = t(t.StudyWeek == w(j),:);
        ampm = unique(t_w.AMPM);
        for k = 1:length(ampm)
            row = table;
            t_t = t_w(t_w.AMPM == ampm(k),:);
            row{end+1,"user"} = SID(i);
            row{end,"StudyWeek"} = w(j);
            row{end,"AMPM"} = ampm(k);
            if ampm(k) == "AM"
                for l = 1:height(t_t)+1
                    if l == 1
                        attach = t_t(l,find(matches(t_t.Properties.VariableNames,"AMPM"))+1:end);
                        attach = blank_row(attach, "unusable_data");
                    else
                        attach = t_t(l-1,find(matches(t_t.Properties.VariableNames,"AMPM"))+1:end);
                    end
                    col_names = string(attach.Properties.VariableNames);
                    for m = 1:length(col_names)
                        col_names(m) = append(col_names(m),"_",string(l));
                    end
                    row(end,end+1:end + width(attach)) = attach;
                    row = renamevars(row,row.Properties.VariableNames(end-width(attach)+1:end),col_names);
                end
            else
                for l = 1:height(t_t)+1
                    if l == 8
                        attach = t_t(l-1,find(matches(t_t.Properties.VariableNames,"AMPM"))+1:end);
                        attach = blank_row(attach, "unusable_data");
                    else
                        attach = t_t(l,find(matches(t_t.Properties.VariableNames,"AMPM"))+1:end);
                    end
                    col_names = string(attach.Properties.VariableNames);
                    for m = 1:length(col_names)
                        col_names(m) = append(col_names(m),"_",string(l));
                    end
                    row(end,end+1:end + width(attach)) = attach;
                    row = renamevars(row,row.Properties.VariableNames(end-width(attach)+1:end),col_names);
                end
            end

            WPA_wide = vertcat(WPA_wide,row);
        end
    end
end
z = WPA_wide;
a = WPA_wide;   % 3rd output was never assigned before; z is overwritten by the wide-wide table below
copy = z;
% Keep only columns that can be subtracted (plus user, StudyWeek, AMPM).
% The old "word_pairs" filter no longer matched anything, so the string
% column wordpair_matching and the cell column wordpair_sets reached the
% subtraction below and would error there.
numCols = varfun(@(v) isnumeric(v) || islogical(v), copy, 'OutputFormat', 'uniform');
numCols(1:3) = true;
copy = copy(:, numCols);
copy_m = copy(copy.AMPM == "AM",:);
copy_m(:,contains(copy_m.Properties.VariableNames,"_1")) = [];
copy_n = copy(copy.AMPM == "PM",:);
copy_n(:,contains(copy_n.Properties.VariableNames,"_8")) = [];
copy_m = renamevars(copy_m,copy_m.Properties.VariableNames(3:end),string(copy_n.Properties.VariableNames(3:end)));
copy_0 = vertcat(copy_m,copy_n);
user = unique(copy_0.user);

WPA_diff = table;
for i = 1:length(user)
    t = copy_0(copy_0.user == user(i),:);
    t = sortrows(t,"StudyWeek","ascend");
    for j = 1:2:height(t)
        row = table;
        row{end+1,"user"} = user(i);
        row{end,"StudyWeek"} = t{j,"StudyWeek"};
        p_diff = t(j,4:end) - t(j+1,4:end);
        col_names = string(p_diff.Properties.VariableNames);
        for k = 1:length(col_names)
            c = char(col_names(k));
            c_0 = c(1:end-2);
            col_names(k) = append(c_0,"_Ov_perf_diff_Night",c(end));
        end
        p_diff = renamevars(p_diff,p_diff.Properties.VariableNames,col_names);
        row = horzcat(row,p_diff);
        WPA_diff = vertcat(WPA_diff,row);
    end

end
diff = WPA_diff;
writetable(WPA_diff,append(file_path,'\Cog_Tasks\postprocessed\WPA\WPA_summary.xlsx'));
%wide wide format
copy = x;
wide = table;
SID = unique(copy.SID);
for i = 1:length(SID)
    t = copy(copy.SID == SID(i),:);
    sw = unique(t.StudyWeek);
    for j = 1:length(sw)
        tt = t(t.StudyWeek == sw(j),:);
        row = tt(1,["SID","StudyWeek"]);
        t_m = tt(string(tt.AMPM) == "AM",:);
        %t_m(1,:) = [];
        t_n = tt(string(tt.AMPM) == "PM",:);
        %t_n(end,:) = [];
        for k = 1:height(t_m)
            row_m = t_m(k,width(T_study)+2:end);
            col_m = string(row_m.Properties.VariableNames);
            row_n = t_n(k,width(T_study)+2:end);
            col_n = string(row_n.Properties.VariableNames);
            for l = 1:length(col_m)
                col_m(l) = append(col_m(l),"_AM_",string(k+1));
                col_n(l) = append(col_n(l),"_PM_",string(k));
            end
            row_m = renamevars(row_m,row_m.Properties.VariableNames,col_m);
            row_n = renamevars(row_n,row_n.Properties.VariableNames,col_n);
            row = horzcat(row,row_n,row_m);
        end
        wide = vertcat(wide,row);
    end
end
z = wide;
writetable(z,append(file_path,'\Cog_Tasks\postprocessed\WPA\WPA_wide.xlsx'));
end

function attach = blank_row(attach, keep)
% Fills every variable of a one-row table with a missing value that fits
% its type, except the variables named in keep. Replaces the old
% attach{1,...} = nan(...) line, which failed once the table had string
% (wordpair_matching), logical (TaskPerf flags) or cell (wordpair_sets)
% columns, because NaN can't be put into those types.
names = attach.Properties.VariableNames;
for v = 1:numel(names)
    if any(strcmp(names{v}, keep))
        continue
    end
    val = attach.(names{v});
    if isnumeric(val) || islogical(val)
        attach.(names{v}) = NaN(size(val));          % logical becomes double NaN
    elseif iscell(val)
        attach.(names{v}) = repmat({[]}, size(val)); % empty, still class "double" inside
    else
        try
            attach.(names{v})(:) = missing;           % string, datetime, categorical
        catch
            % leave any other type as it is
        end
    end
end
end