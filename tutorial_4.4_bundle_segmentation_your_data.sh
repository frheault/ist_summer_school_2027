#!/bin/bash
# For pedagogical context, notes, and tips, refer to NOTEBOOK.md.
#
# ======================================================================
# dMRI Summer School - Tutorial 4.4 (Your Data)
#
# Theme: Hands-on Bundle Segmentation (Your Data)
#
# Goal: Segment white matter pathways from your personal whole-brain
#       tractogram using both ROI-based dissection and automated BundleSeg.
#
# Instructions:
#   1. Set the YOUR_* variables below to point to your files.
#   2. Run this script: bash tutorial_4.4_bundle_segmentation_your_data.sh
#   3. Inspect the resulting bundles in mrview or MI-Brain.
# ======================================================================

# --- CONFIGURE YOUR PATHS HERE ---
YOUR_WB_TCK="YOUR_WB_250k.tck"
YOUR_PARCELLATION="YOUR_SYNTHSEG_IN_DWI.nii.gz"
YOUR_AFFINE="YOUR_T1_TO_B0_AFFINE.mat"
YOUR_REF="YOUR_B0_BRAIN.nii.gz"
OUT_DIR="your_bundleseg_automated"

if [ ! -f "$YOUR_WB_TCK" ]; then
    echo "[INFO] Please edit this script and specify YOUR_WB_TCK, YOUR_PARCELLATION, YOUR_AFFINE, and YOUR_REF."
    echo "       Example usage with workshop data: "
    echo "       YOUR_WB_TCK=wb_250k.tck"
    exit 0
fi

# Step 1: Automated Bundle Segmentation via BundleSeg
echo "Step 1: Running automated BundleSeg on your data..."
mkdir -p zenodo_scil_atlas
if [ ! -d "zenodo_scil_atlas/atlas" ]; then
    echo "Downloading BundleSeg atlas..."
    curl -sL https://zenodo.org/records/10103446/files/config.zip?download=1 -o config.zip
    curl -sL https://zenodo.org/records/10103446/files/atlas.zip?download=1 -o atlas.zip
    unzip -q config.zip -d zenodo_scil_atlas
    unzip -q atlas.zip -d zenodo_scil_atlas
    rm -f config.zip atlas.zip
fi

scil_tractogram_segment_with_bundleseg "$YOUR_WB_TCK" \
    zenodo_scil_atlas/config_fss_1.json \
    zenodo_scil_atlas/atlas/ \
    "$YOUR_AFFINE" \
    --out_dir "$OUT_DIR" --modify_distance_thr 1 --processes 4 --reference "$YOUR_REF" -f

echo "Tutorial 4.4 complete. Segmented bundles are located in '${OUT_DIR}'."
