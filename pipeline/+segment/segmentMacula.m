function [foveaCenter, foveaRadius, maculaHazardMask, details] = segmentMacula(img, odCenter, odRadius, mask, cfg)
% SEGMENTMACULA Localizes the Macula and Fovea Centralis hazard zones.
%
%   [FOVEACENTER, FOVEARADIUS, MACULAHAZARDMASK, DETAILS] = ...
%       SEGMENT.SEGMENTMACULA(IMG, ODCENTER, ODRADIUS, MASK, CFG)
%
%   Localizes the anatomical fovea centralis and establishes the clinically
%   critical 1-disc-diameter and 500 µm macular danger zones. Exudates or
%   microaneurysms within these zones define Clinically Significant Macular
%   Edema (CSME), the leading cause of moderate visual loss in diabetes.
%
%   Inputs:
%       img        - Preprocessed or enhanced RGB/grayscale fundus photograph.
%       odCenter   - [X, Y] center coordinate of the Optic Disc (from segmentOpticDisc).
%       odRadius   - Estimated radius of the Optic Disc in pixels.
%       mask       - (Optional) Foreground circular fundus mask.
%       cfg        - (Optional) Configuration struct. Defaults to config().
%
%   Outputs:
%       foveaCenter      - [X, Y] pixel coordinates of the estimated Fovea Centralis.
%       foveaRadius      - Estimated radius of the central foveal avascular zone (FAZ).
%       maculaHazardMask - Binary mask representing the 1-disc-diameter hazard zone.
%       details          - Struct containing anatomical offsets, distance to OD,
%                          and macular boundary coordinates.
%
%   Anatomical Reference:
%       In human retinal anatomy, the fovea is located approximately 2.5 optic
%       disc diameters temporal to the center of the optic disc, slightly inferior
%       (1-2 degrees downward). It represents the region of lowest reflectance
%       due to xanthophyll macular pigment and avascularity.
%
%   Author: DR Screening Pipeline MVP
%   Date: 2026-08-30

    % 1. Parse Inputs & Configuration
    if nargin < 5 || isempty(cfg)
        cfg = config();
    end

    if isempty(img)
        error('segmentMacula:EmptyInput', 'Input image cannot be empty.');
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

    if nargin < 4 || isempty(mask)
        mask = quality.getFundusMask(imgD);
    end

    if nargin < 2 || isempty(odCenter)
        % Fallback default: assume OD is at one-third width, center height
        odCenter = [cols * 0.35, rows * 0.50];
        odRadius = round(min(rows, cols) * 0.08);
    end

    % 2. Determine Temporal Direction (Left Eye OS vs Right Eye OD)
    % If OD is on the left side of the image center, the fovea is to the right (+X, temporal)
    % If OD is on the right side of the image center, the fovea is to the left (-X, temporal)
    imageCenterX = cols / 2.0;
    if odCenter(1) < imageCenterX
        temporalDirection = 1;  % Fovea is rightward (+X)
        eyeLaterality = 'OD (Right Eye)';
    else
        temporalDirection = -1; % Fovea is leftward (-X)
        eyeLaterality = 'OS (Left Eye)';
    end

    % 3. Search Region Estimation based on Disc Diameter (DD)
    discDiameter = 2.0 * odRadius;
    expectedDistance = cfg.segment.macula.odDistanceDiscDiameters * discDiameter;
    
    % Nominal geometric position: ~2.5 DD temporal, slight inferior tilt (5-10% of DD downward)
    nominalFoveaX = odCenter(1) + (temporalDirection * expectedDistance);
    nominalFoveaY = odCenter(2) + (0.15 * discDiameter);

    % Clamp search region inside image boundaries
    nominalFoveaX = max(odRadius, min(cols - odRadius, nominalFoveaX));
    nominalFoveaY = max(odRadius, min(rows - odRadius, nominalFoveaY));

    % 4. Intensity Search within Macular Candidate ROI
    % The fovea is the darkest circular region in the green/luminance channel
    if numChannels == 3
        searchChannel = imgD(:,:,2); % Green channel
    else
        searchChannel = imgD;
    end

    % Define search window around nominal location (radius = 0.8 * discDiameter)
    searchRadius = round(0.8 * discDiameter);
    [X, Y] = meshgrid(1:cols, 1:rows);
    searchROI = (sqrt((X - nominalFoveaX).^2 + (Y - nominalFoveaY).^2) <= searchRadius) & mask;

    % Gaussian smooth search channel to ignore dark capillary pixels
    smoothedChannel = imgaussfilt(searchChannel, max(2, round(odRadius * 0.2)));
    smoothedChannel(~searchROI) = Inf; % Exclude outside ROI

    [minVal, minLinIdx] = min(smoothedChannel(:));

    if ~isinf(minVal)
        [foveaY, foveaX] = ind2sub([rows, cols], minLinIdx);
        foveaCenter = [foveaX, foveaY];
    else
        foveaCenter = [nominalFoveaX, nominalFoveaY];
    end

    % 5. Construct Foveal & Macular Hazard Zones
    foveaRadius = round(discDiameter * cfg.segment.macula.foveaRadiusDiscRatio);
    hazardRadius = round(discDiameter * cfg.segment.macula.maculaHazardRadiusRatio);

    distFromFovea = sqrt((X - foveaCenter(1)).^2 + (Y - foveaCenter(2)).^2);
    
    foveaMask = (distFromFovea <= foveaRadius) & mask;
    maculaHazardMask = (distFromFovea <= hazardRadius) & mask;

    % 6. Package Details Struct
    actualDistancePixels = sqrt((foveaCenter(1) - odCenter(1))^2 + (foveaCenter(2) - odCenter(2))^2);
    details = struct();
    details.foveaCenter = foveaCenter;
    details.foveaRadius = foveaRadius;
    details.maculaHazardRadius = hazardRadius;
    details.distanceToDiscPixels = actualDistancePixels;
    details.distanceInDiscDiameters = actualDistancePixels / discDiameter;
    details.eyeLaterality = eyeLaterality;
    details.foveaMask = foveaMask;
    details.maculaHazardMask = maculaHazardMask;

end
