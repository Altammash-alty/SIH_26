#!/usr/bin/env python3
"""
organize_datasets.py
--------------------
Organizes extracted fundus datasets (IDRiD Segmentation, IDRiD Disease Grading,
and Messidor-2) into a clean, pipeline-ready directory structure under data/.

Modes:
  --dry-run   (Default) Inspects source folders, counts files, validates pairings,
              and prints a full inventory report WITHOUT copying anything.
  --copy      Executes safe copying into data/ structure without altering original sources.

Target Structure:
data/
├── idrid/
│   ├── segmentation/
│   │   ├── microaneurysms/    (images/, masks/)
│   │   ├── hemorrhages/       (images/, masks/)
│   │   ├── hard_exudates/     (images/, masks/)
│   │   ├── soft_exudates/     (images/, masks/)
│   │   └── optic_disc/        (images/, masks/)
│   ├── grading/
│   │   ├── train/             (images/, labels.csv)
│   │   └── test/              (images/, labels.csv)
├── messidor2/
│   ├── images/
│   └── labels.csv             (if found)
└── models/                    (empty directory for trained models)
"""

import os
import sys
import shutil
import argparse
import csv
from pathlib import Path

# Force UTF-8 on Windows terminal
if sys.platform == 'win32':
    try:
        sys.stdout.reconfigure(encoding='utf-8')
    except Exception:
        pass


def find_source_paths(workspace_root):
    """Dynamically locate extracted dataset folders under workspace_root."""
    dataset_dir = os.path.join(workspace_root, 'dataset')
    
    paths = {
        'workspace': workspace_root,
        'dataset_root': dataset_dir,
        'idrid_seg': None,
        'idrid_grading': None,
        'messidor2_images': None,
        'messidor2_labels': None
    }
    
    # Locate IDRiD Segmentation
    # Expected pattern: A. Segmentation/A. Segmentation/
    candidate_seg = [
        os.path.join(dataset_dir, 'A. Segmentation', 'A. Segmentation'),
        os.path.join(dataset_dir, 'A. Segmentation'),
        os.path.join(dataset_dir, 'idrid_segmentation')
    ]
    for c in candidate_seg:
        if os.path.exists(os.path.join(c, '1. Original Images')) or os.path.exists(os.path.join(c, '2. All Segmentation Groundtruths')):
            paths['idrid_seg'] = c
            break
            
    # Locate IDRiD Disease Grading
    # Expected pattern: B. Disease Grading/B. Disease Grading/
    candidate_grading = [
        os.path.join(dataset_dir, 'B. Disease Grading', 'B. Disease Grading'),
        os.path.join(dataset_dir, 'B. Disease Grading'),
        os.path.join(dataset_dir, 'idrid_grading')
    ]
    for c in candidate_grading:
        if os.path.exists(os.path.join(c, '1. Original Images')) and os.path.exists(os.path.join(c, '2. Groundtruths')):
            paths['idrid_grading'] = c
            break
            
    # Locate Messidor-2 Images
    # Expected pattern: messidor-2/IMAGES.zip/IMAGES or messidor-2/IMAGES
    candidate_m2 = [
        os.path.join(dataset_dir, 'messidor-2', 'IMAGES.zip', 'IMAGES'),
        os.path.join(dataset_dir, 'messidor-2', 'IMAGES'),
        os.path.join(dataset_dir, 'messidor-2')
    ]
    for c in candidate_m2:
        if os.path.exists(c):
            png_count = len([f for f in os.listdir(c) if f.lower().endswith(('.png', '.jpg', '.tif'))])
            if png_count > 100:
                paths['messidor2_images'] = c
                break

    # Look for any CSV file that might be Messidor-2 labels
    if os.path.exists(os.path.join(dataset_dir, 'messidor-2')):
        for root, _, files in os.walk(os.path.join(dataset_dir, 'messidor-2')):
            for f in files:
                if f.lower().endswith('.csv'):
                    paths['messidor2_labels'] = os.path.join(root, f)
                    break

    return paths


