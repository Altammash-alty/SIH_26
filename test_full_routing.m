%% TEST_FULL_ROUTING: End-to-End Verification of DR Pipeline & Routing Layer
%
% This script exercises the complete Stage 1-2 pipeline and the Trust/Routing Layer:
%   1. Stage 1: Quality Gate (+quality package)
%   2. Stage 2: Preprocessing & Enhancement (+preprocess package)
%   3. OOD Module: Out-of-Distribution Anomaly Detection (+ood package)
%   4. Stage 4 Stub: DR Severity Grading & Confidence Estimation (+routing package)
%   5. Quality Recheck: Controlled perturbation sensitivity testing
%   6. Second Opinion: Multi-model consensus & disagreement detection
%   7. Decision Layer: Master triage routing logic
%
% Scenarios Tested:
%   - Scenario 1: Clean Normal Retina (Grade 0, Conf 0.94) -> AUTO_CLEAR_SAMPLED
%   - Scenario 2: Blurry / Defocused Retina -> RETAKE (Quality Gate rejection)
%   - Scenario 3: Out-of-Distribution Image (Aberrant color/texture) -> OOD_FLAG
%   - Scenario 4: High-Confidence Severe NPDR (Grade 3, Conf 0.92) -> DOCTOR_REVIEW
%   - Scenario 5: Low-Confidence Image Sensitive to Blur -> RETAKE (Quality-driven)
%   - Scenario 6: Low-Confidence Image Invariant to Blur -> DOCTOR_REVIEW (Medical ambiguity)
%   - Scenario 7: Multi-Model Disagreement (Model 1: Gr 1 vs Model 2: Gr 3) -> MODEL_DISAGREEMENT
%
% Author: DR Screening Pipeline MVP
% Date: 2026-09-02

clear; clc; close all;

fprintf('=========================================================================================\n');
fprintf('     DIABETIC RETINOPATHY SCREENING PIPELINE: STAGES 1-2 + TRUST/ROUTING SUITE          \n');
fprintf('=========================================================================================\n\n');

%% 1. Configuration & Setup
cfg = config();

% Load or ensure baseline reference statistics exist
if ~exist(cfg.ood.statsFilePath, 'file')
    fprintf('[SETUP] Generating baseline reference statistics for OOD module...\n');
    ood.buildReferenceStats([], cfg.ood.statsFilePath, cfg);
end
refStats = load(cfg.ood.statsFilePath);
if isfield(refStats, 'refStats'), refStats = refStats.refStats; end

%% 2. Generate Synthetic Test Dataset Covering All 7 Clinical Scenarios
fprintf('[DATASET] Generating synthetic fundus dataset for 7 screening scenarios...\n\n');

baseFundus = createSyntheticFundus(384, 1);

testCases = struct('name', {}, 'image', {}, 'preset1', {}, 'preset2', {}, ...
                   'expectedDecision', {}, 'description', {});

% --- Scenario 1: Clean Normal Retina ---
testCases(1).name = 'Scenario 1: Clean Normal Retina';
testCases(1).image = baseFundus;
testCases(1).preset1 = 'normal'; % Grade 0, Conf 0.94
testCases(1).preset2 = [];
testCases(1).expectedDecision = 'AUTO_CLEAR_SAMPLED';
testCases(1).description = 'Healthy normal retina; passes quality & OOD; eligible for fast-track tele-triage.';

% --- Scenario 2: Blurry / Motion-Degraded Retina ---
hBlur = fspecial('gaussian', [25 25], 6.0);
blurryImg = imfilter(baseFundus, hBlur, 'replicate');
testCases(2).name = 'Scenario 2: Severely Blurry Retina';
testCases(2).image = blurryImg;
testCases(2).preset1 = 'normal';
testCases(2).preset2 = [];
testCases(2).expectedDecision = 'RETAKE';
testCases(2).description = 'Motion blur / optical defocus fails Stage 1 Quality Gate.';

