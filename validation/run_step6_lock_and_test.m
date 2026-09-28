% run_step6_lock_and_test.m - STEP 6: LOCK AND FINAL TEST
% Run once on test/ and Messidor-2 external generalization cohort.
clear; clc;
rng(2026, 'twister');
addpath(pwd);

fprintf('====================================================================\n');
fprintf('     STEP 6: LOCK PIPELINE AND EXECUTE FINAL HELD-OUT TEST          \n');
fprintf('====================================================================\n\n');

%% 1. Lock the Chosen Model, Cutoff, and Configuration
s = load(fullfile('results', 'steps_2_to_5_workspace.mat'));
bagModel = s.bagModel;
lockedCutoff = s.bestCutBag; % 0.3833
cfg = config();

% Save locked model artifact
lockedModelPath = fullfile('results', 'locked_model_bagged_trees.mat');
featureCols = {'darkCount', 'brightCount', 'darkQ1', 'darkQ2', 'darkQ3', 'darkQ4', ...
               'brightQ1', 'brightQ2', 'brightQ3', 'brightQ4', 'quadsSevere', ...
               'darkArea', 'brightArea', 'vesselDensity', 'vesselTortuosity', ...
               'cupToDiscRatio', 'qualityScore', ...
               'PGrade0', 'PGrade1', 'PGrade2', 'PGrade3', 'PGrade4'};

save(lockedModelPath, 'bagModel', 'lockedCutoff', 'featureCols', 'cfg', '-v7.3');
fprintf('[LOCKED] Model file: %s\n', lockedModelPath);
fprintf('[LOCKED] Operating probability cutoff: %.4f\n', lockedCutoff);

%% 2. Generate SHA-256 Hashes
filesToHash = {
    lockedModelPath;
    fullfile(pwd, 'config.m');
    fullfile(pwd, 'evalReferable.m');
    fullfile(pwd, '+classify', 'gradeDR.m');
    fullfile(pwd, '+segment', 'segmentAll.m')
};

hashFile = fullfile('results', 'model_hashes.txt');
fid = fopen(hashFile, 'w');
fprintf(fid, 'SIH 26038 REFERABLE-DR LOCKED PIPELINE FILE HASHES (SHA-256)\n');
fprintf(fid, 'Generated: %s\n\n', char(datetime('now')));

for i = 1:numel(filesToHash)
    f = filesToHash{i};
    if exist(f, 'file')
        md = java.security.MessageDigest.getInstance('SHA-256');
        bytes = uint8(fileread(f));
        md.update(bytes);
        hashBytes = typecast(md.digest(), 'uint8');
        h = sprintf('%02x', hashBytes);
        fprintf(fid, '%s : %s\n', f, h);
        fprintf('  File: %s -> SHA-256: %s\n', f, h);
    end
end
fclose(fid);
fprintf('SHA-256 file hashes written to %s\n\n', hashFile);

%% 3. Evaluate Held-Out IDRiD TEST Set (n = 103)
fprintf('>>> RUNNING LOCKED PIPELINE ON IDRiD TEST SET (n=103) <<<\n');
[testTbl, ~] = data.loadIDRiDGrading('test');
nTest = height(testTbl);

% Extract features for test set
dark = zeros(nTest, 1); bright = dark; darkArea = dark; brightArea = dark;
qd = zeros(nTest, 4); qb = zeros(nTest, 4); severe = dark; vd = dark; vt = dark;
cdr = dark; qualityScore = dark; probs = zeros(nTest, 5); qpass = false(nTest, 1);

