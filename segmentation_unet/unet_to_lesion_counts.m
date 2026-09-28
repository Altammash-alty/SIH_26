function lesions = unet_to_lesion_counts(predMask, fundusMask, foveaCenter, cfg)
% UNET_TO_LESION_COUNTS Converts U-Net categorical/integer segmentation mask
% into discrete clinical lesion counts matching segmentLesions.m output format.
%
% Drops directly into gradeDR.m and extractFeatures.m without downstream changes.
%
% Inputs:
%   predMask    - 2D label map (uint8 or categorical) from semanticseg()
%                 Class Mapping:
%                   0: Background
%                   1: Microaneurysms (MA) -> Dark Lesions
%                   2: Hemorrhages (HE)    -> Dark Lesions
%                   3: Hard Exudates (EX)  -> Bright Lesions
%                   4: Soft Exudates (SE)  -> Bright Lesions
%   fundusMask  - (Optional) Logical binary fundus aperture mask
%   foveaCenter - (Optional) [X, Y] coordinates of foveal center for quadrants
%   cfg         - (Optional) Configuration struct. Defaults to config().
%
% Output:
%   lesions     - Struct matching segmentLesions.m output:
%                   .darkMask
%                   .brightMask
%                   .darkCount
%                   .brightCount
%                   .darkAreaTotalPixels
%                   .brightAreaTotalPixels
%                   .quadrantDarkCount     [ST, SN, IT, IN]
%                   .quadrantBrightCount   [ST, SN, IT, IN]
%                   .minDistToFoveaPixels
%                   .darkStats
%                   .brightStats
%
% Author: DR Screening Pipeline MVP - U-Net Integration
% Date: 2026-09-29

    if nargin < 4 || isempty(cfg)
        cfg = config();
    end

    % 1. Convert categorical to numeric matrix if needed
    if iscategorical(predMask)
        catNames = categories(predMask);
        numMask = zeros(size(predMask), 'uint8');
        for i = 1:numel(catNames)
            cName = lower(catNames{i});
            if contains(cName, 'ma') || contains(cName, 'micro')
                numMask(predMask == catNames{i}) = 1;
            elseif contains(cName, 'he') || contains(cName, 'haem') || contains(cName, 'hem')
                numMask(predMask == catNames{i}) = 2;
            elseif contains(cName, 'ex') || contains(cName, 'hard')
                numMask(predMask == catNames{i}) = 3;
            elseif contains(cName, 'se') || contains(cName, 'soft') || contains(cName, 'cotton')
                numMask(predMask == catNames{i}) = 4;
            end
        end
        predMask = numMask;
    else
        predMask = uint8(predMask);
    end

    % Constrain to valid fundus mask if provided
    if nargin >= 2 && ~isempty(fundusMask)
        predMask(~fundusMask) = 0;
    end

    [H, W] = size(predMask);
    if nargin < 3 || isempty(foveaCenter)
        foveaCenter = [round(W / 2), round(H / 2)];
    end

    % 2. Group into Dark and Bright Lesions
    % Dark lesions = Microaneurysms (1) + Hemorrhages (2)
    darkMask = (predMask == 1) | (predMask == 2);
    % Bright lesions = Hard Exudates (3) + Soft Exudates (4)
    brightMask = (predMask == 3) | (predMask == 4);

    % Optional minimum cluster size filter (removes isolated 1-2 pixel network noise)
    minClusterSize = 3;
    darkMask   = bwareaopen(darkMask, minClusterSize);
    brightMask = bwareaopen(brightMask, minClusterSize);

    % 3. Connected Component Analysis (matching segmentLesions.m)
    darkCC   = bwconncomp(darkMask, 8);
    brightCC = bwconncomp(brightMask, 8);

    darkStatsList   = regionprops(darkCC, 'Area', 'Centroid', 'BoundingBox');
    brightStatsList = regionprops(brightCC, 'Area', 'Centroid', 'BoundingBox');

    darkCount   = darkCC.NumObjects;
    brightCount = brightCC.NumObjects;

    % 4. Quantify 4-Quadrant Distribution (ETDRS Standard)
    % Quadrants: [ST, SN, IT, IN]
    quadrantDarkCount   = zeros(1, 4);
    quadrantBrightCount = zeros(1, 4);
    minDistToFovea      = Inf;

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

    % 5. Package Details Struct (Drop-in replacement for segmentResults.lesions)
    lesions = struct();
    lesions.darkMask             = darkMask;
    lesions.brightMask           = brightMask;
    lesions.darkCount            = darkCount;
    lesions.brightCount          = brightCount;
    lesions.darkAreaTotalPixels  = sum(darkMask(:));
    lesions.brightAreaTotalPixels = sum(brightMask(:));
    lesions.quadrantDarkCount    = quadrantDarkCount;     % [ST, SN, IT, IN]
    lesions.quadrantBrightCount  = quadrantBrightCount;   % [ST, SN, IT, IN]
    lesions.minDistToFoveaPixels = minDistToFovea;
    lesions.darkStats            = darkStatsList;
    lesions.brightStats          = brightStatsList;

end

function qIdx = getQuadrantIndex(pt, center)
    % Maps point to ETDRS quadrant: 1:ST, 2:SN, 3:IT, 4:IN
    dx = pt(1) - center(1);
    dy = pt(2) - center(2);
    
    if dy <= 0 % Superior
        if dx <= 0
            qIdx = 1; % ST
        else
            qIdx = 2; % SN
        end
    else % Inferior
        if dx <= 0
            qIdx = 3; % IT
        else
            qIdx = 4; % IN
        end
    end
end
