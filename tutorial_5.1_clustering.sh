#!/bin/bash
# For pedagogical context, notes, and tips, refer to NOTEBOOK.md.
#
# ======================================================================
# dMRI Summer School - Tutorial 5.1 (Our Data)
#
# Theme: Tractography Clustering with QuickBundlesX (Scilpy)
#
# Goal: Perform unsupervised geometric clustering of a whole-brain
#       tractogram using scil_tractogram_qbx, characterize the largest
#       resulting cluster with shape measures, and visualize all clusters
#       in MI-Brain.
#
# Inputs:
#   - wb_250k.tck (Whole-brain tractogram from Tutorial 4.3)
#   - fa.nii.gz   (used as spatial reference)
#
# Outputs:
#   - qbx_clusters/              (One .trk file per cluster)
#   - qbx_centroids.trk          (One centroid streamline per cluster)
#   - qbx_biggest_cluster_shape.json
#
# ======================================================================

# -----------------------------------------------------------------------
# PEDAGOGICAL NOTE — Distance threshold:
#   The distance threshold (in mm) is the most important QBX parameter.
#   A SMALLER value → more clusters, finer grouping (may over-split).
#   A LARGER value  → fewer clusters, coarser grouping (may merge tracts).
#   Typical values for whole-brain data: 10–20 mm.
#
#   Try re-running this script with different DIST_THRESH values and
#   observe how the cluster count and shapes change:
#     DIST_THRESH=10   → fine-grained (~hundreds of clusters)
#     DIST_THRESH=15   → balanced clustering (default here)
#     DIST_THRESH=20   → coarse clustering (~tens of clusters)
#     DIST_THRESH=30   → very coarse, large anatomical bundles grouped
DIST_THRESH=15
INPUT_TCK="wb_250k.tck"
REF_IMG="fa.nii.gz"

echo "Using tractogram  : ${INPUT_TCK}"
echo "Distance threshold: ${DIST_THRESH} mm"
echo "Spatial reference : ${REF_IMG}"

# -----------------------------------------------------------------------
# Step 1: Run QuickBundlesX clustering
# -----------------------------------------------------------------------
echo ""
echo "Step 1: Running QuickBundlesX clustering (threshold = ${DIST_THRESH} mm)..."
mkdir -p qbx_clusters

scil_tractogram_qbx "${INPUT_TCK}" "${DIST_THRESH}" qbx_clusters/ \
    --nb_points 20 \
    --out_centroids qbx_centroids.trk \
    --reference "${REF_IMG}" \
    -f -v

NUM_CLUSTERS=$(ls qbx_clusters/*.trk 2>/dev/null | wc -l)
echo "Clustering complete: ${NUM_CLUSTERS} clusters saved in qbx_clusters/"

# -----------------------------------------------------------------------
# Step 2: Find the largest cluster by streamline count (file size proxy)
# -----------------------------------------------------------------------
echo ""
echo "Step 2: Finding the largest cluster..."

BIGGEST_CLUSTER=$(ls -S qbx_clusters/cluster_*.trk | head -n 1)
echo "Largest cluster  : ${BIGGEST_CLUSTER}"


# -----------------------------------------------------------------------
# Step 3: Shape measures on the largest cluster
# -----------------------------------------------------------------------
echo ""
echo "Step 3: Computing shape measures on the largest cluster..."

scil_bundle_shape_measures "${BIGGEST_CLUSTER}" \
    --out_json qbx_biggest_cluster_shape.json \
    --reference "${REF_IMG}" \
    --indent 2 \
    -f

echo "Shape measures written to: qbx_biggest_cluster_shape.json"
echo ""
python3 - <<'EOF'
import json
try:
    with open("qbx_biggest_cluster_shape.json") as f:
        m = json.load(f)
    if not isinstance(m, dict):
        raise ValueError("Unexpected JSON format")
    # If nested under a bundle key, extract inner dict
    if "streamlines_count" not in m and len(m) > 0:
        first_val = list(m.values())[0]
        if isinstance(first_val, dict):
            m = first_val
    def fmt(v): return f"{v:.1f}" if isinstance(v, float) else str(v)
    print("  Key shape measures for the largest cluster:")
    print(f"    Streamline count  : {fmt(m.get('streamlines_count', 'N/A'))}")
    print(f"    Avg length (mm)   : {fmt(m.get('avg_length', 'N/A'))}")
    print(f"    Min / Max length  : {fmt(m.get('min_length', 'N/A'))} / {fmt(m.get('max_length', 'N/A'))}")
    print(f"    Volume (mm³)      : {fmt(m.get('volume', 'N/A'))}")
    print(f"    Elongation        : {fmt(m.get('elongation', 'N/A'))}")
    print(f"    Mean curvature    : {fmt(m.get('mean_curvature', 'N/A'))}")
except Exception as e:
    print(f"  [Could not parse shape measures JSON: {e}]")
EOF


# -----------------------------------------------------------------------
# Step 4: Visualization instructions — MI-Brain
# -----------------------------------------------------------------------
echo ""
echo "======================================================================="
echo " Step 4: Visualization in MI-Brain (multi-bundle view)"
echo "======================================================================="
echo ""
echo "  MI-Brain can load an entire directory of .trk files at once and"
echo "  color each cluster automatically — ideal for inspecting QBX output."
echo ""
echo "  1. Open MI-Brain."
echo "  2. Load anatomy  : File > Open > fa.nii.gz"
echo "  3. Load clusters : File > Open > select all .trk files in qbx_clusters/"
echo "     OR drag-and-drop the entire qbx_clusters/ folder onto MI-Brain."
echo "  4. Each cluster appears as a distinct colored bundle."
echo "  5. Load centroids: File > Open > qbx_centroids.trk"
echo "     (centroids give a skeleton view of each cluster's geometry)"
echo ""
echo "  TIP: In MI-Brain's bundle panel, sort entries by streamline count"
echo "       to quickly identify which clusters correspond to major anatomical"
echo "       pathways (Corpus Callosum, CST, SLF, etc.)."
echo ""
echo "======================================================================="
echo " EXPERIMENT: Vary the distance threshold"
echo "======================================================================="
echo ""
echo "  Edit the DIST_THRESH variable at the top of this script and re-run:"
echo ""
echo "    DIST_THRESH=10  → finer clustering  (more, smaller clusters)"
echo "    DIST_THRESH=20  → coarser clustering (fewer, larger clusters)"
echo "    DIST_THRESH=30  → very coarse        (dominant pathways only)"
echo ""
echo "  Observe in MI-Brain how bundles split or merge as you change the"
echo "  threshold. This directly illustrates the scale-dependence of"
echo "  unsupervised tractography clustering."
echo ""
echo "Tutorial 5.1 complete."