t0 = tic;
for k = 1:nTest
    raw = imread(testTbl.ImagePath{k});
    md = max(size(raw,1), size(raw,2));
    if md > 768, raw = imresize(raw, 768/md); end
    [qpass(k), ~, qm] = quality.assessQuality(raw, cfg);
    if ~isfield(qm, 'mask') || isempty(qm.mask), qm.mask = rgb2gray(raw) > 10; end
    [enh, ~] = preprocess.enhanceImage(raw, cfg);
    seg = segment.segmentAll(enh, qm.mask, cfg);
    [~, ~, ~, ~, ~, ~, ~, det] = classify.gradeDR(enh, seg, cfg);
    f = det.features;
    dark(k) = f.darkCountTotal; bright(k) = f.brightCountTotal;
    darkArea(k) = seg.lesions.darkAreaTotalPixels; brightArea(k) = seg.lesions.brightAreaTotalPixels;
    qd(k, :) = f.quadrantDark; qb(k, :) = f.quadrantBright; severe(k) = f.quadsWithSevereHemo;
    vd(k) = f.vesselDensity; vt(k) = f.vesselTortuosity; cdr(k) = f.cupToDiscRatio;
    qualityScore(k) = qm.overallScore; probs(k, :) = det.nnProbs;
    if mod(k, 15) == 0 || k == nTest
        fprintf('  Processed %d/%d test images (%.1f s)...\n', k, nTest, toc(t0));
    end
end

labelsTest = testTbl.ReferableDR;
testFeaturesTbl = table(testTbl.ImageName, testTbl.DRGrade, labelsTest, dark, bright, ...
    qd(:,1), qd(:,2), qd(:,3), qd(:,4), qb(:,1), qb(:,2), qb(:,3), qb(:,4), severe, ...
    darkArea, brightArea, vd, vt, cdr, qualityScore, qpass, ...
    probs(:,1), probs(:,2), probs(:,3), probs(:,4), probs(:,5), ...
    'VariableNames', {'ImageName', 'Grade', 'Referable', 'darkCount', 'brightCount', ...
    'darkQ1', 'darkQ2', 'darkQ3', 'darkQ4', 'brightQ1', 'brightQ2', 'brightQ3', 'brightQ4', ...
    'quadsSevere', 'darkArea', 'brightArea', 'vesselDensity', 'vesselTortuosity', ...
    'cupToDiscRatio', 'qualityScore', 'qualityPass', ...
    'PGrade0', 'PGrade1', 'PGrade2', 'PGrade3', 'PGrade4'});

save(fullfile('results', 'features_test.mat'), 'testFeaturesTbl', 'cfg', '-v7.3');

% Evaluate model predictions
X_test = testFeaturesTbl{:, featureCols};
[~, testScores] = predict(bagModel, X_test);
testProbRef = testScores(:, 2);
testPred = testProbRef >= lockedCutoff;

testEval = evalReferable(testProbRef, labelsTest, lockedCutoff);
[~, ~, ~, testAUC] = perfcurve(labelsTest, testProbRef, true);

fprintf('\n=================================================================\n');
fprintf('                IDRiD TEST SET FINAL EVALUATION                  \n');
fprintf('=================================================================\n');
fprintf('Total Test Images (N):        %d\n', testEval.n);
fprintf('Referable Cases (Grade 2-4):  %d\n', sum(labelsTest));
fprintf('Non-Referable (Grade 0-1):    %d\n', sum(~labelsTest));
fprintf('ROC AUC:                      %.4f\n', testAUC);
fprintf('Sensitivity (95%% CI):        %.2f%% [%.2f%%, %.2f%%] (%d/%d)\n', ...
    testEval.sensitivity*100, testEval.sensitivityCI(1)*100, testEval.sensitivityCI(2)*100, testEval.TP, testEval.TP+testEval.FN);
fprintf('Specificity (95%% CI):        %.2f%% [%.2f%%, %.2f%%] (%d/%d)\n', ...
    testEval.specificity*100, testEval.specificityCI(1)*100, testEval.specificityCI(2)*100, testEval.TN, testEval.TN+testEval.FP);
fprintf('Binary Confusion Matrix [TN, FP; FN, TP]:\n');
disp(testEval.confusion);

