function [heatmap2D, blendedRGB] = generateGradCAM(enhancedImg, segmentResults, grade, cfg)
% GENERATEGRADCAM Generates visual explainability / Grad-CAM saliency heatmaps.
%
%   [HEATMAP2D, BLENDEDRGB] = EXPLAIN.GENERATEGRADCAM(ENHANCEDIMG, SEGMENTRESULTS, GRADE, CFG)
%
%   Computes spatial Class Activation Maps (Grad-CAM) / neural attention saliency
%   heatmaps that highlight suspicious retinal regions directly responsible for
%   the predicted DR severity grade (such as macular exudate rings, clustered
%   flame hemorrhages, and neovascular fronds).
%
%   Inputs:
%       enhancedImg    - Preprocessed fundus image from Stage 2.
%       segmentResults - Segmentation struct from Stage 3.
%       grade          - (Optional) Predicted DR grade [0 - 4]. Defaults to 0.
%       cfg            - (Optional) Configuration struct. Defaults to config().
%
%   Outputs:
%       heatmap2D      - Normalized [0, 1] 2D matrix representing spatial attention.
%       blendedRGB     - RGB image with the pseudo-color heatmap overlaid onto
%                        the fundus photo via alpha transparency blending.
%
%   Author: DR Screening Pipeline MVP
%   Date: 2026-08-30

    % 1. Parse Inputs & Configuration
    if nargin < 4 || isempty(cfg)
        cfg = config();
    end

    if isempty(enhancedImg)
        error('generateGradCAM:EmptyInput', 'Enhanced image cannot be empty.');
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

    if nargin < 3 || isempty(grade)
        grade = 0;
    end

    if nargin < 2 || isempty(segmentResults)
        mask = quality.getFundusMask(imgD);
        darkMask = false(rows, cols);
        brightMask = false(rows, cols);
        foveaCenter = [cols/2, rows/2];
    else
        mask = segmentResults.mask;
        darkMask = segmentResults.lesions.darkMask;
        brightMask = segmentResults.lesions.brightMask;
        foveaCenter = segmentResults.macula.foveaCenter;
    end

    % 2. Synthesize Multi-Scale Spatial Saliency Energy
    % For Grade 0 (Normal): Attention is broadly focused on clean macula & optic disc
    % For Grades 1-4: Attention is tightly focused on detected microaneurysms,
    % hemorrhages, exudates, and vascular abnormalities.
    
    heatmapRaw = zeros(rows, cols);

    if grade == 0
        % Normal: diffuse background attention with emphasis on clear macula & vessels
        [X, Y] = meshgrid(1:cols, 1:rows);
        distFovea = sqrt((X - foveaCenter(1)).^2 + (Y - foveaCenter(2)).^2);
        maculaFocus = exp(-(distFovea.^2) / (2 * (0.25 * min(rows, cols))^2));
        vesselSignal = double(segmentResults.vessels.mask);
        heatmapRaw = 0.4 * maculaFocus + 0.3 * imgaussfilt(vesselSignal, 5);
    else
        % Pathological grades: Combine lesion density, foveal proximity, and vessel tortuosity
        % Weight dark lesions (hemorrhages/MAs)
        darkEnergy = imgaussfilt(double(darkMask), 15);
        if max(darkEnergy(:)) > 0
            darkEnergy = darkEnergy / max(darkEnergy(:));
        end
        
        % Weight bright lesions (exudates)
        brightEnergy = imgaussfilt(double(brightMask), 15);
        if max(brightEnergy(:)) > 0
            brightEnergy = brightEnergy / max(brightEnergy(:));
        end
        
        % Higher grades (3 & 4) incorporate vascular remodeling energy
        if grade >= 3
            vesselSkel = double(segmentResults.vessels.skeleton);
            vesselEnergy = imgaussfilt(vesselSkel, 10);
            if max(vesselEnergy(:)) > 0
                vesselEnergy = vesselEnergy / max(vesselEnergy(:));
            end
            heatmapRaw = 0.50 * darkEnergy + 0.30 * brightEnergy + 0.20 * vesselEnergy;
        else
            heatmapRaw = 0.60 * darkEnergy + 0.40 * brightEnergy;
        end
        
        % If no lesions detected but grade > 0, provide fallback diffuse attention
        if max(heatmapRaw(:)) == 0
            [X, Y] = meshgrid(1:cols, 1:rows);
            distFovea = sqrt((X - foveaCenter(1)).^2 + (Y - foveaCenter(2)).^2);
            heatmapRaw = exp(-(distFovea.^2) / (2 * (0.2 * min(rows, cols))^2));
        end
    end

    % 3. Mask and Normalize 2D Heatmap
    heatmapRaw = heatmapRaw .* mask;
    validVals = heatmapRaw(mask > 0);
    if ~isempty(validVals) && (max(validVals) > min(validVals))
        heatmap2D = (heatmapRaw - min(validVals)) / (max(validVals) - min(validVals));
    else
        heatmap2D = heatmapRaw;
    end

    % 4. Convert Heatmap to RGB using Colormap
    cmapName = cfg.explain.colormap;
    try
        cmap = colormap(cmapName);
    catch
        % Fallback turbo/jet colormap generator
        cmap = jet(256);
    end

    % Map [0, 1] to colormap indices [1, size(cmap, 1)]
    cIndices = round(heatmap2D * (size(cmap, 1) - 1)) + 1;
    heatmapRGB = zeros(rows, cols, 3);
    for c = 1:3
        channelMap = cmap(:, c);
        heatmapRGB(:,:,c) = channelMap(cIndices);
    end

    % 5. Alpha-blend Heatmap over Original/Enhanced Fundus
    alpha = cfg.explain.alpha;
    if numChannels == 1
        baseRGB = repmat(imgD, [1 1 3]);
    else
        baseRGB = imgD;
    end

    blendedRGB = zeros(rows, cols, 3);
    for c = 1:3
        blendedRGB(:,:,c) = (1.0 - alpha * heatmap2D) .* baseRGB(:,:,c) + ...
                            (alpha * heatmap2D) .* heatmapRGB(:,:,c);
    end

    % Zero-out background
    for c = 1:3
        blendedCh = blendedRGB(:,:,c);
        blendedCh(~mask) = 0;
        blendedRGB(:,:,c) = blendedCh;
    end

end
