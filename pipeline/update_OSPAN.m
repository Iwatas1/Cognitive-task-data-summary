function y = update_OSPAN(OSPAN, file_path)
% Expands each OSPAN row into one row per math trial plus one letter-recall
% ("bottom") row per set, for ospan_1..ospan_3, then saves CSV and MAT copies.
%
% Faster version: each trial is edited as a plain struct (cheap) instead of
% through ~15 table operations, converted to a table once, and all rows are
% concatenated once instead of growing tables inside the loops.
% Output columns, order and types are meant to match the original.

nR = height(OSPAN);
bodyParts = cell(nR, 1);
counts = zeros(nR, 1);
last = [];   % most recent kept trial row (was test / test_sub)

for i = 1:nR
    rows = {};
    for j = 1:3
        task = char("ospan_" + j);
        A = OSPAN{i, task}{1};
        for k = 1:height(A)
            blk = A{k};
            for l = 1:height(blk)-1
                r = blk{l};
                if numel(fieldnames(r)) <= 4
                    continue        % original skipped these rows too
                end
                r = process_trial(r, task);
                last = r;
                rows{end+1, 1} = r; %#ok<AGROW>
            end
            if isempty(last)
                error("update_OSPAN: no valid trial before the first letter-recall row (OSPAN row %d, %s, set %d).", i, task, k);
            end
            rows{end+1, 1} = make_bottom(blk{end}, last); %#ok<AGROW>
        end
    end
    T = cellfun(@(s) struct2table(s, "AsArray", true), rows, "UniformOutput", false);
    bodyParts{i} = vertcat(T{:});
    counts(i) = numel(rows);
end

body = vertcat(bodyParts{:});
meta = OSPAN(repelem((1:nR)', counts), ["user","started_at","finished_at"]);
pre_prosess = [meta, body];

col_names = pre_prosess.Properties.VariableNames;
col_names([4:5 6:end]) = col_names([end-1:end 4:end-2]);
col_names([6:7 8]) = col_names([7:8 6]);
y = pre_prosess(:, col_names);

cog_path = fullfile(file_path, 'Cog_Tasks', 'preprocessed');
if ~isfolder(cog_path)
    mkdir(cog_path);
end
writetable(y, fullfile(cog_path, 'OSPAN_preprocessed.csv'));
save(fullfile(cog_path, 'OSPAN_preprocessed.mat'), "y");
end

%% ---------------------------------------------------------------------
function r = process_trial(r, task)
% Same steps as the original table code, in the same order, so the field
% order (and therefore the column order) is unchanged.
eqs = r.equation;
eq = char(string(eqs.a) + " " + string(char(eqs.operator)) + " " + ...
    string(eqs.b) + " = " + string(eqs.result));
r = rmfield(r, 'equation');
r.equation = {eq};
r.letter = wrap_like_table(r.letter);

if r.correctAnswer == 1
    r.user_is_correct = {'True'};
else
    r.user_is_correct = {'False'};
end
r.math_correct = eqs.isCorrect;

if r.missed == 1
    r.choice_0 = {'missed'};
    r = rmfield(r, {'correctAnswer', 'missed'});
    r = rename_fields(r, {'choice_0', 'startTime'}, {'choice', 'user_start_time'});
    r.user_input_time = NaN;
else
    if r.choice == 1
        r.choice_0 = {'True'};
    else
        r.choice_0 = {'False'};
    end
    r = rmfield(r, {'correctAnswer', 'choice', 'missed'});
    r = rename_fields(r, {'choice_0', 'decisionTime', 'startTime'}, ...
        {'choice', 'user_input_time', 'user_start_time'});
end

r.problem_set  = {task};
r.user_letters = {''};
r.letters      = {''};
end

function b = make_bottom(rawEnd, last)
% Letter-recall row: recall fields first, then the last trial's fields
% (minus the four the recall row supplies), with the trial values blanked.
b = rename_fields(rawEnd, {'input', 'inputTime', 'startTime'}, ...
    {'user_letters', 'user_input_time', 'user_start_time'});
t = rmfield(last, {'user_input_time', 'user_start_time', 'user_letters', 'letters'});
b = cell2struct([struct2cell(b); struct2cell(t)], [fieldnames(b); fieldnames(t)], 1);

b.letter = {' '};
b.equation = {''};
m = b.math_correct;  m(1) = 0;  b.math_correct = m;   % keeps logical/double type
b.user_is_correct = {''};
b.choice = {''};
b.user_letters = wrap_like_table(b.user_letters);
b.letters      = wrap_like_table(b.letters);
end

function out = wrap_like_table(v)
% Reproduces the original  t.x = {t{1,"x"}}  pattern: struct2table stores a
% non-scalar value (e.g. 'ABC') in a cell, so the original ended up with one
% extra level of cell for those. Scalars ('A', 5) get a single cell.
if ~isscalar(v)
    v = {v};
end
out = {v};
end

function s = rename_fields(s, oldNames, newNames)
% Renames struct fields in place, keeping field order (like renamevars).
f = fieldnames(s);
c = struct2cell(s);
[found, loc] = ismember(oldNames, f);
if ~all(found)
    error("update_OSPAN: missing field(s): %s", strjoin(oldNames(~found), ", "));
end
f(loc) = newNames;
s = cell2struct(c, f, 1);
end
