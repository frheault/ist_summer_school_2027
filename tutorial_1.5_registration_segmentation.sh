#!/bin/bash
# For pedagogical context, notes, and tips, refer to NOTEBOOK.md.
#
# ======================================================================
# dMRI Summer School - Tutorial 1.5
#
# Theme: Hands-on Registration & Segmentation
#
# Goal: To co-register structural T1w to diffusion space using ANTs,
#       and perform anatomical segmentation with FreeSurfer SynthSeg.
#
# Inputs:
#   - bids_data/sub-01/ses-01/dwi/dwi.nii.gz
#   - bids_data/sub-01/ses-01/anat/t1.nii.gz
#
# Outputs:
#   - b0.nii.gz, b0_brain.nii.gz, b0_brain_mask.nii.gz
#   - t1_synthseg.nii.gz, synthseg_in_dwi.nii.gz
#   - wm_mask.nii.gz, cc_roi.nii.gz
# ======================================================================

# Source FreeSurfer if available
if [ -n "$FREESURFER_HOME" ] && [ -f "$FREESURFER_HOME/SetUpFreeSurfer.sh" ]; then
    . "$FREESURFER_HOME/SetUpFreeSurfer.sh" > /dev/null 2>&1
fi

# Step 1: Extract b0 and brain extraction (BET)
echo "Step 1: Extracting b0 reference and brain extraction..."
dwiextract bids_data/sub-01/ses-01/dwi/dwi.nii.gz b0.nii.gz -fslgrad bids_data/sub-01/ses-01/dwi/dwi.bvec bids_data/sub-01/ses-01/dwi/dwi.bval -bzero
mrmath b0.nii.gz mean b0_mean.nii.gz -axis 3
bet b0_mean.nii.gz b0_brain.nii.gz -f 0.25 -m

# Step 2: Multimodal Affine Registration with ANTs
echo "Step 2: Registering T1w to b0 with ANTs..."
antsRegistrationSyNQuick.sh -d 3 -f b0_brain.nii.gz -m bids_data/sub-01/ses-01/anat/t1.nii.gz -t a -o t1_to_b0_

# Step 3: Anatomical Segmentation with SynthSeg
echo "Step 3: Performing anatomical segmentation with SynthSeg..."
mri_synthseg --i bids_data/sub-01/ses-01/anat/t1.nii.gz --o t1_synthseg.nii.gz --robust --parc --cpu

# Step 4: Transform segmentation into DWI space
echo "Step 4: Transforming SynthSeg parcellation to DWI space..."
antsApplyTransforms -d 3 -i t1_synthseg.nii.gz -r b0_brain.nii.gz \
    -t t1_to_b0_0GenericAffine.mat -n NearestNeighbor -o synthseg_in_dwi.nii.gz

# Step 5: Extract White Matter mask and Corpus Callosum ROI
echo "Step 5: Extracting WM mask and Corpus Callosum ROI..."
mrcalc synthseg_in_dwi.nii.gz 2 -eq synthseg_in_dwi.nii.gz 41 -eq -or wm_mask.nii.gz -datatype uint8
mrcalc synthseg_in_dwi.nii.gz 251 -eq synthseg_in_dwi.nii.gz 252 -eq -or \
       synthseg_in_dwi.nii.gz 253 -eq -or synthseg_in_dwi.nii.gz 254 -eq -or \
       synthseg_in_dwi.nii.gz 255 -eq -or cc_roi.nii.gz -datatype uint8

echo "Tutorial 1.5 complete. Inspect t1_to_b0_Warped.nii.gz and synthseg_in_dwi.nii.gz in mrview."
