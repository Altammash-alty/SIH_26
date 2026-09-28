% PREPARE_UNET_DATA
% Preprocesses IDRiD multi-lesion segmentation dataset for U-Net training.
%
% CLASS MAPPING CONVENTION:
%   0: Background (Normal retinal tissue, vessels, optic disc)
%   1: Microaneurysms (MA)
%   2: Haemorrhages / Hemorrhages (HE)
%   3: Hard Exudates (EX)
%   4: Soft Exudates / Cotton Wool Spots (SE)
%
% NOTE: Discrete pixel label values must remain strictly integer 0, 1, 2, 3, 4.
% Resizing of label masks uses NEAREST-NEIGHBOR interpolation exclusively.

clear; clc;
rootPath = fullfile(fileparts(mfilename('fullpath')), '..');
addpath(genpath(rootPath));

fprintf('====================================================================\n');
fprintf('     IDRiD U-NET DATASET PREPARATION & LABEL FUSION (768px)         \n');
fprintf('====================================================================\n\n');

%% 1. Locate Segmentation Data Directory
candidateDirs = {
    fullfile(rootPath, 'data', 'messidor2', 'images', 'segmentation');
    fullfile(rootPath, 'data', 'idrid', 'segmentation');
    fullfile(rootPath, 'dataset', 'A. Segmentation', 'A. Segmentation');
    fullfile(rootPath, 'dataset', 'A. Segmentation');
    fullfile(rootPath, 'dataset', 'idrid_segmentation')
};

segDir = '';
for i = 1:numel(candidateDirs)
    c = candidateDirs{i};
    if exist(fullfile(c, 'microaneurysms'), 'dir') || ...
       exist(fullfile(c, '2. All Segmentation Groundtruths'), 'dir')
        segDir = c;
        break;
    end
end

if isempty(segDir)
    error('prepare_unet_data:DirNotFound', ...
        'Could not locate IDRiD segmentation ground truth directory. Check data/ paths.');
end
fprintf('Located segmentation dataset root: %s\n\n', segDir);

%% 2. Discover Images and Masks
% Subfolders per lesion
lesionKeys = {'microaneurysms', 'hemorrhages', 'hard_exudates', 'soft_exudates'};
lesionIDs  = [1, 2, 3, 4]; % 1=MA, 2=HE, 3=EX, 4=SE

% Destination directories for 768px preprocessed data
outBase = fullfile(rootPath, 'data', 'unet_processed');
outImgDir = fullfile(outBase, 'images');
outLblDir = fullfile(outBase, 'labels');
if ~exist(outImgDir, 'dir'), mkdir(outImgDir); end
if ~exist(outLblDir, 'dir'), mkdir(outLblDir); end

% Collect all 81 base image stems (IDRiD_01 to IDRiD_81)
% IDRiD official challenge: IDRiD_01 to IDRiD_54 = Training (54), IDRiD_55 to IDRiD_81 = Testing (27)
stems = cell(81, 1);
isTrain = false(81, 1);
for id = 1:81
    stems{id} = sprintf('IDRiD_%02d', id);
    isTrain(id) = (id <= 54);
end

targetDim = 768; % Pipeline standard resolution

imagePathsProcessed = cell(81, 1);
labelPathsProcessed = cell(81, 1);
processedCount = 0;

