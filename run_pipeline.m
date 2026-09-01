function [examData, isGood] = run_pipeline(imageInput, patientInfo, cfg, outputDir)
% RUN_PIPELINE Master End-to-End Autonomous Diabetic Retinopathy Screening Pipeline.
%
%   [EXAMDATA, ISGOOD] = RUN_PIPELINE(IMAGEINPUT, PATIENTINFO, CFG, OUTPUTDIR)
%
%   Executes the complete 5-stage autonomous screening pipeline:
%       Stage 1: Quality Gate (Blur, Illumination, Field of View Assessment)
%       Stage 2: Preprocessing (Vignetting Correction, Green-CLAHE, Denoising)
%       Stage 3: Retinal Segmentation (Optic Disc/Cup, Vessels, Macula, Lesions)
%       Stage 4: AI Severity Grading (ICDR Grades 0-4 + DME Risk Stratification)
%       Stage 5: Explainability & Clinical Reporting (Grad-CAM, 6-Panel Figure, HTML)
%
%   Inputs:
%       imageInput  - File path to fundus image (char/string) OR in-memory image matrix.
%       patientInfo - (Optional) Struct with patient metadata:
%                       .patientID     (e.g., 'PAT-2026-101')
%                       .patientAge    (e.g., 55)
%                       .patientGender ('M' or 'F')
%                       .eyeLaterality ('OD (Right Eye)' or 'OS (Left Eye)')
%       cfg         - (Optional) Configuration struct. Defaults to config().
%       outputDir   - (Optional) Directory to save generated reports. Defaults to ./reports.
%
%   Outputs:
%       examData    - Comprehensive struct containing all intermediate and final outputs:
%                       .qualityMetrics, .enhancedImage, .segmentResults,
%                       .grade, .gradeName, .confidence, .probabilities,
%                       .dmeRisk, .urgency, .icd10Code, .reportSummary.
%       isGood      - Boolean scalar. True if image passed Quality Gate and was graded;
%                     False if image failed Quality Gate and was rejected.
%
%   Example:
%       % Screen a fundus photograph file:
%       [result, passed] = run_pipeline('sample_fundus.jpg');
%       fprintf('Diagnosis: %s (Confidence: %.1f%%)\n', result.gradeName, result.confidence*100);
%
%   Author: DR Screening Pipeline MVP
%   Date: 2026-08-30

    % 1. Parse Inputs & Configuration
    if nargin < 3 || isempty(cfg)
        cfg = config();
    end

    if nargin < 4 || isempty(outputDir)
        outputDir = fullfile(pwd, 'reports');
    end

    if ~exist(outputDir, 'dir')
        mkdir(outputDir);
    end

    % Parse Patient Metadata
    if nargin < 2 || isempty(patientInfo)
        patientInfo = struct();
    end
    if ~isfield(patientInfo, 'patientID'),     patientInfo.patientID = 'PAT-2026-DEMO'; end
    if ~isfield(patientInfo, 'patientAge'),    patientInfo.patientAge = 56; end
    if ~isfield(patientInfo, 'patientGender'), patientInfo.patientGender = 'F'; end
    if ~isfield(patientInfo, 'eyeLaterality'), patientInfo.eyeLaterality = 'OD (Right Eye)'; end
    if ~isfield(patientInfo, 'examDate'),      patientInfo.examDate = char(datetime('now', 'Format', 'yyyy-MM-dd HH:mm')); end

    % Load Image if string / char path
    if ischar(imageInput) || isstring(imageInput)
        if ~exist(imageInput, 'file')
            error('run_pipeline:FileNotFound', 'Input image file not found: %s', imageInput);
        end
        rawImg = imread(char(imageInput));
    else
        rawImg = imageInput;
    end

    if isempty(rawImg)
        error('run_pipeline:EmptyInput', 'Input fundus image is empty.');
    end

    fprintf('==================================================================\n');
    fprintf('  RUNNING DIABETIC RETINOPATHY AUTONOMOUS SCREENING PIPELINE      \n');
    fprintf('==================================================================\n');
    fprintf('Patient ID: %s | Eye: %s | Age: %d\n\n', ...
        patientInfo.patientID, patientInfo.eyeLaterality, patientInfo.patientAge);

    examData = patientInfo;
    examData.rawImage = rawImg;

    % ---------------------------------------------------------------------
    % STAGE 1: QUALITY GATE
    % ---------------------------------------------------------------------
    fprintf('[STAGE 1] Evaluating fundus photo quality...\n');
    [isGood, qualityReason, qMetrics] = quality.assessQuality(rawImg, cfg);
    examData.isGood = isGood;
    examData.qualityReason = qualityReason;
    examData.qualityMetrics = qMetrics;

    if ~isGood
        fprintf('  [REJECTED] Quality Gate Failed: %s (Quality Score: %.1f/100)\n', ...
            qualityReason, qMetrics.overallScore);
        fprintf('  --> Clinical action: Prompt technician to retake fundus image.\n\n');
        return;
    else
        fprintf('  [PASSED] Quality Score: %.1f/100 (Blur: %.1f, Illum: %.1f, FOV: %.1f)\n\n', ...
            qMetrics.overallScore, qMetrics.blurScore, qMetrics.illumScore, qMetrics.fovScore);
    end

    % ---------------------------------------------------------------------
    % STAGE 2: PREPROCESSING & ENHANCEMENT
    % ---------------------------------------------------------------------
    fprintf('[STAGE 2] Applying multi-step preprocessing & CLAHE enhancement...\n');
    [enhancedImg, prepSteps] = preprocess.enhanceImage(rawImg, cfg);
    examData.enhancedImage = enhancedImg;
    examData.preprocessSteps = prepSteps;
    fprintf('  [COMPLETE] Illumination flattened, green-CLAHE enhanced, denoised.\n\n');

    % ---------------------------------------------------------------------
    % STAGE 3: RETINAL SEGMENTATION
    % ---------------------------------------------------------------------
    fprintf('[STAGE 3] Segmenting retinal landmarks and microvascular lesions...\n');
    [segResults, compositeRGB] = segment.segmentAll(enhancedImg, qMetrics.mask, cfg);
    examData.segmentResults = segResults;
    examData.compositeRGB = compositeRGB;
    fprintf('  [COMPLETE] Optic Disc CDR: %.2f | Vessel Density: %.1f%% | Dark Lesions: %d | Exudates: %d\n\n', ...
        segResults.opticDisc.cupToDiscRatio, segResults.vessels.density, ...
        segResults.lesions.darkCount, segResults.lesions.brightCount);

    % ---------------------------------------------------------------------
    % STAGE 4: DR SEVERITY GRADING & DME STRATIFICATION
    % ---------------------------------------------------------------------
    fprintf('[STAGE 4] Executing AI DR grading & risk stratification...\n');
    [grade, gradeName, confidence, probs, dmeRisk, urgency, icd10, classifyDetails] = ...
        classify.gradeDR(enhancedImg, segResults, cfg);

    examData.grade = grade;
    examData.gradeName = gradeName;
    examData.confidence = confidence;
    examData.probabilities = probs;
    examData.dmeRisk = dmeRisk;
    examData.urgency = urgency;
    examData.icd10Code = icd10;
    examData.classifyDetails = classifyDetails;
    examData.features = classifyDetails.features;

    fprintf('  [DIAGNOSIS] %s (Confidence: %.1f%%)\n', gradeName, confidence * 100.0);
    fprintf('  [ICD-10]    %s\n', icd10);
    fprintf('  [DME RISK]  %s\n', dmeRisk);
    fprintf('  [URGENCY]   %s\n\n', urgency);

    % ---------------------------------------------------------------------
    % STAGE 5: EXPLAINABILITY & DOCTOR REPORT
    % ---------------------------------------------------------------------
    fprintf('[STAGE 5] Generating Grad-CAM saliency heatmaps & clinical reports...\n');
    reportSummary = explain.generateDoctorReport(examData, cfg, outputDir);
    examData.reportSummary = reportSummary;

    fprintf('  [OUTPUT] Diagnostic Composite: %s\n', reportSummary.figurePath);
    fprintf('  [OUTPUT] Interactive HTML:     %s\n\n', reportSummary.htmlPath);
    fprintf('==================================================================\n');
    fprintf('               EXAMINATION COMPLETE (STATUS: OK)                  \n');
    fprintf('==================================================================\n\n');

end
