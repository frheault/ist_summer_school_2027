#!/bin/bash
# ======================================================================
# IST Summer School 2027 - Launch JupyterLab Server
#
# Usage (Inside Docker container with port forwarding):
#   docker run -it --rm -p 8888:8888 -v $(pwd):/data ist_summer_school_2027:latest ./launch_jupyter.sh
#
# Usage (Local workstation):
#   ./launch_jupyter.sh [PORT]
#
# Default Port: 8888
# Browser URL:  http://localhost:8888
#
# Notebooks available in notebooks/:
#   - notebooks/Day3_Microstructure_NODDI_DKI.ipynb
#   - notebooks/Day4_Tractometry_Profiling.ipynb
#   - notebooks/Day5_Connectomics_Graph_Theory.ipynb
# ======================================================================

PORT=${1:-8888}
IP="0.0.0.0"

echo "================================================="
echo " Starting JupyterLab Server for IST 2027"
echo " Host Access URL: http://localhost:$PORT"
echo " Listening on:    $IP:$PORT"
echo "================================================="

[ -f "/opt/venv/bin/activate" ] && source /opt/venv/bin/activate
[ -n "$VIRTUAL_ENV" ] && export PATH="$VIRTUAL_ENV/bin:$PATH"

if command -v jupyter &>/dev/null; then
    exec jupyter lab --ip="$IP" --port="$PORT" --no-browser --allow-root
else
    echo "Error: jupyter is not installed in the current environment." >&2
    echo "Please activate your virtualenv: source /opt/venv/bin/activate" >&2
    exit 1
fi
