#!/bin/bash
# For pedagogical context, notes, and tips, refer to NOTEBOOK.md.
#
# ======================================================================
# dMRI Summer School - Tutorial 3.7 (Our Data)
#
# Theme: Hands-on CSD Tractography (Deterministic vs. Probabilistic)
#
# Goal: Run state-of-the-art spherical deconvolution tractography
#       using both deterministic (iFOD1) and probabilistic (iFOD2) algorithms.
#
# Inputs:
#   - wmfod.nii.gz (from Tutorial 3.4)
#   - b0_brain_mask.nii.gz
#   - cc_roi.nii.gz
#
# Outputs:
#   - csd_det_cc_10k.tck (Deterministic CSD tractogram)
#   - csd_prob_cc_10k.tck (Probabilistic CSD tractogram)
# ======================================================================

# Step 1: Run Deterministic CSD Tractography (iFOD1 / SD_STREAM)
echo "Step 1: Running deterministic CSD tractography (iFOD1)..."
tckgen -algorithm iFOD1 \
       -seed_image cc_roi.nii.gz \
       -mask b0_brain_mask.nii.gz \
       -select 10000 \
       wmfod.nii.gz \
       csd_det_cc_10k.tck -force

# Step 2: Run Probabilistic CSD Tractography (iFOD2)
echo "Step 2: Running probabilistic CSD tractography (iFOD2)..."
tckgen -algorithm iFOD2 \
       -seed_image cc_roi.nii.gz \
       -mask b0_brain_mask.nii.gz \
       -select 10000 \
       wmfod.nii.gz \
       csd_prob_cc_10k.tck -force

# [scilpy Version]
# scil_tracking_local wmfod.nii.gz cc_roi.nii.gz b0_brain_mask.nii.gz csd_prob_cc_10k.tck --algo prob --nt 10000 --sh_basis tournier07 -f

echo "Tutorial 3.7 complete. Compare DTI vs CSD tractograms in mrview:"
echo "mrview fa.nii.gz -tractography.load csd_det_cc_10k.tck -tractography.load csd_prob_cc_10k.tck"