for id = 1:81
    stem = stems{id};
    
    % Find source original image
    rawImgPath = '';
    % Check potential locations for original image
    imgCandidates = {
        fullfile(segDir, 'microaneurysms', 'images', [stem '.jpg']);
        fullfile(segDir, 'microaneurysms', 'images', [stem '.tif']);
        fullfile(segDir, '1. Original Images', 'a. Training Set', [stem '.jpg']);
        fullfile(segDir, '1. Original Images', 'b. Testing Set', [stem '.jpg']);
        fullfile(rootPath, 'data', 'idrid', 'grading', 'train', 'images', [stem '.jpg']);
        fullfile(rootPath, 'data', 'idrid', 'grading', 'test', 'images', [stem '.jpg'])
    };
    for ic = 1:numel(imgCandidates)
        if exist(imgCandidates{ic}, 'file')
            rawImgPath = imgCandidates{ic};
            break;
        end
    end
    
    if isempty(rawImgPath)
        warning('prepare_unet_data:ImageMissing', 'Original image for %s not found. Skipping.', stem);
        continue;
    end
    
    rawImg = imread(rawImgPath);
    origH = size(rawImg, 1); origW = size(rawImg, 2);
    
    % Initialize multi-class label map with 0 (Background)
    multiLabel = zeros(origH, origW, 'uint8');
    
    % Load and fuse masks according to class hierarchy:
    % 1: MA, 2: HE, 3: EX, 4: SE
    % Lesion suffix map: MA, HE, EX, SE
    suffixes = {'_MA.tif', '_HE.tif', '_EX.tif', '_SE.tif'};
    
    for l = 1:4
        catName = lesionKeys{l};
        cID = lesionIDs(l);
        suf = suffixes{l};
        
        maskCandidates = {
            fullfile(segDir, catName, 'masks', [stem suf]);
            fullfile(segDir, catName, 'masks', [stem '_' catName(1:2) '.tif']);
            fullfile(segDir, '2. All Segmentation Groundtruths', 'a. Training Set', sprintf('%d. %s', l, catName), [stem suf]);
            fullfile(segDir, '2. All Segmentation Groundtruths', 'b. Testing Set', sprintf('%d. %s', l, catName), [stem suf])
        };
        
        foundMask = '';
        for mc = 1:numel(maskCandidates)
            if exist(maskCandidates{mc}, 'file')
                foundMask = maskCandidates{mc};
                break;
            end
        end
        
        if ~isempty(foundMask)
            m = imread(foundMask);
            if size(m, 3) > 1, m = m(:,:,1); end
            binMask = (m > 0);
            % Assign class label
            multiLabel(binMask) = cID;
        end
    end
    
    % Resize image and label map together to 768px working resolution
    md = max(origH, origW);
    scale = targetDim / md;
    newH = round(origH * scale);
    newW = round(origW * scale);
    
    % Pad to uniform 768x768 canvas
    resizedImg = imresize(rawImg, [newH, newW], 'bilinear');
    resizedLbl = imresize(multiLabel, [newH, newW], 'nearest'); % CRITICAL: Nearest-neighbor preserves discrete class IDs
    
    padH = targetDim - newH;
    padW = targetDim - newW;
    topPad = floor(padH / 2); bottomPad = padH - topPad;
    leftPad = floor(padW / 2); rightPad = padW - leftPad;
    
    finalImg = padarray(resizedImg, [topPad, leftPad, 0], 0, 'pre');
    finalImg = padarray(finalImg, [bottomPad, rightPad, 0], 0, 'post');
    
    finalLbl = padarray(resizedLbl, [topPad, leftPad], 0, 'pre');
    finalLbl = padarray(finalLbl, [bottomPad, rightPad], 0, 'post');
    
    % Save preprocessed image and label map
    saveImgPath = fullfile(outImgDir, [stem '.png']);
    saveLblPath = fullfile(outLblDir, [stem '.png']);
    
    imwrite(finalImg, saveImgPath);
    imwrite(finalLbl, saveLblPath);
    
    processedCount = processedCount + 1;
    imagePathsProcessed{processedCount} = saveImgPath;
    labelPathsProcessed{processedCount} = saveLblPath;
    
    if mod(processedCount, 15) == 0 || processedCount == 81
        fprintf('  Prepared %d / 81 images (%s)...\n', processedCount, stem);
    end
end

imagePathsProcessed = imagePathsProcessed(1:processedCount);
labelPathsProcessed = labelPathsProcessed(1:processedCount);
isTrain = isTrain(1:processedCount);

%% 3. Create Datastores and Save Metadata
classNames = {'Background', 'MA', 'HE', 'EX', 'SE'};
labelIDs   = [0, 1, 2, 3, 4];

imdsTrain = imageDatastore(imagePathsProcessed(isTrain));
pxdsTrain = pixelLabelDatastore(labelPathsProcessed(isTrain), classNames, labelIDs);

imdsTest  = imageDatastore(imagePathsProcessed(~isTrain));
pxdsTest  = pixelLabelDatastore(labelPathsProcessed(~isTrain), classNames, labelIDs);

metadataPath = fullfile(outBase, 'unet_datastores.mat');
save(metadataPath, 'imdsTrain', 'pxdsTrain', 'imdsTest', 'pxdsTest', ...
    'classNames', 'labelIDs', 'targetDim', 'isTrain', 'stems', '-v7.3');

fprintf('\nData preparation complete. Preprocessed 768px images saved to %s\n', outBase);
fprintf('Metadata saved to: %s\n', metadataPath);
fprintf('  Training images: %d (IDRiD_01 to IDRiD_54)\n', sum(isTrain));
fprintf('  Testing images:  %d (IDRiD_55 to IDRiD_81)\n', sum(~isTrain));
