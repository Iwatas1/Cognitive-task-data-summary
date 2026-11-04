% Memory Task Test Data Pre-Processing
% Matthew Blam
% blammatthew@gmail.com

function result = processTest(rawData,file_path)
    % Table metadata
    tableHeight = height(rawData);
    varNames = rawData.Properties.VariableNames;
    varTypes = {};
    for i = 1:length(varNames)
        varTypes{end+1} = class(rawData{1,varNames{i}});
    end

    memTestingIndex = strcmp(varNames, 'mem_testing');
    varNames = varNames(~memTestingIndex);
    varTypes = varTypes(~memTestingIndex);

    % Set this according to app max grid length
    MAX_GRID_LENGTH = 4;
    
    % Force mem_testing to be a cell array
    memTestingIdx = find(strcmp(varNames, 'mem_testing'));
    if ~isempty(memTestingIdx)
        varTypes{memTestingIdx} = 'cell';
    end

    % Preallocate result table with same fields
    newTableSize = tableHeight * MAX_GRID_LENGTH^2;
    result = table('Size', [newTableSize, numel(varNames)], ...
        'VariableNames', varNames, ...
        'VariableTypes', varTypes);
    
    % Initialize indices for filling the result table
    currentRow = 1;
    
    % Process each original row
    for i = 1:tableHeight
        % Unchanged columns for the current row
        userData = rawData.user(i);
        testTypeData = rawData.test_type(i);
        startedAtData = rawData.started_at(i);
        finishedAtData = rawData.finished_at(i);
    
        % Get testing data
        memTestingData = rawData.mem_testing(i);
        
        % Create tiles column
        grid = memTestingData.grid;
        gridLength = length(grid);
        tiles = cell(gridLength, gridLength);
        for j = 1:gridLength
            for k = 1:gridLength
                tiles(j, k) = {(grid{j}{k})};
            end
        end
        tilesData = tiles;
        
        % Create date column
        dateData = datetime(finishedAtData / 1000, 'ConvertFrom', 'posixtime', 'TimeZone', 'America/Los_Angeles');
        
        % Process answer columns for n moves depending on grid
        for move = 1:(gridLength^2)
            % Copy unchanged columns
            result.user(currentRow) = userData;
            result.test_type(currentRow) = testTypeData;
            result.started_at(currentRow) = startedAtData;
            result.finished_at(currentRow) = finishedAtData;
            % result.mem_testing{currentRow} = memTestingData;
            result.tiles{currentRow} = tilesData;
            result.date(currentRow) = dateData;
    
            % Populate reactionTime, subjectResponse, trueLocation, isCorrect
            sequence = memTestingData.sequence;
            sequence = sequence(move);
    
            start = sequence.start;
            time = sequence.time;
            difference = (time / 1000) - (start / 1000);
            reactionTime = string(duration(0, 0, difference, 'Format', 'mm:ss.SSS'));
            
            subjResp = sequence.subjResp;
            srRow = subjResp.row + 1;
            srCol = subjResp.col + 1;
            subjectResponseRowCol = [srRow srCol];
            subjectResponseTile = grid{srRow}{srCol};
            
            trueLoc = sequence.trueLoc;
            tlRow = trueLoc.row + 1;
            tlCol = trueLoc.col + 1;
            trueLocationRowCol = [tlRow tlCol];
            trueLocationTile = grid{tlRow}{tlCol};
    
            isCorrect = sequence.isCorrect;
            accuracyManhattan = -1 * manhattanDistance(trueLocationRowCol, subjectResponseRowCol);
    
            result.reaction_time{currentRow} = reactionTime;
            result.subject_response_row_col{currentRow} = subjectResponseRowCol;
            result.subject_response_tile{currentRow} = subjectResponseTile;
            result.true_location_row_col{currentRow} = trueLocationRowCol;
            result.true_location_tile{currentRow} = trueLocationTile;
            result.is_correct{currentRow} = isCorrect;
            result.accuracy_manhattan{currentRow} = accuracyManhattan;
    
            % Increment row counter
            currentRow = currentRow + 1;
        end
    end
    writetable(result,[file_path '\Cog_Tasks\preprocessed\M_task_test_preprocessed.csv'])
    save([file_path '\Cog_Tasks\preprocessed\M_task_test_preprocessed.mat'],"result")
end

% Calculate manhattan distance between two points
function MD = manhattanDistance(p1, p2)
    x1 = p1(1, 1);
    y1 = p1(1, 2);
    x2 = p2(1, 1);
    y2 = p2(1, 2);
    MD = abs(x1 - x2) + abs(y1 - y2);
end
