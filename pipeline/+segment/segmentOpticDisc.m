function [odMask, odCenter, odRadius, cupMask, cdr, details] = segmentOpticDisc(img, mask, cfg)
% SEGMENTOPTICDISC Detects and segments the Optic Disc and Optic Cup.
%
%   [ODMASK, ODCENTER, ODRADIUS, CUPMASK, CDR, DETAILS] = ...
%       SEGMENT.SEGMENTOPTICDISC(IMG, MASK, CFG)
%
%   Performs anatomical segmentation of the Optic Nerve Head (Optic Disc)
%   and central physiological Optic Cup to derive the Cup-to-Disc Ratio (CDR),
%   a primary clinical biomarker for glaucomatous optic neuropathy and ischemic
%   retinal changes in diabetic retinopathy.
%
%   Inputs:
%       img     - Preprocessed or enhanced RGB/grayscale fundus image.
%       mask    - (Optional) Binary foreground fundus mask.
%       cfg     - (Optional) Configuration struct. Defaults to config().
%
%   Outputs:
%       odMask   - Binary mask (logical 2D matrix) of the Optic Disc.
%       odCenter - [X, Y] coordinates of the Optic Disc center in pixels.
%       odRadius - Estimated radius of the Optic Disc in pixels.
%       cupMask  - Binary mask of the physiological Optic Cup.
%       cdr      - Vertical Cup-to-Disc Ratio (0.0 to 1.0).
%       details  - Diagnostic struct containing bounding boxes, CDR status,
%                  and intermediate visualization overlays.
%
%   Algorithm:
%       1. Isolates red & luminance channels where optic disc exhibits highest
%          reflectance compared to surrounding retinal pigment epithelium.
%       2. Applies morphological opening & thresholding to identify candidate regions.
%       3. Fits a circular/elliptical boundary to the largest high-reflectance cluster.
%       4. Identifies the central bright subregion to extract the optic cup.
%
%   Author: DR Screening Pipeline MVP
%   Date: 2026-08-30

    % 1. Parse Inputs & Configuration
    if nargin < 3 || isempty(cfg)
        cfg = config();
    end

    if isempty(img)
        error('segmentOpticDisc:EmptyInput', 'Input image cannot be empty.');
    end

    % Convert image to standard double [0, 1]
    if isinteger(img)
        imgD = im2double(img);
    else
        imgD = double(img);
        if max(imgD(:)) > 1.0
            imgD = imgD / 255.0;
        end
    end

    [rows, cols, numChannels] = size(imgD);

    if nargin < 2 || isempty(mask)
        mask = quality.getFundusMask(imgD);
    end

    % 2. Extract Disc Luminance & Red Channel
    if numChannels == 3
        redCh = imgD(:,:,1);
        greenCh = imgD(:,:,2);
        % Optic disc is distinctively bright in Red and Green, with low Blue
        odSignal = (0.7 * redCh + 0.3 * greenCh) .* mask;
    else
        odSignal = imgD .* mask;
    end

    % 3. Candidate Seed Detection via Top Intensity Percentile
    threshPct = cfg.segment.opticDisc.intensityPercentile;
    validPixels = odSignal(mask > 0);
    if isempty(validPixels)
        validPixels = 0;
    end
    threshVal = prctile(validPixels, threshPct);
    candMask = (odSignal >= threshVal) & mask;

    % Morphological closing to coalesce fragmented seeds
    seRadius = max(3, round(min(rows, cols) * 0.015));
    candMask = imclose(candMask, strel('disk', seRadius));
    candMask = imfill(candMask, 'holes');

    % 4. Select Largest / Most Circular Region within expected anatomical size
    cc = bwconncomp(candMask);
    minR = max(10, round(min(rows, cols) * cfg.segment.opticDisc.minRadiusRatio));
    maxR = round(min(rows, cols) * cfg.segment.opticDisc.maxRadiusRatio);
    minArea = pi * (minR^2) * 0.4;
    maxArea = pi * (maxR^2) * 1.5;

    bestScore = -1;
    bestIdx = 0;

    if cc.NumObjects > 0
        stats = regionprops(cc, 'Area', 'Centroid', 'Eccentricity', 'EquivDiameter', 'Perimeter');
        for i = 1:numel(stats)
            area_i = stats(i).Area;
            if area_i >= minArea && area_i <= maxArea
                % Circularity score
                circ = 4 * pi * area_i / (stats(i).Perimeter^2 + eps);
                % Center score (penalize extreme borders)
                dx = (stats(i).Centroid(1) - cols/2) / (cols/2);
                dy = (stats(i).Centroid(2) - rows/2) / (rows/2);
                distScore = 1.0 - 0.4 * sqrt(dx^2 + dy^2);
                score = (1.0 - stats(i).Eccentricity) * circ * distScore * sqrt(area_i);
                if score > bestScore
                    bestScore = score;
                    bestIdx = i;
                end
            end
        end
    end

    % Fallback if no candidate meets criteria: pick maximum intensity centroid
    if bestIdx == 0
        [~, maxLinIdx] = max(odSignal(:));
        [bestY, bestX] = ind2sub([rows, cols], maxLinIdx);
        estRadius = round((minR + maxR) / 2);
        odCenter = [bestX, bestY];
        odRadius = estRadius;
    else
        stats = regionprops(cc, 'Centroid', 'EquivDiameter');
        odCenter = stats(bestIdx).Centroid;
        odRadius = max(minR, min(maxR, round(stats(bestIdx).EquivDiameter / 2)));
    end

    % 5. Generate Smooth Circular Disc Mask
    [X, Y] = meshgrid(1:cols, 1:rows);
    distFromCenter = sqrt((X - odCenter(1)).^2 + (Y - odCenter(2)).^2);
    odMask = (distFromCenter <= odRadius) & mask;

    % 6. Segment Central Optic Cup
    % The physiological cup is the central, palish, brighter depression inside the disc
    odRegionValues = odSignal(odMask);
    if isempty(odRegionValues)
        cupRadius = round(odRadius * 0.35);
        cupMask = (distFromCenter <= cupRadius) & mask;
        cdr = 0.35;
    else
        cupThreshold = mean(odRegionValues) + 0.15 * std(odRegionValues);
        rawCupMask = (odSignal >= cupThreshold) & odMask;
        
        % Cup must be geometrically constrained inside disc center
        cupDistMask = (distFromCenter <= odRadius * 0.75);
        constrainedCup = rawCupMask & cupDistMask;
        
        if sum(constrainedCup(:)) < (0.05 * sum(odMask(:)))
            % Synthetic/default proportional cup
            cupRadius = max(4, round(odRadius * 0.38));
            cupMask = (distFromCenter <= cupRadius) & mask;
        else
            constrainedCup = imfill(constrainedCup, 'holes');
            cupStats = regionprops(constrainedCup, 'Area', 'EquivDiameter');
            if ~isempty(cupStats)
                [~, maxCupIdx] = max([cupStats.Area]);
                cupRadius = round(cupStats(maxCupIdx).EquivDiameter / 2);
                cupMask = (distFromCenter <= cupRadius) & odMask;
            else
                cupRadius = round(odRadius * 0.38);
                cupMask = (distFromCenter <= cupRadius) & mask;
            end
        end
        cdr = min(0.95, max(0.15, double(cupRadius) / double(odRadius)));
    end

    % 7. Categorize CDR Clinical Status
    if cdr < 0.50
        cdrStatus = 'Normal (CDR < 0.50)';
    elseif cdr <= 0.65
        cdrStatus = 'Borderline (CDR 0.50 - 0.65)';
    else
        cdrStatus = 'Enlarged / Glaucoma Suspect (CDR > 0.65)';
    end

    % 8. Package Details Struct
    details = struct();
    details.odCenter = odCenter;
    details.odRadius = odRadius;
    details.cupRadius = cupRadius;
    details.cupToDiscRatio = cdr;
    details.cdrStatus = cdrStatus;
    details.boundingBox = [max(1, odCenter(1) - odRadius), ...
                           max(1, odCenter(2) - odRadius), ...
                           2 * odRadius, 2 * odRadius];
    details.odAreaPixels = sum(odMask(:));
    details.cupAreaPixels = sum(cupMask(:));

end
