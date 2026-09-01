function [passed, blurScore, details] = checkBlur(img, mask, cfg)
% CHECKBLUR Sharpness estimation for fundus images using Laplacian variance.
%
%   [PASSED, BLURSCORE, DETAILS] = QUALITY.CHECKBLUR(IMG) assesses the
%   sharpness of the input fundus image using default configuration and
%   auto-detected retinal mask.
%
%   [PASSED, BLURSCORE, DETAILS] = QUALITY.CHECKBLUR(IMG, MASK, CFG) uses
%   the supplied binary MASK and CFG struct (from config.m).
%
%   Methodology:
%       1. Extracts the green channel (which contains maximum contrast for
%          retinal blood vessels, optic disc margins, and lesions).
%       2. Erodes the retinal FOV mask to exclude artificial high-gradient
%          edges at the circular boundary of the camera aperture.
%       3. Computes the discrete Laplacian operator on the green channel.
%       4. Calculates the variance of the Laplacian response within the
%          eroded retinal mask. Higher variance indicates crisp, sharp features;
%          lower variance indicates optical defocus or motion blur.
%
%   Inputs:
%       img     - Input fundus image (RGB or grayscale, uint8 or double).
%       mask    - (Optional) Logical mask of the retinal FOV. If empty,
%                 quality.getFundusMask(img) is used.
%       cfg     - (Optional) Struct with field 'quality.blur' or 'threshold'.
%
%   Outputs:
%       passed    - Logical (true if blurScore >= threshold, false if too blurry).
%       blurScore - Numeric sharpness metric (variance of Laplacian * 1e4).
%       details   - Struct with intermediate metrics (threshold, erodedMask,
%                   laplacianMap, meanGrad, etc.).
%
%   Example:
%       [passed, score] = quality.checkBlur(fundusImg);
%       fprintf('Sharpness Score: %.2f (Passed: %d)\n', score, passed);

    % Parse inputs and defaults
    if nargin < 3 || isempty(cfg)
        defaultCfg = config();
        cfgBlur = defaultCfg.quality.blur;
    elseif isfield(cfg, 'quality') && isfield(cfg.quality, 'blur')
        cfgBlur = cfg.quality.blur;
    else
        cfgBlur = cfg;
    end

    % Ensure image is double [0, 1]
    if isinteger(img)
        imgD = im2double(img);
    else
        imgD = double(img);
        if max(imgD(:)) > 1.0
            imgD = imgD / 255.0;
        end
    end

    % Extract green channel (or grayscale if 2D)
    if ndims(imgD) == 3
        greenChan = imgD(:, :, 2);
    else
        greenChan = imgD;
    end

    % Obtain retinal mask if not supplied
    if nargin < 2 || isempty(mask)
        mask = quality.getFundusMask(imgD);
    else
        mask = logical(mask);
    end

    % Erode mask to avoid false edge gradients from the outer circular aperture
    erosionRadius = 15;
    if isfield(cfgBlur, 'maskErosionRadius')
        erosionRadius = cfgBlur.maskErosionRadius;
    end
    se = strel('disk', max(1, round(erosionRadius)));
    erodedMask = imerode(mask, se);

    % Fallback if mask is tiny or empty
    if ~any(erodedMask(:))
        erodedMask = mask;
    end
    if ~any(erodedMask(:))
        passed = false;
        blurScore = 0.0;
        details = struct('threshold', cfgBlur.threshold, 'blurScore', 0.0, ...
            'passed', false, 'reason', 'No valid retinal tissue detected');
        return;
    end

    % Define Laplacian kernel
    if isfield(cfgBlur, 'laplacianKernel')
        lapKernel = cfgBlur.laplacianKernel;
    else
        lapKernel = [0 1 0; 1 -4 1; 0 1 0];
    end

    % Apply Laplacian filter to the green channel
    lapMap = imfilter(greenChan, lapKernel, 'replicate', 'same', 'conv');

    % Extract Laplacian responses within the valid eroded mask
    validResponses = lapMap(erodedMask);

    % Compute variance of Laplacian. Scaled by 10,000 to yield intuitive values (e.g. 10 - 100+)
    lapVar = var(validResponses);
    blurScore = lapVar * 10000.0;

    % Evaluate against threshold
    threshold = cfgBlur.threshold;
    passed = (blurScore >= threshold);

    % Package diagnostic details
    details = struct();
    details.blurScore = blurScore;
    details.threshold = threshold;
    details.passed = passed;
    details.laplacianVariance = lapVar;
    details.erodedMask = erodedMask;
    details.validPixelCount = numel(validResponses);
    if ~passed
        details.message = sprintf('Blur score (%.2f) below threshold (%.2f): Image is out of focus or motion blurred.', blurScore, threshold);
    else
        details.message = sprintf('Blur score (%.2f) meets threshold (%.2f): Sharpness acceptable.', blurScore, threshold);
    end
end
