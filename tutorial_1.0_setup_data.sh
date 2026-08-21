#!/bin/bash
# For pedagogical context, notes, and tips, refer to NOTEBOOK.md.
#
# ======================================================================
# dMRI Summer School - Tutorial 1.0 (Setup and Data Download)
#
# Theme: Setup and Data Download
#
# Goal: To create a BIDS-compliant directory structure and prepare
#       the raw DWI and T1w datasets for the hands-on sessions.
#
# Outputs:
#   - bids_data/sub-01/ses-01/dwi/ (dwi.nii.gz, dwi.bval, dwi.bvec)
#   - bids_data/sub-01/ses-01/anat/ (t1.nii.gz)
# ======================================================================

echo "Step 1: Unzipping raw DICOM data..."
unzip -q -o dicom_filtered_sub01.zip
chmod -R u+rwx dicom_data

echo "Step 2: Converting DICOM to NIfTI with dcm2niix..."
mkdir -p nifti_data
dcm2niix -o nifti_data/ -z y dicom_data/

echo "Step 3: Creating BIDS directory structure..."
mkdir -p bids_data/sub-01/ses-01/dwi
mkdir -p bids_data/sub-01/ses-01/anat

mrconvert nifti_data/dicom_data_WIP_DWI_20230912152935_1201.nii.gz bids_data/sub-01/ses-01/dwi/dwi.nii.gz -stride 1,2,3,4 -force
cp nifti_data/dicom_data_WIP_DWI_20230912152935_1201.bval bids_data/sub-01/ses-01/dwi/dwi.bval
cp nifti_data/dicom_data_WIP_DWI_20230912152935_1201.bvec bids_data/sub-01/ses-01/dwi/dwi.bvec
cp nifti_data/dicom_data_WIP_3D_T1_20230912152935_901.nii.gz bids_data/sub-01/ses-01/anat/t1.nii.gz

echo "Tutorial 1.0 complete. BIDS dataset created in bids_data/"
