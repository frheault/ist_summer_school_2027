#!/bin/bash
# For pedagogical context, notes, and tips, refer to NOTEBOOK.md.
#
# ======================================================================
# dMRI Summer School - Tutorial 5.4 (Capstone Analysis)
#
# Theme: Capstone Project: Quantitative Structural Connectomics & SIFT2
#
# Goal: Compute SIFT2 streamline weights, build structural connectomes,
#       and calculate network graph metrics with NetworkX.
# ======================================================================

# CPU thread limit
export OMP_NUM_THREADS=4
export OPENBLAS_NUM_THREADS=4
export MRTRIX_NTHREADS=4
export ITK_GLOBAL_DEFAULT_NUMBER_OF_THREADS=4

# Step 1: SIFT2 Streamline Weighting
echo "Step 1: Computing SIFT2 streamline weights..."
tcksift2 wb_250k.tck wmfod.nii.gz sift2_weights.txt -nthreads 4 -force

# Step 2: Parcellation Node Relabeling
echo "Step 2: Relabeling parcellation nodes for connectomics..."
if [ -f "b0_synthseg.nii.gz" ]; then
    labelconvert b0_synthseg.nii.gz template/FreeSurferColorLUT.txt template/MrtrixLUT.txt synthseg_relabeled_nodes.nii.gz -force
elif [ -f "synthseg_in_dwi.nii.gz" ]; then
    labelconvert synthseg_in_dwi.nii.gz template/FreeSurferColorLUT.txt template/MrtrixLUT.txt synthseg_relabeled_nodes.nii.gz -force
fi

# Step 3: Generate Connectome Matrices (Raw & SIFT2-Weighted)
echo "Step 3: Generating structural connectivity matrices..."
tck2connectome wb_250k.tck synthseg_relabeled_nodes.nii.gz connectome.csv \
    -symmetric -zero_diagonal -scale_invnodevol -nthreads 4 -force

tck2connectome wb_250k.tck synthseg_relabeled_nodes.nii.gz connectome_sift2.csv \
    -tck_weights_in sift2_weights.txt \
    -symmetric -zero_diagonal -scale_invnodevol -nthreads 4 -force

# Step 4: Run Graph Theory Analysis in Python
echo "Step 4: Running NetworkX graph analysis on structural connectome..."
python3 tutorial_5.2_connectomics.py

# Step 5: Run QuickBundles Clustering
echo "Step 5: Running QuickBundles streamline clustering..."
bash tutorial_5.1_clustering.sh

echo "Tutorial 5.4 Capstone complete."
