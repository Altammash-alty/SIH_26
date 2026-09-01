function [isTypical, distributionScore, flagReason, details] = checkDistribution(img, refStats, cfg)
% CHECKDISTRIBUTION Master Out-of-Distribution (OOD) Quality & Safety Gate.
%
%   [ISTYPICAL, DISTRIBUTIONSCORE, FLAGREASON] = OOD.CHECKDISTRIBUTION(IMG)
%   extracts statistical features from the input fundus image, compares them
%   against the precomputed baseline training-set distribution statistics,
%   and flags images that deviate significantly from typical training data.
%
%   [ISTYPICAL, DISTRIBUTIONSCORE, FLAGREASON, DETAILS] = OOD.CHECKDISTRIBUTION(IMG, REFSTATS, CFG)
%   allows supplying custom reference statistics (or a .mat filepath) and
%   custom configuration thresholds.
%
%   Clinical & Safety Rationale:
%       Deep learning classification models are susceptible to "silent failure"
%       modes where they output high-confidence, erroneous predictions when
%       presented with unfamiliar camera optics, rare artifacts, or atypical
%       staining/illumination profiles outside their training manifold.
%       This module flags such images BEFORE downstream AI grading is trusted,
%       routing them directly to a specialist for human review.
%
%   Explicit Scope & Governance Framing:
%       - This is strictly an Out-of-Distribution filter.
%       - It does NOT claim to be "self-improving AI".
%       - It does NOT retrain, update, or modify any downstream model weights.
%       - It acts purely as a fixed statistical safety barrier.
%
%   Inputs:
%       img               - Input fundus image (preprocessed or raw, uint8/double).
%       refStats          - (Optional) Precomputed reference statistics struct or
%                           path to a .mat file. If omitted/empty, loads from
%                           cfg.ood.statsFilePath ('reference_stats.mat').
%       cfg               - (Optional) Configuration struct from config().
%
%   Outputs:
%       isTypical         - Logical. True if image is within normal training distribution;
%                           False if anomalous / out-of-distribution.
%       distributionScore - Numeric Mahalanobis distance metric from training manifold.
%       flagReason        - String describing why the image was flagged as atypical
%                           (empty string "" if isTypical is true).
%       details           - Struct with extracted features, z-scores, and top deviations.
%
%   Example:
%       [isTypical, distScore, reason] = ood.checkDistribution(enhancedImg);
%       if ~isTypical
%           fprintf('OOD Safety Warning: %s (Dist: %.2f)\n', reason, distScore);
%       end
%
%   Author: DR Screening Pipeline MVP
%   Date: 2026-09-02

    % 1. Parse configuration
    if nargin < 3 || isempty(cfg)
        cfg = config();
    end

    % 2. Validate input image
    if isempty(img)
        isTypical = false;
        distributionScore = Inf;
        flagReason = "Empty image provided to OOD module";
        details = struct('isTypical', false, 'distScore', Inf);
        return;
    end

    % 3. Load or resolve Reference Statistics
    if nargin < 2 || isempty(refStats)
        statsPath = 'reference_stats.mat';
        if isfield(cfg, 'ood') && isfield(cfg.ood, 'statsFilePath')
            statsPath = cfg.ood.statsFilePath;
        end

        if exist(statsPath, 'file')
            loaded = load(statsPath);
            if isfield(loaded, 'refStats')
                refStats = loaded.refStats;
            else
                refStats = loaded;
            end
        else
            % Fallback: Build synthetic reference stats if file is missing
            refStats = ood.buildReferenceStats([], statsPath, cfg);
        end
    elseif ischar(refStats) || isstring(refStats)
        % Path provided as string
        if exist(refStats, 'file')
            loaded = load(refStats);
            if isfield(loaded, 'refStats')
                refStats = loaded.refStats;
            else
                refStats = loaded;
            end
        else
            error('checkDistribution:FileNotFound', 'Specified stats file "%s" does not exist.', refStats);
        end
    end

    % 4. Extract Statistical Features from the image
    [featureVec, featureNames] = ood.extractImageFeatures(img, cfg);

    % Ensure reference statistics contains feature names
    if ~isfield(refStats, 'featureNames') || isempty(refStats.featureNames)
        refStats.featureNames = featureNames;
    end

    % 5. Compare Features to Baseline Distribution
    [distributionScore, isTypical, flagReason, details] = ...
        ood.compareToReference(featureVec, refStats, cfg);

    % Attach extracted feature vector to details
    details.extractedFeatures = featureVec;
    details.featureNames = featureNames;

end
