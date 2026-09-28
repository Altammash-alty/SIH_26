function [segTbl, categoryStats] = loadIDRiDSegmentation(category, baseDir)
% LOADIDRIDSEGMENTATION Loads IDRiD Segmentation image and pixel ground truth mask pairs.
%
%   [SEGTBL, STATS] = DATA.LOADIDRIDSEGMENTATION() loads all 5 retinal
%   segmentation categories from 'data/idrid/segmentation'.
%
%   [SEGTBL, STATS] = DATA.LOADIDRIDSEGMENTATION(CATEGORY) loads a specific category:
%       - 'all'             : All 5 lesion and optic disc categories (default)
%       - 'microaneurysms'  : Microaneurysm (MA) detection masks
%       - 'hemorrhages'     : Hemorrhage (HE) detection masks
%       - 'hard_exudates'   : Hard Exudate (EX) detection masks
%       - 'soft_exudates'   : Soft Exudate (SE) / Cotton Wool Spot masks
%       - 'optic_disc'      : Optic Disc (OD) segmentation masks
%
%   [SEGTBL, STATS] = DATA.LOADIDRIDSEGMENTATION(CATEGORY, BASEDIR) uses custom BASEDIR.
%
%   Outputs:
%       segTbl        - Table containing:
%                         .Category   - Anatomical / lesion category name
%                         .ImageName  - Source fundus image filename
%                         .ImagePath  - Full filesystem path to RGB image
%                         .MaskName   - Ground truth binary mask filename
%                         .MaskPath   - Full filesystem path to ground truth mask (.tif)
%       categoryStats - Struct with sample counts per category.
%
%   Author: DR Screening Pipeline MVP
%   Date: 2026-09-02

    if nargin < 1 || isempty(category)
        category = 'all';
    end

    if nargin < 2 || isempty(baseDir)
        baseDir = fullfile('data', 'idrid', 'segmentation');
    end

    if ~exist(baseDir, 'dir')
        error('loadIDRiDSegmentation:DirNotFound', ...
            'Segmentation directory not found at: %s. Please run organize_datasets.py first.', baseDir);
    end

    allCategories = {'microaneurysms', 'hemorrhages', 'hard_exudates', 'soft_exudates', 'optic_disc'};
    catLower = lower(char(category));

    if strcmp(catLower, 'all')
        targetCats = allCategories;
    elseif ismember(catLower, allCategories)
        targetCats = {catLower};
    else
        error('loadIDRiDSegmentation:InvalidCategory', ...
            'Category must be one of: ''all'', ''microaneurysms'', ''hemorrhages'', ''hard_exudates'', ''soft_exudates'', ''optic_disc''.');
    end

    records = [];
    categoryStats = struct();

    for c = 1:numel(targetCats)
        curCat = targetCats{c};
        curDir = fullfile(baseDir, curCat);
        imgDir = fullfile(curDir, 'images');
        mskDir = fullfile(curDir, 'masks');

        if ~exist(imgDir, 'dir') || ~exist(mskDir, 'dir')
            categoryStats.(curCat) = 0;
            continue;
        end

        maskFiles = dir(fullfile(mskDir, '*.tif'));
        if isempty(maskFiles)
            maskFiles = [dir(fullfile(mskDir, '*.png')); dir(fullfile(mskDir, '*.jpg'))];
        end

        nMsk = numel(maskFiles);
        categoryStats.(curCat) = nMsk;

        for m = 1:nMsk
            mName = maskFiles(m).name;
            mPath = fullfile(maskFiles(m).folder, mName);

            % Deduce base image stem (e.g., 'IDRiD_01_MA.tif' -> 'IDRiD_01')
            parts = strsplit(mName, '_');
            if numel(parts) >= 2
                imgStem = [parts{1}, '_', parts{2}];
            else
                [~, imgStem, ~] = fileparts(mName);
            end

            % Locate matching image
            imgFiles = [dir(fullfile(imgDir, [imgStem, '.jpg'])); ...
                        dir(fullfile(imgDir, [imgStem, '.jpeg'])); ...
                        dir(fullfile(imgDir, [imgStem, '.png']))];

            if isempty(imgFiles)
                warning('loadIDRiDSegmentation:MissingImage', ...
                    'Mask %s has no matching image in %s.', mName, imgDir);
                continue;
            end

            iName = imgFiles(1).name;
            iPath = fullfile(imgFiles(1).folder, iName);

            rec = struct('Category', string(curCat), ...
                         'ImageName', string(iName), ...
                         'ImagePath', string(iPath), ...
                         'MaskName', string(mName), ...
                         'MaskPath', string(mPath));
            records = [records; rec]; %#ok<AGROW>
        end
    end

    if isempty(records)
        segTbl = table();
    else
        segTbl = struct2table(records);
    end

    fprintf('[DATA] Loaded IDRiD Segmentation: %d verified image-mask pairs across %d categories.\n', ...
        height(segTbl), numel(targetCats));

end
