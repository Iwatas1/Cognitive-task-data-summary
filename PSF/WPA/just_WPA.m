% Exported from just_WPA.mlx (live script outputs removed)
clear
cfg = study_config();
warning('off','all')
file_path = cfg.psf_root;
% (add this task's code folder to the MATLAB path)
raw_data = select_dataset(file_path);
T_study = select_studysheet(file_path);
raw_data(~contains(raw_data.user,digitsPattern),:) = [];
[WPA_train, WPA_morning] = sorting_WPA(raw_data);
WPA_train = update_WPA_night(WPA_train,file_path);
WPA_morning = update_WPA_morning(WPA_morning,file_path);
[WPA_long,WPA_wide,WPA_modification_detail,WPA_summary] = summarize_WPA(WPA_morning,WPA_train,T_study,file_path);
psf = x;
k08 = load(fullfile(cfg.k08_root,'Cog_Tasks\postprocessed\WPA\WPA_long.mat'))
k08 = k08.x;
T = [k08;psf]
study = readtable(fullfile(cfg.psf_root,'Studysheet\sex_age_match.xlsx'),'sheet','sheet1');
SID = [study.SID;study.SID_match];
T.Date = string(month(T.Date,'long'));
t = T(ismember(string(T.SID),string(SID)),:)
col = readtable(fullfile(cfg.psf_root,'Cog_Tasks\postprocessed\OSPAN\new_data.xlsx'),'sheet','OSPAN')
ind = find(matches(t.Properties.VariableNames,"AMPM"));
col(:,col.Properties.VariableNames(1:find(matches(col.Properties.VariableNames,"AMPM"))))
[col(:,col.Properties.VariableNames(1:find(matches(col.Properties.VariableNames,"AMPM")))) t(:,ind+1:end)]
writetable([col(:,col.Properties.VariableNames(1:find(matches(col.Properties.VariableNames,"AMPM")))) t(:,ind+1:end)],fullfile(cfg.psf_root,'Cog_Tasks\postprocessed\OSPAN\new_data.xlsx'),'sheet','WPA')
