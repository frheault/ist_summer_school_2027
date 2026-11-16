#!/bin/bash
# See NOTEBOOK.md for study notes and quality control tips.
#
# ======================================================================
# dMRI Summer School - Tutorial 4.6 (Session 4.6 - Our Data)
#
# Theme: Tractometry: From Tracts to Tables with Scilpy
#
# Goal: Compute bundle centroids, subdivide bundles into 20 sections,
#       and extract along-tract microstructural profiles (FA, MD, NDI).
#
# Inputs:
#   - CC_bundle.tck, CST_L.tck, bundleseg_automated/*.tck (Tutorial 4.2)
#   - fa.nii.gz, md.nii.gz (Tutorial 2.3), NDI.nii.gz (Tutorial 3.3)
#
# Outputs:
#   - tractometry_results/ (centroids, label maps, per-bundle JSON files)
#   - tractometry_profiles.json, tractometry_whole_bundles.json
#   - tractometry_profiles_plot/ (along-tract profile plots)
# ======================================================================

set -e

BUNDLES="CC_bundle.tck CST_L.tck bundleseg_automated/*.tck"
REF="fa.nii.gz"
SUBJ="sub-01"
MIN_STREAMLINES=50

# Scalar maps to sample along each bundle (from Tutorials 2.3 and 3.3)
# Note: If you do not have NDI.nii.gz, use: METRICS="fa.nii.gz md.nii.gz"
METRICS="fa.nii.gz md.nii.gz NDI.nii.gz"

echo "Step 1: Preparing output folders..."
mkdir -p tractometry_results/json_tmp
rm -f tractometry_results/json_tmp/*

for bundle_file in $BUNDLES; do
    [ -e "$bundle_file" ] || continue
    ext="${bundle_file##*.}"
    bname=$(basename "$bundle_file" ."$ext")
    nb=$(scil_tractogram_count_streamlines "$bundle_file" --print_count_alone)
    if [ "$nb" -lt "$MIN_STREAMLINES" ]; then
        echo "--- Skipping ${bname} (${nb} streamlines < ${MIN_STREAMLINES}) ---"
        continue
    fi
    echo "--- Profiling bundle: ${bname} (${nb} streamlines) ---"

    # Step 2: Compute a 20-point centroid and align its endpoints
    centroid_file="tractometry_results/${bname}_centroid.trk"
    scil_bundle_compute_centroid "$bundle_file" "$centroid_file" --nb_points 20 --reference "$REF" -f
    scil_bundle_uniformize_endpoints "$centroid_file" "$centroid_file" --auto -f

    # Step 3: Create the 20-section label map along the bundle
    label_map_dir="tractometry_results/${bname}_labelling"
    scil_bundle_label_map "$bundle_file" "$centroid_file" "$label_map_dir" --reference "$REF" -f
    label_map_file="${label_map_dir}/labels_map.nii.gz"

    # Step 4: Compute density-weighted mean and standard deviation (whole-bundle and per-point)
    scil_bundle_mean_std "$bundle_file" $METRICS \
        --out_json "tractometry_results/json_tmp/${bname}_whole_bundle.json" \
        --density_weighting --reference "$REF"

    scil_bundle_mean_std "$bundle_file" $METRICS \
        --per_point "$label_map_file" \
        --out_json "tractometry_results/json_tmp/${bname}_profile.json" \
        --density_weighting --reference "$REF"
done

# Step 5: Merge per-bundle JSON files and plot along-tract profiles
echo "Step 5: Merging JSON results and plotting profiles..."
scil_json_merge_entries tractometry_results/json_tmp/*_profile.json \
    tractometry_profiles.json --no_list --add_parent_key "$SUBJ" -f
scil_json_merge_entries tractometry_results/json_tmp/*_whole_bundle.json \
    tractometry_whole_bundles.json --no_list --add_parent_key "$SUBJ" -f
scil_plot_stats_per_point tractometry_profiles.json tractometry_profiles_plot/ -f

echo "Tutorial 4.6 complete. Profiles saved in tractometry_profiles.json and tractometry_profiles_plot/."
