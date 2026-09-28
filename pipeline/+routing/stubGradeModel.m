function [grade, confidence, probabilities] = stubGradeModel(img, preset)
% STUBGRADEMODEL Lightweight Stage 4 stub classifier for DR severity grading.
%
%   [GRADE, CONFIDENCE, PROBABILITIES] = ROUTING.STUBGRADEMODEL(IMG) returns
%   a simulated ICDR severity grade (0 to 4), confidence score [0, 1], and
%   5-class softmax probability distribution based on heuristic image features.
%
%   [GRADE, CONFIDENCE, PROBABILITIES] = ROUTING.STUBGRADEMODEL(IMG, PRESET)
%   allows forcing specific clinical presets or simulated model states for
%   reproducible unit testing of the routing layer:
%       - 'normal'    : Grade 0 (No DR), confidence = 0.94
%       - 'mild'      : Grade 1 (Mild NPDR), confidence = 0.88
%       - 'moderate'  : Grade 2 (Moderate NPDR), confidence = 0.86
%       - 'severe'    : Grade 3 (Severe NPDR), confidence = 0.92
%       - 'pdr'       : Grade 4 (Proliferative DR), confidence = 0.95
%       - 'uncertain' : Grade 1, low confidence = 0.58 (borderline case)
%       - struct with fields .grade and .confidence
%
%   ICDR Grading Scale:
%       0: No Diabetic Retinopathy
%       1: Mild Non-Proliferative DR (Microaneurysms only)
%       2: Moderate Non-Proliferative DR (More than microaneurysms, < severe)
%       3: Severe Non-Proliferative DR (4-2-1 rule: 20+ hemorrhages per quad)
%       4: Proliferative DR (Neovascularization, vitreous hemorrhage)
%
%   Scope & Purpose:
%       This is a standalone stub for testing the routing and trust layer
%       prior to the integration of the deep learning Stage 4 CNN.
%
%   Author: DR Screening Pipeline MVP
%   Date: 2026-09-02

    % 1. Handle Explicit Test Presets
    if nargin >= 2 && ~isempty(preset)
        if isstruct(preset)
            grade = preset.grade;
            confidence = preset.confidence;
        elseif ischar(preset) || isstring(preset)
            switch lower(char(preset))
                case 'normal'
                    grade = 0; confidence = 0.94;
                case 'mild'
                    grade = 1; confidence = 0.88;
                case 'moderate'
                    grade = 2; confidence = 0.86;
                case 'severe'
                    grade = 3; confidence = 0.92;
                case 'pdr'
                    grade = 4; confidence = 0.95;
                case 'uncertain'
                    grade = 1; confidence = 0.58;
                case 'uncertain_severe'
                    grade = 3; confidence = 0.62;
                otherwise
                    grade = 0; confidence = 0.90;
            end
        else
            grade = 0; confidence = 0.90;
        end

        probabilities = generateProbabilities(grade, confidence);
        return;
    end

    % 2. Dynamic Heuristic Grading (for testing with actual image variations)
    if isempty(img)
        grade = 0; confidence = 0.50;
        probabilities = ones(1, 5) / 5;
        return;
    end

    % Normalize image
    if isinteger(img)
        imgD = im2double(img);
    else
        imgD = double(img);
        if max(imgD(:)) > 1.0, imgD = imgD / 255.0; end
    end

    if ndims(imgD) == 2
        imgD = cat(3, imgD, imgD, imgD);
    end

    mask = quality.getFundusMask(imgD);
    if ~any(mask(:)), mask = true(size(imgD, 1), size(imgD, 2)); end

    G = imgD(:, :, 2);
    retinalPixels = G(mask);
    
    % Measure sharpness via gradient variance (detects if image was perturbed/degraded)
    [Gx, Gy] = gradient(G);
    gradMag = sqrt(Gx.^2 + Gy.^2);
    sharpness = std(gradMag(mask)) * 100;

    % Measure dark lesion candidates (bottom-hat on green channel)
    se = strel('disk', 3);
    bhat = imbothat(G, se);
    darkCandidates = (bhat > 0.06) & mask;
    darkAreaRatio = sum(darkCandidates(:)) / max(1, sum(mask(:)));

    % Measure bright exudate candidates (top-hat on green channel)
    that = imtophat(G, se);
    brightCandidates = (that > 0.08) & mask;
    brightAreaRatio = sum(brightCandidates(:)) / max(1, sum(mask(:)));

    lesionLoad = darkAreaRatio * 1000 + brightAreaRatio * 800;

    % Determine grade based on lesion load
    if lesionLoad < 1.0
        grade = 0;
        confidence = 0.92;
    elseif lesionLoad < 3.5
        grade = 1;
        confidence = 0.85;
    elseif lesionLoad < 8.0
        grade = 2;
        confidence = 0.82;
    elseif lesionLoad < 15.0
        grade = 3;
        confidence = 0.88;
    else
        grade = 4;
        confidence = 0.93;
    end

    % If image sharpness is marginal / perturbed, confidence degrades
    if sharpness < 1.8
        % Sharpness drop causes uncertainty
        confidence = max(0.40, confidence - (2.0 - sharpness) * 0.35);
        if sharpness < 1.0
            grade = max(0, grade - 1); % Grade shift under heavy degradation
        end
    end

    probabilities = generateProbabilities(grade, confidence);

end

%% Local Helper: Softmax Distribution Generator
function probs = generateProbabilities(grade, confidence)
    probs = zeros(1, 5);
    targetIdx = grade + 1; % 1-indexed (0 -> 1, ..., 4 -> 5)
    
    probs(targetIdx) = confidence;
    remaining = max(0, 1.0 - confidence);
    
    % Spread remaining probability to neighboring classes
    otherIndices = setdiff(1:5, targetIdx);
    distWeights = 1 ./ abs(otherIndices - targetIdx);
    distWeights = distWeights / sum(distWeights);
    
    probs(otherIndices) = remaining * distWeights;
    probs = probs / sum(probs); % Ensure exact unit sum
end
