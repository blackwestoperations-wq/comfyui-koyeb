#!/bin/bash
set -euo pipefail

# Koyeb injects $PORT; fall back to 8188 for local dev
PORT="${PORT:-8188}"

echo "================================================"
echo " ComfyUI  |  port: ${PORT}  |  CUDA: $(nvcc --version 2>/dev/null | grep release | awk '{print $6}' || echo 'n/a')"
echo "================================================"

cd /app/ComfyUI

exec python3 main.py \
    --listen 0.0.0.0 \
    --port "${PORT}" \
    --disable-auto-launch
