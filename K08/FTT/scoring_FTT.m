function [x, y, z] = scoring_FTT(result,target,strokes)
correct = 0;
a = 1;
consec = false;
reaction_time = [];
first = false;
consec_error = false;
error = 0;
for i = 1:length(result)
    if isempty(char(result(i))) == 1 
        if a+length(char(target))-1 <= length(strokes)
            correct = correct + 1;
            time = strokes(a+length(char(target))-1) - strokes(a);
            time = datetime(time/1000,"ConvertFrom","posixtime","Format","uuuu-MM-dd'T'HH:mm:ss.SSSSSS");
            time = second(time);
            time = datenum(time) * 1000;
            reaction_time(end + 1) = time;
            a = a + length(char(target));
            if i == 1
                first = true;
            elseif first == false && i ~= 1
                consec = true;
                consec_error = false;
            end
        end
    else
        if consec == true && first == false || consec_error == true
            correct = correct + 1;
            time = strokes(a + length(char(target))-1) - strokes(a);
            time = datetime(time/1000,"ConvertFrom","posixtime","Format","uuuu-MM-dd'T'HH:mm:ss.SSSSSS");
            time = second(time);
            time = datenum(time) * 1000;
            reaction_time(end + 1) = time;
            a = a + length(char(target));
        end
        a = a + length(char(result(i)));
        error = error + length(char(result(i)));
        consec = false;
        consec_error = true;
        first = false;
    end
end
x = correct;
y = error;
z = reaction_time;
end