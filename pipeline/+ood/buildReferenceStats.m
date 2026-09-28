function refStats = buildReferenceStats(imageSource, outputPath, cfg)
% BUILDREFERENCESTATS Offline utility to compute and save reference distribution statistics.
%
%   REFSTATS = OOD.BUILDREFERENCESTATS() generates baseline reference statistics
%   from a representative synthetic cohort of normal/typical training fundus
%   images and saves them to 'reference_stats.mat'.
%
%   REFSTATS = OOD.BUILDREFERENCESTATS(IMAGESOURCE, OUTPUTPATH, CFG) computes
%   statistics from IMAGESOURCE:
%       - A directory path containing training images (.jpg, .png, .tif, .mat)
%       - A cell array of loaded RGB fundus images
%       - Empty [] (builds a representative synthetic calibration cohort)
%
%   Inputs:
%       imageSource - (Optional) Directory path, cell array of images, or [].
%       outputPath  - (Optional) File path to save the .mat file. Defaults to
%                     'reference_stats.mat'. Set to '' to skip saving.
%       cfg         - (Optional) Configuration struct from config().
%
%   Outputs:
%       refStats    - Struct containing:
%                       .mean         - 1xD mean feature vector
%                       .cov          - DxD sample covariance matrix
%                       .invCov       - DxD regularized inverse covariance
%                       .std          - 1xD standard deviation vector
%                       .featureNames - 1xD cell array of feature names
%                       .sampleSize   - Number of calibration images used
%                       .createdAt    - Generation timestamp string
%
%   Scope & Governance:
%       Run this script/function once offline to capture the statistical profile
%       of the training distribution. This is a fixed reference anchor and does
%       not modify models at runtime.
%
%   Author: DR Screening Pipeline MVP
%   Date: 2026-09-02

    % 1. Parse inputs
    if nargin < 3 || isempty(cfg)
        cfg = config();
    end

    if nargin < 2 || isempty(outputPath)
        outputPath = 'reference_stats.mat';
        if isfield(cfg, 'ood') && isfield(cfg.ood, 'statsFilePath')
            outputPath = cfg.ood.statsFilePath;
        end
    end

    lambda = 1e-4;
    if isfield(cfg, 'ood') && isfield(cfg.ood, 'regCovariance')
        lambda = cfg.ood.regCovariance;
    end

    % 2. Acquire training-cohort images from a real dataset only
    imageArray = {};

    if nargin < 1 || isempty(imageSource)
        error('buildReferenceStats:MissingImageSource', ...
            'A real training-image directory or image cell array is required. Use ood.buildReferenceStats(''data/idrid/grading/train/images'', ...) without synthetic fallback.');
    elseif ischar(imageSource) || isstring(imageSource)
        if isfolder(imageSource)
            fprintf('[INFO] Scanning reference images from directory: %s\n', imageSource);
            fileList = [dir(fullfile(imageSource, '*.jpg')); ...
                        dir(fullfile(imageSource, '*.png')); ...
                        dir(fullfile(imageSource, '*.jpeg')); ...
                        dir(fullfile(imageSource, '*.tif'))];
            if isempty(fileList)
                error('buildReferenceStats:NoImagesFound', ...
                    'No real image files were found in %s. Please point to the actual training dataset and do not use synthetic fallback data.', imageSource);
            end

            for k = 1:numel(fileList)
                fPath = fullfile(fileList(k).folder, fileList(k).name);
                try
                    imgK = imread(fPath);
                    % Enhance image via Stage 2 preprocessing for consistency
                    enhancedK = preprocess.enhanceImage(imgK, cfg);
                    imageArray{end+1} = enhancedK;
                catch ME
                    fprintf('[WARNING] Failed to read/process %s: %s\n', fPath, ME.message);
                end
            end
        else
            error('buildReferenceStats:InvalidPath', 'Provided path is not a valid directory: %s', imageSource);
        end
    elseif iscell(imageSource)
        imageArray = imageSource;
    else
        error('buildReferenceStats:UnsupportedSource', ...
            'imageSource must be a real directory path or a cell array of images. Synthetic cohorts are not allowed.');
    end

    nImages = numel(imageArray);
    if nImages < 5
        error('buildReferenceStats:InsufficientSamples', ...
            'Need at least 5 images to estimate covariance; only %d provided.', nImages);
    end

    fprintf('[INFO] Extracting statistical features across %d calibration images...\n', nImages);

    % 3. Extract features across all cohort images
    allFeatures = [];
    featureNames = {};

    for i = 1:nImages
        currImg = imageArray{i};
        [featVec, featNames] = ood.extractImageFeatures(currImg, cfg);
        allFeatures = [allFeatures; featVec]; %#ok<AGROW>
        if isempty(featureNames)
            featureNames = featNames;
        end
    end

    % 4. Compute Statistical Moments
    mu = mean(allFeatures, 1);
    sigma = std(allFeatures, 0, 1);
    sampleCov = cov(allFeatures);

    % Regularize covariance to guarantee positive-definite invertibility
    D = length(mu);
    sampleCovReg = sampleCov + lambda * eye(D);
    invSigma = inv(sampleCovReg);

    % 5. Package Reference Statistics
    refStats = struct();
    refStats.mean = mu;
    refStats.cov = sampleCov;
    refStats.invCov = invSigma;
    refStats.std = sigma;
    refStats.featureNames = featureNames;
    refStats.sampleSize = nImages;
    refStats.createdAt = char(datetime('now', 'Format', 'yyyy-MM-dd HH:mm:ss'));

    % 6. Save to MAT file if output path specified
    if ~isempty(outputPath)
        save(outputPath, 'refStats');
        fprintf('[SUCCESS] Baseline reference statistics successfully saved to: %s\n', outputPath);
    end

end
