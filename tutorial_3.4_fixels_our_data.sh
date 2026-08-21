#!/bin/bash
# For pedagogical context, notes, and tips, refer to NOTEBOOK.md.
#
# ======================================================================
# dMRI Summer School - Tutorial 3.4 (Our Data)
#
# Theme: Hands-on Fixel-Based Analysis (FBA)
#
# Goal: Segment continuous Fiber Orientation Distributions (fODFs) into
#       discrete fixels and extract Fiber Density (FD) in crossing fibers.
#
# Inputs:
#   - bids_data/sub-01/ses-01/dwi/dwi.nii.gz
#   - bids_data/sub-01/ses-01/dwi/dwi.bval
#   - bids_data/sub-01/ses-01/dwi/dwi.bvec
#   - b0_brain_mask.nii.gz
#
# Outputs:
#   - wmfod.nii.gz (White Matter fODFs)
#   - fixel_dir/ (Fixel directory with index.mif, directions.mif, fd.mif)
# ======================================================================

# Step 1: Multi-Tissue Response Function Estimation
echo "Step 1: Estimating 3-tissue response functions (dhollander)..."
dwi2response dhollander bids_data/sub-01/ses-01/dwi/dwi.nii.gz \
    wm.txt gm.txt csf.txt \
    -fslgrad bids_data/sub-01/ses-01/dwi/dwi.bvec bids_data/sub-01/ses-01/dwi/dwi.bval \
    -mask b0_brain_mask.nii.gz -force

# Step 2: Multi-Shell Multi-Tissue CSD (MSMT-CSD)
echo "Step 2: Performing MSMT-CSD to estimate fODFs..."
dwi2fod msmt_csd bids_data/sub-01/ses-01/dwi/dwi.nii.gz \
    wm.txt wmfod.nii.gz gm.txt gmfod.nii.gz csf.txt csffod.nii.gz \
    -fslgrad bids_data/sub-01/ses-01/dwi/dwi.bvec bids_data/sub-01/ses-01/dwi/dwi.bval \
    -mask b0_brain_mask.nii.gz -force

# Step 3: Segment fODFs into Discrete Fixels
echo "Step 3: Segmenting fODFs into fixels (fod2fixel)..."
mkdir -p fixel_dir
fod2fixel wmfod.nii.gz fixel_dir -afd fd.mif -peak peaks.mif -mask b0_brain_mask.nii.gz -force

echo "Tutorial 3.4 complete. Inspect fixels in mrview: mrview b0.nii.gz -fixel.load fixel_dir/index.mif"
