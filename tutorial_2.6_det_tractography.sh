#!/bin/bash
# See NOTEBOOK.md for study notes and quality control tips.
#
# ======================================================================
# dMRI Summer School - Tutorial 2.6 (Session 2.6 - Our Data)
#
# Theme: Hands-on Deterministic DTI Tractography
#
# Goal: Create an FA tracking mask, run deterministic DTI tractography
#       from the Corpus Callosum seed mask, and inspect the tractogram.
#
# Inputs:
#   - fa.nii.gz, ev.nii.gz (Tutorial 2.3)
#   - cc_roi.nii.gz (Tutorial 1.6)
#
# Outputs:
#   - fa_thr.nii.gz (FA > 0.1 tracking mask, reused in Tutorial 3.7)
#   - dti_det_cc_10k.tck (Corpus Callosum DTI tractogram)
# ======================================================================

set -e

# Step 1: Threshold the FA map (FA > 0.1) to create a tracking mask
echo "Step 1: Creating the tracking mask (FA > 0.1)..."
mrthreshold fa.nii.gz fa_thr.nii.gz -abs 0.1 -force

# Step 2: Run deterministic DTI tractography (FACT algorithm on the principal eigenvector)
echo "Step 2: Running deterministic DTI tractography (10,000 streamlines)..."
tckgen -algorithm FACT \
       -seed_image cc_roi.nii.gz \
       -mask fa_thr.nii.gz \
       -angle 45 \
       -select 10000 \
       ev.nii.gz \
       dti_det_cc_10k.tck -force

# [MRtrix Alternative: Tensor_Det fits the tensor directly from the DWI]
# tckgen -algorithm Tensor_Det -seed_image cc_roi.nii.gz -mask fa_thr.nii.gz -select 10000 \
#        dwi_dti.nii.gz -fslgrad dwi_dti.bvec dwi_dti.bval dti_det_cc_10k.tck -force

# [Scilpy Alternative]
# scil_tracking_local ev.nii.gz cc_roi.nii.gz fa_thr.nii.gz dti_det_cc_10k.trk --algo eudx --nt 10000 -f

# Exercise: Draw a manual CC ROI on fa.nii.gz in mrview (ROI editor) or MI-Brain,
# save it as a binary uint8 NIfTI (my_cc_roi.nii.gz), and run Step 2 with -seed_image my_cc_roi.nii.gz.

echo "Tutorial 2.6 complete. Inspect the tractogram in mrview:"
echo "mrview fa.nii.gz -tractography.load dti_det_cc_10k.tck"
