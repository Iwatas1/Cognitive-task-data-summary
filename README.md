# Cognitive task data summary

MATLAB code for sorting, scoring, and summarizing HowRU app cognitive tasks (FTT, OSPAN, RST, WPA), one folder per study (K08, PSF).

## Setup
1. Copy `study_config_template.m` to `study_config.m` in the study folder and fill in the data paths and ID lists.
2. Add the study folder and the task folder to the MATLAB path.
3. Run `just_<TASK>.m` (the main workflow for each task).

`study_config.m` and all data files (.csv, .xlsx, .mat, .mlx) are gitignored. Do not commit participant data, IDs, or lab server paths.
