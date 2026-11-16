#!/bin/bash
# See NOTEBOOK.md for study notes and quality control tips.
#
# ======================================================================
# dMRI Summer School - Tutorial 3.7 (Session 3.7 - Our Data)
#
# Theme: Hands-on CSD Tractography (Deterministic vs Probabilistic)
#
# Goal: Extract the b=2000 shell, estimate a single-shell response
#       function, fit SSST-CSD, and compare deterministic (SD_STREAM)
#       and probabilistic (iFOD2) tractography from the CC seed.
#
# Inputs:
#   - bids_data/sub-01/ses-01/dwi/dwi.nii.gz, dwi.bval, dwi.bvec (Tutorial 1.0)
#   - b0_brain_mask.nii.gz, cc_roi.nii.gz (Tutorial 1.6)
#   - fa_thr.nii.gz, dti_det_cc_10k.tck (Tutorial 2.6)
#
# Outputs:
#   - dwi_ssst.nii.gz, dwi_ssst.bval, dwi_ssst.bvec (b=0 and b=2000 shells)
#   - frf_ssst.txt, fodf_ssst.nii.gz
#   - csd_det_cc_10k.tck (Deterministic CSD tractogram)
#   - csd_prob_cc_10k.tck (Probabilistic CSD tractogram)
# ======================================================================

set -e

DWI="bids_data/sub-01/ses-01/dwi/dwi"

# Step 1: Extract the b=0 and b=2000 shells for Single-Shell Single-Tissue CSD (SSST-CSD)
# Note: SH order 8 (lmax 8) requires at least 45 directions; b=2000 has 60 directions.
echo "Step 1: Extracting b=0 and b=2000 shells..."
dwiextract ${DWI}.nii.gz dwi_ssst.nii.gz -fslgrad ${DWI}.bvec ${DWI}.bval -shells 0,2000 \
    -export_grad_fsl dwi_ssst.bvec dwi_ssst.bval -force

# Step 2: Estimate the single-shell fiber response function (FRF)
echo "Step 2: Estimating the single-shell response function (dwi2response tournier)..."
dwi2response tournier dwi_ssst.nii.gz frf_ssst.txt \
    -fslgrad dwi_ssst.bvec dwi_ssst.bval -mask b0_brain_mask.nii.gz -force

# Step 3: Fit the SSST-CSD model to compute fODFs
echo "Step 3: Fitting SSST-CSD (dwi2fod csd)..."
dwi2fod csd dwi_ssst.nii.gz frf_ssst.txt fodf_ssst.nii.gz \
    -fslgrad dwi_ssst.bvec dwi_ssst.bval -mask b0_brain_mask.nii.gz -force

# Step 4: Run deterministic CSD tractography (SD_STREAM follows the fODF peak)
echo "Step 4: Running deterministic CSD tractography (SD_STREAM)..."
tckgen -algorithm SD_STREAM \
       -seed_image cc_roi.nii.gz \
       -mask fa_thr.nii.gz \
       -select 10000 \
       fodf_ssst.nii.gz \
       csd_det_cc_10k.tck -force

# Step 5: Run probabilistic CSD tractography (iFOD2 samples from the fODF)
echo "Step 5: Running probabilistic CSD tractography (iFOD2)..."
tckgen -algorithm iFOD2 \
       -seed_image cc_roi.nii.gz \
       -mask fa_thr.nii.gz \
       -select 10000 \
       fodf_ssst.nii.gz \
       csd_prob_cc_10k.tck -force

# ----------------------------------------------------------------------
# [Scilpy Alternative]
# Uncomment the lines below to run the Scilpy pipeline instead of MRtrix:
# scil_frf_ssst dwi_ssst.nii.gz dwi_ssst.bval dwi_ssst.bvec frf_ssst_scil.txt --mask b0_brain_mask.nii.gz -f
# scil_fodf_ssst dwi_ssst.nii.gz dwi_ssst.bval dwi_ssst.bvec frf_ssst_scil.txt fodf_ssst_scil.nii.gz --mask b0_brain_mask.nii.gz --processes 4 -f
# scil_tracking_local fodf_ssst_scil.nii.gz cc_roi.nii.gz fa_thr.nii.gz csd_det_cc_10k.trk --algo det --nt 10000 -f
# scil_tracking_local fodf_ssst_scil.nii.gz cc_roi.nii.gz fa_thr.nii.gz csd_prob_cc_10k.trk --algo prob --nt 10000 -f
#
# Note: When reading an MRtrix fODF in Scilpy, always add --sh_basis tournier07:
# scil_tracking_local wmfod.nii.gz cc_roi.nii.gz fa_thr.nii.gz msmt_prob_cc.trk --algo prob --nt 10000 --sh_basis tournier07 -f
# ----------------------------------------------------------------------

echo "Tutorial 3.7 complete. Compare DTI and CSD tractograms in mrview:"
echo "mrview fa.nii.gz -tractography.load dti_det_cc_10k.tck -tractography.load csd_det_cc_10k.tck -tractography.load csd_prob_cc_10k.tck"
