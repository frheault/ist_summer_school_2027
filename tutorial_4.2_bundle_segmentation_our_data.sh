#!/bin/bash
# For pedagogical context, notes, and tips, refer to NOTEBOOK.md.
#
# ======================================================================
# dMRI Summer School - Tutorial 4.2 (Our Data)
#
# Theme: Hands-on bundle segmentation
#
# Goal: Generate a whole-brain tractogram, filter it by length, perform
#       ROI-based virtual dissection (CC, left CST) and automated
#       segmentation with BundleSeg.
#
# Inputs:
#   - wmfod.nii.gz (from Tutorial 3.4)
#   - b0_brain_mask.nii.gz, wm_mask.nii.gz, cc_roi.nii.gz, t1_to_b0.nii.gz,
#     roi_precentral_l.nii.gz, roi_brainstem.nii.gz (from Tutorial 1.6)
#   - fa.nii.gz (from Tutorial 2.3)
#
# Outputs:
#   - wb_100k.tck (Whole-brain tractogram), wb_100k_filtered.tck (20-200 mm)
#   - CC_bundle.tck (Corpus Callosum), CST_L.tck (Left Corticospinal Tract)
#   - bundleseg_automated/*.tck (BundleSeg bundles)
# ======================================================================

set -e

# Thread limits to prevent overwhelming host CPUs
export MRTRIX_NTHREADS=4
export ITK_GLOBAL_DEFAULT_NUMBER_OF_THREADS=4

# Step 1: White Matter Seeding Mask
# We use wm_mask.nii.gz generated in Tutorial 1.6 as the seeding mask.
# (Note: If you skipped Tutorial 1.6, you can generate an FA mask instead:
#  mrthreshold fa.nii.gz wm_mask.nii.gz -abs 0.2 -force)

# Step 2: Generate Whole-Brain Tractogram (100k streamlines, iFOD2 on MSMT fODFs)
echo "Step 2: Generating whole-brain tractogram (100,000 streamlines)..."
tckgen wmfod.nii.gz wb_100k.tck -seed_image wm_mask.nii.gz -mask b0_brain_mask.nii.gz \
    -select 100000 -force

# Step 3: Basic filtering: remove anatomically implausible lengths
echo "Step 3: Length filtering (20-200 mm)..."
tckedit wb_100k.tck wb_100k_filtered.tck -minlength 20 -maxlength 200 -force
echo "  Streamlines kept: $(tckinfo wb_100k_filtered.tck -count | awk '/actual count/{print $NF}') / 100000"

# Step 4: ROI-based virtual dissection
echo "Step 4: Extracting bundles with ROIs (Corpus Callosum and Left CST)..."
# Corpus Callosum: streamlines passing anywhere through the midsagittal CC ROI
tckedit wb_100k_filtered.tck CC_bundle.tck -include cc_roi.nii.gz -force

# Left CST, two steps:
#   a) keep streamlines with either end in the left precentral gyrus (-ends_only)
#   b) from that file, keep those that pass through the brainstem
tckedit wb_100k_filtered.tck precentral_L.tck -include roi_precentral_l.nii.gz -ends_only -force
tckedit precentral_L.tck CST_L.tck -include roi_brainstem.nii.gz -force
# Exercise: repeat with roi_postcentral_l.nii.gz (sensory fibres) and compare.

# [scilpy Version] (either_end / any modes in a single call)
# scil_tractogram_filter_by_roi wb_100k_filtered.tck CST_L.trk --reference fa.nii.gz \
#     --drawn_roi roi_precentral_l.nii.gz either_end include \
#     --drawn_roi roi_brainstem.nii.gz any include -f

# Step 5: Automated segmentation with BundleSeg
echo "Step 5: Automated bundle segmentation with BundleSeg..."
if [ ! -d "zenodo_scil_atlas/atlas" ]; then
    echo "  Downloading BundleSeg atlas (~110 MB)..."
    mkdir -p zenodo_scil_atlas
    curl -sL "https://zenodo.org/records/10103446/files/config.zip?download=1" -o config.zip
    curl -sL "https://zenodo.org/records/10103446/files/atlas.zip?download=1" -o atlas.zip
    unzip -q -o config.zip -d zenodo_scil_atlas
    unzip -q -o atlas.zip -d zenodo_scil_atlas
    rm -f config.zip atlas.zip
fi

# Simple affine: atlas T1 (moving) -> subject T1 in DWI space (fixed). Same contrast on both sides.
antsRegistrationSyNQuick.sh -d 3 -f t1_to_b0.nii.gz -m zenodo_scil_atlas/mni_masked.nii.gz \
    -t a -o atlas_to_subj_

# moving=atlas / fixed=subject registration => use --inverse (see scil_tractogram_segment_with_bundleseg -h)
scil_tractogram_segment_with_bundleseg wb_100k_filtered.tck \
    zenodo_scil_atlas/config_fss_1.json \
    zenodo_scil_atlas/atlas/ \
    atlas_to_subj_0GenericAffine.mat --inverse \
    --out_dir bundleseg_automated --modify_distance_thr 1 --processes 4 \
    --reference fa.nii.gz -f

echo "Tutorial 4.2 complete. Generated wb_100k.tck, CC_bundle.tck, CST_L.tck and bundleseg_automated/."
echo "Visual inspection: mrview fa.nii.gz -tractography.load CC_bundle.tck -tractography.load CST_L.tck"
