function pre = update_WPA(WPA_train, WPA_test, file_path)
% Expands each WPA session (training, then testing) into one row per trial,
% adds the 1x2 wordpair and the session's wordpair_sets, then saves CSV and
% MAT copies.
%
% Faster version: no table growth inside loops (rows are collected and
% concatenated once), and the per-trial loop fills a plain string array
% instead of writing into the table one row at a time.
% Output columns, order and values are meant to match the original.

srcs = {WPA_train, WPA_test};
srcParts = cell(1, 2);

for s = 1:2
    copy = srcs{s};
    nR = height(copy);
    parts = cell(nR, 1);
    counts = zeros(nR, 1);
    for i = 1:nR
        c = struct2table(copy{i, "wpa_testing"}{1});
        wp = c.wordPair;
        n = numel(wp);

        w = strings(n, 2);
        for j = 1:n
            p = string(wp{j});
            w(j, :) = p(:).';
        end

        % Same as the original: a 2x30 grid, padded with "" if a session
        % has fewer than 30 trials (and wider if it has more)
        wp_t = strings(2, max(30, n));
        wp_t(:, 1:n) = w.';

        c.wordpair = w;          % appended, then wordPair removed: same column order as before
        c.wordPair = [];
        c.wordpair_sets = repmat({[wp_t(1, :) wp_t(2, :)]}, n, 1);

        parts{i} = c;
        counts(i) = n;
    end
    meta = copy(repelem((1:nR)', counts), ["user","test_type","started_at","finished_at"]);
    srcParts{s} = [meta, vertcat(parts{:})];
end

pre = vertcat(srcParts{:});
pre = renamevars(pre, "user", "SID");
pre.SID = double(string(pre.SID));

conf = string(pre.confidence);
pre.confidence_rate = 3*(conf == "HIGH") + 2*(conf == "MODERATE") + 1*(conf == "LOW");

pre.date = datetime(pre.started_at/1000, "ConvertFrom", "posixtime", ...
    "Format", "dd-MMM-yyyy", "TimeZone", "local");

cog_path = fullfile(file_path, 'Cog_Tasks', 'preprocessed');
if ~isfolder(cog_path)
    mkdir(cog_path);
end
writetable(pre, fullfile(cog_path, 'WPA_preprocessed.csv'));
save(fullfile(cog_path, 'WPA_preprocessed.mat'), "pre");
end
