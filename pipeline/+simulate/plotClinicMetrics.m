function hFig = plotClinicMetrics(simResults, outputDir)
% PLOTCLINICMETRICS Visualizes tele-ophthalmology clinic operational metrics.
%
%   HFIG = SIMULATE.PLOTCLINICMETRICS(SIMRESULTS, OUTPUTDIR)
%
%   Generates a 4-panel executive operations dashboard comparing AI-assisted
%   screening vs. traditional manual clinical workflows:
%       1. Screening Throughput (Patients / Hour)
%       2. Patient Total Clinic Waiting Time Distribution
%       3. Physician Clinical Workload & Time Savings
%       4. Screening Triage & Quality Gate Retake Breakdown
%
%   Inputs:
%       simResults - Struct returned by simulate.simulateClinicThroughput.
%       outputDir  - (Optional) Directory to save the generated figure.
%
%   Outputs:
%       hFig       - Figure handle to the generated dashboard.
%
%   Author: DR Screening Pipeline MVP
%   Date: 2026-08-30

    if nargin < 1 || isempty(simResults)
        simResults = simulate.simulateClinicThroughput();
    end

    if nargin < 2 || isempty(outputDir)
        outputDir = fullfile(pwd, 'reports');
    end

    if ~exist(outputDir, 'dir')
        mkdir(outputDir);
    end

    hFig = figure('Name', 'Clinic Operational Simulation Dashboard', ...
                  'Color', [0.10 0.12 0.16], ...
                  'Position', [80 80 1100 700], ...
                  'Visible', 'off');

    % 1. Panel 1: Throughput Comparison (Bar Chart)
    subplot(2, 2, 1);
    barVals = [simResults.manualThroughputPatientsPerHour, simResults.aiThroughputPatientsPerHour];
    b1 = bar(1:2, barVals, 0.55);
    b1.FaceColor = 'flat';
    b1.CData(1, :) = [0.85 0.35 0.35]; % Manual Red
    b1.CData(2, :) = [0.20 0.75 0.50]; % AI Green
    set(gca, 'XTick', 1:2, 'XTickLabel', {'Manual Screening', 'AI Pipeline'}, ...
             'Color', [0.15 0.18 0.24], 'XColor', 'w', 'YColor', 'w');
    ylabel('Patients Screened / Hour', 'Color', 'w', 'FontWeight', 'bold');
    title(sprintf('Screening Throughput (%.1fx Speedup)', simResults.throughputMultiplier), ...
        'Color', 'w', 'FontSize', 11, 'FontWeight', 'bold');
    grid on; set(gca, 'GridColor', [0.25 0.30 0.40]);

    % 2. Panel 2: Waiting Time Comparison (Bar Chart)
    subplot(2, 2, 2);
    waitVals = [simResults.manualAvgWaitTimeMinutes, simResults.aiAvgWaitTimeMinutes];
    b2 = bar(1:2, waitVals, 0.55);
    b2.FaceColor = 'flat';
    b2.CData(1, :) = [0.95 0.55 0.20];
    b2.CData(2, :) = [0.25 0.65 0.95];
    set(gca, 'XTick', 1:2, 'XTickLabel', {'Manual Screening', 'AI Pipeline'}, ...
             'Color', [0.15 0.18 0.24], 'XColor', 'w', 'YColor', 'w');
    ylabel('Mean Patient Wait Time (mins)', 'Color', 'w', 'FontWeight', 'bold');
    title(sprintf('Average Clinic Wait Time (-%.0f%%)', ...
        ((simResults.manualAvgWaitTimeMinutes - simResults.aiAvgWaitTimeMinutes)/simResults.manualAvgWaitTimeMinutes)*100), ...
        'Color', 'w', 'FontSize', 11, 'FontWeight', 'bold');
    grid on; set(gca, 'GridColor', [0.25 0.30 0.40]);

    % 3. Panel 3: Physician Workload & Time Savings
    subplot(2, 2, 3);
    docHours = [simResults.manualTotalDoctorHours, simResults.aiTotalDoctorHours];
    b3 = bar(1:2, docHours, 0.55);
    b3.FaceColor = 'flat';
    b3.CData(1, :) = [0.75 0.30 0.85];
    b3.CData(2, :) = [0.15 0.80 0.85];
    set(gca, 'XTick', 1:2, 'XTickLabel', {'Manual Screening', 'AI Pipeline'}, ...
             'Color', [0.15 0.18 0.24], 'XColor', 'w', 'YColor', 'w');
    ylabel('Total Physician Hours Required', 'Color', 'w', 'FontWeight', 'bold');
    title(sprintf('Doctor Time Saved: %.1f%% ($%.0f Daily Savings)', ...
        simResults.doctorTimeSavedPercent, simResults.totalDailyCostSavingsUSD), ...
        'Color', 'y', 'FontSize', 11, 'FontWeight', 'bold');
    grid on; set(gca, 'GridColor', [0.25 0.30 0.40]);

    % 4. Panel 4: Population Triage & Quality Retake Breakdown
    subplot(2, 2, 4);
    gradeCounts = histcounts(simResults.aiGrades, -0.5:1:4.5);
    p = pie(gradeCounts, {'Grade 0 (Normal)', 'Grade 1 (Mild)', 'Grade 2 (Mod)', 'Grade 3 (Severe)', 'Grade 4 (PDR)'});
    title(sprintf('Patient Triage Cohort (Retake Rate: %.1f%%)', simResults.retakeRatePercent), ...
        'Color', 'w', 'FontSize', 11, 'FontWeight', 'bold');

    % Save Dashboard Figure
    dashPath = fullfile(outputDir, 'clinic_operational_dashboard.png');
    saveas(hFig, dashPath);

end
