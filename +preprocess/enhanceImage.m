function [enhancedImg, intermediate] = enhanceImage(img, cfg)
% ENHANCEIMAGE Master pipeline for Stage 2 Retinal Image Preprocessing.
%
%   ENHANCEDIMG = PREPROCESS.ENHANCEIMAGE(IMG) runs the complete 3-stage
%   enhancement pipeline on an input fundus image:
%       Step 1: Illumination Normalization (vignetting & flash correction)
%       Step 2: Green-Channel CLAHE (vessel & lesion contrast enhancement)
%       Step 3: Edge-Preserving Denoising (sensor/compression noise removal)
%
%   [ENHANCEDIMG, INTERMEDIATE] = PREPROCESS.ENHANCEIMAGE(IMG, CFG) uses
%   custom configuration parameters in CFG (see config.m) and returns a
%   struct of intermediate images for visualization and auditing.
%
%   Inputs:
%       img          - Input fundus photograph (RGB or grayscale, uint8,
%                      uint16, or double).
%       cfg          - (Optional) Struct containing preprocessing settings.
%                      Defaults to config().
%
%   Outputs:
%       enhancedImg  - Fully preprocessed and enhanced fundus image ready
%                      for segmentation (Stage 3) and CNN grading (Stage 4).
%       intermediate - Struct containing all intermediate transformation steps:
%                        .original               - Input image
%                        .illuminationNormalized - After vignetting correction
%                        .claheEnhanced          - After Green-channel CLAHE
%                        .finalEnhanced          - Final denoised output
%
%   Example:
%       [enhanced, steps] = preprocess.enhanceImage(rawFundusImg);
%       figure;
%       subplot(1,2,1); imshow(steps.original); title('Original');
%       subplot(1,2,2); imshow(enhanced);       title('Enhanced');

    % 1. Load configuration
    if nargin < 2 || isempty(cfg)
        cfg = config();
    end

    % 2. Validate input
    if isempty(img)
        error('enhanceImage:EmptyInput', 'Input image cannot be empty.');
    end

    % Store original
    intermediate = struct();
    intermediate.original = img;

    % 3. Step 1: Illumination Normalization
    % Flattens uneven lighting, shadows, and camera flash gradients
    normImg = preprocess.normalizeIllumination(img, cfg);
    intermediate.illuminationNormalized = normImg;

    % 4. Step 2: CLAHE on Green Channel
    % Enhances microvascular structures, hemorrhages, and optic cup edges
    claheImg = preprocess.claheGreenChannel(normImg, cfg);
    intermediate.claheEnhanced = claheImg;

    % 5. Step 3: Denoising
    % Suppresses high-frequency sensor noise without blurring fine capillaries
    enhancedImg = preprocess.denoiseImage(claheImg, cfg);
    intermediate.finalEnhanced = enhancedImg;

end
