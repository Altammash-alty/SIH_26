function [results, compositeRGB] = segmentAll(enhancedImg, mask, cfg)
% SEGMENTALL Master coordinator for Stage 3 Retinal Segmentation Pipeline.
%
%   [RESULTS, COMPOSITERGB] = SEGMENT.SEGMENTALL(ENHANCEDIMG, MASK, CFG)
%
%   Executes the complete anatomical and pathological segmentation suite:
%       1. Optic Disc & Cup Segmentation (+ Cup-to-Disc Ratio CDR)
%       2. Retinal Vascular Tree Extraction (+ Density, Skeleton, Tortuosity)
%       3. Macula & Fovea Centralis Localization (+ 1-DD Hazard Zone)
%       4. Pathological Lesion Detection (Dark Hemorrhages/MAs & Bright Exudates)
%
%   Inputs:
%       enhancedImg  - Enhanced fundus image output from Stage 2 (double or uint8).
%       mask         - (Optional) Valid circular fundus aperture mask.
%       cfg          - (Optional) Configuration struct. Defaults to config().
%
%   Outputs:
%       results      - Comprehensive struct containing all segmented masks,
%                      landmarks, bounding boxes, and quantitative biomarkers.
%       compositeRGB - Multi-color diagnostic RGB overlay showing vessels,
%                      optic disc, fovea, hemorrhages, and exudates.
%
%   Example:
%       [segResults, compositeImg] = segment.segmentAll(enhancedFundus);
%       figure; imshow(compositeImg); title('Stage 3 Retinal Segmentation');
%
%   Author: DR Screening Pipeline MVP
%   Date: 2026-08-30

    % 1. Parse Inputs & Configuration
    if nargin < 3 || isempty(cfg)
        cfg = config();
    end

    if isempty(enhancedImg)
        error('segmentAll:EmptyInput', 'Input enhanced image cannot be empty.');
    end

    % Standardize double [0, 1]
    if isinteger(enhancedImg)
        imgD = im2double(enhancedImg);
    else
        imgD = double(enhancedImg);
        if max(imgD(:)) > 1.0
            imgD = imgD / 255.0;
        end
    end

    [rows, cols, numChannels] = size(imgD);

    if nargin < 2 || isempty(mask)
        mask = quality.getFundusMask(imgD);
    end

    % ---------------------------------------------------------------------
    % 2. Step 1: Optic Disc & Optic Cup Segmentation
    % ---------------------------------------------------------------------
    [odMask, odCenter, odRadius, cupMask, cdr, odDetails] = ...
        segment.segmentOpticDisc(imgD, mask, cfg);

    % ---------------------------------------------------------------------
    % 3. Step 2: Retinal Vascular Network Segmentation
    % ---------------------------------------------------------------------
    [vesselMask, vesselSkeleton, vesselDensity, tortuosityIndex, vesselDetails] = ...
        segment.segmentVessels(imgD, mask, cfg);

    % ---------------------------------------------------------------------
    % 4. Step 3: Macula & Fovea Centralis Localization
    % ---------------------------------------------------------------------
    [foveaCenter, foveaRadius, maculaHazardMask, maculaDetails] = ...
        segment.segmentMacula(imgD, odCenter, odRadius, mask, cfg);

    % ---------------------------------------------------------------------
    % 5. Step 4: Pathological Lesion Detection (Dark & Bright Lesions)
    % ---------------------------------------------------------------------
    [darkLesionMask, brightLesionMask, darkCount, brightCount, lesionDetails] = ...
        segment.segmentLesions(imgD, vesselMask, odMask, foveaCenter, mask, cfg);

    % ---------------------------------------------------------------------
    % 6. Construct Multi-Color Diagnostic Composite Overlay
    % ---------------------------------------------------------------------
    if numChannels == 1
        baseRGB = repmat(imgD, [1 1 3]);
    else
        baseRGB = imgD;
    end

    compositeRGB = baseRGB;
    
    % Color encoding standard:
    % - Vessels: Emerald Green [0.0, 0.9, 0.4]
    % - Optic Disc Boundary: Electric Blue [0.1, 0.6, 1.0]
    % - Optic Cup: Cyan [0.2, 0.9, 0.9]
    % - Fovea Center / Hazard: Orange/Magenta [1.0, 0.4, 0.0]
    % - Dark Lesions (Hemorrhages/MAs): Crimson Red [1.0, 0.05, 0.05]
    % - Bright Lesions (Exudates): Golden Yellow [1.0, 0.95, 0.1]

    % A. Overlay Vessels (Alpha blend)
    vesselIdx = find(vesselMask);
    if ~isempty(vesselIdx)
        compositeRGB(vesselIdx)             = 0.3 * compositeRGB(vesselIdx)             + 0.7 * 0.0;
        compositeRGB(vesselIdx + rows*cols)   = 0.3 * compositeRGB(vesselIdx + rows*cols)   + 0.7 * 0.9;
        compositeRGB(vesselIdx + 2*rows*cols) = 0.3 * compositeRGB(vesselIdx + 2*rows*cols) + 0.7 * 0.4;
    end

    % B. Overlay Optic Disc Perimeter
    odPerim = bwperim(odMask);
    odPerimDilated = imdilate(odPerim, strel('disk', 2));
    odPerimIdx = find(odPerimDilated);
    if ~isempty(odPerimIdx)
        compositeRGB(odPerimIdx)             = 0.1;
        compositeRGB(odPerimIdx + rows*cols)   = 0.6;
        compositeRGB(odPerimIdx + 2*rows*cols) = 1.0;
    end

    % C. Overlay Optic Cup Perimeter
    cupPerim = bwperim(cupMask);
    cupPerimIdx = find(cupPerim);
    if ~isempty(cupPerimIdx)
        compositeRGB(cupPerimIdx)             = 0.2;
        compositeRGB(cupPerimIdx + rows*cols)   = 0.9;
        compositeRGB(cupPerimIdx + 2*rows*cols) = 0.9;
    end

    % D. Overlay Fovea Center Marker (Crosshair)
    fX = round(foveaCenter(1));
    fY = round(foveaCenter(2));
    markerArm = max(4, round(min(rows, cols) * 0.02));
    if fX > markerArm && fX <= cols - markerArm && fY > markerArm && fY <= rows - markerArm
        foveaMarkerMask = false(rows, cols);
        foveaMarkerMask(max(1, fY-markerArm):min(rows, fY+markerArm), max(1, fX-1):min(cols, fX+1)) = true;
        foveaMarkerMask(max(1, fY-1):min(rows, fY+1), max(1, fX-markerArm):min(cols, fX+markerArm)) = true;
        
        mIdx = find(foveaMarkerMask);
        compositeRGB(mIdx)             = 1.0;
        compositeRGB(mIdx + rows*cols)   = 0.4;
        compositeRGB(mIdx + 2*rows*cols) = 0.0;
    end

    % E. Overlay Dark Lesions (Crimson Red)
    darkIdx = find(imdilate(darkLesionMask, strel('disk', 1)));
    if ~isempty(darkIdx)
        compositeRGB(darkIdx)             = 1.0;
        compositeRGB(darkIdx + rows*cols)   = 0.05;
        compositeRGB(darkIdx + 2*rows*cols) = 0.05;
    end

    % F. Overlay Bright Lesions (Golden Yellow)
    brightIdx = find(imdilate(brightLesionMask, strel('disk', 1)));
    if ~isempty(brightIdx)
        compositeRGB(brightIdx)             = 1.0;
        compositeRGB(brightIdx + rows*cols)   = 0.95;
        compositeRGB(brightIdx + 2*rows*cols) = 0.1;
    end

    % ---------------------------------------------------------------------
    % 7. Package Consolidated Results Struct
    % ---------------------------------------------------------------------
    results = struct();
    results.opticDisc = odDetails;
    results.opticDisc.mask = odMask;
    results.opticDisc.cupMask = cupMask;
    results.opticDisc.center = odCenter;
    results.opticDisc.radius = odRadius;
    results.opticDisc.cupToDiscRatio = cdr;

    results.vessels = vesselDetails;
    results.vessels.mask = vesselMask;
    results.vessels.skeleton = vesselSkeleton;
    results.vessels.density = vesselDensity;
    results.vessels.tortuosity = tortuosityIndex;

    results.macula = maculaDetails;
    results.macula.foveaCenter = foveaCenter;
    results.macula.foveaRadius = foveaRadius;
    results.macula.hazardMask = maculaHazardMask;

    results.lesions = lesionDetails;
    results.lesions.darkMask = darkLesionMask;
    results.lesions.brightMask = brightLesionMask;
    results.lesions.darkCount = darkCount;
    results.lesions.brightCount = brightCount;

    results.mask = mask;
    results.compositeRGB = compositeRGB;

end
