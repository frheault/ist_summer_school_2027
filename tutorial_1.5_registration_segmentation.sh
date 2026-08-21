#!/bin/bash
# For pedagogical context, notes, and tips, refer to NOTEBOOK.md.
#
# ======================================================================
# dMRI Summer School - Tutorial 1.5
#
# Theme: Hands-on Registration & Segmentation
#
# Goal: To extract b0 reference, skull-strip, co-register structural/template
#       images to diffusion space, and generate anatomical ROIs (Corpus Callosum & WM).
#
# Inputs:
#   - bids_data/sub-01/ses-01/dwi/dwi.nii.gz
#   - bids_data/sub-01/ses-01/anat/t1.nii.gz
#   - template/mni_masked.nii.gz
#   - template/cc.nii.gz
#
# Outputs:
#   - b0.nii.gz, b0_brain.nii.gz, b0_brain_mask.nii.gz
#   - cc_roi.nii.gz (Corpus Callosum seed mask)
#   - from_mni_fsl_ras_fix.txt (Affine transform for downstream atlas segmentation)
# ======================================================================

# Step 1: Extract b0 and brain extraction (BET)
echo "Step 1: Extracting b0 reference and brain extraction..."
dwiextract bids_data/sub-01/ses-01/dwi/dwi.nii.gz b0.nii.gz \
    -fslgrad bids_data/sub-01/ses-01/dwi/dwi.bvec bids_data/sub-01/ses-01/dwi/dwi.bval -bzero -force
mrmath b0.nii.gz mean b0_mean.nii.gz -axis 3 -force
bet b0_mean.nii.gz b0_brain.nii.gz -f 0.25 -m

# Step 2: Linear Registration (FLIRT / ANTs)
echo "Step 2: Registering template to diffusion space..."
# [FSL Version - Fast & robust]
flirt -in template/mni_masked.nii.gz -ref b0_brain.nii.gz -omat from_mni_fsl_mat.txt -dof 12
flirt -in template/cc.nii.gz -ref b0_brain.nii.gz -applyxfm -init from_mni_fsl_mat.txt -out cc_roi.nii.gz -interp nearestneighbour

# Convert FLIRT matrix to MRtrix format
transformconvert from_mni_fsl_mat.txt template/mni_masked.nii.gz b0_brain.nii.gz flirt_import from_mni_fsl_ras_fix.txt -force

# [ANTs Alternative]
# antsRegistrationSyNQuick.sh -d 3 -f b0_brain.nii.gz -m template/mni_masked.nii.gz -t a -o from_mni_
# antsApplyTransforms -d 3 -i template/cc.nii.gz -r b0_brain.nii.gz -t from_mni_0GenericAffine.mat -n NearestNeighbor -o cc_roi.nii.gz

# Step 3: Register T1w to DWI space with ANTs affine
echo "Step 3: Registering T1w to b0 space with ANTs affine..."
antsRegistrationSyNQuick.sh -d 3 \
    -f b0_brain.nii.gz \
    -m bids_data/sub-01/ses-01/anat/t1.nii.gz \
    -t a \
    -o t1_to_b0_

# Step 4: Run SynthSeg parcellation on the T1w image
echo "Step 4: Running FreeSurfer SynthSeg parcellation on T1w..."
# If this command fails (on macOS or due to RAM constraints), you can transform
# pre-computed labels from template space using flirt/ants as a fallback:
# flirt -in template/mni_masked.nii.gz -ref b0_brain.nii.gz -applyxfm -init from_mni_fsl_mat.txt -out synthseg_in_dwi.nii.gz -interp nearestneighbour
mri_synthseg --i bids_data/sub-01/ses-01/anat/t1.nii.gz \
             --o t1_synthseg.nii.gz \
             --robust --parc --threads 4


# Step 5: Bring the SynthSeg parcellation into DWI space (nearest-neighbor to preserve label integers)
echo "Step 5: Transforming SynthSeg parcellation into DWI space..."
antsApplyTransforms -d 3 \
    -i t1_synthseg.nii.gz \
    -r b0_brain.nii.gz \
    -t t1_to_b0_0GenericAffine.mat \
    -n NearestNeighbor \
    -o synthseg_in_dwi.nii.gz

# Step 6: Extract anatomical ROIs from the DWI-space parcellation
# SynthSeg WM label IDs: 2 (Left cerebral WM), 41 (Right cerebral WM)
echo "Step 6: Extracting WM mask, CC, and CST inclusion ROIs..."
mrcalc synthseg_in_dwi.nii.gz 2 -eq \
       synthseg_in_dwi.nii.gz 41 -eq -add \
       wm_mask.nii.gz -force

# SynthSeg Corpus Callosum labels: 192 (CC_Posterior) 251-255 (CC sub-divisions)
mrcalc synthseg_in_dwi.nii.gz 192 -eq \
       synthseg_in_dwi.nii.gz 251 -eq -add \
       synthseg_in_dwi.nii.gz 252 -eq -add \
       synthseg_in_dwi.nii.gz 253 -eq -add \
       synthseg_in_dwi.nii.gz 254 -eq -add \
       synthseg_in_dwi.nii.gz 255 -eq -add \
       cc_roi_synthseg.nii.gz -force

# Corticospinal Tract (CST) Left inclusion ROIs:
# SynthSeg label IDs: 1024 (Left Precentral Gyrus / Primary Motor Cortex), 16 (Brainstem)
mrcalc synthseg_in_dwi.nii.gz 1024 -eq cst_roi_precentral_l.nii.gz -force
mrcalc synthseg_in_dwi.nii.gz 16 -eq cst_roi_brainstem.nii.gz -force

echo "Tutorial 1.5 complete."
echo "Generated: b0_brain.nii.gz, b0_brain_mask.nii.gz, cc_roi.nii.gz (MNI-atlas)"
echo "           synthseg_in_dwi.nii.gz, wm_mask.nii.gz, cc_roi_synthseg.nii.gz"
echo "           cst_roi_precentral_l.nii.gz, cst_roi_brainstem.nii.gz"