def inventory_and_plan(paths):
    """Scans all sources, validates pairings, and builds explicit copy operations."""
    plan = {
        'idrid_grading': {'train': {'images': [], 'labels': None}, 'test': {'images': [], 'labels': None}},
        'idrid_segmentation': {
            'microaneurysms': {'images': [], 'masks': []},
            'hemorrhages': {'images': [], 'masks': []},
            'hard_exudates': {'images': [], 'masks': []},
            'soft_exudates': {'images': [], 'masks': []},
            'optic_disc': {'images': [], 'masks': []}
        },
        'messidor2': {'images': [], 'labels': paths.get('messidor2_labels')},
        'validation_warnings': [],
        'stats': {}
    }

    # =========================================================================
    # 1. INVENTORY IDRiD DISEASE GRADING
    # =========================================================================
    seg_root = paths['idrid_seg']
    grad_root = paths['idrid_grading']
    
    if grad_root and os.path.exists(grad_root):
        orig_img_dir = os.path.join(grad_root, '1. Original Images')
        groundtruth_dir = os.path.join(grad_root, '2. Groundtruths')
        
        # Training Set
        train_img_dir = os.path.join(orig_img_dir, 'a. Training Set')
        train_csv_file = os.path.join(groundtruth_dir, 'a. IDRiD_Disease Grading_Training Labels.csv')
        if os.path.exists(train_img_dir):
            train_images = [os.path.join(train_img_dir, f) for f in os.listdir(train_img_dir) if f.lower().endswith(('.jpg', '.jpeg', '.png', '.tif'))]
            plan['idrid_grading']['train']['images'] = train_images
        if os.path.exists(train_csv_file):
            plan['idrid_grading']['train']['labels'] = train_csv_file

        # Testing Set
        test_img_dir = os.path.join(orig_img_dir, 'b. Testing Set')
        test_csv_file = os.path.join(groundtruth_dir, 'b. IDRiD_Disease Grading_Testing Labels.csv')
        if os.path.exists(test_img_dir):
            test_images = [os.path.join(test_img_dir, f) for f in os.listdir(test_img_dir) if f.lower().endswith(('.jpg', '.jpeg', '.png', '.tif'))]
            plan['idrid_grading']['test']['images'] = test_images
        if os.path.exists(test_csv_file):
            plan['idrid_grading']['test']['labels'] = test_csv_file

        # Validate CSV-to-Image Pairing for Training
        if plan['idrid_grading']['train']['labels'] and plan['idrid_grading']['train']['images']:
            train_img_names = {os.path.basename(f) for f in plan['idrid_grading']['train']['images']}
            train_img_stems = {Path(f).stem for f in plan['idrid_grading']['train']['images']}
            csv_rows = []
            with open(plan['idrid_grading']['train']['labels'], mode='r', encoding='utf-8-sig') as f:
                reader = csv.DictReader(f)
                for row in reader:
                    # Find image column (usually 'Image name')
                    img_id = row.get('Image name') or row.get('image_id') or list(row.values())[0]
                    if img_id:
                        csv_rows.append(img_id.strip())
            missing_in_images = [r for r in csv_rows if r not in train_img_names and r not in train_img_stems and f"{r}.jpg" not in train_img_names]
            missing_in_csv = [img for img in train_img_names if Path(img).stem not in csv_rows and img not in csv_rows]
            if missing_in_images:
                plan['validation_warnings'].append(f"IDRiD Grading Train: {len(missing_in_images)} CSV rows have no matching image on disk: {missing_in_images[:5]}")
            if missing_in_csv:
                plan['validation_warnings'].append(f"IDRiD Grading Train: {len(missing_in_csv)} images have no matching row in CSV: {missing_in_csv[:5]}")

        # Validate CSV-to-Image Pairing for Testing
        if plan['idrid_grading']['test']['labels'] and plan['idrid_grading']['test']['images']:
            test_img_names = {os.path.basename(f) for f in plan['idrid_grading']['test']['images']}
            test_img_stems = {Path(f).stem for f in plan['idrid_grading']['test']['images']}
            csv_rows = []
            with open(plan['idrid_grading']['test']['labels'], mode='r', encoding='utf-8-sig') as f:
                reader = csv.DictReader(f)
                for row in reader:
                    img_id = row.get('Image name') or row.get('image_id') or list(row.values())[0]
                    if img_id:
                        csv_rows.append(img_id.strip())
            missing_in_images = [r for r in csv_rows if r not in test_img_names and r not in test_img_stems and f"{r}.jpg" not in test_img_names]
            missing_in_csv = [img for img in test_img_names if Path(img).stem not in csv_rows and img not in csv_rows]
            if missing_in_images:
                plan['validation_warnings'].append(f"IDRiD Grading Test: {len(missing_in_images)} CSV rows have no matching image on disk: {missing_in_images[:5]}")
            if missing_in_csv:
                plan['validation_warnings'].append(f"IDRiD Grading Test: {len(missing_in_csv)} images have no matching row in CSV: {missing_in_csv[:5]}")

    # =========================================================================
    # 2. INVENTORY IDRiD SEGMENTATION
    # =========================================================================
    if seg_root and os.path.exists(seg_root):
        orig_img_root = os.path.join(seg_root, '1. Original Images')
        groundtruth_root = os.path.join(seg_root, '2. All Segmentation Groundtruths')

        # Collect all source images across Training and Testing sets
        all_seg_images_map = {} # base_stem -> full_path
        for s in ['a. Training Set', 'b. Testing Set']:
            p = os.path.join(orig_img_root, s)
            if os.path.exists(p):
                for f in os.listdir(p):
                    if f.lower().endswith(('.jpg', '.jpeg', '.png', '.tif')):
                        stem = Path(f).stem # e.g. IDRiD_01
                        all_seg_images_map[stem] = os.path.join(p, f)

        # Mapping for lesion categories
        category_map = {
            '1. Microaneurysms': 'microaneurysms',
            '2. Haemorrhages': 'hemorrhages',
            '2. Hemorrhages': 'hemorrhages',
            '3. Hard Exudates': 'hard_exudates',
            '4. Soft Exudates': 'soft_exudates',
            '5. Optic Disc': 'optic_disc'
        }

        for s in ['a. Training Set', 'b. Testing Set']:
            gt_set_dir = os.path.join(groundtruth_root, s)
            if not os.path.exists(gt_set_dir):
                continue
            for subfolder in os.listdir(gt_set_dir):
                subfolder_path = os.path.join(gt_set_dir, subfolder)
                if not os.path.isdir(subfolder_path):
                    continue
                # Match target category
                target_cat = None
                for pat, target in category_map.items():
                    if pat.lower() in subfolder.lower():
                        target_cat = target
                        break
                if not target_cat:
                    plan['validation_warnings'].append(f"Unrecognized segmentation category: {subfolder_path}")
                    continue

                # Process masks in this category
                mask_files = [f for f in os.listdir(subfolder_path) if f.lower().endswith(('.tif', '.png', '.jpg'))]
                for mf in mask_files:
                    mask_full = os.path.join(subfolder_path, mf)
                    # Deduce image stem: e.g. 'IDRiD_01_MA.tif' -> 'IDRiD_01'
                    parts = Path(mf).stem.split('_')
                    if len(parts) >= 2:
                        img_stem = f"{parts[0]}_{parts[1]}"
                    else:
                        img_stem = Path(mf).stem

                    if img_stem in all_seg_images_map:
                        img_full = all_seg_images_map[img_stem]
                        plan['idrid_segmentation'][target_cat]['masks'].append(mask_full)
                        if img_full not in plan['idrid_segmentation'][target_cat]['images']:
                            plan['idrid_segmentation'][target_cat]['images'].append(img_full)
                    else:
                        plan['validation_warnings'].append(f"Mask has no matching source image: {mask_full} (looked for {img_stem})")

    # =========================================================================
    # 3. INVENTORY MESSIDOR-2
    # =========================================================================
    m2_dir = paths['messidor2_images']
    if m2_dir and os.path.exists(m2_dir):
        m2_imgs = [os.path.join(m2_dir, f) for f in os.listdir(m2_dir) if f.lower().endswith(('.png', '.jpg', '.jpeg', '.tif'))]
        plan['messidor2']['images'] = m2_imgs

    # Calculate summary stats
    plan['stats']['grading_train_images'] = len(plan['idrid_grading']['train']['images'])
    plan['stats']['grading_test_images'] = len(plan['idrid_grading']['test']['images'])
    plan['stats']['messidor2_images'] = len(plan['messidor2']['images'])
    plan['stats']['messidor2_has_labels'] = plan['messidor2']['labels'] is not None

    for cat, data in plan['idrid_segmentation'].items():
        plan['stats'][f'seg_{cat}_images'] = len(data['images'])
        plan['stats'][f'seg_{cat}_masks'] = len(data['masks'])

    return plan


