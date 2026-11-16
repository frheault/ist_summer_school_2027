#!/bin/bash
# See NOTEBOOK.md for study notes and quality control tips.
#
# ======================================================================
# dMRI Summer School - Tutorial 1.0 (Session 1.4)
#
# Theme: Data Setup and DICOM Conversion
#
# Goal: Unzip the raw DICOM files, convert them to NIfTI format, and
#       organize the DWI and T1w images into a BIDS folder structure.
#
# Inputs:
#   - dicom_filtered_sub01.zip
#
# Outputs:
#   - bids_data/sub-01/ses-01/dwi/ (dwi.nii.gz, dwi.bval, dwi.bvec)
#   - bids_data/sub-01/ses-01/anat/ (t1.nii.gz)
# ======================================================================

set -e

echo "Step 1: Unzipping the raw DICOM archive..."
unzip -q -o dicom_filtered_sub01.zip
chmod -R u+rwx dicom_data

echo "Step 2: Converting DICOM files to NIfTI with dcm2niix..."
mkdir -p nifti_data
dcm2niix -o nifti_data/ -z y dicom_data/

echo "Step 3: Organizing NIfTI files into bids_data/..."
mkdir -p bids_data/sub-01/ses-01/dwi
mkdir -p bids_data/sub-01/ses-01/anat

mrconvert nifti_data/dicom_data_WIP_DWI_20230912152935_1201.nii.gz \
    bids_data/sub-01/ses-01/dwi/dwi.nii.gz -stride 1,2,3,4 -force
cp nifti_data/dicom_data_WIP_DWI_20230912152935_1201.bval bids_data/sub-01/ses-01/dwi/dwi.bval
cp nifti_data/dicom_data_WIP_DWI_20230912152935_1201.bvec bids_data/sub-01/ses-01/dwi/dwi.bvec
cp nifti_data/dicom_data_WIP_3D_T1_20230912152935_901.nii.gz bids_data/sub-01/ses-01/anat/t1.nii.gz

echo "Tutorial 1.0 complete. BIDS data saved in bids_data/."
