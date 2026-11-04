function y = sorting_FTT(raw_data)
cfg = study_config();
format long g
current_T = raw_data;
user = string(extract(current_T.user,digitsPattern));
current_T.user = user;
current_T(ismember(current_T.user, cfg.test_ids),:) = []; % drop test accounts
FTT = table;
for i = 1:height(current_T)
    try
        json = current_T{i,'data'}{1};
        struct = jsondecode(json);
        struct_data = struct.data;
        struct_meta = struct.metadata;
        row_data = struct2table(struct_data,"AsArray", true);
        row_meta = struct2table(struct_meta,"AsArray",true);
        row_meta(:,'page_advances') = [];
        row = horzcat(current_T(i,"user"), row_data, row_meta);
        col_names = row.Properties.VariableNames;
        if sum(contains(col_names,"finger_tap")) >= 1
            FTT = vertcat(FTT,row);
        end
    end
    %{
    if assigned == false
        disp("unknown data")
        row
        break;
    end
    %}
end
y = FTT;
end

