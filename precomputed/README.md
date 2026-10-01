# Precomputed derivatives (workshop subject only)

`t1_synthseg.nii.gz`: FreeSurfer 7.4.1 `mri_synthseg --i bids_data/sub-01/ses-01/anat/t1.nii.gz --o t1_synthseg.nii.gz --robust --parc --threads 4`
(2026-09-28). SynthSeg needs ~15 GB of RAM; use this file only if the command crashes, and ONLY for the workshop T1.
In the Docker image it is available at `/opt/ist2027/precomputed/t1_synthseg.nii.gz`.
