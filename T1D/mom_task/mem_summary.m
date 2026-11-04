function memTaskSummarySheet = mem_summary(M_train,M_test,study_cog,file_path)

%load('Memory Task Data/M_train.mat');
trainProcessed = processTrain(M_train,file_path);

%load('Memory Task Data/M_test.mat');
testProcessed = processTest(M_test,file_path);

%load('Memory Task Data/study_sheet.mat');
compiledStudySheet = compileStudySheet(study_cog, trainProcessed, testProcessed,file_path);
compiledStudySheet = movevars(compiledStudySheet, 'date', 'After', 'StudyWeek');

processedData = processStudySheet(compiledStudySheet);
memTaskSummarySheet = summary(processedData);
if ~exist([file_path '\Cog_Tasks\postprocessed\Memory_Task\'],'dir')
    mkdir([file_path '\Cog_Tasks\postprocessed\Memory_Task\'])
end
writetable(memTaskSummarySheet, [file_path '\Cog_Tasks\postprocessed\Memory_Task\memory_task_summary.csv']); 
function result = summary(data)
    % Initialize table
    result = table;
    currentRow = 1;
    
    sids = unique(data.SID);

    % For each subject
    for i = 1:height(sids)
        sidData = data(data.SID == sids(i), :);
        
        % Create unique test sessions by combining date and AMPM
        % This handles cases where empty data has same timestamp (00:00:00)
        % but different AMPM values indicating different test sessions
        sidData.testSession = strcat(string(sidData.date), '_', string(sidData.AMPM));
        uniqueSessions = unique(sidData.testSession);

        for j = 1:height(uniqueSessions)
            testData = sidData(sidData.testSession == uniqueSessions(j), :);
           
            result.sid{currentRow} = testData.SID(1);
            result.study_week{currentRow} = testData.StudyWeek(1);
            result.sex{currentRow} = testData.Sex(1);
            result.sex_1{currentRow} = testData.Sex_1(1);
            result.age{currentRow} = testData.Age(1);
            result.burst_day{currentRow} = string(testData.Burst_Day_(1));
            result.ethnicity{currentRow} = testData.Ethnicity(1);
            result.day{currentRow} = testData.DayofWeek(1);
            result.day_code{currentRow} = testData.DayofWeek_code(1);
            result.weekday_weekend{currentRow} = testData.WeekdayWeekend(1);
            result.weekday_weekend_code{currentRow} = testData.WeekdayWeekend_coded(1);
            result.day_code{currentRow} = string(testData.date(1));
            result.sleep_wake_condition{currentRow} = testData.Sleep_Wake_condition(1);
            result.ampm{currentRow} = testData.AMPM(1);
            result.test_type{currentRow} = testData.test_type(1);

            tiles = testData.tiles(1);
            result.tiles{currentRow} = tiles{1};

            if isempty(tiles{1})
                length = NaN;
                result.grid_size{currentRow} = length;
                result.avg_reaction_time{currentRow} = '';
                result.std_reaction_time{currentRow} = '';
                result.total_correct{currentRow} = NaN;
                result.avg_accuracy{currentRow} = NaN;
                result.std_accuracy{currentRow} = NaN;
                result.avg_incorrect{currentRow} = NaN;
                result.std_incorrect{currentRow} = NaN;
                result.first_test_correct_rate{currentRow} = NaN;
                result.second_test_correct_rate{currentRow} = NaN;
                result.correctness_improvement_rate{currentRow} = NaN;
                result.avg_correctness_change{currentRow} = NaN;
                result.std_correctness_change{currentRow} = NaN;
                result.corresponding_train_test{currentRow} = '';
                result.test_type{currentRow} = '';

            else

                length = height(testData);
                result.grid_size{currentRow} = length;
    
                % Reaction time calculations with std
                timeStrings = cellfun(@string, testData.reaction_time);
                timeDurations = duration(timeStrings, 'InputFormat', 'mm:ss.SSS');
                avgReactionTime = mean(timeDurations);
                stdReactionTime = std(timeDurations);
                formattedAvg = string(avgReactionTime, 'mm:ss.SSS');
                formattedStd = string(stdReactionTime, 'mm:ss.SSS');
                result.avg_reaction_time{currentRow} = formattedAvg;
                result.std_reaction_time{currentRow} = formattedStd;
    
                totalCorrect = sum(cell2mat(testData.is_correct));
                result.total_correct{currentRow} = totalCorrect;
                
                % Accuracy calculations with std
                accuracyValues = cell2mat(testData.accuracy_manhattan);
                avgAccuracy = sum(accuracyValues) / length;
                stdAccuracy = std(accuracyValues);
                
                incorrect = accuracyValues(accuracyValues ~= 0);
                avgIncorrect = sum(incorrect) / height(incorrect);
                stdIncorrect = std(incorrect);
                
                if isnan(avgIncorrect)
                    avgIncorrect = 0;
                    stdIncorrect = 0;
                end
                if isnan(stdIncorrect)
                    stdIncorrect = 0;
                end
                
                result.avg_accuracy{currentRow} = avgAccuracy;
                result.std_accuracy{currentRow} = stdAccuracy;
                result.avg_incorrect{currentRow} = avgIncorrect;
                result.std_incorrect{currentRow} = stdIncorrect;
                
                % Calculate correctness metrics for this test
                first_correct = cell2mat(testData.first_test_correct);
                second_correct = cell2mat(testData.second_test_correct);
                correctness_changes = cell2mat(testData.correctness_change_numeric);
                
                % Remove NaN values for calculations
                valid_first = first_correct(~isnan(first_correct));
                valid_second = second_correct(~isnan(second_correct));
                valid_changes = correctness_changes(~isnan(correctness_changes));
                
                % Calculate rates and averages
                if ~isempty(valid_first)
                    result.first_test_correct_rate{currentRow} = mean(valid_first);
                else
                    result.first_test_correct_rate{currentRow} = NaN;
                end
                
                if ~isempty(valid_second)
                    result.second_test_correct_rate{currentRow} = mean(valid_second);
                else
                    result.second_test_correct_rate{currentRow} = NaN;
                end
                
                if ~isempty(valid_changes)
                    % Rate of improvement (percentage that improved)
                    improvements = sum(valid_changes == 1);
                    result.correctness_improvement_rate{currentRow} = improvements / numel(valid_changes);
                    
                    % Average change and standard deviation
                    result.avg_correctness_change{currentRow} = mean(valid_changes);
                    result.std_correctness_change{currentRow} = std(valid_changes);
                else
                    result.correctness_improvement_rate{currentRow} = NaN;
                    result.avg_correctness_change{currentRow} = NaN;
                    result.std_correctness_change{currentRow} = NaN;
                end
    
                correspondingTest = testData.corresponding_train_test(1);
                correspondingTest = correspondingTest{1};
                if height(correspondingTest) > 0
                    correspondingTest = correspondingTest(1:3);
                end
                result.corresponding_train_test{currentRow} = correspondingTest;
            end

            currentRow = currentRow + 1;
        end
    end

    % Calculate deltas (differences between consecutive tests)
    for i = 1:height(result)
        corresponding = result.corresponding_train_test(i);
        corresponding = corresponding{1};
        if isempty(corresponding)
            result.delta_avg_reaction_time{i} = NaN;
            result.delta_std_reaction_time{i} = NaN;
            result.delta_total_correct{i} = NaN;
            result.delta_avg_accuracy{i} = NaN;
            result.delta_std_accuracy{i} = NaN;
            result.delta_avg_incorrect{i} = NaN;
            result.delta_std_incorrect{i} = NaN;
            result.delta_first_test_correct_rate{i} = NaN;
            result.delta_second_test_correct_rate{i} = NaN;
            result.delta_correctness_improvement_rate{i} = NaN;
            result.delta_avg_correctness_change{i} = NaN;
            result.delta_std_correctness_change{i} = NaN;
            continue
        end
        
        % Delta reaction time calculations
        avgReaction = result.avg_reaction_time;
        stdReaction = result.std_reaction_time;
        
        currAvgReactionTime = avgReaction(i);
        currAvgReactionTime = currAvgReactionTime{1};
        currAvgReactionTime = duration(currAvgReactionTime, 'InputFormat', 'mm:ss.SSS');
        
        currStdReactionTime = stdReaction(i);
        currStdReactionTime = currStdReactionTime{1};
        currStdReactionTime = duration(currStdReactionTime, 'InputFormat', 'mm:ss.SSS');
        
        prevAvgReactionTime = avgReaction(i - 1);
        prevAvgReactionTime = prevAvgReactionTime{1};
        prevAvgReactionTime = duration(prevAvgReactionTime, 'InputFormat', 'mm:ss.SSS');
        
        prevStdReactionTime = stdReaction(i - 1);
        prevStdReactionTime = prevStdReactionTime{1};
        prevStdReactionTime = duration(prevStdReactionTime, 'InputFormat', 'mm:ss.SSS');
        
        deltaAvgReactionTime = currAvgReactionTime - prevAvgReactionTime;
        deltaStdReactionTime = currStdReactionTime - prevStdReactionTime;
        
        deltaAvgReactionTime = string(deltaAvgReactionTime, 'mm:ss.SSS');
        deltaStdReactionTime = string(deltaStdReactionTime, 'mm:ss.SSS');
        
        result.delta_avg_reaction_time{i} = deltaAvgReactionTime;
        result.delta_std_reaction_time{i} = deltaStdReactionTime;

        % Delta total correct (no std needed - it's a count)
        totalCorrect = result.total_correct;
        currTotalCorrect = totalCorrect(i);
        currTotalCorrect = currTotalCorrect{1};
        prevTotalCorrect = totalCorrect(i - 1);
        prevTotalCorrect = prevTotalCorrect{1};
        deltaTotalCorrect = currTotalCorrect - prevTotalCorrect;
        result.delta_total_correct{i} = deltaTotalCorrect;

        % Delta accuracy calculations
        avgAccuracy = result.avg_accuracy;
        stdAccuracy = result.std_accuracy;
        
        currAvgAccuracy = avgAccuracy(i);
        currAvgAccuracy = currAvgAccuracy{1};
        currStdAccuracy = stdAccuracy(i);
        currStdAccuracy = currStdAccuracy{1};
        
        prevAvgAccuracy = avgAccuracy(i - 1);
        prevAvgAccuracy = prevAvgAccuracy{1};
        prevStdAccuracy = stdAccuracy(i - 1);
        prevStdAccuracy = prevStdAccuracy{1};
        
        deltaAvgAccuracy = currAvgAccuracy - prevAvgAccuracy;
        deltaStdAccuracy = currStdAccuracy - prevStdAccuracy;
        
        result.delta_avg_accuracy{i} = deltaAvgAccuracy;
        result.delta_std_accuracy{i} = deltaStdAccuracy;

        % Delta incorrect calculations
        avgIncorrect = result.avg_incorrect;
        stdIncorrect = result.std_incorrect;
        
        currAvgIncorrect = avgIncorrect(i);
        currAvgIncorrect = currAvgIncorrect{1};
        currStdIncorrect = stdIncorrect(i);
        currStdIncorrect = currStdIncorrect{1};
        
        prevAvgIncorrect = avgIncorrect(i - 1);
        prevAvgIncorrect = prevAvgIncorrect{1};
        prevStdIncorrect = stdIncorrect(i - 1);
        prevStdIncorrect = prevStdIncorrect{1};
        
        deltaAvgIncorrect = currAvgIncorrect - prevAvgIncorrect;
        deltaStdIncorrect = currStdIncorrect - prevStdIncorrect;
        
        result.delta_avg_incorrect{i} = deltaAvgIncorrect;
        result.delta_std_incorrect{i} = deltaStdIncorrect;
        
        % Delta correctness calculations
        firstTestRate = result.first_test_correct_rate;
        secondTestRate = result.second_test_correct_rate;
        improvementRate = result.correctness_improvement_rate;
        avgCorrectnessChange = result.avg_correctness_change;
        stdCorrectnessChange = result.std_correctness_change;
        
        % Current values
        currFirstRate = firstTestRate(i);
        currFirstRate = currFirstRate{1};
        currSecondRate = secondTestRate(i);
        currSecondRate = currSecondRate{1};
        currImprovementRate = improvementRate(i);
        currImprovementRate = currImprovementRate{1};
        currAvgChange = avgCorrectnessChange(i);
        currAvgChange = currAvgChange{1};
        currStdChange = stdCorrectnessChange(i);
        currStdChange = currStdChange{1};
        
        % Previous values
        prevFirstRate = firstTestRate(i - 1);
        prevFirstRate = prevFirstRate{1};
        prevSecondRate = secondTestRate(i - 1);
        prevSecondRate = prevSecondRate{1};
        prevImprovementRate = improvementRate(i - 1);
        prevImprovementRate = prevImprovementRate{1};
        prevAvgChange = avgCorrectnessChange(i - 1);
        prevAvgChange = prevAvgChange{1};
        prevStdChange = stdCorrectnessChange(i - 1);
        prevStdChange = prevStdChange{1};
        
        % Calculate deltas
        result.delta_first_test_correct_rate{i} = currFirstRate - prevFirstRate;
        result.delta_second_test_correct_rate{i} = currSecondRate - prevSecondRate;
        result.delta_correctness_improvement_rate{i} = currImprovementRate - prevImprovementRate;
        result.delta_avg_correctness_change{i} = currAvgChange - prevAvgChange;
        result.delta_std_correctness_change{i} = currStdChange - prevStdChange;
    end
end
end

