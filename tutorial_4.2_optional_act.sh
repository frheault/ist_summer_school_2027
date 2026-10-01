#!/bin/bash
# For pedagogical context, notes, and tips, refer to NOTEBOOK.md.
#
# ======================================================================
# dMRI Summer School - Tutorial 4.2 (Optional): Anatomically-Constrained Tractography
#
# Theme: ACT with a SynthSeg-derived 5-tissue-type (5TT) image
#
# Goal: Build a 5TT image from SynthSeg, track with ACT from the GM-WM
#       interface, and compare with the non-ACT tractogram of Tutorial 4.2.
#       On this dataset (no distortion correction) ACT truncates many
#       streamlines: ACT needs a T1 that is well aligned with the DWI.
#
# Inputs:
#   - t1_synthseg.nii.gz, t1_to_b0_0GenericAffine.mat, b0_brain.nii.gz,
#     roi_precentral_l.nii.gz, roi_brainstem.nii.gz (from Tutorial 1.6)
#   - wmfod.nii.gz (from Tutorial 3.4), wb_100k.tck (from Tutorial 4.2)
#
# Outputs:
#   - 5tt_dwi.nii.gz, gmwmi.nii.gz, wb_100k_act.tck
#   (not used downstream: Tutorials 4.6 / 5.4 keep using wb_100k.tck)
# ======================================================================

set -e

export MRTRIX_NTHREADS=4
export ITK_GLOBAL_DEFAULT_NUMBER_OF_THREADS=4

# Step 1: 5TT image from SynthSeg (aseg-compatible labels) in T1 space
echo "Step 1: Building the 5TT image from SynthSeg..."
5ttgen freesurfer t1_synthseg.nii.gz 5tt_t1.nii.gz -lut template/FreeSurferColorLUT.txt -nocrop -force

# Step 2: Bring the 5TT to DWI space at 1 mm (rigid transform from Tutorial 1.6)
# Linear interpolation of tissue fractions: 5ttcheck may warn that fractions
# do not sum exactly to 1 at boundaries; this is acceptable for ACT.
echo "Step 2: Transforming the 5TT image to DWI space (1 mm)..."
mrgrid b0_brain.nii.gz regrid -voxel 1 ref_dwi_1mm.nii.gz -force
antsApplyTransforms -d 3 -e 3 -i 5tt_t1.nii.gz -r ref_dwi_1mm.nii.gz \
    -t t1_to_b0_0GenericAffine.mat -n Linear -o 5tt_dwi.nii.gz
5ttcheck 5tt_dwi.nii.gz

# Step 3: ACT tracking seeded at the grey/white matter interface
echo "Step 3: ACT tractography (100,000 streamlines)..."
5tt2gmwmi 5tt_dwi.nii.gz gmwmi.nii.gz -force
tckgen wmfod.nii.gz wb_100k_act.tck -act 5tt_dwi.nii.gz -backtrack -crop_at_gmwmi \
    -seed_gmwmi gmwmi.nii.gz -select 100000 -force

# Step 4: Compare with the non-ACT tractogram
echo "Step 4: ACT vs no ACT..."
for t in wb_100k.tck wb_100k_act.tck; do
    tckedit "$t" short_tmp.tck -maxlength 20 -force -quiet
    tckedit "$t" pre_tmp.tck -include roi_precentral_l.nii.gz -ends_only -force -quiet
    tckedit pre_tmp.tck cst_tmp.tck -include roi_brainstem.nii.gz -force -quiet
    echo "  ${t}: mean length $(tckstats "$t" -output mean -quiet) mm," \
         "< 20 mm: $(tckinfo short_tmp.tck -count -quiet | awk '/actual/{print $NF}')," \
         "CST_L: $(tckinfo cst_tmp.tck -count -quiet | awk '/actual/{print $NF}')"
done
rm -f short_tmp.tck pre_tmp.tck cst_tmp.tck

# Discussion: why does ACT shorten streamlines here? (Hint: overlay 5tt_dwi.nii.gz
# on b0_mean.nii.gz in mrview and look at the frontal lobe / EPI distortion.)
# [Optional] SIFT2 with ACT: tcksift2 wb_100k_act.tck wmfod.nii.gz sift2_act_weights.txt -act 5tt_dwi.nii.gz

echo "Tutorial 4.2 (optional ACT) complete. Compare in mrview:"
echo "mrview fa.nii.gz -tractography.load wb_100k.tck -tractography.load wb_100k_act.tck"
