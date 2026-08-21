#!/bin/bash
# For pedagogical context, notes, and tips, refer to NOTEBOOK.md.
#
# ======================================================================
# dMRI Summer School - Tutorial 3.5 (Your Data)
#
# Theme: Microstructure Modeling & Fixels (Your Data)
#
# Goal: Assess multi-shell suitability of your personal dataset and fit
#       microstructure models (NODDI via AMICO, DKI via DIPY, FBA via MRtrix3).
#
# Instructions:
#   1. Set the YOUR_* variables below to point to your files.
#   2. Run this script: bash tutorial_3.5_microstructure_your_data.sh
#   3. Inspect the resulting maps (NDI, ODI, MK) and fixels in mrview.
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

# Step 1: Fit NODDI via AMICO
echo "Step 1: Fitting NODDI multi-compartment model via AMICO..."
mkdir -p "${OUT_PREFIX}_NODDI_results"
scil_NODDI_maps "$YOUR_DWI" "$YOUR_BVAL" "$YOUR_BVEC" \
    --mask "$YOUR_MASK" --out_dir "${OUT_PREFIX}_NODDI_results" -f

# Step 2: Fit DKI via DIPY
echo "Step 2: Fitting Diffusion Kurtosis Imaging (DKI) via DIPY..."
scil_dki_metrics "$YOUR_DWI" "$YOUR_BVAL" "$YOUR_BVEC" \
    --mask "$YOUR_MASK" \
    --mk "${OUT_PREFIX}_dki_mk.nii.gz" \
    --ak "${OUT_PREFIX}_dki_ak.nii.gz" \
    --rk "${OUT_PREFIX}_dki_rk.nii.gz" -f --not_all

# Step 3: Estimate fODFs & Fixels
echo "Step 3: Estimating 3-tissue response and fODFs for fixels..."
dwi2response dhollander "$YOUR_DWI" \
    "${OUT_PREFIX}_wm.txt" "${OUT_PREFIX}_gm.txt" "${OUT_PREFIX}_csf.txt" \
    -fslgrad "$YOUR_BVEC" "$YOUR_BVAL" \
    -mask "$YOUR_MASK" -force

dwi2fod msmt_csd "$YOUR_DWI" \
    "${OUT_PREFIX}_wm.txt" "${OUT_PREFIX}_wmfod.nii.gz" \
    "${OUT_PREFIX}_gm.txt" "${OUT_PREFIX}_gmfod.nii.gz" \
    "${OUT_PREFIX}_csf.txt" "${OUT_PREFIX}_csffod.nii.gz" \
    -fslgrad "$YOUR_BVEC" "$YOUR_BVAL" \
    -mask "$YOUR_MASK" -force

mkdir -p "${OUT_PREFIX}_fixel_dir"
fod2fixel "${OUT_PREFIX}_wmfod.nii.gz" "${OUT_PREFIX}_fixel_dir" \
    -afd fd.mif -peak peaks.mif -mask "$YOUR_MASK" -force

echo "Tutorial 3.5 complete. Inspect microstructure maps and fixels in mrview."