% Compare with targets
passSens = testEval.sensitivity > 0.90;
passSpec = testEval.specificity > 0.85;
fprintf('\n--- BENCHMARK VERDICT vs MathWorks SIH 26038 TARGETS ---\n');
fprintf('Sensitivity > 90%%: %s (Actual: %.2f%%)\n', char(matlab.lang.OnOffSwitchState(passSens)), testEval.sensitivity*100);
fprintf('Specificity > 85%%: %s (Actual: %.2f%%)\n', char(matlab.lang.OnOffSwitchState(passSpec)), testEval.specificity*100);

% Selection vs Test Gap
selData = load(fullfile('results', 'features_selection.mat'));
X_sel = selData.tbl{:, featureCols};
[~, selScores] = predict(bagModel, X_sel);
selEval = evalReferable(selScores(:, 2), selData.tbl.Referable, lockedCutoff);
sensGap = (testEval.sensitivity - selEval.sensitivity) * 100;
specGap = (testEval.specificity - selEval.specificity) * 100;

fprintf('\n--- SELECTION -> TEST GENERALIZATION GAP ---\n');
fprintf('SELECTION Sensitivity: %.2f%%  -->  TEST Sensitivity: %.2f%%  (Gap: %+.2f%%)\n', ...
    selEval.sensitivity*100, testEval.sensitivity*100, sensGap);
fprintf('SELECTION Specificity: %.2f%%  -->  TEST Specificity: %.2f%%  (Gap: %+.2f%%)\n', ...
    selEval.specificity*100, testEval.specificity*100, specGap);

% Per-grade accuracy on test
fprintf('\nTest Breakdown by Ground Truth Grade:\n');
for g = 0:4
    gIdx = (testFeaturesTbl.Grade == g);
    nG = sum(gIdx);
    gReferred = sum(testPred(gIdx));
    if g >= 2
        fprintf('  Grade %d (Referable):     %d/%d (%.1f%%) correctly referred\n', g, gReferred, nG, (gReferred/max(1,nG))*100);
    else
        fprintf('  Grade %d (Non-Referable): %d/%d (%.1f%%) correctly cleared (%d falsely referred)\n', ...
            g, nG - gReferred, nG, ((nG - gReferred)/max(1,nG))*100, gReferred);
    end
end

% Save detailed CSV
testReportTbl = table(testTbl.ImageName, testTbl.DRGrade, labelsTest, testProbRef, testPred, ...
    testFeaturesTbl.darkCount, testFeaturesTbl.brightCount, testFeaturesTbl.vesselDensity, ...
    'VariableNames', {'ImageName', 'ActualGrade', 'ReferableActual', 'ReferableProb', 'ReferablePred', ...
    'DarkCount', 'BrightCount', 'VesselDensity'});
writetable(testReportTbl, fullfile('results', 'test_evaluation_report.csv'));

%% 4. Messidor-2 External Cohort Generalization Check (No Retuning)
fprintf('\n>>> RUNNING LOCKED PIPELINE ON MESSIDOR-2 COHORT <<<\n');
[m2Tbl, ~] = data.loadMessidor2();
% Sample 50 representative cases across different patient sessions
nM2Sample = min(50, height(m2Tbl));
rng(2026, 'twister');
sampleIdxs = randperm(height(m2Tbl), nM2Sample);
m2Sample = m2Tbl(sampleIdxs, :);

m2Dark = zeros(nM2Sample, 1); m2Bright = m2Dark; m2DarkArea = m2Dark; m2BrightArea = m2Dark;
m2Qd = zeros(nM2Sample, 4); m2Qb = zeros(nM2Sample, 4); m2Severe = m2Dark;
m2Vd = m2Dark; m2Vt = m2Dark; m2Cdr = m2Dark; m2QualityScore = m2Dark; m2Qpass = false(nM2Sample, 1);
m2Probs = zeros(nM2Sample, 5);

