function t = session_scoring(t_s,s,grid_size,sd,k)
if height(s)~=0
    s.reaction_time = seconds(duration(string(s.reaction_time),"inputformat", "mm:ss.SSS"));
    t_s{and(string(t_s.Date) == sd,t_s.Session == t_s.Session(k)),"tiles"} = {s.tiles{1}};
    t_s{and(string(t_s.Date) == sd,t_s.Session == t_s.Session(k)),"grid_size"} = grid_size;
    t_s{and(string(t_s.Date) == sd,t_s.Session == t_s.Session(k)),"ave_reaction_time"} = mean(s.reaction_time);
    t_s{and(string(t_s.Date) == sd,t_s.Session == t_s.Session(k)),"std_reaction_time"} = std(s.reaction_time);
    t_s{and(string(t_s.Date) == sd,t_s.Session == t_s.Session(k)),"total_correct"} = sum(s.is_correct);
    t_s{and(string(t_s.Date) == sd,t_s.Session == t_s.Session(k)),"ave_distance"} = -mean(s.accuracy_manhattan); %average manhattan on each tile
    t_s{and(string(t_s.Date) == sd,t_s.Session == t_s.Session(k)),"std_distance"} = std(s.accuracy_manhattan);
    t_s{and(string(t_s.Date) == sd,t_s.Session == t_s.Session(k)),"ave_distance_incorrect"} = -mean(s.accuracy_manhattan(s.accuracy_manhattan~=0)); %average manhattan on the tiles that was wrong on S2
    t_s{and(string(t_s.Date) == sd,t_s.Session == t_s.Session(k)),"std_distance_incorrect"} = std(s.accuracy_manhattan(s.accuracy_manhattan~=0));
    t_s{and(string(t_s.Date) == sd,t_s.Session == t_s.Session(k)),"correct_rate"} = sum(s.is_correct)/grid_size *100;
else
    t_s{and(string(t_s.Date) == sd,t_s.Session == t_s.Session(k)),"tiles"} = {missing};
    t_s{and(string(t_s.Date) == sd,t_s.Session == t_s.Session(k)),"grid_size"} = nan;
    t_s{and(string(t_s.Date) == sd,t_s.Session == t_s.Session(k)),"ave_reaction_time"} = nan;
    t_s{and(string(t_s.Date) == sd,t_s.Session == t_s.Session(k)),"std_reaction_time"} = nan;
    t_s{and(string(t_s.Date) == sd,t_s.Session == t_s.Session(k)),"total_correct"} = nan;
    t_s{and(string(t_s.Date) == sd,t_s.Session == t_s.Session(k)),"ave_distance"} = nan;
    t_s{and(string(t_s.Date) == sd,t_s.Session == t_s.Session(k)),"std_distance"} = nan;
    t_s{and(string(t_s.Date) == sd,t_s.Session == t_s.Session(k)),"ave_distance_incorrect"} = nan;
    t_s{and(string(t_s.Date) == sd,t_s.Session == t_s.Session(k)),"std_distance_incorrect"} = nan;
    t_s{and(string(t_s.Date) == sd,t_s.Session == t_s.Session(k)),"correct_rate"} = nan;
end   
t = t_s;
end