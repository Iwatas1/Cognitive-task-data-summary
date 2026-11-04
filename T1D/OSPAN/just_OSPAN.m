% Exported from just_OSPAN.mlx (live script outputs removed)
clear
cfg = study_config();
warning('off','all')
file_path = cfg.t1d_root;%file path to sorter code
% (add this task's code folder to the MATLAB path)
warning('off','all')
raw_data = select_dataset(file_path);
T_study = select_studysheet(file_path);
OSPAN = sorting_OSPAN(raw_data);
[study_cog,study_sd] = expand_study(T_study);
%clear RST OSPAN WPA_train WPA_test EMA_morning EMA_evening PSS forget_evening forget_morning GAD_7 ISO EMA_on_mind EMA M_test M_train Digit_Span PDI PSQI MEQ_child CESD MEQ
OSPAN = update_OSPAN(OSPAN,file_path);
[OSPAN_scores,OSPAN_diff_level,OSPAN_long,OSPAN_wide,OSPAN_summary] = summarize_OSPAN(OSPAN,study_cog,file_path);
clear OSPAN
copy = OSPAN_diff_level;
copy(:,contains(copy.Properties.VariableNames,["extra","add"])) = []
ovn = copy(copy.Sleep_Wake_condition == 1,:);
ovn_s1 = ovn(ovn.Session == "S1",:);
ovn_s2 = ovn(ovn.Session == "S2",:);
wake = copy(copy.Sleep_Wake_condition == 0,:);
wake_s1 = wake(wake.Session == "S1",:);
wake_s2 = wake(wake.Session == "S1",:);
T = {ovn,ovn_s1,ovn_s2,wake,wake_s1,wake_s2};
ovn

for i = 1:length(T)
    t = T{i};
    writetable(t,append(fullfile(cfg.t1d_root,'Cog_Tasks\postprocessed\OSPAN\'),string(i),".xlsx"))
end
