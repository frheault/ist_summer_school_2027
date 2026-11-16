# Diffusion MRI Summer School 2027: Study Guide

This guide is a companion reference for the hands-on tutorials of the 5-day dMRI Summer School. For each session, it summarizes the goal, the main commands, and the visual quality control (QC) checks in MRView and MI-Brain. Section numbers match the curriculum sessions.

Run every script from the repository root in the order listed below. Each script stops at the first error (`set -e`). "Your data" scripts start with `YOUR_*` variables at the top of the file: edit those lines to point to your own files.

---

## Installation & Environment

### Software Stack
- **MRtrix3**: CSD, fixels, tractography, SIFT2, connectomics, MRView.
- **FSL**: `bet`, `flirt`, `fslhd`.
- **FreeSurfer / SynthSeg**: automated anatomical segmentation (`mri_synthseg`).
- **ANTs**: rigid and affine registration (`antsRegistrationSyNQuick.sh`, `antsApplyTransforms`).
- **Scilpy & DIPY**: streamline processing, BundleSeg, QuickBundlesX, DKI, tractometry.
- **AMICO**: fast NODDI and Free Water fitting.
- **NetworkX**: graph theory analysis on structural connectomes.

### Running with Docker
```bash
docker run -it --rm -v "${PWD}":/summer_school -w /summer_school -p 8888:8888 frheault/ist_summer_school_2027
```

### Launching Interactive Notebooks
```bash
./launch_jupyter.sh   # then open http://localhost:8888
```

---

## Day 1: Foundations & Setup

### Session 1.4: Setup and Data (`check_installation.sh`, `tutorial_1.0_setup_data.sh`)
* **Context**: Verify the software installation, then convert the raw DICOM archive into a BIDS folder structure.
* **Action**: Unzips `dicom_filtered_sub01.zip`, runs `dcm2niix`, and writes `bids_data/sub-01/ses-01/{dwi,anat}/`.
* **QC**: `mrinfo bids_data/sub-01/ses-01/dwi/dwi.nii.gz` shows a 112 × 112 × 66 × 107 grid at 2 mm isotropic resolution.

### Session 1.6: Registration & Segmentation (`tutorial_1.6_registration_segmentation.sh`)
* **Context**: Structural T1w and diffusion images are in different coordinate spaces. We align the MNI template and the T1w image to DWI space and extract anatomical masks.
* **Action**:
  1. Extract b0 volumes (`dwiextract -bzero`), compute the mean b0 (`mrmath mean`), and extract the brain mask (`bet -f 0.25 -m` -> `b0_brain_mask.nii.gz`).
  2. Register `template/mni_masked.nii.gz` to `b0_brain.nii.gz` with `flirt` (12 DOF), transform `template/cc.nii.gz` to `cc_roi.nii.gz` (nearest-neighbor), and convert the matrix to MRtrix format (`transformconvert`).
  3. Run `mri_synthseg --robust --parc` on `t1.nii.gz` to create `t1_synthseg.nii.gz`.
  4. Skull-strip the T1w image using the SynthSeg mask (`> 0`) and register `t1_brain.nii.gz` to `b0_brain.nii.gz` with ANTs rigid registration (`-t r` -> `t1_to_b0.nii.gz`).
  5. Transform `t1_synthseg.nii.gz` into DWI space with `antsApplyTransforms -n NearestNeighbor` (`synthseg_in_dwi.nii.gz`).
  6. Extract binary uint8 ROI masks (`wm_mask.nii.gz`, `roi_precentral_l.nii.gz`, `roi_postcentral_l.nii.gz`, `roi_brainstem.nii.gz`).
