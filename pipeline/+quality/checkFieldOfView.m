function [passed, fovScore, details] = checkFieldOfView(img, cfg)
% CHECKFIELDOFVIEW Verifies retinal aperture geometry, area, and centering.
%
%   [PASSED, FOVSCORE, DETAILS] = QUALITY.CHECKFIELDOFVIEW(IMG) tests if
%   the retinal field of view (FOV) is complete, sufficiently circular,
%   and well-centered within the camera frame.
%
%   [PASSED, FOVSCORE, DETAILS] = QUALITY.CHECKFIELDOFVIEW(IMG, CFG) uses
%   custom thresholds in CFG.
%
%   Checks Performed:
%       1. Area Ratio: Verifies the retina occupies an appropriate percentage
%          of the camera sensor (rejects empty, tiny, or fully occluded views).
%       2. Circularity: Calculates isoperimetric quotient 4*pi*Area / (Perimeter^2)
%          to detect severe cropping, clipping by camera eyelids/margins.
%       3. Eccentricity: Measures how circular vs elongated the mask is.
%       4. Centroid Offset: Verifies the fundus is reasonably centered.
%
%   Inputs:
%       img     - Input fundus image (RGB or grayscale, uint8 or double).
%       cfg     - (Optional) Struct with field 'quality.fov'.
%
%   Outputs:
%       passed   - Logical (true if FOV is valid, false if cropped/occluded).
%       fovScore - Composite FOV quality score [0, 100].
%       details  - Struct with mask, areaRatio, circularity, eccentricity,
%                  centerOffset, and diagnostic messages.
%
%   Example:
%       [passed, score, details] = quality.checkFieldOfView(fundusImg);

    % Parse inputs and defaults
    if nargin < 2 || isempty(cfg)
        defaultCfg = config();
        cfgFov = defaultCfg.quality.fov;
    elseif isfield(cfg, 'quality') && isfield(cfg.quality, 'fov')
        cfgFov = cfg.quality.fov;
    else
        cfgFov = cfg;
    end

    % Normalize image to double [0, 1]
    if isinteger(img)
        imgD = im2double(img);
    else
        imgD = double(img);
        if max(imgD(:)) > 1.0
            imgD = imgD / 255.0;
        end
    end

    [H, W, ~] = size(imgD);
    totalArea = H * W;

    % Segment retinal mask
    mask = quality.getFundusMask(imgD);

    % Check if mask is empty
    if ~any(mask(:))
        passed = false;
        fovScore = 0.0;
        details = struct('mask', mask, 'passed', false, 'areaRatio', 0, ...
            'circularity', 0, 'eccentricity', 1, 'centerOffset', 1, ...
            'reason', 'No retinal field of view detected (image black/empty)');
        return;
    end

    % Extract morphological region properties
    props = regionprops(mask, 'Area', 'Perimeter', 'Centroid', 'Eccentricity', 'BoundingBox');

    % If multiple components, pick the largest
    if numel(props) > 1
        [~, maxIdx] = max([props.Area]);
        props = props(maxIdx);
    end

    maskArea = props.Area;
    perimeter = props.Perimeter;
    centroid = props.Centroid; % [X, Y]
    eccentricity = props.Eccentricity;

    % 1. Area ratio
    areaRatio = maskArea / totalArea;

    % 2. Circularity metric: 4 * pi * Area / Perimeter^2 (1.0 for a perfect circle)
    if perimeter > 0
        circularity = (4 * pi * maskArea) / (perimeter^2);
        circularity = min(1.0, circularity); % Cap at 1.0
    else
        circularity = 0;
    end

    % 3. Centroid offset relative to image center
    imgCenter = [W / 2, H / 2];
    distFromCenter = sqrt((centroid(1) - imgCenter(1))^2 + (centroid(2) - imgCenter(2))^2);
    normCenterOffset = distFromCenter / min(H, W);

    % Evaluate against thresholds
    isGoodArea = (areaRatio >= cfgFov.minAreaRatio) && (areaRatio <= cfgFov.maxAreaRatio);
    isGoodCircularity = (circularity >= cfgFov.minCircularity);
    isGoodEccentricity = (eccentricity <= cfgFov.maxEccentricity);
    isGoodCenter = (normCenterOffset <= cfgFov.maxCenterOffset);

    passed = isGoodArea && isGoodCircularity && isGoodEccentricity && isGoodCenter;

    % Composite score calculation [0, 100]
    areaScore = min(1.0, areaRatio / 0.50);
    circScore = circularity;
    centerScore = max(0.0, 1.0 - (normCenterOffset / 0.30));
    eccScore = 1.0 - eccentricity;
    fovScore = max(0.0, (0.35 * circScore + 0.25 * areaScore + 0.20 * centerScore + 0.20 * eccScore) * 100.0);

    % Build diagnostic details
    details = struct();
    details.mask = mask;
    details.areaRatio = areaRatio;
    details.circularity = circularity;
    details.eccentricity = eccentricity;
    details.centroid = centroid;
    details.centerOffset = normCenterOffset;
    details.isGoodArea = isGoodArea;
    details.isGoodCircularity = isGoodCircularity;
    details.isGoodEccentricity = isGoodEccentricity;
    details.isGoodCenter = isGoodCenter;
    details.passed = passed;
    details.fovScore = fovScore;

    % Assemble failure reasons
    reasons = {};
    if ~isGoodArea
        if areaRatio < cfgFov.minAreaRatio
            reasons{end+1} = sprintf('Retinal field of view too small/occluded (area ratio: %.2f < %.2f)', areaRatio, cfgFov.minAreaRatio);
        else
            reasons{end+1} = sprintf('Excessive field coverage/lack of border (area ratio: %.2f > %.2f)', areaRatio, cfgFov.maxAreaRatio);
        end
    end
    if ~isGoodCircularity
        reasons{end+1} = sprintf('Retina shape severely cropped or clipped (circularity: %.2f < %.2f)', circularity, cfgFov.minCircularity);
    end
    if ~isGoodEccentricity
        reasons{end+1} = sprintf('Retinal view elongated / distorted (eccentricity: %.2f > %.2f)', eccentricity, cfgFov.maxEccentricity);
    end
    if ~isGoodCenter
        reasons{end+1} = sprintf('Retina severely off-center (offset: %.2f > %.2f)', normCenterOffset, cfgFov.maxCenterOffset);
    end

    if isempty(reasons)
        details.reason = '';
        details.message = sprintf('Field of View acceptable (Area ratio: %.2f, Circularity: %.2f, Score: %.1f/100).', areaRatio, circularity, fovScore);
    else
        details.reason = strjoin(reasons, '; ');
        details.message = details.reason;
    end
end
