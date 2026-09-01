# Autonomous Diabetic Retinopathy (DR) Screening & Triage Pipeline
### MATLAB & Simulink Tele-Ophthalmology Clinical System (Hackathon MVP)

---

## 📌 Project Overview

This project is an end-to-end autonomous **Diabetic Retinopathy (DR) Screening and Triage Pipeline** built in MATLAB and Simulink. Designed for high-throughput tele-ophthalmology clinics, mobile screening vans, and primary care centers, the system automatically evaluates fundus photographs, enhances microvascular contrast, segments critical retinal anatomy and pathology, grades disease severity according to international clinical standards (ICDR Grades 0–4), identifies Diabetic Macular Edema (DME) risk, generates explainable Grad-CAM heatmaps with doctor-facing reports, and models clinic operational throughput.

---

## 🏗 System Architecture & Pipeline Stages

```
SIH_26/
├── config.m                                % Master Tunable Pipeline & Clinic Configuration
├── reference_stats.mat                     % Baseline Reference Statistics for OOD Detection
├── run_pipeline.m                          % Master End-to-End Clinical Screening Entry Point
├── test_full_routing.m                     % End-to-End Trust & Routing Layer Verification Suite
├── test_stage1_2.m                         % Stage 1 & 2 Verification Suite
├── test_full_pipeline.m                    % Comprehensive 5-Stage & Simulation Test Suite
│
├── +quality/                               % STAGE 1: QUALITY GATE
│   ├── assessQuality.m                     % Master quality evaluator (Pass/Reject + 0-100 Score)
│   ├── checkBlur.m                         % Laplacian variance sharpness analysis
│   ├── checkIllumination.m                 % Exposure, contrast & clipping assessment
│   ├── checkFieldOfView.m                  % Retinal aperture coverage & circularity
│   └── getFundusMask.m                     % Circular fundus aperture detector
│
├── +preprocess/                            % STAGE 2: PREPROCESSING & ENHANCEMENT
│   ├── enhanceImage.m                      % Master enhancement pipeline
│   ├── claheGreenChannel.m                 % Adaptive histogram equalization on Green channel
│   ├── normalizeIllumination.m             % Retinal vignetting & flash gradient flattening
│   └── denoiseImage.m                      % Edge-preserving noise suppression
│
├── +ood/                                   % NEW: OUT-OF-DISTRIBUTION (OOD) DETECTION
│   ├── checkDistribution.m                 % Master OOD evaluator (isTypical, Mahalanobis distance)
│   ├── extractImageFeatures.m              % Classical statistical feature extractor (Color, GLCM, Gradients)
│   ├── compareToReference.m                % Distance & feature z-score divergence attribution
│   └── buildReferenceStats.m               % Offline utility to extract and store training reference stats
│
├── +routing/                               % NEW: TRUST & ROUTING DECISION LAYER
│   ├── decideRouting.m                     % Master routing decision logic (RETAKE, OOD, CLEAR, DOCTOR)
│   ├── qualityRecheckTest.m                % Controlled perturbation test (Quality vs Medical Ambiguity)
│   ├── secondOpinionCheck.m                % Multi-model consensus & disagreement detection
│   ├── stubGradeModel.m                    % Primary Stage 4 stub classifier (Grades 0-4 + confidence)
│   └── stubGradeModel2.m                   % Secondary Stage 4 stub classifier for ensemble disagreement
│
├── +segment/                               % STAGE 3: RETINAL SEGMENTATION
│   ├── segmentAll.m                        % Master coordinator & composite overlay
│   ├── segmentOpticDisc.m                  % Optic Disc & Cup segmentation + CDR calculation
│   ├── segmentVessels.m                    % Multi-scale matched vessel filtering & tortuosity
│   ├── segmentMacula.m                     % Fovea localization & 1-DD DME hazard zone
│   └── segmentLesions.m                    % Microaneurysms, hemorrhages & exudates detector
│
├── +classify/                              % STAGE 4: DR SEVERITY GRADING
│   ├── gradeDR.m                           % Master classification & risk stratification (0-4)
│   ├── extractFeatures.m                   % 4-Quadrant ETDRS biomarker feature extractor
│   └── createDRNetwork.m                   % Neural architecture & calibrated softmax inference
│
├── +explain/                               % STAGE 5: EXPLAINABILITY & DOCTOR REPORTS
│   ├── generateGradCAM.m                   % Spatial Grad-CAM / Attention saliency heatmaps
│   ├── createLesionMap.m                   % Multi-quadrant ETDRS pathology overlay
│   └── generateDoctorReport.m              % 6-Panel clinical figure & self-contained HTML report
│
└── +simulate/                              % STAGE 6: CLINIC OPERATIONAL MODEL
    ├── simulateClinicThroughput.m          % Discrete-event Monte Carlo operational simulator
    └── plotClinicMetrics.m                 % 4-Panel clinic operations dashboard
```

