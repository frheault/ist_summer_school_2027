#!/bin/bash
# See NOTEBOOK.md for study notes and quality control tips.
#
# ======================================================================
# dMRI Summer School - Tutorial 3.3 (Session 3.3 - Our Data)
#
# Theme: Hands-on Microstructure Modeling (NODDI, DKI, and Free Water)
#
# Goal: Fit NODDI and Free Water models (AMICO) and Diffusion Kurtosis
#       Imaging (DKI via DIPY) to multi-shell diffusion data.
#
# Inputs:
#   - bids_data/sub-01/ses-01/dwi/dwi.nii.gz, dwi.bval, dwi.bvec (Tutorial 1.0)
#   - b0_brain_mask.nii.gz (Tutorial 1.6)
#
# Outputs:
#   - NODDI_results/ (fit_NDI.nii.gz, fit_ODI.nii.gz, fit_FWF.nii.gz, fit_dir.nii.gz)
#   - NDI.nii.gz, ODI.nii.gz, ISOVF.nii.gz
#   - dki_mk.nii.gz, dki_ak.nii.gz, dki_rk.nii.gz
#   - freewater_results/ (fit_FW.nii.gz, fit_FiberVolume.nii.gz, DWI_corrected.nii.gz)
#   - fw.nii.gz
# ======================================================================

set -e

DWI="bids_data/sub-01/ses-01/dwi/dwi"

# Step 1: Fit the NODDI model with AMICO (~2 min)
# AMICO builds the gradient scheme file from bval and bvec automatically.
echo "Step 1: Fitting the NODDI model with AMICO..."
scil_NODDI_maps ${DWI}.nii.gz ${DWI}.bval ${DWI}.bvec \
    --mask b0_brain_mask.nii.gz --out_dir NODDI_results --processes 4 -f

# Copy the main NODDI maps to the main folder (AMICO names: NDI = ICVF, ODI = OD, FWF = ISOVF)
cp NODDI_results/fit_NDI.nii.gz NDI.nii.gz
cp NODDI_results/fit_ODI.nii.gz ODI.nii.gz
cp NODDI_results/fit_FWF.nii.gz ISOVF.nii.gz

# Step 2: Fit the Diffusion Kurtosis Imaging (DKI) model with DIPY
echo "Step 2: Fitting the DKI model with DIPY..."
scil_dki_metrics ${DWI}.nii.gz ${DWI}.bval ${DWI}.bvec \
    --mask b0_brain_mask.nii.gz \
    --mk dki_mk.nii.gz --ak dki_ak.nii.gz --rk dki_rk.nii.gz --not_all -f

# Step 3: Fit the Free Water Elimination model with AMICO (~1 min)
echo "Step 3: Fitting the Free Water model with AMICO..."
scil_freewater_maps ${DWI}.nii.gz ${DWI}.bval ${DWI}.bvec \
    --mask b0_brain_mask.nii.gz --out_dir freewater_results --processes 4 -f

cp freewater_results/fit_FW.nii.gz fw.nii.gz

echo "Tutorial 3.3 complete. Inspect NDI.nii.gz, ODI.nii.gz, dki_mk.nii.gz, and fw.nii.gz in mrview."
