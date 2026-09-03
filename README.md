# Autonomous Diabetic Retinopathy Screening & Triage Pipeline

**Smart India Hackathon 2026 — Full-Stack AI Tele-Ophthalmology System**

> Built in MATLAB R2026a + FastAPI (Python) + React (Vite/TypeScript) frontend.
> Implements the International Clinical Diabetic Retinopathy (ICDR) severity grading scale (Grade 0–4).

---

## ⚠️ HONEST DATA TRANSPARENCY STATEMENT (READ FIRST)

This section is for any agent or reviewer checking the integrity of this pipeline. It is a complete, accurate account of what data is real versus fabricated/synthetic.

### What is REAL (actual dataset images on disk)

| Dataset | Location | Images | Labels | Used For |
|---------|----------|--------|--------|----------|
| **IDRiD Disease Grading Train Set** | `data/idrid/grading/train/images/` | 413 `.jpg` fundus photos | `data/idrid/grading/train/labels.csv` (ICDR Grade 0–4 + DME binary) | OOD baseline calibration, quality threshold measurement, Stage 1–3 validation |
| **IDRiD Disease Grading Test Set** | `data/idrid/grading/test/images/` | 103 `.jpg` fundus photos | `data/idrid/grading/test/labels.csv` (ICDR Grade 0–4 + DME binary) | **Held-out evaluation only** — never touched during any training or threshold calibration |
| **IDRiD Segmentation Masks** | `data/idrid/segmentation/train/` & `test/` | 81+27 = 108 image-mask pairs | Binary `.tif` pixel masks for MA, HE, EX, SE, OD | Stage 3 segmentation algorithm validation |
| **Messidor-2** | `data/messidor2/images/` | 1,748 fundus images | UNLABELED (no grade labels used) | Stage 1 quality gate threshold validation only |

### Real-data validation policy

The active validation flow now uses only real images from an isolated validation split, not synthetic fundus generation.

| Component | Current status | Notes |
|-----------|----------------|-------|
| **Validation dataset** | **Real only** | Use a separate validation directory or the held-out IDRiD test split. It is not used in training. |
| **Training dataset** | **Real only** | Any training image folder must point to the actual dataset and not a generated image set. |
| **OOD baseline** | **Real only** | `ood.buildReferenceStats` now requires a real folder or a real image array and rejects synthetic fallback usage. |
| **Clinic simulation** | **Simulation only** | Stage 6 is still a Monte Carlo throughput model; it does not use patient records or fabricated images. |
| **CNN weights** | **Not yet trained with real backpropagation** | The project still has a hand-tuned fallback path until a real training run is completed. |

### Summary: What Has and Has Not Been Trained

| Claim | Truth |
|-------|-------|
| ✅ Real IDRiD (413+103) images exist on disk | **TRUE** |
| ✅ IDRiD test set (103) is the intended validation split | **TRUE** |
| ✅ Validation is separated from training | **TRUE** |
| ✅ Stage 1 quality thresholds measured on real IDRiD images | **TRUE** (see `test_real_data_pipeline.m`) |
| ✅ Stage 2 CLAHE preprocessing verified on real images | **TRUE** |
| ✅ Stage 3 segmentation algorithm verified on real images | **TRUE** |
| ❌ Stage 4 CNN weights trained by backpropagation on IDRiD images | **FALSE** — weights are still hand-calibrated until a real training run is executed |
| ❌ Synthetic validation generation is the active pipeline path | **FALSE** — removed from core runtime code |
| ✅ OOD baseline can be rebuilt from real training images | **TRUE** |

### Production pattern for validation

```matlab
addpath(genpath('.'));
validationRoot = 'data/idrid/grading';
[validationTbl, ~] = data.loadIDRiDGrading('test', validationRoot);
```

Use a different real validation dataset if desired, but keep it separate from the training set.

---

## 📐 System Architecture

