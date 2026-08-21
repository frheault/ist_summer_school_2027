#!/bin/bash
# For pedagogical context, notes, and tips, refer to NOTEBOOK.md.
#
# ======================================================================
# dMRI Summer School - Tutorial 2.5 (Your Data)
#
# Theme: Hands-on Quality Assurance and DTI Fitting (Your Data)
#
# Goal: Apply the DTI processing workflow learned in Tutorial 2.4 to
#       your personal dataset, inspecting headers, b-tables, and metrics.
#
# Instructions:
#   1. Set the YOUR_* variables below to point to your files.
#   2. Run this script: bash tutorial_2.5_qa_your_data.sh
#   3. Inspect the resulting FA and RGB maps in mrview.
# ======================================================================

# --- CONFIGURE YOUR PATHS HERE ---
YOUR_DWI="YOUR_DWI.nii.gz"
YOUR_BVAL="YOUR_DWI.bval"
YOUR_BVEC="YOUR_DWI.bvec"
YOUR_MASK="YOUR_MASK.nii.gz"
OUT_PREFIX="your_data"

if [ ! -f "$YOUR_DWI" ]; then
    echo "[INFO] Please edit this script and specify YOUR_DWI, YOUR_BVAL, YOUR_BVEC, and YOUR_MASK."
    echo "       Example usage with workshop data: "
    echo "       YOUR_DWI=bids_data/sub-01/ses-01/dwi/dwi.nii.gz"
    exit 0
fi

# Step 1: Inspect headers and b-table
echo "Step 1: Inspecting DWI headers..."
mrinfo "$YOUR_DWI"

# Step 2: Fit DTI model
echo "Step 2: Fitting DTI model on your data..."
dwi2tensor "$YOUR_DWI" "${OUT_PREFIX}_dti.nii.gz" \
    -mask "$YOUR_MASK" \
    -fslgrad "$YOUR_BVEC" "$YOUR_BVAL" -force

# Step 3: Compute scalar maps
echo "Step 3: Calculating scalar maps (FA, MD, RD, AD, RGB, EV)..."
tensor2metric "${OUT_PREFIX}_dti.nii.gz" \
    -fa "${OUT_PREFIX}_fa.nii.gz" \
    -adc "${OUT_PREFIX}_md.nii.gz" \
    -rd "${OUT_PREFIX}_rd.nii.gz" \
    -ad "${OUT_PREFIX}_ad.nii.gz" \
    -vector "${OUT_PREFIX}_rgb.nii.gz" \
    -evec "${OUT_PREFIX}_ev.nii.gz" \
    -mask "$YOUR_MASK" -force

echo "Tutorial 2.5 complete. Inspect ${OUT_PREFIX}_fa.nii.gz and ${OUT_PREFIX}_rgb.nii.gz in mrview."