* **QC**: `mrview b0_mean.nii.gz -overlay.load t1_to_b0.nii.gz -overlay.opacity 0.4`. Check that the ventricles and cortex align.
* **Tips**:
  - SynthSeg uses ~15 GB of RAM. If it stops with an error, follow the comment in Step 3 to copy `/opt/ist2027/precomputed/t1_synthseg.nii.gz` (or `precomputed/t1_synthseg.nii.gz` on a manual install).
  - SynthSeg has **no corpus callosum label**, so the CC mask comes from the MNI template (Step 2).
  - Try `-n Linear` on the label map to see false intermediate label numbers at region borders.
  - Try `-t a` (affine) in Step 4 and compare with `-t r` (rigid).

---

## Day 2: Core Processing

### Session 2.3: QA & DTI (`tutorial_2.3_qa_our_data.sh`)
* **Context**: Inspect image headers and shells, check the brain mask, and fit the DTI model on low-b shells (`b <= 1000`).
* **Action**:
  1. `mrinfo -shell_bvalues -shell_sizes` lists shells 0, 300, 1000, and 2000 with 7, 8, 32, and 60 volumes. MRtrix treats `b < 10` as zero, so the six `b = 0.001` volumes count as `b = 0`.
  2. Compare the voxel count (`mrstats -output count -ignorezero`) of `b0_brain_mask.nii.gz` (`-f 0.25`) with a too-strict `bet -f 0.6` mask (`b0_brain_bad_mask.nii.gz`). Multiply the voxel count by the voxel volume (`2 × 2 × 2 = 8 mm³ = 0.008 mL`) to get the volume in mL.
  3. Extract the `b = 0` and `b = 1000` shells (`dwiextract -shells 0,1000`), fit the tensor (`dwi2tensor`), and compute `fa`, `md`, `rd`, `ad`, `rgb`, and unit `ev` (`tensor2metric`).
* **QC**: In `rgb.nii.gz`, the corpus callosum is red (left–right), the corticospinal tract is blue (inferior–superior), and the cingulum is green (anterior–posterior).
* **Tip**: If a b-vector axis is inverted, fix it with `scil_gradients_modify_axes dwi_dti.bvec dwi_dti_flipx.bvec -1 2 3`.

### Session 2.5: QA & DTI on Your Data (`tutorial_2.5_qa_your_data.sh`)
* Runs the same quality assurance and DTI workflow on your own files (`YOUR_DWI`, `YOUR_BVAL`, `YOUR_BVEC`). It computes `your_data_b0_brain_mask.nii.gz` with `bet` and fits DTI on `YOUR_SHELLS` (default `0,1000`).

### Session 2.6: Deterministic DTI Tractography (`tutorial_2.6_det_tractography.sh`)
* **Context**: Track streamlines by following the DTI principal eigenvector (`ev.nii.gz`) from voxel to voxel.
* **Action**:
  1. Threshold the FA map at 0.1 (`mrthreshold fa.nii.gz fa_thr.nii.gz -abs 0.1`) to create a tracking mask.
  2. Track 10,000 streamlines from `cc_roi.nii.gz` with `tckgen -algorithm FACT -angle 45 -select 10000`.
* **QC**: `mrview fa.nii.gz -tractography.load dti_det_cc_10k.tck`. Observe how DTI streamlines stay near the midline and stop at crossing-fiber regions.

---

## Day 3: Microstructure, Fixels & Advanced Tractography

### Session 3.3: Microstructure (`tutorial_3.3_microstructure_our_data.sh`)
* **Action**:
  1. Fit NODDI (`scil_NODDI_maps`, AMICO) to compute `NDI.nii.gz` (`fit_NDI`), `ODI.nii.gz` (`fit_ODI`), and `ISOVF.nii.gz` (`fit_FWF`).
  2. Fit DKI (`scil_dki_metrics`, DIPY) to compute `dki_mk.nii.gz`, `dki_ak.nii.gz`, and `dki_rk.nii.gz`.
  3. Fit Free Water Elimination (`scil_freewater_maps`, AMICO) to compute `fw.nii.gz` (`fit_FW`).