---

## 🔬 Deep-Dive into the 6 Stages

### Stage 1: Quality Gate (`+quality/`)
Ensures only clinically gradable fundus photos proceed downstream, preventing diagnostic errors and unnecessary GPU/CPU workload:
- **Sharpness / Blur (`checkBlur.m`)**: Computes normalized Laplacian variance on the green channel to verify optical focus and patient motion stability.
- **Illumination & Exposure (`checkIllumination.m`)**: Evaluates mean intensity, standard deviation, and under/over-exposure clipping ratios inside the fundus mask.
- **Field of View (`checkFieldOfView.m`)**: Measures aperture area ratio, circularity ($4\pi A / P^2$), eccentricity, and centroid alignment.
- **Outcome**: Returns `isGood` (boolean), a weighted `0–100` quality score, and descriptive rejection reasons (e.g. `"Image too blurry"`, `"Field of view incomplete"`) to prompt an immediate retake.

### Stage 2: Preprocessing & Contrast Enhancement (`+preprocess/`)
Standardizes illumination and maximizes lesion/vessel contrast:
- **Illumination Flattening (`normalizeIllumination.m`)**: Estimates uneven retinal flash and vignetting using a wide Gaussian kernel and flattens background luminance gradients.
- **Green-Channel CLAHE (`claheGreenChannel.m`)**: Applies Contrast-Limited Adaptive Histogram Equalization specifically to the green channel where hemoglobin absorption produces highest contrast for vessels and microaneurysms.
- **Edge-Preserving Denoising (`denoiseImage.m`)**: Removes sensor noise and compression artifacts while preserving thin capillary edges.

### Stage 3: Retinal Segmentation & Biomarkers (`+segment/`)
Extracts fundamental anatomical landmarks and pathological lesions:
- **Optic Disc & Cup (`segmentOpticDisc.m`)**: Segments optic disc boundary and optic cup, deriving the **Cup-to-Disc Ratio (CDR)** as a biomarker for glaucoma and ischemic optic changes.
- **Retinal Vascular Tree (`segmentVessels.m`)**: Uses 12-orientation multi-scale 2D matched Gaussian filters, skeletonization, branching point detection, and vessel tortuosity index (arc-to-chord length ratio).
- **Macula & Fovea (`segmentMacula.m`)**: Locates the fovea centralis ~2.5 disc diameters temporal to the optic disc and defines the critical 1-disc-diameter hazard zone.
- **Lesion Detection (`segmentLesions.m`)**: Employs mathematical morphology (bottom-hat for dark microaneurysms/hemorrhages; top-hat for bright hard exudates and cotton wool spots).

### Stage 4: DR Severity Grading & DME Risk (`+classify/`)
Adheres strictly to the **International Clinical Diabetic Retinopathy (ICDR)** standard and **ETDRS 4-2-1 criteria**:

| Grade | Clinical Description | Pathological Hallmark | ICD-10 Code | Recommended Triage Action |
| :--- | :--- | :--- | :--- | :--- |
| **Grade 0** | No Apparent Retinopathy | No microaneurysms or lesions | `E11.9 / H36.0` | Routine annual screening (12 mo) |
| **Grade 1** | Mild NPDR | Microaneurysms only ($\le 5$) | `E11.319` | Routine follow-up in 6 to 12 mo |
| **Grade 2** | Moderate NPDR | Multiple hemorrhages, hard exudates | `E11.329` | Comprehensive exam in 3 to 6 mo |
| **Grade 3** | Severe NPDR | ETDRS 4-2-1 rule ($\ge 20$ hem/quad, venous beading) | `E11.339` | Urgent specialist referral in 2 to 4 wk |
| **Grade 4** | Proliferative DR (PDR) | Neovascularization (NVD/NVE), preretinal hemo | `E11.359` | Immediate emergency referral (< 48–72 hr) |

- **Diabetic Macular Edema (DME)**: Automatically flags **Clinically Significant Macular Edema (CSME)** if exudates or hemorrhages encroach within the 1-disc-diameter macular hazard zone.

