#!/bin/bash
# For pedagogical context, notes, and tips, refer to NOTEBOOK.md.
#
# ======================================================================
# dMRI Summer School - Tutorial 1.6 (Session 1.6)
#
# Theme: Hands-on Registration & Segmentation
#
# Goal: To extract b0 reference, skull-strip, co-register structural/template
#       images to diffusion space, and generate anatomical ROIs (Corpus Callosum & WM).
#
# Inputs:
#   - bids_data/sub-01/ses-01/dwi/dwi.nii.gz (from Tutorial 1.0)
#   - bids_data/sub-01/ses-01/anat/t1.nii.gz (from Tutorial 1.0)
#   - template/mni_masked.nii.gz
#   - template/cc.nii.gz
#
# Outputs:
#   - b0.nii.gz, b0_mean.nii.gz, b0_brain.nii.gz, b0_brain_mask.nii.gz
#   - t1_to_b0.nii.gz, t1_to_b0_0GenericAffine.mat
#   - synthseg_in_dwi.nii.gz, wm_mask.nii.gz
#   - cc_roi.nii.gz (Corpus Callosum seed mask, from the MNI atlas)
#   - roi_precentral_l.nii.gz, roi_postcentral_l.nii.gz, roi_brainstem.nii.gz
# ======================================================================

set -e

# Step 1: Extract b0 and brain extraction (BET)
echo "Step 1: Extracting b0 reference and brain extraction..."
dwiextract bids_data/sub-01/ses-01/dwi/dwi.nii.gz b0.nii.gz \
    -fslgrad bids_data/sub-01/ses-01/dwi/dwi.bvec bids_data/sub-01/ses-01/dwi/dwi.bval -bzero -force
mrmath b0.nii.gz mean b0_mean.nii.gz -axis 3 -force
bet b0_mean.nii.gz b0_brain.nii.gz -f 0.25 -m

# Step 2: Linear Registration of the MNI template (FLIRT / ANTs)
echo "Step 2: Registering template to diffusion space..."
# [FSL Version - Fast & robust]
flirt -in template/mni_masked.nii.gz -ref b0_brain.nii.gz -omat from_mni_fsl_mat.txt -dof 12
flirt -in template/cc.nii.gz -ref b0_brain.nii.gz -applyxfm -init from_mni_fsl_mat.txt \
      -out cc_roi.nii.gz -interp nearestneighbour -datatype char

# Convert FLIRT matrix to MRtrix format
transformconvert from_mni_fsl_mat.txt template/mni_masked.nii.gz b0_brain.nii.gz flirt_import from_mni_fsl_ras_fix.txt -force

# [ANTs Alternative]
# antsRegistrationSyNQuick.sh -d 3 -f b0_brain.nii.gz -m template/mni_masked.nii.gz -t a -o from_mni_
# antsApplyTransforms -d 3 -i template/cc.nii.gz -r b0_brain.nii.gz -t from_mni_0GenericAffine.mat -n NearestNeighbor -o cc_roi.nii.gz

# Step 3: Run SynthSeg parcellation on the T1w image
# SynthSeg needs ~15 GB of RAM. If this command is killed / crashes, replace it
# with the precomputed segmentation shipped in the Docker image, then re-run the script:
#   cp /opt/ist2027/precomputed/t1_synthseg.nii.gz t1_synthseg.nii.gz
#   (manual install: cp precomputed/t1_synthseg.nii.gz t1_synthseg.nii.gz)
# i.e. comment out the mri_synthseg command below and uncomment the cp line.
# The precomputed file is ONLY valid for the workshop T1: never use it on your own data.
echo "Step 3: Running FreeSurfer SynthSeg parcellation on T1w..."
mri_synthseg --i bids_data/sub-01/ses-01/anat/t1.nii.gz \
             --o t1_synthseg.nii.gz \
             --robust --parc --threads 4
# cp /opt/ist2027/precomputed/t1_synthseg.nii.gz t1_synthseg.nii.gz

# Step 4: Register the T1w to DWI space with ANTs (rigid: same subject, same brain)
# The fixed b0 is skull-stripped, so we skull-strip the moving T1w too (SynthSeg labels > 0).
# Exercise: re-run with '-t a' (affine) and compare; the extra scaling/shear
# parameters try to absorb EPI distortions and are less stable across runs.
echo "Step 4: Registering T1w to b0 space with ANTs rigid..."
mrcalc bids_data/sub-01/ses-01/anat/t1.nii.gz t1_synthseg.nii.gz 0 -gt -mult t1_brain.nii.gz -force
antsRegistrationSyNQuick.sh -d 3 \
    -f b0_brain.nii.gz \
    -m t1_brain.nii.gz \
    -t r \
    -o t1_to_b0_
cp t1_to_b0_Warped.nii.gz t1_to_b0.nii.gz

# Step 5: Bring the SynthSeg parcellation into DWI space (nearest-neighbor to preserve label integers)
# Counter-example: try '-n Linear' instead and look at the label boundaries (non-existent labels appear).
echo "Step 5: Transforming SynthSeg parcellation into DWI space..."
antsApplyTransforms -d 3 \
    -i t1_synthseg.nii.gz \
    -r b0_brain.nii.gz \
    -t t1_to_b0_0GenericAffine.mat \
    -n NearestNeighbor \
    -u int \
    -o synthseg_in_dwi.nii.gz

# Step 6: Extract anatomical ROIs from the DWI-space parcellation (saved as uint8 binary masks)
# SynthSeg WM label IDs: 2 (Left cerebral WM), 41 (Right cerebral WM)
# NOTE: SynthSeg has NO Corpus Callosum label (unlike FreeSurfer's aseg 251-255),
#       which is why the CC seed comes from the MNI atlas (Step 2).
echo "Step 6: Extracting WM mask and CST ROIs..."
mrcalc synthseg_in_dwi.nii.gz 2 -eq \
       synthseg_in_dwi.nii.gz 41 -eq -add \
       wm_mask.nii.gz -datatype uint8 -force

# SynthSeg label IDs: 1024 (Left Precentral), 1022 (Left Postcentral), 16 (Brainstem)
mrcalc synthseg_in_dwi.nii.gz 1024 -eq roi_precentral_l.nii.gz -datatype uint8 -force
mrcalc synthseg_in_dwi.nii.gz 1022 -eq roi_postcentral_l.nii.gz -datatype uint8 -force
mrcalc synthseg_in_dwi.nii.gz 16 -eq roi_brainstem.nii.gz -datatype uint8 -force

echo "Tutorial 1.6 complete."
echo "Generated: b0_brain.nii.gz, b0_brain_mask.nii.gz, cc_roi.nii.gz (MNI-atlas), t1_to_b0.nii.gz"
echo "           synthseg_in_dwi.nii.gz, wm_mask.nii.gz"
echo "           roi_precentral_l.nii.gz, roi_postcentral_l.nii.gz, roi_brainstem.nii.gz"
echo "QC: mrview b0_mean.nii.gz -overlay.load t1_to_b0.nii.gz -overlay.opacity 0.4"
