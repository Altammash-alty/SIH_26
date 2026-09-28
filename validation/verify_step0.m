% verify_step0.m - Step 0: Re-establish starting point on SELECTION
clear; clc;
addpath(pwd);

% Load SELECTION features and baseline report
baseTbl = readtable(fullfile('results', 'baseline_report.csv'));
selData = load(fullfile('results', 'features_selection.mat'));
selTbl = selData.tbl;

fprintf('=== STEP 0: STARTING POINT RE-ESTABLISHMENT (SELECTION split, n=%d) ===\n\n', height(selTbl));

% Ground truth
gtLabels = selTbl.Referable; % Grade >= 2
gtGrades = selTbl.Grade;
isG0 = (gtGrades == 0);
nG0 = sum(isG0);

% 1. Method A: Baseline
baseScores = baseTbl.PredictedGrade;
baseEval = evalReferable(baseScores, gtLabels, 2);
baseMeanDarkG0 = mean(baseTbl.DarkCount(isG0));
baseMeanBrightG0 = mean(baseTbl.BrightCount(isG0));
baseMeanTotalG0 = mean(baseTbl.DarkCount(isG0) + baseTbl.BrightCount(isG0));

fprintf('--- METHOD A: BASELINE ---\n');
fprintf('N: %d\n', baseEval.n);
fprintf('Sensitivity: %.2f%% (95%% CI: [%.2f%%, %.2f%%]) [%d/%d]\n', ...
    baseEval.sensitivity*100, baseEval.sensitivityCI(1)*100, baseEval.sensitivityCI(2)*100, baseEval.TP, baseEval.TP+baseEval.FN);
fprintf('Specificity: %.2f%% (95%% CI: [%.2f%%, %.2f%%]) [%d/%d]\n', ...
    baseEval.specificity*100, baseEval.specificityCI(1)*100, baseEval.specificityCI(2)*100, baseEval.TN, baseEval.TN+baseEval.FP);
fprintf('Binary Confusion Matrix [TN, FP; FN, TP]:\n');
disp(baseEval.confusion);
fprintf('Grade 0 False Lesions (n=%d): Mean Dark=%.2f, Mean Bright=%.2f, Mean Total=%.2f\n\n', ...
    nG0, baseMeanDarkG0, baseMeanBrightG0, baseMeanTotalG0);

% 2. Method B: Calibrated Params with Gate OFF
bScores = selTbl.gradeNoGate;
bEval = evalReferable(bScores, gtLabels, 2);
bMeanDarkG0 = mean(selTbl.darkCount(isG0));
bMeanBrightG0 = mean(selTbl.brightCount(isG0));
bMeanTotalG0 = mean(selTbl.darkCount(isG0) + selTbl.brightCount(isG0));

fprintf('--- METHOD B: CALIBRATED (GATE OFF) ---\n');
fprintf('N: %d\n', bEval.n);
fprintf('Sensitivity: %.2f%% (95%% CI: [%.2f%%, %.2f%%]) [%d/%d]\n', ...
    bEval.sensitivity*100, bEval.sensitivityCI(1)*100, bEval.sensitivityCI(2)*100, bEval.TP, bEval.TP+bEval.FN);
fprintf('Specificity: %.2f%% (95%% CI: [%.2f%%, %.2f%%]) [%d/%d]\n', ...
    bEval.specificity*100, bEval.specificityCI(1)*100, bEval.specificityCI(2)*100, bEval.TN, bEval.TN+bEval.FP);
fprintf('Binary Confusion Matrix [TN, FP; FN, TP]:\n');
disp(bEval.confusion);
fprintf('Grade 0 False Lesions (n=%d): Mean Dark=%.2f, Mean Bright=%.2f, Mean Total=%.2f\n\n', ...
    nG0, bMeanDarkG0, bMeanBrightG0, bMeanTotalG0);

% 3. Method C: Calibrated Params with Gate ON
cScores = selTbl.gradeGate;
cEval = evalReferable(cScores, gtLabels, 2);
cMeanDarkG0 = bMeanDarkG0; % Same segmentation features
cMeanBrightG0 = bMeanBrightG0;
cMeanTotalG0 = bMeanTotalG0;

fprintf('--- METHOD C: CALIBRATED (GATE ON) ---\n');
fprintf('N: %d\n', cEval.n);
fprintf('Sensitivity: %.2f%% (95%% CI: [%.2f%%, %.2f%%]) [%d/%d]\n', ...
    cEval.sensitivity*100, cEval.sensitivityCI(1)*100, cEval.sensitivityCI(2)*100, cEval.TP, cEval.TP+cEval.FN);
fprintf('Specificity: %.2f%% (95%% CI: [%.2f%%, %.2f%%]) [%d/%d]\n', ...
    cEval.specificity*100, cEval.specificityCI(1)*100, cEval.specificityCI(2)*100, cEval.TN, cEval.TN+cEval.FP);
fprintf('Binary Confusion Matrix [TN, FP; FN, TP]:\n');
disp(cEval.confusion);
fprintf('Grade 0 False Lesions (n=%d): Mean Dark=%.2f, Mean Bright=%.2f, Mean Total=%.2f\n\n', ...
    nG0, cMeanDarkG0, cMeanBrightG0, cMeanTotalG0);

% Save Step 0 results
step0_results = struct('baseEval', baseEval, 'bEval', bEval, 'cEval', cEval, ...
    'baseG0', [baseMeanDarkG0, baseMeanBrightG0, baseMeanTotalG0], ...
    'calibG0', [bMeanDarkG0, bMeanBrightG0, bMeanTotalG0]);
save(fullfile('results', 'step0_results.mat'), 'step0_results');
fprintf('Step 0 complete. Saved to results/step0_results.mat\n');
