% run_steps_2_to_5.m - Execution of Steps 2, 3, 4, 5 for SIH 26038 Referable-DR
clear; clc;
rng(2026, 'twister');

% 1. Load cached features
tuneData = load(fullfile('results', 'features_tune.mat'));
selData  = load(fullfile('results', 'features_selection.mat'));
tuneTbl  = tuneData.tbl;
selTbl   = selData.tbl;

fprintf('====================================================================\n');
fprintf('   REFERABLE-DR OPTIMIZATION: STEPS 2, 3, 4, 5 ON TUNE & SELECTION   \n');
fprintf('====================================================================\n');
fprintf('TUNE samples: %d (Referable: %d, Non-referable: %d)\n', ...
    height(tuneTbl), sum(tuneTbl.Referable), sum(~tuneTbl.Referable));
fprintf('SELECTION samples: %d (Referable: %d, Non-referable: %d)\n', ...
    height(selTbl), sum(selTbl.Referable), sum(~selTbl.Referable));

%% ====================================================================
%  STEP 2: ROC-BASED OPERATING POINTS (No Retraining)
%  ====================================================================
fprintf('\n>>> STEP 2: ROC-BASED OPERATING POINTS <<<\n');

% Feature definitions
% Candidate a: Network P(Grade >= 2)
tune_score_a = tuneTbl.PGrade2 + tuneTbl.PGrade3 + tuneTbl.PGrade4;
sel_score_a  = selTbl.PGrade2 + selTbl.PGrade3 + selTbl.PGrade4;

% Candidate b1: Lesion count (dark + bright)
tune_score_b1 = tuneTbl.darkCount + tuneTbl.brightCount;
sel_score_b1  = selTbl.darkCount + selTbl.brightCount;

% Candidate b2: Lesion area (darkArea + brightArea)
tune_score_b2 = tuneTbl.darkArea + tuneTbl.brightArea;
sel_score_b2  = selTbl.darkArea + selTbl.brightArea;

% Candidate b3: Weighted lesion burden: darkCount + 2*brightCount + 0.1*brightArea
tune_score_b3 = tuneTbl.darkCount + 2.0*tuneTbl.brightCount + 0.05*tuneTbl.brightArea;
sel_score_b3  = selTbl.darkCount + 2.0*selTbl.brightCount + 0.05*selTbl.brightArea;

% Candidate c: Blend of network and lesion count
tune_rescaled_b = (tune_score_b1 - min(tune_score_b1)) / (max(tune_score_b1) - min(tune_score_b1) + eps);
sel_rescaled_b  = (sel_score_b1 - min(tune_score_b1)) / (max(tune_score_b1) - min(tune_score_b1) + eps);
tune_score_c = 0.5 * tune_score_a + 0.5 * tune_rescaled_b;
sel_score_c  = 0.5 * sel_score_a + 0.5 * sel_rescaled_b;

candNames = {
    'Network P(Grade>=2)';
    'Lesion Count (Dark+Bright)';
    'Lesion Area (Dark+Bright)';
    'Weighted Lesion Burden';
    'Network + Lesion Blend'
};
candTuneScores = {tune_score_a, tune_score_b1, tune_score_b2, tune_score_b3, tune_score_c};
candSelScores  = {sel_score_a, sel_score_b1, sel_score_b2, sel_score_b3, sel_score_c};

step2_results = cell(numel(candNames), 1);

