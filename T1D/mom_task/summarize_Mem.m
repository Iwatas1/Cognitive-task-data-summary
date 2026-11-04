function [A,D] = summarize_Mem(processedData,study_cog)
cfg = study_config();

copy = processedData;
copy.date = string(copy.Burst_Day_);
copy(copy.started_at == 0,:) = [];
copy.is_correct = cell2mat(copy.is_correct);
copy.accuracy_manhattan = cell2mat(copy.accuracy_manhattan);
a = cell2table(copy.first_test_correct);
copy(:,"first_test_correct") = [];
copy.first_test_correct = a{:,1};
a = cell2table(copy.second_test_correct);
copy.second_test_correct = a{:,1};
a = cell2table(copy.correctness_change_numeric);
copy.correctness_change_numeric = a{:,1};
tf = isnan(a{:,1});
a = cell2mat(copy.accuracy_difference);
copy(:,"accuracy_difference") = [];
copy{~tf,"accuracy_difference"} = a;
copy{tf,"accuracy_difference"} = nan;
a = cell2mat(copy.response_distance);
copy(:,"response_distance") = [];
copy{~tf,"response_distance"} = a;
copy{tf,"response_distance"} = nan;
s1 = or(and(copy.AMPM == "PM",copy.Sleep_Wake_condition == 1),and(copy.AMPM == "AM",copy.Sleep_Wake_condition == 0));
train = copy(s1,:);
test = copy(~s1,:);
clear copy s1
T = study_cog;
T.AMPM = repmat(["S1";"S2"],height(study_cog)/2,1);
T = renamevars(T,"AMPM","Session");
SID = unique(T.SID);
A = table;
D = table;
check = table;
for i = 1:length(SID)
    t_train = train(train.SID == SID(i),:);
    t_test = test(test.SID == SID(i),:);
    t = T(T.SID == SID(i),:);
    swc = unique(t.Sleep_Wake_condition);
    for j = 1:length(swc)
        t_s = t(t.Sleep_Wake_condition == swc(j),:);
        sd = string(t_s.Date);
        for k = length(sd):-1:1
            if t_s.Session(k) == "S1"
                s1 = train(train.date == sd(k),:);
                match = false;
                if height(s1)>=grid_size 
                    if multiple_tiles == false
                        for l = 1:height(s1)/grid_size
                            if sum(matches(s1.tiles{l*grid_size},s_tiles),'all') == grid_size
                                s1 = s1(l*grid_size - grid_size+1:l*grid_size,:);
                                match = true;
                                break;
                            end
                        end
                        if height(s1)>grid_size
                            s1(1:end,:) = [];
                        end
                    else
                        for L = 1:length(TILES)
                            s_tiles = TILES{L};
                            for l = 1:height(s1)/grid_size
                                if sum(matches(s1.tiles{l*grid_size},s_tiles),'all') == grid_size
                                    s1 = s1(l*grid_size - grid_size+1:l*grid_size,:);
                                    s2 = s2(grid_size*L - grid_size+1:grid_size*L,:);
                                    if ~all(isnan(s2.first_test_correct))
                                        data_exist = true;
                                    else
                                        data_exist = false;
                                    end
                                    sub = overnight_scoring(s2,data_exist,sub);
                                    t_s = session_scoring(t_s,s2,grid_size,sd(k+1),k+1);
                                    multiple_tiles = false;
                                    match = true;
                                    break;
                                end
                            end
                        end
                        if height(s1)>grid_size
                            s1(1:end,:) = [];
                        end
                    end
                else
                    s1(1:end,:) = [];
                end
                if match == false
                    s1(1:end,:) = [];
                end
                t_s = session_scoring(t_s,s1,grid_size,sd(k),k);
            else
                s2 = test(test.date == sd(k),:);
                sub = t_s(t_s.Session == "S2",:);
                data_exist = false;
                multiple_tiles = false;
                TILES = cell(0,0);
                if height(s2) > 0
                    grid_size = numel(s2.tiles{1});
                    if height(s2) > numel(s2.tiles{1})
                        multiple_tiles = true;
                        for l = 1:height(s2)/grid_size
                            TILES{l} = s2.tiles{l*grid_size};
                        end
                        %s2 = s2(s2.started_at == max(s2.started_at),:);
                        %check = [check;t_s];
                    else
                        s_tiles = s2.tiles{1};
                       
                    end
                    

                else
                    grid_size = nan;
                    s_tiles = "";
                end                    
                if ~all(isnan(s2.first_test_correct)) && multiple_tiles == false
                    data_exist = true;
                    t_s = session_scoring(t_s,s2,grid_size,sd(k),k);
                    sub = overnight_scoring(s2,data_exist,sub);
                elseif multiple_tiles == false 
                    t_s = session_scoring(t_s,s2,grid_size,sd(k),k);
                    sub = overnight_scoring(s2,data_exist,sub);
                end
                
            end
        end  
        if multiple_tiles == false
            sub = [sub t_s(t_s.Session == "S2",["ave_reaction_time","ave_distance","ave_distance_incorrect","correct_rate"]) - t_s(t_s.Session == "S1",["ave_reaction_time","ave_distance","ave_distance_incorrect","correct_rate"])];
            D = [D;sub];
        end
        A = [A;t_s];
    end
end
clear i j k l match grid_size s-tiles sd SID t T swc a tf data_exist  L multiple_tiles
A.Date = month(A.Date,'long');
A(:,["Day","Blurghbo","Burst_Day_"]) = [];
D.Date = month(D.Date,'long');
D(:,["Day","Blurghbo","Burst_Day_"]) = [];
writetable(A,fullfile(cfg.t1d_root,'Cog_Tasks\postprocessed\Memory_Task\Mem_task_long.csv'))
% Excel can't hold a list in one cell (e.g. tiles = {'cat','dog',...}),
% so list columns are written as text like "cat, dog, ...". A and D
% themselves are unchanged for use in MATLAB.
writetable(cells_to_text(A),fullfile(cfg.t1d_root,'Cog_Tasks\Cogtask data.xlsx'),'sheet','Memory Task')
writetable(cells_to_text(A),fullfile(cfg.t1d_root,'T1D master data.xlsx'),'sheet','Memory Task')
writetable(cells_to_text(D),fullfile(cfg.t1d_root,'Cog_Tasks\postprocessed\Memory_Task\Mem_task_OVN.xlsx'))

end

function T = cells_to_text(T)
% Turns every cell column that holds lists (not just one text value per
% row) into a string column, joining each list with ", ".
names = T.Properties.VariableNames;
for v = 1:numel(names)
    x = T.(names{v});
    if ~iscell(x) || iscellstr(x)
        continue
    end
    out = strings(size(x, 1), 1);
    for r = 1:size(x, 1)
        e = x{r, 1};
        if isempty(e)
            out(r) = "";
        else
            try
                out(r) = strjoin(string(e(:)).', ", ");
            catch
                out(r) = string(jsonencode(e));   % anything that isn't text/numbers
            end
        end
    end
    T.(names{v}) = out;
end
end