% --- Scenario 3: Out-of-Distribution Image ---
% Invert colors & shift hues (simulates camera sensor malfunction or non-retinal image)
oodImg = baseFundus;
oodImg(:, :, 1) = baseFundus(:, :, 3) * 1.5; % Invert red/blue balance
oodImg(:, :, 3) = baseFundus(:, :, 1) * 0.8;
testCases(3).name = 'Scenario 3: Out-of-Distribution Retina';
testCases(3).image = oodImg;
testCases(3).preset1 = 'normal';
testCases(3).preset2 = [];
testCases(3).expectedDecision = 'OOD_FLAG';
testCases(3).description = 'Passes quality gate but exhibits severe color/texture statistical drift vs training baseline.';

% --- Scenario 4: High-Confidence Severe NPDR ---
testCases(4).name = 'Scenario 4: High-Confidence Severe DR';
testCases(4).image = baseFundus;
testCases(4).preset1 = 'severe'; % Grade 3, Conf 0.92
testCases(4).preset2 = [];
testCases(4).expectedDecision = 'DOCTOR_REVIEW';
testCases(4).description = 'Referable DR (Grade 3) with high AI confidence; routed to standard doctor queue.';

% --- Scenario 5: Low-Confidence Quality-Sensitive Retina ---
testCases(5).name = 'Scenario 5: Low-Conf Quality-Sensitive Case';
testCases(5).image = baseFundus;
testCases(5).preset1 = 'uncertain'; % Grade 1, Conf 0.58
testCases(5).preset2 = [];
testCases(5).expectedDecision = 'RETAKE';
testCases(5).description = 'Low AI confidence; recheck test reveals grade/confidence collapse under perturbation -> RETAKE.';

% --- Scenario 6: Low-Confidence Clinical Ambiguity Retina ---
testCases(6).name = 'Scenario 6: Low-Conf Medical Ambiguity Case';
testCases(6).image = baseFundus;
testCases(6).preset1 = struct('grade', 2, 'confidence', 0.62); % Grade 2, Conf 0.62
testCases(6).preset2 = [];
testCases(6).expectedDecision = 'DOCTOR_REVIEW';
testCases(6).description = 'Low AI confidence; recheck test remains invariant to perturbation -> genuine medical ambiguity.';

% --- Scenario 7: Multi-Model Disagreement ---
testCases(7).name = 'Scenario 7: Multi-Model Disagreement';
testCases(7).image = baseFundus;
testCases(7).preset1 = struct('grade', 1, 'confidence', 0.88); % Model 1: Mild NPDR (Grade 1)
testCases(7).preset2 = struct('grade', 3, 'confidence', 0.85); % Model 2: Severe NPDR (Grade 3)
testCases(7).expectedDecision = 'MODEL_DISAGREEMENT';
testCases(7).description = 'Two AI models predict conflicting DR grades (Grade 1 vs Grade 3) -> Highest priority specialist triage.';

%% 3. Execute Pipeline Across All Scenarios
results = struct();

