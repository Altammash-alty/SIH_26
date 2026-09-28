function mask = getFundusMask(img, threshold)
% GETFUNDUSMASK Robustly segments the circular retinal field-of-view (FOV) mask.
%
%   MASK = QUALITY.GETFUNDUSMASK(IMG) computes a logical binary mask (true for
%   foreground retinal tissue, false for black camera border) using default
%   intensity thresholding and morphological cleanup.
%
%   MASK = QUALITY.GETFUNDUSMASK(IMG, THRESHOLD) uses the specified normalized
%   intensity threshold [0, 1].
%
%   Inputs:
%       img       - Input image (RGB or grayscale, uint8, uint16, or double).
%       threshold - (Optional) Normalized scalar threshold. Default: 0.06.
%
%   Outputs:
%       mask      - Logical matrix (same height and width as IMG) where true
%                   indicates valid retinal area.
%
%   Example:
%       mask = quality.getFundusMask(fundusImg);
%       imshow(mask);

    if nargin < 2 || isempty(threshold)
        threshold = 0.06;
    end

    % Convert input to normalized double [0, 1]
    if isinteger(img)
        imgD = im2double(img);
    else
        imgD = double(img);
        if max(imgD(:)) > 1.0
            imgD = imgD / 255.0;
        end
    end

    % Use the channel with the best foreground-to-background contrast.
    % In fundus images, the Red channel or maximum channel has the highest
    % intensity across retinal tissue compared to the black background border.
    if ndims(imgD) == 3
        guideChan = max(imgD, [], 3);
    else
        guideChan = imgD;
    end

    % Initial binary thresholding
    rawMask = guideChan > threshold;

    % Fill holes (e.g., dark retinal vessels, optic cup, fovea)
    filledMask = imfill(rawMask, 'holes');

    % Morphological cleanup: smooth boundary and remove stray noise specks
    se = strel('disk', 5);
    cleanedMask = imclose(filledMask, se);
    cleanedMask = imopen(cleanedMask, se);

    % Keep only the largest connected component (the main retinal circle)
    cleanedMask = bwareafilt(cleanedMask, 1);

    % Final hole filling to ensure solid circular mask
    mask = imfill(cleanedMask, 'holes');

    % Fallback: If no mask could be segmented (e.g., all black), return false matrix
    if isempty(mask) || ~any(mask(:))
        mask = false(size(imgD, 1), size(imgD, 2));
    end
end
