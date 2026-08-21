# Diffusion MRI Summer School 2027: PhD Study Guide

This guide is a complete companion and personal reference for the 5-day dMRI Summer School hands-on tutorials. It outlines each processing step with its scientific context, exact commands, and visual quality control checkpoints in MRView / MI-Brain.

---

## Installation & Environment

### Software Stack
The workshop utilizes an open-source neuroimaging stack:
- **MRtrix3**: CSD modeling, FBA (fixels), streamline tractography, SIFT2, and MRView.
- **FSL**: Brain extraction (`bet`), linear registration (`flirt`), headers (`fslhd`).
- **FreeSurfer / SynthSeg**: Deep-learning anatomical segmentation (`mri_synthseg`).
- **ANTs**: Multimodal affine & non-linear registration (`antsRegistrationSyNQuick.sh`).
- **Scilpy & DIPY**: Streamline processing, BundleSeg, QuickBundles, DKI, and tractometry.
- **AMICO**: Fast NODDI multi-compartment microstructure fitting.
- **NetworkX**: Graph-theory analysis of structural connectomes.

### Running with Docker
```bash
docker run -it --rm -p 8888:8888 -v /path/to/ist_summer_school_2027:/data -w /data ist_summer_school_2027
```

### Launching Interactive Notebooks
Inside the Docker container or local environment:
```bash
./launch_jupyter.sh
```
Then open `http://localhost:8888` in your laptop browser to access notebooks in `notebooks/`.

---

## Day 1: Foundations, Setup & Image Registration

### Hands-on 1.0: Setup and Data Download (`tutorial_1.0_setup_data.sh`)
* **Context**: Organizes raw DICOM data into the standardized Brain Imaging Data Structure (BIDS).
* **Action**: Unzips `dicom_filtered_sub01.zip`, runs `dcm2niix` to generate NIfTI files, and structures them into `bids_data/sub-01/ses-01/dwi/` and `bids_data/sub-01/ses-01/anat/`.

### Hands-on 1.5: Registration & Segmentation (`tutorial_1.5_registration_segmentation.sh`)
* **Context**: Diffusion and T1-weighted structural scans live in different coordinate spaces. We co-register T1w to DWI b0 space using ANTs affine registration and segment anatomical structures using FreeSurfer's AI-based `mri_synthseg`.
* **Action**:
  1. Extracts b0 reference and generates brain mask via FSL `bet`.
  2. Runs ANTs affine registration: `antsRegistrationSyNQuick.sh -d 3 -f b0_brain.nii.gz -m t1.nii.gz -t a -o t1_to_b0_`.
  3. Computes whole-brain parcellation: `mri_synthseg --i t1.nii.gz --o t1_synthseg.nii.gz --robust --parc --cpu`.
  4. Transforms parcellation into DWI space: `antsApplyTransforms -d 3 -i t1_synthseg.nii.gz -r b0_brain.nii.gz -t t1_to_b0_0GenericAffine.mat -n NearestNeighbor -o synthseg_in_dwi.nii.gz`.
  5. Extracts Corpus Callosum ROI (`cc_roi.nii.gz`) and White Matter mask (`wm_mask.nii.gz`).
* **Quality Control**: Load `b0.nii.gz` in `mrview` and overlay `synthseg_in_dwi.nii.gz` to confirm alignment of cortical and subcortical boundaries.

---

## Day 2: Core Processing: From Raw DWI to Tracts

### Hands-on 2.4: Quality Assurance & DTI Fitting (`tutorial_2.4_qa_our_data.sh`)
* **Context**: Inspects metadata, gradient directions, and fits the single-tensor Diffusion Tensor Imaging (DTI) model.
* **Action**:
  1. Inspects headers (`mrinfo`) and checks b-values / b-vectors.
  2. Fits DTI model: `dwi2tensor dwi.nii.gz dti.nii.gz -mask b0_brain_mask.nii.gz -fslgrad dwi.bvec dwi.bval`.
  3. Computes scalar maps: `tensor2metric dti.nii.gz -fa fa.nii.gz -adc md.nii.gz -vector rgb.nii.gz`.
* **Quality Control**: Open `fa.nii.gz` and `rgb.nii.gz` in `mrview`. Major white matter pathways should be bright on FA, and the Corpus Callosum should be distinctly red (Left-Right orientation).

### Hands-on 2.7: Deterministic DTI Tractography (`tutorial_2.7_det_tractography.sh`)
* **Context**: Reconstructs streamlines by following the principal eigenvector ($\mathbf{e}_1$) from voxel to voxel.
* **Action**: Runs `tckgen -algorithm Tensor_Det -seed_image cc_roi.nii.gz -mask fa_thr.nii.gz -select 10000 dwi_brain.mif dti_det_cc_10k.tck`.
* **Quality Control**: `mrview fa.nii.gz -tractography.load dti_det_cc_10k.tck`. Streamlines should form the characteristic interhemispheric U-shape of the Corpus Callosum.

---

## Day 3: Advanced Microstructure, Fixels & Advanced Tractography

