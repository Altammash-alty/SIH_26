%% TEST_ADAPTIVE_SWEEP Diagnostic script testing segmentLesions with adaptive thresholding
clear; clc;
cfg = config();
cfg.debug = true;

[trainTbl, ~] = data.loadIDRiDGrading('train', fullfile('data', 'idrid', 'grading'));

% Pick a Grade 0, Grade 2, and Grade 3 image
testSamples = [
    find(trainTbl.DRGrade == 0, 1, 'first');
    find(trainTbl.DRGrade == 2, 1, 'first');
    find(trainTbl.DRGrade == 3, 1, 'first')
];

for k = 1:numel(testSamples)
    idx = testSamples(k);
    imgName = trainTbl.ImageName{idx};
    gtGrade = trainTbl.DRGrade(idx);
    imgPath = trainTbl.ImagePath{idx};
    
    raw = imread(imgPath);
    img768 = imresize(raw, 768 / max(size(raw,1), size(raw,2)));
    [enhanced, ~] = preprocess.enhanceImage(img768, cfg);
    mask = quality.getFundusMask(enhanced);
    
    [odMask, odCenter, odRadius, ~, ~, ~] = segment.segmentOpticDisc(enhanced, mask, cfg);
    [vesselMask, ~, ~, ~, ~] = segment.segmentVessels(enhanced, mask, cfg);
    [foveaCenter, ~, ~, ~] = segment.segmentMacula(enhanced, odCenter, odRadius, mask, cfg);
    
    fprintf('--- TESTING IMAGE: %s (Actual Grade: %d) ---\n', imgName, gtGrade);
    
    % Test multiple values of darkSensitivity and brightSensitivity: 2.0, 2.5, 3.0
    for sens = [1.5, 2.0, 2.5, 3.0]
        cfg.segment.lesion.darkSensitivity = sens;
        cfg.segment.lesion.brightSensitivity = sens;
        [~, ~, dCount, bCount, ~] = segment.segmentLesions(enhanced, vesselMask, odMask, foveaCenter, mask, cfg);
        fprintf('  Sens = %.1f -> Dark Lesions: %3d | Bright Lesions: %3d\n', sens, dCount, bCount);
    end
    fprintf('\n');
end
