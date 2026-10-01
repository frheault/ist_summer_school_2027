# Diffusion MRI Summer School 2027: PhD Study Guide

This guide is a companion and personal reference for the hands-on sessions of the 5-day dMRI Summer School. For each script it gives the scientific context, the key commands, and the visual quality control (QC) checks in MRView / MI-Brain. Section numbers match the curriculum sessions.

Run every script from the repository root, in the order below. Each script stops at the first error (`set -e`). "Your data" scripts start with plain `YOUR_*` assignments (e.g. `YOUR_DWI="YOUR_DWI.nii.gz"`): edit them in the file to point to your data. All commands, grouped by topic, are listed in [COMMANDS.md](COMMANDS.md).

---

## Installation & Environment

### Software Stack
- **MRtrix3**: CSD, fixels, tractography, SIFT2, MRView.
- **FSL**: `bet`, `flirt`, `fslhd`.
- **FreeSurfer / SynthSeg**: deep-learning anatomical segmentation (`mri_synthseg`).
- **ANTs**: rigid/affine registration (`antsRegistrationSyNQuick.sh`).
- **Scilpy & DIPY**: streamline processing, BundleSeg, QuickBundles, DKI, tractometry.
- **AMICO**: fast NODDI fitting.
- **NetworkX**: graph theory on structural connectomes.

### Running with Docker
```bash
docker run -it --rm -v "${PWD}":/summer_school -w /summer_school -p 8888:8888 frheault/ist_summer_school_2027
```

### Launching Interactive Notebooks
```bash
./launch_jupyter.sh   # then open http://localhost:8888
```

---

## Day 1: Foundations & setup

### Session 1.4: Setup and data (`check_installation.sh`, `tutorial_1.0_setup_data.sh`)
* **Context**: Verify the software stack, then organize the raw DICOMs into a BIDS-like structure.
* **Action**: Unzips `dicom_filtered_sub01.zip`, runs `dcm2niix`, and writes `bids_data/sub-01/ses-01/{dwi,anat}/`.
* **QC**: `mrinfo bids_data/sub-01/ses-01/dwi/dwi.nii.gz` should show 112×112×66×107 at 2 mm.

### Session 1.6: Registration & segmentation (`tutorial_1.6_registration_segmentation.sh`)
* **Context**: Diffusion and T1w images live in different spaces. We bring the anatomy (SynthSeg labels, MNI atlas ROIs) into DWI space.
* **Action**:
  1. Mean b0, then `bet -f 0.25 -m` gives `b0_brain_mask.nii.gz`.
  2. MNI template → b0 with `flirt` (12 dof). The MNI CC mask becomes `cc_roi.nii.gz` (nearest neighbour).
  3. `mri_synthseg --robust --parc` on the T1w.
  4. Skull-stripped T1w → b0 with ANTs **rigid** (`-t r`), producing `t1_to_b0.nii.gz`.
  5. SynthSeg → DWI space with `antsApplyTransforms -n NearestNeighbor`.
  6. Binary uint8 ROIs: `wm_mask`, `roi_precentral_l`, `roi_postcentral_l`, `roi_brainstem`.
* **QC**: `mrview b0_mean.nii.gz -overlay.load t1_to_b0.nii.gz`. The ventricles and the cortical ribbon should line up.
* **Tips**:
  - SynthSeg needs ~15 GB RAM. If it crashes or is killed, follow the comment in Step 3 to copy the precomputed segmentation from `/opt/ist2027/precomputed/` (or `precomputed/` for manual installs).
  - SynthSeg has **no corpus callosum label**, which is why the CC seed comes from the MNI atlas.
  - Try `-n Linear` on the labels to see fake intermediate labels appear.
  - Try `-t a` (affine) and compare: it is less stable than rigid for same-subject registration.

---

## Day 2: Core processing

### Session 2.3: QA & DTI (our data) (`tutorial_2.3_qa_our_data.sh`)
* **Context**: Inspect metadata and the b-table, check the mask, and fit DTI on the low-b shell only. The mean b0 (`dwiextract -bzero`) and the `bet` mask were made in Tutorial 1.6 and are reused here, not recomputed.
* **Action**:
  1. `mrinfo -shell_bvalues -shell_sizes` shows shells 0 / 300 / 1000 / 2000 with 7 / 8 / 32 / 60 volumes. The six b=0.001 volumes count as b0.
  2. Mask volume in mL, compared with a deliberately bad `bet -f 0.6`.
  3. `dwiextract -shells 0,1000`, then `dwi2tensor` and `tensor2metric` (FA, MD, RD, AD, RGB, EV).
* **QC**: The CC should be red (left-right), the CST blue, and the cingulum green. WM FA is about 0.4.
* **Tip**: To fix a flipped b-vector axis, run `scil_gradients_modify_axes dwi_dti.bvec dwi_dti_flipx.bvec -1 2 3`.

