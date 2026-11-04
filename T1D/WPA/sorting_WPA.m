function [x,y] = sorting_WPA(current_T)
cfg = study_config();
format long g
current_T.user = string(extract(current_T.user,digitsPattern));
current_T(ismember(current_T.user, cfg.test_ids),:) = []; % drop test accounts
WPA_train = table;
WPA_test = table;
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
        if sum(contains(col_names,"wpa_training")) >= 1
            if sum(contains(col_names,"wpa_morning_testing")) >= 1
                row = renamevars(row,"wpa_morning_testing","wpa_testing");
                WPA_train = vertcat(WPA_train,row);
            elseif sum(contains(col_names,"wpa_night_testing")) >= 1
                row = renamevars(row,"wpa_night_testing","wpa_testing");
                WPA_train= vertcat(WPA_train,row);
            else
                WPA_train = vertcat(WPA_train,row);
            end
            t.task = "WPA_S1";
            assigned = true;
        elseif sum(contains(col_names,"wpa")) >= 1

            if sum(contains(col_names,"wpa_morning_testing")) >= 1
                row = renamevars(row,"wpa_morning_testing","wpa_testing");
                WPA_test = vertcat(WPA_test,row);
            elseif sum(contains(col_names,"wpa_night_testing")) >= 1
                row = renamevars(row,"wpa_night_testing","wpa_testing");
                WPA_test = vertcat(WPA_test,row);
            else
                WPA_test = vertcat(WPA_test,row);
            end
            t.task = "WPA_S2";
            assigned = true;
        end
    catch
    end
    %{
    if assigned == false
        disp("unknown data")
        row
        break;
    end
    %}
end
x = WPA_train;
y = WPA_test;
end