def print_inventory_report(paths, plan):
    """Prints a clear, formatted pre-execution inventory report."""
    print("=" * 80)
    print("        DATASET REORGANIZATION INVENTORY & PRE-FLIGHT CHECK")
    print("=" * 80)
    print(f"\n[WORKSPACE ROOT] : {paths['workspace']}")
    print(f"[DATASET SOURCE] : {paths['dataset_root']}\n")

    print("1. SOURCE FOLDERS LOCATED:")
    print(f"  * IDRiD Disease Grading : {paths['idrid_grading'] or '[NOT FOUND]'}")
    print(f"  * IDRiD Segmentation    : {paths['idrid_seg'] or '[NOT FOUND]'}")
    print(f"  * Messidor-2 Images     : {paths['messidor2_images'] or '[NOT FOUND]'}")
    print(f"  * Messidor-2 Labels     : {paths['messidor2_labels'] or '[NONE FOUND - Unlabeled Dataset]'}")

    print("\n" + "-" * 80)
    print("2. INVENTORY BREAKDOWN & TARGET MAPPINGS:")
    print("-" * 80)

    # Grading
    train_n = plan['stats']['grading_train_images']
    test_n = plan['stats']['grading_test_images']
    print(f"\n  [IDRiD Disease Grading]")
    print(f"  +-- Train Images : {train_n:4d} files -> data/idrid/grading/train/images/")
    print(f"  +-- Train Labels : {'YES' if plan['idrid_grading']['train']['labels'] else 'NO '} CSV   -> data/idrid/grading/train/labels.csv")
    print(f"  +-- Test Images  : {test_n:4d} files -> data/idrid/grading/test/images/")
    print(f"  \\-- Test Labels  : {'YES' if plan['idrid_grading']['test']['labels'] else 'NO '} CSV   -> data/idrid/grading/test/labels.csv")

    # Segmentation
    print(f"\n  [IDRiD Retinal Segmentation]")
    for cat in ['microaneurysms', 'hemorrhages', 'hard_exudates', 'soft_exudates', 'optic_disc']:
        n_img = plan['stats'][f'seg_{cat}_images']
        n_msk = plan['stats'][f'seg_{cat}_masks']
        print(f"  +-- {cat:<16} : {n_img:2d} images, {n_msk:2d} paired masks -> data/idrid/segmentation/{cat}/")

    # Messidor-2
    m2_n = plan['stats']['messidor2_images']
    print(f"\n  [Messidor-2 Dataset]")
    print(f"  +-- Total Images : {m2_n:4d} images -> data/messidor2/images/")
    if plan['messidor2']['labels']:
        print(f"  \\-- Labels CSV   : FOUND ({plan['messidor2']['labels']}) -> data/messidor2/labels.csv")
    else:
        print(f"  \\-- Labels CSV   : NOT PRESENT (Images marked as UNLABELED for Stage 1-2 & OOD use)")

    print(f"\n  [Models Output Directory]")
    print(f"  \\-- data/models/ : [EMPTY DIRECTORY] (Reserved for trained model weights)")

    # Validation & Warnings
    print("\n" + "-" * 80)
    print("3. PAIRING VALIDATION & INTEGRITY CHECKS:")
    print("-" * 80)
    if not plan['validation_warnings']:
        print("  [SUCCESS] All image-to-mask and CSV-to-image pairings verified 100% intact!")
    else:
        print(f"  [ATTENTION] {len(plan['validation_warnings'])} notices found:")
        for w in plan['validation_warnings']:
            print(f"   * {w}")

    print("\n" + "=" * 80)



