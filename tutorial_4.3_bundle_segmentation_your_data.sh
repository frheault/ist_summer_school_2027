#!/bin/bash
# For pedagogical context, notes, and tips, refer to NOTEBOOK.md.
#
# ======================================================================
# dMRI Summer School - Tutorial 4.3 (Your Data)
#
# Theme: Hands-on Bundle Segmentation (Your Data)
#
# Goal: Segment white matter pathways from your personal whole-brain
#       tractogram using both ROI-based dissection and automated BundleSeg.
#
# Instructions:
#   1. Set the YOUR_* variables below to point to your files (all in DWI space).
#   2. Run this script: bash tutorial_4.3_bundle_segmentation_your_data.sh
#   3. Inspect the resulting bundles in mrview or MI-Brain.
# ======================================================================

set -e

# --- CONFIGURE YOUR PATHS HERE ---
YOUR_WB_TCK="YOUR_WB_100k.tck"                  # whole-brain tractogram
YOUR_T1="YOUR_T1_IN_DWI.nii.gz"                 # skull-stripped T1w in DWI space (e.g. t1_to_b0.nii.gz)
YOUR_PARCELLATION="YOUR_SYNTHSEG_IN_DWI.nii.gz" # SynthSeg labels in DWI space
OUT_PREFIX="your_data"

# No T1 / parcellation in DWI space yet? Run the Steps 1-6 commands of
# tutorial_1.6_registration_segmentation.sh on YOUR files (the precomputed
# SynthSeg is only valid for the workshop T1), i.e. with your paths:
#   mri_synthseg --i YOUR_T1.nii.gz --o your_data_t1_synthseg.nii.gz --robust --parc --threads 4
#   mrcalc YOUR_T1.nii.gz your_data_t1_synthseg.nii.gz 0 -gt -mult your_data_t1_brain.nii.gz
#   antsRegistrationSyNQuick.sh -d 3 -f your_data_b0_brain.nii.gz -m your_data_t1_brain.nii.gz \
#       -t r -o your_data_t1_to_b0_                     # -> YOUR_T1 = your_data_t1_to_b0_Warped.nii.gz
#   antsApplyTransforms -d 3 -i your_data_t1_synthseg.nii.gz -r your_data_b0_brain.nii.gz \
#       -t your_data_t1_to_b0_0GenericAffine.mat -n NearestNeighbor -u int \
#       -o your_data_synthseg_in_dwi.nii.gz              # -> YOUR_PARCELLATION
#   mrcalc your_data_synthseg_in_dwi.nii.gz 2 -eq your_data_synthseg_in_dwi.nii.gz 41 -eq -add \
#       your_data_wm_mask.nii.gz -datatype uint8          # -> WM seeding mask for tckgen below
# (your_data_b0_brain.nii.gz comes from Tutorial 2.5 / 3.5.)
#
# No whole-brain tractogram yet? Generate one from your fODFs (Tutorial 3.5), e.g.:
#   tckgen your_data_wmfod.nii.gz your_data_wb_100k.tck -seed_image your_data_wm_mask.nii.gz \
#          -mask your_data_b0_brain_mask.nii.gz -select 100000 -nthreads 4

if [ ! -f "$YOUR_WB_TCK" ]; then
    echo "[INFO] Please edit this script and specify YOUR_WB_TCK, YOUR_T1 and YOUR_PARCELLATION."
    echo "       Example (workshop data), edit these lines at the top of the file:"
    echo "       YOUR_WB_TCK=\"wb_100k.tck\"  YOUR_T1=\"t1_to_b0.nii.gz\"  YOUR_PARCELLATION=\"synthseg_in_dwi.nii.gz\""
    exit 0
fi

export MRTRIX_NTHREADS=4
export ITK_GLOBAL_DEFAULT_NUMBER_OF_THREADS=4

# Step 1: Length filtering
echo "Step 1: Length filtering (20-200 mm)..."
tckedit "$YOUR_WB_TCK" "${OUT_PREFIX}_wb_filtered.tck" -minlength 20 -maxlength 200 -force

# Step 2: ROI-based dissection of the left CST from your parcellation
# SynthSeg label IDs: 1024 (Left Precentral), 16 (Brainstem)
echo "Step 2: ROI-based dissection (left CST)..."
mrcalc "$YOUR_PARCELLATION" 1024 -eq "${OUT_PREFIX}_roi_precentral_l.nii.gz" -datatype uint8 -force
mrcalc "$YOUR_PARCELLATION" 16 -eq "${OUT_PREFIX}_roi_brainstem.nii.gz" -datatype uint8 -force
tckedit "${OUT_PREFIX}_wb_filtered.tck" "${OUT_PREFIX}_precentral_L.tck" \
    -include "${OUT_PREFIX}_roi_precentral_l.nii.gz" -ends_only -force
tckedit "${OUT_PREFIX}_precentral_L.tck" "${OUT_PREFIX}_CST_L.tck" \
    -include "${OUT_PREFIX}_roi_brainstem.nii.gz" -force

# Step 3: Automated Bundle Segmentation via BundleSeg
echo "Step 3: Running automated BundleSeg on your data..."
if [ ! -d "zenodo_scil_atlas/atlas" ]; then
    echo "  Downloading BundleSeg atlas (~110 MB)..."
    mkdir -p zenodo_scil_atlas
    curl -sL "https://zenodo.org/records/10103446/files/config.zip?download=1" -o config.zip
    curl -sL "https://zenodo.org/records/10103446/files/atlas.zip?download=1" -o atlas.zip
    unzip -q -o config.zip -d zenodo_scil_atlas
    unzip -q -o atlas.zip -d zenodo_scil_atlas
    rm -f config.zip atlas.zip
fi

# Atlas (moving) -> your T1 in DWI space (fixed), used with --inverse
antsRegistrationSyNQuick.sh -d 3 -f "$YOUR_T1" -m zenodo_scil_atlas/mni_masked.nii.gz \
    -t a -o "${OUT_PREFIX}_atlas_to_subj_"

scil_tractogram_segment_with_bundleseg "${OUT_PREFIX}_wb_filtered.tck" \
    zenodo_scil_atlas/config_fss_1.json \
    zenodo_scil_atlas/atlas/ \
    "${OUT_PREFIX}_atlas_to_subj_0GenericAffine.mat" --inverse \
    --out_dir "${OUT_PREFIX}_bundleseg_automated" --modify_distance_thr 1 --processes 4 \
    --reference "$YOUR_T1" -f

echo "Tutorial 4.3 complete. ROI bundle: ${OUT_PREFIX}_CST_L.tck; BundleSeg bundles in '${OUT_PREFIX}_bundleseg_automated'."