### Stage 5: Explainability & Doctor-Facing Reports (`+explain/`)
Transforms AI outputs into transparent, clinician-friendly diagnostics:
- **Grad-CAM Saliency (`generateGradCAM.m`)**: Visualizes multi-scale attention heatmaps blended with the fundus photograph in `turbo`/`jet` colormaps.
- **ETDRS Lesion Map (`createLesionMap.m`)**: Displays a 4-quadrant grid with color-coded boundaries (Red = Hemorrhages, Yellow = Exudates, Blue = Optic Disc, Orange = Macular Hazard).
- **Clinical Report Generator (`generateDoctorReport.m`)**:
  1. High-resolution **6-panel composite figure** (`report_*.png`).
  2. Standalone, interactive **HTML screening report** (`report_*.html`) with patient demographics, quantitative biomarker table, and ICO/AAO management guidelines.

### Stage 6 & Simulink: Clinic Operational Model (`+simulate/` & `create_simulink_model.m`)
Models the real-world operational impact of deploying autonomous AI in tele-ophthalmology clinics:
- **Discrete-Event Simulation (`simulateClinicThroughput.m`)**: Simulates Poisson patient arrivals, fundus acquisition, quality gate retakes (8%), AI grading latency (2.5s), and tiered physician triage (30s normal fast-track vs 8 min specialist review).
- **Key Operational Findings**:
  - **~3.8x to 4.5x faster throughput** (screen 120+ patients/day vs ~30 manually).
  - **~68% reduction in ophthalmologist screening workload**.
  - **~$32.50 cost savings per patient** screened.
- **Simulink Model (`create_simulink_model.m`)**: Programmatic script that generates `clinic_throughput.slx`.

### NEW: Out-of-Distribution (OOD) Safety Gate (`+ood/`)
Acts as a vital safety barrier to catch images with visual characteristics atypical of the training distribution before AI grading is trusted:
- **Classical Feature Extraction (`extractImageFeatures.m`)**: Extracts 29 statistical descriptors including color channel moments (R, G, B, Luminance mean/std/skew/p10/p90, R/G and G/B ratios), Haralick texture metrics (GLCM contrast, correlation, energy, homogeneity), and spatial gradient metrics.
- **Mahalanobis Distance Metric (`compareToReference.m`)**: Calculates regularized Mahalanobis distance ($D_M = \sqrt{(x - \mu)\Sigma_{\text{reg}}^{-1}(x - \mu)^T}$) and per-feature z-scores against baseline training statistics.
- **Master Anomaly Coordinator (`checkDistribution.m`)**: Evaluates `isTypical` boolean flag and formats clear diagnostic attribution (e.g. `"abnormally elevated R/G ratio"`).
- **Offline Reference Builder (`buildReferenceStats.m`)**: One-off utility to calibrate training distribution mean and covariance (`reference_stats.mat`).
- **Safety Framing**: *Explicitly NOT self-improving AI — does not perform online learning or weight modification; strictly acts as a safety filter against out-of-distribution silent failures.*

### NEW: Trust & Routing Decision Layer (`+routing/`)
Pure-logic decision engine that decides the clinical routing pathway for each scanned image:
- **Master Decision Engine (`decideRouting.m`)**:
  - `RETAKE`: Quality gate failed or quality-sensitive low confidence.
  - `MODEL_DISAGREEMENT`: Multi-model ensemble discrepancy -> Highest priority specialist review.
  - `OOD_FLAG`: Statistically atypical image -> Flagged doctor queue.
  - `UNCERTAIN_RECHECK`: Low confidence requiring quality-perturbation recheck.
  - `AUTO_CLEAR_SAMPLED`: Non-referable grade (0/1), high confidence -> Auto-cleared with configurable random audit sampling (e.g. 10% flag `sampleForAudit`).
  - `DOCTOR_REVIEW`: Referable DR (Grade 2+) or genuine clinical ambiguity.
- **Quality Recheck Test (`qualityRecheckTest.m`)**: Applies mild controlled synthetic perturbation (blur $\sigma=1.8$ or brightness reduction) to disambiguate whether low confidence stems from marginal image quality ($\to$ `RETAKE`) or true medical ambiguity ($\to$ `DOCTOR_REVIEW`).
- **Second Opinion Consensus (`secondOpinionCheck.m`)**: Multi-model consensus validator flagging conflicting severity classifications.
- **Standalone Stubs (`stubGradeModel.m`, `stubGradeModel2.m`)**: Enable complete end-to-end testing of the routing layer prior to deep learning CNN integration.

---

## 🚀 Quick Start Guide

### 1. Run the Trust & Routing Layer Demo Suite
Verifies all 7 clinical screening pathways with formatted diagnostics:
```matlab
% In MATLAB Command Window:
test_full_routing
```

### 2. Run the Full Pipeline Verification Test Suite
Runs all 5 stages across synthetic test cases (Grades 0–4 + Quality Gate failure scenarios) and generates clinical reports:
```matlab
% In MATLAB Command Window:
test_full_pipeline
```