for i = 1:numel(candNames)
    tScores = candTuneScores{i};
    sScores = candSelScores{i};
    
    % ROC and AUC on TUNE
    [~, ~, ~, tuneAUC] = perfcurve(tuneTbl.Referable, tScores, true);
    [~, ~, ~, selAUC]  = perfcurve(selTbl.Referable, sScores, true);
    
    % Pick cutoff giving sensitivity >= 92% on TUNE with highest specificity
    uVals = unique(tScores);
    cutCandidates = [-Inf; uVals(:); Inf];
    bestSpec = -Inf;
    bestCut = Inf;
    
    for c = cutCandidates'
        ev = evalReferable(tScores, tuneTbl.Referable, c);
        if ev.sensitivity >= 0.92 && ev.specificity > bestSpec
            bestSpec = ev.specificity;
            bestCut = c;
        end
    end
    
    % If strict >=0.92 was unreachable, find max sensitivity
    if isinf(bestCut)
        for c = cutCandidates'
            ev = evalReferable(tScores, tuneTbl.Referable, c);
            if ev.sensitivity >= 0.85 && ev.specificity > bestSpec
                bestSpec = ev.specificity;
                bestCut = c;
            end
        end
    end
    
    % Evaluate fixed cutoff on SELECTION
    tuneEval = evalReferable(tScores, tuneTbl.Referable, bestCut);
    selEval  = evalReferable(sScores, selTbl.Referable, bestCut);
    
    resRow = struct();
    resRow.Candidate = candNames{i};
    resRow.Cutoff = bestCut;
    resRow.TuneAUC = tuneAUC;
    resRow.TuneSens = tuneEval.sensitivity;
    resRow.TuneSpec = tuneEval.specificity;
    resRow.SelAUC = selAUC;
    resRow.SelSens = selEval.sensitivity;
    resRow.SelSensCI = selEval.sensitivityCI;
    resRow.SelSpec = selEval.specificity;
    resRow.SelSpecCI = selEval.specificityCI;
    resRow.TP = selEval.TP; resRow.FN = selEval.FN;
    resRow.TN = selEval.TN; resRow.FP = selEval.FP;
    step2_results{i} = resRow;
    
    fprintf('%s:\n', candNames{i});
    fprintf('  Cutoff (fit on TUNE): %.4f\n', bestCut);
    fprintf('  TUNE:      AUC=%.3f, Sens=%.1f%%, Spec=%.1f%%\n', tuneAUC, tuneEval.sensitivity*100, tuneEval.specificity*100);
    fprintf('  SELECTION: AUC=%.3f, Sens=%.1f%% [%.1f%%, %.1f%%], Spec=%.1f%% [%.1f%%, %.1f%%] (TP=%d, FN=%d, TN=%d, FP=%d)\n', ...
        selAUC, selEval.sensitivity*100, selEval.sensitivityCI(1)*100, selEval.sensitivityCI(2)*100, ...
        selEval.specificity*100, selEval.specificityCI(1)*100, selEval.specificityCI(2)*100, ...
        selEval.TP, selEval.FN, selEval.TN, selEval.FP);
end

%% ====================================================================
%  STEP 3: TRAINED FEATURE CLASSIFIERS ON TUNE
%  ====================================================================
fprintf('\n>>> STEP 3: TRAINED FEATURE CLASSIFIERS <<<\n');

% Define feature matrix
featureCols = {'darkCount', 'brightCount', 'darkQ1', 'darkQ2', 'darkQ3', 'darkQ4', ...
               'brightQ1', 'brightQ2', 'brightQ3', 'brightQ4', 'quadsSevere', ...
               'darkArea', 'brightArea', 'vesselDensity', 'vesselTortuosity', ...
               'cupToDiscRatio', 'qualityScore', ...
               'PGrade0', 'PGrade1', 'PGrade2', 'PGrade3', 'PGrade4'};

X_tune = tuneTbl{:, featureCols};
y_tune = tuneTbl.Referable;
X_sel  = selTbl{:, featureCols};
y_sel  = selTbl.Referable;

% Cost matrix penalizing FN 3x more than FP: Cost(i,j) is cost of predicting j when true is i
% Row 1 = Non-referable (0), Row 2 = Referable (1)
% Cost(2,1) = Cost of predicting Non-referable when Referable (False Negative) = 3
costMat = [0 1; 3 0];

cvp = cvpartition(y_tune, 'KFold', 5);

% 3.1: Decision Tree
fprintf('Training Decision Tree (fitctree)...\n');
treeModel = fitctree(X_tune, y_tune, 'Cost', costMat, 'PredictorNames', featureCols);
cvTree = crossval(treeModel, 'CVPartition', cvp);
[~, cvTreeScores] = kfoldPredict(cvTree);
cvTreeProbRef = cvTreeScores(:, 2);

% Choose cutoff on TUNE CV
candCuts = unique(cvTreeProbRef); candCuts = [-Inf; candCuts(:); Inf];
bestSpecTree = -Inf; bestCutTree = 0.5;
for c = candCuts'
    ev = evalReferable(cvTreeProbRef, y_tune, c);
    if ev.sensitivity >= 0.92 && ev.specificity > bestSpecTree
        bestSpecTree = ev.specificity;
        bestCutTree = c;
    end
end
treeEvalTune = evalReferable(cvTreeProbRef, y_tune, bestCutTree);
[~, selTreeScores] = predict(treeModel, X_sel);
treeEvalSel = evalReferable(selTreeScores(:, 2), y_sel, bestCutTree);
[~,~,~,treeTuneAUC] = perfcurve(y_tune, cvTreeProbRef, true);
[~,~,~,treeSelAUC]  = perfcurve(y_sel, selTreeScores(:, 2), true);
treeImportance = predictorImportance(treeModel);

