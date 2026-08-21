#!/bin/bash
# For pedagogical context, notes, and tips, refer to NOTEBOOK.md.
#
# ======================================================================
# dMRI Summer School - Tutorial 3.3 (Our Data)
#
# Theme: Hands-on Microstructure Modeling (NODDI & DKI)
#
# Goal: Fit multi-compartment biophysical models (NODDI via AMICO)
#       and non-Gaussian diffusion models (DKI via DIPY) to multi-shell data.
#
# Inputs:
#   - bids_data/sub-01/ses-01/dwi/dwi.nii.gz
#   - bids_data/sub-01/ses-01/dwi/dwi.bval
#   - bids_data/sub-01/ses-01/dwi/dwi.bvec
#   - b0_brain_mask.nii.gz
#
# Outputs:
#   - NDI.nii.gz, ODI.nii.gz, ISOVF.nii.gz (NODDI maps)
#   - dki_mk.nii.gz, dki_ak.nii.gz, dki_rk.nii.gz (DKI maps)
# ======================================================================

# Step 1: Fit NODDI model using AMICO / Scilpy
echo "Step 1: Fitting NODDI multi-compartment model via AMICO..."
scil_NODDI_maps bids_data/sub-01/ses-01/dwi/dwi.nii.gz \
    bids_data/sub-01/ses-01/dwi/dwi.bval bids_data/sub-01/ses-01/dwi/dwi.bvec \
    --mask b0_brain_mask.nii.gz --out_dir NODDI_results -f

# Copy main maps to root for convenient downstream access
if [ -f "NODDI_results/FIT_ICVF.nii.gz" ]; then
    cp NODDI_results/FIT_ICVF.nii.gz NDI.nii.gz
    cp NODDI_results/FIT_OD.nii.gz ODI.nii.gz
    cp NODDI_results/FIT_ISOVF.nii.gz ISOVF.nii.gz
fi

# Step 2: Fit Diffusion Kurtosis Imaging (DKI) using DIPY / Scilpy
echo "Step 2: Fitting Diffusion Kurtosis Imaging (DKI) via DIPY..."
scil_dki_metrics bids_data/sub-01/ses-01/dwi/dwi.nii.gz \
    bids_data/sub-01/ses-01/dwi/dwi.bval bids_data/sub-01/ses-01/dwi/dwi.bvec \
    --mask b0_brain_mask.nii.gz \
    --mk dki_mk.nii.gz --ak dki_ak.nii.gz --rk dki_rk.nii.gz -f --not_all

echo "Tutorial 3.3 complete. Inspect NDI.nii.gz, ODI.nii.gz, and dki_mk.nii.gz in mrview."
