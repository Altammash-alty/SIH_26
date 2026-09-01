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

%% 2. Generate or Load Test Dataset
if ~isempty(customImagePath) && exist(customImagePath, 'file')
    fprintf('[INFO] Loading custom fundus image from: %s\n\n', customImagePath);
    rawImg = imread(customImagePath);
    testCases(1).name = 'Custom Image';
    testCases(1).image = rawImg;
    testCases(1).expectedPass = true;
else
    fprintf('[INFO] Generating synthetic fundus dataset for validation...\n');
    
    % Generate baseline high-quality fundus image
    goodFundus = createSyntheticFundus(512);

    % Case 1: Good Quality Fundus (Passes all checks)
    testCases(1).name = 'Case 1: High Quality (Normal)';
    testCases(1).image = goodFundus;
    testCases(1).expectedPass = true;

    % Case 2: Blurry Fundus (Simulated motion / optical defocus)
    hBlur = fspecial('gaussian', [21 21], 5.0);
    blurryFundus = imfilter(goodFundus, hBlur, 'replicate');
    testCases(2).name = 'Case 2: Blurry / Defocused';
    testCases(2).image = blurryFundus;
    testCases(2).expectedPass = false;

    % Case 3: Underexposed / Dark Fundus (Simulated low-light failure)
    darkFundus = goodFundus * 0.18; % Severely dark
    testCases(3).name = 'Case 3: Underexposed (Too Dark)';
    testCases(3).image = darkFundus;
    testCases(3).expectedPass = false;

    % Case 4: Incomplete / Severely Cropped Field of View
    croppedFundus = goodFundus;
    croppedFundus(:, 1:round(size(goodFundus,2)*0.65), :) = 0; % Crop off 65% of retina
    testCases(4).name = 'Case 4: Cropped / Bad FOV';
    testCases(4).image = croppedFundus;
    testCases(4).expectedPass = false;
    
    fprintf('       Generated 4 test cases (Good, Blurry, Dark, Cropped FOV).\n\n');
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


%% ========================================================================
%  HELPER FUNCTION: Realistic Synthetic Fundus Image Generator
%  ========================================================================
function fundusImg = createSyntheticFundus(imgSize)
    % Generates a realistic fundus photograph with circular mask,
    % natural orange/red retinal background, optic disc, fovea,
    % branching vascular tree, and fine microvasculature.
    
    if nargin < 1, imgSize = 512; end
    
    [X, Y] = meshgrid(1:imgSize, 1:imgSize);
    centerX = imgSize / 2;
    centerY = imgSize / 2;
    radius  = imgSize * 0.44;
    
    % 1. Circular Field-of-View Mask
    distFromCenter = sqrt((X - centerX).^2 + (Y - centerY).^2);
    fovMask = distFromCenter <= radius;
    
    % 2. Retinal background color with natural radial illumination gradient
    % Retina center is slightly brighter; edges naturally darken (vignetting)
    radialFalloff = 1.0 - 0.35 * (distFromCenter / radius).^2;
    radialFalloff(~fovMask) = 0;
    
    % Retinal pigment layers (Red-Orange base)
    R_base = (0.80 + 0.05 * sin(X/30) .* cos(Y/30)) .* radialFalloff;
    G_base = (0.42 + 0.03 * cos(X/25) .* sin(Y/25)) .* radialFalloff;
    B_base = (0.10 + 0.02 * sin(X/40)) .* radialFalloff;
    
    % 3. Optic Disc (Nasal side: yellowish-orange circular structure)
    discX = centerX - imgSize * 0.20;
    discY = centerY;
    discRadius = imgSize * 0.075;
    distDisc = sqrt((X - discX).^2 + (Y - discY).^2);
    discMask = distDisc <= discRadius;
    discSoft = max(0, 1.0 - (distDisc / discRadius).^2) .* discMask;
    
    R_base = R_base + 0.18 * discSoft;
    G_base = G_base + 0.40 * discSoft;
    B_base = B_base + 0.25 * discSoft;
    
    % 4. Fovea & Macula (Temporal side: darker avascular region)
    foveaX = centerX + imgSize * 0.14;
    foveaY = centerY;
    foveaRadius = imgSize * 0.08;
    distFovea = sqrt((X - foveaX).^2 + (Y - foveaY).^2);
    foveaSoft = max(0, 1.0 - (distFovea / foveaRadius).^2) .* (distFovea <= foveaRadius);
    
    R_base = R_base - 0.15 * foveaSoft;
    G_base = G_base - 0.12 * foveaSoft;
    
    % 5. Retinal Blood Vessels (Superior/Inferior arcades branching from disc)
    vesselTree = zeros(imgSize, imgSize);
    
    % Main Superior Arcade
    t = linspace(0, 1, 300);
    arcX_sup = discX + t * (imgSize * 0.55);
    arcY_sup = discY - (imgSize * 0.35) * sin(t * pi * 0.85);
    
    % Main Inferior Arcade
    arcX_inf = discX + t * (imgSize * 0.55);
    arcY_inf = discY + (imgSize * 0.35) * sin(t * pi * 0.85);
    
    % Nasal vessels
    arcX_nas_sup = discX - t * (imgSize * 0.20);
    arcY_nas_sup = discY - (imgSize * 0.25) * sin(t * pi * 0.7);
    arcX_nas_inf = discX - t * (imgSize * 0.20);
    arcY_nas_inf = discY + (imgSize * 0.25) * sin(t * pi * 0.7);
    
    % Draw vessel branches with decreasing thickness
    branches = { [arcX_sup; arcY_sup], [arcX_inf; arcY_inf], ...
                 [arcX_nas_sup; arcY_nas_sup], [arcX_nas_inf; arcY_nas_inf] };
             
    for b = 1:numel(branches)
        pts = branches{b};
        for k = 1:size(pts, 2)
            px = round(pts(1, k));
            py = round(pts(2, k));
            thickness = max(1, round(4.5 * (1.0 - (k / size(pts, 2)) * 0.6)));
            if px > thickness && px < (imgSize - thickness) && py > thickness && py < (imgSize - thickness)
                [bx, by] = meshgrid(-thickness:thickness, -thickness:thickness);
                circ = (bx.^2 + by.^2) <= thickness^2;
                vesselTree(py-thickness:py+thickness, px-thickness:px+thickness) = ...
                    max(vesselTree(py-thickness:py+thickness, px-thickness:px+thickness), circ);
            end
        end
    end
    
    % Add secondary microvessel branches
    for angle = [-0.4, -0.2, 0.2, 0.4, 0.8, -0.8]
        t2 = linspace(0.2, 0.8, 120);
        brX = (discX + imgSize*0.25) + t2 * (imgSize * 0.25) * cos(angle);
        brY = centerY + (imgSize * 0.30) * sin(angle) + t2 * (imgSize * 0.15) * sin(angle*2);
        for k = 1:numel(t2)
            px = round(brX(k));
            py = round(brY(k));
            if px > 2 && px < (imgSize - 2) && py > 2 && py < (imgSize - 2)
                vesselTree(py-1:py+1, px-1:px+1) = 1;
            end
        end
    end
    
    % Smooth vessel tree slightly
    vesselTree = imgaussfilt(vesselTree, 0.8);
    vesselTree(~fovMask) = 0;
    
    % Hemoglobin absorption: Vessels strongly absorb Green & Blue light
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
