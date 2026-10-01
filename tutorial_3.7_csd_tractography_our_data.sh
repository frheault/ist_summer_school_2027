#!/bin/bash
# For pedagogical context, notes, and tips, refer to NOTEBOOK.md.
#
# ======================================================================
# dMRI Summer School - Tutorial 3.7 (Our Data)
#
# Theme: Hands-on CSD Tractography (Deterministic vs. Probabilistic)
#
# Goal: Estimate a single-shell single-tissue (SSST) response function, fit
#       CSD, and track from the same CC seed and FA mask as Tutorial 2.6 with
#       deterministic (SD_STREAM) and probabilistic (iFOD2) algorithms.
#
# Inputs:
#   - bids_data/sub-01/ses-01/dwi/dwi.nii.gz, dwi.bval, dwi.bvec
#   - b0_brain_mask.nii.gz, cc_roi.nii.gz (from Tutorial 1.6)
#   - fa_thr.nii.gz, dti_det_cc_10k.tck (from Tutorial 2.6)
#
# Outputs:
#   - dwi_ssst.nii.gz (b=0 + b=2000 shell)
#   - frf_ssst.txt, fodf_ssst.nii.gz
#   - csd_det_cc_10k.tck (Deterministic CSD tractogram)
#   - csd_prob_cc_10k.tck (Probabilistic CSD tractogram)
# ======================================================================

set -e

DWI="bids_data/sub-01/ses-01/dwi/dwi"

# Step 1: Extract a single shell for SSST-CSD
# lmax 8 needs >= 45 directions: b=2000 has 60, b=1000 only 32 (-> lmax 6).
# Higher b-values also give sharper fODFs.
echo "Step 1: Extracting b=0 and b=2000 shells..."
dwiextract ${DWI}.nii.gz dwi_ssst.nii.gz -fslgrad ${DWI}.bvec ${DWI}.bval -shells 0,2000 \
    -export_grad_fsl dwi_ssst.bvec dwi_ssst.bval -force

# Step 2: Estimate SSST fiber response function (FRF)
echo "Step 2: Estimating SSST response function (dwi2response tournier)..."
dwi2response tournier dwi_ssst.nii.gz frf_ssst.txt \
    -fslgrad dwi_ssst.bvec dwi_ssst.bval -mask b0_brain_mask.nii.gz -force

# Step 3: Fit SSST-CSD (fODFs in the MRtrix 'tournier07' SH basis)
echo "Step 3: Fitting SSST-CSD (dwi2fod csd)..."
dwi2fod csd dwi_ssst.nii.gz frf_ssst.txt fodf_ssst.nii.gz \
    -fslgrad dwi_ssst.bvec dwi_ssst.bval -mask b0_brain_mask.nii.gz -force

# Step 4: Deterministic CSD tractography (SD_STREAM follows the fODF peak)
echo "Step 4: Running deterministic CSD tractography (SD_STREAM)..."
tckgen -algorithm SD_STREAM \
       -seed_image cc_roi.nii.gz \
       -mask fa_thr.nii.gz \
       -select 10000 \
       fodf_ssst.nii.gz \
       csd_det_cc_10k.tck -force

# Step 5: Probabilistic CSD tractography (iFOD2 samples the fODF)
echo "Step 5: Running probabilistic CSD tractography (iFOD2)..."
tckgen -algorithm iFOD2 \
       -seed_image cc_roi.nii.gz \
       -mask fa_thr.nii.gz \
       -select 10000 \
       fodf_ssst.nii.gz \
       csd_prob_cc_10k.tck -force

# ----------------------------------------------------------------------
# [scilpy Version - Alternative]
# To try the scilpy pipeline instead of MRtrix, uncomment the lines below:
# scil_frf_ssst dwi_ssst.nii.gz dwi_ssst.bval dwi_ssst.bvec frf_ssst_scil.txt --mask b0_brain_mask.nii.gz -f
# scil_fodf_ssst dwi_ssst.nii.gz dwi_ssst.bval dwi_ssst.bvec frf_ssst_scil.txt fodf_ssst_scil.nii.gz --mask b0_brain_mask.nii.gz --processes 4 -f
# scil_tracking_local fodf_ssst_scil.nii.gz cc_roi.nii.gz fa_thr.nii.gz csd_det_cc_10k.trk --algo det --nt 10000 -f
# scil_tracking_local fodf_ssst_scil.nii.gz cc_roi.nii.gz fa_thr.nii.gz csd_prob_cc_10k.trk --algo prob --nt 10000 -f
# ----------------------------------------------------------------------

# Interoperability: an MRtrix fODF (e.g. wmfod.nii.gz from Tutorial 3.4) must be
# read with --sh_basis tournier07 in scilpy, otherwise the lobes are wrong:
#   scil_tracking_local wmfod.nii.gz cc_roi.nii.gz fa_thr.nii.gz msmt_prob_cc.trk --algo prob --nt 10000 --sh_basis tournier07 -f

echo "Tutorial 3.7 complete. Compare DTI vs CSD tractograms in mrview:"
echo "mrview fa.nii.gz -tractography.load dti_det_cc_10k.tck -tractography.load csd_det_cc_10k.tck -tractography.load csd_prob_cc_10k.tck"
