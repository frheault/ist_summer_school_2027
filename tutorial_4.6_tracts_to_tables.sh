#!/bin/bash
# For pedagogical context, notes, and tips, refer to NOTEBOOK.md.
#
# ======================================================================
# dMRI Summer School - Tutorial 4.6 (Our Data)
#
# Theme: Tractometry: From Tracts to Tables with Scilpy
#
# Goal: Compute bundle centroids, equidistant tract labelling maps,
#       and extract along-tract quantitative microstructural profiles (FA, MD, NDI).
#
# Inputs:
#   - Segmented bundles: CC_bundle.tck, CST_L.tck, bundleseg_automated/*.tck (from Tutorial 4.2)
#   - Scalar metric maps: fa.nii.gz, md.nii.gz (Tutorial 2.3), NDI.nii.gz (Tutorial 3.3, optional)
#
# Outputs:
#   - tractometry_results/ (Centroids, labels, JSON statistics)
#   - tractometry_profiles.json, tractometry_whole_bundles.json
#   - tractometry_profiles_plot/ (Profile plots)
# ======================================================================

set -e

# Thread limits to prevent overwhelming host CPUs
export OMP_NUM_THREADS=4
export OPENBLAS_NUM_THREADS=4
export MRTRIX_NTHREADS=4
export ITK_GLOBAL_DEFAULT_NUMBER_OF_THREADS=4

# Bundles to profile: CC, CST, and automated bundles from Tutorial 4.2
BUNDLES="CC_bundle.tck CST_L.tck bundleseg_automated/*.tck"
REF="fa.nii.gz"
SUBJ="sub-01"
MIN_STREAMLINES=50   # profiles of tiny bundles are meaningless

# Metrics to sample along the bundles (from Tutorial 2.3 and Tutorial 3.3)
# Note: If you skipped Tutorial 3.3 and do not have NDI.nii.gz, you can use:
#   METRICS="fa.nii.gz md.nii.gz"
METRICS="fa.nii.gz md.nii.gz NDI.nii.gz"

echo "Step 1: Setting up output directories..."
mkdir -p tractometry_results/json_tmp
rm -f tractometry_results/json_tmp/*
echo "Metrics: ${METRICS}"

# Process segmented bundles
for bundle_file in $BUNDLES; do
    [ -e "$bundle_file" ] || continue
    ext="${bundle_file##*.}"
    bname=$(basename "$bundle_file" ."$ext")
    nb=$(scil_tractogram_count_streamlines "$bundle_file" --print_count_alone)
    if [ "$nb" -lt "$MIN_STREAMLINES" ]; then
        echo "--- Skipping ${bname}: ${nb} streamlines < ${MIN_STREAMLINES} ---"
        continue
    fi
    echo "--- Processing bundle: ${bname} (${nb} streamlines) ---"

    # Step 2: Compute Bundle Centroid (output as .trk to match input reference)
    centroid_file="tractometry_results/${bname}_centroid.trk"
    scil_bundle_compute_centroid "$bundle_file" "$centroid_file" --nb_points 20 --reference "$REF" -f
    scil_bundle_uniformize_endpoints "$centroid_file" "$centroid_file" --auto --reference "$REF" -f

    # Step 3: Create Label Map Along Tract
    label_map_dir="tractometry_results/${bname}_labelling"
    scil_bundle_label_map "$bundle_file" "$centroid_file" "$label_map_dir" --reference "$REF" -f
    label_map_file="${label_map_dir}/labels_map.nii.gz"

    # Step 4: Compute Whole-Bundle & Per-Point Statistics
    scil_bundle_mean_std "$bundle_file" $METRICS \
        --out_json "tractometry_results/json_tmp/${bname}_whole_bundle.json" \
        --density_weighting --reference "$REF"

    scil_bundle_mean_std "$bundle_file" $METRICS \
        --per_point "$label_map_file" \
        --out_json "tractometry_results/json_tmp/${bname}_profile.json" \
        --density_weighting --reference "$REF"
done

# Step 5: Aggregate All Results
echo "Step 5: Aggregating tractometry profiles..."
scil_json_merge_entries tractometry_results/json_tmp/*_profile.json tractometry_profiles.json --no_list --add_parent_key "$SUBJ" -f
scil_json_merge_entries tractometry_results/json_tmp/*_whole_bundle.json tractometry_whole_bundles.json --no_list --add_parent_key "$SUBJ" -f
scil_plot_stats_per_point tractometry_profiles.json tractometry_profiles_plot/ -f

echo "Tutorial 4.6 complete. Results saved in 'tractometry_profiles.json' and plots in 'tractometry_profiles_plot/'."
