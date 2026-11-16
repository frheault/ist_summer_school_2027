#!/bin/bash
# See NOTEBOOK.md for study notes and quality control tips.
#
# ======================================================================
# dMRI Summer School - Tutorial 5.4, Track A (Session 5.4)
#
# Theme: Build Your Analysis: Bundle Segmentation and Tractometry
#
# Goal: Segment bundles on your subject (ROI + BundleSeg) and extract
#       along-tract microstructural profiles (FA, MD, NDI).
#
# Instructions:
#   1. Edit the YOUR_* variables below to use your own data in DWI space.
#      (Defaults point to the workshop files, so it runs as-is after Day 4.)
#   2. Run: bash tutorial_5.4A.sh
#
# Outputs (all saved in trackA_tractometry/):
#   - CST_L.tck, bundleseg_automated/*.tck
#   - tractometry_profiles.json, tractometry_whole_bundles.json
#   - tractometry_profiles_plot/
# ======================================================================

set -e

# --- CONFIGURE YOUR PATHS HERE ---
YOUR_WB_TCK="wb_100k.tck"
YOUR_T1="t1_to_b0.nii.gz"
YOUR_PARCELLATION="synthseg_in_dwi.nii.gz"
YOUR_FA="fa.nii.gz"
YOUR_MD="md.nii.gz"
YOUR_NDI="NDI.nii.gz"   # NODDI map (Tutorial 3.3 / 3.5), multi-shell only
OUT_DIR="trackA_tractometry"

mkdir -p "${OUT_DIR}/json_tmp"
rm -f "${OUT_DIR}/json_tmp/"*

# Step 1: Filter streamlines by length (20-200 mm) and extract the Left CST with ROIs
echo "Step 1: Filtering streamlines (20-200 mm) and extracting the Left CST..."
tckedit "$YOUR_WB_TCK" "${OUT_DIR}/wb_filtered.tck" -minlength 20 -maxlength 200 -force
mrcalc "$YOUR_PARCELLATION" 1024 -eq "${OUT_DIR}/roi_precentral_l.nii.gz" -datatype uint8 -force
mrcalc "$YOUR_PARCELLATION" 16 -eq "${OUT_DIR}/roi_brainstem.nii.gz" -datatype uint8 -force
tckedit "${OUT_DIR}/wb_filtered.tck" "${OUT_DIR}/precentral_L.tck" \
    -include "${OUT_DIR}/roi_precentral_l.nii.gz" -ends_only -force
tckedit "${OUT_DIR}/precentral_L.tck" "${OUT_DIR}/CST_L.tck" \
    -include "${OUT_DIR}/roi_brainstem.nii.gz" -force

# Step 2: Automated bundle segmentation with BundleSeg
echo "Step 2: Running automated BundleSeg..."
if [ ! -d "zenodo_scil_atlas/atlas" ]; then
    echo "  Downloading the BundleSeg atlas (~110 MB)..."
    mkdir -p zenodo_scil_atlas
    curl -sL "https://zenodo.org/records/10103446/files/config.zip?download=1" -o config.zip
    curl -sL "https://zenodo.org/records/10103446/files/atlas.zip?download=1" -o atlas.zip
    unzip -q -o config.zip -d zenodo_scil_atlas
    unzip -q -o atlas.zip -d zenodo_scil_atlas
    rm -f config.zip atlas.zip
fi

antsRegistrationSyNQuick.sh -d 3 -f "$YOUR_T1" -m zenodo_scil_atlas/mni_masked.nii.gz \
    -t a -o "${OUT_DIR}/atlas_to_subj_"

scil_tractogram_segment_with_bundleseg "${OUT_DIR}/wb_filtered.tck" \
    zenodo_scil_atlas/config_fss_1.json \
    zenodo_scil_atlas/atlas/ \
    "${OUT_DIR}/atlas_to_subj_0GenericAffine.mat" --inverse \
    --out_dir "${OUT_DIR}/bundleseg_automated" --modify_distance_thr 1 --processes 4 \
    --reference "$YOUR_T1" -f

# Step 3: Extract along-tract microstructural profiles (Tractometry)
# Note: Without an NDI map, use: METRICS="$YOUR_FA $YOUR_MD"
echo "Step 3: Extracting along-tract profiles..."
METRICS="$YOUR_FA $YOUR_MD $YOUR_NDI"

for bundle_file in "${OUT_DIR}/CST_L.tck" "${OUT_DIR}/bundleseg_automated"/*.tck; do
    [ -e "$bundle_file" ] || continue
    ext="${bundle_file##*.}"
    bname=$(basename "$bundle_file" ."$ext")
    nb=$(scil_tractogram_count_streamlines "$bundle_file" --print_count_alone)
    if [ "$nb" -lt 50 ]; then
        echo "--- Skipping ${bname} (${nb} streamlines < 50) ---"
        continue
    fi
    echo "--- Profiling bundle: ${bname} (${nb} streamlines) ---"

    centroid_file="${OUT_DIR}/${bname}_centroid.trk"
    scil_bundle_compute_centroid "$bundle_file" "$centroid_file" --nb_points 20 --reference "$YOUR_FA" -f
    scil_bundle_uniformize_endpoints "$centroid_file" "$centroid_file" --auto -f

    label_map_dir="${OUT_DIR}/${bname}_labelling"
    scil_bundle_label_map "$bundle_file" "$centroid_file" "$label_map_dir" --reference "$YOUR_FA" -f
    label_map_file="${label_map_dir}/labels_map.nii.gz"

    scil_bundle_mean_std "$bundle_file" $METRICS \
        --out_json "${OUT_DIR}/json_tmp/${bname}_whole_bundle.json" \
        --density_weighting --reference "$YOUR_FA"

    scil_bundle_mean_std "$bundle_file" $METRICS \
        --per_point "$label_map_file" \
        --out_json "${OUT_DIR}/json_tmp/${bname}_profile.json" \
        --density_weighting --reference "$YOUR_FA"
done

# Step 4: Merge JSON results and plot along-tract profiles
echo "Step 4: Merging JSON results and plotting profiles..."
scil_json_merge_entries "${OUT_DIR}/json_tmp/"*_profile.json \
    "${OUT_DIR}/tractometry_profiles.json" --no_list --add_parent_key "trackA" -f
scil_json_merge_entries "${OUT_DIR}/json_tmp/"*_whole_bundle.json \
    "${OUT_DIR}/tractometry_whole_bundles.json" --no_list --add_parent_key "trackA" -f
scil_plot_stats_per_point "${OUT_DIR}/tractometry_profiles.json" \
    "${OUT_DIR}/tractometry_profiles_plot/" -f

echo "Tutorial 5.4 (Track A) complete. Results saved in ${OUT_DIR}/."