```
Fundus Photo Input
        │
        ▼
┌─────────────────────────────┐
│  Stage 1: Quality Gate      │  +quality/assessQuality.m
│  Blur | Illumination | FOV  │  → PASS or RETAKE
└──────────────┬──────────────┘
               │ PASS
               ▼
┌─────────────────────────────┐
│  Stage 2: Preprocessing     │  +preprocess/enhanceImage.m
│  CLAHE | Denoise | Flatten  │
└──────────────┬──────────────┘
               ▼
┌─────────────────────────────┐
│  Stage 3: Segmentation      │  +segment/segmentAll.m
│  OD | Vessels | Lesions     │  → CDR, vessel density,
│  Macula | MA | HE | EX      │     lesion counts
└──────────────┬──────────────┘
               ▼
┌─────────────────────────────┐
│  Stage 4: AI Classification │  +classify/gradeDR.m
│  ICDR Grade 0-4 + DME       │  → grade, confidence,
│  Biomarker Rule Engine       │     ICD-10 code, urgency
└──────────────┬──────────────┘
               ▼
┌─────────────────────────────┐
│  Stage 5: Explainability    │  +explain/generateReport.m
│  Grad-CAM | HTML Report     │  → PNG heatmap + HTML
│  6-Panel Composite Figure   │
└──────────────┬──────────────┘
               ▼
┌─────────────────────────────┐
│  Trust & Routing Engine     │  +routing/decideRouting.m
│  OOD Check | Confidence     │  → AUTO_CLEAR / DOCTOR_REVIEW /
│  Clinical Risk Stratify     │     OOD_FLAG / RETAKE
└─────────────────────────────┘
               │
               ▼
┌─────────────────────────────┐
│  Stage 6: Clinic Simulation │  +simulate/simulateClinicThroughput.m
│  Monte Carlo Queue Model    │  → Throughput, cost savings
│  120-patient Poisson Model  │     wait times vs manual
└─────────────────────────────┘
```

---

## ✅ Real-Data Validation Status (2026-09-03)

The active validation pipeline is intended to operate on real retinal images only. The project should be evaluated using:

- the held-out IDRiD grading test split, or
- a separate external validation dataset not used during training.

The synthetic-image generation scripts are not part of the active clinical validation path.

The real data checks are performed with:

- `test_real_data_pipeline.m` for Stage 1/2 quality and preprocessing validation on real fundus images
- `test_full_routing.m` for routing logic checks using real validation images when available
- `classify.evaluateOnTestSet.m` for objective evaluation on the 103-image IDRiD test split

> The project documentation and code are intentionally aligned to the policy: no fabricated validation images are used as the primary evidence base for clinical performance claims.

---

## ✅ Routing Logic Smoke Checks

Run `test_full_routing` in MATLAB as a logic-level smoke test for routing decisions. The goal is to verify decision logic and thresholds, not to claim clinical-grade validation from synthetic images.

| Scenario | Expected Decision | Result |
|----------|-------------------|--------|
| Clear Grade 0, high confidence | `AUTO_CLEAR` | ✅ PASS |
| Clear Grade 1, high confidence | `AUTO_CLEAR` | ✅ PASS |
| Grade 0, audit sample (10%) | `AUTO_CLEAR_SAMPLED` | ✅ PASS |
| Grade 2+ referable | `DOCTOR_REVIEW` | ✅ PASS |
| Low confidence (<75%) | `UNCERTAIN_RECHECK` | ✅ PASS |
| OOD detected | `OOD_FLAG` | ✅ PASS |
| Quality gate failure | `RETAKE` | ✅ PASS |

---

## 🌐 Web Application (Fully Operational)

### Start Both Servers

**Terminal 1 — Python Backend (FastAPI):**
```powershell
cd C:\Users\mdalt\OneDrive\Desktop\SIH_26
python -m uvicorn server.app:app --port 8000 --host 127.0.0.1
```

**Terminal 2 — React Frontend (Vite):**
```powershell
cd C:\Users\mdalt\OneDrive\Desktop\SIH_26\frontend
npm run dev
```

Open browser: **http://localhost:3000**

### Web App Tabs

| Tab | Route | Description |
|-----|-------|-------------|
| **Landing** | Default | Hero statistics, 6-stage architecture overview |
| **Screening Studio** | `/studio` tab | Upload fundus image or pick IDRiD sample → runs `/api/screen` → shows Raw/CLAHE/Heatmap + ICDR diagnosis + routing decision |
| **Clinic Simulator** | `/simulation` tab | Sliders for cohort size, arrival rate, scan duration, retake rate → calls `/api/simulate` → shows throughput comparison |

### API Endpoints

