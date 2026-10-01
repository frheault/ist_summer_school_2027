#!/bin/bash
# For pedagogical context, notes, and tips, refer to NOTEBOOK.md.
#
# ======================================================================
# dMRI Summer School - Tutorial 2.6 (Our Data)
#
# Theme: Hands-on deterministic DTI tractography
#
# Goal: Run deterministic DTI streamline tracking from a Corpus Callosum
#       anatomical seed ROI and inspect streamline geometry.
#
# Inputs:
#   - fa.nii.gz, ev.nii.gz (from Tutorial 2.3)
#   - cc_roi.nii.gz (from Tutorial 1.6)
#
# Outputs:
#   - fa_thr.nii.gz (FA > 0.1 tracking mask, reused in Tutorial 3.7)
#   - dti_det_cc_10k.tck (Tractogram of the Corpus Callosum)
# ======================================================================

set -e

# Step 1: Threshold FA map to define tracking boundary mask
echo "Step 1: Thresholding FA map (FA > 0.1)..."
mrthreshold fa.nii.gz fa_thr.nii.gz -abs 0.1 -force

# Step 2: Run deterministic DTI tractography
# FACT follows the principal eigenvector (ev.nii.gz) from the seed until it
# leaves the FA mask or bends more than -angle degrees between steps.
echo "Step 2: Running deterministic DTI tractography (10,000 streamlines)..."
# [MRtrix Version]
tckgen -algorithm FACT \
       -seed_image cc_roi.nii.gz \
       -mask fa_thr.nii.gz \
       -angle 45 \
       -select 10000 \
       ev.nii.gz \
       dti_det_cc_10k.tck -force

# [MRtrix alternative: Tensor_Det re-fits the tensor from the DWI on the fly]
# tckgen -algorithm Tensor_Det -seed_image cc_roi.nii.gz -mask fa_thr.nii.gz -select 10000 \
#        dwi_dti.nii.gz -fslgrad dwi_dti.bvec dwi_dti.bval dti_det_cc_10k.tck -force

# [scilpy Version] (eudx on the principal eigenvector, reference = fa.nii.gz)
# scil_tracking_local ev.nii.gz cc_roi.nii.gz fa_thr.nii.gz dti_det_cc_10k.trk --algo eudx --nt 10000 -f

# Manual seed: draw a CC ROI on the FA/RGB map (mrview ROI editor or MI-Brain),
# save it as a binary uint8 NIfTI with the same header as fa.nii.gz, and re-run
# Step 2 with -seed_image my_cc_roi.nii.gz.

echo "Tutorial 2.6 complete. Inspect dti_det_cc_10k.tck in mrview: mrview fa.nii.gz -tractography.load dti_det_cc_10k.tck"
