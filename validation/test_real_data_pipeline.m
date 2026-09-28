%% test_real_data_pipeline.m
% REAL DATA PIPELINE VALIDATION SCRIPT
%
% Runs the actual Stage 1 (Quality Gate) and Stage 2 (Preprocessing) 
% over real IDRiD training images, measures empirical retake rate and
% per-image latency, then feeds those measured values into the clinic
% throughput simulation so every number is traceable to real execution.
%
% Output:
%   - Console report of Stage 1 results on real images
%   - results/stage1_quality_report.csv (per-image breakdown)
%   - Measured values passed into simulateClinicThroughput for honest sim
%
% Author: DR Screening Pipeline MVP
% Date:   2026-09-02

clear; clc;
addpath(genpath('.'));

fprintf('====================================================================\n');
fprintf('   REAL DATA PIPELINE VALIDATION — Stage 1 + 2 on IDRiD Data       \n');
fprintf('====================================================================\n\n');

cfg = config();

%% -----------------------------------------------------------------------
% 1. Load IDRiD Training Set (using real data loader)
% -----------------------------------------------------------------------
fprintf('[STEP 1] Loading IDRiD Training Set via +data.loadIDRiDGrading...\n');
try
    [trainTbl, ~] = data.loadIDRiDGrading('train');
catch ME
    fprintf('[ERROR] Could not load IDRiD training set.\n');
    fprintf('  Message: %s\n', ME.message);
    fprintf('  Ensure you have run: python organize_datasets.py --copy\n');
    return;
end
N = height(trainTbl);
fprintf('  -> %d training images loaded.\n\n', N);

%% -----------------------------------------------------------------------
% 2. Run Stage 1 Quality Gate over all training images
% -----------------------------------------------------------------------
fprintf('[STEP 2] Running Stage 1 Quality Gate over %d images...\n', N);

passCount     = 0;
failCount     = 0;
borderCount   = 0;
totalQualTime = 0;

resultsDir = 'results';
if ~exist(resultsDir, 'dir'), mkdir(resultsDir); end
csvPath = fullfile(resultsDir, 'stage1_quality_report.csv');

fcsv = fopen(csvPath, 'w');
fprintf(fcsv, 'ImageName,DRGrade,QualityDecision,SharpnessScore,IlluminationMean,FovRatio,LatencyMs\n');

qualDecisions = cell(N, 1);

for i = 1:N
    imgPath = trainTbl.ImagePath{i};
    imgName = trainTbl.ImageName{i};
    drGrade = trainTbl.DRGrade(i);

    rawImg = imread(imgPath);

    % Resize to working resolution (768px long-edge) before quality checks.
    % Thresholds in config.m are calibrated at this scale. Full-res IDRiD
    % images (~4288x2848) cause incorrect morphological kernel proportions.
    rawImg = imresize(rawImg, 768 / max(size(rawImg,1), size(rawImg,2)));

    t0 = tic;
    [isGood, ~, qMetrics] = quality.assessQuality(rawImg, cfg);
    elapsed = toc(t0);
    totalQualTime = totalQualTime + elapsed;

    % Derive string decision from logical isGood
    if isGood
        decision = 'PASS';
        passCount = passCount + 1;
    else
        decision = 'RETAKE';
        failCount = failCount + 1;
    end
    qualDecisions{i} = decision;

    % Extract actual field names from assessQuality metrics struct
    sharpness = qMetrics.blurScore;
    illumMean = qMetrics.illumScore;
    fovRatio  = qMetrics.fovScore;
    latMs     = elapsed * 1000;

    fprintf(fcsv, '%s,%d,%s,%.4f,%.4f,%.4f,%.2f\n', ...
        imgName, drGrade, decision, sharpness, illumMean, fovRatio, latMs);

    if mod(i, 50) == 0 || i == N
        fprintf('  -> Evaluated %3d / %3d images (%.0f ms last)\n', i, N, latMs);
    end
end

fclose(fcsv);

%% -----------------------------------------------------------------------
% 3. Compute Measured Retake Rate & Latency
% -----------------------------------------------------------------------
retakeCount = failCount;
measuredRetakeRate = retakeCount / N;
measuredQualityLatencyMs = (totalQualTime / N) * 1000;

fprintf('\n');
fprintf('====================================================================\n');
fprintf('           STAGE 1 QUALITY GATE: MEASURED RESULTS (N=%d)            \n', N);
fprintf('====================================================================\n');
fprintf('  PASS        : %d images  (%.1f%%)\n', passCount, passCount/N*100);
fprintf('  RETAKE      : %d images  (%.1f%%) -- MEASURED retake rate\n', retakeCount, measuredRetakeRate*100);
fprintf('  BORDERLINE  : %d images  (%.1f%%)\n', borderCount, borderCount/N*100);
fprintf('  Avg Latency : %.2f ms per image\n', measuredQualityLatencyMs);
fprintf('====================================================================\n\n');
fprintf('[REPORT] Per-image Stage 1 breakdown saved to: %s\n\n', csvPath);

