function [T_33,T_34] = sorting_memtask(current_T)
format long g
current_T.user = string(extract(current_T.user,digitsPattern));
M_test = table;
M_train = table;
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
    if sum(matches(col_names,"mem_testing"))>=1
        M_test = vertcat(M_test,row);
    elseif sum(matches(col_names,"mem_training"))>=1
        M_train = vertcat(M_train,row);
    end

    if i == height(current_T)
        disp("done sorting")
        %output
        
        T_33 = M_test;
        T_34 = M_train;
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