% Exported from just_WPA.mlx (live script outputs removed)
clear
cfg = study_config();
warning('off','all')
file_path = cfg.t1d_root;
% (add this task's code folder to the MATLAB path)
raw_data = select_dataset(file_path);
T_study = select_studysheet(file_path);
[study_cog,study_sd] = expand_study(T_study);
[WPA_train, WPA_test] = sorting_WPA(raw_data);
WPA_pre = update_WPA(WPA_train, WPA_test, file_path);
[WPA_long,WPA_wide,WPA_summary] = summarize_WPA(WPA_pre,study_cog,file_path)
