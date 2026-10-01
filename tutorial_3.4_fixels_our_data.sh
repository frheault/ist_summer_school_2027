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
#   - b0_brain_mask.nii.gz (from Tutorial 1.6), fa.nii.gz (from Tutorial 2.3)
#
# Outputs:
#   - wmfod.nii.gz (White Matter fODFs, MSMT-CSD)
#   - fixel_dir/ (Fixel directory with index.mif, directions.mif, fd.mif, peak_amp.mif)
#   - nufo.nii.gz (Number of fixels per voxel)
# ======================================================================

set -e

DWI=bids_data/sub-01/ses-01/dwi/dwi

# Step 1: Multi-Tissue Response Function Estimation
echo "Step 1: Estimating 3-tissue response functions (dhollander)..."
dwi2response dhollander ${DWI}.nii.gz \
    wm.txt gm.txt csf.txt \
    -fslgrad ${DWI}.bvec ${DWI}.bval \
    -mask b0_brain_mask.nii.gz -force

# Step 2: Multi-Shell Multi-Tissue CSD to generate white matter fODFs (wmfod.nii.gz)
# Note: Fiber Orientation Distribution Functions (fODFs) and deconvolution theory
# will be covered in much more detail later today (Lecture 3.6 & Tutorial 3.7).
# Here, we generate wmfod.nii.gz as the required continuous input for discrete fixel segmentation.
echo "Step 2: Estimating white matter fODFs (wmfod.nii.gz) via MSMT-CSD..."
dwi2fod msmt_csd ${DWI}.nii.gz \
    wm.txt wmfod.nii.gz gm.txt gmfod.nii.gz csf.txt csffod.nii.gz \
    -fslgrad ${DWI}.bvec ${DWI}.bval \
    -mask b0_brain_mask.nii.gz -force

# Step 3: Segment fODFs into Discrete Fixels
echo "Step 3: Segmenting fODFs into fixels (fod2fixel)..."
fod2fixel wmfod.nii.gz fixel_dir -afd fd.mif -peak_amp peak_amp.mif -mask b0_brain_mask.nii.gz -force

# Step 4: Fixel vs voxel: number of fibre populations per voxel
# Compare nufo.nii.gz with fa.nii.gz: low FA in the centrum semiovale is often
# a crossing (NuFO >= 2), not a loss of "integrity".
echo "Step 4: Computing number of fixels per voxel (NuFO)..."
fixel2voxel fixel_dir/fd.mif count nufo.nii.gz -force

echo "Tutorial 3.4 complete. Inspect fixels in mrview:"
echo "mrview fa.nii.gz -fixel.load fixel_dir/fd.mif -overlay.load nufo.nii.gz"