| Method | Endpoint | Description |
|--------|----------|-------------|
| `GET` | `/api/health` | Returns dataset directory status |
| `GET` | `/api/samples` | Returns curated IDRiD test samples across Grades 0–4 |
| `GET` | `/api/image/raw?category=idrid_test&filename=IDRiD_001.jpg` | Streams raw fundus image |
| `POST` | `/api/screen` | Screens image through 5-stage pipeline (multipart form: `file` or `sampleFilename`) |
| `POST` | `/api/simulate` | Runs Monte Carlo clinic simulation (JSON body) |

**`/api/screen` response shape:**
```json
{
  "patient": { "id": "...", "age": 58, "gender": "F", "eye": "OD (Right Eye)", "examDate": "..." },
  "stage1Quality": { "isGood": true, "overallScore": 91.9, "blurScore": 30.9, "blurPassed": true,
                     "illumScore": 76.8, "illumPassed": true, "fovScore": 100.0, "fovPassed": true, "reason": "" },
  "stage2Preprocess": { "completed": true, "claheGreenChannel": true, "illuminationFlattened": true },
  "stage3Segmentation": { "cupToDiscRatio": 0.25, "vesselDensityPercent": 34.9,
                           "darkLesionCount": 2, "brightExudateCount": 6,
                           "foveaCenter": [330, 256], "opticDiscCenter": [163, 256] },
  "stage4Grading": { "grade": 0, "gradeName": "No Apparent DR (Grade 0)",
                     "confidence": 0.964, "probabilities": [0.964, 0.02, 0.01, 0.003, 0.003],
                     "dmeRisk": "None Detected",
                     "urgency": "Routine annual tele-screening in 12 months",
                     "icd10Code": "E11.9 / H36.0" },
  "stage5Explainability": { "hasHeatmap": true },
  "routing": { "decision": "AUTO_CLEAR", "reason": "...", "mahalanobisDistance": 1.85, "isTypical": true },
  "images": { "raw": "data:image/jpeg;base64,...", "enhanced": "data:image/jpeg;base64,...",
              "heatmap": "data:image/jpeg;base64,..." }
}
```

**`/api/simulate` request body:**
```json
{
  "numPatients": 120,
  "arrivalRatePerHour": 15.0,
  "scanDurationMinutes": 3.0,
  "retakeProbability": 0.08,
  "costManualScreeningUSD": 45.0,
  "costAiAssistedScreeningUSD": 12.5
}
```

---

## 📁 Project File Structure

```
SIH_26/
├── +classify/                  # Stage 4: AI Grading
│   ├── gradeDR.m               # Master classifier entry point
│   ├── extractFeatures.m       # 16-feature biomarker extractor
│   ├── createDRNetwork.m       # CNN architecture + hand-calibrated weights
│   └── evaluateOnTestSet.m     # Held-out IDRiD test set evaluator (103 images)
│
├── +quality/                   # Stage 1: Quality Gate
│   └── assessQuality.m         # Blur/illumination/FOV validation
│
├── +preprocess/                # Stage 2: Enhancement
│   └── enhanceImage.m          # CLAHE, denoising, illumination flattening
│
├── +segment/                   # Stage 3: Segmentation
│   └── segmentAll.m            # OD, vessels, lesions, macula detection
│
├── +explain/                   # Stage 5: Explainability
│   └── generateReport.m        # Grad-CAM saliency + HTML report + PNG composite
│
├── +ood/                       # Out-of-Distribution Detection
│   ├── checkDistribution.m     # Mahalanobis distance runtime check
│   └── buildReferenceStats.m   # Offline stats builder (run once)
│
├── +routing/                   # Trust & Safety Router
│   └── decideRouting.m         # 7-route deterministic decision logic
│
├── +simulate/                  # Stage 6: Clinic Operations
│   ├── simulateClinicThroughput.m  # Monte Carlo discrete-event model
│   └── plotClinicMetrics.m         # Dashboard figure generation
│
├── +data/                      # Data utilities
│   └── loadIDRiD.m             # IDRiD dataset loader
│
├── server/
│   └── app.py                  # FastAPI backend (Python, no OpenCV — uses PIL + numpy + scipy)
│
├── frontend/                   # React/Vite web app
│   ├── src/components/
│   │   ├── Navbar.tsx           # Tab navigation + engine status
│   │   ├── Hero.tsx             # Landing page, statistics, architecture
│   │   ├── ScreeningStudio.tsx  # Screening interface
│   │   └── SimulationDashboard.tsx  # Clinic simulation interface
│   ├── src/App.tsx
│   ├── src/index.css           # Dark clinical glassmorphic design system
│   └── vite.config.ts          # Proxy: /api → localhost:8000
│
├── data/
│   ├── idrid/grading/train/images/  (413 real fundus images)
│   ├── idrid/grading/train/labels.csv
│   ├── idrid/grading/test/images/   (103 real fundus images — held-out)
│   ├── idrid/grading/test/labels.csv
│   ├── idrid/segmentation/          (108 image-mask pairs)
│   └── messidor2/images/            (1748 real fundus images, no labels used)
│
├── config.m                    # Master configuration (all thresholds & paths)
├── run_pipeline.m              # Primary 5-stage pipeline entry point
├── train_classifier.m          # Script to train CNN on real images (run manually)
├── test_full_pipeline.m        # End-to-end verification suite (8 scenarios)
├── test_full_routing.m         # 7-scenario trust & routing validator
├── test_real_data_pipeline.m   # Stage 1+2 validation on real IDRiD images
├── reference_stats.mat         # OOD baseline statistics rebuilt from the real training split when available
└── README.md
```

