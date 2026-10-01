#!/bin/bash
# For pedagogical context, notes, and tips, refer to NOTEBOOK.md.
#
# ======================================================================
# dMRI Summer School - Tutorial 5.4, Track A (Build your analysis: Tractometry)
#
# Theme: Automated bundle segmentation + along-tract profiling on YOUR data
#
# Goal: Segment bundles on your subject (ROI + BundleSeg) and extract
#       along-tract microstructural profiles (tractometry).
#
# Instructions:
#   1. Set the YOUR_* variables below (all images in DWI space; see the
#      comments of tutorial_4.3 to bring your T1/SynthSeg into DWI space).
#   2. Defaults = workshop data, so the script runs as-is after Day 4.
#   3. Run: bash tutorial_5.4A.sh
#
# Outputs:
#   - ${OUT_PREFIX}_CST_L.tck, ${OUT_PREFIX}_bundleseg_automated/
#   - ${OUT_PREFIX}_tractometry/ (profiles JSON + plots)
# ======================================================================

set -e

# --- CONFIGURE YOUR PATHS HERE ---
YOUR_WB_TCK="wb_100k.tck"
YOUR_T1="t1_to_b0.nii.gz"
YOUR_PARCELLATION="synthseg_in_dwi.nii.gz"
YOUR_FA="fa.nii.gz"
YOUR_MD="md.nii.gz"
YOUR_NDI="NDI.nii.gz"                 # NODDI map (Tutorial 3.3 / 3.5), multi-shell only
OUT_PREFIX="trackA"

# Thread limits to prevent overwhelming host CPUs
export OMP_NUM_THREADS=4
export OPENBLAS_NUM_THREADS=4
export MRTRIX_NTHREADS=4
export ITK_GLOBAL_DEFAULT_NUMBER_OF_THREADS=4

# Step 1: Length filtering & ROI dissection (Left CST)
echo "Step 1: Length filtering (20-200 mm) & ROI dissection (left CST)..."
tckedit "$YOUR_WB_TCK" "${OUT_PREFIX}_wb_filtered.tck" -minlength 20 -maxlength 200 -force
mrcalc "$YOUR_PARCELLATION" 1024 -eq "${OUT_PREFIX}_roi_precentral_l.nii.gz" -datatype uint8 -force
mrcalc "$YOUR_PARCELLATION" 16 -eq "${OUT_PREFIX}_roi_brainstem.nii.gz" -datatype uint8 -force
tckedit "${OUT_PREFIX}_wb_filtered.tck" "${OUT_PREFIX}_precentral_L.tck" \
    -include "${OUT_PREFIX}_roi_precentral_l.nii.gz" -ends_only -force
tckedit "${OUT_PREFIX}_precentral_L.tck" "${OUT_PREFIX}_CST_L.tck" \
    -include "${OUT_PREFIX}_roi_brainstem.nii.gz" -force

# Step 2: Automated Bundle Segmentation via BundleSeg
echo "Step 2: Running automated BundleSeg..."
if [ ! -d "zenodo_scil_atlas/atlas" ]; then
    echo "  Downloading BundleSeg atlas (~110 MB)..."
    mkdir -p zenodo_scil_atlas
    curl -sL "https://zenodo.org/records/10103446/files/config.zip?download=1" -o config.zip
    curl -sL "https://zenodo.org/records/10103446/files/atlas.zip?download=1" -o atlas.zip
    unzip -q -o config.zip -d zenodo_scil_atlas
    unzip -q -o atlas.zip -d zenodo_scil_atlas
    rm -f config.zip atlas.zip
fi

antsRegistrationSyNQuick.sh -d 3 -f "$YOUR_T1" -m zenodo_scil_atlas/mni_masked.nii.gz \
    -t a -o "${OUT_PREFIX}_atlas_to_subj_"

