#!/usr/bin/env python3
"""
dMRI Summer School - Tutorial 5.1
Theme: Tractography Clustering with QuickBundles (DIPY / Scilpy)
Goal: Perform unsupervised clustering on a whole-brain tractogram.
"""

import os
from dipy.io.streamline import load_tractogram, save_tractogram
from dipy.segment.clustering import QuickBundles
from dipy.tracking.streamline import set_number_of_points

tractogram_file = "wb_250k.trk" if os.path.exists("wb_250k.trk") else "dti_det_cc_10k.trk"

print(f"Loading tractogram: {tractogram_file}...")
sft = load_tractogram(tractogram_file, "same")
streamlines = sft.streamlines
print(f"Loaded {len(streamlines)} streamlines.")

# Resample streamlines to 12 equidistant points for fast distance computation
print("Resampling streamlines to 12 points...")
streamlines_resampled = set_number_of_points(streamlines, 12)

# QuickBundles clustering with a 15mm MDF distance threshold
print("Running QuickBundles clustering (threshold = 15.0 mm)...")
qb = QuickBundles(threshold=15.0)
clusters = qb.cluster(streamlines_resampled)

print(f"Clustering complete: Formed {len(clusters)} clusters from {len(streamlines)} streamlines.")

# Display summary of the 5 largest clusters
print("\nTop 5 Largest Clusters:")
for idx, cluster in enumerate(sorted(clusters, key=lambda c: len(c.indices), reverse=True)[:5]):
    print(f"  Cluster {idx + 1}: {len(cluster.indices)} streamlines")

print("\nTutorial 5.1 complete.")
