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

# Step 1: Prepare White Matter Tracking Mask
echo "Step 1: Preparing tracking masks..."
# Use SynthSeg wm_mask.nii.gz if available, otherwise generate FA threshold mask
if [ ! -f "wm_mask.nii.gz" ]; then
    mrthreshold fa.nii.gz wm_mask.nii.gz -abs 0.2 -force
fi

# Step 2: Generate Whole-Brain Tractogram (250k streamlines)
echo "Step 2: Generating whole-brain tractogram (250,000 streamlines)..."
tckgen wmfod.nii.gz wb_250k.tck -seed_image wm_mask.nii.gz -mask b0_brain_mask.nii.gz -select 250000 -force

# Convert to TRK for Scilpy compatibility
scil_tractogram_convert wb_250k.tck wb_250k.trk --reference b0_brain.nii.gz -f

# Step 3: Bundle Extraction (Corpus Callosum & Left Corticospinal Tract)
echo "Step 3: Extracting anatomical bundles (Corpus Callosum and Left CST)..."
# Corpus Callosum extraction
tckedit wb_250k.tck CC_bundle.tck -include cc_roi.nii.gz -minlength 20 -maxlength 200 -force

# Left CST ROI extraction using Motor Cortex (Precentral) and Brainstem inclusion ROIs
if [ -f "cst_roi_precentral_l.nii.gz" ] && [ -f "cst_roi_brainstem.nii.gz" ]; then
    tckedit wb_250k.tck CST_L.tck \
        -include cst_roi_precentral_l.nii.gz \
        -include cst_roi_brainstem.nii.gz \
        -minlength 30 -force
else
    tckedit wb_250k.tck CST_L.tck -include cc_roi.nii.gz -minlength 30 -force
fi

echo "Tutorial 4.3 complete. Generated wb_250k.tck, CC_bundle.tck, and CST_L.tck."
echo "Visual inspection: mrview fa.nii.gz -tractography.load CC_bundle.tck -tractography.load CST_L.tck"
