function [isGood, reason, metrics] = assessQuality(img, cfg)
% ASSESSQUALITY Stage 1 Master Quality Gate for Fundus Images.
%
%   [ISGOOD, REASON, METRICS] = QUALITY.ASSESSQUALITY(IMG) performs a
%   comprehensive three-tier quality evaluation of an input retinal fundus
%   image:
%       1. Field of View (FOV) & Centering Check
%       2. Illumination, Exposure & Contrast Check
%       3. Sharpness / Blur Check (Laplacian variance on green channel)
%
%   [ISGOOD, REASON, METRICS] = QUALITY.ASSESSQUALITY(IMG, CFG) uses custom
%   thresholds defined in CFG (see config.m).
%
%   Inputs:
%       img     - Input fundus photograph (RGB or grayscale, uint8, uint16,
%                 or double).
%       cfg     - (Optional) Struct containing quality thresholds.
%                 Defaults to config().
%
%   Outputs:
%       isGood  - Logical scalar. True if all quality gates pass; False if
%                 any critical quality check fails.
%       reason  - String describing reason for failure (empty string "" if
%                 image passed).
%       metrics - Struct containing all intermediate scores and test flags:
%                   .fovPassed, .fovScore, .fovDetails
%                   .illumPassed, .illumScore, .illumDetails
%                   .blurPassed, .blurScore, .blurDetails
%                   .overallScore (0 - 100)
%                   .mask (detected retinal foreground mask)
%
%   Example:
%       [isGood, reason, metrics] = quality.assessQuality(fundusImg);
%       if ~isGood
%           fprintf('Image Rejected: %s\n', reason);
%       else
%           fprintf('Image Passed Quality Gate (Score: %.1f/100)\n', metrics.overallScore);
%       end

    % 1. Load configuration
    if nargin < 2 || isempty(cfg)
        cfg = config();
    end

    % 2. Validate input image
    if isempty(img)
        isGood = false;
        reason = "Empty image provided";
        metrics = struct('isGood', false, 'overallScore', 0);
        return;
    end

    % Convert image to standard double [0, 1]
    if isinteger(img)
        imgD = im2double(img);
    else
        imgD = double(img);
        if max(imgD(:)) > 1.0
            imgD = imgD / 255.0;
        end
    end

    % 3. Check 1: Field of View (FOV) & Aperture Geometry
    [fovPassed, fovScore, fovDetails] = quality.checkFieldOfView(imgD, cfg);
    mask = fovDetails.mask;

    % 4. Check 2: Illumination, Exposure & Dynamic Range
    [illumPassed, illumScore, illumDetails] = quality.checkIllumination(imgD, mask, cfg);

    % 5. Check 3: Sharpness & Blur
    [blurPassed, blurScore, blurDetails] = quality.checkBlur(imgD, mask, cfg);

    % 6. Decision Logic (All sub-checks must pass)
    isGood = fovPassed && illumPassed && blurPassed;

    % 7. Build Descriptive Failure Reasons
    reasons = {};
    if ~fovPassed
        if isfield(fovDetails, 'reason') && ~isempty(fovDetails.reason)
            reasons{end+1} = fovDetails.reason;
        else
            reasons{end+1} = "Field of view incomplete or severely cropped";
        end
    end

    if ~illumPassed
        if isfield(illumDetails, 'reason') && ~isempty(illumDetails.reason)
            reasons{end+1} = illumDetails.reason;
        else
            reasons{end+1} = "Illumination/exposure out of acceptable range";
        end
    end

    if ~blurPassed
        reasons{end+1} = sprintf('Image too blurry / out of focus (sharpness score: %.2f < %.2f)', ...
            blurScore, cfg.quality.blur.threshold);
    end

    if isGood
        reason = "";
    else
        reason = string(strjoin(reasons, " | "));
    end

    % 8. Compute weighted overall quality score (0 to 100)
    % Weighted blend: 35% Sharpness (normalized against 2x threshold), 35% Illumination, 30% FOV
    normalizedBlurScore = min(100.0, (blurScore / (2.0 * cfg.quality.blur.threshold)) * 100.0);
    overallScore = (0.35 * normalizedBlurScore) + (0.35 * illumScore) + (0.30 * fovScore);

    % If any hard check failed, penalize the overall score to reflect unsuitability
    if ~isGood
        overallScore = min(overallScore, 49.0);
    else
        overallScore = max(overallScore, 50.0);
    end

    % 9. Package metrics struct
    metrics = struct();
    metrics.isGood = isGood;
    metrics.overallScore = overallScore;
    metrics.fovPassed = fovPassed;
    metrics.fovScore = fovScore;
    metrics.fovDetails = fovDetails;
    metrics.illumPassed = illumPassed;
    metrics.illumScore = illumScore;
    metrics.illumDetails = illumDetails;
    metrics.blurPassed = blurPassed;
    metrics.blurScore = blurScore;
    metrics.blurDetails = blurDetails;
    metrics.mask = mask;

end
