#!/bin/bash
# See NOTEBOOK.md for study notes and quality control tips.
#
# ======================================================================
# dMRI Summer School - Tutorial 2.3 (Session 2.3 - Our Data)
#
# Theme: Hands-on Quality Assurance and DTI Fitting
#
# Goal: Inspect DWI headers and shells, check the brain mask, fit the
#       Diffusion Tensor (DTI) model, and compute DTI scalar maps.
#
# Inputs:
#   - bids_data/sub-01/ses-01/dwi/dwi.nii.gz, dwi.bval, dwi.bvec (Tutorial 1.0)
#   - b0_mean.nii.gz, b0_brain_mask.nii.gz (Tutorial 1.6)
#
# Outputs:
#   - b0_brain_bad.nii.gz, b0_brain_bad_mask.nii.gz (counter-example)
#   - dwi_dti.nii.gz, dwi_dti.bval, dwi_dti.bvec (b=0 and b=1000 shells)
#   - dti.nii.gz, fa.nii.gz, md.nii.gz, rd.nii.gz, ad.nii.gz, rgb.nii.gz, ev.nii.gz
# ======================================================================

set -e

DWI="bids_data/sub-01/ses-01/dwi/dwi"
GRAD="-fslgrad ${DWI}.bvec ${DWI}.bval"

# Step 1: Inspect image headers and dimensions
echo "Step 1: Inspecting DWI image headers..."
mrinfo ${DWI}.nii.gz

# [Scilpy Alternative]
# scil_header_print_info ${DWI}.nii.gz

# Step 2: Inspect b-values and number of volumes per shell
# Note: MRtrix treats b < 10 as b=0, so the six b=0.001 volumes count as b0.
echo "Step 2: Checking shells (b-values) and volume counts..."
mrinfo ${DWI}.nii.gz ${GRAD} -shell_bvalues -shell_sizes

# Step 3: Brain mask quality control
# Multiply voxel count by voxel volume (2x2x2 = 8 mm3 = 0.008 mL) to get mask volume.
# Counter-example: bet -f 0.6 is too strict and cuts into the brain tissue.
echo "Step 3: Comparing voxel counts for good (-f 0.25) vs bad (-f 0.6) brain masks..."
mrstats b0_brain_mask.nii.gz -output count -ignorezero
bet b0_mean.nii.gz b0_brain_bad.nii.gz -f 0.6 -m
mrstats b0_brain_bad_mask.nii.gz -output count -ignorezero

# Step 4: Extract the b=0 and b=1000 shells
# DTI assumes Gaussian diffusion, which is valid at low b-values (b <= 1000).
echo "Step 4: Extracting b=0 and b=1000 shells for DTI..."
dwiextract ${DWI}.nii.gz dwi_dti.nii.gz ${GRAD} -shells 0,1000 \
    -export_grad_fsl dwi_dti.bvec dwi_dti.bval -force

# Step 5: Fit the Diffusion Tensor (DTI) model
echo "Step 5: Fitting the DTI model..."
dwi2tensor dwi_dti.nii.gz dti.nii.gz \
    -mask b0_brain_mask.nii.gz \
    -fslgrad dwi_dti.bvec dwi_dti.bval -force

# [Scilpy Alternative]
# scil_dti_metrics dwi_dti.nii.gz dwi_dti.bval dwi_dti.bvec --mask b0_brain_mask.nii.gz \
#     --not_all --tensor dti.nii.gz --fa fa.nii.gz --md md.nii.gz --rgb rgb.nii.gz --evecs ev.nii.gz -f

# Step 6: Compute DTI scalar maps (FA, MD, RD, AD, RGB, and unit principal eigenvector EV)
echo "Step 6: Computing DTI scalar maps (FA, MD, RD, AD, RGB, EV)..."
tensor2metric dti.nii.gz \
    -fa fa.nii.gz \
    -adc md.nii.gz \
    -rd rd.nii.gz \
    -ad ad.nii.gz \
    -vector rgb.nii.gz \
    -mask b0_brain_mask.nii.gz \
    -force
tensor2metric dti.nii.gz -vector ev.nii.gz -modulate none -mask b0_brain_mask.nii.gz -force

# Tip: If a b-vector axis is inverted (wrong colors in rgb.nii.gz or broken tracts), flip it:
#   scil_gradients_modify_axes dwi_dti.bvec dwi_dti_flipx.bvec -1 2 3

echo "Tutorial 2.3 complete. Inspect fa.nii.gz and rgb.nii.gz in mrview."
