# IST Summer School 2027: Tractography Workshop

This repository contains the hands-on tutorial scripts, sample data, and companion study guide for the 5-day workshop covering diffusion MRI from physics and data quality control to microstructure, tractography, tractometry, and structural connectomics.

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
2. **Day 2 — QA & DTI Tractography**: Raw data inspection, tensor fitting, scalar maps (FA, MD, RD, AD), DEC-FA maps, and deterministic tracking of the Corpus Callosum.
3. **Day 3 — Microstructure & CSD**: Multi-compartment models (NODDI, DKI), Fixel-Based Analysis (FBA / `fod2fixel`), MSMT-CSD, and probabilistic tractography (`iFOD2`).
4. **Day 4 — Pipelines & Tractometry**: Automated preprocessing pipelines (TractoFlow/QSIPrep), bundle dissection, and along-tract microstructural profiling with Scilpy.
5. **Day 5 — Clustering & Connectomics**: QuickBundles streamline clustering, SIFT2 filtering, structural connectomes, and graph theory analysis with NetworkX.

---

## Software & System Requirements

Participants are expected to bring their own laptops.

### Hardware Requirements

* **Operating System**: Linux (Ubuntu 20.04/22.04/24.04), macOS (Intel or Apple Silicon via Docker), or Windows 10/11 ([WSL2](https://learn.microsoft.com/en-us/windows/wsl/install) required).
* **CPU**: Multi-core 64-bit x86_64 processor (4+ cores recommended).
* **RAM**: 16 GB is strongly recommended. 8 GB (e.g., base MacBook Air) may struggle with the processing-intensive nature of the datasets and FreeSurfer SynthSeg inference.
* **Disk Space**: Please ensure you have at least **35 GB to 40 GB free** disk space (the Megadocker image/software stack requires ~20 GB, while workshop datasets and generated derivatives require an additional 10–15 GB).

### Software Stack Summary

* **MRtrix3 (v3.0.4)**: `mrinfo`, `dwiextract`, `dwi2tensor`, `tensor2metric`, `dwi2response`, `dwi2fod`, `fod2fixel`, `tckgen`, `tckedit`, `tcksift2`, `tck2connectome`, `mrview`.
* **FreeSurfer (v7.4.1 / v8.0)**: `mri_synthseg` (parcellation), `mri_convert`, `recon-all`, `freeview`.
* **FSL (v6.0.7)**: `bet` (brain extraction), `fslhd`, `flirt` (linear registration).
* **ANTs (v2.5.0)**: `antsRegistrationSyNQuick.sh`, `antsApplyTransforms`, `antsRegistration`.
* **Scilpy**: Python scripts and tools for dMRI processing and tractometry.
* **Python Stack (v3.10+)**: `scilpy`, `dipy`, `dmri-amico`, `pyAFQ`, `trx-python`, `torch`, `networkx`, `pandas`, `seaborn`, `matplotlib`, `scipy`, `numpy`, `nibabel`, `jupyterlab`.
* **Visualization & Utilities**: `dcm2niix`, `MI-Brain`, `ExploreDTI`, `unzip`, `curl`, `git`, `parallel`.

---

## Installation & Setup

### Option A: Megadocker Solution (Recommended)

This approach guarantees an identical, pre-configured software stack across all operating systems without local dependency conflicts.

#### 1. Install Docker & Pull the Image

Install [Docker](https://docs.docker.com/get-docker/). Once installed, pull the pre-built Megadocker image:

```bash
docker pull frheault/ist_summer_school_2027
```

*(Alternatively, you can build locally via `docker build -t frheault/ist_summer_school_2027 .`)*

#### 2. Launch the Interactive Container

Run the container with your current workspace mounted to `/data`, interactive shell, Jupyter port binding (`8888`), and X11 forwarding for visual tools (`MRView`, `MI-Brain`, `freeview`):

**On Linux (or WSL)**:

```bash
xhost +local:root
docker run -it --rm \
  -v "${PWD}":/summer_school \
  -w /summer_school \
  -p 8888:8888 \
  -e DISPLAY=DISPLAY \
  -v /tmp/.X11-unix:/tmp/.X11-unix \
  --ipc=host \
  frheault/ist_summer_school_2027
```

**On macOS**:

```bash
xhost + 127.0.0.1
docker run -it --rm \
  -v "${PWD}":/summer_school \
  -w /summer_school \
  -p 8888:8888 \
  -e DISPLAY=host.docker.internal:0 \
  --ipc=host \
  frheault/ist_summer_school_2027
```

---

### Option B: Local Conda / Virtualenv Setup & Manual Installation

Experienced users or native Linux/macOS users can configure environments manually. Windows users **should use Windows Subsystem for Linux ([WSL](https://learn.microsoft.com/en-us/windows/wsl/install))** to facilitate installation.

1. **Install Neuroimaging Suites**:
* [MRtrix3](https://www.mrtrix.org/download/)
* [FSL](https://fsl.fmrib.ox.ac.uk/fsl/fslwiki/FslInstallation)
* [FreeSurfer](https://surfer.nmr.mgh.harvard.edu/fswiki/DownloadAndInstall)
* [ANTs](https://github.com/ANTSX/ANTs)
* [Scilpy](https://github.com/scilus/scilpy)
* [dcm2niix](https://github.com/rordenlab/dcm2niix)
* [MI-Brain](https://github.com/imeka/mi-brain)
* [ExploreDTI](https://www.exploredti.com/)

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
. "FREESURFER_HOME/SetUpFreeSurfer.sh"
export FSLDIR=/opt/fsl
. "FSLDIR/etc/fslconf/fsl.sh"
export ANTSPATH=/opt/ants/bin/
export MRTRIX3_HOME=/opt/mrtrix3
export PATH="ANTSPATH:MRTRIX3_HOME/bin:PATH"
```

---

### Environment Verification
First, you need to naviguate to the folder containing the various scripts and data (e.g., `cd ~/code/ist_summer_school_2027/` or `cd /mnt/c/Users/[YourUser]/code/ist_summer_school_2027` on Windows WSL).
**If using the Megadocker:**
Then, mount the directory containing the verification script and execute the container directly:

```bash
docker run --rm -it \
  -v "${PWD}":/summer_school \
  frheault/ist_summer_school_2027 bash ./check_installation.sh
```

**If using a Manual Installation:**
```bash
bash check_installation.sh
```

A complete summary log will be saved to `installation_check.log`.

---

## Dataset Description & Structure

The workshop dataset is packaged in `dicom_filtered_sub01.zip` (~65 MB). It contains anonymized clinical research acquisitions:

1. **Multi-Shell Diffusion-Weighted Imaging (DWI)**:
* **Sequence**: Spin-Echo EPI, Single-Shot, AP phase encoding.
* **Matrix Size**: 110 * 110 * 70 slices.
* **Isotropic Resolution**: 2.0 * 2.0 * 2.0 mm^3.
* **TR / TE**: 8500 ms / 85 ms.
* **Gradient Scheme**: 96 volumes total:
* b = 0 s/mm^2 (6 non-diffusion baseline volumes)
* b = 1000 s/mm^2 (30 uniformly distributed directions)
* b = 2000 s/mm^2 (60 uniformly distributed directions)

2. **High-Resolution Anatomical Structural Image (T1w)**:
* **Sequence**: 3D MPRAGE T_1-weighted.
* **Resolution**: 1.0 mm^3 isotropic (192 sagittal slices).

3. **Reference Templates (`template/`)**:
* `template/mni_masked.nii.gz`: Skull-stripped MNI152 1 mm anatomical template.
* `template/mni_synthseg.nii.gz`: A precomputed WM/GM parcellation from FreeSurfer SynthSeg.
* `template/cc.nii.gz`: Corpus Callosum MNI152 anatomical binary mask.
* `template/FreeSurferColorLUT.txt`: FreeSurfer anatomical color and label lookup table.
* `template/MrtrixLUT.txt`: MRtrix3 structural connectome integer label lookup table.

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

* **`notebooks/Day3_Microstructure_NODDI_DKI.ipynb`**: Interactive fitting and visualization of AMICO NODDI and DIPY DKI models, voxel-wise parameter slicing, and comparison with tensor metrics in crossing fiber regions.
* **`notebooks/Day4_Tractometry_Profiling.ipynb`**: Loading along-tract JSON profile deliverables, plotting along-tract FA/MD/NDI profiles with confidence ribbons across bundles, and running statistical tests.
* **`notebooks/Day5_Connectomics_Graph_Theory.ipynb`**: Structural connectome visualization (raw vs. SIFT2 matrices), hub node identification, and graph-theoretical network analysis with NetworkX.

---

## References & Citations

If you use this repository, tutorial code, or tools in your research, please ``` the corresponding packages:

1. **MRtrix3**: Tournier, J.-D., et al. (2019). MRtrix3: A fast, flexible and open-source software framework for multi-modal diffusion MRI. *NeuroImage*, 202, 116137.
2. **Scilpy**: The SCIL tractography and diffusion processing suite, Université de Sherbrooke. [https://github.com/scilus/scilpy](https://github.com/scilus/scilpy).
3. **SynthSeg**: Billot, B., et al. (2023). Robust machine learning segmentation for large-scale neuroimaging. *Medical Image Analysis*, 86, 102789.
4. **AMICO (NODDI)**: Daducci, A., et al. (2015). Accelerated Microstructure Imaging via Convex Optimization (AMICO) for NODDI. *NeuroImage*, 105, 32–44.
5. **DIPY**: Garyfallidis, E., et al. (2014). DIPY, a library for the analysis of diffusion MRI data. *Frontiers in Neuroinformatics*, 8, 8.
6. **ANTs**: Avants, B. B., et al. (2011). An open source software framework for image registration with Advanced Normalization Tools (ANTs). *Insight Journal*, 2, 1–35.
7. **FSL**: Jenkinson, M., et al. (2012). FSL. *NeuroImage*, 62(2), 782–790.
8. **pyAFQ**: Kruper, J., et al. (2021). Evaluating the reproducibility of automated tractometry across datasets and pipelines. *NeuroImage*, 245, 118749.