# Retinal Lesion U-Net Segmentation Module

This directory contains the self-contained, standalone MATLAB implementation for training and evaluating a multi-class deep convolutional U-Net to segment Diabetic Retinopathy lesions from color fundus photographs.

---

## 1. Purpose & Scope
This module upgrades the Stage 3 lesion segmentation stage from classical morphological filters (top-hat / bottom-hat operations) to a learned deep convolutional neural network. 

The primary clinical objective is to resolve the high false-positive rate on healthy retinas (Grade 0), allowing the pipeline to cross the **>85% specificity** threshold at **>90% sensitivity** without missing early Grade 2 microaneurysms.

---

## 2. Dataset Constraints & Design Choices
- **Small-Dataset Constraint (81 Images Total)**:
  - IDRiD's official pixel-level segmentation dataset contains only **81 images** (54 training subset, 27 testing subset) at 4288×2848 resolution.
  - Per-lesion ground truth availability is sparse across the 81 cases: Microaneurysms ($n=81$), Hard Exudates ($n=81$), Hemorrhages ($n=80$), and Soft Exudates ($n=40$).
  - Lesion pixels occupy less than **0.5%** of total retinal area, presenting an extreme class imbalance against the background.
- **Why 5-Fold Cross-Validation Was Chosen**:
  - A single fixed train/validation split on only 54 training images would allocate merely ~10 images to validation. A single 10-image validation split has high sampling variance and cannot reliably guide architecture or hyperparameter choices.
  - 5-fold cross-validation trains 5 models on 43–44 images each, validating on 10–11 held-out images per fold, ensuring every training image is validated out-of-fold.
- **Data Augmentation**:
  - Synchronized geometric augmentation (random horizontal/vertical reflection, random rotation $\pm 25^\circ$) applied to image-mask pairs simultaneously.
  - Discrete integer class label maps are strictly transformed using **nearest-neighbor interpolation** to prevent corruption of discrete categorical indices into fractional values.
- **Class Balancing**:
  - Inverse/median frequency class weighting is incorporated into the custom pixel classification loss to prevent the network from trivially minimizing loss by predicting background everywhere.

---

## 3. Class-Mapping Convention
Discrete multi-class pixel label maps adhere strictly to:
- **0**: Background (normal retinal tissue, vascular tree, optic disc)
- **1**: Microaneurysms (MA) — *Dark Lesions*
- **2**: Hemorrhages (HE) — *Dark Lesions*
- **3**: Hard Exudates (EX) — *Bright Lesions*
- **4**: Soft Exudates / Cotton Wool Spots (SE) — *Bright Lesions*

The downstream interface [`unet_to_lesion_counts.m`](file:///c:/Users/mdalt/OneDrive/Desktop/SIH_26/segmentation_unet/unet_to_lesion_counts.m) maps:
$$\text{Dark Lesions} = (\text{MA} \cup \text{HE}), \quad \text{Bright Lesions} = (\text{EX} \cup \text{SE})$$
producing identical output structures (`darkCount`, `brightCount`, `quadrantDarkCount`, `quadrantBrightCount`, etc.) for seamless ingestion into [`gradeDR.m`](file:///c:/Users/mdalt/OneDrive/Desktop/SIH_26/pipeline/+classify/gradeDR.m).

---

## 4. Module Contents
1. [`prepare_unet_data.m`](file:///c:/Users/mdalt/OneDrive/Desktop/SIH_26/segmentation_unet/prepare_unet_data.m): Locates IDRiD masks, fuses separate binary lesion masks into one multi-class ground truth map, resizes both image and mask to the pipeline's 768px resolution, and caches `imageDatastore` / `pixelLabelDatastore` pairs.
2. [`train_unet_lesion_segmenter.m`](file:///c:/Users/mdalt/OneDrive/Desktop/SIH_26/segmentation_unet/train_unet_lesion_segmenter.m): Constructs U-Net via `unetLayers()`, configures inverse-frequency class weights, applies synchronized augmentation, and sets up 5-fold cross-validation with early stopping.
3. [`evaluate_unet_segmenter.m`](file:///c:/Users/mdalt/OneDrive/Desktop/SIH_26/segmentation_unet/evaluate_unet_segmenter.m): Evaluates trained fold models and test set using `semanticseg()` and `evaluateSemanticSegmentation()`, outputting per-class Dice and IoU metrics.
4. [`unet_to_lesion_counts.m`](file:///c:/Users/mdalt/OneDrive/Desktop/SIH_26/segmentation_unet/unet_to_lesion_counts.m): Converts network prediction masks into clinical biomarker counts and ETDRS 4-quadrant distributions matching [`segmentLesions.m`](file:///c:/Users/mdalt/OneDrive/Desktop/SIH_26/pipeline/+segment/segmentLesions.m).

---

## 5. Execution Workflow
> *Note: Run instructions added after folder reorganization is confirmed.*