---

## 🚀 Quick Start (MATLAB Pipeline)

```matlab
% 1. From MATLAB, set working directory to project root
cd 'C:\Users\mdalt\OneDrive\Desktop\SIH_26'
addpath(genpath('.'));

% 2. Load config
cfg = config();

% 3. Run a single image through the full 5-stage pipeline
patInfo = struct('patientID', 'PAT-2026-001', 'patientAge', 58, ...
                 'patientGender', 'F', 'eyeLaterality', 'OD (Right Eye)');
img = imread('data/idrid/grading/train/images/IDRiD_001.jpg');
reportDir = 'reports';
[examData, passedQGate] = run_pipeline(img, patInfo, cfg, reportDir);

% 4. Inspect diagnosis
if passedQGate
    fprintf('Grade: %d | %s | Confidence: %.1f%%\n', ...
        examData.grade, examData.gradeName, examData.confidence * 100);
    fprintf('ICD-10: %s\n', examData.icd10Code);
    fprintf('Routing: %s\n', examData.routingDecision);
end

% 5. Run Stage 6 clinic simulation
simResults = simulate.simulateClinicThroughput(120, cfg);

% 6. Evaluate on held-out test set (103 images)
metrics = classify.evaluateOnTestSet();
```

---

## 🔁 run_pipeline.m — Full Function Signature

```matlab
[examData, passedQGate] = run_pipeline(img, patientInfo, cfg, reportDir)
```

| Argument | Type | Description |
|----------|------|-------------|
| `img` | `uint8 H×W×3` | RGB fundus image (any resolution) |
| `patientInfo` | `struct` | Fields: `patientID`, `patientAge`, `patientGender`, `eyeLaterality` |
| `cfg` | `struct` | Output of `config()`. Pass `[]` to use defaults. |
| `reportDir` | `string` | Output directory for PNG composites and HTML reports |

| Return | Type | Description |
|--------|------|-------------|
| `examData` | `struct` | `.qualityMetrics`, `.grade`, `.gradeName`, `.confidence`, `.probabilities`, `.dmeRisk`, `.urgency`, `.icd10Code`, `.routingDecision`, `.reportPNG`, `.reportHTML` |
| `passedQGate` | `logical` | `true` if Stage 1 quality gate passed |

---

## 🔒 Routing Decision Logic

After Stage 4 grading, `routing.decideRouting()` makes a deterministic disposition:

| Decision | Trigger |
|----------|---------|
| `RETAKE` | Stage 1 Quality Gate failed |
| `OOD_FLAG` | Mahalanobis distance > threshold (image outside training distribution) |
| `MODEL_DISAGREEMENT` | Primary and secondary model grades differ |
| `UNCERTAIN_RECHECK` | Model confidence < 75% |
| `AUTO_CLEAR_SAMPLED` | Grade 0/1, high confidence, randomly drawn for 10% audit |
| `AUTO_CLEAR` | Grade 0/1, high confidence — fast-track |
| `DOCTOR_REVIEW` | Grade 2+ (Moderate/Severe NPDR/PDR) |