fprintf('  Tree: TUNE CV AUC=%.3f, Sens=%.1f%%, Spec=%.1f%% (Cut=%.4f)\n', ...
    treeTuneAUC, treeEvalTune.sensitivity*100, treeEvalTune.specificity*100, bestCutTree);
fprintf('        SELECTION: AUC=%.3f, Sens=%.1f%% [%.1f%%, %.1f%%], Spec=%.1f%% [%.1f%%, %.1f%%]\n', ...
    treeSelAUC, treeEvalSel.sensitivity*100, treeEvalSel.sensitivityCI(1)*100, treeEvalSel.sensitivityCI(2)*100, ...
    treeEvalSel.specificity*100, treeEvalSel.specificityCI(1)*100, treeEvalSel.specificityCI(2)*100);

% 3.2: Ensemble of Trees (Bagged Trees / Random Forest)
fprintf('Training Bagged Trees Ensemble (fitcensemble - Bag)...\n');
bagTemplate = templateTree('Cost', costMat, 'Reproducible', true);
bagModel = fitcensemble(X_tune, y_tune, 'Method', 'Bag', 'NumLearningCycles', 60, ...
    'Learners', bagTemplate, 'PredictorNames', featureCols);
cvBag = crossval(bagModel, 'CVPartition', cvp);
[~, cvBagScores] = kfoldPredict(cvBag);
cvBagProbRef = cvBagScores(:, 2);

candCuts = unique(cvBagProbRef); candCuts = [-Inf; candCuts(:); Inf];
bestSpecBag = -Inf; bestCutBag = 0.5;
for c = candCuts'
    ev = evalReferable(cvBagProbRef, y_tune, c);
    if ev.sensitivity >= 0.92 && ev.specificity > bestSpecBag
        bestSpecBag = ev.specificity;
        bestCutBag = c;
    end
end
bagEvalTune = evalReferable(cvBagProbRef, y_tune, bestCutBag);
[~, selBagScores] = predict(bagModel, X_sel);
bagEvalSel = evalReferable(selBagScores(:, 2), y_sel, bestCutBag);
[~,~,~,bagTuneAUC] = perfcurve(y_tune, cvBagProbRef, true);
[~,~,~,bagSelAUC]  = perfcurve(y_sel, selBagScores(:, 2), true);
bagImportance = oobPermutedPredictorImportance(bagModel);

fprintf('  Bagged Trees: TUNE CV AUC=%.3f, Sens=%.1f%%, Spec=%.1f%% (Cut=%.4f)\n', ...
    bagTuneAUC, bagEvalTune.sensitivity*100, bagEvalTune.specificity*100, bestCutBag);
fprintf('        SELECTION: AUC=%.3f, Sens=%.1f%% [%.1f%%, %.1f%%], Spec=%.1f%% [%.1f%%, %.1f%%]\n', ...
    bagSelAUC, bagEvalSel.sensitivity*100, bagEvalSel.sensitivityCI(1)*100, bagEvalSel.sensitivityCI(2)*100, ...
    bagEvalSel.specificity*100, bagEvalSel.specificityCI(1)*100, bagEvalSel.specificityCI(2)*100);

% 3.3: Boosted Trees (GentleBoost)
fprintf('Training Boosted Trees (fitcensemble - GentleBoost)...\n');
boostTemplate = templateTree('MaxNumSplits', 10);
% Fit GentleBoost with class weights or cost
weights = ones(size(y_tune));
weights(y_tune == true) = 2.5; % Weight positive (referable) class more heavily
boostModel = fitcensemble(X_tune, y_tune, 'Method', 'GentleBoost', 'NumLearningCycles', 50, ...
    'Learners', boostTemplate, 'Weights', weights, 'PredictorNames', featureCols);
cvBoost = crossval(boostModel, 'CVPartition', cvp);
[~, cvBoostScores] = kfoldPredict(cvBoost);
cvBoostProbRef = cvBoostScores(:, 2);

candCuts = unique(cvBoostProbRef); candCuts = [-Inf; candCuts(:); Inf];
bestSpecBoost = -Inf; bestCutBoost = 0.5;
for c = candCuts'
    ev = evalReferable(cvBoostProbRef, y_tune, c);
    if ev.sensitivity >= 0.92 && ev.specificity > bestSpecBoost
        bestSpecBoost = ev.specificity;
        bestCutBoost = c;
    end
