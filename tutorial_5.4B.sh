#!/bin/bash
# See NOTEBOOK.md for study notes and quality control tips.
#
# ======================================================================
# dMRI Summer School - Tutorial 5.4, Track B (Session 5.4)
#
# Theme: Build Your Analysis: Structural Connectomics and SIFT2
#
# Goal: Compute SIFT2 streamline weights, build 84-node structural
#       connectome matrices, and compute graph metrics with NetworkX.
#
# Inputs:
#   - wb_100k.tck (Tutorial 4.2), wmfod.nii.gz (Tutorial 3.4)
#   - synthseg_in_dwi.nii.gz (Tutorial 1.6)
#   - template/FreeSurferColorLUT.txt, template/MrtrixLUT.txt
#
# Outputs:
#   - sift2_weights.txt, sift2_mu.txt, synthseg_relabeled_nodes.nii.gz
#   - connectome.csv (raw count), connectome_sift2.csv (SIFT2-weighted)
# ======================================================================

set -e

# Step 1: Compute SIFT2 streamline weights
echo "Step 1: Computing SIFT2 streamline weights..."
tcksift2 wb_100k.tck wmfod.nii.gz sift2_weights.txt -out_mu sift2_mu.txt -force

# Step 2: Convert SynthSeg labels to consecutive node IDs (1 to 84)
echo "Step 2: Converting SynthSeg labels to 84 connectome nodes..."
labelconvert synthseg_in_dwi.nii.gz template/FreeSurferColorLUT.txt \
    template/MrtrixLUT.txt synthseg_relabeled_nodes.nii.gz -force

# Step 3: Build structural connectivity matrices (raw and SIFT2-weighted)
echo "Step 3: Building raw and SIFT2-weighted connectivity matrices..."
tck2connectome wb_100k.tck synthseg_relabeled_nodes.nii.gz connectome.csv \
    -symmetric -zero_diagonal -scale_invnodevol -force

tck2connectome wb_100k.tck synthseg_relabeled_nodes.nii.gz connectome_sift2.csv \
    -tck_weights_in sift2_weights.txt \
    -symmetric -zero_diagonal -scale_invnodevol -force

# Step 4: Compute network graph metrics in Python (NetworkX)
echo "Step 4: Computing graph metrics with NetworkX..."
python3 tutorial_5.4B.py

echo "Tutorial 5.4 (Track B) complete. Inspect the connectome in mrview:"
echo "mrview fa.nii.gz -connectome.init synthseg_relabeled_nodes.nii.gz -connectome.load connectome_sift2.csv"
