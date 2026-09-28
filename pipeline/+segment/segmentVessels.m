function [vesselMask, vesselSkeleton, vesselDensity, tortuosityIndex, details] = segmentVessels(img, mask, cfg)
% SEGMENTVESSELS Segments the retinal vascular network and computes vascular biomarkers.
%
%   [VESSELMASK, VESSELSKELETON, VESSELDENSITY, TORTUOSITYINDEX, DETAILS] = ...
%       SEGMENT.SEGMENTVESSELS(IMG, MASK, CFG)
%
%   Extracts the complete retinal vascular tree (arterioles, venules, and
%   capillaries) using multi-scale 2D matched filtering and adaptive
%   morphological thresholding. Computes critical microvascular biomarkers:
%   vessel area density, vascular tortuosity, and branching points.
%
%   Inputs:
%       img             - Preprocessed or enhanced fundus image (RGB or grayscale).
%       mask            - (Optional) Foreground circular fundus mask.
%       cfg             - (Optional) Configuration struct. Defaults to config().
%
%   Outputs:
%       vesselMask      - Logical 2D binary matrix representing segmented blood vessels.
%       vesselSkeleton  - 1-pixel wide vascular centerline tree (logical 2D matrix).
%       vesselDensity   - Vessel area fraction relative to total fundus area (%).
%       tortuosityIndex - Mean arc-chord tortuosity ratio across vessel branches.
%       details         - Struct containing intermediate vessel response maps,
%                         branching points count, and morphological statistics.
%
%   Author: DR Screening Pipeline MVP
%   Date: 2026-08-30

    % 1. Parse Inputs & Configuration
    if nargin < 3 || isempty(cfg)
        cfg = config();
    end

    if isempty(img)
        error('segmentVessels:EmptyInput', 'Input image cannot be empty.');
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

    if nargin < 2 || isempty(mask)
        mask = quality.getFundusMask(imgD);
    end

    % Erode mask slightly to eliminate strong boundary artifacts
    borderErosion = strel('disk', max(5, round(min(rows, cols) * 0.015)));
    erodedMask = imerode(mask, borderErosion);

    % 2. Extract Vessel Contrast Channel
    % In fundus photography, the Green channel exhibits optimal vessel-to-background contrast
    if numChannels == 3
        greenChannel = imgD(:,:,2);
    else
        greenChannel = imgD;
    end

    % Invert green channel: vessels (dark) become bright ridges
    invGreen = (1.0 - greenChannel) .* erodedMask;

    % 3. Multi-scale Matched Directional Filtering
    % Retinal vessels are piecewise linear tubular structures of varying widths.
    % We construct 2D Gaussian matched filters across 12 discrete angles (0 to 165 deg).
    thetas = 0:15:165;
    scales = cfg.segment.vessel.scales;
    combinedResponse = zeros(rows, cols);

    for s = 1:numel(scales)
        sigma = scales(s);
        L = round(9 * sigma);
        if mod(L, 2) == 0, L = L + 1; end
        halfL = (L - 1) / 2;
        [x, y] = meshgrid(-halfL:halfL, -halfL:halfL);
        
        scaleMaxResponse = zeros(rows, cols);
        
        for thetaDeg = thetas
            theta = deg2rad(thetaDeg);
            % Rotated coordinate system
            u =  x * cos(theta) + y * sin(theta);
            v = -x * sin(theta) + y * cos(theta);
            
            % Gaussian matched kernel along transverse direction u
            % -exp(-u^2 / (2*sigma^2)) with zero mean
            kernel = -exp(-(u.^2) / (2 * (sigma^2)));
            kernel(abs(v) > (2 * sigma)) = 0; % Truncate lengthwise
            kernel = kernel - mean(kernel(:));
            normFactor = sum(abs(kernel(:)));
            if normFactor > 0
                kernel = kernel / normFactor;
            end
            
            % Apply 2D convolution
            filtered = imfilter(invGreen, kernel, 'replicate', 'conv');
            scaleMaxResponse = max(scaleMaxResponse, filtered);
        end
        
        combinedResponse = max(combinedResponse, scaleMaxResponse);
    end

    % 4. Morphological Top-Hat Enhancement for Fine Capillaries
    tophatRadius = cfg.segment.vessel.tophatRadius;
    seTophat = strel('disk', tophatRadius);
    tophatEnhance = imtophat(invGreen, seTophat);

    % Fuse matched filter response with top-hat response
    fusedVesselMap = (0.65 * combinedResponse) + (0.35 * tophatEnhance);
    fusedVesselMap = fusedVesselMap .* erodedMask;

    % Normalize response map inside mask to [0, 1]
    validResp = fusedVesselMap(erodedMask > 0);
    if ~isempty(validResp) && (max(validResp) > min(validResp))
        normMap = (fusedVesselMap - min(validResp)) / (max(validResp) - min(validResp));
    else
        normMap = fusedVesselMap;
    end

    % 5. Adaptive Thresholding & Binary Morphological Refinement
    sensitivity = cfg.segment.vessel.adaptThreshSensitivity;
    adaptThresh = adaptthresh(normMap, sensitivity, 'NeighborhoodSize', 2*floor(size(normMap)/16)+1);
    rawVessels = (normMap > adaptThresh) & erodedMask;

    % Remove small isolated noisy specks and fill small holes
    minArea = cfg.segment.vessel.minAreaPixels;
    cleanVessels = bwareaopen(rawVessels, minArea);
    cleanVessels = imclose(cleanVessels, strel('disk', cfg.segment.vessel.closingRadius));
    vesselMask = cleanVessels & erodedMask;

    % 6. Vascular Skeletonization & Branching Analysis
    vesselSkeleton = bwskel(vesselMask);

    % Detect branching / bifurcation points using morphological hit-or-miss / convolution
    % A pixel on the skeleton with >= 3 neighbors is a bifurcation or crossover point
    branchKernel = [1 1 1; 1 0 1; 1 1 1];
    neighborCount = imfilter(double(vesselSkeleton), branchKernel, 'replicate');
    branchPoints = (neighborCount >= 3) & vesselSkeleton;
    branchingPointsCount = sum(branchPoints(:));

    % 7. Vascular Biomarker Metrics Calculation
    % Vessel Density (% of retinal foreground area)
    totalFundusArea = sum(erodedMask(:));
    if totalFundusArea > 0
        vesselDensity = (sum(vesselMask(:)) / totalFundusArea) * 100.0;
    else
        vesselDensity = 0.0;
    end

    % Vessel Tortuosity Index (Arc-Chord ratio)
    % Evaluated across continuous skeleton segments between branching points
    segmentSkeleton = vesselSkeleton & ~branchPoints;
    segCC = bwconncomp(segmentSkeleton);
    
    tortuosityRatios = [];
    for k = 1:segCC.NumObjects
        segIdx = segCC.PixelIdxList{k};
        if numel(segIdx) >= 15 % Only consider meaningful vessel arcs
            [py, px] = ind2sub([rows, cols], segIdx);
            arcLength = numel(segIdx);
            % Chord length: distance between the two furthest points in this segment
            dx = max(px) - min(px);
            dy = max(py) - min(py);
            chordLength = sqrt(dx^2 + dy^2);
            if chordLength > 3
                tortuosityRatios(end+1) = arcLength / chordLength;
            end
        end
    end

    if isempty(tortuosityRatios)
        tortuosityIndex = 1.05; % Default baseline (nearly straight vessels)
    else
        tortuosityIndex = mean(tortuosityRatios);
    end

    % 8. Package Details Struct
    details = struct();
    details.vesselDensityPercent = vesselDensity;
    details.tortuosityIndex = tortuosityIndex;
    details.branchingPointsCount = branchingPointsCount;
    details.totalVesselPixels = sum(vesselMask(:));
    details.skeletonPixels = sum(vesselSkeleton(:));
    details.fusedVesselResponse = normMap;
    details.branchPointsMask = branchPoints;

end
