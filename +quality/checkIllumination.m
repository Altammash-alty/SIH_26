function [passed, illumScore, details] = checkIllumination(img, mask, cfg)
% CHECKILLUMINATION Evaluates retinal illumination, exposure, and contrast.
%
%   [PASSED, ILLUMSCORE, DETAILS] = QUALITY.CHECKILLUMINATION(IMG) checks if
%   the input fundus image has acceptable lighting, contrast, and exposure
%   using default parameters and an auto-detected retinal mask.
%
%   [PASSED, ILLUMSCORE, DETAILS] = QUALITY.CHECKILLUMINATION(IMG, MASK, CFG)
%   uses the provided binary MASK and configuration parameters in CFG.
%
%   Checks Performed:
%       1. Mean Luminance: Ensures the retina is neither severely underexposed
%          (dark) nor washed out (overexposed).
%       2. Standard Deviation: Ensures adequate dynamic range and contrast for
%          clinical diagnosis.
%       3. Underexposure/Overexposure Clipping: Rejects images with excessive
%          sensor saturation (white flash glare) or clipped black regions.
%
%   Inputs:
%       img     - Input fundus image (RGB or grayscale, uint8 or double).
%       mask    - (Optional) Logical mask of the retinal FOV.
%       cfg     - (Optional) Struct with field 'quality.illumination'.
%
%   Outputs:
%       passed     - Logical (true if all illumination checks pass, false otherwise).
%       illumScore - Composite illumination quality score [0, 100].
%       details    - Struct containing meanLuminance, stdLuminance, underRatio,
%                    overRatio, and individual check flags.
%
%   Example:
%       [passed, score, details] = quality.checkIllumination(fundusImg);

    % Parse inputs and defaults
    if nargin < 3 || isempty(cfg)
        defaultCfg = config();
        cfgIllum = defaultCfg.quality.illumination;
    elseif isfield(cfg, 'quality') && isfield(cfg.quality, 'illumination')
        cfgIllum = cfg.quality.illumination;
    else
        cfgIllum = cfg;
    end

    % Normalize image to double [0, 1]
    if isinteger(img)
        imgD = im2double(img);
    else
        imgD = double(img);
        if max(imgD(:)) > 1.0
            imgD = imgD / 255.0;
        end
    end

    % Extract green channel (or converted grayscale luminance)
    if ndims(imgD) == 3
        % Weighted luminance: 0.2989*R + 0.5870*G + 0.1140*B
        lum = rgb2gray(imgD);
    else
        lum = imgD;
    end

    % Obtain retinal mask if not supplied
    if nargin < 2 || isempty(mask)
        mask = quality.getFundusMask(imgD);
    else
        mask = logical(mask);
    end

    % Check if mask is empty
    if ~any(mask(:))
        passed = false;
        illumScore = 0.0;
        details = struct('passed', false, 'reason', 'No valid retinal area detected', ...
            'meanLuminance', 0, 'stdLuminance', 0);
        return;
    end

    % Extract luminance pixel values within the retinal mask
    retinalPixels = lum(mask);
    nPixels = numel(retinalPixels);

    meanLum = mean(retinalPixels);
    stdLum  = std(retinalPixels);

    % Compute clipping ratios
    underThresh = 0.05;
    if isfield(cfgIllum, 'underThreshold')
        underThresh = cfgIllum.underThreshold;
    end
    overThresh = 0.95;
    if isfield(cfgIllum, 'overThreshold')
        overThresh = cfgIllum.overThreshold;
    end

    underRatio = sum(retinalPixels < underThresh) / nPixels;
    overRatio  = sum(retinalPixels > overThresh) / nPixels;

    % Evaluate thresholds
    isNotTooDark  = (meanLum >= cfgIllum.minMean) && (underRatio <= cfgIllum.maxUnderRatio);
    isNotTooBright = (meanLum <= cfgIllum.maxMean) && (overRatio <= cfgIllum.maxOverRatio);
    isGoodContrast = (stdLum >= cfgIllum.minStd) && (stdLum <= cfgIllum.maxStd);

    passed = isNotTooDark && isNotTooBright && isGoodContrast;

    % Compute normalized composite score [0 - 100]
    % Ideal mean is around 0.45 - 0.55, ideal std is around 0.12 - 0.25
    meanPenalty = abs(meanLum - 0.50) / 0.50; % 0 = ideal, 1 = extreme
    stdPenalty  = max(0, 1.0 - (stdLum / 0.15)); % penalizes low contrast
    clipPenalty = 2.0 * (underRatio + overRatio);
    penalty = min(1.0, 0.4 * meanPenalty + 0.3 * stdPenalty + 0.3 * clipPenalty);
    illumScore = max(0.0, (1.0 - penalty) * 100.0);

    % Build diagnostic details
    details = struct();
    details.meanLuminance = meanLum;
    details.stdLuminance  = stdLum;
    details.underRatio    = underRatio;
    details.overRatio     = overRatio;
    details.isNotTooDark  = isNotTooDark;
    details.isNotTooBright = isNotTooBright;
    details.isGoodContrast = isGoodContrast;
    details.passed        = passed;
    details.illumScore    = illumScore;

    % Build failure reason strings if rejected
    reasons = {};
    if ~isNotTooDark
        reasons{end+1} = sprintf('Image too dark (mean luminance: %.2f < %.2f)', meanLum, cfgIllum.minMean);
    end
    if ~isNotTooBright
        reasons{end+1} = sprintf('Image overexposed / flash glare (mean luminance: %.2f > %.2f)', meanLum, cfgIllum.maxMean);
    end
    if ~isGoodContrast
        if stdLum < cfgIllum.minStd
            reasons{end+1} = sprintf('Poor dynamic range / flat contrast (std: %.3f < %.3f)', stdLum, cfgIllum.minStd);
        else
            reasons{end+1} = sprintf('Severe illumination non-uniformity (std: %.3f > %.3f)', stdLum, cfgIllum.maxStd);
        end
    end

    if isempty(reasons)
        details.reason = '';
        details.message = sprintf('Illumination acceptable (Mean: %.2f, Std: %.2f, Score: %.1f/100).', meanLum, stdLum, illumScore);
    else
        details.reason = strjoin(reasons, '; ');
        details.message = details.reason;
    end
end
