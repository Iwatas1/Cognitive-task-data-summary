% Exported from just_RST.mlx (live script outputs removed)
clear
cfg = study_config();
warning('off','all')
file_path = cfg.t1d_root;
% (add this task's code folder to the MATLAB path)
raw_data = select_dataset(file_path);
T_study = select_studysheet(file_path);
[study_cog,study_sd] = expand_study(T_study);
RST = sorting_RST(raw_data);
RST = update_RST(RST,file_path);
[RST_long,RST_wide,RST_summary] = summarize_RST(RST,study_cog,file_path);
