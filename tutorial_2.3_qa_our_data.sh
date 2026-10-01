#!/bin/bash
# For pedagogical context, notes, and tips, refer to NOTEBOOK.md.
#
# ======================================================================
# dMRI Summer School - Tutorial 2.3 (Our Data)
#
# Theme: Hands-on quality assurance and DTI fitting
#
# Goal: Inspect data headers, fit the Diffusion Tensor model,
#       and compute quantitative scalar maps (FA, MD, RD, AD, RGB, EV).
#
# Inputs:
#   - bids_data/sub-01/ses-01/dwi/dwi.nii.gz
#   - bids_data/sub-01/ses-01/dwi/dwi.bval
#   - bids_data/sub-01/ses-01/dwi/dwi.bvec
#   - b0_mean.nii.gz, b0_brain_mask.nii.gz (from Tutorial 1.6)
#
# Outputs:
#   - dwi_dti.nii.gz (b=0 + b=1000 shell only)
#   - dti.nii.gz, fa.nii.gz, md.nii.gz, rd.nii.gz, ad.nii.gz, rgb.nii.gz, ev.nii.gz
# ======================================================================

set -e

DWI=bids_data/sub-01/ses-01/dwi/dwi
GRAD="-fslgrad ${DWI}.bvec ${DWI}.bval"

# Step 1: Inspect Headers and metadata
echo "Step 1: Inspecting DWI data headers..."
mrinfo ${DWI}.nii.gz

# [scilpy Version]
# scil_header_print_info ${DWI}.nii.gz

# Step 2: Inspect b-values and b-vectors
# Note the b=0.001 volumes: they count as b0 because dwiextract/dwi2tensor treat
# b < 10 as zero (MRtrix 'BZeroThreshold'; scilpy's equivalent is --tolerance / --b0_threshold).
echo "Step 2: Displaying shells (b-values) and their number of volumes..."
mrinfo ${DWI}.nii.gz ${GRAD} -shell_bvalues -shell_sizes

# Step 3: Brain mask QC (mask volume + bad BET counter-example)
echo "Step 3: Brain mask volume (voxel count x voxel volume)..."
VOX_MM3=$(mrinfo b0_brain_mask.nii.gz -spacing | awk '{print $1*$2*$3}')
NVOX=$(mrstats b0_brain_mask.nii.gz -output count -ignorezero)
echo "  b0_brain_mask: ${NVOX} voxels = $(echo "${NVOX} * ${VOX_MM3} / 1000" | bc) mL"
# Counter-example: a too-aggressive fractional threshold cuts into the brain.
bet b0_mean.nii.gz b0_brain_bad.nii.gz -f 0.6 -m
NVOX_BAD=$(mrstats b0_brain_bad_mask.nii.gz -output count -ignorezero)
echo "  bet -f 0.6   : ${NVOX_BAD} voxels (compare both masks in mrview)"

# Step 4: Extract the b=0 and b=1000 shells
# DTI assumes Gaussian diffusion, which only holds at low b-values (b ~ 1000).
# Fitting it on all shells (up to b=2000 here) biases MD/FA downwards.
echo "Step 4: Extracting b=0 and b=1000 shells for DTI..."
dwiextract ${DWI}.nii.gz dwi_dti.nii.gz ${GRAD} -shells 0,1000 \
    -export_grad_fsl dwi_dti.bvec dwi_dti.bval -force

# Step 5: Fit the Diffusion Tensor (DTI) Model
echo "Step 5: Fitting the Diffusion Tensor model..."
# [MRtrix Version]
dwi2tensor dwi_dti.nii.gz dti.nii.gz \
    -mask b0_brain_mask.nii.gz \
    -fslgrad dwi_dti.bvec dwi_dti.bval -force

# [scilpy Version]
# scil_dti_metrics dwi_dti.nii.gz dwi_dti.bval dwi_dti.bvec --mask b0_brain_mask.nii.gz \
#     --not_all --tensor dti.nii.gz --fa fa.nii.gz --md md.nii.gz --rgb rgb.nii.gz --evecs ev.nii.gz -f

# Step 6: Calculate DTI Scalar Maps (FA, MD, RD, AD, RGB, EV)
echo "Step 6: Calculating scalar maps (FA, MD, RD, AD, RGB, EV)..."
# [MRtrix Version]
tensor2metric dti.nii.gz \
    -fa fa.nii.gz \
    -adc md.nii.gz \
    -rd rd.nii.gz \
    -ad ad.nii.gz \
    -vector rgb.nii.gz \
    -mask b0_brain_mask.nii.gz \
    -force
# Principal eigenvector (unit length, not FA-modulated), used for FACT tracking in Tutorial 2.6
tensor2metric dti.nii.gz -vector ev.nii.gz -modulate none -mask b0_brain_mask.nii.gz -force

# How to fix a wrong b-vector orientation (e.g. CC not red, or tracking fails):
#   scil_gradients_modify_axes dwi_dti.bvec dwi_dti_flipx.bvec -1 2 3
# then re-run Steps 5-6 with the flipped file and compare the RGB maps.

echo "Tutorial 2.3 complete. Inspect fa.nii.gz and rgb.nii.gz in mrview for quality control."
