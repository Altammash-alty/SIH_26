function normImg = normalizeIllumination(img, cfg)
% NORMALIZEILLUMINATION Flattens non-uniform lighting across the retinal fundus.
%
%   NORMIMG = PREPROCESS.NORMALIZEILLUMINATION(IMG) corrects vignetting and
%   uneven flash illumination across the retinal photograph using default
%   Gaussian background subtraction.
%
%   NORMIMG = PREPROCESS.NORMALIZEILLUMINATION(IMG, CFG) uses the parameters
%   specified in CFG (see config.m).
%
%   Methodology:
%       1. Obtains the retinal foreground mask.
%       2. Inpaints or extrapolates boundary values so the dark outer camera
%          border does not distort the low-pass background estimate.
%       3. Estimates the low-frequency illumination bias using a wide Gaussian
%          filter (imgaussfilt with sigma ~ 30-50 pixels).
%       4. Subtracts the estimated background and shifts by the global mean
%          retinal luminance:
%             I_norm = I - I_bg + mean(I_bg(mask))
%       5. Constrains the dynamic range to [0, 1] and preserves the clean
%          black outer frame.
%
%   Inputs:
%       img     - Input fundus photograph (RGB or grayscale, uint8 or double).
%       cfg     - (Optional) Struct with field 'preprocess.illumination'.
%
%   Outputs:
%       normImg - Illumination-normalized image (same class/range as input).
%
%   Example:
%       flatImg = preprocess.normalizeIllumination(fundusImg);

    % Parse inputs and defaults
    if nargin < 2 || isempty(cfg)
        defaultCfg = config();
        cfgIllum = defaultCfg.preprocess.illumination;
    elseif isfield(cfg, 'preprocess') && isfield(cfg.preprocess, 'illumination')
        cfgIllum = cfg.preprocess.illumination;
    else
        cfgIllum = cfg;
    end

    inputWasInteger = isinteger(img);
    origClass = class(img);

    % Convert to double [0, 1]
    if inputWasInteger
        imgD = im2double(img);
    else
        imgD = double(img);
        if max(imgD(:)) > 1.0
            imgD = imgD / 255.0;
        end
    end

    % Get retinal mask to handle background borders cleanly
    mask = quality.getFundusMask(imgD);
    if ~any(mask(:))
        mask = true(size(imgD, 1), size(imgD, 2));
    end

    sigma = 35;
    if isfield(cfgIllum, 'filterSigma')
        sigma = cfgIllum.filterSigma;
    end

    targetMean = 0.50;
    if isfield(cfgIllum, 'targetMean')
        targetMean = cfgIllum.targetMean;
    end

    numChannels = size(imgD, 3);
    normImgD = zeros(size(imgD), 'double');

    for c = 1:numChannels
        chan = imgD(:, :, c);

        % Inpaint outside background with mean channel intensity so the
        % Gaussian filter doesn't create severe dark ring artifacts at the periphery
        meanVal = mean(chan(mask));
        filledChan = chan;
        filledChan(~mask) = meanVal;

        % Estimate low-frequency background illumination
        bg = imgaussfilt(filledChan, sigma);

        % Compute average background level on retinal tissue
        bgMean = mean(bg(mask));

        % Normalize: subtract estimated background and restore mean level
        % Formula: I_corrected = I - bg + bgMean
        correctedChan = chan - bg + bgMean;

        % Contrast stretch slightly if dynamic range was shifted
        correctedChan(~mask) = 0; % Keep outer border black
        correctedChan = max(0.0, min(1.0, correctedChan));

        normImgD(:, :, c) = correctedChan;
    end

    % Cast back to original input format
    if inputWasInteger
        if strcmp(origClass, 'uint8')
            normImg = im2uint8(normImgD);
        elseif strcmp(origClass, 'uint16')
            normImg = im2uint16(normImgD);
        else
            normImg = cast(normImgD * 255, origClass);
        end
    else
        normImg = normImgD;
    end
end
