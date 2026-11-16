#!/bin/bash
# See NOTEBOOK.md for study notes and quality control tips.
#
# ======================================================================
# dMRI Summer School - Tutorial 1.6 (Session 1.6)
#
# Theme: Hands-on Registration and Segmentation
#
# Goal: Extract the mean b0 image, compute a brain mask, register the
#       MNI template and T1w image to DWI space, and create ROI masks.
#
# Inputs:
#   - bids_data/sub-01/ses-01/dwi/dwi.nii.gz, dwi.bval, dwi.bvec (Tutorial 1.0)
#   - bids_data/sub-01/ses-01/anat/t1.nii.gz (Tutorial 1.0)
#   - template/mni_masked.nii.gz, template/cc.nii.gz
#
# Outputs:
#   - b0.nii.gz, b0_mean.nii.gz, b0_brain.nii.gz, b0_brain_mask.nii.gz
#   - cc_roi.nii.gz (Corpus Callosum mask from the MNI template)
#   - t1_synthseg.nii.gz, t1_brain.nii.gz, t1_to_b0.nii.gz, t1_to_b0_0GenericAffine.mat
#   - synthseg_in_dwi.nii.gz, wm_mask.nii.gz
#   - roi_precentral_l.nii.gz, roi_postcentral_l.nii.gz, roi_brainstem.nii.gz
# ======================================================================

set -e

# Step 1: Extract b0 volumes and compute the brain mask (FSL bet)
echo "Step 1: Extracting mean b0 and computing the brain mask..."
dwiextract bids_data/sub-01/ses-01/dwi/dwi.nii.gz b0.nii.gz \
    -fslgrad bids_data/sub-01/ses-01/dwi/dwi.bvec bids_data/sub-01/ses-01/dwi/dwi.bval -bzero -force
mrmath b0.nii.gz mean b0_mean.nii.gz -axis 3 -force
bet b0_mean.nii.gz b0_brain.nii.gz -f 0.25 -m

# Step 2: Register the MNI template to b0 space and transform the MNI CC mask
echo "Step 2: Registering the MNI template to b0 space..."
flirt -in template/mni_masked.nii.gz -ref b0_brain.nii.gz -omat from_mni_fsl_mat.txt -dof 12
flirt -in template/cc.nii.gz -ref b0_brain.nii.gz -applyxfm -init from_mni_fsl_mat.txt \
      -out cc_roi.nii.gz -interp nearestneighbour -datatype char

# Convert the FLIRT matrix to MRtrix format
transformconvert from_mni_fsl_mat.txt template/mni_masked.nii.gz b0_brain.nii.gz \
    flirt_import from_mni_fsl_ras_fix.txt -force

# [ANTs Alternative]
# antsRegistrationSyNQuick.sh -d 3 -f b0_brain.nii.gz -m template/mni_masked.nii.gz -t a -o from_mni_
# antsApplyTransforms -d 3 -i template/cc.nii.gz -r b0_brain.nii.gz -t from_mni_0GenericAffine.mat -n NearestNeighbor -o cc_roi.nii.gz

# Step 3: Segment the T1w image with FreeSurfer SynthSeg
# Note: SynthSeg uses ~15 GB of RAM. If this command stops with an error,
# comment out mri_synthseg, uncomment the cp line below, and run the script again:
#   cp /opt/ist2027/precomputed/t1_synthseg.nii.gz t1_synthseg.nii.gz
#   (manual install: cp precomputed/t1_synthseg.nii.gz t1_synthseg.nii.gz)
# Warning: The precomputed file is valid ONLY for the workshop T1w image.
echo "Step 3: Running SynthSeg segmentation on the T1w image..."
mri_synthseg --i bids_data/sub-01/ses-01/anat/t1.nii.gz \
             --o t1_synthseg.nii.gz \
             --robust --parc --threads 4
# cp /opt/ist2027/precomputed/t1_synthseg.nii.gz t1_synthseg.nii.gz

# Step 4: Skull-strip the T1w image and register it to b0 space (ANTs rigid: -t r)
# Exercise: Run again with '-t a' (affine) and compare the alignment.
echo "Step 4: Registering the T1w image to b0 space (ANTs rigid)..."
mrcalc bids_data/sub-01/ses-01/anat/t1.nii.gz t1_synthseg.nii.gz 0 -gt -mult t1_brain.nii.gz -force
antsRegistrationSyNQuick.sh -d 3 \
    -f b0_brain.nii.gz \
    -m t1_brain.nii.gz \
    -t r \
    -o t1_to_b0_
cp t1_to_b0_Warped.nii.gz t1_to_b0.nii.gz

# Step 5: Transform SynthSeg labels to DWI space (NearestNeighbor keeps integer labels)
# Exercise: Try '-n Linear' and inspect the false intermediate values at label borders.
echo "Step 5: Transforming SynthSeg labels to DWI space..."
antsApplyTransforms -d 3 \
    -i t1_synthseg.nii.gz \
    -r b0_brain.nii.gz \
    -t t1_to_b0_0GenericAffine.mat \
    -n NearestNeighbor \
    -u int \
    -o synthseg_in_dwi.nii.gz

# Step 6: Extract binary uint8 ROI masks from the DWI-space SynthSeg labels
# Note: SynthSeg has no Corpus Callosum label, so we use cc_roi.nii.gz from Step 2.
# SynthSeg WM labels: 2 (Left cerebral WM), 41 (Right cerebral WM)
echo "Step 6: Extracting white matter and anatomical ROI masks..."
mrcalc synthseg_in_dwi.nii.gz 2 -eq \
       synthseg_in_dwi.nii.gz 41 -eq -add \
       wm_mask.nii.gz -datatype uint8 -force

# SynthSeg labels: 1024 (Left Precentral), 1022 (Left Postcentral), 16 (Brainstem)
mrcalc synthseg_in_dwi.nii.gz 1024 -eq roi_precentral_l.nii.gz -datatype uint8 -force
mrcalc synthseg_in_dwi.nii.gz 1022 -eq roi_postcentral_l.nii.gz -datatype uint8 -force
mrcalc synthseg_in_dwi.nii.gz 16 -eq roi_brainstem.nii.gz -datatype uint8 -force

echo "Tutorial 1.6 complete. Inspect registration in mrview:"
echo "mrview b0_mean.nii.gz -overlay.load t1_to_b0.nii.gz -overlay.opacity 0.4"
