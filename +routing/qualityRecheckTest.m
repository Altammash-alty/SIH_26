function [qualitySensitive, details] = qualityRecheckTest(img, origGrade, origConfidence, gradeModelHandle, cfg)
% QUALITYRECHECKTEST Controlled perturbation test to disambiguate quality vs clinical uncertainty.
%
%   [QUALITYSENSITIVE, DETAILS] = ROUTING.QUALITYRECHECKTEST(IMG, ORIGGRADE, ORIGCONFIDENCE)
%   applies a controlled synthetic quality degradation (mild blur or brightness attenuation)
%   to the enhanced fundus image and re-evaluates the grading model.
%
%   [QUALITYSENSITIVE, DETAILS] = ROUTING.QUALITYRECHECKTEST(IMG, ORIGGRADE, ORIGCONFIDENCE, GRADEMODELHANDLE, CFG)
%   uses custom model handles and configuration thresholds (see config.m).
%
%   Clinical & Algorithmic Principle:
%       When an AI model outputs low confidence (< threshold), the root cause
%       is typically one of two distinct phenomena:
%         1. Sub-optimal Image Quality: Marginal contrast or borderline focus
%            degraded feature sharpness, making the decision boundary unstable.
%            Under controlled perturbation, the model's output drops sharply or shifts.
%            -> Action: Flag as QUALITY-SENSITIVE -> Route to RETAKE.
%         2. Genuine Clinical Ambiguity: Atypical lesion morphology, borderline
%            microaneurysm count, or rare co-pathology where even high-quality
%            images pose diagnostic challenge. The output remains stable under
%            mild quality perturbation.
%            -> Action: Flag as CLINICAL AMBIGUITY -> Route to DOCTOR_REVIEW.
%
%   Inputs:
%       img              - Preprocessed/enhanced fundus image.
%       origGrade        - (Optional) Baseline discrete grade (0-4). If omitted,
%                          evaluated from gradeModelHandle.
%       origConfidence   - (Optional) Baseline confidence score [0, 1].
%       gradeModelHandle - (Optional) Function handle for grading model. Defaults
%                          to @routing.stubGradeModel.
%       cfg              - (Optional) Struct with field 'routing.qualityRecheck'.
%
%   Outputs:
%       qualitySensitive - Logical. True if perturbation caused significant
%                          confidence collapse or grade shift; False if invariant.
%       details          - Struct with perturbed metrics:
%                            .origGrade, .origConfidence
%                            .pertGrade, .pertConfidence
%                            .deltaConf, .deltaGrade
%                            .qualitySensitive, .perturbationType
%                            .explanation, .perturbedImage
%
%   Author: DR Screening Pipeline MVP
%   Date: 2026-09-02

    % 1. Parse configuration and defaults
    if nargin < 5 || isempty(cfg)
        cfg = config();
    end

    if nargin < 4 || isempty(gradeModelHandle)
        gradeModelHandle = @routing.stubGradeModel;
    end

    pertCfg = cfg.routing.qualityRecheck;
    pertType = pertCfg.perturbationType;
    confThresh = pertCfg.confDeltaThreshold;
    gradeShiftSensitive = pertCfg.gradeShiftSensitive;

    % Normalize image to double [0, 1]
    if isinteger(img)
        imgD = im2double(img);
    else
        imgD = double(img);
        if max(imgD(:)) > 1.0, imgD = imgD / 255.0; end
    end

    % 2. Establish Baseline Grade and Confidence if not passed
    if nargin < 2 || isempty(origGrade) || nargin < 3 || isempty(origConfidence)
        [origGrade, origConfidence] = gradeModelHandle(imgD);
    end

    % 3. Apply Controlled Synthetic Quality Perturbation
    % We use deterministic, non-random perturbations
    mask = quality.getFundusMask(imgD);
    if ~any(mask(:)), mask = true(size(imgD, 1), size(imgD, 2)); end

    switch lower(pertType)
        case 'blur'
            sigma = pertCfg.blurSigma;
            pertImg = imgaussfilt(imgD, sigma);
            % Preserve black outer mask
            for c = 1:size(pertImg, 3)
                ch = pertImg(:, :, c);
                ch(~mask) = 0;
                pertImg(:, :, c) = ch;
            end

        case 'brightness'
            factor = pertCfg.brightnessFactor;
            pertImg = imgD * factor;
            for c = 1:size(pertImg, 3)
                ch = pertImg(:, :, c);
                ch(~mask) = 0;
                pertImg(:, :, c) = ch;
            end

        otherwise
            % Default combined mild blur
            pertImg = imgaussfilt(imgD, 1.8);
            for c = 1:size(pertImg, 3)
                ch = pertImg(:, :, c);
                ch(~mask) = 0;
                pertImg(:, :, c) = ch;
            end
    end

    % 4. Re-evaluate Grading Model on Perturbed Image
    [pertGrade, pertConfidence] = gradeModelHandle(pertImg);

    % 5. Compute Divergence Metrics
    deltaConf = origConfidence - pertConfidence;
    deltaGrade = abs(origGrade - pertGrade);

    gradeChanged = (origGrade ~= pertGrade);
    confDropExcessive = (deltaConf >= confThresh);

    if gradeShiftSensitive
        qualitySensitive = gradeChanged || confDropExcessive;
    else
        qualitySensitive = confDropExcessive;
    end

    % 6. Build Diagnostic Explanation
    if qualitySensitive
        if gradeChanged
            explanation = sprintf('Model output is quality-sensitive: grade shifted from Grade %d to Grade %d under mild %s perturbation (delta-conf: %+.2f). Root cause is marginal image quality -> RETAKE recommended.', ...
                origGrade, pertGrade, pertType, deltaConf);
        else
            explanation = sprintf('Model output is quality-sensitive: confidence collapsed by %.2f (%.2f -> %.2f >= threshold %.2f) under mild %s perturbation. Root cause is marginal image quality -> RETAKE recommended.', ...
                deltaConf, origConfidence, pertConfidence, confThresh, pertType);
        end
    else
        explanation = sprintf('Model output is invariant to quality perturbation (delta-grade: %d, delta-conf: %+.2f < %.2f). Uncertainty represents genuine clinical ambiguity -> DOCTOR_REVIEW recommended.', ...
            deltaGrade, deltaConf, confThresh);
    end

    % 7. Package Details
    details = struct();
    details.origGrade = origGrade;
    details.origConfidence = origConfidence;
    details.pertGrade = pertGrade;
    details.pertConfidence = pertConfidence;
    details.deltaConf = deltaConf;
    details.deltaGrade = deltaGrade;
    details.qualitySensitive = qualitySensitive;
    details.perturbationType = pertType;
    details.explanation = explanation;
    details.perturbedImage = pertImg;

end
