#!/bin/bash
# ======================================================================
# IST Summer School 2027 — Docker Build Preparation & Caching Script
#
# Pre-downloads all large binary dependencies (FreeSurfer, ANTs, FSL)
# to a local `.docker_cache/` directory with resume support (wget -c).
# This drastically accelerates docker builds from ~20 minutes to ~2 minutes.
# ======================================================================

set -euo pipefail

CACHE_DIR=".docker_cache"
mkdir -p "$CACHE_DIR"

echo "============================================================"
echo " Preparing local cache for fast Docker builds..."
echo " Target directory: $(pwd)/$CACHE_DIR"
echo "============================================================"

# 1. FreeSurfer 7.4.1 Linux 64-bit Tarball (~5.5 GB)
FS_FILE="$CACHE_DIR/freesurfer-linux-ubuntu22_amd64-7.4.1.tar.gz"
FS_URL="https://surfer.nmr.mgh.harvard.edu/pub/dist/freesurfer/7.4.1/freesurfer-linux-ubuntu22_amd64-7.4.1.tar.gz"
if [ ! -f "$FS_FILE" ]; then
    echo "[DOWNLOADING] FreeSurfer 7.4.1 tarball..."
    wget -c --no-check-certificate -O "$FS_FILE" "$FS_URL"
    echo "  ✓ FreeSurfer downloaded."
else
    echo "  ✓ FreeSurfer tarball already cached: $FS_FILE"
fi

# 2. ANTs 2.5.0 Precompiled Binary Zip (~500 MB)
ANTS_FILE="$CACHE_DIR/ants-2.5.0-ubuntu-22.04-X64-gcc.zip"
ANTS_URL="https://github.com/ANTsX/ANTs/releases/download/v2.5.0/ants-2.5.0-ubuntu-22.04-X64-gcc.zip"
if [ ! -f "$ANTS_FILE" ]; then
    echo "[DOWNLOADING] ANTs 2.5.0 release zip..."
    wget -c -O "$ANTS_FILE" "$ANTS_URL"
    echo "  ✓ ANTs downloaded."
else
    echo "  ✓ ANTs binary already cached: $ANTS_FILE"
fi

# 3. FSL Official Installer Script
FSL_FILE="$CACHE_DIR/fslinstaller.py"
FSL_URL="https://fsl.fmrib.ox.ac.uk/fsldownloads/fslconda/releases/fslinstaller.py"
if [ ! -f "$FSL_FILE" ]; then
    echo "[DOWNLOADING] FSL installer..."
    wget -c -O "$FSL_FILE" "$FSL_URL"
    echo "  ✓ FSL installer downloaded."
else
    echo "  ✓ FSL installer already cached: $FSL_FILE"
fi

echo ""
echo "============================================================"
echo " All build dependencies ready in $CACHE_DIR."
echo " You can now run: docker build -t ist_summer_school_2027:latest ."
echo "============================================================"
