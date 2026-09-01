function results = simulateClinicThroughput(numPatients, cfg)
% SIMULATECLINICTHROUGHPUT Discrete-event Monte Carlo simulation of tele-ophthalmology clinic.
%
%   RESULTS = SIMULATE.SIMULATECLINICTHROUGHPUT(NUMPATIENTS, CFG)
%
%   Models and evaluates the operational efficiency of an AI-assisted Diabetic
%   Retinopathy screening clinic against a traditional manual ophthalmologist
%   screening workflow.
%
%   Simulation Stages:
%       1. Patient Arrivals (Poisson inter-arrival times)
%       2. Technician Camera Acquisition
%       3. Stage 1 Quality Gate Check & Retake Loop (rejection handling)
%       4. Stages 2-4 AI Preprocessing, Segmentation & Severity Grading
%       5. AI-Assisted Triage Routing (Normal fast-track vs High-Risk urgent queue)
%       6. Doctor Review & Sign-off
%
%   Inputs:
%       numPatients - (Optional) Number of patients to simulate. Defaults to 120.
%       cfg         - (Optional) Configuration struct. Defaults to config().
%
%   Outputs:
%       results     - Struct containing operational metrics:
%                       .totalPatientsSimulated
%                       .aiThroughputPatientsPerHour
%                       .manualThroughputPatientsPerHour
%                       .throughputMultiplier (e.g. 4.2x speedup)
%                       .aiAvgWaitTimeMinutes
%                       .manualAvgWaitTimeMinutes
%                       .doctorTimeSavedPercent
%                       .totalDailyCostSavingsUSD
%                       .patientLog (table of individual patient timestamps & stages)
%
%   Author: DR Screening Pipeline MVP
%   Date: 2026-08-30

    % 1. Parse Inputs & Configuration
    if nargin < 2 || isempty(cfg)
        cfg = config();
    end

    if nargin < 1 || isempty(numPatients)
        numPatients = cfg.sim.patientsExpected;
    end

    rng(42); % Seed for reproducible simulation results

    % 2. Simulation Parameters (Times in Minutes)
    arrivalRate = cfg.sim.arrivalRatePerHour / 60.0; % Patients per minute
    meanInterArrival = 1.0 / arrivalRate;

    scanDurationMean = cfg.sim.scanDurationMinutes;
    scanDurationStd  = 0.5;

    retakeProb = cfg.sim.retakeProbability;
    retakeDuration = 2.0; % Extra minutes to reposition patient and retake

    aiProcessingTimeMin = cfg.sim.aiProcessingTimeSeconds / 60.0;

    docReviewG0 = cfg.sim.doctorReviewTimeGrade0Minutes;  % Fast-track normal
    docReviewG1 = cfg.sim.doctorReviewTimeGrade1Minutes;  % Mild
    docReviewG24 = cfg.sim.doctorReviewTimeGrade24Minutes;% High-risk referral

    docReviewManualMean = 12.0; % Baseline manual screening examination per patient
    docReviewManualStd  = 2.5;

    % Population DR Prevalence Distribution in Screening Cohort:
    % Grade 0 (65%), Grade 1 (18%), Grade 2 (10%), Grade 3 (4%), Grade 4 (3%)
    gradeProbDist = [0.65, 0.18, 0.10, 0.04, 0.03];

    % ---------------------------------------------------------------------
    % 3. Run AI-Assisted Clinic Simulation
    % ---------------------------------------------------------------------
    patientArrivalTimes = zeros(numPatients, 1);
    currentArrivalTime = 0;

    for i = 1:numPatients
        interArrival = exprnd(meanInterArrival);
        currentArrivalTime = currentArrivalTime + interArrival;
        patientArrivalTimes(i) = currentArrivalTime;
    end

    % Tracking Arrays
    camStartTimes  = zeros(numPatients, 1);
    camEndTimes    = zeros(numPatients, 1);
    retakeFlags    = false(numPatients, 1);
    aiGrades       = zeros(numPatients, 1);
    docStartTimes  = zeros(numPatients, 1);
    docEndTimes    = zeros(numPatients, 1);
    totalWaitTimes = zeros(numPatients, 1);

    % Fundus Camera Queue (Single camera server)
    camFreeTime = 0;
    for i = 1:numPatients
        camStart = max(patientArrivalTimes(i), camFreeTime);
        scanTime = max(1.5, normrnd(scanDurationMean, scanDurationStd));
        
        % Quality Gate Retake Event
        if rand() < retakeProb
            retakeFlags(i) = true;
            scanTime = scanTime + retakeDuration;
        end
        
        camEnd = camStart + scanTime;
        camFreeTime = camEnd;

        camStartTimes(i) = camStart;
        camEndTimes(i) = camEnd;

        % Sample Clinical Grade
        r = rand();
        cumP = cumsum(gradeProbDist);
        grade_i = find(r <= cumP, 1, 'first') - 1;
        aiGrades(i) = grade_i;
    end

    % AI Processing + Doctor Queue
    docFreeTime = 0;
    for i = 1:numPatients
        % Image arrives at doctor queue after AI processing
        imgReadyForDocTime = camEndTimes(i) + aiProcessingTimeMin;
        
        docStart = max(imgReadyForDocTime, docFreeTime);
        
        % Triage duration based on AI Grade
        switch aiGrades(i)
            case 0
                docDuration = docReviewG0;
            case 1
                docDuration = docReviewG1;
            otherwise
                docDuration = docReviewG24;
        end
        
        docEnd = docStart + docDuration;
        docFreeTime = docEnd;

        docStartTimes(i) = docStart;
        docEndTimes(i) = docEnd;
        totalWaitTimes(i) = docEnd - patientArrivalTimes(i);
    end

    totalShiftTimeAI = max(docEndTimes);
    aiThroughputPerHour = (numPatients / totalShiftTimeAI) * 60.0;
    aiAvgWaitTime = mean(totalWaitTimes);
    aiTotalDocTimeHours = sum(docEndTimes - docStartTimes) / 60.0;

    % ---------------------------------------------------------------------
    % 4. Run Baseline Manual Screening Simulation (No AI Triage)
    % ---------------------------------------------------------------------
    docFreeTimeManual = 0;
    totalWaitTimesManual = zeros(numPatients, 1);
    docTimesManual = zeros(numPatients, 1);

    for i = 1:numPatients
        % In manual screening, doctor must examine every patient thoroughly
        docStart = max(patientArrivalTimes(i), docFreeTimeManual);
        examTime = max(6.0, normrnd(docReviewManualMean, docReviewManualStd));
        docEnd = docStart + examTime;
        docFreeTimeManual = docEnd;

        totalWaitTimesManual(i) = docEnd - patientArrivalTimes(i);
        docTimesManual(i) = examTime;
    end

    totalShiftTimeManual = max(docFreeTimeManual);
    manualThroughputPerHour = (numPatients / totalShiftTimeManual) * 60.0;
    manualAvgWaitTime = mean(totalWaitTimesManual);
    manualTotalDocTimeHours = sum(docTimesManual) / 60.0;

    % ---------------------------------------------------------------------
    % 5. Compute Comparative Impact & Economics
    % ---------------------------------------------------------------------
    throughputMultiplier = aiThroughputPerHour / manualThroughputPerHour;
    docTimeSavedPercent = ((manualTotalDocTimeHours - aiTotalDocTimeHours) / manualTotalDocTimeHours) * 100.0;
    
    costManualTotal = numPatients * cfg.sim.costManualScreeningUSD;
    costAiTotal     = numPatients * cfg.sim.costAiAssistedScreeningUSD;
    dailyCostSavings = costManualTotal - costAiTotal;

    % 6. Construct Results Struct
    results = struct();
    results.totalPatientsSimulated = numPatients;
    results.aiThroughputPatientsPerHour = aiThroughputPerHour;
    results.manualThroughputPatientsPerHour = manualThroughputPerHour;
    results.throughputMultiplier = throughputMultiplier;
    results.aiAvgWaitTimeMinutes = aiAvgWaitTime;
    results.manualAvgWaitTimeMinutes = manualAvgWaitTime;
    results.aiTotalDoctorHours = aiTotalDocTimeHours;
    results.manualTotalDoctorHours = manualTotalDocTimeHours;
    results.doctorTimeSavedPercent = docTimeSavedPercent;
    results.retakeCount = sum(retakeFlags);
    results.retakeRatePercent = (sum(retakeFlags) / numPatients) * 100.0;
    results.totalDailyCostSavingsUSD = dailyCostSavings;
    
    % Detail summary log
    results.patientArrivalTimes = patientArrivalTimes;
    results.aiTotalWaitTimes = totalWaitTimes;
    results.manualTotalWaitTimes = totalWaitTimesManual;
    results.aiGrades = aiGrades;

end
