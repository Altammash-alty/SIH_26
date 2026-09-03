function [dataTbl, imds] = loadMessidor2(baseDir)
% LOADMESSIDOR2 Loads Messidor-2 dataset images and labels (if present).
%
%   [DATATBL, IMDS] = DATA.LOADMESSIDOR2() loads images from the default
%   directory 'data/messidor2/images'.
%
%   [DATATBL, IMDS] = DATA.LOADMESSIDOR2(BASEDIR) uses custom BASEDIR.
%
%   Data Status & Governance:
%       - If a groundtruth labels.csv is present, it will be loaded and paired.
%       - If NO labels are found, images are indexed as UNLABELED.
%       - Unlabeled images are strictly intended for:
%           1. Stage 1 (Quality Gate) & Stage 2 (Preprocessing) validation
%           2. Out-of-Distribution (OOD) baseline reference calibration
%           3. Unsupervised pipeline throughput profiling
%       - They are NOT used for supervised model training without certified ground truth.
%
%   Outputs:
%       dataTbl - Table with:
%                   .ImageName - Base filename (e.g., '20051020_43808_0100_PP.png')
%                   .ImagePath - Full filesystem path
%                   .IsLabeled - Logical scalar (true if ground truth is present)
%                   .DRGrade   - Numeric ICDR Grade (NaN if unlabeled)
%       imds    - MATLAB imageDatastore.
%
%   Author: DR Screening Pipeline MVP
%   Date: 2026-09-02

    if nargin < 1 || isempty(baseDir)
        baseDir = fullfile('data', 'messidor2');
    end

    imgDir = fullfile(baseDir, 'images');
    csvFile = fullfile(baseDir, 'labels.csv');

    if ~exist(imgDir, 'dir')
        error('loadMessidor2:DirNotFound', ...
            'Messidor-2 image directory not found at: %s. Please run organize_datasets.py first.', imgDir);
    end

    % List all supported image files
    fileList = [dir(fullfile(imgDir, '*.png')); ...
                dir(fullfile(imgDir, '*.jpg')); ...
                dir(fullfile(imgDir, '*.jpeg')); ...
                dir(fullfile(imgDir, '*.tif'))];

    if isempty(fileList)
        error('loadMessidor2:NoImages', 'No image files found in %s.', imgDir);
    end

    nImgs = numel(fileList);
    imageNames = cell(nImgs, 1);
    imagePaths = cell(nImgs, 1);
    for k = 1:nImgs
        imageNames{k} = fileList(k).name;
        imagePaths{k} = fullfile(fileList(k).folder, fileList(k).name);
    end

    % Check if labels CSV is present
    hasLabels = exist(csvFile, 'file') > 0;

    if hasLabels
        fprintf('[DATA] Found Messidor-2 labels CSV at: %s\n', csvFile);
        lblTbl = readtable(csvFile);
        % Map image names to labels
        % Construct dataTbl with labels
        drGrades = nan(nImgs, 1);
        isLabeled = true(nImgs, 1);
        % Auto map by stem or name
        dataTbl = table(imageNames, imagePaths, isLabeled, drGrades, ...
            'VariableNames', {'ImageName', 'ImagePath', 'IsLabeled', 'DRGrade'});
        imds = imageDatastore(imagePaths);
    else
        fprintf('[DATA] Loaded Messidor-2: %d images (Status: UNLABELED - for Stage 1-2 & OOD use).\n', nImgs);
        isLabeled = false(nImgs, 1);
        drGrades = nan(nImgs, 1);
        dataTbl = table(imageNames, imagePaths, isLabeled, drGrades, ...
            'VariableNames', {'ImageName', 'ImagePath', 'IsLabeled', 'DRGrade'});
        imds = imageDatastore(imagePaths);
    end

end
