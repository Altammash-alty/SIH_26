function [dataTbl, imds] = loadIDRiDGrading(split, baseDir)
% LOADIDRIDGRADING Loads IDRiD Disease Grading dataset (Train or Test set).
%
%   [DATATBL, IMDS] = DATA.LOADIDRIDGRADING() loads the IDRiD Training Set from
%   the default path 'data/idrid/grading/train'.
%
%   [DATATBL, IMDS] = DATA.LOADIDRIDGRADING(SPLIT) loads the specified split:
%       - 'train' (default): 413 training images + ground truth grades
%       - 'test'           : 103 held-out testing images + ground truth grades
%
%   [DATATBL, IMDS] = DATA.LOADIDRIDGRADING(SPLIT, BASEDIR) uses custom BASEDIR.
%
%   Outputs:
%       dataTbl - Table containing:
%                   .ImageName    - Base filename (e.g., 'IDRiD_001.jpg')
%                   .ImagePath    - Full filesystem path to image
%                   .DRGrade      - Numeric ICDR Grade (0 to 4)
%                   .RiskOfDME    - Numeric DME risk level (0 to 2)
%                   .ReferableDR  - Logical (true if DRGrade >= 2)
%       imds    - MATLAB imageDatastore with categorical labels for DR Grade.
%
%   Clinical Grading Standard:
%       0: No Apparent DR
%       1: Mild NPDR
%       2: Moderate NPDR (Referable)
%       3: Severe NPDR (Referable)
%       4: Proliferative DR (Referable)
%
%   Strict Data Governance:
%       Train and Test splits are kept strictly isolated to prevent data leakage.
%
%   Author: DR Screening Pipeline MVP
%   Date: 2026-09-02

    if nargin < 1 || isempty(split)
        split = 'train';
    end

    if nargin < 2 || isempty(baseDir)
        baseDir = fullfile('data', 'idrid', 'grading');
    end

    splitLower = lower(char(split));
    if ~ismember(splitLower, {'train', 'test'})
        error('loadIDRiDGrading:InvalidSplit', 'Split must be either ''train'' or ''test''.');
    end

    splitDir = fullfile(baseDir, splitLower);
    imgDir = fullfile(splitDir, 'images');
    csvFile = fullfile(splitDir, 'labels.csv');

    if ~exist(imgDir, 'dir')
        error('loadIDRiDGrading:DirNotFound', ...
            'Image directory not found at: %s. Please run organize_datasets.py first.', imgDir);
    end

    if ~exist(csvFile, 'file')
        error('loadIDRiDGrading:CsvNotFound', ...
            'Labels CSV file not found at: %s.', csvFile);
    end

    % 1. Read CSV Ground Truth Table
    rawTbl = readtable(csvFile, 'VariableNamingRule', 'preserve');

    % Auto-detect columns
    colNames = rawTbl.Properties.VariableNames;
    imgCol = colNames{1};
    gradeCol = colNames{2};
    dmeCol = '';

    for c = 1:numel(colNames)
        name = lower(colNames{c});
        if contains(name, 'image') || contains(name, 'id') || contains(name, 'file')
            imgCol = colNames{c};
        elseif contains(name, 'retinopathy') || contains(name, 'grade') || contains(name, 'dr')
            gradeCol = colNames{c};
        elseif contains(name, 'edema') || contains(name, 'dme') || contains(name, 'macular')
            dmeCol = colNames{c};
        end
    end

    nRows = height(rawTbl);
    imageNames = cell(nRows, 1);
    imagePaths = cell(nRows, 1);
    drGrades = zeros(nRows, 1);
    dmeRisks = zeros(nRows, 1);
    validMask = true(nRows, 1);

    for i = 1:nRows
        rawName = string(rawTbl.(imgCol)(i));
        if iscell(rawName), rawName = rawName{1}; end
        rawName = strtrim(char(rawName));

        % Append .jpg if missing
        if ~contains(rawName, '.')
            fName = [rawName, '.jpg'];
        else
            fName = rawName;
        end

        fPath = fullfile(imgDir, fName);
        if ~exist(fPath, 'file')
            % Check alternative extensions
            [p, n, ~] = fileparts(fPath);
            if exist(fullfile(p, [n, '.png']), 'file')
                fPath = fullfile(p, [n, '.png']);
                fName = [n, '.png'];
            elseif exist(fullfile(p, [n, '.tif']), 'file')
                fPath = fullfile(p, [n, '.tif']);
                fName = [n, '.tif'];
            else
                validMask(i) = false;
                continue;
            end
        end

        imageNames{i} = fName;
        imagePaths{i} = fPath;
        drGrades(i) = double(rawTbl.(gradeCol)(i));

        if ~isempty(dmeCol) && ismember(dmeCol, colNames)
            dmeRisks(i) = double(rawTbl.(dmeCol)(i));
        else
            dmeRisks(i) = 0;
        end
    end

    % Filter valid existing entries
    imageNames = imageNames(validMask);
    imagePaths = imagePaths(validMask);
    drGrades = drGrades(validMask);
    dmeRisks = dmeRisks(validMask);
    referableDR = (drGrades >= 2);

    dataTbl = table(imageNames, imagePaths, drGrades, dmeRisks, referableDR, ...
        'VariableNames', {'ImageName', 'ImagePath', 'DRGrade', 'RiskOfDME', 'ReferableDR'});

    % 2. Create imageDatastore for MATLAB Deep Learning workflows
    categories = {'Grade 0', 'Grade 1', 'Grade 2', 'Grade 3', 'Grade 4'};
    labels = categorical(cellstr(strcat('Grade ', num2str(drGrades))), categories);
    imds = imageDatastore(imagePaths, 'Labels', labels);

    fprintf('[DATA] Loaded IDRiD %s set: %d images with validated ground truth labels.\n', ...
        upper(splitLower), height(dataTbl));

end
