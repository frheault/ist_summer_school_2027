#!/bin/bash
# For pedagogical context, notes, and tips, refer to NOTEBOOK.md.
#
# ======================================================================
# dMRI Summer School - Tutorial 3.3 (Our Data)
#
# Theme: Hands-on Microstructure Modeling (NODDI, DKI & Free Water)
#
# Goal: Fit multi-compartment biophysical models (NODDI & Free Water via AMICO)
#       and non-Gaussian diffusion models (DKI via DIPY) to multi-shell data.
#
# Inputs:
#   - bids_data/sub-01/ses-01/dwi/dwi.nii.gz
#   - bids_data/sub-01/ses-01/dwi/dwi.bval
#   - bids_data/sub-01/ses-01/dwi/dwi.bvec
#   - b0_brain_mask.nii.gz (from Tutorial 1.6)
#   - fa.nii.gz, ad.nii.gz, rd.nii.gz, md.nii.gz (from Tutorial 2.3, for priors)
#
# Outputs:
#   - NODDI_results/ (AMICO outputs: fit_NDI, fit_ODI, fit_FWF, fit_dir)
#   - NDI.nii.gz, ODI.nii.gz, ISOVF.nii.gz (NODDI maps, copied for convenience)
#   - dki_mk.nii.gz, dki_ak.nii.gz, dki_rk.nii.gz (DKI maps)
#   - para_diff.txt, iso_diff.txt (diffusivity priors from DTI)
#   - freewater_results/ (AMICO Free Water outputs: fit_FW, fit_FiberVolume, DWI_corrected)
#   - fw.nii.gz (Free Water volume fraction map)
# ======================================================================

set -e

export OMP_NUM_THREADS=4
DWI=bids_data/sub-01/ses-01/dwi/dwi

# Step 1: Fit NODDI model using AMICO / Scilpy (~2 min, ~2 GB RAM)
# AMICO builds the gradient scheme file from bval/bvec internally.
echo "Step 1: Fitting NODDI multi-compartment model via AMICO..."
scil_NODDI_maps ${DWI}.nii.gz ${DWI}.bval ${DWI}.bvec \
    --mask b0_brain_mask.nii.gz --out_dir NODDI_results --processes 4 -f

# Copy main maps to root for convenient downstream access
# (AMICO >= 2.0 names: NDI = ICVF, ODI = OD, FWF = ISOVF)
cp NODDI_results/fit_NDI.nii.gz NDI.nii.gz
cp NODDI_results/fit_ODI.nii.gz ODI.nii.gz
cp NODDI_results/fit_FWF.nii.gz ISOVF.nii.gz

# Step 2: Fit Diffusion Kurtosis Imaging (DKI) using DIPY / Scilpy
echo "Step 2: Fitting Diffusion Kurtosis Imaging (DKI) via DIPY..."
scil_dki_metrics ${DWI}.nii.gz ${DWI}.bval ${DWI}.bvec \
    --mask b0_brain_mask.nii.gz \
    --mk dki_mk.nii.gz --ak dki_ak.nii.gz --rk dki_rk.nii.gz -f --not_all

# Step 3: Diffusivity Priors & Free Water Elimination (AMICO) (~1 min, ~1.5 GB RAM)
# Estimates data-driven priors from Day 2 DTI metrics, then fits Free Water model.
echo "Step 3: Estimating diffusivity priors and fitting Free Water model..."
scil_freewater_priors fa.nii.gz ad.nii.gz rd.nii.gz md.nii.gz \
    --out_txt_1fiber_para para_diff.txt \
    --out_txt_ventricles iso_diff.txt -f

PARA=$(awk 'NR==2 {print $1}' para_diff.txt)
ISO=$(awk 'NR==2 {print $1}' iso_diff.txt)

scil_freewater_maps ${DWI}.nii.gz ${DWI}.bval ${DWI}.bvec \
    --mask b0_brain_mask.nii.gz --out_dir freewater_results \
    --para_diff "$PARA" --iso_diff "$ISO" --processes 4 -f

cp freewater_results/fit_FW.nii.gz fw.nii.gz

echo "Tutorial 3.3 complete. Inspect NDI.nii.gz, ODI.nii.gz, dki_mk.nii.gz, and fw.nii.gz in mrview."
