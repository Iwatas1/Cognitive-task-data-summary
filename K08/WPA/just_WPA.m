% Exported from just_WPA.mlx (live script outputs removed)
clear
cfg = study_config();
warning('off','all')
file_path = cfg.k08_root;
% (add this task's code folder to the MATLAB path)
raw_data = select_dataset(file_path);
T_study = select_studysheet(file_path);
[WPA_train, WPA_morning] = sorting_WPA(raw_data);
WPA_train = update_WPA_night(WPA_train,file_path);
WPA_morning = update_WPA_morning(WPA_morning,file_path);
[WPA_long,WPA_wide1,WPA_wide2,WPA_summary] = summarize_WPA(WPA_morning,WPA_train,T_study,file_path)
x = long;
if ~exist([file_path '\Cog_Tasks\postprocessed\WPA\'],'dir')
    mkdir([file_path '\Cog_Tasks\postprocessed\WPA\'])
end
writetable(x,[file_path '\Cog_Tasks\postprocessed\WPA\WPA_long.xlsx']);
save([file_path '\Cog_Tasks\postprocessed\WPA\WPA_long.mat'],'x');
x
x(x.unusable_data ~= 1,:)