tM2 = tic;
for k = 1:nM2Sample
    raw = imread(m2Sample.ImagePath{k});
    md = max(size(raw,1), size(raw,2));
    if md > 768, raw = imresize(raw, 768/md); end
    [m2Qpass(k), ~, qm] = quality.assessQuality(raw, cfg);
    if ~isfield(qm, 'mask') || isempty(qm.mask), qm.mask = rgb2gray(raw) > 10; end
    [enh, ~] = preprocess.enhanceImage(raw, cfg);
    seg = segment.segmentAll(enh, qm.mask, cfg);
    [~, ~, ~, ~, ~, ~, ~, det] = classify.gradeDR(enh, seg, cfg);
    f = det.features;
    m2Dark(k) = f.darkCountTotal; m2Bright(k) = f.brightCountTotal;
    m2DarkArea(k) = seg.lesions.darkAreaTotalPixels; m2BrightArea(k) = seg.lesions.brightAreaTotalPixels;
    m2Qd(k, :) = f.quadrantDark; m2Qb(k, :) = f.quadrantBright; m2Severe(k) = f.quadsWithSevereHemo;
    m2Vd(k) = f.vesselDensity; m2Vt(k) = f.vesselTortuosity; m2Cdr(k) = f.cupToDiscRatio;
    m2QualityScore(k) = qm.overallScore; m2Probs(k, :) = det.nnProbs;
end

m2FeaturesTbl = table(m2Sample.ImageName, m2Dark, m2Bright, ...
    m2Qd(:,1), m2Qd(:,2), m2Qd(:,3), m2Qd(:,4), m2Qb(:,1), m2Qb(:,2), m2Qb(:,3), m2Qb(:,4), m2Severe, ...
    m2DarkArea, m2BrightArea, m2Vd, m2Vt, m2Cdr, m2QualityScore, m2Qpass, ...
    m2Probs(:,1), m2Probs(:,2), m2Probs(:,3), m2Probs(:,4), m2Probs(:,5), ...
    'VariableNames', {'ImageName', 'darkCount', 'brightCount', ...
    'darkQ1', 'darkQ2', 'darkQ3', 'darkQ4', 'brightQ1', 'brightQ2', 'brightQ3', 'brightQ4', ...
    'quadsSevere', 'darkArea', 'brightArea', 'vesselDensity', 'vesselTortuosity', ...
    'cupToDiscRatio', 'qualityScore', 'qualityPass', ...
    'PGrade0', 'PGrade1', 'PGrade2', 'PGrade3', 'PGrade4'});

X_m2 = m2FeaturesTbl{:, featureCols};
[~, m2Scores] = predict(bagModel, X_m2);
m2ProbRef = m2Scores(:, 2);
m2PredRef = m2ProbRef >= lockedCutoff;

fprintf('\n--- MESSIDOR-2 GENERALIZATION CHECK (n=%d images) ---\n', nM2Sample);
fprintf('Quality Gate Pass Rate:   %.1f%% (%d/%d)\n', mean(m2Qpass)*100, sum(m2Qpass), nM2Sample);
fprintf('Mean Image Quality Score: %.2f / 100\n', mean(m2QualityScore));
fprintf('Predicted Referral Rate:  %.1f%% (%d/%d flagged as Referable DR)\n', ...
    mean(m2PredRef)*100, sum(m2PredRef), nM2Sample);
fprintf('Mean False Lesion Counts: Dark = %.1f, Bright = %.1f\n', mean(m2Dark), mean(m2Bright));
fprintf('Average Pipeline Latency: %.2f seconds per image\n', toc(tM2) / nM2Sample);

save(fullfile('results', 'step6_test_and_messidor2_workspace.mat'), ...
    'testEval', 'testAUC', 'testReportTbl', 'm2FeaturesTbl', 'm2ProbRef', 'm2PredRef', ...
    'lockedCutoff', 'sensGap', 'specGap');

fprintf('\nStep 6 completed successfully. Results saved in results/\n');
