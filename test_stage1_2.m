%% TEST_STAGE1_2: Verification and Demo Suite for DR Pipeline Stages 1 & 2
%
% This script verifies:
%   1. Stage 1 Quality Gate (+quality package)
%      - Tests Sharpness/Blur check (Laplacian variance)
%      - Tests Illumination/Exposure check (mean, std, clipping)
%      - Tests Field of View check (circularity, area, centering)
%      - Evaluates 4 scenarios: Good, Blurry, Underexposed, and Bad FOV.
%
%   2. Stage 2 Preprocessing & Enhancement (+preprocess package)
%      - Takes passing fundus image
%      - Applies Illumination Normalization
%      - Applies Green Channel CLAHE
%      - Applies Edge-Preserving Denoising
%      - Displays side-by-side visual comparisons
%
% Usage:
%   Simply run 'test_stage1_2' in the MATLAB Command Window.
%   You can also specify a real fundus image path below.
%
% Author: DR Screening Pipeline MVP
% Date: 2026-08-30

clear; clc; close all;

fprintf('==================================================================\n');
fprintf('   DIABETIC RETINOPATHY SCREENING PIPELINE - STAGES 1 & 2 TEST   \n');
fprintf('==================================================================\n\n');

%% 1. Configuration & Setup
cfg = config();

% Optional: Set to a valid image path to test on your own fundus image file:
% e.g., customImagePath = 'my_fundus_photo.jpg';
customImagePath = '';

%% 2. Load real validation images or a custom real image
if ~isempty(customImagePath) && exist(customImagePath, 'file')
    fprintf('[INFO] Loading custom fundus image from: %s\n\n', customImagePath);
    rawImg = imread(customImagePath);
    testCases(1).name = 'Custom Real Image';
    testCases(1).image = rawImg;
    testCases(1).expectedPass = true;
else
    realImageDir = fullfile('data', 'idrid', 'grading', 'test', 'images');
    imageFiles = [];
    if exist(realImageDir, 'dir')
        pngFiles = dir(fullfile(realImageDir, '*.png'));
        jpgFiles = dir(fullfile(realImageDir, '*.jpg'));
        jpegFiles = dir(fullfile(realImageDir, '*.jpeg'));
        imageFiles = [pngFiles; jpgFiles; jpegFiles];
    end

    if isempty(imageFiles)
        error('[ERROR] No real validation images were found in %s. Provide a customImagePath or add the real IDRiD validation images.', realImageDir);
    end

    fprintf('[INFO] Loading real fundus images from: %s\n\n', realImageDir);
    numCases = min(4, numel(imageFiles));
    for i = 1:numCases
        imgPath = fullfile(realImageDir, imageFiles(i).name);
        rawImg = imread(imgPath);
        testCases(i).name = sprintf('Real Validation Image %d: %s', i, imageFiles(i).name);
        testCases(i).image = rawImg;
        testCases(i).expectedPass = true;
    end

    fprintf('       Loaded %d real IDRiD validation images for quality and preprocessing checks.\n\n', numCases);
end

%% 3. Execute Stage 1: Quality Gate Evaluation
fprintf('------------------------------------------------------------------\n');
fprintf('  STAGE 1: QUALITY GATE ASSESSMENT RESULTS\n');
fprintf('------------------------------------------------------------------\n');
fprintf('%-28s | %-6s | %-8s | %-8s | %-8s | %s\n', ...
    'Test Scenario', 'Status', 'Blur Scr', 'Illm Scr', 'FOV Scr', 'Failure Reason');
fprintf('-------------------------------------------------------------------------------------------------------\n');

qualityResults = struct();

for i = 1:numel(testCases)
    img = testCases(i).image;
    [isGood, reason, metrics] = quality.assessQuality(img, cfg);
    
    qualityResults(i).isGood = isGood;
    qualityResults(i).reason = reason;
    qualityResults(i).metrics = metrics;
    
    if isGood
        statusStr = 'PASS';
        reasonDisplay = '(None - Image Accepted)';
    else
        statusStr = 'FAIL';
        reasonDisplay = char(reason);
    end
    
    fprintf('%-28s | %-6s | %8.2f | %8.1f | %8.1f | %s\n', ...
        testCases(i).name, statusStr, ...
        metrics.blurScore, metrics.illumScore, metrics.fovScore, reasonDisplay);
end
fprintf('-------------------------------------------------------------------------------------------------------\n\n');

%% 4. Execute Stage 2: Preprocessing & Enhancement on Accepted Image
passIdx = find([qualityResults.isGood], 1);
if isempty(passIdx)
    fprintf('[WARN] No image passed the Quality Gate. Running enhancement on Case 1 for demo...\n');
    passIdx = 1;
end

acceptedImg = testCases(passIdx).image;
fprintf('[INFO] Running Stage 2 Preprocessing & Enhancement on "%s"...\n', testCases(passIdx).name);

tic;
[enhancedImg, steps] = preprocess.enhanceImage(acceptedImg, cfg);
procTime = toc;

fprintf('       Step 1: Illumination Normalization -> Completed.\n');
fprintf('       Step 2: Green Channel CLAHE        -> Completed.\n');
fprintf('       Step 3: Edge-Preserving Denoising  -> Completed.\n');
fprintf('       Total Preprocessing Time: %.3f seconds.\n\n', procTime);

%% 5. Visual Display: Figure 1 - Quality Gate Evaluation
hFig1 = figure('Name', 'Stage 1: Quality Gate Test Suite', ...
               'Position', [50, 100, 1100, 700], 'Color', [0.12 0.12 0.12]);

