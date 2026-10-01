#!/bin/bash
# IST Diffusion MRI Summer School 2027 - Installation Check
LOG_FILE="installation_check.log"
> "$LOG_FILE"
ERRORS=0

echo "=================================================" | tee -a "$LOG_FILE"
echo " dMRI Summer School 2027 - Installation Check"     | tee -a "$LOG_FILE"
echo "=================================================" | tee -a "$LOG_FILE"

# Environment auto-detection and setup
[ -z "$FREESURFER_HOME" ] && for d in /usr/local/freesurfer/8.2.0 /usr/local/freesurfer/8.0.0 /usr/local/freesurfer/7.4.1 /opt/freesurfer; do [ -d "$d" ] && export FREESURFER_HOME="$d" && break; done
[ -n "$FREESURFER_HOME" ] && [ -f "$FREESURFER_HOME/SetUpFreeSurfer.sh" ] && . "$FREESURFER_HOME/SetUpFreeSurfer.sh" > /dev/null 2>&1
[ -z "$FSLDIR" ] && for d in /opt/fsl /usr/local/fsl /usr/share/fsl; do [ -d "$d" ] && export FSLDIR="$d" && break; done
[ -n "$FSLDIR" ] && [ -f "$FSLDIR/etc/fslconf/fsl.sh" ] && . "$FSLDIR/etc/fslconf/fsl.sh" > /dev/null 2>&1
[ -z "$ANTSPATH" ] && for d in /opt/ants/bin /usr/local/ants/bin /usr/lib/ants; do [ -d "$d" ] && export ANTSPATH="$d" && export PATH="$ANTSPATH:$PATH" && break; done

# Ensure virtualenv python takes precedence over FSL/FreeSurfer embedded pythons
[ -d "/opt/venv/bin" ] && export PATH="/opt/venv/bin:$PATH"
[ -n "$VIRTUAL_ENV" ] && export PATH="$VIRTUAL_ENV/bin:$PATH"

check_cmd() {
    local cmd="$1"
    printf "Checking for %-35s ... " "${2:-$cmd}" | tee -a "$LOG_FILE"
    if command -v "$cmd" &> /dev/null; then
        echo "Installed ($(command -v "$cmd"))" | tee -a "$LOG_FILE"
    else
        echo "NOT FOUND" | tee -a "$LOG_FILE"; ERRORS=$((ERRORS + 1))
    fi
}

check_py() {
    local mod="$1"
    printf "Checking Python module %-27s ... " "$mod" | tee -a "$LOG_FILE"
    if python3 -c "import $mod" &> /dev/null; then
        echo "Installed" | tee -a "$LOG_FILE"
    else
        echo "NOT FOUND" | tee -a "$LOG_FILE"; ERRORS=$((ERRORS + 1))
    fi
}

echo -e "\n--- Core Neuroimaging Tools ---" | tee -a "$LOG_FILE"
check_cmd "bet" "FSL bet"
check_cmd "flirt" "FSL flirt"
check_cmd "antsRegistrationSyNQuick.sh" "ANTs SyNQuick registration"
check_cmd "antsApplyTransforms" "ANTs ApplyTransforms"
check_cmd "mri_synthseg" "FreeSurfer SynthSeg"

echo -e "\n--- Scilpy Tools ---" | tee -a "$LOG_FILE"
check_cmd "scil_header_print_info" "Scilpy header info"
check_cmd "scil_NODDI_maps" "Scilpy NODDI fitting"
check_cmd "scil_freewater_priors" "Scilpy Free Water priors"
check_cmd "scil_freewater_maps" "Scilpy Free Water maps"
check_cmd "scil_tractogram_segment_with_bundleseg" "Scilpy BundleSeg"
check_cmd "scil_tractogram_qbx" "Scilpy QuickBundlesX"
check_cmd "scil_bundle_compute_centroid" "Scilpy Bundle Centroids"

echo -e "\n--- MRtrix3 Suite ---" | tee -a "$LOG_FILE"
for cmd in mrinfo mrconvert mrcalc dwiextract dwi2tensor tensor2metric dwi2fod tckgen tckedit fod2fixel tcksift2 tck2connectome labelconvert transformconvert; do
    check_cmd "$cmd" "MRtrix3 $cmd"
done

echo -e "\n--- Python Modules ---" | tee -a "$LOG_FILE"
for mod in scilpy dipy amico trx numpy scipy nibabel networkx pandas matplotlib seaborn jupyterlab h5py; do
    check_py "$mod"
done

echo -e "\n--- System Utilities ---" | tee -a "$LOG_FILE"
check_cmd "dcm2niix" "dcm2niix"
check_cmd "unzip" "unzip"
check_cmd "curl" "curl"
printf "Checking for %-35s ... " "precomputed SynthSeg (fallback)" | tee -a "$LOG_FILE"
if [ -f /opt/ist2027/precomputed/t1_synthseg.nii.gz ] || [ -f precomputed/t1_synthseg.nii.gz ]; then
    echo "Found" | tee -a "$LOG_FILE"
else
    echo "NOT FOUND (only needed if mri_synthseg crashes)" | tee -a "$LOG_FILE"
fi

echo "=================================================" | tee -a "$LOG_FILE"
if [ "$ERRORS" -eq 0 ]; then
    echo " All mandatory tools are installed! (0 errors)" | tee -a "$LOG_FILE"
    echo "=================================================" | tee -a "$LOG_FILE"
    exit 0
else
    echo " ERROR: $ERRORS required tool(s) missing." | tee -a "$LOG_FILE"
    echo "=================================================" | tee -a "$LOG_FILE"
    exit 1
fi
