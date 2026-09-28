function [reportTbl, confMat, acc, sens, spec, g0Stats] = validate_against_labels(cfg, target, outputCsv, maxSamples)
% VALIDATE_AGAINST_LABELS Validates RetinaAI pipeline against specified dataset/split.
%
% Usage:
%   [reportTbl, confMat, acc, sens, spec, g0Stats] = validate_against_labels(cfg, target, outputCsv, maxSamples)
%
% Inputs:
%   cfg         - Pipeline configuration struct. Defaults to config().
%   target      - One of:
%                   'selection' (default) -> runs on the 102 SELECTION split images from results/splits.mat
%                   'tune'                -> runs on the 311 TUNE split images
%                   'test'                -> runs on data/idrid/grading/test
%                   struct array / table  -> custom dataset table with ImagePath, DRGrade, ImageName
%                   char folder path      -> folder containing images and labels.csv
%   outputCsv   - (Optional) Filepath to save the CSV report. Defaults to 'results/validation_report.csv'.
%   maxSamples  - (Optional) Limit evaluation to first N samples (or stratified subset). Defaults to Inf (all).

    if nargin < 1 || isempty(cfg)
        cfg = config();
    end
    if nargin < 2 || isempty(target)
        target = 'selection';
    end
    if nargin < 3 || isempty(outputCsv)
        outputCsv = fullfile('results', 'validation_report.csv');
    end
    if nargin < 4 || isempty(maxSamples)
        maxSamples = Inf;
    end

    % 1. Resolve dataset
    if ischar(target) || isstring(target)
        targetStr = lower(char(target));
        if strcmp(targetStr, 'selection')
            splitsFile = fullfile('results', 'splits.mat');
            if ~exist(splitsFile, 'file')
                splitsFile = fullfile(fileparts(mfilename('fullpath')), '..', 'results', 'splits.mat');
            end
            if ~exist(splitsFile, 'file')
                error('validate_against_labels:NoSplits', 'results/splits.mat not found. Please create splits first.');
            end
            s = load(splitsFile);
            evalTbl = s.trainTbl(s.selectIdxs, :);
            splitName = 'IDRiD Train SELECTION Split (102 images)';
        elseif strcmp(targetStr, 'tune')
            splitsFile = fullfile('results', 'splits.mat');
            if ~exist(splitsFile, 'file')
                splitsFile = fullfile(fileparts(mfilename('fullpath')), '..', 'results', 'splits.mat');
            end
            s = load(splitsFile);
            evalTbl = s.trainTbl(s.tuneIdxs, :);
            splitName = 'IDRiD Train TUNE Split (311 images)';
        elseif strcmp(targetStr, 'test')
            [evalTbl, ~] = data.loadIDRiDGrading('test', fullfile('data', 'idrid', 'grading'));
            splitName = 'IDRiD Official TEST Split (103 images)';
        elseif strcmp(targetStr, 'messidor2')
            [evalTbl, ~] = data.loadMessidor2(fullfile('data', 'messidor2'));
            splitName = 'Messidor-2 Cohort';
        elseif exist(targetStr, 'dir')
            % Custom folder containing labels.csv
            csvFile = fullfile(targetStr, 'labels.csv');
            imgDir = fullfile(targetStr, 'images');
            if ~exist(imgDir, 'dir'), imgDir = targetStr; end
            rawTbl = readtable(csvFile, 'VariableNamingRule', 'preserve');
            % Standardize columns
            imageNames = rawTbl{:, 1};
            imagePaths = cell(numel(imageNames), 1);
            for i = 1:numel(imageNames)
                fn = imageNames{i};
                if ~contains(fn, '.'), fn = [fn, '.jpg']; end
                imagePaths{i} = fullfile(imgDir, fn);
            end
            evalTbl = table(imageNames, imagePaths, rawTbl{:, 2}, 'VariableNames', {'ImageName', 'ImagePath', 'DRGrade'});
            splitName = ['Custom Folder: ', targetStr];
        else
            error('validate_against_labels:InvalidTarget', 'Unknown target dataset: %s', targetStr);
        end
    elseif istable(target)
        evalTbl = target;
        splitName = 'Custom Table';
    else
        error('validate_against_labels:InvalidInput', 'Invalid target parameter.');
    end

    nTotal = height(evalTbl);
    if isfinite(maxSamples) && maxSamples < nTotal
        evalTbl = evalTbl(1:maxSamples, :);
    end
    nImgs = height(evalTbl);

    fprintf('\n=================================================================\n');
    fprintf(' VALIDATION HARNESS: %s\n', splitName);
    fprintf(' Total Images to Evaluate: %d\n', nImgs);
    fprintf(' Output CSV Destination:   %s\n', outputCsv);
    fprintf('=================================================================\n');

    actualGrades = zeros(nImgs, 1);
    predGrades   = zeros(nImgs, 1);
    nnGrades     = zeros(nImgs, 1);
    darkCounts   = zeros(nImgs, 1);
    brightCounts = zeros(nImgs, 1);
    qPassList    = false(nImgs, 1);
    imageNames   = cell(nImgs, 1);

    hasGT = ismember('DRGrade', evalTbl.Properties.VariableNames) && ~all(isnan(evalTbl.DRGrade));

    for k = 1:nImgs
        imgName = evalTbl.ImageName{k};
        imgPath = evalTbl.ImagePath{k};
        imageNames{k} = imgName;

        if hasGT
            actualGrades(k) = evalTbl.DRGrade(k);
        else
            actualGrades(k) = NaN;
        end

        try
            raw = imread(imgPath);
            maxDim = max(size(raw, 1), size(raw, 2));
            if maxDim > 768
                raw768 = imresize(raw, 768 / maxDim);
            else
                raw768 = raw;
            end

            % Stage 1: Quality Gate
            [isGood, ~, qMetrics] = quality.assessQuality(raw768, cfg);
            qPassList(k) = isGood;
            if ~isfield(qMetrics, 'mask') || isempty(qMetrics.mask)
                grayTmp = rgb2gray(raw768);
                qMetrics.mask = grayTmp > 10;
            end

            % Stage 2: Enhancement
            [enhanced, ~] = preprocess.enhanceImage(raw768, cfg);

            % Stage 3: Segmentation
            [segResults, ~] = segment.segmentAll(enhanced, qMetrics.mask, cfg);
            darkCounts(k)   = segResults.lesions.darkCount;
            brightCounts(k) = segResults.lesions.brightCount;

            % Stage 4: Classification
            [grade, ~, ~, ~, ~, ~, ~, det] = classify.gradeDR(enhanced, segResults, cfg);
            predGrades(k) = grade;
            if isfield(det, 'nnGrade')
                nnGrades(k) = det.nnGrade;
            else
                nnGrades(k) = grade;
            end

        catch ME
            fprintf('  [ERROR] Image %s (%d/%d) failed: %s\n', imgName, k, nImgs, ME.message);
            predGrades(k) = 4;
            nnGrades(k)   = 4;
            qPassList(k)  = false;
        end

        if mod(k, 10) == 0 || k == nImgs
            fprintf('  Processed %d / %d images...\n', k, nImgs);
        end
    end

    % Build per-image report table
    if hasGT
        matchList = (actualGrades == predGrades);
        ruleOverrideList = (nnGrades ~= predGrades);
        reportTbl = table(imageNames, actualGrades, predGrades, nnGrades, ...
            darkCounts, brightCounts, qPassList, matchList, ruleOverrideList, ...
            'VariableNames', {'ImageName', 'ActualGrade', 'PredictedGrade', 'NetworkGrade', ...
                              'DarkCount', 'BrightCount', 'QPass', 'Match', 'RuleOverrodeNetwork'});
    else
        reportTbl = table(imageNames, predGrades, nnGrades, ...
            darkCounts, brightCounts, qPassList, ...
            'VariableNames', {'ImageName', 'PredictedGrade', 'NetworkGrade', ...
                              'DarkCount', 'BrightCount', 'QPass'});
    end

    [outDir, ~, ~] = fileparts(outputCsv);
    if ~isempty(outDir) && ~exist(outDir, 'dir')
        mkdir(outDir);
    end
    writetable(reportTbl, outputCsv);

    % Compute statistics if ground truth available
    if hasGT
        confMat = confusionmat(actualGrades, predGrades, 'Order', 0:4);
        acc = mean(actualGrades == predGrades);
        withinOneGrade = mean(abs(actualGrades - predGrades) <= 1);

        refActual = (actualGrades >= 2);
        refPred   = (predGrades   >= 2);
        tp = sum(refActual &  refPred);
        fn = sum(refActual & ~refPred);
        tn = sum(~refActual & ~refPred);
        fp = sum(~refActual &  refPred);

        sens = tp / max(1, tp + fn);
        spec = tn / max(1, tn + fp);

        % 95% Wilson Score Confidence Intervals
        [sensCI_low, sensCI_high] = wilsonCI(tp, tp + fn, 0.95);
        [specCI_low, specCI_high] = wilsonCI(tn, tn + fp, 0.95);

        % Grade 0 audit
        g0Idxs = (actualGrades == 0);
        g0Count = sum(g0Idxs);
        g0NonzeroDark   = sum(g0Idxs & darkCounts > 0);
        g0NonzeroBright = sum(g0Idxs & brightCounts > 0);
        avgDarkG0   = mean(darkCounts(g0Idxs));
        avgBrightG0 = mean(brightCounts(g0Idxs));
        medDarkG0   = median(darkCounts(g0Idxs));
        medBrightG0 = median(brightCounts(g0Idxs));

        g0Stats = struct('totalG0', g0Count, ...
                         'nonzeroDark', g0NonzeroDark, 'nonzeroBright', g0NonzeroBright, ...
                         'avgDark', avgDarkG0, 'avgBright', avgBrightG0, ...
                         'medDark', medDarkG0, 'medBright', medBrightG0);

        underGraded = sum(predGrades < actualGrades);
        overGraded  = sum(predGrades > actualGrades);
        pctUnder    = (underGraded / nImgs) * 100.0;
        pctOver     = (overGraded  / nImgs) * 100.0;

        nRuleOverride = sum(ruleOverrideList);
        pctRuleOverride = (nRuleOverride / nImgs) * 100.0;

        qRejections = sum(~qPassList);

        % Display summary
        fprintf('\n================== VALIDATION REPORT SUMMARY ==================\n');
        fprintf(' Dataset / Cohort: %s (n = %d)\n', splitName, nImgs);
        fprintf(' Quality Gate Rejections: %d / %d (%.1f%%)\n', qRejections, nImgs, (qRejections/nImgs)*100);
        fprintf('\n 5x5 Confusion Matrix (Rows: Actual Grade 0-4, Cols: Predicted Grade 0-4):\n');
        disp(confMat);

        fprintf(' Exact-Grade Accuracy:        %.1f%% (%d/%d)\n', acc * 100, sum(matchList), nImgs);
        fprintf(' Within-1-Grade Accuracy:     %.1f%% (%d/%d)\n', withinOneGrade * 100, sum(abs(actualGrades - predGrades) <= 1), nImgs);
        fprintf(' Referable DR Sensitivity:    %.1f%% (%d/%d)  [95%% CI: %.1f%% - %.1f%%] (Target: >90%%)\n', ...
            sens * 100, tp, tp + fn, sensCI_low * 100, sensCI_high * 100);
        fprintf(' Referable DR Specificity:    %.1f%% (%d/%d)  [95%% CI: %.1f%% - %.1f%%] (Target: >85%%)\n', ...
            spec * 100, tn, tn + fp, specCI_low * 100, specCI_high * 100);
        fprintf('\n Error Direction:\n');
        fprintf('   Under-graded cases:        %d / %d (%.1f%%)\n', underGraded, nImgs, pctUnder);
        fprintf('   Over-graded cases:         %d / %d (%.1f%%)\n', overGraded, nImgs, pctOver);
        fprintf('\n Rule vs Neural Network Disagreement:\n');
        fprintf('   Rule overrode NN:          %d / %d (%.1f%%)\n', nRuleOverride, nImgs, pctRuleOverride);
        fprintf('\n Grade 0 False Positive Audit (n = %d Normal Images):\n', g0Count);
        fprintf('   Images with darkCount > 0:   %d / %d (Mean: %.1f, Median: %.1f)\n', ...
            g0NonzeroDark, g0Count, avgDarkG0, medDarkG0);
        fprintf('   Images with brightCount > 0: %d / %d (Mean: %.1f, Median: %.1f)\n', ...
            g0NonzeroBright, g0Count, avgBrightG0, medBrightG0);
        fprintf(' Detailed CSV saved to:        %s\n', outputCsv);
        fprintf('=================================================================\n\n');
    else
        confMat = []; acc = NaN; sens = NaN; spec = NaN; g0Stats = struct();
        fprintf('\n[INFO] Target has no ground-truth grades. Predictions saved to %s\n', outputCsv);
    end

end

function [ciLow, ciHigh] = wilsonCI(k, n, confLevel)
    if n == 0
        ciLow = 0; ciHigh = 0;
        return;
    end
    z = 1.95996; % 95% standard normal quantile
    p = k / n;
    denominator = 1 + (z^2) / n;
    center = (p + (z^2) / (2 * n)) / denominator;
    margin = (z * sqrt((p * (1 - p) / n) + ((z^2) / (4 * (n^2))))) / denominator;
    ciLow = max(0.0, center - margin);
    ciHigh = min(1.0, center + margin);
end
