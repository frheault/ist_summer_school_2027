#!/bin/bash
# See NOTEBOOK.md for study notes and quality control tips.
#
# ======================================================================
# dMRI Summer School - Tutorial 4.2 (Session 4.2 - Our Data)
#
# Theme: Hands-on Bundle Segmentation
#
# Goal: Generate a whole-brain tractogram, filter streamlines by length,
#       and extract bundles using manual ROIs and automated BundleSeg.
#
# Inputs:
#   - wmfod.nii.gz (Tutorial 3.4)
#   - b0_brain_mask.nii.gz, wm_mask.nii.gz, cc_roi.nii.gz, t1_to_b0.nii.gz,
#     roi_precentral_l.nii.gz, roi_postcentral_l.nii.gz, roi_brainstem.nii.gz (Tutorial 1.6)
#   - fa.nii.gz (Tutorial 2.3)
#
# Outputs:
#   - wb_100k.tck (whole-brain tractogram), wb_100k_filtered.tck (20-200 mm)
#   - CC_bundle.tck, precentral_L.tck, CST_L.tck
#   - atlas_to_subj_0GenericAffine.mat, bundleseg_automated/*.tck
# ======================================================================

set -e

# Step 1: Generate a whole-brain tractogram (100,000 streamlines, iFOD2 on MSMT fODFs)
# Note: We seed from wm_mask.nii.gz created in Tutorial 1.6.
echo "Step 1: Generating a 100,000-streamline whole-brain tractogram..."
tckgen wmfod.nii.gz wb_100k.tck -seed_image wm_mask.nii.gz -mask b0_brain_mask.nii.gz \
    -select 100000 -force

# Step 2: Filter streamlines by length (keep 20 to 200 mm)
echo "Step 2: Filtering streamlines by length (20-200 mm)..."
tckedit wb_100k.tck wb_100k_filtered.tck -minlength 20 -maxlength 200 -force
tckinfo wb_100k_filtered.tck -count

# Step 3: ROI-based virtual dissection (Corpus Callosum and Left CST)
echo "Step 3: Extracting Corpus Callosum and Left CST with ROI masks..."
tckedit wb_100k_filtered.tck CC_bundle.tck -include cc_roi.nii.gz -force

# Left CST: keep streamlines ending in the left precentral gyrus that pass through the brainstem
tckedit wb_100k_filtered.tck precentral_L.tck -include roi_precentral_l.nii.gz -ends_only -force
tckedit precentral_L.tck CST_L.tck -include roi_brainstem.nii.gz -force
# Exercise: Repeat with roi_postcentral_l.nii.gz (sensory tract) and compare with CST_L.tck.

# [Scilpy Alternative]
# scil_tractogram_filter_by_roi wb_100k_filtered.tck CST_L.trk --reference fa.nii.gz \
#     --drawn_roi roi_precentral_l.nii.gz either_end include \
#     --drawn_roi roi_brainstem.nii.gz any include -f

# Step 4: Automated bundle segmentation with BundleSeg
echo "Step 4: Running automated bundle segmentation with BundleSeg..."
if [ ! -d "zenodo_scil_atlas/atlas" ]; then
    echo "  Downloading the BundleSeg atlas (~110 MB)..."
    mkdir -p zenodo_scil_atlas
    curl -sL "https://zenodo.org/records/10103446/files/config.zip?download=1" -o config.zip
    curl -sL "https://zenodo.org/records/10103446/files/atlas.zip?download=1" -o atlas.zip
    unzip -q -o config.zip -d zenodo_scil_atlas
    unzip -q -o atlas.zip -d zenodo_scil_atlas
    rm -f config.zip atlas.zip
fi

# Register the atlas T1 (moving) to the subject T1 in DWI space (fixed)
antsRegistrationSyNQuick.sh -d 3 -f t1_to_b0.nii.gz -m zenodo_scil_atlas/mni_masked.nii.gz \
    -t a -o atlas_to_subj_

# Note: Since moving=atlas and fixed=subject, pass --inverse to BundleSeg
scil_tractogram_segment_with_bundleseg wb_100k_filtered.tck \
    zenodo_scil_atlas/config_fss_1.json \
    zenodo_scil_atlas/atlas/ \
    atlas_to_subj_0GenericAffine.mat --inverse \
    --out_dir bundleseg_automated --modify_distance_thr 1 --processes 4 \
    --reference fa.nii.gz -f

# Step 5: Compare manual CST_L vs automated BundleSeg PYT_L streamline counts
echo "Step 5: Comparing manual CST_L.tck and automated PYT_L.tck..."
tckinfo CST_L.tck bundleseg_automated/PYT_L.tck -count

echo "Tutorial 4.2 complete. Inspect bundles in mrview:"
echo "mrview fa.nii.gz -tractography.load CC_bundle.tck -tractography.load CST_L.tck"
