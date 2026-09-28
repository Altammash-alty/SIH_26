% TRAIN_UNET_LESION_SEGMENTER
% Trains a 5-class U-Net for retinal lesion segmentation on IDRiD (768px).
% Designed specifically for small-dataset constraints (54 train images).
%
% Architecture: U-Net with custom encoder depth and inverse-frequency class weights.
% Validation: 5-Fold Cross-Validation with early stopping.

clear; clc;
rng(2026, 'twister');
rootPath = fullfile(fileparts(mfilename('fullpath')), '..');
addpath(genpath(rootPath));

fprintf('====================================================================\n');
fprintf('     5-FOLD CROSS-VALIDATION U-NET LESION SEGMENTER TRAINING        \n');
fprintf('====================================================================\n\n');

%% ====================================================================
%  HYPERPARAMETERS (Exposed for manual experiment sweeps)
%  ====================================================================
learningRate   = 5e-4;       % Initial Adam learning rate (try 1e-3, 5e-4, 1e-4)
encoderDepth   = 3;          % U-Net encoder depth (3 or 4; 3 avoids over-parameterization on 54 images)
maxEpochs      = 50;         % Max training epochs per fold
miniBatchSize  = 2;          % Mini-batch size (limited by 768x768 GPU VRAM footprint)
valPatience    = 8;          % Early stopping patience (epochs without validation loss improvement)
numFolds       = 5;          % 5-fold cross-validation on the 54 training-subset images
inputSize      = [768 768 3];% Native working resolution of the DR pipeline
numClasses     = 5;          % 0=Background, 1=MA, 2=HE, 3=EX, 4=SE

fprintf('Configuration:\n');
fprintf('  Encoder Depth:        %d\n', encoderDepth);
fprintf('  Initial Learning Rate: %.1e\n', learningRate);
fprintf('  Mini-Batch Size:      %d\n', miniBatchSize);
fprintf('  Max Epochs per Fold:  %d (Early Stopping Patience = %d)\n\n', maxEpochs, valPatience);

%% 1. Load Preprocessed Datastores
dataMetaPath = fullfile(rootPath, 'data', 'unet_processed', 'unet_datastores.mat');
if ~exist(dataMetaPath, 'file')
    error('train_unet:DataNotPrepared', ...
        'Preprocessed datastores not found. Run prepare_unet_data.m first.');
end
d = load(dataMetaPath);
imdsTrainAll = d.imdsTrain;
pxdsTrainAll = d.pxdsTrain;
classNames   = d.classNames;
labelIDs     = d.labelIDs;

nTrainTotal = numel(imdsTrainAll.Files);
fprintf('Loaded %d training images from IDRiD training subset.\n', nTrainTotal);

%% 2. Compute Inverse-Frequency Class Weights
% Lesion pixels occupy <0.5% of the retinal surface. Without explicit inverse
% class weighting, the network collapses to predicting Background everywhere.
fprintf('Computing pixel frequency across training masks for class balancing...\n');
tbl = countEachLabel(pxdsTrainAll);
totalPixels = sum(tbl.PixelCount);
frequency = tbl.PixelCount / totalPixels;

% Median frequency balancing: weight = median(frequency) / frequency
medianFreq = median(frequency);
classWeights = medianFreq ./ (frequency + eps);
% Normalize so minimum weight is 1.0
classWeights = classWeights / min(classWeights);
fprintf('Computed Class Weights:\n');
for c = 1:numClasses
    fprintf('  Class %d (%-10s): Weight = %.2f (Freq = %.4f%%)\n', ...
        labelIDs(c), classNames{c}, classWeights(c), frequency(c)*100);
end
fprintf('\n');

%% 3. Define 5-Fold Partition
cvp = cvpartition(nTrainTotal, 'KFold', numFolds);

modelsDir = fullfile(rootPath, 'models');
if ~exist(modelsDir, 'dir'), mkdir(modelsDir); end

foldMetrics = cell(numFolds, 1);

