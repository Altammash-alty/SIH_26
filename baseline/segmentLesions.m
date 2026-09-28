function [darkLesionMask, brightLesionMask, darkCount, brightCount, details] = ...
    segmentLesions(img, vesselMask, odMask, foveaCenter, mask, cfg)
% SEGMENTLESIONS Detects dark lesions (hemorrhages/MAs) and bright lesions (exudates).
%
%   [DARKLESIONMASK, BRIGHTLESIONMASK, DARKCOUNT, BRIGHTCOUNT, DETAILS] = ...
%       SEGMENT.SEGMENTLESIONS(IMG, VESSELMASK, ODMASK, FOVEACENTER, MASK, CFG)
%
%   Detects pathognomonic lesions of Diabetic Retinopathy:
%       1. Dark Lesions: Microaneurysms (MAs), dot/blot intraretinal hemorrhages,
%          and preretinal/vitreous hemorrhages.
%       2. Bright Lesions: Hard Exudates (lipid/protein extravasations) and
%          Cotton Wool Spots (soft exudates / axoplasmic flow stasis).
%
%   Inputs:
%       img         - Enhanced fundus image (RGB double [0, 1]).
%       vesselMask  - Binary mask of segmented blood vessels (from segmentVessels).
%       odMask      - Binary mask of Optic Disc (from segmentOpticDisc).
%       foveaCenter - [X, Y] coordinates of Fovea (from segmentMacula).
%       mask        - (Optional) Foreground circular fundus mask.
%       cfg         - (Optional) Configuration struct. Defaults to config().
%
%   Outputs:
%       darkLesionMask   - Logical 2D binary mask of detected hemorrhages/MAs.
%       brightLesionMask - Logical 2D binary mask of detected hard/soft exudates.
%       darkCount        - Integer count of distinct dark lesion clusters.
%       brightCount      - Integer count of distinct bright lesion clusters.
%       details          - Struct containing lesion coordinates, quadrant distribution,
%                          and distance of nearest lesion to the fovea.
%
%   Author: DR Screening Pipeline MVP
%   Date: 2026-08-30

    % 1. Parse Inputs & Configuration
    if nargin < 6 || isempty(cfg)
        cfg = config();
    end

    if isempty(img)
        error('segmentLesions:EmptyInput', 'Input image cannot be empty.');
    end

    % Convert to double [0, 1]
    if isinteger(img)
        imgD = im2double(img);
    else
        imgD = double(img);
        if max(imgD(:)) > 1.0
            imgD = imgD / 255.0;
        end
    end

    [rows, cols, numChannels] = size(imgD);

    if nargin < 5 || isempty(mask)
        mask = quality.getFundusMask(imgD);
    end

    if nargin < 2 || isempty(vesselMask)
        vesselMask = false(rows, cols);
    end

    if nargin < 3 || isempty(odMask)
        odMask = false(rows, cols);
    end

    if nargin < 4 || isempty(foveaCenter)
        foveaCenter = [cols / 2.0, rows / 2.0];
    end

    % Erode fundus mask to prevent false boundary detections
    erodedMask = imerode(mask, strel('disk', max(8, round(min(rows, cols) * 0.02))));

    % 2. Extract Processing Channels
    if numChannels == 3
        greenCh = imgD(:,:,2);
        redCh   = imgD(:,:,1);
        blueCh  = imgD(:,:,3);
    else
        greenCh = imgD;
        redCh   = imgD;
        blueCh  = imgD;
    end

    % ---------------------------------------------------------------------
    % 3. DETECT DARK LESIONS (Microaneurysms & Hemorrhages)
    % ---------------------------------------------------------------------
    % Dark lesions appear darker than local background in green channel.
    % Morphological bottom-hat isolates dark local minima.
    seDark = strel('disk', 12);
    bothatGreen = imbothat(greenCh, seDark);
    bothatGreen = bothatGreen .* erodedMask;

    % Exclude main vascular tree (dilate vessel mask by 3px to avoid vessel edge fringes/bifurcations)
    dilatedVessels = imdilate(vesselMask, strel('disk', 3));
    nonVesselMask = erodedMask & ~dilatedVessels & ~odMask;

    % Statistical Adaptive Thresholding for Dark Lesions
    % darkSensitivity = N standard deviations above this image's own bottom-hat background
    bgDarkVals = bothatGreen(nonVesselMask);
    if isempty(bgDarkVals)
        bgDarkMean = 0;
        bgDarkStd = 0.01;
    else
        bgDarkMean = mean(bgDarkVals);
        bgDarkStd = std(bgDarkVals);
    end
    darkThresh = bgDarkMean + cfg.segment.lesion.darkSensitivity * bgDarkStd;
    rawDarkCand = (bothatGreen > darkThresh) & nonVesselMask;

    % Minimum Contrast-Above-Local-Surroundings Check:
    % Large-radius closing (radius 36px ~ 3x seDark) computes local green background.
    % Real focal hemorrhages/MAs must be darker than their immediate surrounding background by darkLocalMinContrast.
    if isfield(cfg.segment.lesion, 'darkLocalMinContrast') && cfg.segment.lesion.darkLocalMinContrast > 0
        seLocalBg = strel('disk', 36);
        localDarkBg = imclose(greenCh, seLocalBg);
        darkContrast = (localDarkBg - greenCh) .* nonVesselMask;
        rawDarkCand = rawDarkCand & (darkContrast >= cfg.segment.lesion.darkLocalMinContrast);
    end

    % Filter candidate dark lesions by size
    minDarkArea = cfg.segment.lesion.darkMinSize;
    maxDarkArea = cfg.segment.lesion.darkMaxSize;
    
    cleanDark = bwareaopen(rawDarkCand, minDarkArea);
    if isfield(cfg, 'debug') && cfg.debug
        fprintf('[segmentLesions] dark raw=%d afterArea=%d (adaptive thresh=%.4f, mean=%.4f, std=%.4f)\n', ...
            nnz(rawDarkCand), nnz(cleanDark), darkThresh, bgDarkMean, bgDarkStd);
    end
    darkCC = bwconncomp(cleanDark);
    darkLesionMask = false(rows, cols);
    darkStatsList = [];

    if darkCC.NumObjects > 0
        statsD = regionprops(darkCC, 'Area', 'Centroid', 'Eccentricity', 'Solidity', 'PixelIdxList');
        validDarkIdx = [];
        for i = 1:numel(statsD)
            area_i = statsD(i).Area;
            % Hemorrhages/MAs are round or solid oval blobs (Eccentricity < 0.96 & Solidity > 0.70)
            if area_i <= maxDarkArea && statsD(i).Eccentricity < 0.96 && statsD(i).Solidity > 0.70
                darkLesionMask(statsD(i).PixelIdxList) = true;
                validDarkIdx(end+1) = i;
            end
        end
        darkStatsList = statsD(validDarkIdx);
        darkCount = numel(validDarkIdx);
    else
        darkCount = 0;
    end
    if isfield(cfg, 'debug') && cfg.debug
        fprintf('[segmentLesions] dark afterShape=%d\n', darkCount);
    end

    % ---------------------------------------------------------------------
    % 4. DETECT BRIGHT LESIONS (Hard Exudates & Cotton Wool Spots)
    % ---------------------------------------------------------------------
    % Exudates appear bright and yellowish (high in both Red & Green channels).
    % Exclude the Optic Disc region (dilate OD mask to remove peripapillary halo).
    dilatedOD = imdilate(odMask, strel('disk', max(8, round(min(rows, cols) * 0.02))));
    nonODMask = erodedMask & ~dilatedOD;

    % Top-hat transform highlights bright local extrema
    seBright = strel('disk', 10);
    tophatGreen = imtophat(greenCh, seBright);
    tophatRed   = imtophat(redCh, seBright);
    brightSignal = (0.6 * tophatGreen + 0.4 * tophatRed) .* nonODMask;

    % Yellowness gate: distinguish true yellow exudates from white/specular glare
    yellownessMask = (redCh > 0.3) & (greenCh > 0.3) & ...
        (blueCh < 0.6 * ((redCh + greenCh) / 2));
    brightSignal = brightSignal .* yellownessMask;

    % Statistical Adaptive Thresholding for Bright Lesions
    bgBrightVals = brightSignal(nonODMask);
    if isempty(bgBrightVals)
        bgBrightMean = 0;
        bgBrightStd = 0.01;
    else
        bgBrightMean = mean(bgBrightVals);
        bgBrightStd = std(bgBrightVals);
    end
    brightThresh = bgBrightMean + cfg.segment.lesion.brightSensitivity * bgBrightStd;
    rawBrightCand = (brightSignal > brightThresh) & nonODMask;

    % Minimum Contrast-Above-Local-Surroundings Check:
    % Large-radius opening (radius 30px ~ 3x seBright) computes local red/green background.
    % Real focal exudates must stand out above immediate local retina by brightLocalMinContrast.
    if isfield(cfg.segment.lesion, 'brightLocalMinContrast') && cfg.segment.lesion.brightLocalMinContrast > 0
        seLocalBright = strel('disk', 30);
        localBrightBg = (0.6 * imopen(greenCh, seLocalBright) + 0.4 * imopen(redCh, seLocalBright));
        brightContrast = ((0.6 * greenCh + 0.4 * redCh) - localBrightBg) .* nonODMask;
        rawBrightCand = rawBrightCand & (brightContrast >= cfg.segment.lesion.brightLocalMinContrast);
    end

    minBrightArea = cfg.segment.lesion.brightMinSize;
    maxBrightArea = cfg.segment.lesion.brightMaxSize;

    cleanBright = bwareaopen(rawBrightCand, minBrightArea);
    if isfield(cfg, 'debug') && cfg.debug
        fprintf('[segmentLesions] bright raw=%d afterArea=%d (adaptive thresh=%.4f, mean=%.4f, std=%.4f)\n', ...
            nnz(rawBrightCand), nnz(cleanBright), brightThresh, bgBrightMean, bgBrightStd);
    end
    brightCC = bwconncomp(cleanBright);
    brightLesionMask = false(rows, cols);
    brightStatsList = [];

    if brightCC.NumObjects > 0
        statsB = regionprops(brightCC, 'Area', 'Centroid', 'Eccentricity', 'PixelIdxList');
        validBrightIdx = [];
        for j = 1:numel(statsB)
            area_j = statsB(j).Area;
            if area_j <= maxBrightArea
                brightLesionMask(statsB(j).PixelIdxList) = true;
                validBrightIdx(end+1) = j;
            end
        end
        brightStatsList = statsB(validBrightIdx);
        brightCount = numel(validBrightIdx);
    else
        brightCount = 0;
    end

    % ---------------------------------------------------------------------
    % 5. QUANTIFY QUADRANT DISTRIBUTION (ETDRS Standard)
    % ---------------------------------------------------------------------
    % Quadrants are centered at fovea: Superior-Temporal (ST), Superior-Nasal (SN),
    % Inferior-Temporal (IT), Inferior-Nasal (IN).
    quadrantDarkCount = zeros(1, 4); % [ST, SN, IT, IN]
    quadrantBrightCount = zeros(1, 4);
    minDistToFovea = Inf;

    for i = 1:numel(darkStatsList)
        pt = darkStatsList(i).Centroid;
        distFovea = sqrt((pt(1) - foveaCenter(1))^2 + (pt(2) - foveaCenter(2))^2);
        minDistToFovea = min(minDistToFovea, distFovea);
        
        qIdx = getQuadrantIndex(pt, foveaCenter);
        quadrantDarkCount(qIdx) = quadrantDarkCount(qIdx) + 1;
    end

    for j = 1:numel(brightStatsList)
        pt = brightStatsList(j).Centroid;
        distFovea = sqrt((pt(1) - foveaCenter(1))^2 + (pt(2) - foveaCenter(2))^2);
        minDistToFovea = min(minDistToFovea, distFovea);
        
        qIdx = getQuadrantIndex(pt, foveaCenter);
        quadrantBrightCount(qIdx) = quadrantBrightCount(qIdx) + 1;
    end

    if isinf(minDistToFovea)
        minDistToFovea = 999.0;
    end

    % 6. Package Details Struct
    details = struct();
    details.darkCount = darkCount;
    details.brightCount = brightCount;
    details.darkAreaTotalPixels = sum(darkLesionMask(:));
    details.brightAreaTotalPixels = sum(brightLesionMask(:));
    details.quadrantDarkCount = quadrantDarkCount;     % [ST, SN, IT, IN]
    details.quadrantBrightCount = quadrantBrightCount; % [ST, SN, IT, IN]
    details.minDistToFoveaPixels = minDistToFovea;
    details.darkStats = darkStatsList;
    details.brightStats = brightStatsList;

end

function qIdx = getQuadrantIndex(pt, center)
    % Assigns a 2D point to one of four ETDRS quadrants:
    % 1: Superior-Temporal (Top-Left / Top-Right depending on eye; here X < cx, Y < cy)
    % 2: Superior-Nasal
    % 3: Inferior-Temporal
    % 4: Inferior-Nasal
    if pt(2) < center(2)
        if pt(1) < center(1)
            qIdx = 1; % ST
        else
            qIdx = 2; % SN
        end
    else
        if pt(1) < center(1)
            qIdx = 3; % IT
        else
            qIdx = 4; % IN
        end
    end
end
