%% TEST_MULTI_FACTOR_CALIBRATION
clear; clc;
cfg = config();

[trainTbl, ~] = data.loadIDRiDGrading('train', fullfile('data', 'idrid', 'grading'));

g0Samples = find(trainTbl.DRGrade == 0, 5, 'first');
g2Samples = find(trainTbl.DRGrade == 2, 5, 'first');
g3Samples = find(trainTbl.DRGrade == 3, 5, 'first');

testIdxs = [g0Samples; g2Samples; g3Samples];

for dSens = [3.0, 3.5, 4.0, 4.5]
    for bSens = [3.0, 3.5, 4.0, 4.5]
        cfg.segment.lesion.darkSensitivity = dSens;
        cfg.segment.lesion.brightSensitivity = bSens;
        
        g0DarkTotal = 0; g0BrightTotal = 0;
        g2DarkTotal = 0; g2BrightTotal = 0;
        g3DarkTotal = 0; g3BrightTotal = 0;
        
        for idx = g0Samples'
            raw = imresize(imread(trainTbl.ImagePath{idx}), 768 / max(size(imread(trainTbl.ImagePath{idx}),1), size(imread(trainTbl.ImagePath{idx}),2)));
            [enh, ~] = preprocess.enhanceImage(raw, cfg);
            mask = quality.getFundusMask(enh);
            [odM, odC, odR, ~, ~, ~] = segment.segmentOpticDisc(enh, mask, cfg);
            [vM, ~, ~, ~, ~] = segment.segmentVessels(enh, mask, cfg);
            [fC, ~, ~, ~] = segment.segmentMacula(enh, odC, odR, mask, cfg);
            [~, ~, dC, bC, ~] = segment.segmentLesions(enh, vM, odM, fC, mask, cfg);
            g0DarkTotal = g0DarkTotal + dC;
            g0BrightTotal = g0BrightTotal + bC;
        end
        
        for idx = g2Samples'
            raw = imresize(imread(trainTbl.ImagePath{idx}), 768 / max(size(imread(trainTbl.ImagePath{idx}),1), size(imread(trainTbl.ImagePath{idx}),2)));
            [enh, ~] = preprocess.enhanceImage(raw, cfg);
            mask = quality.getFundusMask(enh);
            [odM, odC, odR, ~, ~, ~] = segment.segmentOpticDisc(enh, mask, cfg);
            [vM, ~, ~, ~, ~] = segment.segmentVessels(enh, mask, cfg);
            [fC, ~, ~, ~] = segment.segmentMacula(enh, odC, odR, mask, cfg);
            [~, ~, dC, bC, ~] = segment.segmentLesions(enh, vM, odM, fC, mask, cfg);
            g2DarkTotal = g2DarkTotal + dC;
            g2BrightTotal = g2BrightTotal + bC;
        end
        
        for idx = g3Samples'
            raw = imresize(imread(trainTbl.ImagePath{idx}), 768 / max(size(imread(trainTbl.ImagePath{idx}),1), size(imread(trainTbl.ImagePath{idx}),2)));
            [enh, ~] = preprocess.enhanceImage(raw, cfg);
            mask = quality.getFundusMask(enh);
            [odM, odC, odR, ~, ~, ~] = segment.segmentOpticDisc(enh, mask, cfg);
            [vM, ~, ~, ~, ~] = segment.segmentVessels(enh, mask, cfg);
            [fC, ~, ~, ~] = segment.segmentMacula(enh, odC, odR, mask, cfg);
            [~, ~, dC, bC, ~] = segment.segmentLesions(enh, vM, odM, fC, mask, cfg);
            g3DarkTotal = g3DarkTotal + dC;
            g3BrightTotal = g3BrightTotal + bC;
        end
        
        fprintf('dSens=%.1f bSens=%.1f | G0: d=%.1f b=%.1f | G2: d=%.1f b=%.1f | G3: d=%.1f b=%.1f\n', ...
            dSens, bSens, g0DarkTotal/5, g0BrightTotal/5, g2DarkTotal/5, g2BrightTotal/5, g3DarkTotal/5, g3BrightTotal/5);
    end
end
