#!/bin/bash
# For pedagogical context, notes, and tips, refer to NOTEBOOK.md.
#
# ======================================================================
# dMRI Summer School - Tutorial 4.3 (Our Data)
#
# Theme: Hands-on bundle segmentation
#
# Goal: Generate a whole-brain tractogram, perform virtual dissection
#       of the Corticospinal Tract using ROIs, and run automated BundleSeg.
#
# Inputs:
#   - wmfod.nii.gz (from Tutorial 3.4)
#   - wm_mask.nii.gz (from Tutorial 1.5)
#   - synthseg_in_dwi.nii.gz (from Tutorial 1.5)
#   - b0_brain_mask.nii.gz
#
# Outputs:
#   - wb_250k.tck (Whole-brain tractogram)
#   - CST_L.tck (Manually dissected Left Corticospinal Tract)
#   - bundleseg_automated/ (Directory of automatically segmented bundles)
# ======================================================================

# Step 1: Generate Whole-Brain Tractogram (250k streamlines)
echo "Step 1: Generating whole-brain tractogram (250,000 streamlines)..."
tckgen wmfod.nii.gz wb_250k.tck -seed_image wm_mask.nii.gz -mask b0_brain_mask.nii.gz -select 250000 -force

# Convert to TRK for visualization
scil_tractogram_convert wb_250k.tck wb_250k.trk --reference b0_brain.nii.gz -f

# Step 2: Manual-Style Virtual Dissection with ROIs (Left CST)
echo "Step 2: Performing ROI-based dissection of Left Corticospinal Tract..."
# Extract inclusion ROIs from SynthSeg (1024: Precentral Gyrus Left, 16: Brainstem)
mrcalc synthseg_in_dwi.nii.gz 1024 -eq precentral_L_roi.nii.gz -force
mrcalc synthseg_in_dwi.nii.gz 16 -eq brainstem_roi.nii.gz -force

# Filter whole-brain tractogram keeping streamlines intersecting BOTH ROIs
tckedit wb_250k.tck CST_L.tck -include precentral_L_roi.nii.gz -include brainstem_roi.nii.gz -force

# Step 3: Automated Bundle Segmentation with BundleSeg
echo "Step 3: Performing automated bundle segmentation with BundleSeg..."
mkdir -p zenodo_scil_atlas
if [ ! -d "zenodo_scil_atlas/atlas" ]; then
    echo "Downloading BundleSeg atlas..."
    curl -sL https://zenodo.org/records/10103446/files/config.zip?download=1 -o config.zip
    curl -sL https://zenodo.org/records/10103446/files/atlas.zip?download=1 -o atlas.zip
    unzip -q config.zip -d zenodo_scil_atlas
    unzip -q atlas.zip -d zenodo_scil_atlas
    rm -f config.zip atlas.zip
fi

# Run BundleSeg
scil_tractogram_segment_with_bundleseg wb_250k.tck \
    zenodo_scil_atlas/config_fss_1.json \
    zenodo_scil_atlas/atlas/ \
    t1_to_b0_0GenericAffine.mat \
    --out_dir bundleseg_automated --modify_distance_thr 1 --processes 4 --reference b0_brain.nii.gz -f

echo "Tutorial 4.3 complete. Results are in 'bundleseg_automated/' and 'CST_L.tck'."
