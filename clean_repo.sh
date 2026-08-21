#!/bin/bash

# This script cleans the repository by deleting all generated files and folders except for the workshop source files.

echo "Cleaning the repository..."

find . -maxdepth 1 \
    -not -name "template" \
    -not -name "notebooks" \
    -not -name "dicom_filtered_sub01.zip" \
    -not -name "tutorial*" \
    -not -name "Dockerfile" \
    -not -name "requirements.txt" \
    -not -name "launch_jupyter.sh" \
    -not -name "NOTEBOOK.md" \
    -not -name "*CURRICULUM*" \
    -not -name "*curriculum*" \
    -not -name "README.md" \
    -not -name "clean_repo.sh" \
    -not -name "check_installation.sh" \
    -not -name "check_setup.sh" \
    -not -name ".git" \
    -not -name ".gitignore" \
    -not -name "." \
    -exec rm -rf {} +

echo "Repository cleaned."
