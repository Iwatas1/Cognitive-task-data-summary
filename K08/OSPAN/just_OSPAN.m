% Exported from just_OSPAN.mlx (live script outputs removed)
clear
cfg = study_config();
warning('off','all')
file_path = cfg.k08_root;
% (add this task's code folder to the MATLAB path)
%file path to data folder
raw_data = select_dataset(file_path);
T_study = select_studysheet(file_path);
OSPAN = sorting_OSPAN(raw_data);
OSPAN = update_OSPAN(OSPAN,file_path);
[OSPAN_scores,OSPAN_diff_level,OSPAN_long,OSPAN_wide_AMPM,OSPAN_wide,OSPAN_summary] = summarize_OSPAN(OSPAN,T_study,file_path);

   cfg.days_sheet = [cfg.study_dir '\PSF DATA\Studysheet\PSF_StudySheet_082026_noblurgh.xlsx']
save([fullfile(cfg.minigame_root,'example.mat'),'OSPAN')
k08 = OSPAN_diff_level;
psf = readtable(fullfile(cfg.psf_root,'Cog_Tasks\postprocessed\OSPAN\OSPAN_difficulties.xlsx'));
study = readtable(fullfile(cfg.psf_root,'Cog_Tasks\postprocessed\OSPAN',cfg.ospan_match_file));
ospan = [k08;psf]
study = study(:,1:find(matches(study.Properties.VariableNames,"AMPM")));
final = outerjoin(study, ospan, 'Keys', ["SID","StudyWeek","Day","AMPM"], 'Type', 'left', 'MergeKeys', true)
writetable(final,fullfile(cfg.psf_root,'Cog_Tasks\postprocessed\OSPAN\new_ospan.xlsx'))
ospan = load(fullfile(cfg.k08_root,'Cog_Tasks\preprocessed\OSPAN_preprocessed.mat'));
ospan = ospan.y;
ospan.date = datetime(ospan.started_at/1000,"convertfrom","posixtime","Format","default","TimeZone","local")
ind = find(string(ospan.choice) == '');
ind = [0;ind];
summary = table;
for i = 1:length(ind)-1
    row = table;
    t = ospan(ind(i)+1:ind(i+1)-1,:);
    row{1,"SID"} = t{1,"user"};
    row{1,"Date"} = t{1,"date"};
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
save(fullfile(cfg.psf_root,'Cog_Tasks\postprocessed\OSPAN\codes\k08_math.mat'),'summary')
