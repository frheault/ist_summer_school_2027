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
#   - Segmented bundles (e.g. bundleseg_automated/ or CST_L.tck)
#   - Scalar metric maps: fa.nii.gz, md.nii.gz, NDI.nii.gz
#
# Outputs:
#   - tractometry_results/ (Centroids, labels, JSON statistics)
#   - tractometry_profiles.json, tractometry_whole_bundles.json
#   - tractometry_profiles_plot/ (Profile plots)
# ======================================================================

# Thread limits to prevent overwhelming host CPUs
export OMP_NUM_THREADS=4
export OPENBLAS_NUM_THREADS=4
export MRTRIX_NTHREADS=4
export ITK_GLOBAL_DEFAULT_NUMBER_OF_THREADS=4

echo "Step 1: Setting up output directories..."
mkdir -p tractometry_results/json_tmp
rm -f tractometry_results/json_tmp/*


# Use available metrics (NDI if generated, otherwise FA & MD)
METRICS="fa.nii.gz md.nii.gz"
if [ -f "NDI.nii.gz" ]; then
    METRICS="fa.nii.gz md.nii.gz NDI.nii.gz"
fi

# Process segmented bundles (e.g. CC_bundle.tck, CST_L.tck, bundleseg_automated/*.trk)
for bundle_file in CC_bundle.tck CST_L.tck bundleseg_automated/*.trk; do
    [ -e "$bundle_file" ] || continue
    ext="${bundle_file##*.}"
    bname=$(basename "$bundle_file" ."$ext")
    echo "--- Processing bundle: ${bname} ---"


    # Step 2: Compute Bundle Centroid (output as .trk to match input reference)
    centroid_file="tractometry_results/${bname}_centroid.trk"
    scil_bundle_compute_centroid "$bundle_file" "$centroid_file" --nb_points 20 --reference fa.nii.gz -f
    scil_bundle_uniformize_endpoints "$centroid_file" "$centroid_file" --auto --reference fa.nii.gz -f

    # Step 3: Create Label Map Along Tract
    label_map_dir="tractometry_results/${bname}_labelling"
    scil_bundle_label_map "$bundle_file" "$centroid_file" "$label_map_dir" --reference fa.nii.gz -f
    label_map_file="${label_map_dir}/labels_map.nii.gz"


    # Step 4: Compute Whole-Bundle & Per-Point Statistics
    scil_bundle_mean_std "$bundle_file" $METRICS \
        --out_json "tractometry_results/json_tmp/${bname}_whole_bundle.json" \
        --density_weighting --reference fa.nii.gz

    scil_bundle_mean_std "$bundle_file" $METRICS \
        --per_point "$label_map_file" \
        --out_json "tractometry_results/json_tmp/${bname}_profile.json" \
        --density_weighting --reference fa.nii.gz
done

# Step 5: Aggregate All Results
echo "Step 5: Aggregating tractometry profiles..."
scil_json_merge_entries tractometry_results/json_tmp/*_profile.json tractometry_profiles.json --no_list --add_parent_key "sub-01" -f
scil_json_merge_entries tractometry_results/json_tmp/*_whole_bundle.json tractometry_whole_bundles.json --no_list --add_parent_key "sub-01" -f
scil_plot_stats_per_point tractometry_profiles.json tractometry_profiles_plot/ -f

echo "Tutorial 4.6 complete. Results saved in 'tractometry_profiles.json' and plots in 'tractometry_profiles_plot/'."
