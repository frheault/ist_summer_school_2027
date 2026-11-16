#!/bin/bash
# See NOTEBOOK.md for study notes and quality control tips.
#
# ======================================================================
# dMRI Summer School - Tutorial 4.2 (Optional - ACT)
#
# Theme: Anatomically-Constrained Tractography (ACT)
#
# Goal: Build a 5-tissue-type (5TT) image from SynthSeg, run ACT
#       tractography seeded at the GM-WM interface, and compare
#       streamline lengths with wb_100k.tck from Tutorial 4.2.
#
# Inputs:
#   - t1_synthseg.nii.gz, t1_to_b0_0GenericAffine.mat, b0_brain.nii.gz (Tutorial 1.6)
#   - wmfod.nii.gz (Tutorial 3.4), wb_100k.tck (Tutorial 4.2)
#
# Outputs:
#   - 5tt_t1.nii.gz, ref_dwi_1mm.nii.gz, 5tt_dwi.nii.gz, gmwmi.nii.gz, wb_100k_act.tck
#   (Note: Tutorials 4.6 and 5.4 continue to use wb_100k.tck.)
# ======================================================================

set -e

# Step 1: Build the 5TT image from SynthSeg labels in T1w space
echo "Step 1: Building the 5TT image from SynthSeg..."
5ttgen freesurfer t1_synthseg.nii.gz 5tt_t1.nii.gz -lut template/FreeSurferColorLUT.txt -nocrop -force

# Step 2: Transform the 5TT image to DWI space on a 1 mm grid
echo "Step 2: Transforming the 5TT image to DWI space (1 mm)..."
mrgrid b0_brain.nii.gz regrid -voxel 1 ref_dwi_1mm.nii.gz -force
antsApplyTransforms -d 3 -e 3 -i 5tt_t1.nii.gz -r ref_dwi_1mm.nii.gz \
    -t t1_to_b0_0GenericAffine.mat -n Linear -o 5tt_dwi.nii.gz
5ttcheck 5tt_dwi.nii.gz

# Step 3: Extract the GM-WM interface and run ACT tractography
echo "Step 3: Running ACT tractography (100,000 streamlines)..."
5tt2gmwmi 5tt_dwi.nii.gz gmwmi.nii.gz -force
tckgen wmfod.nii.gz wb_100k_act.tck -act 5tt_dwi.nii.gz -backtrack -crop_at_gmwmi \
    -seed_gmwmi gmwmi.nii.gz -select 100000 -force

# Step 4: Compare streamline length statistics (non-ACT vs ACT)
# Note: Without EPI distortion correction, T1-to-DWI misalignment causes ACT to stop streamlines early.
echo "Step 4: Comparing streamline lengths (wb_100k.tck vs wb_100k_act.tck)..."
tckstats wb_100k.tck
tckstats wb_100k_act.tck

echo "Tutorial 4.2 (optional ACT) complete. Compare in mrview:"
echo "mrview fa.nii.gz -tractography.load wb_100k.tck -tractography.load wb_100k_act.tck"
