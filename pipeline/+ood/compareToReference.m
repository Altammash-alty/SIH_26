function [distScore, isTypical, flagReason, details] = compareToReference(featureVec, refStats, cfg)
% COMPARETOREFERENCE Evaluates distance of an image's feature vector to training baseline.
%
%   [DISTSCORE, ISTYPICAL, FLAGREASON, DETAILS] = OOD.COMPARETOREFERENCE(FEATUREVEC, REFSTATS)
%   computes the Mahalanobis distance and per-feature z-scores between the
%   extracted image feature vector and the reference statistics of typical
%   training-distribution fundus images.
%
%   [DISTSCORE, ISTYPICAL, FLAGREASON, DETAILS] = OOD.COMPARETOREFERENCE(FEATUREVEC, REFSTATS, CFG)
%   uses configurable thresholds from CFG (see config.m).
%
%   Methodology:
%       1. Calculates regularized Mahalanobis Distance:
%            D_M = sqrt((x - mu) * inv(Sigma + lambda*I) * (x - mu)')
%       2. Computes per-feature z-scores:
%            z_i = (x_i - mu_i) / sigma_i
%       3. Flags the image as Out-of-Distribution (isTypical = false) if
%          D_M exceeds cfg.ood.distanceThreshold.
%       4. Identifies top diverging feature dimensions (e.g., color imbalance,
%          texture anomalies, excessive gradient sharpness) to generate a
%          diagnostic clinical explanation.
%
%   Inputs:
%       featureVec  - 1xD numeric row vector of extracted image features.
%       refStats    - Struct containing baseline training distribution statistics:
%                       .mean         - 1xD mean feature vector
%                       .cov          - DxD covariance matrix
%                       .invCov       - DxD regularized inverse covariance matrix
%                       .std          - 1xD standard deviation vector
%                       .featureNames - 1xD cell array of feature names
%       cfg         - (Optional) Configuration struct with 'ood' parameters.
%
%   Outputs:
%       distScore   - Double, regularized Mahalanobis distance to reference distribution.
%       isTypical   - Logical, true if image statistics fall within normal baseline limits.
%       flagReason  - String describing reason for OOD flag (empty string "" if typical).
%       details     - Struct containing zScores, topDeviations, threshold, and raw metrics.
%
%   Explicit Scope & Governance Framing:
%       This function strictly performs anomaly detection by comparing fixed
%       statistical profiles. It does NOT claim self-improving AI, does NOT
%       retrain any downstream neural network, and does NOT perform online adaptation.
%
%   Author: DR Screening Pipeline MVP
%   Date: 2026-09-02

    % 1. Parse inputs and configuration
    if nargin < 3 || isempty(cfg)
        cfg = config();
    end

    distThreshold = 3.8;
    if isfield(cfg, 'ood') && isfield(cfg.ood, 'distanceThreshold')
        distThreshold = cfg.ood.distanceThreshold;
    end

    zCutoff = 3.0;
    if isfield(cfg, 'ood') && isfield(cfg.ood, 'zScoreFeatureCutoff')
        zCutoff = cfg.ood.zScoreFeatureCutoff;
    end

    lambda = 1e-4;
    if isfield(cfg, 'ood') && isfield(cfg.ood, 'regCovariance')
        lambda = cfg.ood.regCovariance;
    end

    % 2. Validate feature vector & reference stats
    featureVec = featureVec(:)'; % Ensure 1xD row vector
    D = length(featureVec);

    if isempty(refStats) || ~isfield(refStats, 'mean')
        error('compareToReference:InvalidStats', 'Reference statistics struct is missing or malformed.');
    end

    mu = refStats.mean(:)';
    if length(mu) ~= D
        error('compareToReference:DimensionMismatch', ...
            'Feature vector length (%d) does not match reference statistics dimension (%d).', D, length(mu));
    end

    % 3. Retrieve or compute regularized inverse covariance
    if isfield(refStats, 'invCov') && ~isempty(refStats.invCov) && all(size(refStats.invCov) == [D, D])
        invSigma = refStats.invCov;
    else
        Sigma = refStats.cov;
        SigmaReg = Sigma + lambda * eye(D);
        invSigma = inv(SigmaReg);
    end

    % 4. Compute Mahalanobis Distance
    diffVec = featureVec - mu;
    distSq = diffVec * invSigma * diffVec';
    distScore = sqrt(max(0, distSq));

    % 5. Compute per-feature Z-scores
    if isfield(refStats, 'std') && ~isempty(refStats.std)
        stds = max(1e-6, refStats.std(:)');
    else
        stds = max(1e-6, sqrt(diag(refStats.cov))');
    end
    zScores = diffVec ./ stds;

    % 6. Determine if image is typical
    isTypical = (distScore <= distThreshold);

    % 7. Identify top diverging features and formulate diagnostic reason
    featureNames = refStats.featureNames;
    [absZSorted, sortIdx] = sort(abs(zScores), 'descend');

    topDeviations = struct('name', {}, 'zScore', {}, 'value', {}, 'refMean', {});
    flagDescriptions = {};

    for k = 1:min(5, D)
        idx = sortIdx(k);
        topDeviations(k).name = featureNames{idx};
        topDeviations(k).zScore = zScores(idx);
        topDeviations(k).value = featureVec(idx);
        topDeviations(k).refMean = mu(idx);

        if absZSorted(k) >= zCutoff
            if zScores(idx) > 0
                direction = 'abnormally elevated';
            else
                direction = 'abnormally reduced';
            end
            flagDescriptions{end+1} = sprintf('%s is %s (z = %+.1f)', ...
                featureNames{idx}, direction, zScores(idx));
        end
    end

    if isTypical
        flagReason = "";
    else
        if ~isempty(flagDescriptions)
            flagReason = sprintf('Statistically atypical vs training distribution (Mahalanobis dist = %.2f > %.2f): %s', ...
                distScore, distThreshold, strjoin(flagDescriptions, '; '));
        else
            flagReason = sprintf('Statistically atypical vs training distribution (Mahalanobis dist = %.2f > %.2f; multivariate drift)', ...
                distScore, distThreshold);
        end
    end

    % 8. Assemble detailed diagnostics struct
    details = struct();
    details.distScore = distScore;
    details.threshold = distThreshold;
    details.isTypical = isTypical;
    details.zScores = zScores;
    details.topDeviations = topDeviations;
    details.featureNames = featureNames;

end