def execute_copy(paths, plan):
    """Executes safe copying into data/ directory structure."""
    target_data_dir = os.path.join(paths['workspace'], 'data')
    print(f"\n[EXECUTING] Copying files to: {target_data_dir}")
    print("Note: Source files remain completely untouched.\n")

    # 1. Create Models Directory
    os.makedirs(os.path.join(target_data_dir, 'models'), exist_ok=True)

    # 2. Copy IDRiD Disease Grading
    # Train
    train_dest_img = os.path.join(target_data_dir, 'idrid', 'grading', 'train', 'images')
    os.makedirs(train_dest_img, exist_ok=True)
    for src in plan['idrid_grading']['train']['images']:
        dst = os.path.join(train_dest_img, os.path.basename(src))
        if not os.path.exists(dst):
            shutil.copy2(src, dst)
    if plan['idrid_grading']['train']['labels']:
        shutil.copy2(plan['idrid_grading']['train']['labels'],
                     os.path.join(target_data_dir, 'idrid', 'grading', 'train', 'labels.csv'))

    # Test
    test_dest_img = os.path.join(target_data_dir, 'idrid', 'grading', 'test', 'images')
    os.makedirs(test_dest_img, exist_ok=True)
    for src in plan['idrid_grading']['test']['images']:
        dst = os.path.join(test_dest_img, os.path.basename(src))
        if not os.path.exists(dst):
            shutil.copy2(src, dst)
    if plan['idrid_grading']['test']['labels']:
        shutil.copy2(plan['idrid_grading']['test']['labels'],
                     os.path.join(target_data_dir, 'idrid', 'grading', 'test', 'labels.csv'))

    # 3. Copy IDRiD Segmentation
    for cat, data in plan['idrid_segmentation'].items():
        cat_img_dir = os.path.join(target_data_dir, 'idrid', 'segmentation', cat, 'images')
        cat_msk_dir = os.path.join(target_data_dir, 'idrid', 'segmentation', cat, 'masks')
        os.makedirs(cat_img_dir, exist_ok=True)
        os.makedirs(cat_msk_dir, exist_ok=True)

        for src in data['images']:
            dst = os.path.join(cat_img_dir, os.path.basename(src))
            if not os.path.exists(dst):
                shutil.copy2(src, dst)

        for src in data['masks']:
            dst = os.path.join(cat_msk_dir, os.path.basename(src))
            if not os.path.exists(dst):
                shutil.copy2(src, dst)

    # 4. Copy Messidor-2
    m2_dest_img = os.path.join(target_data_dir, 'messidor2', 'images')
    os.makedirs(m2_dest_img, exist_ok=True)
    print(f"Copying {len(plan['messidor2']['images'])} Messidor-2 images...")
    for idx, src in enumerate(plan['messidor2']['images']):
        dst = os.path.join(m2_dest_img, os.path.basename(src))
        if not os.path.exists(dst):
            shutil.copy2(src, dst)
        if (idx + 1) % 500 == 0:
            print(f"  -> Copied {idx + 1}/{len(plan['messidor2']['images'])} images...")

    if plan['messidor2']['labels']:
        shutil.copy2(plan['messidor2']['labels'], os.path.join(target_data_dir, 'messidor2', 'labels.csv'))

    print("\n[SUCCESS] Reorganization complete! Target data/ structure is ready.")


def main():
    parser = argparse.ArgumentParser(description="Organize fundus datasets into standard pipeline data/ layout.")
    parser.add_argument('--workspace', type=str, default=os.getcwd(), help="Workspace root path containing dataset/ directory.")
    parser.add_argument('--copy', action='store_true', help="Execute the copy operation. (Default is dry-run inventory only).")
    args = parser.parse_args()

    paths = find_source_paths(args.workspace)
    plan = inventory_and_plan(paths)
    print_inventory_report(paths, plan)

    if args.copy:
        execute_copy(paths, plan)
    else:
        print("[DRY-RUN MODE] No files were modified or copied.")
        print("To execute copying, run: python organize_datasets.py --copy\n")


if __name__ == '__main__':
    main()
