# RetinaAI — Content Specification
**SIH 26038 · Explainable DR Screening**
**Status: APPROVED — Canonical copy for all UI sections**

> All button labels, headings, body copy, and section eyebrows must match this file exactly. Do not paraphrase, do not add em dashes, do not use buzzwords not present below.

---

## Navbar

- **Wordmark:** RetinaAI
- **Subline:** SIH 26038
- **Nav links:** Pipeline · Workspace · Validation · Deployment
- **Primary CTA:** Screen an Image

---

## Hero Section

**Eyebrow (Caption):** ICDR Grade 0–4 · SIH 26038 · MathWorks

**Headline (Display):**
> Fundus screening that explains itself.

**Subhead (Body-lg):**
A 5-stage computer vision pipeline that assesses image quality, enhances contrast, detects retinal lesions, grades diabetic retinopathy severity on the ICDR scale, and returns a Grad-CAM attention map alongside each finding. Built for primary care and tele-ophthalmology.

**Primary CTA:** Screen an image
**Secondary CTA:** See the pipeline

**Stat strip below CTA line:**
- ICDR Grade 0–4 / severity classification
- Grad-CAM / lesion-level evidence
- IDRiD + Messidor-2 / validation datasets

---

## Trust Strip (Context Numbers)

Three factual callouts, no marketing spin:

1. **77M** — adults with diabetes in India (IDF 2023)
2. **1 : 100,000** — ophthalmologist-to-rural-population ratio
3. **90%** — of DR blindness preventable with early detection

Caption under each number: exact stat label, not a tagline.

---

## Pipeline Section

**Eyebrow:** 5-STAGE PIPELINE
**Heading:** From retinal photograph to clinical evidence.
**Body:** Each stage runs in sequence. A quality gate at Stage 1 stops processing if the image is too degraded to yield a reliable result. A human clinician remains in the loop at Stage 5.

### Stage names and descriptions (verbatim for pipeline nodes):

| Stage | Name | One-line description |
|---|---|---|
| 01 | Quality Gate | Measures focus, illumination uniformity, and field-of-view coverage. Rejects images below threshold. |
| 02 | CLAHE Enhancement | Applies contrast-limited adaptive histogram equalization on the green channel. Normalizes illumination. |
| 03 | Lesion Detection | Identifies dark lesions (microaneurysms, hemorrhages) and bright lesions (hard exudates, cotton-wool spots). |
| 04 | DR Grading | Classifies severity on the ICDR 0–4 scale using lesion counts and spatial distribution. Returns per-class probabilities. |
| 05 | Explainability | Generates a Grad-CAM saliency map. Lists lesion evidence with confidence scores. Routes result to clinician or auto-clear queue. |

---

## Clinical Workspace Section

**Eyebrow:** DIAGNOSTIC WORKBENCH
**Heading:** Run the pipeline on a real fundus photograph.
**Body:** Select an image from the IDRiD held-out test set, or upload your own. Results include quality metrics, lesion counts, grade with per-class probabilities, and a saliency map.

### Panel labels:

**Left panel — Image selection:**
- Section label: "Dataset samples"
- Upload label: "Upload a fundus photograph"
- Upload sub-label: ".jpg .png .tif — IDRiD / Messidor-2 format"
- Run button: "Run screening"
- Loading state: "Running pipeline..."

**Center panel — Image viewer:**
- Tab labels: "Raw input" | "CLAHE enhanced" | "Saliency map"
- Empty state: "Select or upload an image to begin."

**Right panel — Results:**
- Stage 1 header: "Quality gate"
- Stage 3 header: "Lesion counts"
- Stage 4 header: "DR grade"
- Stage 5 header: "Routing decision"

### Grade names (Stage 4, verbatim):

| Grade | Name |
|---|---|
| 0 | No apparent DR |
| 1 | Mild nonproliferative DR |
| 2 | Moderate nonproliferative DR |
| 3 | Severe nonproliferative DR |
| 4 | Proliferative DR |

### Routing decisions (verbatim):

| Decision | Label | Description |
|---|---|---|
| AUTO_CLEAR | Auto-clear | Non-referable finding. No doctor review required at this time. |
| DOCTOR_REVIEW | Doctor review | Referable DR detected. Added to ophthalmologist review queue. |
| OOD_FLAG | Out-of-distribution | Image statistics fall outside the training manifold. Flagged for human inspection. |
| RETAKE | Retake required | Image quality too low for a reliable result. Please capture a new image. |

---

## Explainability Section

**Eyebrow:** EXPLAINABILITY
**Heading:** Every grade is backed by visible evidence.
**Body:** The pipeline does not output a number and stop. The saliency map shows which retinal regions drove the classification. The evidence panel lists each detected lesion type, the confidence score for that finding, and whether it is above or below the decision threshold for referral.

**Evidence panel header:** Why was this image classified as Grade N?
**Confidence summary label:** Model agreement

### Lesion evidence row labels:
- Microaneurysms
- Hemorrhages
- Hard exudates
- Cotton-wool spots
- Neovascularization

---

## Validation Section

**Eyebrow:** CLINICAL VALIDATION
**Heading:** Performance targets on held-out data.
**Body:** The pipeline targets greater than 90% sensitivity and greater than 85% specificity for referable DR (ICDR Grade 2 and above), evaluated on held-out IDRiD and Messidor-2 images with ground-truth labels. Numbers below are targets; actual results depend on final training run quality and are reported honestly.

**Comparison table header:** This pipeline vs. single-technique baseline

**Metric rows:**
- Sensitivity — target 90%, single-technique baseline 76%
- Specificity — target 85%, single-technique baseline 71%

**Footnote:** Quality gate, CLAHE preprocessing, and lesion segmentation verified on real IDRiD and Messidor-2 images. Bars show target operating point versus a typical single-feature detector baseline.

---

## Deployment / Simulation Section

**Eyebrow:** CAPACITY MODEL
**Heading:** District-level throughput, not a lab number.
**Body:** A discrete-event Monte Carlo simulation models a clinic day — image acquisition, processing queue, AI inference, and doctor review — under realistic patient load. Outputs include throughput rate, average wait time, and estimated cost per screening versus unassisted manual review.

**Flow node labels:** Capture — Queue — Inference — Review

**Simulation result labels:**
- AI throughput: patients per hour
- Manual throughput: patients per hour
- Doctor time saved: percent
- Average wait time: minutes
- Estimated daily cost saving: USD

---

## Footer

**Tagline:** Built for SIH 2025, problem statement 26038. MathWorks partnership.
**Links:** Pipeline · Workspace · Validation · Deployment
**Legal note:** Research prototype. Not validated for clinical use without independent verification.
