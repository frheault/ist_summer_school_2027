#!/bin/bash
# For pedagogical context, notes, and tips, refer to NOTEBOOK.md.
#
# ======================================================================
# dMRI Summer School - Tutorial 2.7 (Our Data)
#
# Theme: Hands-on deterministic DTI tractography
#
# Goal: Run deterministic DTI streamline tracking from a Corpus Callosum
#       anatomical seed ROI and inspect streamline geometry.
#
# Inputs:
#   - bids_data/sub-01/ses-01/dwi/dwi.nii.gz
#   - bids_data/sub-01/ses-01/dwi/dwi.bval
#   - bids_data/sub-01/ses-01/dwi/dwi.bvec
#   - fa.nii.gz (from Tutorial 2.4)
#   - b0_brain_mask.nii.gz (from Tutorial 1.5)
#   - cc_roi.nii.gz (from Tutorial 1.5)
#
# Outputs:
#   - dti_det_cc_10k.tck (Tractogram of the Corpus Callosum)
# ======================================================================

# Step 1: Threshold FA map to define tracking boundary mask
echo "Step 1: Thresholding FA map (FA > 0.1)..."
mrthreshold fa.nii.gz fa_thr.nii.gz -abs 0.1 -force

# Prepare masked DWI
mrcalc bids_data/sub-01/ses-01/dwi/dwi.nii.gz b0_brain_mask.nii.gz -mult dwi_brain.nii.gz -force
mrconvert dwi_brain.nii.gz dwi_brain.mif -fslgrad bids_data/sub-01/ses-01/dwi/dwi.bvec bids_data/sub-01/ses-01/dwi/dwi.bval -force

# Step 2: Run deterministic DTI tractography
echo "Step 2: Running deterministic DTI tractography (10,000 streamlines)..."
# [MRtrix Version]
tckgen -algorithm Tensor_Det \
       -seed_image cc_roi.nii.gz \
       -mask fa_thr.nii.gz \
       -select 10000 \
       dwi_brain.mif \
       dti_det_cc_10k.tck -force

# [scilpy Version]
# scil_tracking_local rgb.nii.gz cc_roi.nii.gz fa_thr.nii.gz dti_det_cc_10k.trk --algo eudx --nt 10000 -f

echo "Tutorial 2.7 complete. Inspect dti_det_cc_10k.tck in mrview: mrview fa.nii.gz -tractography.load dti_det_cc_10k.tck"