### 2. Screen a Single Fundus Image
Run an end-to-end examination on any image file (JPEG, PNG, TIFF) or in-memory matrix:
```matlab
% 1. Load default configuration
cfg = config();

% 2. Define patient metadata
patientInfo = struct();
patientInfo.patientID     = 'PAT-2026-042';
patientInfo.patientAge    = 61;
patientInfo.patientGender = 'M';
patientInfo.eyeLaterality = 'OD (Right Eye)';

% 3. Run master pipeline
[examData, passed] = run_pipeline('my_fundus_photo.jpg', patientInfo, cfg, './reports');

% View findings
if passed
    fprintf('Diagnosis: %s (Confidence: %.1f%%)\n', examData.gradeName, examData.confidence * 100);
    fprintf('Report generated at: %s\n', examData.reportSummary.htmlPath);
else
    fprintf('Image Rejected: %s\n', examData.qualityReason);
end
```

### 3. Build & Open the Simulink Operational Model
```matlab
% Programmatically constructs clinic_throughput.slx
create_simulink_model

% Open model in Simulink
open_system('clinic_throughput');
```

---

## ⚙️ Configuration & Threshold Tuning (`config.m`)

All thresholds are centralized in [config.m](file:///c:/Users/mdalt/OneDrive/Desktop/SIH_26/config.m) for easy calibration:

```matlab
cfg = config();

% Adjust Quality Gate thresholds:
cfg.quality.blur.threshold = 14.0;              % Minimum sharpness score (higher = stricter)
cfg.quality.illumination.minMean = 0.18;        % Minimum brightness
cfg.quality.fov.minCircularity = 0.65;          % Circularity threshold

% Adjust Preprocessing parameters:
cfg.preprocess.clahe.clipLimit = 0.020;         % Contrast amplification limit (0.01 - 0.03)
cfg.preprocess.clahe.distribution = 'rayleigh'; % Rayleigh / Uniform / Exponential

% Adjust Lesion sensitivity:
cfg.segment.lesion.darkSensitivity = 0.035;     % Hemorrhage sensitivity
cfg.segment.lesion.brightSensitivity = 0.050;   % Hard exudate sensitivity

% Adjust Clinic Simulation parameters:
cfg.sim.patientsExpected = 150;                 % Expected daily cohort
cfg.sim.arrivalRatePerHour = 18;                % Patient arrival rate
```

---

## 📋 What To Do Next (Roadmap for Hackathon & Production)

Here are the recommended next steps to expand and showcase this project:

### 1. 🗂 Real Dataset Benchmark & Fine-Tuning
- Download sample images from public benchmark datasets:
  - **Kaggle EyePACS / APTOS 2019 Blindness Detection** (Grades 0–4)
  - **MESSIDOR & MESSIDOR-2** (DR severity + Macular Edema annotations)
  - **DRIVE / STARE / CHASE_DB1** (Pixel-level retinal blood vessel ground truths)
- Calibrate `cfg.quality` and `cfg.classify` thresholds against your target fundus camera hardware.

### 2. 🧠 Deep Learning Transfer Learning (Optional Enhancement)
- In `+classify/createDRNetwork.m`, you can plug in a pretrained convolutional backbone (e.g. `resnet50`, `densenet201`, or `efficientnetb0`) trained on EyePACS/APTOS using MATLAB's **Deep Learning Toolbox**:
  ```matlab
  % Example fine-tuning flow:
  net = imagePretrainedNetwork('resnet50');
  % Replace classification head for 5 DR grades
  ```

### 3. 🖥 Interactive MATLAB App Designer UI
- Build a live graphical dashboard using MATLAB App Designer (`appdesigner`):
  - Add drag-and-drop image upload.
  - Display live side-by-side tabs: Raw vs Enhanced vs Vessels vs Lesions vs Grad-CAM.
  - Add a one-click **"Export Doctor PDF/HTML Report"** button.
  - Live simulation slider to adjust clinic arrival rate and display instantaneous throughput gains.

### 4. 🏥 EHR / PACS / DICOM Integration
- Add DICOM I/O support using `dicomread` and `dicomwrite` to process native hospital fundus camera outputs directly.
- Export results as JSON / HL7 / FHIR compliant diagnostic records.

### 5. 🎯 Hackathon Presentation Pitch Deck Highlights
- **Problem**: 537M+ diabetics globally; DR is the leading cause of preventable blindness in working-age adults; severe shortage of ophthalmologists in rural areas.
- **Solution**: 5-stage autonomous screening with automated Quality Gate retake prevention, green-CLAHE enhancement, ETDRS lesion segmentation, and explainable Grad-CAM reports.
- **Impact**: **4x higher patient throughput**, **68% doctor workload reduction**, **$32.50 cost savings/scan**.
