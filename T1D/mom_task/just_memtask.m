% Exported from just_memtask.mlx (live script outputs removed)
clear
cfg = study_config();
warning('off','all')
file_path = cfg.t1d_root;%file path to sorter code
% (add this task's code folder to the MATLAB path)
warning('off','all')
raw_data = select_dataset(file_path);
T_study = select_studysheet(file_path);
[M_test,M_train] = sorting_memtask(raw_data);
[study_cog,study_sd] = expand_study(T_study);
trainProcessed = processTrain(M_train,file_path);

%load('Memory Task Data/M_test.mat');
testProcessed = processTest(M_test,file_path);
clear raw_data T_study M_train M_test study_sd
%load('Memory Task Data/study_sheet.mat');
compiledStudySheet = compileStudySheet(study_cog, trainProcessed, testProcessed,file_path);
compiledStudySheet = movevars(compiledStudySheet, 'date', 'After', 'SID');
processedData = processStudySheet(compiledStudySheet);
[l,ovn] = summarize_Mem(processedData,study_cog)


clear testProcessed trainProcessed processedData compiledStudySheet


