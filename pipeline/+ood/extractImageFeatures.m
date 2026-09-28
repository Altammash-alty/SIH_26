function [featureVec, featureNames] = extractImageFeatures(img, cfg)
% EXTRACTIMAGEFEATURES Computes a compact statistical feature vector for OOD detection.
%
%   [FEATUREVEC, FEATURENAMES] = OOD.EXTRACTIMAGEFEATURES(IMG) extracts a
%   compact, interpretable 1xD numerical feature representation from an input
%   fundus image within its detected retinal aperture.
%
%   [FEATUREVEC, FEATURENAMES] = OOD.EXTRACTIMAGEFEATURES(IMG, CFG) uses
%   parameters provided in CFG (see config.m).
%
%   Feature Categories Extracted:
%       1. Color Channel Statistics (R, G, B, and Luminance):
%          - Mean, standard deviation, skewness, 10th percentile, 90th percentile
%          - Channel ratios (Red-to-Green, Green-to-Blue)
%       2. Haralick Texture Metrics (via graycomatrix / graycoprops on Green channel):
%          - Contrast: Intensity variation between neighboring pixels
%          - Correlation: Linear dependency of gray levels
%          - Energy: Uniformity / Angular Second Moment
%          - Homogeneity: Closeness of element distribution to diagonal
%       3. Spatial Gradient & Frequency Metrics:
%          - Mean gradient magnitude inside retinal mask
%          - Gradient standard deviation & edge energy ratio
%
%   Inputs:
%       img          - Preprocessed or raw fundus image (RGB/Grayscale, double or uint8).
%       cfg          - (Optional) Struct with field 'ood' or output of config().
%
%   Outputs:
%       featureVec   - 1xD row vector of double precision feature values.
%       featureNames - 1xD cell array of descriptive feature names.
%
%   Notes & Scope:
%       This function extracts classical, low-dimensional statistical markers
%       characterizing the visual distribution of typical retinal photography.
%       It does NOT use deep embeddings and does NOT perform any learning.
%
%   Author: DR Screening Pipeline MVP
%   Date: 2026-09-02

    % 1. Parse configuration
    if nargin < 2 || isempty(cfg)
        cfg = config();
    end

    glcmLevels = 16;
    if isfield(cfg, 'ood') && isfield(cfg.ood, 'glcmNumLevels')
        glcmLevels = cfg.ood.glcmNumLevels;
    end

    glcmOffsets = [0 1; -1 1; -1 0; -1 -1];
    if isfield(cfg, 'ood') && isfield(cfg.ood, 'glcmOffsets')
        glcmOffsets = cfg.ood.glcmOffsets;
    end

    % 2. Normalize input image to double [0, 1]
    if isinteger(img)
        imgD = im2double(img);
    else
        imgD = double(img);
        if max(imgD(:)) > 1.0
            imgD = imgD / 255.0;
        end
    end

    % Ensure 3-channel RGB representation
    if ndims(imgD) == 2
        imgD = cat(3, imgD, imgD, imgD);
    end

    % 3. Extract retinal mask
    mask = quality.getFundusMask(imgD);
    if ~any(mask(:))
        mask = true(size(imgD, 1), size(imgD, 2));
    end

    % 4. Color Channel Statistics
    R = imgD(:, :, 1);
    G = imgD(:, :, 2);
    B = imgD(:, :, 3);
    Lum = 0.2989 * R + 0.5870 * G + 0.1140 * B;

    rPix = R(mask);
    gPix = G(mask);
    bPix = B(mask);
    lumPix = Lum(mask);

    % Helper for moments (mean, std, skewness, p10, p90)
    function [m, s, sk, p10, p90] = calcMoments(v)
        if isempty(v)
            m = 0; s = 0; sk = 0; p10 = 0; p90 = 0;
            return;
        end
        m = mean(v);
        s = std(v);
        if s > 1e-8
            sk = mean(((v - m) / s).^3);
        else
            sk = 0;
        end
        p10 = prctile(v, 10);
        p90 = prctile(v, 90);
    end

    [rMean, rStd, rSkew, rP10, rP90] = calcMoments(rPix);
    [gMean, gStd, gSkew, gP10, gP90] = calcMoments(gPix);
    [bMean, bStd, bSkew, bP10, bP90] = calcMoments(bPix);
    [lumMean, lumStd, lumSkew, lumP10, lumP90] = calcMoments(lumPix);

    rgRatio = (rMean + 1e-4) / (gMean + 1e-4);
    gbRatio = (gMean + 1e-4) / (bMean + 1e-4);

    % 5. Haralick Texture Statistics (on Green channel inside mask)
    % Quantize green channel to discrete levels for GLCM
    gQuant = imquantize(G, linspace(0, 1, glcmLevels + 1));
    % Apply mask: zero out background so it doesn't skew GLCM
    gQuant(~mask) = 0;

    try
        % Compute Gray-Level Co-occurrence Matrix
        glcm = graycomatrix(gQuant, 'NumLevels', glcmLevels + 1, ...
            'Offset', glcmOffsets, 'Symmetric', true);
        % Omit background zero bin by slicing levels 2:end
        glcmValid = glcm(2:end, 2:end, :);
        % Normalize GLCM slices
        for k = 1:size(glcmValid, 3)
            sK = sum(sum(glcmValid(:, :, k)));
            if sK > 0
                glcmValid(:, :, k) = glcmValid(:, :, k) / sK;
            end
        end
        stats = graycoprops(glcmValid, {'Contrast', 'Correlation', 'Energy', 'Homogeneity'});
        texContrast = mean(stats.Contrast);
        texCorrelation = mean(stats.Correlation);
        if isnan(texCorrelation), texCorrelation = 0; end
        texEnergy = mean(stats.Energy);
        texHomogeneity = mean(stats.Homogeneity);
    catch
        texContrast = 0.0;
        texCorrelation = 0.0;
        texEnergy = 0.0;
        texHomogeneity = 0.0;
    end

    % 6. Spatial Gradient & Edge Statistics
    [Gx, Gy] = gradient(G);
    gradMag = sqrt(Gx.^2 + Gy.^2);
    gradPix = gradMag(mask);

    gradMean = mean(gradPix);
    gradStd = std(gradPix);
    edgeRatio = sum(gradPix > (gradMean + 1.5 * gradStd)) / max(1, numel(gradPix));

    % 7. Assemble Feature Vector & Name Mapping
    featureNames = { ...
        'Red_Mean', 'Red_Std', 'Red_Skewness', 'Red_P10', 'Red_P90', ...
        'Green_Mean', 'Green_Std', 'Green_Skewness', 'Green_P10', 'Green_P90', ...
        'Blue_Mean', 'Blue_Std', 'Blue_Skewness', 'Blue_P10', 'Blue_P90', ...
        'Lum_Mean', 'Lum_Std', 'Lum_Skewness', 'Lum_P10', 'Lum_P90', ...
        'RG_Ratio', 'GB_Ratio', ...
        'Texture_Contrast', 'Texture_Correlation', 'Texture_Energy', 'Texture_Homogeneity', ...
        'Gradient_Mean', 'Gradient_Std', 'Edge_Ratio' ...
    };

    featureVec = [ ...
        rMean, rStd, rSkew, rP10, rP90, ...
        gMean, gStd, gSkew, gP10, gP90, ...
        bMean, bStd, bSkew, bP10, bP90, ...
        lumMean, lumStd, lumSkew, lumP10, lumP90, ...
        rgRatio, gbRatio, ...
        texContrast, texCorrelation, texEnergy, texHomogeneity, ...
        gradMean, gradStd, edgeRatio ...
    ];

    % Ensure row vector and sanitize NaNs/Infs
    featureVec = featureVec(:)';
    featureVec(isnan(featureVec) | isinf(featureVec)) = 0.0;

end