for i = 1:numel(testCases)
    tc = testCases(i);
    fprintf('-----------------------------------------------------------------------------------------\n');
    fprintf('  TEST CASE %d: %s\n', i, tc.name);
    fprintf('  Description: %s\n', tc.description);
    fprintf('-----------------------------------------------------------------------------------------\n');

    rawImg = tc.image;
    t0 = tic;

    % =========================================================================
    % STAGE 1: QUALITY GATE
    % =========================================================================
    [isGood, qualityReason, qualityMetrics] = quality.assessQuality(rawImg, cfg);
    fprintf('  [Stage 1 Quality Gate] Result: %s | Sharpness: %.2f | Illum: %.2f\n', ...
        getPassString(isGood), qualityMetrics.blurScore, qualityMetrics.illumScore);
    if ~isGood
        fprintf('                         Failure Reason: %s\n', qualityReason);
    end

    % =========================================================================
    % STAGE 2: PREPROCESSING & ENHANCEMENT
    % =========================================================================
    if isGood
        enhancedImg = preprocess.enhanceImage(rawImg, cfg);
        fprintf('  [Stage 2 Preprocess]   Enhancement: COMPLETE (Illumination Flat + CLAHE + Denoise)\n');
    else
        enhancedImg = rawImg; % Skip enhancement if quality failed
        fprintf('  [Stage 2 Preprocess]   Enhancement: SKIPPED (Quality check failed)\n');
    end

    % =========================================================================
    % OOD DETECTION MODULE
    % =========================================================================
    [isTypical, distScore, oodReason, oodDetails] = ood.checkDistribution(enhancedImg, refStats, cfg);
    fprintf('  [OOD Anomaly Gate]     Typical: %s | Mahalanobis Distance: %.2f (Cutoff: %.2f)\n', ...
        getPassString(isTypical), distScore, cfg.ood.distanceThreshold);
    if ~isTypical
        fprintf('                         OOD Anomaly: %s\n', oodReason);
    end

    % =========================================================================
    % STAGE 4 STUB GRADING
    % =========================================================================
    [grade, confidence, probs] = routing.stubGradeModel(enhancedImg, tc.preset1);
    fprintf('  [Stage 4 Model 1 Stub] Grade: %d (%s) | Confidence: %.1f%%\n', ...
        grade, cfg.classify.grades{grade + 1}, confidence * 100);

    % =========================================================================
    % ROUTING & TRUST DECISION PREPARATION
    % =========================================================================
    extraOpts = struct();
    extraOpts.qualityReason = qualityReason;
    extraOpts.oodReason = oodReason;

    % Check Multi-Model Second Opinion if Model 2 preset provided
    if ~isempty(tc.preset2)
        [grade2, conf2] = routing.stubGradeModel2(enhancedImg, tc.preset2);
        fprintf('  [Stage 4 Model 2 Stub] Grade: %d (%s) | Confidence: %.1f%%\n', ...
            grade2, cfg.classify.grades{grade2 + 1}, conf2 * 100);

        [modelsAgree, disagreeDecision, secDetails] = ...
            routing.secondOpinionCheck([grade, confidence], [grade2, conf2], cfg);
        
        extraOpts.modelsAgree = modelsAgree;
        extraOpts.secondOpinionDetails = secDetails;
        fprintf('  [Second Opinion Check] Models Agree: %s | Grade Diff: %d\n', ...
            getPassString(modelsAgree), secDetails.gradeDiff);
    end

    % Check Low-Confidence Quality Recheck if confidence is below threshold
    if isGood && isTypical && (confidence < cfg.routing.confidenceThreshold)
        % For Scenario 5: simulate quality-sensitivity (collapse under perturbation)
        % For Scenario 6: simulate clinical ambiguity (invariant under perturbation)
        if i == 5
            modelRecheckHandle = @(imgIn) deal(max(0, grade - 1), max(0.35, confidence - 0.22));
        else
            modelRecheckHandle = @(imgIn) deal(grade, confidence - 0.03); % Invariant
        end

        [qualitySensitive, recheckDetails] = routing.qualityRecheckTest(enhancedImg, ...
            grade, confidence, modelRecheckHandle, cfg);

        extraOpts.qualityRecheckDone = true;
        extraOpts.qualitySensitive = qualitySensitive;
        extraOpts.recheckDetails = recheckDetails;

        fprintf('  [Quality Recheck Test] Quality-Sensitive: %s | Delta Conf: %+.2f\n', ...
            getPassString(qualitySensitive), recheckDetails.deltaConf);
        fprintf('                         Diagnostic Note: %s\n', recheckDetails.explanation);
    end

    % =========================================================================
    % MASTER DECISION LAYER
    % =========================================================================
    [decision, reason, sampleForAudit, routingDetails] = routing.decideRouting(...
        isGood, distScore, isTypical, grade, confidence, cfg, extraOpts);

    elapsed = toc(t0);

    % Display Final Decision
    fprintf('\n  >>> FINAL ROUTING DECISION: [%s]\n', decision);
    fprintf('  >>> CLINICAL ACTION REASON: %s\n', reason);
    if strcmp(decision, 'AUTO_CLEAR_SAMPLED')
        fprintf('  >>> 10%% QUALITY AUDIT FLAG : %s\n', mat2str(sampleForAudit));
    end
    fprintf('  >>> Pipeline Latency      : %.2f ms\n\n', elapsed * 1000);

    % Store results for summary table
    results(i).scenario = tc.name;
    results(i).expected = tc.expectedDecision;
    results(i).actual = char(decision);
    results(i).matched = strcmp(results(i).actual, results(i).expected);
    results(i).reason = char(reason);
    results(i).latencyMs = elapsed * 1000;
