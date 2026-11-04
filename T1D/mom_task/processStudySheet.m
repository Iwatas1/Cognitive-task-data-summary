cfg = study_config();
% Memory Task Study Sheet Processing
% Matthew Blam
% blammatthew@gmail.com

% Dependencies: processTrain, processTest, compileStudySheet

function result = processStudySheet(studySheet)
    result = studySheet;

    % Get all PM rows belonging to wake-sleep condition
    % And fill corresponding tests
    sids = studySheet(ismember(studySheet.AMPM, "PM"), :);
    sids = sids(ismember(sids.Sleep_Wake_condition, 0), :);

    for i = 1:height(sids)
        rowData = sids(i, :);

        sid = rowData.SID;
        date = rowData.date;
        indices = find( ...
            result.SID == sid & ...
            result.date == date & ...
            result.AMPM == "PM");
        corrDate = [dateWithTimeToString(date), dateWithTimeToString(date - caldays(1))];

        for j = 1:length(indices)
            idx = indices(j);
            result.corresponding_train_test{idx} = {sid, "AM", corrDate, result.true_location_tile{idx}};
        end
    end

    % Get all AM rows belonging to sleep-wake condition
    sids = studySheet(ismember(studySheet.AMPM, "AM"), :);
    sids = sids(ismember(sids.Sleep_Wake_condition, 1), :);

    for i = 1:height(sids)
        rowData = sids(i, :);

        sid = rowData.SID;
        date = rowData.date;
        indices = find( ...
            result.SID == sid & ...
            result.date == date & ...
            result.AMPM == "AM");
        corrDate = [dateWithTimeToString(date), dateWithTimeToString(date - caldays(1))];

        for j = 1:length(indices)
            idx = indices(j);
            result.corresponding_train_test{idx} = {sid, "PM", corrDate, result.true_location_tile{idx}};
        end
    end

    % Calculate comparisons between corresponding tests
    for i = 1:height(result)
        rowData = result(i, :);

        % Check for a corresponding test
        correspondingTest = rowData.corresponding_train_test{1};
        if isempty(correspondingTest) | length(correspondingTest) < 4
            continue
        end
        sid = rowData.SID;
        cspAMPM = correspondingTest{2};
        cspDate = correspondingTest{3};
        cspTrueLocationTile = correspondingTest{4};

        sidMatch = result.SID == sid;
        ampmMatch = strcmp(result.AMPM, cspAMPM);
        tileMatch = strcmp(result.true_location_tile, cspTrueLocationTile);

        dateMatchLater = strcmp(dateWithTimeToString(result.date), cspDate(1));
        dateMatchEarlier = strcmp(dateWithTimeToString(result.date), cspDate(2));

        % Find the corresponding test location in table
        cspTestIndexLater = find( ...
            sidMatch & ...
            ampmMatch & ...
            dateMatchLater & ...
            tileMatch);

        cspTestIndexEarlier = find( ...
            sidMatch & ...
            ampmMatch & ...
            dateMatchEarlier & ...
            tileMatch);

        % See bottom of file for explanation
        if any(cspTestIndexLater) || any(cspTestIndexEarlier)
            if any(cspTestIndexLater) && any(cspTestIndexEarlier)
                cspTestIndex = cspTestIndexLater;
                result(i, :).corresponding_train_test{1}{3} = cspDate(1);
            elseif any(cspTestIndexLater)
                cspTestIndex = cspTestIndexLater;
                result(i, :).corresponding_train_test{1}{3} = cspDate(1);
            else
                cspTestIndex = cspTestIndexEarlier;
                result(i, :).corresponding_train_test{1}{3} = cspDate(2);
            end
        else
            continue
        end

        cspData = result(cspTestIndex, :); % Previous corresponding test

        if isempty(cspData)
            % This means there is a problem with the data, like if they
            % took a training test twice by mistake
            result.notes{i} = "data for this cycle cannot be used";
            continue
        end

        if ~strcmp(cspData.true_location_tile, rowData.true_location_tile)
            error('True tiles do not match');
        end

        % Calculate 
        prevIsCorrect = cspData.is_correct{1};
        currIsCorrect = rowData.is_correct{1};
        if (prevIsCorrect); prevIsCorrect = 'Right'; else; prevIsCorrect = 'Wrong'; end
        if (currIsCorrect); currIsCorrect = 'Right'; else; currIsCorrect = 'Wrong'; end
        differenceCorrectness = sprintf('%s then %s', prevIsCorrect, currIsCorrect);

        prevAccuracy = cspData.accuracy_manhattan{1};
        currAccuracy = rowData.accuracy_manhattan{1};
        differenceAccuracy = currAccuracy - prevAccuracy;
        
        prevResponse = cspData.subject_response_row_col{1};
        currResponse = rowData.subject_response_row_col{1};
        distanceResponse = manhattanDistance(prevResponse, currResponse);

        result.correctness_difference{i} = differenceCorrectness;
        result.accuracy_difference{i} = differenceAccuracy;
        result.response_distance{i} = distanceResponse;
        
    end
    
    % Add quantified correctness columns
    result.first_test_correct = cell(height(result), 1);
    result.second_test_correct = cell(height(result), 1);
    result.correctness_change_numeric = cell(height(result), 1);
    
    % Process each row to quantify correctness
    for i = 1:height(result)
        correctness_str = result.correctness_difference{i};
        
        if isempty(correctness_str) || strcmp(correctness_str, '')
            % No corresponding test data
            result.first_test_correct{i} = NaN;
            result.second_test_correct{i} = NaN;
            result.correctness_change_numeric{i} = NaN;
        else
            % Parse the correctness string (e.g., "Right then Right")
            parts = split(correctness_str, ' then ');
            
            if length(parts) == 2
                first_result = parts{1};   % "Right" or "Wrong"
                second_result = parts{2};  % "Right" or "Wrong"
                
                % Convert to numeric (1 = Right, 0 = Wrong)
                first_numeric = strcmp(first_result, 'Right');
                second_numeric = strcmp(second_result, 'Right');
                
                result.first_test_correct{i} = first_numeric;
                result.second_test_correct{i} = second_numeric;
                
                % Calculate change: -1 = got worse, 0 = no change, 1 = got better
                change = second_numeric - first_numeric;
                result.correctness_change_numeric{i} = change;
            else
                % Handle unexpected format
                result.first_test_correct{i} = NaN;
                result.second_test_correct{i} = NaN;
                result.correctness_change_numeric{i} = NaN;
            end
        end
    end
    save(fullfile(cfg.t1d_root,'Cog_Tasks\preprocessed\M_task_processedData.mat'),'result');
    %writetable(result,fullfile(cfg.t1d_root,'Cog_Tasks\preprocessed\M_task_processedData.xlsx'));
end

% Convert date to string of format dd-MMM-yyyy
function dateString = dateWithTimeToString(date)
    onlyDate = datetime(date, 'InputFormat','dd-MMM-yyyy HH:mm:ss', 'Format','dd-MMM-yyyy');
    dateString = string(onlyDate);
end

% Calculate manhattan distance between two points
function MD = manhattanDistance(p1, p2)
    x1 = p1(1, 1);
    y1 = p1(1, 2);
    x2 = p2(1, 1);
    y2 = p2(1, 2);
    MD = abs(x1 - x2) + abs(y1 - y2);
end


% for finding the corresponding test data using the date matching:

% sleep-wake
%
% we have our wake test
% our corrs traintest is either same day (past mindight late sleep)
% or day before (normal bedtime)
% corresponding test is PM so use same day (later) if both


% for wake-sleep
%
% we have our sleep test
% our corrs traintest is either same day (normal time) 
% or day before (sleep late past midnight)
% corresponding test is AM so use same day (later) if both