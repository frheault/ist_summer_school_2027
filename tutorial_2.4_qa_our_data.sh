#!/bin/bash
# For pedagogical context, notes, and tips, refer to NOTEBOOK.md.
#
# ======================================================================
# dMRI Summer School - Tutorial 2.4 (Our Data)
#
# Theme: Hands-on quality assurance and DTI fitting
#
# Goal: Inspect data headers, fit the Diffusion Tensor model,
#       and compute quantitative scalar maps (FA, MD, RD, AD, RGB).
#
# Inputs:
#   - bids_data/sub-01/ses-01/dwi/dwi.nii.gz
#   - bids_data/sub-01/ses-01/dwi/dwi.bval
#   - bids_data/sub-01/ses-01/dwi/dwi.bvec
#   - b0_brain_mask.nii.gz (from Tutorial 1.5)
#
# Outputs:
#   - dti.nii.gz, fa.nii.gz, md.nii.gz, rd.nii.gz, ad.nii.gz, rgb.nii.gz, ev.nii.gz
# ======================================================================

# Step 1: Inspect Headers and metadata
echo "Step 1: Inspecting DWI data headers..."
mrinfo bids_data/sub-01/ses-01/dwi/dwi.nii.gz

# [scilpy Version]
# scil_header_print_info bids_data/sub-01/ses-01/dwi/dwi.nii.gz

# Step 2: Inspect b-values and b-vectors
echo "Step 2: Displaying b-values and b-vectors (first few lines)..."
head -n 1 bids_data/sub-01/ses-01/dwi/dwi.bval
head -n 3 bids_data/sub-01/ses-01/dwi/dwi.bvec

# Step 3: Fit the Diffusion Tensor (DTI) Model
echo "Step 3: Fitting the Diffusion Tensor model..."
# [MRtrix Version]
dwi2tensor bids_data/sub-01/ses-01/dwi/dwi.nii.gz dti.nii.gz \
    -mask b0_brain_mask.nii.gz \
    -fslgrad bids_data/sub-01/ses-01/dwi/dwi.bvec bids_data/sub-01/ses-01/dwi/dwi.bval

# [scilpy Version]
# scil_dti_metrics bids_data/sub-01/ses-01/dwi/dwi.nii.gz bids_data/sub-01/ses-01/dwi/dwi.bval bids_data/sub-01/ses-01/dwi/dwi.bvec --tensor dti.nii.gz --rgb rgb.nii.gz --fa fa.nii.gz --mask b0_brain_mask.nii.gz

# Step 4: Calculate DTI Scalar Maps (FA, MD, RD, AD, RGB)
echo "Step 4: Calculating scalar maps (FA, MD, RD, AD, RGB)..."
# [MRtrix Version]
tensor2metric dti.nii.gz \
    -fa fa.nii.gz \
    -adc md.nii.gz \
    -rd rd.nii.gz \
    -ad ad.nii.gz \
    -vector rgb.nii.gz \
    -mask b0_brain_mask.nii.gz \
    -force

echo "Tutorial 2.4 complete. Inspect fa.nii.gz and rgb.nii.gz in mrview for quality control."
