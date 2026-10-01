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
#      (Leave YOUR_MASK empty to compute one with bet.)
#   2. Run this script: bash tutorial_3.5_microstructure_fixels_your_data.sh
#   3. Inspect the resulting maps (NDI, ODI, MK) and fixels in mrview.
# ======================================================================

set -e

# --- CONFIGURE YOUR PATHS HERE ---
YOUR_DWI="YOUR_DWI.nii.gz"
YOUR_BVAL="YOUR_DWI.bval"
YOUR_BVEC="YOUR_DWI.bvec"
YOUR_MASK=""
OUT_PREFIX="your_data"

if [ ! -f "$YOUR_DWI" ]; then
    echo "[INFO] Please edit this script and specify YOUR_DWI, YOUR_BVAL, YOUR_BVEC (and optionally YOUR_MASK)."
    echo "       Example (workshop data), edit these lines at the top of the file:"
    echo "       YOUR_DWI=\"bids_data/sub-01/ses-01/dwi/dwi.nii.gz\"  YOUR_BVAL=\"...dwi.bval\"  YOUR_BVEC=\"...dwi.bvec\""
    exit 0
fi

export OMP_NUM_THREADS=4
export MRTRIX_NTHREADS=4

# Step 0: Inspect shells (NODDI and DKI require >= 2 non-zero shells)
# Single-shell data (e.g. b=0 + b=1000 only): NODDI and DKI are not meaningful.
#   -> comment out Steps 1 and 2, and use the 2-tissue dwi2fod command given in Step 3.
echo "Step 0: Checking shells..."
echo "  b-values: $(mrinfo "$YOUR_DWI" -fslgrad "$YOUR_BVEC" "$YOUR_BVAL" -shell_bvalues)"
echo "  volumes : $(mrinfo "$YOUR_DWI" -fslgrad "$YOUR_BVEC" "$YOUR_BVAL" -shell_sizes)"
# Non-zero shells = b-values above MRtrix's b0 threshold (b > 10)
N_SHELLS=$(mrinfo "$YOUR_DWI" -fslgrad "$YOUR_BVEC" "$YOUR_BVAL" -shell_bvalues | \
    awk '{n=0; for (i=1; i<=NF; i++) if ($i > 10) n++; print n}')
echo "  non-zero shells: ${N_SHELLS}"
[ "$N_SHELLS" -lt 2 ] && echo "  [WARNING] Single-shell data: see the comments of Steps 1-3 before continuing."

# Brain mask: compute with bet on the mean b0
# Note: If you already have a brain mask, comment out this step and set YOUR_MASK="your_mask.nii.gz"
echo "Computing a brain mask with bet..."
dwiextract "$YOUR_DWI" - -fslgrad "$YOUR_BVEC" "$YOUR_BVAL" -bzero | \
    mrmath - mean "${OUT_PREFIX}_b0_mean.nii.gz" -axis 3 -force
bet "${OUT_PREFIX}_b0_mean.nii.gz" "${OUT_PREFIX}_b0_brain.nii.gz" -f 0.25 -m
YOUR_MASK="${OUT_PREFIX}_b0_brain_mask.nii.gz"

# Step 1: Fit NODDI via AMICO (single-shell data: comment out this step)
echo "Step 1: Fitting NODDI multi-compartment model via AMICO..."
scil_NODDI_maps "$YOUR_DWI" "$YOUR_BVAL" "$YOUR_BVEC" \
    --mask "$YOUR_MASK" --out_dir "${OUT_PREFIX}_NODDI_results" --processes 4 -f

# Step 2: Fit DKI via DIPY (single-shell data: comment out this step)
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

# 3-tissue MSMT-CSD (WM + GM + CSF) needs >= 2 non-zero shells.
# Single-shell data: replace the command below with the 2-tissue version (WM + CSF):
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

echo "Tutorial 3.5 complete. Inspect microstructure maps and fixels in mrview."
