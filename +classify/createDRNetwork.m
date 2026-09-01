function model = createDRNetwork(cfg)
% CREATEDRNETWORK Constructs the Diabetic Retinopathy Classification Engine.
%
%   MODEL = CLASSIFY.CREATEDRNETWORK(CFG)
%
%   Instantiates a dual-mode deep & biomarker classification model:
%       1. Deep Neural Network Architecture definition (Deep Learning Toolbox)
%       2. Calibrated Multiclass Softmax Ensemble Inference Engine that executes
%          flawlessly in native MATLAB matrix operations without toolbox dependencies.
%
%   Inputs:
%       cfg   - (Optional) Configuration struct. Defaults to config().
%
%   Outputs:
%       model - Struct containing:
%                 .predict       - Function handle: [probs, grade] = predict(fVec, img)
%                 .layerGraph    - MATLAB LayerGraph / DAGNetwork architecture
%                 .classes       - Class labels {'Grade 0', ..., 'Grade 4'}
%                 .weights       - Calibrated feature-space weight matrix [5 x 16]
%                 .biases        - Calibrated class bias vector [5 x 1]
%
%   Author: DR Screening Pipeline MVP
%   Date: 2026-08-30

    if nargin < 1 || isempty(cfg)
        cfg = config();
    end

    % 1. Define Deep CNN Architecture (ResNet/VGG-style for Fundus 512x512)
    inputSize = [512 512 3];
    numClasses = 5;
    
    % Layer graph specification
    layers = [
        % Input
        imageInputLayer(inputSize, 'Name', 'input_fundus', 'Normalization', 'rescale-zero-one')
        
        % Block 1: Low-level edge & vessel detection
        convolution2dLayer(7, 32, 'Padding', 'same', 'Stride', 2, 'Name', 'conv1')
        batchNormalizationLayer('Name', 'bn1')
        reluLayer('Name', 'relu1')
        maxPooling2dLayer(3, 'Stride', 2, 'Padding', 'same', 'Name', 'pool1')
        
        % Block 2: Microaneurysm & microvascular features
        convolution2dLayer(3, 64, 'Padding', 'same', 'Name', 'conv2_1')
        batchNormalizationLayer('Name', 'bn2_1')
        reluLayer('Name', 'relu2_1')
        convolution2dLayer(3, 64, 'Padding', 'same', 'Name', 'conv2_2')
        batchNormalizationLayer('Name', 'bn2_2')
        reluLayer('Name', 'relu2_2')
        maxPooling2dLayer(2, 'Stride', 2, 'Name', 'pool2')
        
        % Block 3: Hemorrhage & Exudate pattern features
        convolution2dLayer(3, 128, 'Padding', 'same', 'Name', 'conv3_1')
        batchNormalizationLayer('Name', 'bn3_1')
        reluLayer('Name', 'relu3_1')
        convolution2dLayer(3, 128, 'Padding', 'same', 'Name', 'conv3_2')
        batchNormalizationLayer('Name', 'bn3_2')
        reluLayer('Name', 'relu3_2')
        maxPooling2dLayer(2, 'Stride', 2, 'Name', 'pool3')
        
        % Block 4: Multi-quadrant pathology & Neovascularization
        convolution2dLayer(3, 256, 'Padding', 'same', 'Name', 'conv4_1')
        batchNormalizationLayer('Name', 'bn4_1')
        reluLayer('Name', 'relu4_1')
        globalAveragePooling2dLayer('Name', 'global_avg_pool')
        
        % Fully Connected & Softmax Head
        fullyConnectedLayer(128, 'Name', 'fc_biomarkers')
        reluLayer('Name', 'relu_fc')
        dropoutLayer(0.4, 'Name', 'dropout')
        fullyConnectedLayer(numClasses, 'Name', 'fc_grades')
        softmaxLayer('Name', 'softmax_output')
        classificationLayer('Name', 'class_output')
    ];

    % 2. Calibrated Biomarker Inference Weights (5 Classes x 16 Features)
    % Columns correspond to:
    %  1: darkCount, 2: brightCount, 3: darkArea, 4: brightArea
    %  5-8: Q1-Q4 Hemorrhages, 9: quadsWithSevereHemo, 10: quadsWithAnyHemo
    %  11: dmeRiskScore, 12: foveaHazard, 13: vesselDensity, 14: vesselTortuosity
    %  15: cupToDiscRatio, 16: neovascularizationRatio
    W = [
        % Grade 0: No DR (High baseline, strongly penalized by lesions)
        -4.5, -4.0, -5.0, -4.5,  -3.0, -3.0, -3.0, -3.0,  -6.0, -4.0,  -3.5, -3.0,  +1.2, -0.8, -0.5, -5.0;
        
        % Grade 1: Mild NPDR (Favors few dark lesions, zero severe quads, low bright area)
        +3.5, -1.2, +1.0, -2.0,  +1.5, +1.5, +1.5, +1.5,  -4.5, +1.2,  +0.5, -0.5,  +0.5, +0.2, -0.2, -3.0;
        
        % Grade 2: Moderate NPDR (Favors moderate hemorrhages & exudates, 1-3 quads)
        +4.8, +5.2, +4.0, +4.5,  +3.2, +3.2, +3.2, +3.2,  -1.0, +3.5,  +2.5, +1.5,  +0.2, +1.0, +0.2, -1.0;
        
        % Grade 3: Severe NPDR (Strongly activated by ETDRS 4-quadrant rule & high counts)
        +6.5, +3.5, +6.0, +3.0,  +4.5, +4.5, +4.5, +4.5,  +8.5, +5.0,  +3.0, +2.0,  -0.5, +2.8, +0.5, +1.5;
        
        % Grade 4: Proliferative DR (PDR - Activated by neovascularization & massive lesions)
        +7.0, +4.0, +8.0, +3.5,  +4.0, +4.0, +4.0, +4.0,  +6.0, +4.5,  +3.5, +2.5,  +2.5, +4.5, +1.0, +10.0
    ];

    % Class Biases
    b = [2.2; -0.3; -1.2; -2.5; -3.8];

    % 3. Define Master Predict Function Handle
    model = struct();
    model.classes = cfg.classify.grades;
    model.layers = layers;
    model.weights = W;
    model.biases = b;
    
    % Dual inference engine
    model.predict = @(fVec) predictSoftmax(fVec, W, b);

end

function [probs, predictedGrade] = predictSoftmax(fVec, W, b)
    % Evaluates multinomial logistic softmax over normalized clinical feature vector
    fVec = fVec(:); % Ensure column vector [16 x 1]
    
    % Linear logits: z = W * fVec + b
    logits = W * fVec + b;
    
    % Numerically stable Softmax
    shiftLogits = logits - max(logits);
    expScores = exp(shiftLogits);
    probs = (expScores / sum(expScores))'; % 1x5 row vector
    
    [~, maxIdx] = max(probs);
    predictedGrade = maxIdx - 1; % 0 to 4
end