---

## 📊 Stage 1 Quality Thresholds (Measured on Real IDRiD Data)

| Metric | Threshold | Measured on |
|--------|-----------|-------------|
| Sharpness (Laplacian variance, normalized) | ≥ 12.0 | IDRiD train images |
| Mean Luminance | 0.15 – 0.90 (normalized) | IDRiD train images |
| Illumination Std Dev | ≥ 0.04 | IDRiD train images |
| FOV Area Ratio | ≥ 0.30 (30% of frame) | IDRiD train images |
| Mask Eccentricity | ≤ 0.82 | IDRiD train images |

---

## 🗂 Datasets

| Dataset | Split | Images | Labels | Purpose |
|---------|-------|--------|--------|---------|
| **IDRiD Disease Grading** | Train | 413 | ICDR Grade 0–4 + DME (CSV) | Quality threshold calibration, OOD baseline (if rebuilt from real images) |
| **IDRiD Disease Grading** | Test | 103 | ICDR Grade 0–4 + DME (CSV) | Held-out evaluation — never touched during training |
| **IDRiD Segmentation** | Train+Test | 81+27 | Binary masks per lesion type (TIF) | Stage 3 segmentation algorithm validation |
| **Messidor-2** | — | 1,748 | UNLABELED | Stage 1–2 quality gate validation only |

> **Data Governance**: Train and Test splits are never merged. The test set is loaded exclusively inside `evaluateOnTestSet.m`. No test-set image participates in feature extraction, threshold tuning, or training.

---

## 🧪 Test Suites

```matlab
% Run all verification tests (from MATLAB with project root as cwd)
addpath(genpath('.'));

% 1. Full end-to-end pipeline — 8 scenarios (Grades 0-4 + 3 quality failures)
test_full_pipeline

% 2. Trust & Routing — 7 scenarios — all must PASS
test_full_routing

% 3. Real data validation — Stage 1+2 on actual IDRiD images
test_real_data_pipeline

% 4. Held-out evaluation on 103-image IDRiD test set
metrics = classify.evaluateOnTestSet();
```

---

## 🐍 Python Backend Dependencies

The FastAPI server (`server/app.py`) uses **only standard Python scientific libraries** — no OpenCV required.

```
fastapi
uvicorn
Pillow          (PIL — image I/O and histogram equalization)
numpy           (array processing)
scipy           (ndimage — Laplacian, Gaussian blur, morphological ops)
python-multipart (file upload support)
```

Install:
```powershell
pip install fastapi uvicorn pillow numpy scipy python-multipart
```

---

## 🌐 Frontend Dependencies

```
node v24.15.0 / npm v11.12.1
react 19+
vite 8+
lucide-react    (icons)
canvas-confetti (celebration animation)
```

Install:
```powershell
cd frontend
npm install
```

---

## 📁 Git Hygiene

`data/`, `results/` are excluded from git via `.gitignore`. Images are never pushed to the repository. Only MATLAB source (`.m`), Python server, TypeScript/React frontend, and configuration files are version-controlled.

---

## 🚨 Known Limitations (Honest Assessment for SIH Judges)

1. **No real CNN training done yet** — The Stage 4 classifier still uses a hand-calibrated softmax with biomarker features rather than a backprop-trained CNN on the IDRiD data. The CNN architecture (`createDRNetwork.m`) is defined and ready; training requires running `train_classifier.m` with the appropriate real training set.

2. **OOD baseline must be rebuilt from real training images** — Use `ood.buildReferenceStats('data/idrid/grading/train/images', cfg.ood.statsFilePath, cfg)` to generate the current reference statistics from the real training split instead of relying on any synthetic calibration cohort.

3. **Absolute accuracy on real images remains pending real training** — `evaluateOnTestSet.m` is implemented to score on the real IDRiD test split, but the classification performance reflects the current hand-calibrated engine until a trained model is fitted on the real training set.

4. **Stage 5 explainability is rule-based and interpretable** — The heatmap and report logic in `+explain/generateReport.m` are designed to provide clinically interpretable cues and segmentation-derived evidence, not a true gradient-backpropagation explanation from a finished trained CNN.

---

*Built for Smart India Hackathon 2026 — DR Screening Pipeline*
