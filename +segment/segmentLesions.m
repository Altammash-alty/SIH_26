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

    % Exclude main vascular tree (dilate vessel mask slightly to avoid vessel edge fringes)
    dilatedVessels = imdilate(vesselMask, strel('disk', 2));
    nonVesselMask = erodedMask & ~dilatedVessels & ~odMask;

    % Threshold bottom-hat response
    darkThresh = cfg.segment.lesion.darkSensitivity;
    rawDarkCand = (bothatGreen > darkThresh) & nonVesselMask;

    % Filter candidate dark lesions by size
    minDarkArea = cfg.segment.lesion.darkMinSize;
    maxDarkArea = cfg.segment.lesion.darkMaxSize;
    
    cleanDark = bwareaopen(rawDarkCand, minDarkArea);
    darkCC = bwconncomp(cleanDark);
    darkLesionMask = false(rows, cols);
    darkStatsList = [];

    if darkCC.NumObjects > 0
        statsD = regionprops(darkCC, 'Area', 'Centroid', 'Eccentricity', 'PixelIdxList');
        validDarkIdx = [];
        for i = 1:numel(statsD)
            area_i = statsD(i).Area;
            % Hemorrhages/MAs are moderately round or irregular blobs, not extremely long lines
            if area_i <= maxDarkArea && statsD(i).Eccentricity < 0.96
                darkLesionMask(statsD(i).PixelIdxList) = true;
                validDarkIdx(end+1) = i;
            end
        end
        darkStatsList = statsD(validDarkIdx);
        darkCount = numel(validDarkIdx);
    else
        darkCount = 0;
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

    brightThresh = cfg.segment.lesion.brightSensitivity;
    rawBrightCand = (brightSignal > brightThresh) & nonODMask;

    minBrightArea = cfg.segment.lesion.brightMinSize;
    maxBrightArea = cfg.segment.lesion.brightMaxSize;

    cleanBright = bwareaopen(rawBrightCand, minBrightArea);
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