* **QC**: NDI is high in dense white matter (internal capsule). ODI is low in parallel bundles (corpus callosum) and high in crossing areas (centrum semiovale). ISOVF and FW are high in CSF and ventricles.
* **Notebook**: `notebooks/Day3_Microstructure_NODDI_DKI.ipynb` builds the AMICO scheme file with `amico.util.fsl2scheme` and displays FA, NDI, ODI, ISOVF, FW, and MK side by side.

### Session 3.4: Fixels (`tutorial_3.4_fixels_our_data.sh`)
* **Action**:
  1. Estimate 3-tissue response functions (`dwi2response dhollander`) and fit MSMT-CSD (`dwi2fod msmt_csd` -> `wmfod.nii.gz`).
  2. Segment continuous fODFs into discrete fixels (`fod2fixel -afd fd.mif` -> `fixel_dir/`).
  3. Count the number of fixels per voxel (`fixel2voxel fixel_dir/fd.mif count nufo.nii.gz`).
* **QC**: `mrview fa.nii.gz -fixel.load fixel_dir/fd.mif -overlay.load nufo.nii.gz`. Crossing-fiber voxels in the centrum semiovale have low FA but 2–3 distinct fixels.

### Session 3.5: Microstructure & Fixels on Your Data (`tutorial_3.5_microstructure_fixels_your_data.sh`)
* Reuses `your_data_b0_brain_mask.nii.gz` from Tutorial 2.5. It prints the shells of your dataset and fits NODDI, DKI, Free Water, and fixels.
* **Single-shell data**: NODDI, DKI, and 3-tissue MSMT-CSD require at least 2 non-zero shells (`b > 10`). On single-shell data, comment out Steps 2 and 3 (NODDI and DKI) and use the 2-tissue (WM + CSF) `dwi2fod msmt_csd` command shown in Step 5.

### Session 3.7: Deterministic vs Probabilistic CSD Tractography (`tutorial_3.7_csd_tractography_our_data.sh`)
* **Action**:
  1. Extract the `b = 0` and `b = 2000` shells (`dwi_ssst.nii.gz`). Spherical harmonics order 8 (`lmax 8`) requires at least 45 directions (`b = 2000` has 60).
  2. Estimate the single-shell response function (`dwi2response tournier`) and fit SSST-CSD (`dwi2fod csd` -> `fodf_ssst.nii.gz`).
  3. Track 10,000 streamlines from `cc_roi.nii.gz` inside `fa_thr.nii.gz` using `SD_STREAM` (deterministic) and `iFOD2` (probabilistic).
  4. A commented Scilpy alternative (`scil_frf_ssst`, `scil_fodf_ssst`, `scil_tracking_local --algo det|prob`) is included in the script.
* **QC**: Load `dti_det_cc_10k.tck`, `csd_det_cc_10k.tck`, and `csd_prob_cc_10k.tck` together in MRView. CSD resolves crossing fibers and reaches the lateral cortex.
* **Tips**:
  - Scilpy `--nt` counts total seeds, while MRtrix `tckgen -select` counts kept streamlines.
  - When reading an MRtrix fODF in Scilpy, always pass `--sh_basis tournier07`.

---

## Day 4: Bundle Segmentation & Tractometry

### Session 4.2: Bundle Segmentation (`tutorial_4.2_bundle_segmentation_our_data.sh`)
* **Action**:
  1. Generate a 100,000-streamline whole-brain tractogram (`wb_100k.tck`) on `wmfod.nii.gz`, seeded in `wm_mask.nii.gz`.
  2. Filter streamlines to 20–200 mm (`tckedit` -> `wb_100k_filtered.tck`).
  3. Extract `CC_bundle.tck` (`-include cc_roi.nii.gz`) and `CST_L.tck` (`-include roi_precentral_l.nii.gz -ends_only`, then `-include roi_brainstem.nii.gz`).
  4. Download the BundleSeg atlas, register the atlas T1 to `t1_to_b0.nii.gz` (`antsRegistrationSyNQuick.sh -t a`), and run `scil_tractogram_segment_with_bundleseg ... --inverse --reference fa.nii.gz`.
  5. Compare manual `CST_L.tck` and automated `bundleseg_automated/PYT_L.tck` counts (`tckinfo -count`).
