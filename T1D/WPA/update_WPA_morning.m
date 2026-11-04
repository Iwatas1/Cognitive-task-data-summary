function y = update_WPA_morning(WPA_morning, file_path)
% Expands each WPA morning row into one row per test trial, then saves
% CSV and MAT copies.
%
% Faster version: per-row tables are collected in a cell array and
% concatenated once, and the wordpair loop works on a plain cell array
% instead of indexing the table row by row.

nR = height(WPA_morning);
parts  = cell(nR, 1);
counts = zeros(nR, 1);

for i = 1:nR
    A = struct2table(WPA_morning.wpa_morning_testing{i, 1});
    parts{i}  = add_wordpair(A);
    counts(i) = height(A);
end

meta = WPA_morning(repelem((1:nR)', counts), :);
meta(:, 'wpa_morning_testing') = [];

new = [meta, vertcat(parts{:})];
new.date = datetime(new.started_at/1000, "ConvertFrom", "posixtime", ...
    "Format", "dd-MMM-uuuu", "TimeZone", "America/Los_Angeles");
y = new;

cog_path = fullfile(file_path, 'Cog_Tasks', 'preprocessed');
if ~isfolder(cog_path)
    mkdir(cog_path);
end
writetable(y, fullfile(cog_path, 'WPA_morning_preprocessed.csv'));
save(fullfile(cog_path, 'WPA_morning_preprocessed.mat'), "y");
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