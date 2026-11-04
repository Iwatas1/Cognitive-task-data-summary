% Exported from just_OSPAN.mlx (live script outputs removed)
clear all
cfg = study_config();
warning('off','all')
file_path = cfg.psf_root;
% (add this task's code folder to the MATLAB path)
raw_data = select_dataset(file_path);
T_study = select_studysheet(file_path);
OSPAN = sorting_OSPAN(raw_data);
OSPAN = update_OSPAN(OSPAN,file_path);
[OSPAN_scores,OSPAN_diff_level,OSPAN_long,OSPAN_wide_AMPM,OSPAN_wide,OSPAN_summary] = summarize_OSPAN(OSPAN,T_study,file_path);
ind = find(string(ospan.choice) == '');
ind = [0;ind];
summary = table;
for i = 1:length(ind)-1
    row = table;
    t = ospan(ind(i)+1:ind(i+1)-1,:);
    row{1,"SID"} = t{1,"user"};
    row{1,"Date"} = t{1,"date"};
    %row{1,"AMPM"} = t{1,"AMPM"};
    row{1,"length"} = height(t);
    if height(t) < 9 
        row{1,"math_accuracy"} = sum(string(t.user_is_correct) == "True")/height(t)*100;
        row{1,"answer_true"} = sum(string(t.choice) == "True")/height(t)*100;
        row{1,"answer_false"} = sum(string(t.choice) == "False")/height(t)*100;
        row{1,"answer_miss"} = sum(string(t.choice) == "missed")/height(t)*100;
        summary = [summary;row];
    end

end
summary
summary{or(summary.math_accuracy <= 50, summary.answer_miss >= 50),"suspect_flag"} = 1;
summary(summary.length>8,:) = [];
easy = summary(summary.length<6,:);
hard = summary(summary.length>5,:)
k08 = load(fullfile(cfg.psf_root,'Cog_Tasks\postprocessed\OSPAN\codes\k08_math.mat'));
k08 = k08.summary;
T = [summary;k08];
control = load(fullfile(cfg.psf_root,'Cog_Tasks\postprocessed\OSPAN\codes\depression_SID.mat'));
control = control.a;
c = string(control{control.depressed == 0,"SID"});
A = T(ismember(T.SID,c),:)
writetable(summary, fullfile(cfg.psf_root,'Cog_Tasks\postprocessed\OSPAN\ospan_math.xlsx'))
psf = OSPAN_diff_level;
k08 = load(fullfile(cfg.k08_root,'Cog_Tasks\postprocessed\OSPAN\OSPAN_difficulties.mat'));
k08 = k08.b
T = [k08;psf];
study = readtable(fullfile(cfg.psf_root,'Studysheet\sex_age_match.xlsx'),'sheet','sheet1');
SID = [study.SID;study.SID_match];
T.Date = string(month(T.Date,'long'));
t = T(ismember(T.SID,string(SID)),:);
col = readtable(fullfile(cfg.psf_root,'Cog_Tasks\postprocessed\OSPAN\new_ospan.xlsx'));
col_name = col.Properties.VariableNames(1:find(matches(col.Properties.VariableNames,"AMPM")));

writetable(t(:,col.Properties.VariableNames),fullfile(cfg.psf_root,'Cog_Tasks\postprocessed\OSPAN\new_data.xlsx'))
