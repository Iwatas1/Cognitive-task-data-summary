function [T_3] = sorting_OSPAN(current_T)
format long g
current_T.user = string(extract(current_T.user,digitsPattern));
OSPAN = table;

for i = 1:height(current_T)
    %assigned = false;
    json = current_T{i,'data'}{1};
    struct = jsondecode(json);
    struct_data = struct.data;
    struct_meta = struct.metadata;
    row_data = struct2table(struct_data,"AsArray", true);
    row_meta = struct2table(struct_meta,"AsArray",true);
    row_meta(:,'page_advances') = [];
    row = horzcat(current_T(i,"user"), row_data, row_meta);
    col_names = row.Properties.VariableNames;

    if sum(contains(col_names,"ospan")) >= 1
        if sum(contains(col_names,"ospan")) >= 3 
            OSPAN = vertcat(OSPAN,row);
        end
        %assigned = true;
    end

    if i == height(current_T)
        disp("done sorting")
        %output
        T_3 = OSPAN;
    end
    %{
    if assigned == false
        disp("unknown data")
        row
        break;
    end
    %}
    
end
end