end

%% 4. Print Overall Verification Summary Table
fprintf('=========================================================================================\n');
fprintf('                           ROUTING LAYER VERIFICATION SUMMARY                            \n');
fprintf('=========================================================================================\n');
fprintf(' %-3s | %-36s | %-20s | %-20s | %-6s \n', '#', 'Scenario Name', 'Expected Routing', 'Actual Routing', 'Status');
fprintf('-----+--------------------------------------+----------------------+----------------------+--------\n');

allPassed = true;
for k = 1:numel(results)
    if results(k).matched
        statusStr = 'PASS';
    else
        statusStr = 'FAIL';
        allPassed = false;
    end
    fprintf(' %-3d | %-36s | %-20s | %-20s | %-6s \n', ...
        k, results(k).scenario, results(k).expected, results(k).actual, statusStr);
end
fprintf('=========================================================================================\n');

if allPassed
    fprintf('  *** ALL 7 ROUTING SCENARIOS PASSED VERIFICATION WITH ZERO DEFECTS! ***\n');
else
    fprintf('  *** SOME ROUTING SCENARIOS DID NOT MATCH EXPECTED OUTCOMES ***\n');
end
fprintf('=========================================================================================\n\n');

%% Local Helper Functions
function str = getPassString(val)
    if val
        str = 'YES (PASS)';
    else
        str = 'NO  (FAIL)';
    end
end

function fundusImg = createSyntheticFundus(imgSize, seed)
    rng(seed * 42);
    [X, Y] = meshgrid(1:imgSize, 1:imgSize);
    centerX = imgSize / 2;
    centerY = imgSize / 2;
    radius = imgSize * 0.44;

    distFromCenter = sqrt((X - centerX).^2 + (Y - centerY).^2);
    fovMask = distFromCenter <= radius;

    radialFalloff = max(0, 1.0 - 0.35 * (distFromCenter / radius).^2);
    radialFalloff(~fovMask) = 0;

    % Retinal pigment layers (Red-Orange base)
    R = (0.76 + 0.04 * sin(X/25) .* cos(Y/25)) .* radialFalloff;
    G = (0.40 + 0.03 * cos(X/20) .* sin(Y/20)) .* radialFalloff;
    B = (0.09 + 0.02 * sin(X/35)) .* radialFalloff;

    % Optic Disc
    discX = centerX - imgSize * 0.20;
    discY = centerY;
    discRadius = imgSize * 0.075;
    distDisc = sqrt((X - discX).^2 + (Y - discY).^2);
    discSoft = max(0, 1.0 - (distDisc / discRadius).^2) .* (distDisc <= discRadius);

    R = R + 0.18 * discSoft;
    G = G + 0.38 * discSoft;
    B = B + 0.22 * discSoft;

    % Vessel Tree
    vesselTree = zeros(imgSize, imgSize);
    t = linspace(0, 1, 220);
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
    noise = randn(imgSize, imgSize) * 0.012;
    noise(~fovMask) = 0;

    R = max(0, min(1, R + noise));
    G = max(0, min(1, G + noise));
    B = max(0, min(1, B + noise));

    R(~fovMask) = 0;
    G(~fovMask) = 0;
    B(~fovMask) = 0;

    fundusImg = cat(3, R, G, B);
end
