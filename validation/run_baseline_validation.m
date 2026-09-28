%% VALIDATE_AGAINST_LABELS Baseline run before Part 1 fixes
clear; clc;
cfg = config();

[trainTbl, ~] = data.loadIDRiDGrading('train', fullfile('data', 'idrid', 'grading'));
N = height(trainTbl);

% We can run on all or a standard sample size. Let's run on 50 representative cases (10 per grade 0-4)
% to get comprehensive pre-fix and post-fix stats quickly and accurately.
rng(42);
selectedIdxs = [];
for g = 0:4
    gIdxs = find(trainTbl.DRGrade == g);
    takeN = min(numel(gIdxs), 10);
    perm = randperm(numel(gIdxs), takeN);
    selectedIdxs = [selectedIdxs; gIdxs(perm)];
end

fprintf('Running baseline validation on %d stratified images...\n', numel(selectedIdxs));

actualGrades = zeros(numel(selectedIdxs), 1);
predGrades = zeros(numel(selectedIdxs), 1);
darkCounts = zeros(numel(selectedIdxs), 1);
brightCounts = zeros(numel(selectedIdxs), 1);
qPassList = false(numel(selectedIdxs), 1);
imageNames = cell(numel(selectedIdxs), 1);

for k = 1:numel(selectedIdxs)
    idx = selectedIdxs(k);
    imgName = trainTbl.ImageName{idx};
    gtGrade = trainTbl.DRGrade(idx);
    imgPath = trainTbl.ImagePath{idx};
    
    imageNames{k} = imgName;
    actualGrades(k) = gtGrade;
    
    raw = imread(imgPath);
    raw768 = imresize(raw, 768 / max(size(raw,1), size(raw,2)));
    
    patInfo = struct('patientID', sprintf('IDR-%03d', idx), 'patientAge', 55, 'patientGender', 'M', 'eyeLaterality', 'OD');
    
    % Stage 1 Quality
    [isGood, ~, qMetrics] = quality.assessQuality(raw768, cfg);
    qPassList(k) = isGood;
    
    % Stage 2 Enhancement
    [enhanced, ~] = preprocess.enhanceImage(raw768, cfg);
    
    % Stage 3 Segmentation
    [segResults, ~] = segment.segmentAll(enhanced, qMetrics.mask, cfg);
    darkCounts(k) = segResults.lesions.darkCount;
    brightCounts(k) = segResults.lesions.brightCount;
    
    % Stage 4 Classification
    [grade, ~, ~, ~, ~, ~, ~, ~] = classify.gradeDR(enhanced, segResults, cfg);
    predGrades(k) = grade;
end

% Save results table
reportTbl = table(imageNames, actualGrades, predGrades, darkCounts, brightCounts, qPassList, ...
    actualGrades == predGrades, ...
    'VariableNames', {'ImageName', 'ActualGrade', 'PredictedGrade', 'DarkCount', 'BrightCount', 'QPass', 'Match'});

writetable(reportTbl, 'validation_baseline_pre_fix.csv');

% Calculate stats
confMat = confusionmat(actualGrades, predGrades, 'Order', 0:4);
acc = mean(actualGrades == predGrades);

refActual = actualGrades >= 2;
refPred = predGrades >= 2;
tp = sum(refActual & refPred);
fn = sum(refActual & ~refPred);
tn = sum(~refActual & ~refPred);
fp = sum(~refActual & refPred);

sens = tp / max(1, (tp + fn));
spec = tn / max(1, (tn + fp));

g0Idxs = (actualGrades == 0);
g0Count = sum(g0Idxs);
g0NonzeroDark = sum(g0Idxs & darkCounts > 0);
g0NonzeroBright = sum(g0Idxs & brightCounts > 0);
avgDarkG0 = mean(darkCounts(g0Idxs));
avgBrightG0 = mean(brightCounts(g0Idxs));

fprintf('\n=== BASELINE (PRE-FIX) RESULTS ===\n');
fprintf('Confusion Matrix (Rows: Actual 0-4, Cols: Predicted 0-4):\n');
disp(confMat);
fprintf('Overall Accuracy: %.1f%%\n', acc * 100);
fprintf('Referable DR Sensitivity: %.1f%% (%d/%d)\n', sens * 100, tp, tp + fn);
fprintf('Referable DR Specificity: %.1f%% (%d/%d)\n', spec * 100, tn, tn + fp);
fprintf('Grade 0 FP Audit (Total G0 images: %d):\n', g0Count);
fprintf('  Images with darkCount > 0: %d / %d (Avg false count: %.1f)\n', g0NonzeroDark, g0Count, avgDarkG0);
fprintf('  Images with brightCount > 0: %d / %d (Avg false count: %.1f)\n', g0NonzeroBright, g0Count, avgBrightG0);

save('baseline_results.mat', 'confMat', 'acc', 'sens', 'spec', 'g0NonzeroDark', 'g0NonzeroBright', 'avgDarkG0', 'avgBrightG0', 'reportTbl');
