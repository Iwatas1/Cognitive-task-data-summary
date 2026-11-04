function y = update_FTT(FTT, file_path)
% Expands each FTT row into one row per finger-tap trial, scores each
% trial, then saves CSV and MAT copies.
%
% Faster version: no table growth inside loops, and scoring results are
% collected in plain arrays and written to the table once at the end.

%% 1. Expand finger_tap structs (one concatenation instead of one per row)
nR = height(FTT);
fingerParts = cell(nR, 1);
counts = zeros(nR, 1);
for i = 1:nR
    fingerParts{i} = struct2table(FTT.finger_tap{i});
    counts(i) = height(fingerParts{i});
end
finger = vertcat(fingerParts{:});
meta = FTT(repelem((1:nR)', counts), ["user","started_at","finished_at","test_type"]);
new_FTT = [meta, finger];

new_FTT.date = datetime(new_FTT.startTime/1000, "ConvertFrom", "posixtime", ...
    "Format", "MM/dd/uuuu HH:mm:ss", "TimeZone", "America/Los_Angeles");

%% 2. Score each trial into preallocated arrays
n = height(new_FTT);
inputs  = new_FTT.input;      % pull columns out once; indexing a table
targets = new_FTT.target;     % row by row is the slow part
strokes = new_FTT.strokes;

score        = zeros(n, 1);
err          = zeros(n, 1);
test_trial   = cell(n, 1);
fastest_time = NaN(n, 1);     % stays NaN when score == 0
slowest_time = NaN(n, 1);
ave_time     = NaN(n, 1);
std_time     = NaN(n, 1);

for i = 1:n
    target = string(targets{i});
    result = split(string(inputs{i}), target);
    [s, e, time] = scoring_FTT(result, target, strokes{i});
    score(i) = s;
    err(i) = e;
    test_trial{i} = time;
    if s ~= 0
        fastest_time(i) = min(time);
        slowest_time(i) = max(time);
        ave_time(i)     = mean(time);
        std_time(i)     = std(time);
    end
end

%% 3. Attach all new columns at once
new_FTT.score        = score;
new_FTT.error        = err;
new_FTT.test_trial   = test_trial;
new_FTT.fastest_time = fastest_time;
new_FTT.slowest_time = slowest_time;
new_FTT.ave_time     = ave_time;
new_FTT.std_time     = std_time;

y = new_FTT;

cog_path = fullfile(file_path, 'Cog_Tasks', 'preprocessed');
if ~isfolder(cog_path)
    mkdir(cog_path);
end
writetable(y, fullfile(cog_path, 'FTT_preprocessed.csv'));
save(fullfile(cog_path, 'FTT_preprocessed.mat'), "y");
end