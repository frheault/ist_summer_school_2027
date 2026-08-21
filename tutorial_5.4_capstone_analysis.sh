#!/bin/bash
# For pedagogical context, notes, and tips, refer to NOTEBOOK.md.
#
# ======================================================================
# dMRI Summer School - Tutorial 5.4 (Capstone Analysis)
#
# Theme: Capstone Project: Connectomics, SIFT2 & Streamline Clustering
#
# Goal: Compute SIFT2 streamline weights, build structural connectomes,
#       calculate network graph metrics with NetworkX, and run QuickBundles.
#
# Inputs:
#   - wb_250k.tck (Whole-brain tractogram from Tutorial 4.3)
#   - wmfod.nii.gz (fODF from Tutorial 3.4)
#   - synthseg_in_dwi.nii.gz (from Tutorial 1.5)
#
# Outputs:
#   - synthseg_relabeled_nodes.nii.gz (Relabeled connectome nodes)
#   - sift2_weights.txt (SIFT2 streamline weights)
#   - connectome.csv, connectome_sift2.csv (Connectome matrices)
#   - QuickBundles cluster centroids & graph metrics
# ======================================================================

# Step 1: Relabel SynthSeg nodes for MRtrix connectome tool
echo "Step 1: Relabeling SynthSeg nodes with MRtrix lookup tables..."
labelconvert synthseg_in_dwi.nii.gz \
    template/FreeSurferColorLUT.txt template/MrtrixLUT.txt \
    synthseg_relabeled_nodes.nii.gz -force

# Step 2: Compute SIFT2 Streamline Weights
echo "Step 2: Computing SIFT2 streamline weights..."
tcksift2 wb_250k.tck wmfod.nii.gz sift2_weights.txt -force

# Step 3: Generate Structural Connectome Matrices (Raw & SIFT2-Weighted)
echo "Step 3: Generating structural connectivity matrices..."
tck2connectome wb_250k.tck synthseg_relabeled_nodes.nii.gz connectome.csv \
    -symmetric -zero_diagonal -scale_invnodevol -force

tck2connectome wb_250k.tck synthseg_relabeled_nodes.nii.gz connectome_sift2.csv \
    -tck_weights_in sift2_weights.txt \
    -symmetric -zero_diagonal -scale_invnodevol -force

# Step 4: Run Graph Theory Analysis in Python
echo "Step 4: Running NetworkX graph analysis on structural connectome..."
python3 tutorial_5.2_connectomics.py

# Step 5: Run QuickBundles Clustering
echo "Step 5: Running QuickBundles streamline clustering..."
python3 tutorial_5.1_clustering.py

echo "Tutorial 5.4 complete. To visualize the connectome in 3D:"
echo "mrview fa.nii.gz -connectome.init synthseg_relabeled_nodes.nii.gz -connectome.load connectome_sift2.csv"
