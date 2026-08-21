Here is the harmonized and updated curriculum aligned with the updated schedule in [IST_summer_school_schedule](https://docs.google.com/spreadsheets/d/1-53mGmWiw4spUbiti0I1kJMHaiB_VY7rC1xomSLmVzg/edit) and updated from the initial draft in [IST_summer_school_curriculum](https://docs.google.com/document/d/1Bf3vtp-5OWxffMOj9-nrjXlsonsYX6l6M9Md_fjwla8/edit).

---

### Review Guide

* Highlighted in Yellow: Items requiring **manual validation** (unconfirmed presenters, sponsor details, event naming, specific scripts/links).
* Text in Blue: **New sessions and newly drafted content** (objectives, prerequisites, open-source tool stacks, outline, and hands-on code).

---

# Diffusion MRI Summer School Curriculum [Validate: "Summer School" vs. "Winter School"]

# Part I: Program Overview & General Information

This document provides a comprehensive curriculum for a **5-day intensive school** on diffusion Magnetic Resonance Imaging (dMRI). The program is designed to guide participants from foundational imaging concepts to advanced biophysical modeling, fixel-based analysis, tractography clustering, bundle segmentation, tractometry, and connectomics.

### Program at a Glance

**Table 1: High-Level Schedule**

| Day | Time Block | Daily Theme | Key Topics |
| --- | --- | --- | --- |
| **Day 1** | Full day (08:30–17:30) | Foundations, Setup & Image Registration | Neuroimaging rationale, data primitives & spaces, environment setup clinic, dMRI physics, hands-on registration & segmentation |
| **Day 2** | Full day (08:30–17:30) | Basics, Quality Control & DTI Tractography | Connectional anatomy, preprocessing overview, DTI/ODF modeling, hands-on QA (our & your data), tractography introduction, deterministic tracking |
| **Day 3** | Full day (08:30–17:30) | Microstructure, Fixels & Advanced Tractography | Microstructure modeling (NODDI/DKI), Fixel-Based Analysis (FBA), hands-on microstructure & fixels, CSD/fODF command-line anatomy, hands-on DET/PROB tracking |
| **Day 4** | Full day (08:30–17:15) | Pipelines, Bundle Segmentation & Tractometry | Automated pipelines (BIDS/TractoFlow/QSIPrep), bundle segmentation theory & hands-on (our & your data), tractometry profiling, hands-on tracts-to-tables |
| **Day 5** | Full day (08:30–18:00) | Clustering, Connectomics & Capstone Project | Tractography clustering (QuickBundles/RecoBundles), connectomics & network filtering (SIFT2/COMMIT), study design & interpretation, hands-on project sprint / build your analysis |

---

### Software & System Requirements

**Table 2: Required Software Stack**

| Software | Purpose | Installation Guidance / Reference |
| --- | --- | --- |
| **MRtrix3** | dMRI analysis, CSD modeling, FBA (fixels), tractography, SIFT2, and MRView visualization. | [MRtrix3 Download](https://www.mrtrix.org/download/) |
| **FSL** | Brain extraction (`bet`), motion/eddy correction (`eddy`), linear registration (`flirt`), and distortion correction (`topup`). | [FSL Installation Guide](https://fsl.fmrib.ox.ac.uk/fsl/fslwiki/FslInstallation) |
| **FreeSurfer / SynthSeg** | Structural MRI parcellation, surface reconstruction, and AI-based robust segmentation (`mri_synthseg`). | [FreeSurfer Download](https://surfer.nmr.mgh.harvard.edu/fswiki/DownloadAndInstall) |
| **ANTs** | Advanced linear and non-linear SyN image registration and spatial normalization. | [ANTs GitHub Repository](https://github.com/ANTsX/ANTs) |
| **Scilpy** | Python library for streamline processing, bundle segmentation (BundleSeg), clustering, and tractometry. | [Scilpy Documentation](https://www.google.com/search?q=https://scil-documentation.readthedocs.io/en/latest/) |
| **DIPY** | Diffusion imaging in Python: microstructure (DKI, MAP-MRI), clustering (QuickBundles), and RecoBundles. | [DIPY Installation](https://www.google.com/search?q=https://dipy.org/documentation/latest/installation/) |
| **AMICO** | Accelerated Microstructure Imaging via Convex Optimization (fast NODDI and multi-compartment fitting). | [AMICO GitHub Repository](https://github.com/daducci/AMICO) |
| **pyAFQ** | Automated Fiber Quantification and along-tract microstructural profiling (tractometry). | [pyAFQ Documentation](https://yeatmanlab.github.io/pyAFQ/) |
| **dcm2niix** | DICOM to NIfTI conversion and BIDS sidecar generation. | [dcm2niix GitHub](https://github.com/rordenlab/dcm2niix) |
| **MI-Brain** | Interactive tractogram visualization, ROI delineation, and bundle inspection. | [MI-Brain GitHub](https://github.com/imeka/mi-brain) |

---

# Part II: Detailed Daily Curriculum

---

## Day 1: Foundations, Setup & Image Registration (Full Day)

* **Daily Theme**: Establishing computational readiness, foundational imaging concepts, and structural preprocessing.
* **Daily Goal**: Verify that all participant software environments are fully operational, review core dMRI physics, and learn linear/non-linear multimodal registration and anatomical segmentation.

```
08:30 - 09:00 | Arrival of organizing committee
09:00 - 09:15 | Welcome
09:15 - 10:15 | Session 1.1: Why is neuroimaging useful? [Presenter: Luis Concha]
10:15 - 10:45 | Break
10:45 - 11:45 | Session 1.2: Data Representations & Transformations [Presenter: Francois Rheault]
11:45 - 13:15 | Lunch
13:15 - 15:15 | Session 1.3: Installation, setup and verification [Clinic / Hands-on Support]
15:15 - 16:15 | Session 1.4: Introduction to dMRI physics [Presenter: Alexander Leemans]
16:15 - 17:30 | Session 1.5: Hands-on on registration and segmentation [Hands-on Lab]

```

#### Session 1.1: Why is neuroimaging useful?

* **Format**: Theoretical & Clinical Keynote Lecture (1h00)
* **Presenter**: Luis Concha
* **Goals**:
* Understand the clinical, translational, and fundamental neuroscience motivations behind diffusion MRI.
* Explore real-world applications: presurgical tractography mapping, epilepsy focus delineation, traumatic brain injury (TBI), neurodegenerative disease biomarker discovery, and developmental neuroplasticity.
* Appreciate the bridge between microstructural biophysics and macroscale brain connectivity.


* **Prerequisites**: General scientific background.
* **Outline & Concepts**:
* *Clinical Applications*: Presurgical tractography in neurosurgery (e.g., motor strip and optic radiations preservation), tumor infiltration vs. displacement.
* *Translational Research*: Biomarkers for axonal integrity, demyelination, neuroinflammation, and edema.
* *Cognitive & Systems Neuroscience*: Individual differences in structural connectivity and behavioral correlations.



#### Session 1.2: Data Representations & Transformations

* **Format**: Theoretical Lecture (1h00)
* **Presenter**: Francois Rheault
* **Goals**:
* Define and differentiate between voxel grids (volumetric), surface meshes (vertices/faces), and streamlines (3D polylines).
* Master the hierarchy of linear spatial transformations (translation, rigid 6-DOF, affine 12-DOF) and non-linear diffeomorphic deformations (warps/displacements).
* Understand coordinate systems (world space, scanner space, voxel space, RAS+ vs. LPS+, strides, and affine transformation matrices).


* **Prerequisites**: Basic linear algebra (matrices and vectors).
* **Outline & Concepts**:
* *Data Primitives*: 3D/4D voxel rasters, triangular meshes, polylines with point-wise scalar attributes.
* *Transformation Hierarchy*: Rigid (motion correction), Affine (inter-modal alignment), Non-linear SyN / B-splines (atlas normalization).
* *Reference Spaces & Conventions*: NIfTI qform/sform, orientation strides, and pitfalls in file conversions.



#### Session 1.3: Installation, Setup and Verification

* **Format**: Technical Support Clinic & Hands-on Verification (2h00)
* **Goals**:
* Resolve local operating system, WSL2, Docker/Singularity container, and native package configuration issues.
* Execute and validate the verification script (`check_setup.sh`) across all required neuroimaging tools.
* Download, verify, and organize the workshop tutorial datasets.


* **Prerequisites**: Pre-workshop installation attempt.
* **Data & Tools**:
* Participant laptops.
* Verification script check_setup.sh.
* Data download script tutorial_1.0_setup_data.sh.


* **Outline**:
* Verification of Docker/Megadocker execution with adequate RAM and CPU allocation.
* Resolution of path and library conflicts (virtual environments, Conda, system binaries).
* Dataset sanity checks (file integrity, dimensions, header orientations).



#### Session 1.4: Introduction to dMRI Physics

* **Format**: Theoretical Lecture (1h00)
* **Presenter**: Alexander Leemans
* **Goals**:
* Understand how diffusion magnetic resonance imaging produces contrast from Brownian motion of water molecules.
* Relate b-values and gradient encoding vectors (b-vectors) to diffusion attenuation.
* Distinguish free, hindered, and restricted diffusion in white matter microstructure.


* **Prerequisites**: General MRI physics principles ($T_1$, $T_2$, RF excitation).
* **Outline & Concepts**:
* Physical displacement of water molecules and Gaussian diffusion approximations.
* Pulsed gradient spin-echo (PGSE) Stejskal-Tanner conceptual framework.
* The role of b-value: diffusion weighting strength, SNR tradeoffs, and shell selection.



#### Session 1.5: Hands-on on Registration and Segmentation

* **Format**: Hands-on Lab (1h15)
* **Goals**:
* Perform multimodal co-registration between structural T1w and diffusion b0/DWI images.
* Compute and inspect linear (rigid/affine) and non-linear diffeomorphic transformations using ANTs and FSL.
* Perform fast, robust anatomical brain segmentation using FreeSurfer's `mri_synthseg` to generate tissue and region-of-interest (ROI) masks.


* **Prerequisites**: Sessions 1.2 & 1.3.
* **Data & Tools**:
* Data: `t1.nii.gz`, `dwi.nii.gz`, `b0.nii.gz`.
* Tools: ANTs (`antsRegistrationSyNQuick.sh`, `antsApplyTransforms`), FSL (`flirt`, `bet`), FreeSurfer (`mri_synthseg`), MRView / MI-Brain.


* **Key Outputs**:
* `t1_to_b0.nii.gz`, `t1_to_b0_affine.mat`, `t1_to_b0_warp.nii.gz`, `synthseg_parc.nii.gz`, `wm_mask.nii.gz`, `cc_roi.nii.gz`.


* **Outline & Code Examples**:
1. *Brain Extraction on T1w & b0*:
```bash
bet b0.nii.gz b0_brain.nii.gz -f 0.25 -m

```


2. *Multimodal Rigid/Affine Registration with ANTs*:
```bash
antsRegistrationSyNQuick.sh -d 3 -f b0_brain.nii.gz -m t1.nii.gz -t a -o t1_to_b0_

```


3. *Anatomical Segmentation with SynthSeg*:
```bash
mri_synthseg --i t1.nii.gz --o t1_synthseg.nii.gz --robust
antsApplyTransforms -d 3 -i t1_synthseg.nii.gz -r b0_brain.nii.gz \
  -t t1_to_b0_0GenericAffine.mat -n NearestNeighbor -o synthseg_in_dwi.nii.gz

```


4. *Visual Quality Control*: Overlay segmentation boundaries on b0 in MRView.



---

## Day 2: Core Processing: From Raw DWI to Tracts (Full Day + Evening)

* **Daily Theme**: Fundamental dMRI preprocessing, DTI modeling, quality assurance, and basic tractography.
* **Daily Goal**: Learn to diagnose raw diffusion artifacts, fit tensor models, quality-control outputs on provided and personal datasets, and generate a first deterministic tractogram.

```
08:30 - 09:00 | Early start emergency help for setup [Technical Help]
09:00 - 09:45 | Session 2.1: Connectional Anatomy [Presenter: Chiara Maffei]
09:45 - 10:30 | Session 2.2: Preprocessing Overview [Presenter: Francois Rheault]
10:30 - 11:00 | Break
11:00 - 12:00 | Session 2.3: Modeling Overview (DWI to Orientation) [Presenter: Alonso Ramirez]
12:00 - 13:30 | Lunch
13:30 - 14:15 | Session 2.4: Hands-on Quality Assurance (Our data) [Hands-on Lab]
14:15 - 15:00 | Session 2.5: Hands-on Quality Assurance (Your data) [Hands-on Lab]
15:00 - 16:00 | Session 2.6: Tractography Introduction [Presenter: Donald Tournier]
16:00 - 17:30 | Session 2.7: Hands-on DET Tractography [Hands-on Lab]
17:30 - 19:00 | Free time
19:00 - 22:00 | Social dinner / evening event

```

#### Session 2.1: Connectional Anatomy

* **Format**: Theoretical Lecture (0h45)
* **Presenter**: Chiara Maffei
* **Goals**:
* Provide an anatomical overview of the brain's major white matter pathways.
* Categorize pathways: Commissural (Corpus Callosum, Anterior Commissure), Association (SLF, AF, IFOF, ILF, UF, Cingulum), and Projection fibers (Corticospinal Tract, Thalamic Radiations, Optic Radiations).
* Build an anatomical mental atlas for tractography validation.



#### Session 2.2: Preprocessing Overview

* **Format**: Theoretical Lecture (0h45)
* **Presenter**: Francois Rheault
* **Goals**:
* Understand the physics, visual appearance, and consequences of common dMRI artifacts.
* Survey standard correction steps: thermal noise removal (MP-PCA), Gibbs ringing correction, motion & eddy current correction, $B_0$ susceptibility-induced geometric distortions (topup/fieldmaps), and $B_1$ field inhomogeneity (N4).



#### Session 2.3: Modeling Overview (DWI to Orientation)

* **Format**: Theoretical Lecture (1h00)
* **Presenter**: Alonso Ramirez
* **Goals**:
* Understand the distinction between model-based (DTI) and model-free/spherical deconvolution approaches (ODFs/fODFs).
* Understand the Diffusion Tensor model, its eigensystem ($\lambda_1, \lambda_2, \lambda_3$), and scalar indices ($FA$, $MD$, $RD$, $AD$, DEC RGB map).
* Recognize the fundamental "crossing fiber problem" limitation of the single-tensor model.



#### Session 2.4: Hands-on Quality Assurance (Our Data)

* **Format**: Hands-on Lab (0h45)
* **Goals**:
* Inspect raw DWI dimensions, voxel spacing, and b-values/b-vectors.
* Perform skull-stripping (BET) and fit DTI using MRtrix3 (`dwi2tensor`, `tensor2metric`).
* Verify tensor orientation and detect flipped gradient schemes via directional DEC-FA RGB maps.


* **Data & Tools**: Provided `dwi.nii.gz`, `dwi.bval`, `dwi.bvec`, FSL (`bet`), MRtrix3 (`dwiextract`, `dwi2tensor`, `tensor2metric`), MRView.
* **Key Outputs**: `fa.nii.gz`, `md.nii.gz`, `rgb.nii.gz`, `ev.nii.gz`.

#### Session 2.5: Hands-on Quality Assurance (Your Data)

* **Format**: Hands-on Lab (0h45)
* **Goals**:
* Run the identical inspection and DTI fitting sequence on personal participant datasets.
* Troubleshoot heterogeneous acquisition protocols (single vs. multi-shell, gradient tables, oblique slices).



#### Session 2.6: Tractography Introduction

* **Format**: Theoretical Lecture (1h00)
* **Presenter**: Donald Tournier
* **Goals**:
* Understand numerical streamline integration algorithms (Euler vs. Runge-Kutta).
* Differentiate local vs. global, and deterministic vs. probabilistic tractography.
* Review practical tracking parameters: seeding mechanisms, stopping masks, angular curvature thresholds, and step size.



#### Session 2.7: Hands-on DET Tractography

* **Format**: Hands-on Lab (1h30)
* **Goals**:
* Perform ROI-based deterministic DTI tractography on the Corpus Callosum using `tckgen`.
* Validate streamline geometry against anatomical expectations in MRView / MI-Brain.


* **Data & Tools**: `ev.nii.gz`, `b0_brain_mask.nii.gz`, `cc_roi.nii.gz`, MRtrix3 (`tckgen`, `tckedit`), MRView / MI-Brain.
* **Key Command**:
```bash
tckgen -algorithm Tensor_Det -seed_image cc_mask.nii.gz -mask b0_brain_mask.nii.gz \
  -select 10000 ev.nii.gz dti_det_cc_10k.tck

```



---

## Day 3: Advanced Microstructure, Fixels & Advanced Tractography (Full Day + Evening)

* **Daily Theme**: Advanced multi-compartment biophysical modeling, fixel-based analysis, and spherical deconvolution tractography.
* **Daily Goal**: Master multi-shell microstructure models (NODDI/DKI), learn Fixel-Based Analysis (FBA) workflows, and run state-of-the-art CSD deterministic and probabilistic tractography.

```
08:30 - 09:00 | Early start emergency help for setup [Technical Help]
09:00 - 10:00 | Session 3.1: Intro to microstructure modelling [Presenter: Alonso Ramirez]
10:00 - 10:30 | Break
10:30 - 11:30 | Session 3.2: Fixel-based analysis [Presenter: Donald Tournier]
11:30 - 12:30 | Session 3.3: Hands-on on microstructure (our data) [Hands-on Lab]
12:30 - 14:00 | Lunch
14:00 - 14:45 | Session 3.4: Hands-on on Fixels (our data) [Hands-on Lab]
14:45 - 15:45 | Session 3.5: Hands-on microstructure/fixels (Your Data) [Hands-on Lab]
15:45 - 16:30 | Session 3.6: Tractography : Anatomy of a command line [Presenter: Donald Tournier]
16:30 - 17:30 | Session 3.7: Hands-on DET/PROB Tractography (our data) [Hands-on Lab]
17:30 - 19:00 | Free time
19:00 - 22:00 | Trivia night at "tigelleria"

```

#### Session 3.1: Intro to Microstructure Modelling

* **Format**: Theoretical Lecture (1h00)
* **Presenter**: Alonso Ramirez
* **Goals**:
* Understand the physical and mathematical foundations of advanced microstructural modeling beyond DTI.
* Study multi-compartment biophysical models: NODDI (Neurite Orientation Dispersion and Density Imaging), Diffusion Kurtosis Imaging (DKI), Mean Apparent Propagator (MAP-MRI), and Free Water Elimination.
* Interpret parametric maps: Neurite Density Index (NDI / $v_{in}$), Orientation Dispersion Index (ODI), Isotropic Volume Fraction ($v_{iso}$), Mean Kurtosis (MK), Axial Kurtosis (AK), and Radial Kurtosis (RK).


* **Prerequisites**: Day 2 modeling concepts and multi-shell dMRI acquisitions.
* **Outline & Concepts**:
* *Multi-compartment modeling*: Intra-cellular (restricted cylinder), extra-cellular (hindered anisotropic), and free water (isotropic Gaussian).
* *NODDI formulation*: Fitting parameters, b-value requirements ($b \ge 2000\text{ s/mm}^2$), and clinical utility.
* *Non-Gaussian diffusion*: Diffusion Kurtosis Imaging (DKI) metrics and their sensitivity to microstructural heterogeneity.



#### Session 3.2: Fixel-Based Analysis (FBA)

* **Format**: Theoretical Lecture (1h00)
* **Presenter**: Donald Tournier
* **Goals**:
* Understand the concept of a "fixel" (a specific fiber population within a single voxel).
* Overcome the limitations of voxel-averaged metrics (e.g., FA drop in crossing fibers).
* Master the three primary fixel metrics: Fiber Density (FD), Fiber Cross-Section (FC), and combined Fiber Density & Cross-Section (FDC).
* Understand the FBA pipeline: population template creation, fixel segmentation, spatial correspondence, and Connectivity-based Fixel Enhancement (CFE) statistics.


* **Prerequisites**: Spherical deconvolution (fODF) principles.
* **Outline & Concepts**:
* *Fixel Definition*: Continuous orientation distribution segmented into discrete orientations with associated volumes.
* *Microstructural vs. Macrostructural changes*: FD (microscopic intra-axonal volume) vs. FC (macroscopic bundle cross-sectional area changes).
* *Statistical testing on fixels*: Permutation testing with CFE along fiber pathways.



#### Session 3.3: Hands-on on Microstructure (Our Data)

* **Format**: Hands-on Lab (1h00)
* **Goals**:
* Fit the NODDI model using AMICO and/or DIPY on provided multi-shell dataset.
* Compute and visualize NDI, ODI, and ISOVF maps.
* Compute Diffusion Kurtosis Imaging (DKI) scalar maps using DIPY.


* **Data & Tools**: Multi-shell `dwi.nii.gz` ($b=0, 1000, 2000\text{ s/mm}^2$), AMICO, DIPY, MRView.
* **Key Outputs**: `NDI.nii.gz`, `ODI.nii.gz`, `ISOVF.nii.gz`, `MK.nii.gz`.
* **Outline & Code Examples**:
1. *Fitting NODDI with AMICO (Python)*:
```python
import amico
amico.core.setup()
ae = amico.Evaluation(".", "subject_01")
ae.load_data(dwi_filename="dwi.nii.gz", scheme_filename="dwi.scheme", mask_filename="mask.nii.gz")
ae.set_model("NODDI")
ae.generate_kernels()
ae.fit()
ae.save_results()

```


2. *Fitting DKI with DIPY*:
```python
import dipy.reconst.dki as dki
from dipy.io.image import load_nifti
data, affine = load_nifti("dwi.nii.gz")
dkimodel = dki.DiffusionKurtosisModel(gtab)
dkifit = dkimodel.fit(data, mask=mask)
mk = dkifit.mk(0, 3)

```





#### Session 3.4: Hands-on on Fixels (Our Data)

* **Format**: Hands-on Lab (0h45)
* **Goals**:
* Segment fODFs into discrete fixels using MRtrix3 `fod2fixel`.
* Compute Fiber Density (FD) across fixels and display fixel vector plots in MRView.
* Compare fixel-wise metrics with voxel-averaged DTI metrics in complex crossing fiber regions (e.g., Centrum Semiovale).


* **Data & Tools**: `wmfod.nii.gz`, `mask.nii.gz`, MRtrix3 (`fod2fixel`, `fixelconvert`), MRView (Fixel Plot tool).
* **Key Outputs**: Fixel directory (`fixel_dir/index.mif`, `fixel_dir/directions.mif`, `fixel_dir/fd.mif`).
* **Code Example**:
```bash
fod2fixel wmfod.nii.gz fixel_dir -afd fd.mif -peak peaks.mif -mask mask.nii.gz
mrview b0.nii.gz -fixel.load fixel_dir/index.mif

```



#### Session 3.5: Hands-on Microstructure & Fixels (Your Data)

* **Format**: Hands-on Lab (1h00)
* **Goals**:
* Evaluate multi-shell compatibility of participants' personal data for NODDI/DKI and FBA.
* Execute AMICO or DIPY pipelines on participant datasets and troubleshoot protocol-specific parameter tuning.



#### Session 3.6: Tractography : Anatomy of a Command Line

* **Format**: Theoretical Lecture (0h45)
* **Presenter**: Donald Tournier
* **Goals**:
* Understand Constrained Spherical Deconvolution (CSD), Fiber Response Functions (FRF), Single-Shell Single-Tissue (SSST) vs. Multi-Shell Multi-Tissue (MSMT) CSD.
* Deconstruct tracking command-line parameters (MRtrix3 `tckgen` vs. Scilpy `scil_compute_local_tracking.py`): step size, angular cutoff, FOD amplitude threshold (`cutoff` / `sf_threshold`), Anatomically Constrained Tractography (ACT), and seeding criteria.



#### Session 3.7: Hands-on DET/PROB Tractography (Our Data)

* **Format**: Hands-on Lab (1h00)
* **Goals**:
* Estimate response functions (`dwi2response dhollander`) and perform MSMT-CSD (`dwi2fod msmt_csd`).
* Run deterministic (`iFOD1`) and probabilistic (`iFOD2`) CSD tractography.
* Compare streamline dispersion, curvature, and fanning between DTI and CSD tracking.


* **Data & Tools**: `dwi_preproc.nii.gz`, `bvals`, `bvecs`, MRtrix3 (`dwi2response`, `dwi2fod`, `tckgen`), MRView / MI-Brain.
* **Key Outputs**: `wmfod.nii.gz`, `csd_det_10k.tck`, `csd_prob_10k.tck`.

---

## Day 4: Pipelines, Bundle Segmentation & Tractometry (Full Day + Evening)

* **Daily Theme**: High-throughput reproducible pipelines, automated bundle extraction, and quantitative along-tract profilometry.
* **Daily Goal**: Understand standardized preprocessing pipelines, segment anatomical white matter bundles using automated methods, and extract along-tract microstructural profiles (tractometry).

```
08:30 - 09:00 | Early start emergency help for bash & data [Technical Help]
09:00 - 09:30 | Session 4.1: Preprocessing In-Depth: The Power of Pipelines [Presenter: Francois Rheault]
09:30 - 10:00 | Break
10:00 - 10:45 | Session 4.2: Bundle Segmentation: From spaghetti to Highways [Presenter: Chiara Maffei]
10:45 - 12:15 | Session 4.3: Hands-on: Bundle Segmentation (our data) [Hands-on Lab]
12:15 - 13:45 | Lunch
13:45 - 14:45 | Session 4.4: Hands-on: Bundle Segmentation (your data) [Hands-on Lab]
14:45 - 15:45 | Session 4.5: Tractometry: Profiling Along the Pathways [Presenter: Alexander Leemans]
15:45 - 17:15 | Session 4.6: Hands-on: From Tracts to Tables [Hands-on Lab]
17:15 - 18:15 | Free time
18:15 - 21:15 | Social dinner

```

#### Session 4.1: Preprocessing In-Depth: The Power of Pipelines

* **Format**: Theoretical Lecture (0h30)
* **Presenter**: Francois Rheault
* **Goals**:
* Understand the necessity of automated pipelines for reproducible neuroimaging (BIDS standard, containerization via Docker/Singularity).
* Compare standard community pipelines: TractoFlow, QSIPrep, and MRtrix3 `dwifslpreproc`.
* Review automated QC report generation and visual artifact inspection protocols.



#### Session 4.2: Bundle Segmentation: From Spaghetti to Highways

* **Format**: Theoretical Lecture (0h45)
* **Presenter**: Chiara Maffei
* **Goals**:
* Understand the principles of dissecting whole-brain tractograms into recognized anatomical bundles.
* Compare segmentation paradigms: manual ROI virtual dissection (inclusion/exclusion/endpoints), automated atlas-based methods (BundleSeg, pyAFQ), supervised clustering (RecoBundles), and machine-learning approaches (TractSeg, DeepBundle).



#### Session 4.3: Hands-on: Bundle Segmentation (Our Data)

* **Format**: Hands-on Lab (1h30)
* **Goals**:
* Dissect key bundles (e.g., Corticospinal Tract, Arcuate Fasciculus) via manual ROI logic using `tckedit`.
* Run automated bundle extraction using `BundleSeg` (Scilpy) and/or `TractSeg`.
* Apply streamline length and outlier filtering to produce clean anatomical bundles.


* **Data & Tools**: `wb_100k.tck`, `synthseg_parc.nii.gz`, Scilpy (`scil_tractogram_segment_with_bundleseg.py`), MRtrix3 (`tckedit`), MI-Brain.
* **Key Outputs**: Segmented bundle tractograms (`cst_left.trk`, `af_left.trk`, `cc.trk`).

#### Session 4.4: Hands-on: Bundle Segmentation (Your Data)

* **Format**: Hands-on Lab (1h00)
* **Goals**:
* Execute automated bundle segmentation on participants' personal whole-brain tractograms.
* Diagnose missing bundles, adjust atlas registration, and refine filtering thresholds.



#### Session 4.5: Tractometry: Profiling Along the Pathways

* **Format**: Theoretical Lecture (1h00)
* **Presenter**: Alexander Leemans
* **Goals**:
* Understand along-tract microstructural profiling (tract profiling / tractometry).
* Learn methods for bundle core/centerline estimation and equidistant node resampling (e.g., 100 nodes).
* Address point-to-point anatomical correspondence across subjects, crossing fiber contamination, metric weighting, and family-wise multiple comparison correction.



#### Session 4.6: Hands-on: From Tracts to Tables

* **Format**: Hands-on Lab (1h30)
* **Goals**:
* Sample scalar metrics (FA, MD, NDI, AFD) along segmented bundle streamlines.
* Generate tabular `.csv` tract profile datasets using `pyAFQ` or Scilpy.
* Plot and statistically compare tract profiles in Python/Jupyter.


* **Data & Tools**: Segmented bundle files, scalar metric maps (`fa.nii.gz`, `NDI.nii.gz`), `pyAFQ`, Scilpy (`scil_compute_bundle_profile.py`), Python (Pandas, Seaborn).
* **Key Outputs**: `tract_profiles.csv`, statistical along-tract profile plots.

---

## Day 5: Clustering, Connectomics & Capstone Project (Full Day)

* **Daily Theme**: Streamline clustering, structural connectomics, experimental study design, and independent capstone project execution.
* **Daily Goal**: Learn unsupervised streamline clustering, construct and filter structural connectivity matrices, synthesize study design principles, and execute an end-to-end custom analysis on workshop or personal data.

```
08:30 - 09:00 | Early start review own tracking and bundles [Review / Support]
09:00 - 10:00 | Session 5.1: Tractography clustering: Grouping your spaghetti [Presenter: Pamela Guevara]
10:00 - 10:30 | Break
10:30 - 11:30 | Session 5.2: Connectomics: Mapping the Brain's Network [Presenter: Alessandro Daducci]
11:30 - 12:30 | Session 5.3: Study Design & Interpretation [Presenters: Luis Concha + Alexander Leemans]
12:30 - 14:00 | Lunch
14:00 - 14:45 | Sponsor presentation (____) [Sponsor Session]
14:45 - 15:00 | Outro & Concluding Remarks
15:00 - 18:00 | Session 5.4: Build your analysis (bundles, connectomes, clusters) [Capstone Project Lab]

```

#### Session 5.1: Tractography Clustering: Grouping Your Spaghetti

* **Format**: Theoretical Lecture (1h00)
* **Presenter**: Pamela Guevara
* **Goals**:
* Understand distance metrics for 3D streamlines: Mean Direct-Flip distance (MDF) and Bundle-based Minimum Distance (BMD).
* Master unsupervised streamline clustering algorithms (QuickBundles, QuickBundlesX, Hierarchical Dirichlet Processes).
* Explore supervised clustering and bundle recognition using white matter atlases (RecoBundles).
* Discover applications of clustering: tractogram simplification, exploratory discovery of superficial white matter (U-fibers), and artifact removal.


* **Prerequisites**: Whole-brain tractography and geometric representations.
* **Outline & Concepts**:
* *Streamline Distances*: Invariance to point ordering, resampling, and spatial indexing.
* *QuickBundles Algorithm*: Linear-time clustering using streamline centroids.
* *Superficial White Matter (SWM)*: Challenges in mapping short association fibers and how clustering provides automated parcellations.



#### Session 5.2: Connectomics: Mapping the Brain's Network

* **Format**: Theoretical Lecture (1h00)
* **Presenter**: Alessandro Daducci
* **Goals**:
* Model the brain as a complex network/graph: nodes (cortical/subcortical parcellations) and edges (streamlines).
* Understand connection weighting schemes: binary, streamline count, path length, and microstructural weighting.
* Understand quantitative streamline filtering: SIFT/SIFT2 (MRtrix3), COMMIT (Convex Optimization Modeling for Microstructure Informed Tractography), and LiFE.
* Introduction to graph metrics: degree, node strength, clustering coefficient, path length, efficiency, modularity, and rich-club organization.



#### Session 5.3: Study Design & Interpretation

* **Format**: Guided Interactive Lecture & Panel (1h00)
* **Presenters**: Luis Concha + Alexander Leemans [Validate: Co-presenters confirmed?]
* **Goals**:
* Synthesize workshop knowledge into a practical decision tree for planning dMRI research studies.
* Select optimal trade-offs: acquisition protocols, DTI vs. CSD vs. microstructure models, tractometry vs. connectomics.
* Address scanner harmonization, multi-site effects, and test-retest reproducibility.
* Avoid over-interpretation: recognizing that tractography streamlines do not represent individual biological axons.



#### Sponsor Presentation & Outro

* **Time**: 14:00 - 15:00
* **Presenter**: Sponsor Name TBD (e.g., Olea Medical / Industry Partner)
* **Outro (14:45–15:00)**: Concluding remarks, certificate distribution, and feedback survey.

#### Session 5.4: Build Your Analysis (Bundles, Connectomes, Clusters)

* **Format**: Capstone Project Sprint / Hands-on Hackathon (3h00)
* **Goals**:
* Build and execute an end-to-end quantitative analysis pipeline on either the workshop dataset or personal research data.
* Choose one of three specialized tracks with dedicated instructor support:
* **Track A (Tractometry & Bundle Extraction)**: Automated bundle segmentation with BundleSeg/TractSeg followed by pyAFQ along-tract profiling.
* **Track B (Quantitative Structural Connectomics)**: FreeSurfer/SynthSeg parcellation + `tck2connectome` + SIFT2 weighting + NetworkX graph analysis in Python.
* **Track C (Tractography Clustering & Superficial White Matter)**: Unsupervised QuickBundles / RecoBundles clustering using DIPY and Scilpy.




* **Data & Tools**: All workshop outputs, personal datasets, DIPY, MRtrix3, Scilpy, pyAFQ, NetworkX.
* **Key Outputs**: A fully executed analytical workflow script, quantitative figures, and exportable data tables (`.csv`).
* **Code Example (Track B — Quantitative Connectome Construction)**:
```bash
# Step 1: Compute SIFT2 streamline weights
tcksift2 -act 5tt.nii.gz wb_100k.tck wmfod.nii.gz sift2_weights.txt
# Step 2: Generate connectome matrix
tck2connectome -symmetric -zero_diagonal -scale_invnodevol \
  -tck_weights_in sift2_weights.txt wb_100k.tck aparc+aseg.nii.gz connectome_sift2.csv

```


```python
# Step 3: Graph Analysis in Python
import networkx as nx
import numpy as np
matrix = np.loadtxt("connectome_sift2.csv", delimiter=",")
G = nx.from_numpy_array(matrix)
print(f"Graph density: {nx.density(G):.3f}")
print(f"Global efficiency: {nx.global_efficiency(G):.3f}")

```



---

# Part III: Appendices & Supplemental Resources

### Consolidated Command Reference

```bash
# ==========================================
# 1. REGISTRATION & SEGMENTATION (DAY 1)
# ==========================================
# Skull-stripping
bet b0.nii.gz b0_brain.nii.gz -f 0.25 -m

# Multimodal Affine Registration with ANTs
antsRegistrationSyNQuick.sh -d 3 -f b0_brain.nii.gz -m t1.nii.gz -t a -o t1_to_b0_

# Fast Anatomical Segmentation with FreeSurfer SynthSeg
mri_synthseg --i t1.nii.gz --o t1_synthseg.nii.gz --robust
antsApplyTransforms -d 3 -i t1_synthseg.nii.gz -r b0_brain.nii.gz \
  -t t1_to_b0_0GenericAffine.mat -n NearestNeighbor -o synthseg_in_dwi.nii.gz

# ==========================================
# 2. DTI & QUALITY ASSURANCE (DAY 2)
# ==========================================
dwi2tensor dwi.nii.gz -fslgrad dwi.bvec dwi.bval dti.nii.gz
tensor2metric dti.nii.gz -fa fa.nii.gz -vector ev.nii.gz -rd rd.nii.gz -ad ad.nii.gz

# Deterministic DTI Tractography
tckgen -algorithm Tensor_Det -seed_image cc_roi.nii.gz -mask b0_brain_mask.nii.gz \
  -select 10000 ev.nii.gz dti_det_cc_10k.tck

# ==========================================
# 3. MICROSTRUCTURE & FIXEL ANALYSIS (DAY 3)
# ==========================================
# Fixel-Based Analysis in MRtrix3
fod2fixel wmfod.nii.gz fixel_dir -afd fd.mif -peak peaks.mif -mask mask.nii.gz

# MSMT-CSD & Probabilistic Tractography
dwi2response dhollander dwi.nii.gz wm.txt gm.txt csf.txt -fslgrad dwi.bvec dwi.bval
dwi2fod msmt_csd dwi.nii.gz wm.txt wmfod.nii.gz gm.txt gmfod.nii.gz csf.txt csffod.nii.gz
tckgen -algorithm iFOD2 -seed_dynamic wmfod.nii.gz -maxlength 250 -select 100000 \
  wmfod.nii.gz wb_100k.tck

# ==========================================
# 4. BUNDLE SEGMENTATION & TRACTOMETRY (DAY 4)
# ==========================================
# Scilpy automated bundle segmentation
scil_tractogram_segment_with_bundleseg.py wb_100k.trk atlas_directory/ bundles/

# pyAFQ tractometry profiling (CLI / Python)
pyAFQ --config afq_config.toml

# ==========================================
# 5. CLUSTERING & CONNECTOMICS (DAY 5)
# ==========================================
# SIFT2 Streamline Filtering & Connectome Generation
tcksift2 -act 5tt.nii.gz wb_100k.tck wmfod.nii.gz sift2_weights.txt
tck2connectome -symmetric -zero_diagonal -scale_invnodevol -tck_weights_in sift2_weights.txt \
  wb_100k.tck aparc+aseg.nii.gz connectome_sift2.csv

```

### Provided Dataset Specifications

* **Diffusion-Weighted Image (DWI)**:
* **Sequence**: Spin-echo EPI, Single-shot
* **Resolution**: $2.0 \times 2.0 \times 2.0\text{ mm}^3$ isotropic
* **Dimensions**: $110 \times 110 \times 70$
* **TR / TE**: $8500\text{ ms} / 85\text{ ms}$
* **Phase Encoding**: Anterior-Posterior (AP) with paired reverse-phase (PA) $b=0$ acquisitions
* **Diffusion Scheme** (Multi-shell):
* $b = 0\text{ s/mm}^2$ ($6$ volumes)
* $b = 1000\text{ s/mm}^2$ ($30$ gradient directions)
* $b = 2000\text{ s/mm}^2$ ($60$ gradient directions)




* **Structural Image**:
* **Sequence**: 3D T1-weighted MPRAGE ($1.0\text{ mm}^3$ isotropic)



---

### Summary of Major Updates & Adjustments Made:

1. **Schedule Alignment**: Re-indexed and synchronized all session numbers, daily titles, and time blocks across all 5 days with the master spreadsheet [IST_summer_school_schedule](https://docs.google.com/spreadsheets/d/1-53mGmWiw4spUbiti0I1kJMHaiB_VY7rC1xomSLmVzg/edit).
2. **New Sessions Drafted**: Formulated syllabi, learning objectives, open-source software stacks (ANTs, SynthSeg, AMICO, DIPY, MRtrix3 FBA, Scilpy/QuickBundles, pyAFQ, NetworkX), and practical code examples for all 9 new/expanded sessions (1.1, 1.5, 3.1, 3.2, 3.3, 3.4, 3.5, 5.1, and 5.4).
3. **Color-Coded Feedback**: Applied blue text to all newly generated content and highlighted in yellow the specific organizational details for your manual confirmation.

(If you use scil_search_keywords you can type word like fixel, NODDI, DKI, Freewater (FW) to then call the proposed script with -h, this could help you find alternative to some tool and proposed two command line for the tutorial)