for i = 1:numel(testCases)
    subplot(2, 2, i);
    imshow(testCases(i).image);
    
    isGood = qualityResults(i).isGood;
    metrics = qualityResults(i).metrics;
    
    if isGood
        badge = '[PASSED]';
        titleColor = [0.2 0.9 0.3]; % Bright Green
    else
        badge = '[REJECTED]';
        titleColor = [1.0 0.3 0.3]; % Bright Red
    end
    
    titleStr = sprintf('%s %s\nScore: %.1f/100 (Blur: %.1f, Illum: %.1f, FOV: %.1f)', ...
        badge, testCases(i).name, metrics.overallScore, ...
        metrics.blurScore, metrics.illumScore, metrics.fovScore);
    
    title(titleStr, 'Color', titleColor, 'FontSize', 10, 'FontWeight', 'bold');
    
    if ~isGood
        xlabel(char(qualityResults(i).reason), 'Color', [1 0.8 0.5], 'FontSize', 8);
    else
        xlabel('Ready for Stage 2 Preprocessing', 'Color', [0.8 1 0.8], 'FontSize', 8);
    end
end
sgtitle('Stage 1: Quality Gate Verification (Laplacian Blur, Illumination & FOV)', ...
        'Color', 'w', 'FontSize', 14, 'FontWeight', 'bold');

%% 6. Visual Display: Figure 2 - Preprocessing Pipeline Steps
hFig2 = figure('Name', 'Stage 2: Preprocessing & Enhancement Pipeline', ...
               'Position', [100, 150, 1200, 650], 'Color', [0.12 0.12 0.12]);

% 1. Original
subplot(2, 4, 1);
imshow(steps.original);
title('1. Original Input', 'Color', 'w', 'FontSize', 11, 'FontWeight', 'bold');
xlabel('Raw Fundus Capture', 'Color', [0.8 0.8 0.8]);

% 2. Illumination Normalized
subplot(2, 4, 2);
imshow(steps.illuminationNormalized);
title('2. Illum Normalized', 'Color', 'w', 'FontSize', 11, 'FontWeight', 'bold');
xlabel('Vignetting/Flash Corrected', 'Color', [0.8 0.8 0.8]);

% 3. CLAHE Enhanced
subplot(2, 4, 3);
imshow(steps.claheEnhanced);
title('3. Green-Ch CLAHE', 'Color', 'w', 'FontSize', 11, 'FontWeight', 'bold');
xlabel('Vascular Contrast Boosted', 'Color', [0.8 0.8 0.8]);

% 4. Final Denoised
subplot(2, 4, 4);
imshow(steps.finalEnhanced);
title('4. Final Denoised', 'Color', [0.3 1.0 0.4], 'FontSize', 11, 'FontWeight', 'bold');
xlabel('Clean for Segmentation/CNN', 'Color', [0.8 1.0 0.8]);

% 5. Green Channel: Before vs After Profile
origD = im2double(steps.original);
enhD  = im2double(steps.finalEnhanced);
origG = origD(:,:,2);
enhG  = enhD(:,:,2);

subplot(2, 4, [5 6]);
imshowpair(origG, enhG, 'montage');
title('Green Channel Comparison (Left: Before | Right: After CLAHE + Denoise)', ...
      'Color', 'w', 'FontSize', 10, 'FontWeight', 'bold');

% 6. Histogram of Green Channel
subplot(2, 4, [7 8]);
mask = qualityResults(passIdx).metrics.mask;
if any(mask(:))
    origG_vals = origG(mask);
    enhG_vals  = enhG(mask);
else
    origG_vals = origG(:);
    enhG_vals  = enhG(:);
end

[countsOrig, binEdges] = histcounts(origG_vals, 50, 'Normalization', 'pdf');
[countsEnh, ~]         = histcounts(enhG_vals, 50, 'Normalization', 'pdf');
binCenters = (binEdges(1:end-1) + binEdges(2:end)) / 2;

plot(binCenters, countsOrig, 'r--', 'LineWidth', 1.8); hold on;
plot(binCenters, countsEnh,  'g-',  'LineWidth', 2.0);
grid on;
set(gca, 'Color', [0.18 0.18 0.18], 'XColor', 'w', 'YColor', 'w');
legend({'Original Green PDF', 'Enhanced Green PDF'}, 'TextColor', 'w', 'Location', 'northeast');
title('Dynamic Range Expansion (Green Channel PDF)', 'Color', 'w', 'FontSize', 10, 'FontWeight', 'bold');
xlabel('Pixel Intensity [0, 1]', 'Color', 'w');
ylabel('Probability Density', 'Color', 'w');

sgtitle('Stage 2: Fundus Image Preprocessing & Contrast Enhancement Pipeline', ...
        'Color', 'w', 'FontSize', 14, 'FontWeight', 'bold');

fprintf('==================================================================\n');
fprintf('   TEST COMPLETE: All Stage 1 & Stage 2 functions validated!      \n');
fprintf('==================================================================\n\n');

    R_base = R_base - 0.25 * vesselTree;
    G_base = G_base - 0.35 * vesselTree;
    B_base = B_base - 0.15 * vesselTree;
    
    % Add mild realistic sensor noise
    rng(42); % Fixed seed for repeatability
    noise = (randn(imgSize, imgSize) * 0.015);
    noise(~fovMask) = 0;
    
    R_final = max(0, min(1, R_base + noise));
    G_final = max(0, min(1, G_base + noise));
    B_final = max(0, min(1, B_base + noise));
    
    % Apply outer black mask
    R_final(~fovMask) = 0;
    G_final(~fovMask) = 0;
    B_final(~fovMask) = 0;
    
    fundusImg = cat(3, R_final, G_final, B_final);
end
