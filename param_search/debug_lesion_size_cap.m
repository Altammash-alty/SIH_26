%% DEBUG_LESION_SIZE_CAP Diagnostic harness for Part 1: Investigating lesion size distribution
clear; clc;
cfg = config();
cfg.debug = true;

[trainTbl, ~] = data.loadIDRiDGrading('train', fullfile('data', 'idrid', 'grading'));

% Pick diverse samples: a Grade 0 (no DR), a Grade 2 (moderate), a Grade 3 (severe), a Grade 4 (proliferative)
sampleIdxs = [
    find(trainTbl.DRGrade == 0, 2, 'first');
    find(trainTbl.DRGrade == 2, 2, 'first');
    find(trainTbl.DRGrade == 3, 2, 'first');
    find(trainTbl.DRGrade == 4, 2, 'first')
];

fprintf('========================================================================================\n');
fprintf('PART 1: LESION SIZE-CAP & FILTER DIAGNOSTIC ON REAL IDRID IMAGES (768px Working Res)\n');
fprintf('Current caps: darkMaxSize = %d, brightMaxSize = %d\n', cfg.segment.lesion.darkMaxSize, cfg.segment.lesion.brightMaxSize);
fprintf('========================================================================================\n\n');

for k = 1:numel(sampleIdxs)
    idx = sampleIdxs(k);
    imgName = trainTbl.ImageName{idx};
    gtGrade = trainTbl.DRGrade(idx);
    imgPath = trainTbl.ImagePath{idx};
    
    raw = imread(imgPath);
    % Standardize to 768px working resolution
    img768 = imresize(raw, 768 / max(size(raw,1), size(raw,2)));
    
    [enhanced, ~] = preprocess.enhanceImage(img768, cfg);
    mask = quality.getFundusMask(enhanced);
    
    % Get anatomical masks
    [odMask, odCenter, odRadius, ~, ~, ~] = segment.segmentOpticDisc(enhanced, mask, cfg);
    [vesselMask, ~, ~, ~, ~] = segment.segmentVessels(enhanced, mask, cfg);
    [foveaCenter, ~, ~, ~] = segment.segmentMacula(enhanced, odCenter, odRadius, mask, cfg);
    
    % Step-by-step diagnostic of segmentLesions internals
    imgD = im2double(enhanced);
    greenCh = imgD(:,:,2);
    redCh   = imgD(:,:,1);
    blueCh  = imgD(:,:,3);
    [rows, cols, ~] = size(imgD);
    erodedMask = imerode(mask, strel('disk', max(8, round(min(rows, cols) * 0.02))));
    
    % 1. Dark lesions
    seDark = strel('disk', 12);
    bothatGreen = imbothat(greenCh, seDark) .* erodedMask;
    dilatedVessels = imdilate(vesselMask, strel('disk', 1));
    nonVesselMask = erodedMask & ~dilatedVessels & ~odMask;
    rawDarkCand = (bothatGreen > cfg.segment.lesion.darkSensitivity) & nonVesselMask;
    cleanDark = bwareaopen(rawDarkCand, cfg.segment.lesion.darkMinSize);
    darkCC = bwconncomp(cleanDark);
    
    darkAreas = [];
    rejectedDarkByCap = 0;
    rejectedDarkByEcc = 0;
    if darkCC.NumObjects > 0
        statsD = regionprops(darkCC, 'Area', 'Eccentricity');
        darkAreas = [statsD.Area];
        for i = 1:numel(statsD)
            if statsD(i).Area > cfg.segment.lesion.darkMaxSize
                rejectedDarkByCap = rejectedDarkByCap + 1;
            elseif statsD(i).Eccentricity >= 0.96
                rejectedDarkByEcc = rejectedDarkByEcc + 1;
            end
        end
    end
    
    % 2. Bright lesions
    dilatedOD = imdilate(odMask, strel('disk', max(8, round(min(rows, cols) * 0.02))));
    nonODMask = erodedMask & ~dilatedOD;
    seBright = strel('disk', 10);
    tophatGreen = imtophat(greenCh, seBright);
    tophatRed   = imtophat(redCh, seBright);
    brightSignal = (0.6 * tophatGreen + 0.4 * tophatRed) .* nonODMask;
    rawBrightCand = (brightSignal > cfg.segment.lesion.brightSensitivity) & nonODMask;
    cleanBright = bwareaopen(rawBrightCand, cfg.segment.lesion.brightMinSize);
    brightCC = bwconncomp(cleanBright);
    
    brightAreas = [];
    rejectedBrightByCap = 0;
    if brightCC.NumObjects > 0
        statsB = regionprops(brightCC, 'Area');
        brightAreas = [statsB.Area];
        for j = 1:numel(statsB)
            if statsB(j).Area > cfg.segment.lesion.brightMaxSize
                rejectedBrightByCap = rejectedBrightByCap + 1;
            end
        end
    end
    
    fprintf('Image: %-12s | Actual Grade: %d\n', imgName, gtGrade);
    fprintf('  DARK:   rawCand=%d px, afterMinSize=%d px, totalBlobs=%d\n', ...
        nnz(rawDarkCand), nnz(cleanDark), darkCC.NumObjects);
    if ~isempty(darkAreas)
        fprintf('          Max blob area=%d px, blobs > darkMaxSize(%d) rejected=%d, blobs rejected by Ecc=%d\n', ...
            max(darkAreas), cfg.segment.lesion.darkMaxSize, rejectedDarkByCap, rejectedDarkByEcc);
    end
    fprintf('  BRIGHT: rawCand=%d px, afterMinSize=%d px, totalBlobs=%d\n', ...
        nnz(rawBrightCand), nnz(cleanBright), brightCC.NumObjects);
    if ~isempty(brightAreas)
        fprintf('          Max blob area=%d px, blobs > brightMaxSize(%d) rejected=%d\n', ...
            max(brightAreas), cfg.segment.lesion.brightMaxSize, rejectedBrightByCap);
    end
    fprintf('\n');
end
