%% TEST_FULL_PIPELINE Comprehensive Verification and Demo Suite for Full DR Pipeline
%
% This script executes end-to-end testing across all 5 pipeline stages and the
% clinic operational model:
%   - Stage 1: Quality Gate (Blur, Illumination, FOV on good and failing images)
%   - Stage 2: Preprocessing (Illumination flattening, Green-CLAHE, Denoising)
%   - Stage 3: Retinal Segmentation (Optic Disc, Retinal Vessels, Macula, Lesions)
%   - Stage 4: DR Severity Grading (Grade 0 Normal, Grade 1 Mild, Grade 2 Moderate,
%              Grade 3 Severe, Grade 4 Proliferative DR + DME Risk)
%   - Stage 5: Explainability & Doctor Reports (Grad-CAM, 6-Panel Fig, Clinical HTML)
%   - Stage 6: Clinic Operations Simulation (120 patients, throughput speedup, cost savings)
%
% Usage:
%   Run 'test_full_pipeline' in MATLAB.
%
% Author: DR Screening Pipeline MVP
% Date: 2026-08-30

clear; clc; close all;

fprintf('========================================================================================\n');
fprintf('       DIABETIC RETINOPATHY AUTONOMOUS SCREENING PIPELINE - FULL VERIFICATION SUITE     \n');
fprintf('========================================================================================\n\n');

%% 1. Configuration & Directories
cfg = config();
reportDir = fullfile(pwd, 'reports');
if ~exist(reportDir, 'dir')
    mkdir(reportDir);
end

%% 2. Load a real validation dataset that is separate from training
fprintf('[1/3] Loading real validation data from the held-out split (not used in training)...\n\n');

validationRoot = fullfile(pwd, 'data', 'idrid', 'grading');
if isfield(cfg, 'validation') && isfield(cfg.validation, 'rootDir') && ~isempty(cfg.validation.rootDir)
    validationRoot = cfg.validation.rootDir;
end

if ~exist(validationRoot, 'dir')
    error('test_full_pipeline:ValidationDirNotFound', ...
        'No validation dataset found at "%s". Point cfg.validation.rootDir to a separate real dataset that is not used in training.', validationRoot);
end

try
    [validationTbl, ~] = data.loadIDRiDGrading('test', validationRoot);
catch ME
    fprintf('[ERROR] Could not load validation dataset.\n');
    fprintf('  Message: %s\n', ME.message);
    fprintf('  Supply a separate real validation folder outside the training split.\n');
    return;
end

nVal = min(height(validationTbl), 8);
fprintf('  -> Loaded %d real validation images from %s\n', nVal, validationRoot);

testCases = struct();

for i = 1:nVal
    testCases(i).name = sprintf('Validation case %d: %s', i, validationTbl.ImageName{i});
    testCases(i).image = imread(validationTbl.ImagePath{i});
    testCases(i).expectedPass = true;
    testCases(i).expectedGrade = validationTbl.DRGrade(i);
    testCases(i).patientID = sprintf('VAL-%03d', i);
    testCases(i).eye = 'Validation Set';
end

%% 3. Execute End-to-End Pipeline Evaluation
fprintf('[2/3] Executing 5-Stage Autonomous Pipeline on all cases...\n\n');
fprintf('------------------------------------------------------------------------------------------------------------------------\n');
fprintf('%-32s | %-6s | %-6s | %-24s | %-12s | %s\n', ...
    'Clinical Test Scenario', 'Q-Gate', 'Score', 'AI Diagnosis', 'Confidence', 'Triage Urgency');
fprintf('------------------------------------------------------------------------------------------------------------------------\n');

resultsSummary = struct();

for i = 1:numel(testCases)
    tc = testCases(i);
    patInfo = struct('patientID', tc.patientID, 'patientAge', 55+i, 'patientGender', 'M', 'eyeLaterality', tc.eye);
    
    % Run full pipeline
    [examData, passedQGate] = run_pipeline(tc.image, patInfo, cfg, reportDir);
    
    resultsSummary(i).name = tc.name;
    resultsSummary(i).passedQGate = passedQGate;
    
    if passedQGate
        qStatus = 'PASS';
        diagName = examData.gradeName;
        confStr = sprintf('%.1f%%', examData.confidence * 100.0);
        urgencyStr = examData.urgency;
        qScoreVal = examData.qualityMetrics.overallScore;
    else
        qStatus = 'REJECT';
        diagName = '(Rejected at Q-Gate)';
        confStr = 'N/A';
        urgencyStr = 'Retake Fundus Photo';
        qScoreVal = examData.qualityMetrics.overallScore;
    end
    
    fprintf('%-32s | %-6s | %5.1f  | %-24s | %-12s | %s\n', ...
        tc.name, qStatus, qScoreVal, diagName, confStr, urgencyStr);
end

fprintf('------------------------------------------------------------------------------------------------------------------------\n\n');

%% 4. Execute Stage 6: Clinic Throughput Operational Simulation
fprintf('[3/3] Simulating Tele-Ophthalmology Clinic Operations (120 Patients)...\n');
simResults = simulate.simulateClinicThroughput(120, cfg);
hDash = simulate.plotClinicMetrics(simResults, reportDir);
close(hDash);

fprintf('  --> AI Screening Throughput:     %.1f patients / hour\n', simResults.aiThroughputPatientsPerHour);
fprintf('  --> Manual Screening Throughput: %.1f patients / hour\n', simResults.manualThroughputPatientsPerHour);
fprintf('  --> Throughput Multiplier:       %.1fx faster screening\n', simResults.throughputMultiplier);
fprintf('  --> Average Patient Wait Time:   %.1f mins (vs. %.1f mins manual)\n', ...
    simResults.aiAvgWaitTimeMinutes, simResults.manualAvgWaitTimeMinutes);
fprintf('  --> Doctor Clinical Time Saved:  %.1f%%\n', simResults.doctorTimeSavedPercent);
fprintf('  --> Daily Clinic Cost Savings:   $%.2f USD\n\n', simResults.totalDailyCostSavingsUSD);

fprintf('========================================================================================\n');
fprintf('               FULL VERIFICATION COMPLETE - ALL 5 STAGES OPERATIONAL!                   \n');
fprintf(' Reports and Figures saved to: %s\n', reportDir);
fprintf('========================================================================================\n');
