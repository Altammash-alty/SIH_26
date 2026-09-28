function lesionMapRGB = createLesionMap(enhancedImg, segmentResults, cfg)
% CREATELESIONMAP Constructs the multi-quadrant ETDRS pathological lesion map.
%
%   LESIONMAPRGB = EXPLAIN.CREATELESIONMAP(ENHANCEDIMG, SEGMENTRESULTS, CFG)
%
%   Generates a high-contrast clinical diagnostic overlay displaying:
%       - 4-Quadrant ETDRS grid divisions centered at the Fovea
%       - 1-Disc-Diameter Macular Hazard Boundary
%       - Detected Dark Lesions (Hemorrhages / Microaneurysms) highlighted in Red
%       - Detected Bright Lesions (Hard Exudates) highlighted in Yellow
%       - Segmented Optic Disc contour in Blue
%
%   Inputs:
%       enhancedImg    - Preprocessed fundus image from Stage 2.
%       segmentResults - Segmentation struct from Stage 3 (segment.segmentAll).
%       cfg            - (Optional) Configuration struct. Defaults to config().
%
%   Outputs:
%       lesionMapRGB   - Annotated RGB image for clinical review.
%
%   Author: DR Screening Pipeline MVP
%   Date: 2026-08-30

    % 1. Parse Inputs & Configuration
    if nargin < 3 || isempty(cfg)
        cfg = config();
    end

    if isempty(enhancedImg) || isempty(segmentResults)
        error('createLesionMap:EmptyInput', 'Image and segmentation results required.');
    end

    % Convert to double [0, 1]
    if isinteger(enhancedImg)
        imgD = im2double(enhancedImg);
    else
        imgD = double(enhancedImg);
        if max(imgD(:)) > 1.0
            imgD = imgD / 255.0;
        end
    end

    [rows, cols, numChannels] = size(imgD);
    if numChannels == 1
        baseRGB = repmat(imgD, [1 1 3]);
    else
        baseRGB = imgD;
    end

    lesionMapRGB = baseRGB;
    mask = segmentResults.mask;

    % 2. Extract Key Anatomical Landmarks
    foveaCenter = segmentResults.macula.foveaCenter;
    foveaX = round(foveaCenter(1));
    foveaY = round(foveaCenter(2));
    hazardMask = segmentResults.macula.hazardMask;
    odMask = segmentResults.opticDisc.mask;
    darkMask = segmentResults.lesions.darkMask;
    brightMask = segmentResults.lesions.brightMask;

    % 3. Draw 4-Quadrant ETDRS Division Lines
    if cfg.explain.quadrantLines
        % Horizontal line through fovea
        if foveaY >= 1 && foveaY <= rows
            hLineMask = false(rows, cols);
            hLineMask(foveaY, :) = true;
            hLineMask = hLineMask & mask;
            % Stippled / dashed line pattern
            colsGrid = repmat(1:cols, [rows 1]);
            hLineDashed = hLineMask & (mod(colsGrid, 8) < 5);
            hIdx = find(hLineDashed);
            lesionMapRGB(hIdx)             = 0.9;
            lesionMapRGB(hIdx + rows*cols)   = 0.9;
            lesionMapRGB(hIdx + 2*rows*cols) = 0.9;
        end
        
        % Vertical line through fovea
        if foveaX >= 1 && foveaX <= cols
            vLineMask = false(rows, cols);
            vLineMask(:, foveaX) = true;
            vLineMask = vLineMask & mask;
            rowsGrid = repmat((1:rows)', [1 cols]);
            vLineDashed = vLineMask & (mod(rowsGrid, 8) < 5);
            vIdx = find(vLineDashed);
            lesionMapRGB(vIdx)             = 0.9;
            lesionMapRGB(vIdx + rows*cols)   = 0.9;
            lesionMapRGB(vIdx + 2*rows*cols) = 0.9;
        end
    end

    % 4. Draw 1-Disc-Diameter Macular Hazard Circle
    hazardPerim = bwperim(hazardMask);
    hazardPerimDilated = imdilate(hazardPerim, strel('disk', 1));
    hPerimIdx = find(hazardPerimDilated);
    if ~isempty(hPerimIdx)
        lesionMapRGB(hPerimIdx)             = 1.0; % Orange [1.0, 0.55, 0.0]
        lesionMapRGB(hPerimIdx + rows*cols)   = 0.55;
        lesionMapRGB(hPerimIdx + 2*rows*cols) = 0.0;
    end

    % 5. Draw Optic Disc Contour (Blue)
    odPerim = bwperim(odMask);
    odPerimDilated = imdilate(odPerim, strel('disk', 2));
    odPerimIdx = find(odPerimDilated);
    if ~isempty(odPerimIdx)
        lesionMapRGB(odPerimIdx)             = 0.0;
        lesionMapRGB(odPerimIdx + rows*cols)   = 0.6;
        lesionMapRGB(odPerimIdx + 2*rows*cols) = 1.0;
    end

    % 6. Highlight Dark Lesions (Crimson Red with boundary dilation)
    darkDilated = imdilate(darkMask, strel('disk', 2));
    dIdx = find(darkDilated);
    if ~isempty(dIdx)
        lesionMapRGB(dIdx)             = 1.0;
        lesionMapRGB(dIdx + rows*cols)   = 0.05;
        lesionMapRGB(dIdx + 2*rows*cols) = 0.05;
    end

    % 7. Highlight Bright Lesions (Bright Yellow with boundary dilation)
    brightDilated = imdilate(brightMask, strel('disk', 2));
    bIdx = find(brightDilated);
    if ~isempty(bIdx)
        lesionMapRGB(bIdx)             = 1.0;
        lesionMapRGB(bIdx + rows*cols)   = 0.95;
        lesionMapRGB(bIdx + 2*rows*cols) = 0.05;
    end

    % 8. Clean non-fundus background
    for c = 1:3
        channelData = lesionMapRGB(:,:,c);
        channelData(~mask) = 0;
        lesionMapRGB(:,:,c) = channelData;
    end

end
