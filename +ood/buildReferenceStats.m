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

    % 2. Acquire or generate training-cohort images
    imageArray = {};

    if nargin < 1 || isempty(imageSource)
        fprintf('[INFO] No image folder provided. Generating calibration cohort of 40 representative fundus variations...\n');
        imageArray = generateCalibrationCohort(40);
    elseif ischar(imageSource) || isstring(imageSource)
        if isfolder(imageSource)
            fprintf('[INFO] Scanning reference images from directory: %s\n', imageSource);
            fileList = [dir(fullfile(imageSource, '*.jpg')); ...
                        dir(fullfile(imageSource, '*.png')); ...
                        dir(fullfile(imageSource, '*.jpeg')); ...
                        dir(fullfile(imageSource, '*.tif'))];
            if isempty(fileList)
                warning('buildReferenceStats:NoImagesFound', ...
                    'No image files found in %s. Falling back to synthetic calibration cohort.', imageSource);
                imageArray = generateCalibrationCohort(40);
            else
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
            end
        else
            error('buildReferenceStats:InvalidPath', 'Provided path is not a valid directory: %s', imageSource);
        end
    elseif iscell(imageSource)
        imageArray = imageSource;
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

%% Local Helper: Synthetic Calibration Cohort Generator
function cohort = generateCalibrationCohort(N)
    % Generates N diverse, physiologically plausible synthetic retinal images
    % covering realistic pigmentation, vessel topologies, and flash variations.
    cohort = cell(1, N);
    
    for i = 1:N
        % Randomize physiological parameters
        baseR = 0.75 + 0.10 * (rand() - 0.5);
        baseG = 0.38 + 0.08 * (rand() - 0.5);
        baseB = 0.08 + 0.04 * (rand() - 0.5);
        noiseLev = 0.010 + 0.008 * rand();
        
        img = createParametricFundus(384, baseR, baseG, baseB, noiseLev, i);
        % Apply Stage 2 enhancement so stats match preprocessed distribution
        enhanced = preprocess.enhanceImage(img);
        cohort{i} = enhanced;
    end
end

function fundusImg = createParametricFundus(imgSize, rBase, gBase, bBase, noiseAmp, seed)
    rng(seed * 101);
    [X, Y] = meshgrid(1:imgSize, 1:imgSize);
    centerX = imgSize / 2;
    centerY = imgSize / 2;
    radius = imgSize * 0.44;

    distFromCenter = sqrt((X - centerX).^2 + (Y - centerY).^2);
    fovMask = distFromCenter <= radius;

    radialFalloff = max(0, 1.0 - 0.30 * (distFromCenter / radius).^2);
    radialFalloff(~fovMask) = 0;

    R = (rBase + 0.04 * sin(X/25) .* cos(Y/25)) .* radialFalloff;
    G = (gBase + 0.03 * cos(X/20) .* sin(Y/20)) .* radialFalloff;
    B = (bBase + 0.02 * sin(X/35)) .* radialFalloff;

    % Optic Disc
    discX = centerX - imgSize * 0.20;
    discY = centerY;
    discRadius = imgSize * 0.075;
    distDisc = sqrt((X - discX).^2 + (Y - discY).^2);
    discSoft = max(0, 1.0 - (distDisc / discRadius).^2) .* (distDisc <= discRadius);

    R = R + 0.18 * discSoft;
    G = G + 0.38 * discSoft;
    B = B + 0.22 * discSoft;

    % Retinal blood vessels
    vesselTree = zeros(imgSize, imgSize);
    t = linspace(0, 1, 200);
    arcX_sup = discX + t * (imgSize * 0.55);
    arcY_sup = discY - (imgSize * 0.35) * sin(t * pi * 0.85);
    arcX_inf = discX + t * (imgSize * 0.55);
    arcY_inf = discY + (imgSize * 0.35) * sin(t * pi * 0.85);

    branches = { [arcX_sup; arcY_sup], [arcX_inf; arcY_inf] };
    for b = 1:numel(branches)
        pts = branches{b};
        for k = 1:size(pts, 2)
            px = round(pts(1, k));
            py = round(pts(2, k));
            if px > 2 && px < (imgSize - 2) && py > 2 && py < (imgSize - 2)
                vesselTree(py-1:py+1, px-1:px+1) = 1;
            end
        end
    end
    vesselTree = imgaussfilt(vesselTree, 0.7);
    vesselTree(~fovMask) = 0;

    R = R - 0.22 * vesselTree;
    G = G - 0.32 * vesselTree;
    B = B - 0.12 * vesselTree;

    % Sensor noise
    noise = randn(imgSize, imgSize) * noiseAmp;
    noise(~fovMask) = 0;

    R = max(0, min(1, R + noise));
    G = max(0, min(1, G + noise));
    B = max(0, min(1, B + noise));

    R(~fovMask) = 0;
    G(~fovMask) = 0;
    B(~fovMask) = 0;

    fundusImg = cat(3, R, G, B);
end
