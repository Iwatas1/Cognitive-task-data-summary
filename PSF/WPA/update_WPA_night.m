function y = update_WPA_night(WPA_train, file_path)
% Expands each WPA night row into one row per test trial, stores the
% training pairs as a JSON string, then saves CSV and MAT copies.
%
% Faster version: per-row tables are collected in a cell array and
% concatenated once, and the wordpair loop works on a plain cell array
% instead of indexing the table row by row.

nR = height(WPA_train);
parts  = cell(nR, 1);
counts = zeros(nR, 1);
w_json = cell(nR, 1);

for i = 1:nR
    % Training pairs -> JSON string (one per subject row)
    pairs = WPA_train{i, "wpa_training"}.pairs;
    w_pairs = reshape(cellfun(@char, pairs, 'UniformOutput', false), 1, []);
    w_json{i} = jsonencode(w_pairs);

    % Night testing trials
    A = struct2table(WPA_train.wpa_night_testing{i, 1});
    parts{i}  = add_wordpair(A);
    counts(i) = height(A);
end

idx = repelem((1:nR)', counts);
meta = WPA_train(idx, :);
meta(:, ["wpa_night_testing", "wpa_training"]) = [];
meta.wpa_training = w_json(idx);    % same position and name as the old Var7 rename

new = [meta, vertcat(parts{:})];
new.date = datetime(new.started_at/1000, "ConvertFrom", "posixtime", ...
    "Format", "uuuu-MM-dd", "TimeZone", "America/Los_Angeles");
y = new;

cog_path = fullfile(file_path, 'Cog_Tasks', 'preprocessed');
if ~isfolder(cog_path)
    mkdir(cog_path);
end
writetable(y, fullfile(cog_path, 'WPA_night_preprocessed.csv'));
save(fullfile(cog_path, 'WPA_night_preprocessed.mat'), "y");
end

function A = add_wordpair(A)
% Replaces wordPair with a 2-column string variable 'wordpair' and moves
% the last two columns to the front (same logic as the original).
wp = A.wordPair;
n = height(A);
w = strings(n, 2);
for j = 1:n
    x = wp(j, :);
    w(j, 1) = string(x{1}{1});
    w(j, 2) = string(x{1}{2});
end
A.wordpair = w;
A(:, 'wordPair') = [];
columns = A.Properties.VariableNames;
columns([1:2 3:end]) = columns([end-1:end 1:end-2]);
A = A(:, columns);
end