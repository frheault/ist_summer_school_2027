# IST Summer School 2027: Tractography Workshop

This repository contains the hands-on tutorial scripts, sample data, and companion study guide ([NOTEBOOK.md](NOTEBOOK.md)) for the 5-day workshop. It covers diffusion MRI from physics and data quality control to microstructure, tractography, tractometry, and structural connectomics.

---

## Table of Contents
- [Workshop Overview](#workshop-overview)
- [Hands-on Scripts](#hands-on-scripts)
- [Software & System Requirements](#software--system-requirements)
- [Installation & Setup](#installation--setup)
- [Environment Verification](#environment-verification)
- [Dataset Description](#dataset-description)
- [Interactive Jupyter Notebooks](#interactive-jupyter-notebooks)
- [Workspace Cleanup](#workspace-cleanup)
- [References & Citations](#references--citations)

---

## Workshop Overview

1. **Day 1: Foundations & setup.** Motivation, dMRI physics, connectional anatomy, installation, data representations and transformations, registration and SynthSeg segmentation.
2. **Day 2: From raw DWI to tracts.** Preprocessing and modeling overview, QA and DTI (our data and your data), introduction to tractography, deterministic DTI tracking of the corpus callosum.
3. **Day 3: Microstructure, fixels & advanced tractography.** NODDI, DKI, and Free Water elimination, fixel-based analysis, CSD, deterministic vs. probabilistic tracking.
4. **Day 4: Bundle segmentation, tractometry & clustering.** ROI-based and automated (BundleSeg) segmentation, along-tract profiling, streamline clustering.
5. **Day 5: Validation, connectomics & interpretation.** Validation, connectomics, study design, and a "build your analysis" session (Track A tractometry, Track B connectomics, Track C clustering).

---

## Hands-on Scripts

Run the scripts from the repository root, in this order. Each script stops at the first error.

| Session | Script | Main outputs |
|---|---|---|
| 1.4 | `check_installation.sh`, `tutorial_1.0_setup_data.sh` | `bids_data/` |
| 1.6 | `tutorial_1.6_registration_segmentation.sh` | `b0_brain_mask`, `t1_to_b0`, `synthseg_in_dwi`, `cc_roi` |
| 2.3 | `tutorial_2.3_qa_our_data.sh` | `fa`, `md`, `rgb`, `ev` |
| 2.5 | `tutorial_2.5_qa_your_data.sh` | `your_data_*` |
| 2.6 | `tutorial_2.6_det_tractography.sh` | `dti_det_cc_10k.tck` |
| 3.3 | `tutorial_3.3_microstructure_our_data.sh` | `NDI`, `ODI`, `ISOVF`, `dki_mk`, `fw` |
| 3.4 | `tutorial_3.4_fixels_our_data.sh` | `wmfod`, `fixel_dir/`, `nufo` |
| 3.5 | `tutorial_3.5_microstructure_fixels_your_data.sh` | `your_data_*` |
| 3.7 | `tutorial_3.7_csd_tractography_our_data.sh` (scilpy alternative commented inside) | `csd_det_cc_10k`, `csd_prob_cc_10k` |
| 4.2 | `tutorial_4.2_bundle_segmentation_our_data.sh` | `wb_100k.tck`, `CC_bundle`, `CST_L`, `bundleseg_automated/` |
| 4.2 (opt.) | `tutorial_4.2_optional_act.sh` | `wb_100k_act.tck` (comparison only) |
| 4.3 | `tutorial_4.3_bundle_segmentation_your_data.sh` | `your_data_*` |
| 4.6 | `tutorial_4.6_tracts_to_tables.sh` | `tractometry_profiles.json`, `tractometry_profiles_plot/` |
| 5.4 A | `tutorial_5.4A.sh` | `trackA_tractometry/` |
| 5.4 B | `tutorial_5.4B.sh` (calls `tutorial_5.4B.py`) | `connectome_sift2.csv` |
| 5.4 C | `tutorial_5.4C.sh` | `qbx_clusters/` |

"Your data" scripts have plain variable assignments at the top of each file (e.g., `YOUR_DWI="YOUR_DWI.nii.gz"`). Simply edit the paths directly in the script to point to your files.

Every command used in the scripts is also listed by topic in [COMMANDS.md](COMMANDS.md), the consolidated command reference.

---

## Software & System Requirements

Participants are expected to bring their own laptops.

* **Operating System**: Linux, macOS (via Docker), or Windows 10/11 with [WSL2](https://learn.microsoft.com/en-us/windows/wsl/install).
* **CPU**: 64-bit x86_64, 4+ cores recommended. All scripts are capped at 4 threads.
* **RAM**: 16 GB minimum. FreeSurfer SynthSeg peaks at **~15 GB**; everything else stays under ~2 GB (NODDI). On macOS/Windows, raise the Docker Desktop memory limit (Settings > Resources). If SynthSeg is killed, follow the comment in `tutorial_1.6_registration_segmentation.sh` (Step 3) to copy the precomputed segmentation from `/opt/ist2027/precomputed/`.
* **Disk Space**: 25–30 GB free (the Docker image is about 22 GB; all derivatives about 1.5 GB).

### Software Stack (Docker image)

* **MRtrix3 3.0.8**: `mrinfo`, `dwiextract`, `dwi2tensor`, `tensor2metric`, `dwi2response`, `dwi2fod`, `fod2fixel`, `tckgen`, `tckedit`, `tcksift2`, `tck2connectome`, `mrview`.
* **FreeSurfer 7.4.1**: `mri_synthseg`, `freeview`.
* **FSL 6.0.7**: `bet`, `flirt`, `fslhd`.
* **ANTs 2.5.0**: `antsRegistrationSyNQuick.sh`, `antsApplyTransforms`.
* **Python 3.12**: `scilpy` 2.3, `dipy` 1.12, `dmri-amico` 2.1, `trx-python`, `networkx`, `pandas`, `seaborn`, `matplotlib`, `nibabel`, `jupyterlab`.
* **Utilities**: `dcm2niix`, `unzip`, `curl`, `git`, `parallel`.
* **Install on the host (not in the image)**: [MI-Brain](https://github.com/imeka/mi-brain), [TrackVis](https://trackvis.org/).

---

## Installation & Setup

### Option A: Docker (Recommended)

This option gives every participant the same pre-configured software stack on any operating system, with no local dependency conflicts.

Install [Docker](https://docs.docker.com/get-docker/), then pull the image:

```bash
docker pull frheault/ist_summer_school_2027
```

*(Alternatively, build locally with `docker build -t frheault/ist_summer_school_2027 .`)*

Launch the container from the repository folder. The command mounts the folder as `/summer_school`, forwards the Jupyter port (`8888`), and enables X11 so the viewers (`mrview`, `freeview`) can open windows.

**On Linux (or WSL)**:

```bash
xhost +local:root
docker run -it --rm \
  -v "${PWD}":/summer_school \
  -w /summer_school \
  -p 8888:8888 \
  -e DISPLAY="${DISPLAY}" \
  -v /tmp/.X11-unix:/tmp/.X11-unix \
  --ipc=host \
  frheault/ist_summer_school_2027
```

**On macOS** (requires [XQuartz](https://www.xquartz.org/) with "Allow connections from network clients" enabled):

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

### Option B: Manual Installation

Experienced users can install the software themselves. Windows users **should use [WSL](https://learn.microsoft.com/en-us/windows/wsl/install)**.

1. **Install the neuroimaging suites**: [MRtrix3](https://www.mrtrix.org/download/), [FSL](https://fsl.fmrib.ox.ac.uk/fsl/fslwiki/FslInstallation), [FreeSurfer](https://surfer.nmr.mgh.harvard.edu/fswiki/DownloadAndInstall), [ANTs](https://github.com/ANTsX/ANTs), [dcm2niix](https://github.com/rordenlab/dcm2niix).

2. **Create the Python environment**:
```bash
python3 -m venv venv
source venv/bin/activate
pip install --upgrade pip setuptools wheel
pip install -r requirements.txt
```

3. **Configure environment variables** (add to `~/.bashrc`, adapting the paths):
```bash
export FREESURFER_HOME=/opt/freesurfer
. "$FREESURFER_HOME/SetUpFreeSurfer.sh"
export FSLDIR=/opt/fsl
. "$FSLDIR/etc/fslconf/fsl.sh"
export ANTSPATH=/opt/ants/bin/
export MRTRIX3_HOME=/opt/mrtrix3
export PATH="$ANTSPATH:$MRTRIX3_HOME/bin:$PATH"
```

---

## Environment Verification

Go to the repository folder (e.g., `cd ~/code/ist_summer_school_2027`, or `cd /mnt/c/Users/[YourUser]/code/ist_summer_school_2027` on WSL), then run:

**Docker:**
```bash
docker run --rm -v "${PWD}":/summer_school -w /summer_school \
  frheault/ist_summer_school_2027 bash ./check_installation.sh
```

**Manual installation:**
```bash
bash check_installation.sh
```

A summary log is saved to `installation_check.log`.

---

## Dataset Description

The workshop dataset is packaged in `dicom_filtered_sub01.zip` (~65 MB) and contains anonymized research acquisitions. `tutorial_1.0_setup_data.sh` converts it to NIfTI.

1. **Multi-shell diffusion-weighted imaging (DWI)**
   * Philips 3 T spin-echo EPI, AP phase-encoding axis (no reverse-PE b0), TR/TE = 4800/92 ms (from the DICOM headers).
   * Matrix 112 × 112 × 66, 2 mm isotropic.
   * 107 volumes:
     - b = 0 (7 volumes; 6 of them are stored as b = 0.001)
     - b = 300 (8 directions)
     - b = 1000 (32 directions)
     - b = 2000 (60 directions)
2. **T1-weighted anatomical image**: 3D T1-TFE (Philips MPRAGE-type), TR/TE = 7.9/3.5 ms, 1 mm isotropic, matrix 224 × 224 × 150.
3. **Reference templates (`template/`)**
   * `mni_masked.nii.gz`: skull-stripped MNI152 1 mm template.
   * `cc.nii.gz`: corpus callosum binary mask in MNI space.
   * `FreeSurferColorLUT.txt` and `MrtrixLUT.txt`: label lookup tables used by `labelconvert`.

---

## Interactive Jupyter Notebooks

Launch Jupyter Lab inside the container:

```bash
./launch_jupyter.sh
```

Then open `http://localhost:8888` in your browser. The notebooks are in `notebooks/`:

* **`Day3_Microstructure_NODDI_DKI.ipynb`**: visualize the NODDI and DKI maps against DTI (run tutorial 3.3 first).
* **`Day4_Tractometry_Profiling.ipynb`**: along-tract FA, MD and NDI profiles (run tutorial 4.6 first).
* **`Day5_Connectomics_Graph_Theory.ipynb`**: raw vs. SIFT2 connectomes, hubs, and graph metrics (run tutorial 5.4 Track B first).

---

## Workspace Cleanup

`bash clean_repo.sh` deletes all generated files and keeps only the workshop sources.

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
