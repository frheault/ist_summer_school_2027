#!/bin/bash
# See NOTEBOOK.md for study notes and quality control tips.
#
# ======================================================================
# dMRI Summer School - Tutorial 3.5 (Session 3.5 - Your Data)
#
# Theme: Hands-on Microstructure and Fixels (Your Data)
#
# Goal: Check the shells of your dataset and fit microstructure models
#       (NODDI, DKI, Free Water) and fixels, reusing your brain mask
#       from Tutorial 2.5.
#
# Instructions:
#   1. Edit YOUR_DWI, YOUR_BVAL, and YOUR_BVEC below to point to your files.
#      (YOUR_MASK defaults to your_data_b0_brain_mask.nii.gz from Tutorial 2.5.)
#   2. Run: bash tutorial_3.5_microstructure_fixels_your_data.sh
#   3. Inspect your microstructure maps and fixels in mrview.
# ======================================================================

set -e

# --- CONFIGURE YOUR PATHS HERE ---
YOUR_DWI="YOUR_DWI.nii.gz"
YOUR_BVAL="YOUR_DWI.bval"
YOUR_BVEC="YOUR_DWI.bvec"
YOUR_MASK="your_data_b0_brain_mask.nii.gz"   # created in Tutorial 2.5
OUT_PREFIX="your_data"

if [ ! -f "$YOUR_DWI" ]; then
    echo "[INFO] Edit YOUR_DWI, YOUR_BVAL, and YOUR_BVEC at the top of this script."
    echo "       Example (workshop data):"
    echo "       YOUR_DWI=\"bids_data/sub-01/ses-01/dwi/dwi.nii.gz\""
    echo "       YOUR_BVAL=\"bids_data/sub-01/ses-01/dwi/dwi.bval\""
    echo "       YOUR_BVEC=\"bids_data/sub-01/ses-01/dwi/dwi.bvec\""
    echo "       YOUR_MASK=\"b0_brain_mask.nii.gz\""
    exit 0
fi

# Step 1: Inspect shells
# Note: NODDI, DKI, and 3-tissue MSMT-CSD require at least 2 non-zero shells (b > 10).
# For single-shell data, comment out Steps 2 and 3, and use the 2-tissue dwi2fod command in Step 5.
echo "Step 1: Checking shells (b-values) and volume counts..."
mrinfo "$YOUR_DWI" -fslgrad "$YOUR_BVEC" "$YOUR_BVAL" -shell_bvalues -shell_sizes

# Step 2: Fit the NODDI model with AMICO (multi-shell only: comment out for single-shell data)
echo "Step 2: Fitting the NODDI model with AMICO..."
scil_NODDI_maps "$YOUR_DWI" "$YOUR_BVAL" "$YOUR_BVEC" \
    --mask "$YOUR_MASK" --out_dir "${OUT_PREFIX}_NODDI_results" --processes 4 -f

# Step 3: Fit the DKI model with DIPY (multi-shell only: comment out for single-shell data)
echo "Step 3: Fitting the DKI model with DIPY..."
scil_dki_metrics "$YOUR_DWI" "$YOUR_BVAL" "$YOUR_BVEC" \
    --mask "$YOUR_MASK" \
    --mk "${OUT_PREFIX}_dki_mk.nii.gz" \
    --ak "${OUT_PREFIX}_dki_ak.nii.gz" \
    --rk "${OUT_PREFIX}_dki_rk.nii.gz" --not_all -f

# Step 4: Fit the Free Water model with AMICO (works on single-shell and multi-shell data)
echo "Step 4: Fitting the Free Water model with AMICO..."
scil_freewater_maps "$YOUR_DWI" "$YOUR_BVAL" "$YOUR_BVEC" \
    --mask "$YOUR_MASK" --out_dir "${OUT_PREFIX}_freewater_results" --processes 4 -f

# Step 5: Estimate response functions, fODFs, and fixels
echo "Step 5: Computing 3-tissue response functions, fODFs, and fixels..."
dwi2response dhollander "$YOUR_DWI" \
    "${OUT_PREFIX}_wm.txt" "${OUT_PREFIX}_gm.txt" "${OUT_PREFIX}_csf.txt" \
    -fslgrad "$YOUR_BVEC" "$YOUR_BVAL" \
    -mask "$YOUR_MASK" -force

# Single-shell data: replace the 3-tissue command below with the 2-tissue (WM + CSF) version:
#   dwi2fod msmt_csd "$YOUR_DWI" "${OUT_PREFIX}_wm.txt" "${OUT_PREFIX}_wmfod.nii.gz" \
#       "${OUT_PREFIX}_csf.txt" "${OUT_PREFIX}_csffod.nii.gz" \
#       -fslgrad "$YOUR_BVEC" "$YOUR_BVAL" -mask "$YOUR_MASK" -force
dwi2fod msmt_csd "$YOUR_DWI" \
    "${OUT_PREFIX}_wm.txt" "${OUT_PREFIX}_wmfod.nii.gz" \
    "${OUT_PREFIX}_gm.txt" "${OUT_PREFIX}_gmfod.nii.gz" \
    "${OUT_PREFIX}_csf.txt" "${OUT_PREFIX}_csffod.nii.gz" \
    -fslgrad "$YOUR_BVEC" "$YOUR_BVAL" \
    -mask "$YOUR_MASK" -force

fod2fixel "${OUT_PREFIX}_wmfod.nii.gz" "${OUT_PREFIX}_fixel_dir" \
    -afd fd.mif -peak_amp peak_amp.mif -mask "$YOUR_MASK" -force
fixel2voxel "${OUT_PREFIX}_fixel_dir/fd.mif" count "${OUT_PREFIX}_nufo.nii.gz" -force

echo "Tutorial 3.5 complete. Inspect your microstructure maps and fixels in mrview."