### Session 2.5: QA & DTI (your data) (`tutorial_2.5_qa_your_data.sh`)
* Same steps on your data. A bet mask is computed if `YOUR_MASK` is empty. Pick the DTI shells with `YOUR_SHELLS` (default `0,1000`).

### Session 2.6: Deterministic DTI tractography (`tutorial_2.6_det_tractography.sh`)
* **Context**: Follow the principal eigenvector from voxel to voxel.
* **Action**:
  1. `mrthreshold fa.nii.gz -abs 0.1` gives the tracking mask `fa_thr.nii.gz`.
  2. `tckgen -algorithm FACT ev.nii.gz -seed_image cc_roi.nii.gz -mask fa_thr.nii.gz -select 10000`.
* **QC**: `mrview fa.nii.gz -tractography.load dti_det_cc_10k.tck`. You should see the U-shape of the CC. Note how little lateral fanning DTI produces.

---

## Day 3: Microstructure, fixels & advanced tractography

### Session 3.3: Microstructure (our data) (`tutorial_3.3_microstructure_our_data.sh`)
* **Action**:
  - NODDI (`scil_NODDI_maps`, AMICO, about 2 min and 2 GB RAM) gives `NDI`, `ODI` and `ISOVF` (AMICO's `fit_FWF`).
  - DKI (`scil_dki_metrics`) gives `dki_mk`, `dki_ak` and `dki_rk`.
  - Free Water priors (`scil_freewater_priors`) extracts subject-specific axial diffusivity in single-fiber bundles (`para_diff.txt`) and ventricle MD (`iso_diff.txt`) from Day 2 DTI metrics.
  - Free Water elimination (`scil_freewater_maps`, AMICO, ~1 min and ~1.5 GB RAM) fits the bi-compartment model, giving `fit_FW.nii.gz` (copied to `fw.nii.gz`), `fit_FiberVolume.nii.gz`, and `DWI_corrected.nii.gz`.
* **QC**: NDI is high in the internal capsule. ODI is low in the CC and high in the centrum semiovale. ISOVF and Free Water (`fw.nii.gz`) are high in the ventricles and CSF sulci. Compare them: `mrview fa.nii.gz -overlay.load fw.nii.gz -overlay.load ISOVF.nii.gz`.
* **Notebook**: `notebooks/Day3_Microstructure_NODDI_DKI.ipynb` builds the AMICO scheme file by hand (`amico.util.fsl2scheme`, with `bStep` snapping b = 0.001 to 0) and shows NDI / ODI / ISOVF / FW / MK next to FA.

### Session 3.4: Fixels (our data) (`tutorial_3.4_fixels_our_data.sh`)
* **Action**:
  1. `dwi2response dhollander`, then `dwi2fod msmt_csd`, giving `wmfod.nii.gz`.
  2. `fod2fixel -afd fd.mif` writes `fixel_dir/`.
  3. `fixel2voxel count` gives `nufo.nii.gz`.
* **QC**: `mrview fa.nii.gz -fixel.load fixel_dir/fd.mif -overlay.load nufo.nii.gz`. Low-FA voxels in the centrum semiovale have 2–3 fixels.

### Session 3.5: Microstructure & fixels (your data) (`tutorial_3.5_microstructure_fixels_your_data.sh`)
* It first prints the shells and counts the non-zero ones (b > 10). On single-shell data it prints a warning: NODDI and DKI are not meaningful there, so comment out Steps 1–2 and swap in the 2-tissue (WM + CSF) `dwi2fod msmt_csd` command given in the comment of Step 3.

### Session 3.7: DET/PROB CSD tractography (our data) (`tutorial_3.7_csd_tractography_our_data.sh`)
* **Action**:
  1. Extract the b=0 and b=2000 shells. Lmax 8 needs at least 45 directions, and b=2000 has 60.
  2. MRtrix: `dwi2response tournier`, then `dwi2fod csd`, giving `fodf_ssst.nii.gz`.
  3. MRtrix tracking: `SD_STREAM` (deterministic) and `iFOD2` (probabilistic), with the same CC seed and FA mask as 2.6.
  4. A scilpy alternative is provided as commented lines in the script using `scil_frf_ssst`, `scil_fodf_ssst` and `scil_tracking_local --algo det|prob`.
* **QC**: Load `dti_det_cc_10k.tck`, `csd_det_cc_10k.tck` and `csd_prob_cc_10k.tck` together. CSD reaches the lateral cortex.
* **Tips**:
  - `iFOD1` is probabilistic, not deterministic.
  - scilpy `--nt` counts *seeds*, while `tckgen -select` counts *kept streamlines*.
  - Read MRtrix fODFs in scilpy with `--sh_basis tournier07`.

---

## Day 4: Bundle segmentation & tractometry

### Session 4.2: Bundle segmentation (our data) (`tutorial_4.2_bundle_segmentation_our_data.sh`)
* **Action**:
  1. 100k whole-brain iFOD2 streamlines on `wmfod.nii.gz`, seeded in WM (`wb_100k.tck`).
  2. Length filter to 20–200 mm (`wb_100k_filtered.tck`).
  3. ROI dissection. CC: `-include cc_roi`. Left CST: `-include roi_precentral_l -ends_only`, then `-include roi_brainstem`.
  4. BundleSeg: download the atlas, compute an ANTs affine (atlas → `t1_to_b0.nii.gz`), then run `scil_tractogram_segment_with_bundleseg ... --inverse`.
* **QC**: `mrview fa.nii.gz -tractography.load CST_L.tck -tractography.load bundleseg_automated/AF_L.tck`.

### Session 4.2 (Optional): Anatomically-Constrained Tractography (ACT) (`tutorial_4.2_optional_act.sh`)
* **Context**: ACT uses anatomical tissue priors (5TT) to terminate streamlines at the GM/WM interface. On raw/uncorrected EPI data with T1 misalignment, ACT can severely truncate streamlines.
* **Action**:
  1. Build a 5TT image from SynthSeg using `5ttgen freesurfer`.
  2. Transform 5TT to DWI space at 1 mm with ANTs.
  3. Generate GM-WM interface seed mask (`5tt2gmwmi`) and track with `tckgen -act ... -backtrack -crop_at_gmwmi`.
  4. Compare streamline length and CST recovery with non-ACT tractography.
* **QC**: Overlay `5tt_dwi.nii.gz` on `b0_mean.nii.gz` in mrview to observe EPI distortion effects.

### Session 4.3: Bundle segmentation (your data) (`tutorial_4.3_bundle_segmentation_your_data.sh`)
* The same ROI and BundleSeg steps, using `YOUR_WB_TCK`, `YOUR_T1` (skull-stripped T1w in DWI space) and `YOUR_PARCELLATION` (SynthSeg in DWI space).
* **No T1/SynthSeg in DWI space yet?** There is no "your data" version of Tutorial 1.6: run its Steps 1–6 on your files. The comment block at the top of the script lists the exact `mri_synthseg`, `antsRegistrationSyNQuick.sh -t r`, `antsApplyTransforms -n NearestNeighbor` and WM-mask commands with `your_data_*` names, plus the `tckgen` line for `your_data_wb_100k.tck`. Never use the precomputed SynthSeg on your own T1.

### Session 4.6: From tracts to tables (`tutorial_4.6_tracts_to_tables.sh`)
* **Action**:
  1. `scil_bundle_compute_centroid` and `scil_bundle_uniformize_endpoints`.
  2. `scil_bundle_label_map`.
  3. `scil_bundle_mean_std --density_weighting`, both whole-bundle and `--per_point`.
  4. `scil_json_merge_entries`, then `scil_plot_stats_per_point`.
* **QC**: Profile curves in `tractometry_profiles_plot/`. The notebook `notebooks/Day4_Tractometry_Profiling.ipynb` plots them too.

---

## Day 5: Build your analysis (Session 5.4)

### Track A: Tractometry (`tutorial_5.4A.sh`)
* **Action**: one self-contained script. The `YOUR_*` defaults point to the workshop data, so it runs as-is after Day 4.
  1. Length filter + ROI dissection of the left CST, then BundleSeg (the same commands as Tutorial 4.3).
  2. Along-tract profiling (the same commands as Tutorial 4.6) on `YOUR_FA`, `YOUR_MD` and `YOUR_NDI` into `${OUT_PREFIX}_tractometry/`. Without an NDI map, use the `METRICS` line given in the comment.
* **QC**: Inspect generated profiles in `${OUT_PREFIX}_tractometry/tractometry_profiles_plot/` and JSON summaries.

### Track B: Connectomics (`tutorial_5.4B.sh` + `tutorial_5.4B.py`)
* **Action**:
  1. `tcksift2` gives the streamline weights.
  2. `labelconvert` turns SynthSeg labels into 84 nodes (`MrtrixLUT`).
  3. `tck2connectome` builds the raw and SIFT2-weighted connectomes.
  4. The NetworkX metrics follow.
* **QC**: `mrview fa.nii.gz -connectome.init synthseg_relabeled_nodes.nii.gz -connectome.load connectome_sift2.csv`. The notebook `notebooks/Day5_Connectomics_Graph_Theory.ipynb` is the companion.

### Track C: Clustering (`tutorial_5.4C.sh`)
* **Action**: QuickBundlesX (`scil_tractogram_qbx`, default 15 mm) on `wb_100k.tck`, then shape measures of the largest cluster.
* **QC**: Load `qbx_clusters/*.trk` and `qbx_centroids.trk` in MI-Brain. Then edit `DIST_THRESH=15` at the top of `tutorial_5.4C.sh` (e.g. 10 or 20), re-run, and compare the number of clusters.
