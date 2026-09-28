function loss = drPipelineObjective(params, imageSet, groundTruthGrades)
% DRPIPELINEOBJECTIVE  Scalar loss function for bayesopt threshold calibration.
%
%   LOSS = DRPIPELINEOBJECTIVE(PARAMS, IMAGESET, GROUNDTRUTHGRADES)
%
%   Formulation per Part 5 specification:
%       loss = w1 * (1 - specificity_referable)
%            + w2 * (1 - sensitivity_referable)
%            + w3 * normalizedMeanGrade0FalseLesions
%
%   Weights: w1 = 0.50, w2 = 0.30, w3 = 0.20
%   Hard constraint: Any parameter set with sensitivity < 0.90 is heavily penalised (+10.0)
%
%   Inputs:
%       params            - optimizableVariable table row
%       imageSet          - Struct array with fields .imgPath, .drGrade
%       groundTruthGrades - Integer vector of ICDR grades (0-4)

    % 1. Build modified config from candidate parameters
    cfg = config();

    cfg.segment.lesion.darkSensitivity        = double(params.darkSensitivity);
    cfg.segment.lesion.brightSensitivity      = double(params.brightSensitivity);
    cfg.segment.lesion.marginFactor           = double(params.marginFactor);
    cfg.segment.lesion.darkMaxSize            = round(double(params.darkMaxSize));
    cfg.segment.lesion.brightMaxSize          = round(double(params.brightMaxSize));
    cfg.segment.lesion.vesselBufferRadius     = round(double(params.vesselBufferRadius));
    cfg.segment.lesion.solidityCutoff         = double(params.solidityCutoff);
    cfg.segment.lesion.darkLocalMinContrast   = double(params.localContrastMargin);
    cfg.segment.lesion.brightLocalMinContrast = double(params.localContrastMargin);
    cfg.debug = false;

    % 2. Run pipeline on evaluation set
    nImgs         = numel(imageSet);
    predGrades    = zeros(nImgs, 1);
    falseLesionsG0 = [];

    for k = 1:nImgs
        try
            raw = imread(imageSet(k).imgPath);
            maxDim = max(size(raw, 1), size(raw, 2));
            if maxDim > 768
                raw = imresize(raw, 768 / maxDim);
            end

            [~, ~, qMetrics] = quality.assessQuality(raw, cfg);
            if ~isfield(qMetrics, 'mask') || isempty(qMetrics.mask)
                grayTmp = rgb2gray(raw);
                qMetrics.mask = grayTmp > 10;
            end

            [enhanced, ~] = preprocess.enhanceImage(raw, cfg);
            [segResults, ~] = segment.segmentAll(enhanced, qMetrics.mask, cfg);
            [grade, ~, ~, ~, ~, ~, ~, ~] = classify.gradeDR(enhanced, segResults, cfg);
            predGrades(k) = grade;

            if groundTruthGrades(k) == 0
                falseLesionsG0(end+1) = segResults.lesions.darkCount + segResults.lesions.brightCount; %#ok<AGROW>
            end

        catch ME
            predGrades(k) = 4;
            if groundTruthGrades(k) == 0
                falseLesionsG0(end+1) = 200; %#ok<AGROW>
            end
        end
    end

    % 3. Compute referable metrics (Grade >= 2 vs Grade 0-1)
    refActual = (groundTruthGrades >= 2);
    refPred   = (predGrades        >= 2);
    tp = sum( refActual &  refPred);
    fn = sum( refActual & ~refPred);
    tn = sum(~refActual & ~refPred);
    fp = sum(~refActual &  refPred);

    sensitivity = tp / max(1, tp + fn);
    specificity = tn / max(1, tn + fp);

    % Grade 0 false lesion normalisation (50 lesions -> 1.0)
    if isempty(falseLesionsG0)
        avgFP = 0;
        normG0Lesions = 0.0;
    else
        avgFP = mean(falseLesionsG0);
        normG0Lesions = min(1.0, avgFP / 50.0);
    end

    w1 = 0.50;
    w2 = 0.30;
    w3 = 0.20;

    baseLoss = w1 * (1.0 - specificity) + ...
               w2 * (1.0 - sensitivity) + ...
               w3 * normG0Lesions;

    % Hard penalty if sensitivity drops below 0.90
    if sensitivity < 0.90
        loss = baseLoss + 10.0 * (0.90 - sensitivity);
    else
        loss = baseLoss;
    end

    fprintf('  [bayesopt] dSens=%.2f bSens=%.2f marg=%.2f dMax=%d bMax=%d vBuf=%d sol=%.2f cMarg=%.3f | spec=%.3f sens=%.3f avgG0FP=%.1f LOSS=%.4f\n', ...
        cfg.segment.lesion.darkSensitivity, ...
        cfg.segment.lesion.brightSensitivity, ...
        cfg.segment.lesion.marginFactor, ...
        cfg.segment.lesion.darkMaxSize, ...
        cfg.segment.lesion.brightMaxSize, ...
        cfg.segment.lesion.vesselBufferRadius, ...
        cfg.segment.lesion.solidityCutoff, ...
        cfg.segment.lesion.darkLocalMinContrast, ...
        specificity, sensitivity, avgFP, loss);
end
