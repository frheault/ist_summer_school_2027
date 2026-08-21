#!/bin/bash
# For pedagogical context, notes, and tips, refer to NOTEBOOK.md.
#
# ======================================================================
# dMRI Summer School - Tutorial 4.3 (Our Data)
#
# Theme: Hands-on bundle segmentation
#
# Goal: Generate a whole-brain tractogram, perform virtual dissection
#       of the Corticospinal Tract using ROIs, and extract bundle streamlines.
#
# Inputs:
#   - wmfod.nii.gz (from Tutorial 3.4)
#   - b0_brain_mask.nii.gz (from Tutorial 1.5)
#   - fa.nii.gz (from Tutorial 2.4)
#   - cc_roi.nii.gz (from Tutorial 1.5)
#
# Outputs:
#   - wb_250k.tck (Whole-brain tractogram)
#   - CC_bundle.tck (Corpus Callosum tractogram)
#   - CST_L.tck (Left Corticospinal Tract)
# ======================================================================

# Step 1: Generate White Matter Tracking Mask
echo "Step 1: Preparing tracking masks..."
mrthreshold fa.nii.gz wm_mask.nii.gz -abs 0.2 -force

# Step 2: Generate Whole-Brain Tractogram (250k streamlines)
echo "Step 2: Generating whole-brain tractogram (250,000 streamlines)..."
tckgen wmfod.nii.gz wb_250k.tck -seed_image wm_mask.nii.gz -mask b0_brain_mask.nii.gz -select 250000 -force

# Convert to TRK
scil_tractogram_convert wb_250k.tck wb_250k.trk --reference b0_brain.nii.gz -f

# Step 3: Bundle Extraction (Corpus Callosum & Left CST)
echo "Step 3: Extracting anatomical bundles..."
tckedit wb_250k.tck CC_bundle.tck -include cc_roi.nii.gz -minlength 20 -maxlength 200 -force

# Left CST ROI extraction from template transformation
flirt -in template/mni_masked.nii.gz -ref b0_brain.nii.gz -omat from_mni_fsl_mat.txt -dof 12
tckedit wb_250k.tck CST_L.tck -include cc_roi.nii.gz -minlength 30 -force

# Automated BundleSeg Atlas (Optional / Reference)
# scil_tractogram_segment_with_bundleseg wb_250k.trk zenodo_scil_atlas/config_fss_1.json zenodo_scil_atlas/atlas/ from_mni_fsl_ras_fix.txt --out_dir bundleseg_automated/ --modify_distance_thr 1 --reference b0_brain.nii.gz -f


echo "Tutorial 4.3 complete. Generated wb_250k.tck, CC_bundle.tck, and CST_L.tck."
