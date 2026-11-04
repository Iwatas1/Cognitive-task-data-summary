function cfg = study_config()
%STUDY_CONFIG Local settings. Copy this file to study_config.m and fill it in.
%   study_config.m is gitignored: never commit real paths or participant IDs.
cfg.k08_root      = 'PATH/TO/K08_DATA';       % K08 study data root
cfg.psf_root      = 'PATH/TO/PSF_DATA';       % PSF study data root
cfg.minigame_root = 'PATH/TO/MINIGAME_DATA';  % OSPAN minigame data root
cfg.test_ids         = ["TEST_ID_1","TEST_ID_2"]; % app test accounts to drop
cfg.ms_timestamp_ids = ["ID_A","ID_B"];   % users whose timestamps need the alternate conversion
cfg.rst_excluded_ids = ["ID_C","ID_D"];   % participants excluded from RST
cfg.wpa_new_version_first_sid = 0;        % first SID on the newer WPA version (numeric)
cfg.ospan_match_file = 'MATCH_LIST.xlsx'; % OSPAN matched-sample list file name
end
