#!/bin/bash
# For pedagogical context, notes, and tips, refer to NOTEBOOK.md.
#
# ======================================================================
# dMRI Summer School - Tutorial 5.4, Track B (Build your analysis: Connectomics)
#
# Theme: Quantitative Structural Connectomics & SIFT2
#
# Goal: Compute SIFT2 streamline weights, build structural connectomes,
#       and calculate network graph metrics with NetworkX.
#
# Inputs:
#   - wb_100k.tck (from Tutorial 4.2), wmfod.nii.gz (from Tutorial 3.4)
#   - synthseg_in_dwi.nii.gz (from Tutorial 1.6)
#   - template/FreeSurferColorLUT.txt, template/MrtrixLUT.txt
#
# Outputs:
#   - sift2_weights.txt, synthseg_relabeled_nodes.nii.gz
#   - connectome.csv (raw streamline count), connectome_sift2.csv (SIFT2-weighted)
# ======================================================================

set -e

# CPU thread limit
export OMP_NUM_THREADS=4
export OPENBLAS_NUM_THREADS=4
export MRTRIX_NTHREADS=4
export ITK_GLOBAL_DEFAULT_NUMBER_OF_THREADS=4

# Step 1: SIFT2 Streamline Weighting
echo "Step 1: Computing SIFT2 streamline weights..."
tcksift2 wb_100k.tck wmfod.nii.gz sift2_weights.txt -out_mu sift2_mu.txt -nthreads 4 -force

# Step 2: Parcellation Node Relabeling (SynthSeg/FreeSurfer IDs -> consecutive 1..84 node IDs)
echo "Step 2: Relabeling parcellation nodes for connectomics..."
labelconvert synthseg_in_dwi.nii.gz template/FreeSurferColorLUT.txt template/MrtrixLUT.txt synthseg_relabeled_nodes.nii.gz -force

# Step 3: Generate Connectome Matrices (Raw & SIFT2-Weighted)
echo "Step 3: Generating structural connectivity matrices..."
tck2connectome wb_100k.tck synthseg_relabeled_nodes.nii.gz connectome.csv \
    -symmetric -zero_diagonal -scale_invnodevol -nthreads 4 -force

tck2connectome wb_100k.tck synthseg_relabeled_nodes.nii.gz connectome_sift2.csv \
    -tck_weights_in sift2_weights.txt \
    -symmetric -zero_diagonal -scale_invnodevol -nthreads 4 -force

# Step 4: Run Graph Theory Analysis in Python
echo "Step 4: Running NetworkX graph analysis on structural connectome..."
python3 tutorial_5.4B.py

echo ""
echo "Tutorial 5.4 (Track B) complete."
echo "To visualize the SIFT2-weighted connectome in 3D (MRView):"
echo "  mrview fa.nii.gz -connectome.init synthseg_relabeled_nodes.nii.gz -connectome.load connectome_sift2.csv"
