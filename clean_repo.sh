#!/bin/bash

# This script cleans the repository by deleting all generated files and folders except for the workshop source files.

echo "Cleaning the repository..."

find . -maxdepth 1 \
    -not -name "template" \
    -not -name "notebooks" \
    -not -name "dicom_filtered_sub01.zip" \
    -not -name "tutorial*" \
    -not -name "Dockerfile*" \
    -not -name "requirements.txt" \
    -not -name "launch_jupyter.sh" \
    -not -name "NOTEBOOK.md" \
    -not -name "REPORT.md" \
    -not -name "PLAN.md" \
    -not -name "SUGGESTION.md" \
    -not -name "precomputed" \
    -not -name "*CURRICULUM*" \
    -not -name "*curriculum*" \
    -not -name "README.md" \
    -not -name "COMMANDS.md" \
    -not -name "*schedule*" \
    -not -name "*.xlsx" \
    -not -name "clean_repo.sh" \
    -not -name "prepare_docker.sh" \
    -not -name ".docker_cache" \
    -not -name "run_all_tutorials.sh" \
    -not -name "check_installation.sh" \
    -not -name "check_setup.sh" \
    -not -name "validate_*.py" \
    -not -name ".git" \
    -not -name ".gitignore" \
    -not -name ".dockerignore" \
    -not -name "venv" \
    -not -name ".venv" \
    -not -name "." \
    -exec rm -rf {} +

echo "Repository cleaned."
