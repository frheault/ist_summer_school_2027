#!/bin/bash
# See NOTEBOOK.md for study notes and quality control tips.
#
# ======================================================================
# dMRI Summer School - Tutorial 3.4 (Session 3.4 - Our Data)
#
# Theme: Hands-on Fixel-Based Analysis (FBA)
#
# Goal: Estimate multi-tissue fODFs (MSMT-CSD), segment them into fixels,
#       and compute Fiber Density (FD) and the number of fixels per voxel (NuFO).
#
# Inputs:
#   - bids_data/sub-01/ses-01/dwi/dwi.nii.gz, dwi.bval, dwi.bvec (Tutorial 1.0)
#   - b0_brain_mask.nii.gz (Tutorial 1.6), fa.nii.gz (Tutorial 2.3)
#
# Outputs:
#   - wm.txt, gm.txt, csf.txt
#   - wmfod.nii.gz, gmfod.nii.gz, csffod.nii.gz
#   - fixel_dir/ (index.mif, directions.mif, fd.mif, peak_amp.mif)
#   - nufo.nii.gz (number of fixels per voxel)
# ======================================================================

set -e

DWI="bids_data/sub-01/ses-01/dwi/dwi"

# Step 1: Estimate 3-tissue response functions (WM, GM, CSF)
echo "Step 1: Estimating 3-tissue response functions (dhollander)..."
dwi2response dhollander ${DWI}.nii.gz \
    wm.txt gm.txt csf.txt \
    -fslgrad ${DWI}.bvec ${DWI}.bval \
    -mask b0_brain_mask.nii.gz -force

# Step 2: Fit Multi-Shell Multi-Tissue CSD (MSMT-CSD) to compute white matter fODFs
# Note: CSD theory is covered in Session 3.6 and Tutorial 3.7.
echo "Step 2: Computing white matter fODFs (wmfod.nii.gz) with MSMT-CSD..."
dwi2fod msmt_csd ${DWI}.nii.gz \
    wm.txt wmfod.nii.gz gm.txt gmfod.nii.gz csf.txt csffod.nii.gz \
    -fslgrad ${DWI}.bvec ${DWI}.bval \
    -mask b0_brain_mask.nii.gz -force

# Step 3: Segment continuous fODFs into discrete fixels and compute Fiber Density (FD)
echo "Step 3: Segmenting fODFs into fixels (fod2fixel)..."
fod2fixel wmfod.nii.gz fixel_dir -afd fd.mif -peak_amp peak_amp.mif -mask b0_brain_mask.nii.gz -force

# Step 4: Count the number of fixels per voxel (NuFO)
echo "Step 4: Computing the number of fixels per voxel (nufo.nii.gz)..."
fixel2voxel fixel_dir/fd.mif count nufo.nii.gz -force

echo "Tutorial 3.4 complete. Inspect fixels and NuFO in mrview:"
echo "mrview fa.nii.gz -fixel.load fixel_dir/fd.mif -overlay.load nufo.nii.gz"
