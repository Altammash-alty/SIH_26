# Ground-Truth Validation & Lesion Detection Audit Report
**Dataset:** IDRiD Disease Grading Training Split (Labels: `labels.csv`)  
**Resolution:** Standardized 768px long-edge  
**Validation Suite:** `validate_against_labels.m`  

---

## 1. Before vs After Numeric Comparison

| Metric | Baseline (Pre-Fix) | After Part 1 Fixes | Clinical Target (SIH 26038) |
|---|---|---|---|
| **Dark Lesion Max Size Cap** | 400 px | 2,500 px | Prevents deletion of confluent hemorrhages |
| **Bright Lesion Max Size Cap** | 600 px | 8,000 px | Prevents deletion of large exudate plaques |
| **Vessel Tree Dilated Buffer** | 1 px | 3 px | Eliminates vessel bifurcation false detections |
| **Detection Confidence Margin** | None (1.0x) | 1.3x over sensitivity | Filters boundary noise |
| **Dark Lesion Morphology Check** | Eccentricity < 0.96 | Ecc < 0.96 & Solidity > 0.70 | Eliminates stringy vessel edge artifacts |
| **Bright Lesion Yellowness Gating** | Disabled | Red/Green > 0.3, Blue < 0.6*(R+G)/2 | Discards specular glare & flash reflection |
| **Grade 0 Dark False Positive Count** | 617.9 avg lesions / image | 453.5 avg lesions / image (-26.6%) | Target: ~0 |
| **Grade 0 Bright False Positive Count**| 550.2 avg lesions / image | 380.4 avg lesions / image (-30.9%) | Target: ~0 |
| **Referable DR Sensitivity (Grade 2+)** | 100.0% (30/30) | 100.0% (30/30) | > 90.0% (Passed) |
| **Referable DR Specificity (Grade 2+)** | 0.0% (0/20) | 0.0% (0/20) | > 85.0% (Needs threshold calibration) |
| **Exact-Grade Accuracy** | 18.0% | 20.0% | Target: >75% |

---

## 2. Confusion Matrices

### Baseline (Pre-Fix):
```
Actual \ Pred    Grade 0   Grade 1   Grade 2   Grade 3   Grade 4
Grade 0             0         0         0         0        10
Grade 1             0         0         0         0        10
Grade 2             0         0         0         0        10
Grade 3             0         0         0         0        10
Grade 4             0         0         1         0         9
```

### After Part 1 Fixes:
```
Actual \ Pred    Grade 0   Grade 1   Grade 2   Grade 3   Grade 4
Grade 0             0         0         1         0         9
Grade 1             0         0         0         0        10
Grade 2             0         0         0         0        10
Grade 3             0         0         0         1         9
Grade 4             0         0         1         0         9
```

---

## 3. Direction of Classification Errors
- **Under-graded cases:** 1 / 50 (2.0%)
- **Over-graded cases:** 39 / 50 (78.0%)
- **Diagnosis:** Error direction is overwhelmingly **OVER-GRADING**. The pipeline does not undercount lesions; rather, choroidal background texture and retinal pigment variation in normal eyes (Grade 0) generate several hundred false candidates when `darkSensitivity = 0.04` and `brightSensitivity = 0.06` are applied without contrast normalization. Because `gradeDR.m` forces Grade 4 whenever `darkCount >= 50` or `quadDark >= 20`, all Grade 0 and Grade 1 images are pushed into Grade 4.

---

## 4. Part 4 Frontend Exit Verification
- **Escape Key:** Added global `keydown` event listener in `frontend/src/App.tsx`.
- **Overlay Dismiss:** Clicking outside the modal container now triggers `setScreeningOpen(false)`.
- **Sticky Header:** Added `position: sticky; top: 0; z-index: 10;` to modal header ensuring the "Close (Esc)" button remains visible regardless of vertical scroll depth.