end
boostEvalTune = evalReferable(cvBoostProbRef, y_tune, bestCutBoost);
[~, selBoostScores] = predict(boostModel, X_sel);
boostEvalSel = evalReferable(selBoostScores(:, 2), y_sel, bestCutBoost);
[~,~,~,boostTuneAUC] = perfcurve(y_tune, cvBoostProbRef, true);
[~,~,~,boostSelAUC]  = perfcurve(y_sel, selBoostScores(:, 2), true);
boostImportance = predictorImportance(boostModel);

fprintf('  GentleBoost: TUNE CV AUC=%.3f, Sens=%.1f%%, Spec=%.1f%% (Cut=%.4f)\n', ...
    boostTuneAUC, boostEvalTune.sensitivity*100, boostEvalTune.specificity*100, bestCutBoost);
fprintf('        SELECTION: AUC=%.3f, Sens=%.1f%% [%.1f%%, %.1f%%], Spec=%.1f%% [%.1f%%, %.1f%%]\n', ...
    boostSelAUC, boostEvalSel.sensitivity*100, boostEvalSel.sensitivityCI(1)*100, boostEvalSel.sensitivityCI(2)*100, ...
    boostEvalSel.specificity*100, boostEvalSel.specificityCI(1)*100, boostEvalSel.specificityCI(2)*100);

% Feature Importance Table
impTbl = table(featureCols', treeImportance(:), bagImportance(:), boostImportance(:), ...
    'VariableNames', {'Feature', 'TreeImportance', 'BaggedTreesImportance', 'GentleBoostImportance'});
impTbl = sortrows(impTbl, 'BaggedTreesImportance', 'descend');
fprintf('\nTop 8 Features by Bagged Trees Importance:\n');
disp(impTbl(1:min(8, height(impTbl)), :));

%% ====================================================================
%  STEP 4: HYBRID ENSEMBLE AND COMBINED COMPARISON TABLE
%  ====================================================================
fprintf('\n>>> STEP 4: COMBINE AND COMPARE ON SELECTION <<<\n');

% Define sensible Hybrid Rules:
% Method H1: Refer if Classifier says refer OR strong clinical rule fires
% Strong clinical rule: severe quads >= 1 OR brightCount >= 10 OR darkCount >= 15
tuneStrongRule = (tuneTbl.quadsSevere >= 1) | (tuneTbl.brightCount >= 8) | (tuneTbl.darkCount >= 15);
selStrongRule  = (selTbl.quadsSevere >= 1)  | (selTbl.brightCount >= 8)  | (selTbl.darkCount >= 15);

% Tune hybrid probability cutoff
tuneHybridScore = max(cvBagProbRef, double(tuneStrongRule));
selHybridScore  = max(selBagScores(:, 2), double(selStrongRule));

candCuts = unique(tuneHybridScore); candCuts = [-Inf; candCuts(:); Inf];
bestSpecHyb = -Inf; bestCutHyb = 0.5;
for c = candCuts'
    ev = evalReferable(tuneHybridScore, y_tune, c);
    if ev.sensitivity >= 0.92 && ev.specificity > bestSpecHyb
        bestSpecHyb = ev.specificity;
        bestCutHyb = c;
    end
end
hybEvalSel = evalReferable(selHybridScore, y_sel, bestCutHyb);
[~,~,~,hybSelAUC] = perfcurve(y_sel, selHybridScore, true);

% Load Step 0 for comparison
s0 = load(fullfile('results', 'step0_results.mat'));
baseEval = s0.step0_results.baseEval;
bEval    = s0.step0_results.bEval;
cEval    = s0.step0_results.cEval;

% Best Step 2 candidate (e.g. Weighted Lesion Burden or Network P)
bestStep2 = step2_results{1}; % Network P

% Assemble master comparison table
methods = {
    '1. Baseline (config_baseline)';
    '2. Calibrated Rules (Gate OFF)';
    '3. Calibrated Rules (Gate ON, Ceil=12)';
    '4. ROC Operating Point (Network P)';
    '5. Trained Classifier (Decision Tree)';
    '6. Trained Classifier (Bagged Trees)';
    '7. Trained Classifier (GentleBoost)';
    '8. Hybrid (Bagged Trees OR Strong Rule)'
};

