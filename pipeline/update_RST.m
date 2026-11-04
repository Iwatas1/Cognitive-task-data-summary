function y = update_RST(RST, file_path)
% Expands each row of RST into one row per task entry (skipping the first
% element of each block), then saves CSV and MAT copies.
%
% Faster version: no table growth inside loops, and one struct2table call
% per block instead of one per row.

nR = height(RST);
taskParts = cell(nR, 1);
counts = zeros(nR, 1);

for i = 1:nR
    A = RST{i, 'rst'}{1};
    nA = height(A);
    parts = cell(nA, 1);
    for j = 1:nA
        B = A{j, 1};
        if numel(B) < 2
            parts{j} = table;          % no task rows in this block
        else
            parts{j} = structs2table(B(2:end));
        end
    end
    T = vertcat(parts{:});             % one concatenation per subject row
    taskParts{i} = T;
    counts(i) = height(T);
end

tasks = vertcat(taskParts{:});         % one concatenation overall

% Duplicate each RST row once per task row, in a single indexing step
meta = RST(repelem((1:nR)', counts), :);
meta.rst = [];

y = [meta, tasks];

cog_path = fullfile(file_path, 'Cog_Tasks', 'preprocessed');
if ~isfolder(cog_path)
    mkdir(cog_path);
end
writetable(y, fullfile(cog_path, 'RST_preprocessed.csv'));
save(fullfile(cog_path, 'RST_preprocessed.mat'), "y");
end

function T = structs2table(C)
% Fast path: stack the structs into one struct array and convert once.
% Fallback (fields differ in name or order): convert each and stack,
% which matches columns by name like the original code did.
C = C(:);
try
    T = struct2table(vertcat(C{:}), 'AsArray', true);
catch
    rows = cellfun(@(s) struct2table(s, 'AsArray', true), C, ...
        'UniformOutput', false);
    T = vertcat(rows{:});
end
end
