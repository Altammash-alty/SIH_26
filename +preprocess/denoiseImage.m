function denoisedImg = denoiseImage(img, cfg)
% DENOISEIMAGE Suppresses sensor and compression noise in retinal images.
%
%   DENOISEDIMG = PREPROCESS.DENOISEIMAGE(IMG) filters high-frequency
%   speckle and salt-and-pepper noise using median filtering while
%   preserving sharp vascular edges.
%
%   DENOISEDIMG = PREPROCESS.DENOISEIMAGE(IMG, CFG) uses denoising options
%   defined in CFG (see config.m).
%
%   Methods Supported:
%       - 'median' : 2D Median filtering (medfilt2) - ideal for edge-preserving
%                    suppression of impulse noise and compression artifacts.
%       - 'wiener' : 2D Adaptive Wiener filtering (wiener2) - pixelwise
%                    adaptive noise reduction based on local statistics.
%
%   Inputs:
%       img         - Input fundus image (RGB or grayscale, uint8, uint16, or double).
%       cfg         - (Optional) Struct with field 'preprocess.denoise'.
%
%   Outputs:
%       denoisedImg - Cleaned image with preserved vascular structures.
%
%   Example:
%       clean = preprocess.denoiseImage(noisyImg);

    % Parse inputs and defaults
    if nargin < 2 || isempty(cfg)
        defaultCfg = config();
        cfgDenoise = defaultCfg.preprocess.denoise;
    elseif isfield(cfg, 'preprocess') && isfield(cfg.preprocess, 'denoise')
        cfgDenoise = cfg.preprocess.denoise;
    else
        cfgDenoise = cfg;
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

    % Get retinal mask to ensure border stays clean
    mask = quality.getFundusMask(imgD);

    method = 'median';
    if isfield(cfgDenoise, 'method')
        method = cfgDenoise.method;
    end

    medKernel = [3 3];
    if isfield(cfgDenoise, 'medianKernel')
        medKernel = cfgDenoise.medianKernel;
    end

    wienerKernel = [3 3];
    if isfield(cfgDenoise, 'wienerKernel')
        wienerKernel = cfgDenoise.wienerKernel;
    end

    numChannels = size(imgD, 3);
    denoisedImgD = zeros(size(imgD), 'double');

    for c = 1:numChannels
        chan = imgD(:, :, c);

        switch lower(method)
            case 'median'
                % 2D median filter with symmetric boundary extension
                filteredChan = medfilt2(chan, medKernel, 'symmetric');

            case 'wiener'
                % 2D adaptive pixelwise Wiener filter
                filteredChan = wiener2(chan, wienerKernel);

            otherwise
                % Default fallback to median
                filteredChan = medfilt2(chan, [3 3], 'symmetric');
        end

        % Preserve clean outer black mask
        if any(mask(:))
            filteredChan(~mask) = 0;
        end

        denoisedImgD(:, :, c) = max(0.0, min(1.0, filteredChan));
    end

    % Cast back to original class
    if inputWasInteger
        if strcmp(origClass, 'uint8')
            denoisedImg = im2uint8(denoisedImgD);
        elseif strcmp(origClass, 'uint16')
            denoisedImg = im2uint16(denoisedImgD);
        else
            denoisedImg = cast(denoisedImgD * 255, origClass);
        end
    else
        denoisedImg = denoisedImgD;
    end
end