evalList = {baseEval, bEval, cEval, ...
    evalReferable(candSelScores{1}, y_sel, step2_results{1}.Cutoff), ...
    treeEvalSel, bagEvalSel, boostEvalSel, hybEvalSel};

% Get per-sample predictions on SELECTION for each method
p1 = readtable(fullfile('results', 'baseline_report.csv')).PredictedGrade >= 2;
p2 = selTbl.gradeNoGate >= 2;
p3 = selTbl.gradeGate >= 2;
p4 = candSelScores{1} >= step2_results{1}.Cutoff;
p5 = selTreeScores(:, 2) >= bestCutTree;
p6 = selBagScores(:, 2) >= bestCutBag;
p7 = selBoostScores(:, 2) >= bestCutBoost;
p8 = selHybridScore >= bestCutHyb;
allPreds = [p1, p2, p3, p4, p5, p6, p7, p8];

aucList = [NaN, NaN, NaN, step2_results{1}.SelAUC, treeSelAUC, bagSelAUC, boostSelAUC, hybSelAUC];

compTbl = table();
compTbl.Method = methods;
compTbl.N = repmat(102, numel(methods), 1);
compTbl.AUC = aucList';
compTbl.Sensitivity = cellfun(@(e) e.sensitivity, evalList)';
compTbl.SensCI_Low  = cellfun(@(e) e.sensitivityCI(1), evalList)';
compTbl.SensCI_High = cellfun(@(e) e.sensitivityCI(2), evalList)';
compTbl.Specificity = cellfun(@(e) e.specificity, evalList)';
compTbl.SpecCI_Low  = cellfun(@(e) e.specificityCI(1), evalList)';
compTbl.SpecCI_High = cellfun(@(e) e.specificityCI(2), evalList)';
compTbl.TP = cellfun(@(e) e.TP, evalList)';
compTbl.FN = cellfun(@(e) e.FN, evalList)';
compTbl.TN = cellfun(@(e) e.TN, evalList)';
compTbl.FP = cellfun(@(e) e.FP, evalList)';

fprintf('\nMASTER COMPARISON TABLE ON SELECTION (n=102):\n');
disp(compTbl);
writetable(compTbl, fullfile('results', 'master_comparison_selection.csv'));

% Discordance / Error Overlap Matrix
% "how many images each method gets wrong that the others get right"
errors = allPreds ~= repmat(y_sel, 1, numel(methods));
totalErrors = sum(errors, 1);
fprintf('Total classification errors per method on SELECTION:\n');
for m = 1:numel(methods)
    fprintf('  Method %d (%s): %d errors (FN=%d, FP=%d)\n', ...
        m, methods{m}, totalErrors(m), compTbl.FN(m), compTbl.FP(m));
end

%% ====================================================================
%  STEP 5: DETAILED ERROR DIAGNOSIS & GRADE 1 BOUNDARY AUDIT
%  ====================================================================
fprintf('\n>>> STEP 5: ERROR DIAGNOSIS & GRADE 1 BOUNDARY AUDIT <<<\n');

% Evaluate Grade 1 eyes specifically
g1Idx = (selTbl.Grade == 1);
nG1 = sum(g1Idx);
fprintf('Grade 1 eyes in SELECTION: n=%d\n', nG1);
fprintf('Grade 1 is Non-Referable (True Label = 0). A prediction of Referable is a False Positive.\n');
for m = 1:numel(methods)
    g1_referred = sum(allPreds(g1Idx, m));
    fprintf('  Method %d: %d/%d (%.1f%%) Grade 1 eyes referred (called Grade >= 2)\n', ...
        m, g1_referred, nG1, (g1_referred/nG1)*100);
end

% Grade 0 eyes specifically
g0Idx = (selTbl.Grade == 0);
nG0 = sum(g0Idx);
fprintf('\nGrade 0 eyes in SELECTION: n=%d\n', nG0);
for m = 1:numel(methods)
    g0_referred = sum(allPreds(g0Idx, m));
    fprintf('  Method %d: %d/%d (%.1f%%) Grade 0 eyes falsely referred\n', ...
        m, g0_referred, nG0, (g0_referred/nG0)*100);
end

% Save full workspace
save(fullfile('results', 'steps_2_to_5_workspace.mat'), ...
    'step2_results', 'compTbl', 'allPreds', 'impTbl', ...
    'treeModel', 'bagModel', 'boostModel', ...
    'bestCutTree', 'bestCutBag', 'bestCutBoost', 'bestCutHyb');

fprintf('\nAll steps 2-5 completed successfully. Results saved in results/\n');
