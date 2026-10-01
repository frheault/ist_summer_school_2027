#!/bin/bash
# For pedagogical context, notes, and tips, refer to NOTEBOOK.md.
#
# ======================================================================
# dMRI Summer School - Tutorial 2.5 (Your Data)
#
# Theme: Hands-on Quality Assurance and DTI Fitting (Your Data)
#
# Goal: Apply the DTI processing workflow learned in Tutorial 2.3 to
#       your personal dataset, inspecting headers, b-tables, and metrics.
#
# Instructions:
#   1. Set the YOUR_* variables below to point to your files.
#      (Leave YOUR_MASK empty to compute one with bet.)
#   2. Run this script: bash tutorial_2.5_qa_your_data.sh
#   3. Inspect the resulting FA and RGB maps in mrview.
# ======================================================================

set -e

# --- CONFIGURE YOUR PATHS HERE ---
YOUR_DWI="YOUR_DWI.nii.gz"
YOUR_BVAL="YOUR_DWI.bval"
YOUR_BVEC="YOUR_DWI.bvec"
YOUR_MASK=""
YOUR_SHELLS="0,1000"   # shells used for DTI (check Step 1 output)
BET_F="0.25"
OUT_PREFIX="your_data"

if [ ! -f "$YOUR_DWI" ]; then
    echo "[INFO] Please edit this script and specify YOUR_DWI, YOUR_BVAL, YOUR_BVEC (and optionally YOUR_MASK)."
    echo "       Example (workshop data), edit these lines at the top of the file:"
    echo "       YOUR_DWI=\"bids_data/sub-01/ses-01/dwi/dwi.nii.gz\"  YOUR_BVAL=\"...dwi.bval\"  YOUR_BVEC=\"...dwi.bvec\""
    exit 0
fi

# Step 1: Inspect headers and b-table
echo "Step 1: Inspecting DWI headers and shells..."
mrinfo "$YOUR_DWI"
mrinfo "$YOUR_DWI" -fslgrad "$YOUR_BVEC" "$YOUR_BVAL" -shell_bvalues -shell_sizes

# Step 2: Brain mask (bet on the mean b0)
# Note: If you already have a brain mask, comment out this step and set YOUR_MASK="your_mask.nii.gz"
echo "Step 2: Computing a brain mask with bet (-f ${BET_F})..."
dwiextract "$YOUR_DWI" - -fslgrad "$YOUR_BVEC" "$YOUR_BVAL" -bzero | \
    mrmath - mean "${OUT_PREFIX}_b0_mean.nii.gz" -axis 3 -force
bet "${OUT_PREFIX}_b0_mean.nii.gz" "${OUT_PREFIX}_b0_brain.nii.gz" -f "$BET_F" -m
YOUR_MASK="${OUT_PREFIX}_b0_brain_mask.nii.gz"

# Step 3: Extract the low-b shell(s) and fit DTI
echo "Step 3: Fitting DTI model on shells ${YOUR_SHELLS}..."
dwiextract "$YOUR_DWI" "${OUT_PREFIX}_dwi_dti.nii.gz" -fslgrad "$YOUR_BVEC" "$YOUR_BVAL" \
    -shells "$YOUR_SHELLS" -export_grad_fsl "${OUT_PREFIX}_dwi_dti.bvec" "${OUT_PREFIX}_dwi_dti.bval" -force
dwi2tensor "${OUT_PREFIX}_dwi_dti.nii.gz" "${OUT_PREFIX}_dti.nii.gz" \
    -mask "$YOUR_MASK" \
    -fslgrad "${OUT_PREFIX}_dwi_dti.bvec" "${OUT_PREFIX}_dwi_dti.bval" -force

# Step 4: Compute scalar maps
echo "Step 4: Calculating scalar maps (FA, MD, RD, AD, RGB, EV)..."
tensor2metric "${OUT_PREFIX}_dti.nii.gz" \
    -fa "${OUT_PREFIX}_fa.nii.gz" \
    -adc "${OUT_PREFIX}_md.nii.gz" \
    -rd "${OUT_PREFIX}_rd.nii.gz" \
    -ad "${OUT_PREFIX}_ad.nii.gz" \
    -vector "${OUT_PREFIX}_rgb.nii.gz" \
    -mask "$YOUR_MASK" -force
tensor2metric "${OUT_PREFIX}_dti.nii.gz" -vector "${OUT_PREFIX}_ev.nii.gz" -modulate none \
    -mask "$YOUR_MASK" -force

echo "Tutorial 2.5 complete. Inspect ${OUT_PREFIX}_fa.nii.gz and ${OUT_PREFIX}_rgb.nii.gz in mrview."