### Hands-on 3.3: Microstructure Modeling (`tutorial_3.3_microstructure.sh`)
* **Context**: DTI assumes Gaussian diffusion and cannot separate intra-axonal from extra-axonal compartments. We fit multi-compartment NODDI (AMICO) and Diffusion Kurtosis Imaging (DIPY).
* **Action**:
  1. Computes NODDI maps (`scil_NODDI_maps` / AMICO): Neurite Density Index (`NDI`), Orientation Dispersion Index (`ODI`), and Isotropic Volume Fraction (`ISOVF`).
  2. Computes DKI maps (`scil_dki_metrics` / DIPY): Mean Kurtosis (`dki_mk`), Axial Kurtosis (`dki_ak`), Radial Kurtosis (`dki_rk`).
* **Quality Control**: Open `NDI.nii.gz` in `mrview`. Compact white matter bundles show high NDI ($>0.7$), cortex moderate ($\sim 0.3$), and ventricles near zero.

### Hands-on 3.4: Fixel-Based Analysis (`tutorial_3.4_fixels_our_data.sh`)
* **Context**: A "fixel" is a specific fiber population within a single voxel. fODF segmentation allows measuring fiber density without crossing-fiber volume averaging.
* **Action**:
  1. Estimates 3-tissue response functions (`dwi2response dhollander`).
  2. Fits Multi-Shell Multi-Tissue CSD (`dwi2fod msmt_csd`) to produce `wmfod.nii.gz`.
  3. Segments continuous fODFs into discrete fixels: `fod2fixel wmfod.nii.gz fixel_dir -afd fd.mif -peak peaks.mif`.
* **Quality Control**: `mrview b0.nii.gz -fixel.load fixel_dir/index.mif`. Inspect Centrum Semiovale to observe multiple crossing fixel vectors per voxel.

### Hands-on 3.7: CSD Probabilistic Tractography (`tutorial_3.7_csd_tractography.sh`)
* **Context**: Probabilistic tracking samples from the full fODF distribution (iFOD2), handling complex fiber crossings and fanning pathways.
* **Action**: Runs `tckgen -algorithm iFOD2 -seed_image cc_roi.nii.gz -mask b0_brain_mask.nii.gz -select 10000 wmfod.nii.gz csd_prob_cc_10k.tck`.
* **Quality Control**: Compare deterministic DTI vs. probabilistic CSD streamlines in `mrview`. CSD resolves wider lateral fanning branches into the cortex.

---

## Day 4: Pipelines, Bundle Segmentation & Tractometry

### Hands-on 4.3: Bundle Segmentation (`tutorial_4.3_bundle_segmentation.sh`)
* **Context**: Isolates anatomical white matter bundles using both manual ROI inclusion/exclusion logic and automated atlas-based recognition (`BundleSeg`).
* **Action**:
  1. Generates a 250k whole-brain tractogram: `tckgen wmfod.nii.gz wb_250k.tck -seed_image wm_mask.nii.gz -select 250000`.
  2. Virtual dissection of Left CST: `tckedit wb_250k.tck CST_L.tck -include precentral_L_roi.nii.gz -include brainstem_roi.nii.gz`.
  3. Automated segmentation via `BundleSeg` (`scil_tractogram_segment_with_bundleseg`).
* **Quality Control**: `mrview fa.nii.gz -tractography.load CST_L.tck -tractography.load bundleseg_automated/AF_left.trk`.

### Hands-on 4.6: Tractometry: From Tracts to Tables (`tutorial_4.6_tracts_to_tables.sh`)
* **Context**: Quantifies microstructural changes along the trajectory of a bundle by resampling streamlines to equidistant nodes.
* **Action**:
  1. Computes bundle centroid: `scil_bundle_compute_centroid`.
  2. Creates tract label map: `scil_bundle_label_map`.
  3. Samples metrics (FA, MD, NDI) along 20-100 points: `scil_bundle_mean_std --per_point`.
  4. Merges into JSON tables and plots along-tract profiles: `scil_json_merge_entries` & `scil_plot_stats_per_point`.
* **Quality Control**: Inspect generated profile curves in `tractometry_profiles_plot/`.

---

## Day 5: Clustering, Connectomics & Capstone Project

### Hands-on 5.1: Tractography Clustering (`tutorial_5.1_clustering.py`)
* **Context**: Unsupervised geometric clustering with QuickBundles groups whole-brain tractograms into coherent bundles based on streamline shape and distance.
* **Action**: Runs QuickBundles (`dipy.segment.clustering.QuickBundles`) with a 15mm threshold.

### Hands-on 5.2: Connectomics & Graph Theory (`tutorial_5.2_connectomics.py`)
* **Context**: Constructs structural brain networks where nodes are anatomical cortical/subcortical regions and edges are streamline connections. Computes network topology metrics with NetworkX (density, global efficiency, hub centrality).

### Hands-on 5.4: Capstone Analysis (`tutorial_5.4_capstone_analysis.sh`)
* **Context**: Integrates SIFT2 streamline filtering (`tcksift2`), structural connectome generation (`tck2connectome`), and graph theory analysis into an end-to-end reproducible workflow.
* **Action**: Runs SIFT2 weighting, generates `connectome_sift2.csv`, and executes the NetworkX analysis pipeline.
* **Quality Control**: Visualize connectome in 3D: `mrview fa.nii.gz -connectome.init synthseg_relabeled_nodes.nii.gz -connectome.load connectome_sift2.csv`.