scil_tractogram_segment_with_bundleseg "${OUT_PREFIX}_wb_filtered.tck" \
    zenodo_scil_atlas/config_fss_1.json \
    zenodo_scil_atlas/atlas/ \
    "${OUT_PREFIX}_atlas_to_subj_0GenericAffine.mat" --inverse \
    --out_dir "${OUT_PREFIX}_bundleseg_automated" --modify_distance_thr 1 --processes 4 \
    --reference "$YOUR_T1" -f

# Step 3: Along-tract profiles (Tractometry)
echo "Step 3: Along-tract tractometry profiling..."
mkdir -p "${OUT_PREFIX}_tractometry/tractometry_results/json_tmp"
rm -f "${OUT_PREFIX}_tractometry"/tractometry_results/json_tmp/*

# Metrics to sample along the bundles (from Tutorial 2.3 and Tutorial 3.3)
# Note: If you have no NDI map (single-shell data, or Tutorial 3.3 skipped), use:
#   METRICS="$YOUR_FA $YOUR_MD"
METRICS="$YOUR_FA $YOUR_MD $YOUR_NDI"
echo "Metrics: ${METRICS}"

for bundle_file in "${OUT_PREFIX}_CST_L.tck" "${OUT_PREFIX}_bundleseg_automated"/*.tck; do
    [ -e "$bundle_file" ] || continue
    ext="${bundle_file##*.}"
    bname=$(basename "$bundle_file" ."$ext")
    nb=$(scil_tractogram_count_streamlines "$bundle_file" --print_count_alone)
    if [ "$nb" -lt 50 ]; then
        echo "--- Skipping ${bname}: ${nb} streamlines < 50 ---"
        continue
    fi
    echo "--- Processing bundle: ${bname} (${nb} streamlines) ---"

    centroid_file="${OUT_PREFIX}_tractometry/tractometry_results/${bname}_centroid.trk"
    scil_bundle_compute_centroid "$bundle_file" "$centroid_file" --nb_points 20 --reference "$YOUR_FA" -f
    scil_bundle_uniformize_endpoints "$centroid_file" "$centroid_file" --auto --reference "$YOUR_FA" -f

    label_map_dir="${OUT_PREFIX}_tractometry/tractometry_results/${bname}_labelling"
    scil_bundle_label_map "$bundle_file" "$centroid_file" "$label_map_dir" --reference "$YOUR_FA" -f
    label_map_file="${label_map_dir}/labels_map.nii.gz"

    scil_bundle_mean_std "$bundle_file" $METRICS \
        --out_json "${OUT_PREFIX}_tractometry/tractometry_results/json_tmp/${bname}_whole_bundle.json" \
        --density_weighting --reference "$YOUR_FA"

    scil_bundle_mean_std "$bundle_file" $METRICS \
        --per_point "$label_map_file" \
        --out_json "${OUT_PREFIX}_tractometry/tractometry_results/json_tmp/${bname}_profile.json" \
        --density_weighting --reference "$YOUR_FA"
done

echo "Step 4: Aggregating tractometry profiles..."
scil_json_merge_entries "${OUT_PREFIX}_tractometry"/tractometry_results/json_tmp/*_profile.json \
    "${OUT_PREFIX}_tractometry/tractometry_profiles.json" --no_list --add_parent_key "$OUT_PREFIX" -f
scil_json_merge_entries "${OUT_PREFIX}_tractometry"/tractometry_results/json_tmp/*_whole_bundle.json \
    "${OUT_PREFIX}_tractometry/tractometry_whole_bundles.json" --no_list --add_parent_key "$OUT_PREFIX" -f
scil_plot_stats_per_point "${OUT_PREFIX}_tractometry/tractometry_profiles.json" \
    "${OUT_PREFIX}_tractometry/tractometry_profiles_plot/" -f

echo "Tutorial 5.4 (Track A) complete. Profiles: ${OUT_PREFIX}_tractometry/tractometry_profiles.json"
echo "Plots: ${OUT_PREFIX}_tractometry/tractometry_profiles_plot/"
