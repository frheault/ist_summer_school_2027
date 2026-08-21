# IST Summer School 2027: Diffusion MRI Workshop

Welcome to the **IST Summer School 2027 Diffusion MRI Workshop** repository. This repository contains the hands-on tutorial scripts, sample data, and companion study guide for the 5-day workshop covering diffusion MRI from physics and data quality control to microstructure, tractography, tractometry, and structural connectomics.


---

## Table of Contents
- [Workshop Overview](#workshop-overview)
- [5-Day Curriculum Table](#5-day-curriculum-table)
- [Software & System Requirements](#software--system-requirements)
- [Installation & Setup](#installation--setup)
  - [Option A: Docker (Recommended)](#option-a-docker-recommended)
  - [Option B: Local Conda / Virtualenv Setup](#option-b-local-conda--virtualenv-setup)
  - [Environment Verification](#environment-verification)
- [Dataset Description & Structure](#dataset-description--structure)
- [Pipeline Architecture & Execution DAG](#pipeline-architecture--execution-dag)
- [Quickstart: Step-by-Step Hands-on Tutorials](#quickstart-step-by-step-hands-on-tutorials)
- [Interactive Jupyter Notebooks](#interactive-jupyter-notebooks)
- [Repository Directory Structure](#repository-directory-structure)
- [Pedagogical Multi-Tool Reference](#pedagogical-multi-tool-reference)
- [Workspace Cleanup Utility](#workspace-cleanup-utility)
- [Instructors & Organizing Committee](#instructors--organizing-committee)
- [References & Citations](#references--citations)

---

## Workshop Overview

The workshop covers practical diffusion MRI processing and analysis across five days:

1. **Day 1 — Foundations & Registration**: dMRI physics, BIDS structure, rigid/affine multimodal registration (ANTs/FLIRT), and automated anatomical parcellation (SynthSeg).
2. **Day 2 — QA & DTI Tractography**: Raw data inspection, tensor fitting, scalar maps ($FA, MD, RD, AD$), DEC-FA maps, and deterministic tracking of the Corpus Callosum.
3. **Day 3 — Microstructure & CSD**: Multi-compartment models (NODDI, DKI), Fixel-Based Analysis (FBA / `fod2fixel`), MSMT-CSD, and probabilistic tractography (`iFOD2`).
4. **Day 4 — Pipelines & Tractometry**: Automated preprocessing pipelines (TractoFlow/QSIPrep), bundle dissection, and along-tract microstructural profiling with Scilpy.
5. **Day 5 — Clustering & Connectomics**: QuickBundles streamline clustering, SIFT2 filtering, structural connectomes, and graph theory analysis with NetworkX.


---

## 5-Day Curriculum Table

| Day | Session | Time | Type | Topic | Instructors / Leads | Script / Resource |
|:---:|:-------:|:----:|:----:|:------|:-------------------|:------------------|
| **Day 1** | **1.1** | 09:15–10:15 | Lecture | Why is neuroimaging useful? Clinical & Translational dMRI | Luis Concha | Keynote |
| | **1.2** | 10:45–11:45 | Lecture | Data Representations & Transformations (Spaces, Grids, Strides) | Francois Rheault | Lecture |
| | **1.3** | 13:15–15:15 | Clinic | Installation, Setup & Environment Verification | Organizers & TAs | `check_installation.sh`<br>`tutorial_1.0_setup_data.sh` |
| | **1.4** | 15:15–16:15 | Lecture | Introduction to dMRI Physics, Gradients & Attenuation | Alexander Leemans | Lecture |
| | **1.5** | 16:15–17:30 | **Lab** | Multimodal Registration (ANTs) & SynthSeg AI Segmentation | Hands-on Lab | `tutorial_1.5_registration_segmentation.sh` |
| **Day 2** | **2.1** | 09:00–09:45 | Lecture | Connectional Anatomy & White Matter Architecture | Chiara Maffei | Lecture |
| | **2.2** | 09:45–10:30 | Lecture | Preprocessing Overview: Artifacts, Noise & Distortions | Francois Rheault | Lecture |
| | **2.3** | 11:00–12:00 | Lecture | Modeling Overview: From Raw DWI to Orientation Fields | Alonso Ramirez | Lecture |
| | **2.4** | 13:30–14:15 | **Lab** | Quality Assurance & DTI Tensor Fitting (Our Data) | Hands-on Lab | `tutorial_2.4_qa_our_data.sh` |
| | **2.5** | 14:15–15:00 | **Lab** | Quality Assurance & Troubleshooting (Your Data) | Hands-on Lab | `tutorial_2.5_qa_your_data.sh` |
| | **2.6** | 15:00–16:00 | Lecture | Tractography Introduction: Numerical Streamline Integration | Donald Tournier | Lecture |
| | **2.7** | 16:00–17:30 | **Lab** | Deterministic DTI Tractography of the Corpus Callosum | Hands-on Lab | `tutorial_2.7_det_tractography.sh` |
| **Day 3** | **3.1** | 09:00–10:00 | Lecture | Intro to Microstructure Modelling (NODDI, DKI, MAP-MRI) | Alonso Ramirez | Lecture |
| | **3.2** | 10:30–11:30 | Lecture | Fixel-Based Analysis (FBA): FD, FC, and FDC Metrics | Donald Tournier | Lecture |
| | **3.3** | 11:30–12:30 | **Lab** | Microstructure Modeling: AMICO NODDI & DIPY DKI | Hands-on Lab | `tutorial_3.3_microstructure.sh`<br>`notebooks/Day3_Microstructure_NODDI_DKI.ipynb` |
| | **3.4** | 14:00–14:45 | **Lab** | Fixel-Based Analysis & FBA Extraction (Our Data) | Hands-on Lab | `tutorial_3.4_fixels_our_data.sh` |
| | **3.5** | 14:45–15:45 | **Lab** | Microstructure & Fixels on Personal Acquisitions | Hands-on Lab | `tutorial_3.5_microstructure_your_data.sh` |
| | **3.6** | 15:45–16:30 | Lecture | Tractography: Anatomy of a Command Line (CSD & ACT) | Donald Tournier | Lecture |
| | **3.7** | 16:30–17:30 | **Lab** | MSMT-CSD & Probabilistic Streamline Tractography | Hands-on Lab | `tutorial_3.7_csd_tractography.sh` |
| **Day 4** | **4.1** | 09:00–09:30 | Lecture | Preprocessing In-Depth: The Power of Automated Pipelines | Francois Rheault | Lecture |
| | **4.2** | 10:00–10:45 | Lecture | Bundle Segmentation: From Spaghetti to Highways | Chiara Maffei | Lecture |
| | **4.3** | 10:45–12:15 | **Lab** | 250k Whole-Brain Tractogram, Manual CST & BundleSeg | Hands-on Lab | `tutorial_4.3_bundle_segmentation.sh` |
| | **4.4** | 13:45–14:45 | **Lab** | Automated Bundle Segmentation (Your Data) | Hands-on Lab | `tutorial_4.4_bundle_segmentation_your_data.sh` |
| | **4.5** | 14:45–15:45 | Lecture | Tractometry: Quantitative Profiling Along Pathways | Alexander Leemans | Lecture |
| | **4.6** | 15:45–17:15 | **Lab** | From Tracts to Tables: Centroids, Profiling & JSON/CSV | Hands-on Lab | `tutorial_4.6_tracts_to_tables.sh`<br>`notebooks/Day4_Tractometry_Profiling.ipynb` |
| **Day 5** | **5.1** | 09:00–10:00 | Lecture / **Lab** | Tractography Clustering: QuickBundles & Superficial WM | Pamela Guevara | `tutorial_5.1_clustering.sh` |
| | **5.2** | 10:30–11:30 | Lecture | Structural Connectomics: SIFT2 Weighting & Graph Theory | Alessandro Daducci | `tutorial_5.2_connectomics.py` |
| | **5.3** | 11:30–12:30 | Panel | Experimental Study Design, Multi-Site QC & Pitfalls | Luis Concha & Alexander Leemans | Interactive Panel |
| | **5.4** | 15:00–18:00 | **Lab** | Capstone Project Sprint: Build Your Analysis Pipeline | Hands-on Hackathon | `tutorial_5.4_capstone_analysis.sh`<br>`notebooks/Day5_Connectomics_Graph_Theory.ipynb` |

---

## Software & System Requirements

### Hardware Requirements
- **Operating System**: Linux (Ubuntu 20.04/22.04/24.04), macOS (Intel or Apple Silicon via Docker), or Windows 10/11 (WSL2 required).
- **CPU**: Multi-core 64-bit x86_64 processor (4+ cores recommended).
- **RAM**: 8 GB minimum; 16 GB+ strongly recommended for FreeSurfer SynthSeg inference and 250k whole-brain tractography.
- **Disk Space**: At least 15 GB of free disk storage.

### Software Stack Summary
- **MRtrix3 (v3.0.4)**: `mrinfo`, `dwiextract`, `dwi2tensor`, `tensor2metric`, `dwi2response`, `dwi2fod`, `fod2fixel`, `tckgen`, `tckedit`, `tcksift2`, `tck2connectome`, `mrview`.
- **FreeSurfer (v7.4.1 / v8.0)**: `mri_synthseg` (AI parcellation), `mri_convert`, `recon-all`, `freeview`.
- **FSL (v6.0.7)**: `bet` (brain extraction), `fslhd`, `flirt` (linear registration).
- **ANTs (v2.5.0)**: `antsRegistrationSyNQuick.sh`, `antsApplyTransforms`, `antsRegistration`.
- **Python Stack (v3.10+)**: `scilpy`, `dipy`, `dmri-amico`, `pyAFQ`, `trx-python`, `torch`, `networkx`, `pandas`, `seaborn`, `matplotlib`, `scipy`, `numpy`, `nibabel`, `jupyterlab`.
- **Utilities**: `dcm2niix`, `unzip`, `curl`, `git`, `parallel`.

---

## Installation & Setup

### Option A: Docker (Recommended)

A single multi-stage container image packages all required neuroimaging suites, pre-configured environment paths, FreeSurfer licenses, and Python virtual environment.

#### 1. Build the Docker image
```bash
docker build -t ist_ws_2027 .
```

#### 2. Launch the interactive container
Run the container with current workspace mounted to `/data`, interactive shell, Jupyter port binding (`8888`), and X11 forwarding for visual tools (`MRView`, `MI-Brain`, `freeview`):

**On Linux**:
```bash
# Allow local X11 connections
xhost +local:root

# Run container
docker run -it --rm \
  -v "$(pwd)":/data \
  -w /data \
  -p 8888:8888 \
  -e DISPLAY=$DISPLAY \
  -v /tmp/.X11-unix:/tmp/.X11-unix \
  --ipc=host \
  ist_ws_2027
```

**On macOS (with XQuartz)**:
```bash
xhost + 127.0.0.1
docker run -it --rm \
  -v "$(pwd)":/data \
  -w /data \
  -p 8888:8888 \
  -e DISPLAY=host.docker.internal:0 \
  --ipc=host \
  ist_ws_2027
```

**On Windows (WSL2 / VcXsrv)**:
```bash
docker run -it --rm \
  -v "$(pwd)":/data \
  -w /data \
  -p 8888:8888 \
  -e DISPLAY=$DISPLAY \
  -v /tmp/.X11-unix:/tmp/.X11-unix \
  --ipc=host \
  ist_ws_2027
```

---

### Option B: Local Conda / Virtualenv Setup

If installing natively on a Linux host:

1. **Install Neuroimaging Suites**: Follow official documentation for [MRtrix3](https://www.mrtrix.org/download/), [FSL](https://fsl.fmrib.ox.ac.uk/fsl/fslwiki/FslInstallation), [ANTs](https://github.com/ANTsX/ANTs/releases), and [FreeSurfer](https://surfer.nmr.mgh.harvard.edu/fswiki/DownloadAndInstall).
2. **Create Python Environment**:
   ```bash
   python3 -m venv venv
   source venv/bin/activate
   pip install --upgrade pip setuptools wheel
   pip install -r requirements.txt
   ```
3. **Configure Environment Variables** (add to `~/.bashrc`):
   ```bash
   export FREESURFER_HOME=/opt/freesurfer
   [ -f "$FREESURFER_HOME/SetUpFreeSurfer.sh" ] && . "$FREESURFER_HOME/SetUpFreeSurfer.sh"
   export FSLDIR=/opt/fsl
   [ -f "$FSLDIR/etc/fslconf/fsl.sh" ] && . "$FSLDIR/etc/fslconf/fsl.sh"
   export ANTSPATH=/opt/ants/bin/
   export MRTRIX3_HOME=/opt/mrtrix3
   export PATH="$ANTSPATH:$MRTRIX3_HOME/bin:$PATH"
   ```

---

### Environment Verification

Run the automated diagnostic checker to test all 8 software suites and Python packages:
```bash
./check_installation.sh
```
A complete summary log is saved to `installation_check.log`.

---

## Dataset Description & Structure

The workshop dataset is packaged in `dicom_filtered_sub01.zip` (~65 MB). It contains anonymized clinical research acquisitions:

1. **Multi-Shell Diffusion-Weighted Imaging (DWI)**:
   - **Sequence**: Spin-Echo EPI, Single-Shot, AP phase encoding.
   - **Matrix Size**: $110 \times 110 \times 70$ slices.
   - **Isotropic Resolution**: $2.0 \times 2.0 \times 2.0\text{ mm}^3$.
   - **TR / TE**: $8500\text{ ms} / 85\text{ ms}$.
   - **Gradient Scheme**: 96 volumes total:
     - $b = 0\text{ s/mm}^2$ ($6$ non-diffusion baseline volumes)
     - $b = 1000\text{ s/mm}^2$ ($30$ uniformly distributed directions)
     - $b = 2000\text{ s/mm}^2$ ($60$ uniformly distributed directions)
2. **High-Resolution Anatomical Structural Image (T1w)**:
   - **Sequence**: 3D MPRAGE $T_1$-weighted.
   - **Resolution**: $1.0\text{ mm}^3$ isotropic ($192$ sagittal slices).
3. **Reference Templates (`template/`)**:
   - `template/mni_masked.nii.gz`: Skull-stripped MNI152 $1\text{ mm}$ anatomical template.
   - `template/cc.nii.gz`: Corpus Callosum MNI152 anatomical binary mask.
   - `template/FreeSurferColorLUT.txt`: FreeSurfer anatomical color and label lookup table.
   - `template/MrtrixLUT.txt`: MRtrix3 structural connectome integer label lookup table.

---

## Pipeline Architecture & Execution DAG

```
dicom_filtered_sub01.zip
   │
   ▼
[1.0] tutorial_1.0_setup_data.sh
   │  → Unpack DICOMs, dcm2niix conversion, BIDS formatting:
   │    bids_data/sub-01/ses-01/{dwi,anat}/*
   ▼
[1.5] tutorial_1.5_registration_segmentation.sh
   │  → b0 extraction, BET skull stripping, ANTs affine registration (T1w→b0),
   │    FreeSurfer SynthSeg AI segmentation, WM & CC ROI extraction:
   │    b0_mean.nii.gz, b0_mean_bet_mask.nii.gz, t1_synthseg.nii.gz,
   │    b0_synthseg.nii.gz, wm_mask.nii.gz, fa_cc.nii.gz
   ▼
[2.4] tutorial_2.4_qa_our_data.sh
   │  → Header QA, gradient verification, DTI tensor fitting, scalar maps:
   │    dti.nii.gz, fa.nii.gz, md.nii.gz, rgb.nii.gz, ev.nii.gz
   ▼
[2.7] tutorial_2.7_det_tractography.sh
   │  → Corpus Callosum deterministic DTI streamline tractography:
   │    dwi_brain.mif, fa_thr.nii.gz, dti_det_cc_10k.tck
   ▼
[3.3] tutorial_3.3_microstructure.sh ──► notebooks/Day3_Microstructure_NODDI_DKI.ipynb
   │  → AMICO NODDI biophysical modeling & DIPY/Scilpy DKI kurtosis fitting:
   │    NDI.nii.gz, ODI.nii.gz, ISOVF.nii.gz, dki_mk.nii.gz, dki_ak.nii.gz, dki_rk.nii.gz
   ▼
[3.4] tutorial_3.4_fixels_our_data.sh
   │  → MRtrix3 FBA fODF segmentation & Fiber Density (FD) metric extraction:
   │    fixel_dir/ (index.mif, directions.mif, fd.mif, peaks.mif)
   ▼
[3.7] tutorial_3.7_csd_tractography.sh
   │  → Response estimation (dhollander), MSMT-CSD fODFs, probabilistic iFOD2 tracking:
   │    wm.txt, gm.txt, csf.txt, wmfod.nii.gz, csd_prob_cc_10k.tck
   ▼
[4.3] tutorial_4.3_bundle_segmentation.sh
   │  → 250k whole-brain tractogram, manual CST_L dissection, automated BundleSeg:
   │    wb_250k.tck, CST_L.tck, zenodo_scil_atlas/, bundleseg_automated/ (*.tck)
   ▼
[4.6] tutorial_4.6_tracts_to_tables.sh ──► notebooks/Day4_Tractometry_Profiling.ipynb
   │  → Centroids, label maps, along-tract profilometry, JSON & CSV export:
   │    tractometry_results/, tractometry_profiles.json, tract_profiles.csv
   ▼
[5.1] tutorial_5.1_clustering.sh
   │  → QuickBundlesX streamline clustering, centroid streamlines & shape measures:
   │    qbx_clusters/, qbx_centroids.trk, qbx_biggest_cluster_shape.json
   ▼
[5.4] tutorial_5.4_capstone_analysis.sh ──► notebooks/Day5_Connectomics_Graph_Theory.ipynb
   │  → SIFT2 weighting, connectome matrices, NetworkX graph analysis:
   │    sift2_weights.txt, connectome_sift2.csv, network_metrics.json
   ▼
[Validation] clean_repo.sh + End-to-End Pipeline Execution Check
```

---

## Quickstart: Step-by-Step Hands-on Tutorials

Execute each tutorial script sequentially in your terminal:

```bash
# Day 1: Setup & Registration
./tutorial_1.0_setup_data.sh
./tutorial_1.5_registration_segmentation.sh

# Day 2: Quality Assurance & DTI Tracking
./tutorial_2.4_qa_our_data.sh
./tutorial_2.7_det_tractography.sh

# Day 3: Microstructure, Fixels & CSD Probabilistic Tracking
./tutorial_3.3_microstructure.sh
./tutorial_3.4_fixels_our_data.sh
./tutorial_3.7_csd_tractography.sh

# Day 4: Automated Bundle Segmentation & Tractometry Profiling
./tutorial_4.3_bundle_segmentation.sh
./tutorial_4.6_tracts_to_tables.sh

# Day 5: Streamline Clustering, Connectomics, SIFT2 & Graph Analysis Capstone
./tutorial_5.1_clustering.sh
./tutorial_5.4_capstone_analysis.sh
```

---

## Interactive Jupyter Notebooks

For interactive Python-based exploration, visualization, and statistical modeling, launch Jupyter Lab with the helper script:

```bash
./launch_jupyter.sh
```

Or manually:
```bash
jupyter lab --ip=0.0.0.0 --port=8888 --no-browser --allow-root
```

Access the Jupyter server by opening `http://localhost:8888` in your host browser.

### Available Notebooks in `notebooks/`:
- **`notebooks/Day3_Microstructure_NODDI_DKI.ipynb`**: Interactive fitting and visualization of AMICO NODDI and DIPY DKI models, voxel-wise parameter slicing, and comparison with tensor metrics in crossing fiber regions.
- **`notebooks/Day4_Tractometry_Profiling.ipynb`**: Loading along-tract JSON profile deliverables, plotting along-tract FA/MD/NDI profiles with confidence ribbons across bundles, and running statistical tests.
- **`notebooks/Day5_Connectomics_Graph_Theory.ipynb`**: Structural connectome visualization (raw vs. SIFT2 matrices), hub node identification, and graph-theoretical network analysis with NetworkX.

---

## Repository Directory Structure

```
ist_summer_school_2027/
├── .agents/                                    # AI agent workspace metadata
├── bids_data/                                  # BIDS structured NIfTI data (generated by 1.0)
│   └── sub-01/ses-01/{anat,dwi}/
├── notebooks/                                  # Interactive Python Jupyter Notebooks
│   ├── Day3_Microstructure_NODDI_DKI.ipynb     # Microstructure modeling (NODDI/DKI)
│   ├── Day4_Tractometry_Profiling.ipynb        # Along-tract profilometry & stats
│   └── Day5_Connectomics_Graph_Theory.ipynb    # Structural connectomics & graph theory
├── template/                                   # Anatomical templates and lookup tables
│   ├── FreeSurferColorLUT.txt                  # FreeSurfer label lookup table
│   ├── MrtrixLUT.txt                           # MRtrix3 connectome node lookup table
│   ├── cc.nii.gz                               # MNI152 Corpus Callosum binary mask
│   └── mni_masked.nii.gz                       # MNI152 1mm brain reference volume
├── tutorial_1.0_setup_data.sh                  # Day 1: Data extraction & BIDS conversion
├── tutorial_1.5_registration_segmentation.sh   # Day 1: ANTs registration & SynthSeg segmentation
├── tutorial_2.4_qa_our_data.sh                 # Day 2: Metadata QA & DTI tensor fitting
├── tutorial_2.5_qa_your_data.sh                # Day 2: Quality assurance on personal data
├── tutorial_2.7_det_tractography.sh            # Day 2: Deterministic CC DTI tractography
├── tutorial_3.3_microstructure.sh              # Day 3: AMICO NODDI & DIPY DKI fitting
├── tutorial_3.4_fixels_our_data.sh             # Day 3: MRtrix3 FBA fixel segmentation
├── tutorial_3.5_microstructure_your_data.sh    # Day 3: Microstructure & fixels on personal data
├── tutorial_3.7_csd_tractography.sh            # Day 3: MSMT-CSD & probabilistic tracking
├── tutorial_4.3_bundle_segmentation.sh         # Day 4: Whole-brain tracking, CST & BundleSeg
├── tutorial_4.4_bundle_segmentation_your_data.sh # Day 4: Bundle segmentation on personal data
├── tutorial_4.6_tracts_to_tables.sh            # Day 4: Tractometry profiling & CSV export
├── tutorial_5.1_clustering.sh                  # Day 5: QuickBundlesX streamline clustering
├── tutorial_5.2_connectomics.py                # Day 5: NetworkX graph theory analysis
├── tutorial_5.4_capstone_analysis.sh           # Day 5: SIFT2 connectome & NetworkX Capstone
├── check_installation.sh                       # Comprehensive environment diagnostic script
├── clean_repo.sh                               # Safe workspace cleanup utility
├── launch_jupyter.sh                           # JupyterLab server launcher
├── Dockerfile                                  # Multi-stage container recipe
├── requirements.txt                            # Python package dependencies
├── NOTEBOOK.md                                 # Comprehensive 5-Day PhD Study Guide
├── IST_summer_school_curriculum.md             # Complete curriculum & syllabus
└── README.md                                   # Workshop guide and landing page
```

---

## Pedagogical Multi-Tool Reference

Every hands-on tutorial demonstrates syntax differences across leading neuroimaging suites:

| Processing Step | MRtrix3 Syntax | Scilpy / Python Syntax | FSL / ANTs Syntax |
|:----------------|:---------------|:-----------------------|:------------------|
| **Brain Extraction** | `dwiextract \| mrmath` | `scil_dwi_extract_b0.py` | `bet b0.nii.gz b0_brain.nii.gz -f 0.25 -m` |
| **Image Registration**| `mrregister` | — | `antsRegistrationSyNQuick.sh -d 3 -f ... -m ...` |
| **Anatomical Parcellation** | `5ttgen freesurfer` | — | `mri_synthseg --i t1.nii.gz --o t1_synthseg.nii.gz` |
| **DTI Tensor Fitting** | `dwi2tensor -fslgrad bvec bval` | `scil_dti_metrics.py bval bvec` | `dtifit -k dwi.nii.gz -m mask -r bvec -b bval` |
| **Microstructure (NODDI)** | — | `amico.Evaluation()` / `scil_NODDI_maps` | — |
| **Fixel Analysis (FBA)** | `fod2fixel wmfod.nii.gz fixel_dir` | — | — |
| **Spherical Deconv (CSD)**| `dwi2fod msmt_csd` | `scil_fodf_msmt.py` | `bedpostx` (ball & stick) |
| **Streamline Tracking** | `tckgen -algorithm iFOD2` | `scil_tracking_local.py` | `probtrackx2` |
| **Bundle Segmentation** | `tckedit -include ...` | `scil_tractogram_segment_with_bundleseg.py` | — |
| **Tract Profiling** | — | `scil_compute_bundle_profile.py` | `pyAFQ` |
| **Connectome Weighting**| `tcksift2 wb.tck wmfod.nii.gz` | `scil_filter_streamlines` | `bedpostx / probtrackx2` matrix |

---

## Workspace Cleanup Utility

To reset your repository to a pristine state before or between tutorial runs:
```bash
./clean_repo.sh
```

*Note*: `clean_repo.sh` is safety-engineered to delete only generated data artifacts (`bids_data/`, `bundleseg_automated/`, `tractometry_results/`, intermediate `.nii.gz`, `.tck`, `.csv`, etc.) while strictly protecting all code, notebooks, documentation, and dataset zip archives.

---

## Instructors & Organizing Committee

- **Luis Concha** — Universidad Nacional Autónoma de México (UNAM)
- **Francois Rheault** — Université de Sherbrooke
- **Alexander Leemans** — University Medical Center Utrecht
- **Chiara Maffei** — Harvard Medical School / Massachusetts General Hospital
- **Donald Tournier** — King's College London
- **Alonso Ramirez** — Neuroimaging Researcher
- **Pamela Guevara** — Universidad de Concepción
- **Alessandro Daducci** — University of Verona

---

## References & Citations

If you use this repository, tutorial code, or tools in your research, please cite the corresponding packages:

1. **MRtrix3**: Tournier, J.-D., et al. (2019). MRtrix3: A fast, flexible and open-source software framework for multi-modal diffusion MRI. *NeuroImage*, 202, 116137.
2. **Scilpy**: The SCIL tractography and diffusion processing suite, Université de Sherbrooke. [https://github.com/scilus/scilpy](https://github.com/scilus/scilpy).
3. **SynthSeg**: Billot, B., et al. (2023). Robust machine learning segmentation for large-scale neuroimaging. *Medical Image Analysis*, 86, 102789.
4. **AMICO (NODDI)**: Daducci, A., et al. (2015). Accelerated Microstructure Imaging via Convex Optimization (AMICO) for NODDI. *NeuroImage*, 105, 32–44.
5. **DIPY**: Garyfallidis, E., et al. (2014). DIPY, a library for the analysis of diffusion MRI data. *Frontiers in Neuroinformatics*, 8, 8.
6. **ANTs**: Avants, B. B., et al. (2011). An open source software framework for image registration with Advanced Normalization Tools (ANTs). *Insight Journal*, 2, 1–35.
7. **FSL**: Jenkinson, M., et al. (2012). FSL. *NeuroImage*, 62(2), 782–790.
8. **pyAFQ**: Kruper, J., et al. (2021). Evaluating the reproducibility of automated tractometry across datasets and pipelines. *NeuroImage*, 245, 118749.
