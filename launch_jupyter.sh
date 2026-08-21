#!/bin/bash
# IST Summer School 2027 - Launch JupyterLab Server

PORT=${1:-8888}
IP="0.0.0.0"

echo "================================================="
echo " Starting JupyterLab on $IP:$PORT"
echo " Access URL: http://localhost:$PORT"
echo "================================================="

[ -f "/opt/venv/bin/activate" ] && source /opt/venv/bin/activate

if command -v jupyter &>/dev/null; then
    exec jupyter lab --ip="$IP" --port="$PORT" --no-browser --allow-root
else
    echo "Error: jupyter is not installed in the current environment." >&2
    exit 1
fi
