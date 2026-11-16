#!/bin/bash
# See NOTEBOOK.md for study notes and quality control tips.
#
# ======================================================================
# dMRI Summer School - Tutorial 2.5 (Session 2.5 - Your Data)
#
# Theme: Hands-on Quality Assurance and DTI Fitting (Your Data)
#
# Goal: Apply the quality assurance and DTI workflow from Tutorial 2.3
#       to your own diffusion dataset.
#
# Instructions:
#   1. Edit YOUR_DWI, YOUR_BVAL, and YOUR_BVEC below to point to your files.
#   2. Run: bash tutorial_2.5_qa_your_data.sh
#   3. Inspect your_data_fa.nii.gz and your_data_rgb.nii.gz in mrview.
# ======================================================================

set -e

# --- CONFIGURE YOUR PATHS HERE ---
YOUR_DWI="YOUR_DWI.nii.gz"
YOUR_BVAL="YOUR_DWI.bval"
YOUR_BVEC="YOUR_DWI.bvec"
YOUR_SHELLS="0,1000"   # low-b shells used for DTI (check Step 1 output)
BET_F="0.25"
OUT_PREFIX="your_data"

if [ ! -f "$YOUR_DWI" ]; then
    echo "[INFO] Edit YOUR_DWI, YOUR_BVAL, and YOUR_BVEC at the top of this script."
    echo "       Example (workshop data):"
    echo "       YOUR_DWI=\"bids_data/sub-01/ses-01/dwi/dwi.nii.gz\""
    echo "       YOUR_BVAL=\"bids_data/sub-01/ses-01/dwi/dwi.bval\""
    echo "       YOUR_BVEC=\"bids_data/sub-01/ses-01/dwi/dwi.bvec\""
    exit 0
fi

# Step 1: Inspect headers and shells
echo "Step 1: Inspecting DWI headers and shells..."
mrinfo "$YOUR_DWI"
mrinfo "$YOUR_DWI" -fslgrad "$YOUR_BVEC" "$YOUR_BVAL" -shell_bvalues -shell_sizes

# Step 2: Extract mean b0 and compute a brain mask with bet
# Note: If you already have a mask, copy it to ${OUT_PREFIX}_b0_brain_mask.nii.gz instead.
echo "Step 2: Computing the mean b0 and brain mask (bet -f ${BET_F})..."
dwiextract "$YOUR_DWI" "${OUT_PREFIX}_b0.nii.gz" -fslgrad "$YOUR_BVEC" "$YOUR_BVAL" -bzero -force
mrmath "${OUT_PREFIX}_b0.nii.gz" mean "${OUT_PREFIX}_b0_mean.nii.gz" -axis 3 -force
bet "${OUT_PREFIX}_b0_mean.nii.gz" "${OUT_PREFIX}_b0_brain.nii.gz" -f "$BET_F" -m

# Step 3: Extract the low-b shell(s) and fit the DTI model
echo "Step 3: Extracting shells (${YOUR_SHELLS}) and fitting the DTI model..."
dwiextract "$YOUR_DWI" "${OUT_PREFIX}_dwi_dti.nii.gz" -fslgrad "$YOUR_BVEC" "$YOUR_BVAL" \
    -shells "$YOUR_SHELLS" -export_grad_fsl "${OUT_PREFIX}_dwi_dti.bvec" "${OUT_PREFIX}_dwi_dti.bval" -force
dwi2tensor "${OUT_PREFIX}_dwi_dti.nii.gz" "${OUT_PREFIX}_dti.nii.gz" \
    -mask "${OUT_PREFIX}_b0_brain_mask.nii.gz" \
    -fslgrad "${OUT_PREFIX}_dwi_dti.bvec" "${OUT_PREFIX}_dwi_dti.bval" -force

# Step 4: Compute DTI scalar maps
echo "Step 4: Computing DTI scalar maps (FA, MD, RD, AD, RGB, EV)..."
tensor2metric "${OUT_PREFIX}_dti.nii.gz" \
    -fa "${OUT_PREFIX}_fa.nii.gz" \
    -adc "${OUT_PREFIX}_md.nii.gz" \
    -rd "${OUT_PREFIX}_rd.nii.gz" \
    -ad "${OUT_PREFIX}_ad.nii.gz" \
    -vector "${OUT_PREFIX}_rgb.nii.gz" \
    -mask "${OUT_PREFIX}_b0_brain_mask.nii.gz" -force
tensor2metric "${OUT_PREFIX}_dti.nii.gz" -vector "${OUT_PREFIX}_ev.nii.gz" -modulate none \
    -mask "${OUT_PREFIX}_b0_brain_mask.nii.gz" -force

echo "Tutorial 2.5 complete. Inspect ${OUT_PREFIX}_fa.nii.gz and ${OUT_PREFIX}_rgb.nii.gz in mrview."
