% Memory Task Study Sheet Compiling
% Matthew Blam
% blammatthew@gmail.com

% Dependencies: processTrain, processTest

function result = compileStudySheet(studySheet, trainProcessed, testProcessed,file_path)
    % Table metadata
    tableHeight = height(studySheet);

    sheetVarNames = studySheet.Properties.VariableNames;
    sheetVarTypes = {};
    for i = 1:length(sheetVarNames)
        sheetVarTypes{end+1} = class(studySheet{1,sheetVarNames{i}});
    end

    dateIndex = strcmp(sheetVarNames, 'Date');
    sheetVarNames = sheetVarNames(~dateIndex);
    sheetVarTypes = sheetVarTypes(~dateIndex);

    dataVarNames = trainProcessed.Properties.VariableNames;
    dataVarTypes = {};
    for i = 1:length(dataVarNames)
        dataVarTypes{end+1} = class(trainProcessed{1,dataVarNames{i}});
    end
    userIndex = strcmp(dataVarNames, 'user');
    dataVarNames = dataVarNames(~userIndex);
    dataVarTypes = dataVarTypes(~userIndex);

    varNames = [sheetVarNames, dataVarNames];
    varTypes = [sheetVarTypes, dataVarTypes];

    % Identify and convert char columns to string
    for i = 1:numel(varNames)
        if strcmp(varTypes{i}, 'char')
            studySheet.(varNames{i}) = string(studySheet.(varNames{i}));
            varTypes{i} = 'string'; % Update variable type
        end
    end
    
    % Set this according to app max grid length
    MAX_GRID_LENGTH = 4;
    
    % Preallocate result table with same fields
    newTableSize = tableHeight * MAX_GRID_LENGTH^2;
    result = table('Size', [newTableSize, numel(varNames)], ...
        'VariableNames', varNames, ...
        'VariableTypes', varTypes);
    result.date = datetime(result.date, 'TimeZone', 'America/Los_Angeles');
    
    % Initialize indices for filling the result table
    currentRow = 1;

    for i = 1:tableHeight
        rowData = studySheet(i, :);
        ampm = rowData.AMPM;
        sleepWake = rowData.Sleep_Wake_condition;

        if sleepWake == 1
            if ampm == "PM"
                data = trainProcessed;
            elseif ampm == "AM"
                data = testProcessed;
            else
                continue;
            end
        elseif sleepWake == 0
            if ampm == "AM"
                data = trainProcessed;
            elseif ampm == "PM"
                data = testProcessed;
            else
                continue;
            end
        end


        % Evil one-liner
        matchingDateData = data(string(datetime(data.date, 'InputFormat','dd-MMM-yyyy HH:mm:ss', 'Format','dd-MMM-yyyy')) == string(rowData.Date), :);
        matchingDateData = matchingDateData(string(matchingDateData.user) == string(rowData.SID), :);
        testData = table;

        % Get test data for single test (ignore same-day duplicate tests)
        if ~isempty(matchingDateData)
            sleepWake = rowData.Sleep_Wake_condition;

            % For sleep-wake cycle
            if sleepWake == 1
                % Get the latest test on that day for PM
                if ampm == "PM"
                    tiles = matchingDateData.tiles;
                    last = tiles{length(tiles)};
                    gridLength = size(last, 1);
        
                    dataLength = length(matchingDateData.is_correct);
                    testData = matchingDateData(dataLength - gridLength^2 + 1:dataLength, :);
                end

                % Get the earliest test on that day for AM
                if ampm == "AM"
                    tiles = matchingDateData.tiles;
                    first = tiles{1};
                    gridLength = size(first, 1);
        
                    testData = matchingDateData(1:gridLength^2, :);
                end
            end

            % For wake-sleep cycle
            if sleepWake == 0
                % Get the earliest test on that day for PM
                if ampm == "PM"
                    tiles = matchingDateData.tiles;
                    first = tiles{1};
                    gridLength = size(first, 1);
        
                    testData = matchingDateData(1:gridLength^2, :);
                end

                % Get the latest test on that day for AM
                if ampm == "AM"
                    tiles = matchingDateData.tiles;
                    last = tiles{length(tiles)};
                    gridLength = size(last, 1);
        
                    dataLength = length(matchingDateData.is_correct);
                    testData = matchingDateData(dataLength - gridLength^2 + 1:dataLength, :);
                end
            end
        end
        
        % Fill result table with combined data
        if ~isempty(testData)
            rowData = rowData(:, ismember(rowData.Properties.VariableNames, sheetVarNames));
            rowData = repelem(rowData, height(testData),1);
            testData = testData(:, ismember(testData.Properties.VariableNames, dataVarNames));
            
            combined = [rowData, testData];
            result(currentRow: currentRow + height(combined) - 1, :) = combined;
            currentRow = currentRow + height(combined);
        else
            date = rowData.Date;
            date.TimeZone = 'America/Los_Angeles';
            rowData = rowData(:, ismember(rowData.Properties.VariableNames, sheetVarNames));
            numVars = numel(dataVarNames);
            testData = table('Size', [1, numVars], 'VariableNames', dataVarNames, 'VariableTypes', dataVarTypes);

            combined = [rowData, testData];
            combined.date = date;
            result(currentRow, :) = combined;
            currentRow = currentRow + 1;
        end
    end
    % Trim unused rows in table
    result = result(1:currentRow - 1, :);
    if ~exist([file_path '\Cog_Tasks\postprocessed\Memory_Task'],'dir')
        mkdir([file_path '\Cog_Tasks\postprocessed\Memory_Task']);
    end
    save([file_path '\Cog_Tasks\postprocessed\Memory_Task\memory_task_compiled.mat'],'result')
end