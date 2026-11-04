% Exported from just_RST.mlx (live script outputs removed)
clear
cfg = study_config();
warning('off','all')
file_path = cfg.psf_root;
% (add this task's code folder to the MATLAB path)
raw_data = select_dataset(file_path);
raw_data(~contains(raw_data.user,digitsPattern),:) = [];
T_study = select_studysheet(file_path);
RST = sorting_RST(raw_data);
RST = update_RST(RST,file_path);
[RST_long,RST_wide,RST_summary] = summarize_RST(RST,T_study,file_path);
