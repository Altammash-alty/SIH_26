% EVALUATE_UNET_SEGMENTER
% Evaluates trained U-Net fold models and final ensemble against:
%   1. 5-Fold Cross-Validation held-out validation sets (54 images)
%   2. Official IDRiD Segmentation Test Set (27 held-out images)
%
% Computes Dice score and IoU PER LESION CLASS SEPARATELY (MA, HE, EX, SE)
% using evaluateSemanticSegmentation().

clear; clc;
rootPath = fullfile(fileparts(mfilename('fullpath')), '..');
addpath(genpath(rootPath));

fprintf('====================================================================\n');
fprintf('     U-NET SEGMENTATION EVALUATION (PER-CLASS DICE & IoU)           \n');
fprintf('====================================================================\n\n');

%% 1. Load Preprocessed Datastores
dataMetaPath = fullfile(rootPath, 'data', 'unet_processed', 'unet_datastores.mat');
if ~exist(dataMetaPath, 'file')
    error('evaluate_unet:DataNotPrepared', ...
        'Preprocessed datastores not found. Run prepare_unet_data.m first.');
end
d = load(dataMetaPath);
imdsTrainAll = d.imdsTrain;
pxdsTrainAll = d.pxdsTrain;
imdsTest     = d.imdsTest;
pxdsTest     = d.pxdsTest;
classNames   = d.classNames;
labelIDs     = d.labelIDs;
numClasses   = numel(classNames);
numFolds     = 5;

modelsDir = fullfile(rootPath, 'models');
resultsDir = fullfile(rootPath, 'results');
if ~exist(resultsDir, 'dir'), mkdir(resultsDir); end

%% 2. Evaluate 5-Fold Validation Performance
cvp = cvpartition(numel(imdsTrainAll.Files), 'KFold', numFolds);
foldResults = cell(numFolds, 1);

fprintf('--- 1. EVALUATING 5-FOLD CROSS-VALIDATION SETS ---\n');

for fold = 1:numFolds
    modelFile = fullfile(modelsDir, sprintf('unet_fold_%d.mat', fold));
    if ~exist(modelFile, 'file')
        warning('evaluate_unet:ModelMissing', ...
            'Fold model %s not found on disk. Run training first.', modelFile);
        continue;
    end
    
    fprintf('Evaluating Fold %d...\n', fold);
    m = load(modelFile);
    net = m.net;
    
    valIdx = test(cvp, fold);
    imdsVal = imageDatastore(imdsTrainAll.Files(valIdx));
    pxdsVal = pixelLabelDatastore(pxdsTrainAll.Files(valIdx), classNames, labelIDs);
    
    % Run semantic segmentation on validation images
    pxdsPred = semanticseg(imdsVal, net, 'MiniBatchSize', 2, ...
        'Classes', classNames, 'ExecutionEnvironment', 'auto');
    
    % Evaluate segmentation metrics
    metrics = evaluateSemanticSegmentation(pxdsPred, pxdsVal, 'Verbose', false);
    
    % Extract per-class Dice and IoU
    classMetrics = metrics.ClassMetrics;
    
    % Format fold summary table
    foldTbl = table();
    foldTbl.Fold  = repmat(fold, numClasses, 1);
    foldTbl.Class = classNames';
    foldTbl.Dice  = classMetrics.Dice;
    foldTbl.IoU   = classMetrics.MeanIoU;
    
    foldResults{fold} = foldTbl;
    
    fprintf('  Fold %d Per-Class Metrics:\n', fold);
    disp(foldTbl);
end

% Combine cross-validation table if available
validFolds = foldResults(~cellfun('isempty', foldResults));
if ~isempty(validFolds)
    cvMasterTbl = vertcat(validFolds{:});
    writetable(cvMasterTbl, fullfile(resultsDir, 'unet_crossval_per_class_metrics.csv'));
    
    % Compute mean across folds per class
    fprintf('\n--- MEAN 5-FOLD CROSS-VALIDATION RESULTS PER CLASS ---\n');
    for c = 1:numClasses
        cName = classNames{c};
        cRows = cvMasterTbl(strcmp(cvMasterTbl.Class, cName), :);
        fprintf('  Class %-12s: Mean Dice = %.4f (std = %.4f), Mean IoU = %.4f\n', ...
            cName, mean(cRows.Dice), std(cRows.Dice), mean(cRows.IoU));
    end
end

%% 3. Evaluate on Official 27-Image Held-Out IDRiD Test Set
fprintf('\n--- 2. EVALUATING HELD-OUT IDRiD TEST SET (n = %d) ---\n', numel(imdsTest.Files));

% Load best fold model or ensemble
bestModelFile = fullfile(modelsDir, 'unet_fold_1.mat');
if exist(bestModelFile, 'file')
    m = load(bestModelFile);
    net = m.net;
    
    pxdsTestPred = semanticseg(imdsTest, net, 'MiniBatchSize', 2, ...
        'Classes', classNames, 'ExecutionEnvironment', 'auto');
    
    testMetrics = evaluateSemanticSegmentation(pxdsTestPred, pxdsTest, 'Verbose', false);
    testClassMetrics = testMetrics.ClassMetrics;
    
    testSummaryTbl = table(classNames', testClassMetrics.Dice, testClassMetrics.MeanIoU, ...
        'VariableNames', {'Class', 'Dice', 'IoU'});
    
    fprintf('\nHeld-Out IDRiD Segmentation Test Set Metrics:\n');
    disp(testSummaryTbl);
    
    writetable(testSummaryTbl, fullfile(resultsDir, 'unet_heldout_test_metrics.csv'));
else
    fprintf('Test evaluation skipped: Models not yet trained.\n');
end

fprintf('Evaluation script complete.\n');
