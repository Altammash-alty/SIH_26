function cfg = config()
% CONFIG Returns the default configuration parameters for the DR Pipeline.
%
%   CFG = CONFIG() returns a comprehensive struct containing tunable thresholds
%   and parameters for all 5 stages of the Diabetic Retinopathy screening
%   pipeline and the clinic throughput operational simulation:
%     1. Stage 1: Quality Gate (Blur, Illumination, Field of View)
%     2. Stage 2: Preprocessing (Illumination Normalization, CLAHE, Denoising)
%     3. Stage 3: Segmentation (Optic Disc, Retinal Vessels, Macula, Lesions)
%     4. Stage 4: DR Severity Grading (ICDR Grades 0-4, DME Risk Stratification)
%     5. Stage 5: Explainability & Doctor Reports (Grad-CAM, Visual Breakdown)
%     6. Stage 6: Clinic Throughput Operational Model (Tele-ophthalmology triage)
%
%   All parameters are in standardized normalized units [0, 1] or pixel
%   units where noted, allowing consistent behavior across different
%   camera resolutions and bit-depths.
%
%   Output:
%       cfg - Struct with fields 'quality', 'preprocess', 'segment',
%             'classify', 'explain', and 'sim'.
%
%   Author: DR Screening Pipeline MVP
%   Date: 2026-08-30

    %% --------------------------------------------------------------------
    %  STAGE 1: QUALITY GATE CONFIGURATION
    %  --------------------------------------------------------------------
    cfg.quality = struct();

    % 1. Blur / Sharpness check (Laplacian variance)
    % Higher variance indicates sharper edges (retinal vessels, optic disc).
    cfg.quality.blur = struct();
    cfg.quality.blur.threshold = 12.0;         % Minimum sharpness score to pass
    cfg.quality.blur.laplacianKernel = [0 1 0; 1 -4 1; 0 1 0]; % 3x3 discrete Laplacian
    cfg.quality.blur.maskErosionRadius = 15;   % Pixels to erode fundus boundary (avoids boundary edge bias)

    % 2. Illumination & Exposure check
    % Evaluated on green or luminance channel inside the valid fundus mask.
    cfg.quality.illumination = struct();
    cfg.quality.illumination.minMean = 0.15;     % Minimum mean intensity (rejects underexposed / dark images)
    cfg.quality.illumination.maxMean = 0.85;     % Maximum mean intensity (rejects overexposed / washed out)
    cfg.quality.illumination.minStd  = 0.04;     % Minimum standard deviation (rejects low-contrast / flat images)
    cfg.quality.illumination.maxStd  = 0.35;     % Maximum standard deviation (catches severe uneven flash/reflection)
    cfg.quality.illumination.underThreshold = 0.05; % Pixel intensity below which counts as clipping black
    cfg.quality.illumination.maxUnderRatio = 0.25;  % Max allowed fraction of underexposed pixels inside mask
    cfg.quality.illumination.overThreshold  = 0.95; % Pixel intensity above which counts as clipping white
    cfg.quality.illumination.maxOverRatio  = 0.15;  % Max allowed fraction of overexposed pixels inside mask

    % 3. Field of View (FOV) & Geometry check
    % Evaluates the circular fundus aperture coverage and centering.
    cfg.quality.fov = struct();
    cfg.quality.fov.minAreaRatio = 0.30;       % Min ratio of fundus mask area to total image area
    cfg.quality.fov.maxAreaRatio = 0.98;       % Max ratio (sanity check against all-white noise)
    cfg.quality.fov.minCircularity = 0.60;     % Min isoperimetric circularity: 4*pi*Area / (Perimeter^2)
    cfg.quality.fov.maxEccentricity = 0.82;    % Max ellipse eccentricity (0 = perfect circle)
    cfg.quality.fov.maxCenterOffset = 0.30;    % Max distance of fundus centroid from image center (fraction of min dimension)

    %% --------------------------------------------------------------------
    %  STAGE 2: PREPROCESSING & ENHANCEMENT CONFIGURATION
    %  --------------------------------------------------------------------
    cfg.preprocess = struct();

    % 1. Illumination Normalization
    % Smooths out non-uniform retinal flash illumination while retaining vessels.
    cfg.preprocess.illumination = struct();
    cfg.preprocess.illumination.filterSigma = 35;       % Gaussian kernel sigma for background estimation (in pixels)
    cfg.preprocess.illumination.targetMean  = 0.50;     % Target background luminance after flattening

    % 2. CLAHE (Contrast Limited Adaptive Histogram Equalization) on Green Channel
    % Enhances local vessel contrast and lesion visibility without over-amplifying noise.
    cfg.preprocess.clahe = struct();
    cfg.preprocess.clahe.clipLimit    = 0.015;          % Clip limit for contrast limitation (0.01 - 0.03)
    cfg.preprocess.clahe.numTiles     = [8 8];          % Contextual grid tiles [M N]
    cfg.preprocess.clahe.distribution = 'rayleigh';     % Histogram distribution ('uniform', 'rayleigh', 'exponential')
    cfg.preprocess.clahe.alpha        = 0.4;            % Rayleigh alpha parameter

    % 3. Denoising
    % Removes sensor speckle and compression artifacts while preserving vascular edges.
    cfg.preprocess.denoise = struct();
    cfg.preprocess.denoise.method       = 'median';     % 'median' or 'wiener' or 'guided'
    cfg.preprocess.denoise.medianKernel = [3 3];        % 2D median filter neighborhood size
    cfg.preprocess.denoise.wienerKernel = [3 3];        % 2D Wiener filter neighborhood size

    %% --------------------------------------------------------------------
    %  STAGE 3: RETINAL SEGMENTATION CONFIGURATION
    %  --------------------------------------------------------------------
    cfg.segment = struct();

    % 1. Optic Disc & Cup Segmentation
    cfg.segment.opticDisc = struct();
    cfg.segment.opticDisc.minRadiusRatio = 0.05;   % Min OD radius relative to image width
    cfg.segment.opticDisc.maxRadiusRatio = 0.18;   % Max OD radius relative to image width
    cfg.segment.opticDisc.intensityPercentile = 97; % Percentile for bright candidate seed detection
    cfg.segment.opticDisc.morphKernelRadius = 10;  % Closing disk radius for smoothing OD boundary
    cfg.segment.opticDisc.cupThresholdFactor = 1.15; % Brightness multiplier for optic cup inside disc

    % 2. Retinal Vessel Tree Segmentation
    cfg.segment.vessel = struct();
    cfg.segment.vessel.scales = [1.0, 1.8, 2.5, 3.2]; % Multi-scale matched filter sigmas
    cfg.segment.vessel.tophatRadius = 9;              % Morphological top-hat structuring element radius
    cfg.segment.vessel.adaptThreshSensitivity = 0.55; % Adaptive threshold sensitivity (0 to 1)
    cfg.segment.vessel.minAreaPixels = 30;             % Minimum connected component pixel size to retain
    cfg.segment.vessel.closingRadius = 1;              % Morphological bridge radius

    % 3. Macula / Fovea Localization
    cfg.segment.macula = struct();
    cfg.segment.macula.odDistanceDiscDiameters = 2.5;  % Fovea is ~2.5 disc diameters temporal to OD
    cfg.segment.macula.foveaRadiusDiscRatio = 0.45;    % Central fovea zone radius relative to OD diameter
    cfg.segment.macula.maculaHazardRadiusRatio = 1.0;  % 1-disc-diameter hazard zone for clinically significant DME

    % 4. Lesion Candidate Detection (Dark & Bright Lesions)
    cfg.segment.lesion = struct();
    cfg.segment.lesion.darkMinSize = 4;                % Min microaneurysm size in pixels
    cfg.segment.lesion.darkMaxSize = 400;              % Max hemorrhage cluster size in pixels
    cfg.segment.lesion.darkSensitivity = 0.04;         % Bottom-hat intensity contrast threshold
    cfg.segment.lesion.brightMinSize = 4;              % Min hard exudate size in pixels
    cfg.segment.lesion.brightMaxSize = 600;            % Max exudate / cotton wool spot size in pixels
    cfg.segment.lesion.brightSensitivity = 0.06;       % Top-hat intensity contrast threshold

    %% --------------------------------------------------------------------
    %  STAGE 4: DR SEVERITY CLASSIFICATION CONFIGURATION
    %  --------------------------------------------------------------------
    cfg.classify = struct();
    cfg.classify.grades = {'No DR (Grade 0)', 'Mild NPDR (Grade 1)', ...
                          'Moderate NPDR (Grade 2)', 'Severe NPDR (Grade 3)', ...
                          'Proliferative DR (Grade 4)'};
    cfg.classify.icd10 = {'E11.9 / H36.0', 'E11.319', 'E11.329', 'E11.339', 'E11.359'};
    cfg.classify.urgencies = {
        'Routine annual screening (12 months)', ...
        'Routine follow-up in 6 to 12 months', ...
        'Prompt comprehensive exam in 3 to 6 months', ...
        'Urgent specialist referral in 2 to 4 weeks', ...
        'Immediate vitreoretinal specialist referral (< 48-72 hours)'
    };
    
    % ETDRS Biomarker Grading Criteria Thresholds
    cfg.classify.mildMaxMicroaneurysms = 5;      % Max microaneurysms for Mild NPDR
    cfg.classify.modMaxHemorrhages = 20;         % Hemorrhages for Moderate NPDR
    cfg.classify.severeHemorrhagePerQuad = 20;   % 4-2-1 rule: 20+ intraretinal hemorrhages in each of 4 quadrants
    cfg.classify.pdrNeovascularAreaRatio = 0.005;% Neovascularization area threshold for PDR
    cfg.classify.dmeNearDistancePx = 50.0;       % Exudate distance to fovea for Clinically Significant DME

    %% --------------------------------------------------------------------
    %  STAGE 5: EXPLAINABILITY & REPORTING CONFIGURATION
    %  --------------------------------------------------------------------
    cfg.explain = struct();
    cfg.explain.colormap = 'turbo';              % Colormap for Grad-CAM / Attention map ('turbo', 'jet', 'hot')
    cfg.explain.alpha = 0.50;                    % Transparency alpha blend for heatmap overlay
    cfg.explain.quadrantLines = true;            % Overlay 4-quadrant ETDRS grid
    cfg.explain.exportDpi = 300;                 % Output figure resolution
    cfg.explain.saveHtmlReport = true;           % Export self-contained HTML clinical report

    %% --------------------------------------------------------------------
    %  OUT-OF-DISTRIBUTION (OOD) DETECTION CONFIGURATION
    %  --------------------------------------------------------------------
    cfg.ood = struct();
    cfg.ood.distanceMetric     = 'mahalanobis';  % Distance metric: 'mahalanobis' or 'zscore'
    cfg.ood.distanceThreshold  = 3.8;            % Mahalanobis distance cutoff to flag an image as OOD
    cfg.ood.zScoreFeatureCutoff = 3.0;           % Individual feature z-score cutoff for detailed flag reasons
    cfg.ood.regCovariance      = 1e-4;           % Regularization shrinkage factor (lambda*I) for stable covariance inversion
    cfg.ood.statsFilePath      = 'reference_stats.mat'; % Default precomputed training reference stats file
    cfg.ood.glcmNumLevels      = 16;             % Gray-level quantization levels for Haralick texture GLCM
    cfg.ood.glcmOffsets        = [0 1; -1 1; -1 0; -1 -1]; % 4 standard 2D directional offsets (0, 45, 90, 135 deg)

    %% --------------------------------------------------------------------
    %  TRUST & ROUTING DECISION LAYER CONFIGURATION
    %  --------------------------------------------------------------------
    cfg.routing = struct();
    cfg.routing.confidenceThreshold = 0.75;      % Minimum confidence score required to trust AI prediction
    cfg.routing.healthyGrades       = [0, 1];    % Grades eligible for auto-cleared fast-track (No DR, Mild NPDR)
    cfg.routing.referableGrades     = [2, 3, 4]; % Grades requiring specialist ophthalmology review (Mod, Severe, PDR)
    cfg.routing.auditSamplingRate   = 0.10;      % 10% random sampling rate for auditing auto-cleared cases

    % Quality Sensitivity Recheck Test parameters
    cfg.routing.qualityRecheck = struct();
    cfg.routing.qualityRecheck.perturbationType   = 'blur'; % 'blur' or 'brightness'
    cfg.routing.qualityRecheck.blurSigma          = 1.8;    % Gaussian blur standard deviation for perturbation
    cfg.routing.qualityRecheck.brightnessFactor   = 0.85;   % Controlled attenuation factor (if brightness perturbation chosen)
    cfg.routing.qualityRecheck.confDeltaThreshold = 0.15;   % Maximum allowed confidence drop before flagging quality sensitivity
    cfg.routing.qualityRecheck.gradeShiftSensitive = true;  % Flag as quality-sensitive if the discrete grade changes

    % Second Opinion / Model Disagreement parameters
    cfg.routing.secondOpinion = struct();
    cfg.routing.secondOpinion.maxAllowedGradeDiff = 0;      % 0 = exact agreement required on discrete grade (0-4)
    cfg.routing.secondOpinion.confDeltaThreshold  = 0.30;   % Disagreement if confidence divergence is large

    %% --------------------------------------------------------------------
    %  STAGE 6: CLINIC THROUGHPUT OPERATIONAL MODEL CONFIGURATION
    %  --------------------------------------------------------------------
    cfg.sim = struct();
    cfg.sim.workdayHours = 8;                    % Standard clinical screening shift (hours)
    cfg.sim.patientsExpected = 120;              % Total daily screening appointments
    cfg.sim.arrivalRatePerHour = 15;             % Poisson patient arrival rate (patients/hr)
    cfg.sim.retakeProbability = 0.08;            % Retake rate from Quality Gate rejection (8%)
    cfg.sim.scanDurationMinutes = 3.0;           % Fundus camera acquisition duration (mins)
    cfg.sim.aiProcessingTimeSeconds = 2.5;       % End-to-end AI latency per patient (seconds)
    cfg.sim.doctorReviewTimeGrade0Minutes = 0.5;  % Fast-track normal sign-off (30s)
    cfg.sim.doctorReviewTimeGrade1Minutes = 1.5;  % Mild NPDR verification (90s)
    cfg.sim.doctorReviewTimeGrade24Minutes = 8.0; % High-risk severe/PDR counseling & referral (8 mins)
    cfg.sim.costManualScreeningUSD = 45.0;       % Baseline manual screening cost per patient
    cfg.sim.costAiAssistedScreeningUSD = 12.5;   % AI triage cost per patient

end

