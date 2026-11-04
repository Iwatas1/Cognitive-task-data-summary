% Exported from just_RST.mlx (live script outputs removed)
cfg = study_config();
warning('off','all')
file_path = cfg.k08_root;
% (add this task's code folder to the MATLAB path)
raw_data = select_dataset(file_path);
T_study = select_studysheet(file_path);
RST = sorting_RST(raw_data);
RST = update_RST(RST,file_path);
[RST_long,RST_wide,RST_summary] = summarize_RST(RST,T_study,file_path);
copy = RST;
copy(copy.mode == "practice",:) = [];
copy(copy.isCorrect == 0,:) = [];
date = datetime(copy.started_at /1000,"ConvertFrom","posixtime","Format","dd-MMM-uuuu","TimeZone","local");
copy{or(hour(date) >=15,hour(date) < 4),"AMPM"} = "PM";
copy{~or(hour(date) >=15,hour(date) < 4),"AMPM"} = "AM";
copy.date = string(date);
copy.reaction_time = second(datetime((copy.decisionTime - copy.startTime)/1000,"convertfrom","posixtime","Format","HH:mm:ss.SSSSS",'TimeZone','local' ))*1000;
copy
t = RST_long
100 - height(t(isnan(t.congruent_time_ave),:))/height(t)*100
