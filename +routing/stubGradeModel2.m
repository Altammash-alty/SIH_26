function [grade, confidence, probabilities] = stubGradeModel2(img, preset)
% STUBGRADEMODEL2 Secondary Stage 4 stub classifier for multi-model ensemble validation.
%
%   [GRADE, CONFIDENCE, PROBABILITIES] = ROUTING.STUBGRADEMODEL2(IMG) simulates
%   a secondary independent CNN architecture (e.g. Vision Transformer vs ResNet)
%   for testing automated second opinion and disagreement detection.
%
%   [GRADE, CONFIDENCE, PROBABILITIES] = ROUTING.STUBGRADEMODEL2(IMG, PRESET)
%   allows explicit overrides:
%       - 'agree'     : Returns identical/compatible grade to Model 1
%       - 'disagree'  : Returns a diverging grade (e.g. Grade 3 when Model 1 is Grade 1)
%       - struct with .grade and .confidence
%
%   Scope & Purpose:
%       Enables deterministic testing of the MODEL_DISAGREEMENT routing pathway.
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
                case 'agree'
                    % Default agreement with normal case
                    grade = 0; confidence = 0.91;
                case 'disagree'
                    % Distinct severity level to trigger disagreement
                    grade = 3; confidence = 0.84;
                case 'disagree_mild'
                    grade = 2; confidence = 0.79;
                case 'severe'
                    grade = 3; confidence = 0.89;
                case 'pdr'
                    grade = 4; confidence = 0.92;
                otherwise
                    grade = 0; confidence = 0.88;
            end
        else
            grade = 0; confidence = 0.88;
        end

        probabilities = generateProbabilities(grade, confidence);
        return;
    end

    % 2. Baseline Model 2 Prediction (Slightly different sensitivity curve)
    [m1Grade, m1Conf] = routing.stubGradeModel(img);

    % Secondary model has slightly higher sensitivity to vascular changes
    grade = m1Grade;
    confidence = max(0.40, m1Conf - 0.04);
    probabilities = generateProbabilities(grade, confidence);

end

%% Local Helper: Softmax Distribution Generator
function probs = generateProbabilities(grade, confidence)
    probs = zeros(1, 5);
    targetIdx = grade + 1;
    probs(targetIdx) = confidence;
    remaining = max(0, 1.0 - confidence);
    
    otherIndices = setdiff(1:5, targetIdx);
    distWeights = 1 ./ abs(otherIndices - targetIdx);
    distWeights = distWeights / sum(distWeights);
    
    probs(otherIndices) = remaining * distWeights;
    probs = probs / sum(probs);
end
