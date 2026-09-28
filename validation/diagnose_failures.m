% diagnose_failures.m - Detailed failure analysis for Step 5
clear; clc;
s = load(fullfile('results', 'steps_2_to_5_workspace.mat'));
selData = load(fullfile('results', 'features_selection.mat'));
selTbl = selData.tbl;

y_true = selTbl.Referable;
% Method 6: Bagged Trees
bagPred = s.allPreds(:, 6);

fn_idx = find(y_true & ~bagPred);
fp_idx = find(~y_true & bagPred);
tp_idx = find(y_true & bagPred);
tn_idx = find(~y_true & ~bagPred);

fprintf('=== STEP 5: DETAILED ERROR DIAGNOSIS (BAG-TREES MODEL) ===\n\n');
fprintf('Total SELECTION: %d\n', height(selTbl));
fprintf('TP: %d, FN: %d, TN: %d, FP: %d\n\n', numel(tp_idx), numel(fn_idx), numel(tn_idx), numel(fp_idx));

fprintf('--- 5 FALSE NEGATIVES (MISSED REFERABLE CASES) ---\n');
fnTbl = selTbl(fn_idx, {'ImageName', 'Grade', 'darkCount', 'brightCount', 'darkArea', 'brightArea', 'vesselDensity', 'qualityScore', 'PGrade2', 'PGrade3'});
disp(fnTbl);

fprintf('--- 24 FALSE POSITIVES (NORMAL/MILD CALLED REFERABLE) ---\n');
fpTbl = selTbl(fp_idx, {'ImageName', 'Grade', 'darkCount', 'brightCount', 'darkArea', 'brightArea', 'vesselDensity', 'qualityScore'});
fprintf('FP breakdown by true grade:\n');
tabulate(fpTbl.Grade);

fprintf('\nMean stats for False Positives vs True Negatives:\n');
fprintf('FP (n=%d): Mean darkCount=%.2f, Mean brightCount=%.2f, Mean vesselDensity=%.2f, Mean qualityScore=%.2f\n', ...
    numel(fp_idx), mean(fpTbl.darkCount), mean(fpTbl.brightCount), mean(fpTbl.vesselDensity), mean(fpTbl.qualityScore));
tnTbl = selTbl(tn_idx, {'ImageName', 'Grade', 'darkCount', 'brightCount', 'darkArea', 'brightArea', 'vesselDensity', 'qualityScore'});
fprintf('TN (n=%d): Mean darkCount=%.2f, Mean brightCount=%.2f, Mean vesselDensity=%.2f, Mean qualityScore=%.2f\n', ...
    numel(tn_idx), mean(tnTbl.darkCount), mean(tnTbl.brightCount), mean(tnTbl.vesselDensity), mean(tnTbl.qualityScore));

% Save diagnostic table
writetable(fnTbl, fullfile('results', 'step5_false_negatives.csv'));
writetable(fpTbl, fullfile('results', 'step5_false_positives.csv'));