* **QC**: `mrview fa.nii.gz -tractography.load CC_bundle.tck -tractography.load CST_L.tck`.

### Session 4.2 (Optional): Anatomically-Constrained Tractography (`tutorial_4.2_optional_act.sh`)
* **Context**: ACT uses a 5-tissue-type (`5TT`) image to stop streamlines at the GM–WM interface. Without EPI distortion correction, misalignment between the T1w and DWI images causes ACT to stop streamlines too early.
* **Action**: Build `5tt_t1.nii.gz` from SynthSeg (`5ttgen freesurfer`), transform it to 1 mm DWI space (`5tt_dwi.nii.gz`), extract the GM–WM interface (`5tt2gmwmi`), track `wb_100k_act.tck`, and compare streamline lengths with `tckstats`.

### Session 4.3: Bundle Segmentation on Your Data (`tutorial_4.3_bundle_segmentation_your_data.sh`)
* Runs length filtering, ROI dissection of the left CST, and BundleSeg on `YOUR_WB_TCK`, `YOUR_T1`, and `YOUR_PARCELLATION`. If you have not created your DWI-space T1w, SynthSeg parcellation, and whole-brain tractogram yet, follow the commands in the comment block at the top of the script.

### Session 4.6: From Tracts to Tables (`tutorial_4.6_tracts_to_tables.sh`)
* **Action**:
  1. Compute a 20-node bundle centroid (`scil_bundle_compute_centroid`) and align its endpoints (`scil_bundle_uniformize_endpoints`).
  2. Subdivide each bundle into 20 sections (`scil_bundle_label_map`).
  3. Extract density-weighted mean and standard deviation (`scil_bundle_mean_std --density_weighting`) for the whole bundle and per section (`--per_point`).
  4. Merge the JSON files (`scil_json_merge_entries`) and plot the profiles (`scil_plot_stats_per_point`).
* **QC**: Inspect the plots in `tractometry_profiles_plot/` or open `notebooks/Day4_Tractometry_Profiling.ipynb`.

---

## Day 5: Build Your Analysis (Session 5.4)

### Track A: Tractometry (`tutorial_5.4A.sh`)
* Self-contained end-to-end tractometry pipeline (length filtering, ROI left CST, BundleSeg, and 20-node along-tract profiling of FA, MD, and NDI). Defaults point to the workshop files, and all outputs are saved in `trackA_tractometry/`.

### Track B: Connectomics (`tutorial_5.4B.sh` + `tutorial_5.4B.py`)
* **Action**:
  1. Compute SIFT2 streamline weights (`tcksift2`).
  2. Convert SynthSeg labels into 84 consecutive nodes (`labelconvert` with `MrtrixLUT.txt`).
  3. Build raw (`connectome.csv`) and SIFT2-weighted (`connectome_sift2.csv`) 84 × 84 matrices (`tck2connectome -symmetric -zero_diagonal -scale_invnodevol`).
  4. Compute graph density, binary global efficiency, weighted clustering, and the top 5 hub nodes in NetworkX (`tutorial_5.4B.py` and `notebooks/Day5_Connectomics_Graph_Theory.ipynb`).
* **QC**: `mrview fa.nii.gz -connectome.init synthseg_relabeled_nodes.nii.gz -connectome.load connectome_sift2.csv`.

### Track C: Clustering (`tutorial_5.4C.sh`)
* **Action**: Run QuickBundlesX clustering (`scil_tractogram_qbx` at `DIST_THRESH=15` mm) on `wb_100k.tck`, find the largest cluster in `qbx_clusters/`, and print its geometric shape metrics (`scil_bundle_shape_measures` -> `qbx_biggest_cluster_shape.json`).
* **QC**: Load `fa.nii.gz`, `qbx_centroids.trk`, and `qbx_clusters/*.trk` in MI-Brain. Try `DIST_THRESH=10` or `20` and compare the number of clusters.