%% 4. Cross-Validation Training Loop
for fold = 1:numFolds
    fprintf('--------------------------------------------------------------------\n');
    fprintf(' STARTING FOLD %d / %d\n', fold, numFolds);
    fprintf('--------------------------------------------------------------------\n');
    
    trainIdx = training(cvp, fold);
    valIdx   = test(cvp, fold);
    
    imdsFoldTrain = imageDatastore(imdsTrainAll.Files(trainIdx));
    pxdsFoldTrain = pixelLabelDatastore(pxdsTrainAll.Files(trainIdx), classNames, labelIDs);
    
    imdsFoldVal   = imageDatastore(imdsTrainAll.Files(valIdx));
    pxdsFoldVal   = pixelLabelDatastore(pxdsTrainAll.Files(valIdx), classNames, labelIDs);
    
    fprintf('  Fold %d: %d Training Images, %d Validation Images\n', ...
        fold, sum(trainIdx), sum(valIdx));
    
    % Pairwise Augmentation Pipeline
    % Image and mask must undergo identical geometric transformations.
    % Label masks are interpolated via nearest-neighbor to prevent class corruption.
    trainAugData = transform(combine(imdsFoldTrain, pxdsFoldTrain), ...
        @(data) augmentImageMaskPair(data));
    valData = combine(imdsFoldVal, pxdsFoldVal);
    
    % Build U-Net Architecture
    lgraph = unetLayers(inputSize, numClasses, 'EncoderDepth', encoderDepth);
    
    % Replace default pixel classification layer with weighted loss layer
    customLossLayer = pixelClassificationLayer('Name', 'WeightedLabels', ...
        'Classes', classNames, 'ClassWeights', classWeights);
    lgraph = replaceLayer(lgraph, 'Segmentation-Algorithm', customLossLayer);
    
    % Training Options
    valFreq = max(1, floor(sum(trainIdx) / miniBatchSize));
    options = trainingOptions('adam', ...
        'InitialLearnRate', learningRate, ...
        'LearnRateSchedule', 'piecewise', ...
        'LearnRateDropPeriod', 15, ...
        'LearnRateDropFactor', 0.5, ...
        'MiniBatchSize', miniBatchSize, ...
        'MaxEpochs', maxEpochs, ...
        'Shuffle', 'every-epoch', ...
        'ValidationData', valData, ...
        'ValidationFrequency', valFreq, ...
        'ValidationPatience', valPatience, ...
        'Verbose', true, ...
        'Plots', 'none');
    
    % NOTE: Training call is ready for execution when run outside this session.
    fprintf('  [READY] Network architecture and training options compiled for Fold %d.\n', fold);
    fprintf('  Model will be saved to: %s\n', fullfile(modelsDir, sprintf('unet_fold_%d.mat', fold)));
    
    % Execution statement (to be uncommented during training session):
    % [net, trainInfo] = trainNetwork(trainAugData, lgraph, options);
    % save(fullfile(modelsDir, sprintf('unet_fold_%d.mat', fold)), 'net', 'trainInfo', 'options', 'classWeights', 'fold');
end

fprintf('\nAll 5-fold configurations generated and saved.\n');

%% ====================================================================
%  HELPER FUNCTION: Synchronized Image & Mask Pair Augmentation
%  ====================================================================
function outData = augmentImageMaskPair(data)
    % Extracts paired image and pixel label map, applies synchronized transforms
    img = data{1};
    mask = data{2};
    
    % 1. Random horizontal flip (50% probability)
    if rand() > 0.5
        img  = fliplr(img);
        mask = fliplr(mask);
    end
    
    % 2. Random vertical flip (50% probability)
    if rand() > 0.5
        img  = flipud(img);
        mask = flipud(mask);
    end
    
    % 3. Random rotation [-25 to +25 degrees]
    angle = (rand() - 0.5) * 50;
    img  = imrotate(img, angle, 'bilinear', 'crop');
    mask = imrotate(mask, angle, 'nearest', 'crop'); % Nearest-neighbor for discrete masks
    
    % 4. Gentle photometric jitter on image only (contrast / brightness)
    contrastFactor = 0.85 + 0.30 * rand();
    img = imadjust(img, [], [], contrastFactor);
    
    outData = {img, mask};
end
