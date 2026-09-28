function enhancedImg = claheGreenChannel(img, cfg)
% CLAHEGREENCHANNEL Applies CLAHE contrast enhancement specifically on the Green channel.
%
%   ENHANCEDIMG = PREPROCESS.CLAHEGREENCHANNEL(IMG) applies Contrast-Limited
%   Adaptive Histogram Equalization (CLAHE) to the green channel of a fundus
%   image (where hemoglobin absorption and vascular contrast are highest)
%   and recombines it into an enhanced color image.
%
%   ENHANCEDIMG = PREPROCESS.CLAHEGREENCHANNEL(IMG, CFG) uses custom CLAHE
%   parameters specified in CFG (see config.m).
%
%   Rationale:
%       In ophthalmic fundus imaging, the Green channel exhibits optimal
%       signal-to-noise ratio and spectral contrast for retinal vessels,
%       microaneurysms, hard exudates, and hemorrhages. Enhancing the green
%       channel dramatically improves lesion detectability without blowing
%       out color naturalness.
%
%   Inputs:
%       img         - Input fundus image (RGB or grayscale, uint8, uint16, or double).
%       cfg         - (Optional) Struct with field 'preprocess.clahe'.
%
%   Outputs:
%       enhancedImg - Contrast-enhanced image with recombined color channels.
%
%   Example:
%       enhanced = preprocess.claheGreenChannel(fundusImg);

    % Parse inputs and defaults
    if nargin < 2 || isempty(cfg)
        defaultCfg = config();
        cfgClahe = defaultCfg.preprocess.clahe;
    elseif isfield(cfg, 'preprocess') && isfield(cfg.preprocess, 'clahe')
        cfgClahe = cfg.preprocess.clahe;
    else
        cfgClahe = cfg;
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

    % Get retinal mask to keep black background pristine
    mask = quality.getFundusMask(imgD);

    % Setup adapthisteq options
    clipLimit = 0.015;
    if isfield(cfgClahe, 'clipLimit')
        clipLimit = cfgClahe.clipLimit;
    end

    numTiles = [8 8];
    if isfield(cfgClahe, 'numTiles')
        numTiles = cfgClahe.numTiles;
    end

    distribution = 'rayleigh';
    if isfield(cfgClahe, 'distribution')
        distribution = cfgClahe.distribution;
    end

    alpha = 0.4;
    if isfield(cfgClahe, 'alpha')
        alpha = cfgClahe.alpha;
    end

    % Apply CLAHE based on image dimensionality
    if ndims(imgD) == 3
        % Extract individual channels
        R = imgD(:, :, 1);
        G = imgD(:, :, 2);
        B = imgD(:, :, 3);

        % Apply CLAHE specifically on the Green channel
        if strcmpi(distribution, 'rayleigh')
            G_clahe = adapthisteq(G, 'ClipLimit', clipLimit, 'NumTiles', numTiles, ...
                                  'Distribution', 'rayleigh', 'Alpha', alpha);
        else
            G_clahe = adapthisteq(G, 'ClipLimit', clipLimit, 'NumTiles', numTiles, ...
                                  'Distribution', distribution);
        end

        % Maintain outer background mask as black
        if any(mask(:))
            G_clahe(~mask) = 0;
            R(~mask) = 0;
            B(~mask) = 0;
        end

        % Recombine color channels
        enhancedImgD = cat(3, R, G_clahe, B);

    else
        % Grayscale image
        if strcmpi(distribution, 'rayleigh')
            enhancedImgD = adapthisteq(imgD, 'ClipLimit', clipLimit, 'NumTiles', numTiles, ...
                                      'Distribution', 'rayleigh', 'Alpha', alpha);
        else
            enhancedImgD = adapthisteq(imgD, 'ClipLimit', clipLimit, 'NumTiles', numTiles, ...
                                      'Distribution', distribution);
        end
        if any(mask(:))
            enhancedImgD(~mask) = 0;
        end
    end

    % Cast back to original class
    if inputWasInteger
        if strcmp(origClass, 'uint8')
            enhancedImg = im2uint8(enhancedImgD);
        elseif strcmp(origClass, 'uint16')
            enhancedImg = im2uint16(enhancedImgD);
        else
            enhancedImg = cast(enhancedImgD * 255, origClass);
        end
    else
        enhancedImg = enhancedImgD;
    end
end