%% -----------------------------------------------------------------------
% 4. Grade-Stratified Quality Analysis  
% -----------------------------------------------------------------------
fprintf('[STEP 3] Grade-stratified quality analysis...\n');
fprintf('  Grade | Total | PASS  | RETAKE | Retake%%\n');
fprintf('  ------|-------|-------|--------|--------\n');
for g = 0:4
    mask = trainTbl.DRGrade == g;
    total_g = sum(mask);
    fail_g  = sum(mask & strcmp(qualDecisions, 'RETAKE'));
    if total_g > 0
        fprintf('    %d   |  %3d  |  %3d  |   %3d  | %5.1f%%\n', ...
            g, total_g, total_g - fail_g, fail_g, fail_g/total_g*100);
    end
end
fprintf('\n');

%% -----------------------------------------------------------------------
% 5. Run Stage 2 Preprocessing Latency Benchmark (Sample of 20 PASS images)
% -----------------------------------------------------------------------
fprintf('[STEP 4] Benchmarking Stage 2 Preprocessing latency on up to 20 sample images...\n');
passMask = strcmp(qualDecisions, 'PASS');
passIndices = find(passMask);
nSample = min(20, numel(passIndices));

if nSample == 0
    fprintf('  [WARNING] No images passed Stage 1 -- using first 20 images for Stage 2 latency benchmark.\n');
    sampleIdx = (1:min(20,N))'';
    nSample = numel(sampleIdx);
else
    sampleIdx = passIndices(1:nSample);
end

preprocTimes = zeros(nSample, 1);
for j = 1:nSample
    rawImg = imread(trainTbl.ImagePath{sampleIdx(j)});
    rawImg = imresize(rawImg, 768 / max(size(rawImg,1), size(rawImg,2)));
    t0 = tic;
    preprocess.enhanceImage(rawImg, cfg);
    preprocTimes(j) = toc(t0) * 1000;
end

measuredPreprocMs = mean(preprocTimes);
totalAILatencyMs  = measuredQualityLatencyMs + measuredPreprocMs;

fprintf('  -> Stage 2 avg latency : %.2f ms/image (over %d samples)\n', measuredPreprocMs, nSample);
fprintf('  -> Stages 1+2 combined : %.2f ms/image\n', totalAILatencyMs);

%% -----------------------------------------------------------------------
% 6. Run Clinic Throughput Simulation with MEASURED Parameters
% -----------------------------------------------------------------------
fprintf('\n[STEP 5] Running clinic simulation with MEASURED retake rate & latency...\n\n');

% Override config with empirically measured values
cfgMeasured = cfg;
cfgMeasured.sim.retakeProbability = measuredRetakeRate;
cfgMeasured.sim.aiProcessingTimeSeconds = totalAILatencyMs / 1000;  % convert ms to seconds

simResults = simulate.simulateClinicThroughput(120, cfgMeasured);

fprintf('\n====================================================================\n');
fprintf('   CLINIC SIMULATION RESULTS (MEASURED PARAMETERS)                  \n');
fprintf('====================================================================\n');
fprintf('  MEASURED retake rate (from %d real images) : %.1f%%\n', N, measuredRetakeRate * 100);
fprintf('  MEASURED AI latency (Stages 1+2, sample)   : %.2f ms/image\n', totalAILatencyMs);
fprintf('  SIMULATED (unvalidated model) throughput    : %.2fx vs manual\n', simResults.throughputMultiplier);
fprintf('  SIMULATED (unvalidated model) doctor time   : %.1f%% reduction\n', simResults.doctorTimeSavedPercent);
fprintf('  SIMULATED (unvalidated model) cost savings  : $%.2f / patient\n', ...
    cfg.sim.costManualScreeningUSD - cfg.sim.costAiAssistedScreeningUSD);
fprintf('====================================================================\n\n');
fprintf('[NOTE] Throughput, cost and workload figures are SIMULATED based on assumed\n');
fprintf('       doctor review times. NOT validated on a real clinic workflow.\n');
fprintf('       Only retake rate (%.1f%%) and latency (%.2f ms) are real measurements.\n\n', ...
    measuredRetakeRate * 100, totalAILatencyMs);

%% -----------------------------------------------------------------------
% 7. Save Measured Parameters for Use by Other Scripts
% -----------------------------------------------------------------------
measuredParams = struct();
measuredParams.retakeRate = measuredRetakeRate;
measuredParams.qualityLatencyMs = measuredQualityLatencyMs;
measuredParams.preprocLatencyMs = measuredPreprocMs;
measuredParams.combinedLatencyMs = totalAILatencyMs;
measuredParams.nImages = N;
measuredParams.measuredAt = char(datetime('now', 'Format', 'yyyy-MM-dd HH:mm:ss'));
measuredParams.simulationResults = simResults;

save(fullfile(resultsDir, 'measured_params.mat'), 'measuredParams');
fprintf('[SAVED] Measured parameters saved to: results/measured_params.mat\n');
fprintf('[DONE]  Use these values to wire into simulateClinicThroughput for\n');
fprintf('        honest reporting. Discrepancies from config defaults are expected.\n\n');
