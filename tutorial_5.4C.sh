#!/bin/bash
# See NOTEBOOK.md for study notes and quality control tips.
#
# ======================================================================
# dMRI Summer School - Tutorial 5.4, Track C (Session 5.4)
#
# Theme: Build Your Analysis: Streamline Clustering with QuickBundlesX
#
# Goal: Cluster a whole-brain tractogram by streamline geometry with
#       QuickBundlesX (scil_tractogram_qbx) and compute shape metrics
#       on the largest cluster.
#
# Inputs:
#   - wb_100k.tck (Tutorial 4.2)
#   - fa.nii.gz (Tutorial 2.3, used as spatial reference)
#
# Outputs:
#   - qbx_clusters/ (one .trk file per cluster)
#   - qbx_centroids.trk (one centroid streamline per cluster)
#   - qbx_biggest_cluster_shape.json
# ======================================================================

set -e

# Distance threshold in mm:
#   DIST_THRESH=10 -> fine clustering (~2700 clusters on wb_100k.tck)
#   DIST_THRESH=15 -> balanced clustering (default, ~700 clusters)
#   DIST_THRESH=20 -> coarse clustering (~190 clusters)
# Exercise: Edit DIST_THRESH below (e.g. 10 or 20) and run the script again.
DIST_THRESH=15
INPUT_TCK="wb_100k.tck"
REF_IMG="fa.nii.gz"

# Step 1: Run QuickBundlesX clustering
echo "Step 1: Running QuickBundlesX clustering (threshold = ${DIST_THRESH} mm)..."
mkdir -p qbx_clusters
rm -f qbx_clusters/*.trk

scil_tractogram_qbx "${INPUT_TCK}" "${DIST_THRESH}" qbx_clusters/ \
    --nb_points 20 \
    --out_centroids qbx_centroids.trk \
    --reference "${REF_IMG}" \
    -f

echo "  Clusters saved in qbx_clusters/: $(ls qbx_clusters/*.trk | wc -l)"

# Step 2: Find the largest cluster file
echo "Step 2: Finding the largest cluster..."
BIGGEST_CLUSTER=$(ls -S qbx_clusters/cluster_*.trk | head -n 1)
echo "  Largest cluster: ${BIGGEST_CLUSTER}"

# Step 3: Compute shape metrics on the largest cluster
echo "Step 3: Computing shape metrics on ${BIGGEST_CLUSTER}..."
scil_bundle_shape_measures "${BIGGEST_CLUSTER}" \
    --out_json qbx_biggest_cluster_shape.json \
    --reference "${REF_IMG}" \
    --indent 2 \
    -f
cat qbx_biggest_cluster_shape.json
echo ""

echo "Tutorial 5.4 (Track C) complete. Open fa.nii.gz, qbx_centroids.trk, and qbx_clusters/*.trk in MI-Brain."
