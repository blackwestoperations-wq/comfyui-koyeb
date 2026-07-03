#!/usr/bin/env bash
set -euo pipefail

WORKSPACE="/workspace"
REMOTE="dospaces"

echo "=========================================="
echo "ComfyUI + Spaces (NO-MOVE SAFE MODE)"
echo "=========================================="

python - <<EOF
import torch
print("PyTorch:", torch.__version__)
print("CUDA:", torch.cuda.is_available())
if torch.cuda.is_available():
    print(torch.cuda.get_device_name(0))
EOF

# ---------------------------------------------------
# Configure rclone
# ---------------------------------------------------

mkdir -p /root/.config/rclone

cat >/root/.config/rclone/rclone.conf <<EOF
[$REMOTE]
type = s3
provider = DigitalOcean
env_auth = false
access_key_id = ${AWS_ACCESS_KEY_ID}
secret_access_key = ${AWS_SECRET_ACCESS_KEY}
endpoint = ams3.digitaloceanspaces.com
region = ${AWS_DEFAULT_REGION}
acl = private
EOF

# ---------------------------------------------------
# Workspace
# ---------------------------------------------------

mkdir -p \
    ${WORKSPACE}/models \
    ${WORKSPACE}/custom_nodes \
    ${WORKSPACE}/user \
    ${WORKSPACE}/input \
    ${WORKSPACE}/output \
    ${WORKSPACE}/workflows

echo "BOOT: Downloading models..."

rclone copy \
    ${REMOTE}:${SPACES_BUCKET}/models \
    ${WORKSPACE}/models \
    --ignore-existing \
    --exclude "*.partial" \
    --transfers 4 \
    --checkers 4 \
    --s3-no-check-bucket || true

echo "BOOT: Downloading workflows..."

rclone copy \
    ${REMOTE}:${SPACES_BUCKET}/workflows \
    ${WORKSPACE}/workflows \
    --ignore-existing \
    --exclude "*.partial" \
    --transfers 4 \
    --checkers 4 \
    --s3-no-check-bucket || true

# ---------------------------------------------------
# Link workspace into ComfyUI
# ---------------------------------------------------

rm -rf /app/models
ln -s ${WORKSPACE}/models /app/models

rm -rf /app/input
ln -s ${WORKSPACE}/input /app/input

rm -rf /app/output
ln -s ${WORKSPACE}/output /app/output

rm -rf /app/user
ln -s ${WORKSPACE}/user /app/user

# Keep built-in Manager but allow extra custom nodes
mkdir -p /app/user/__manager

# ---------------------------------------------------
# ComfyUI Manager configuration
# ---------------------------------------------------

cat >/app/user/__manager/config.ini <<EOF
[default]
security_level = weak
network_mode = public
EOF

echo "ComfyUI-Manager security level set to WEAK."

# ---------------------------------------------------
# Output uploader
# ---------------------------------------------------

sync_outputs() {
    while true; do
        sleep 60

        echo "[UPLOAD] Syncing outputs..."

        rclone copy \
            ${WORKSPACE}/output \
            ${REMOTE}:${SPACES_BUCKET}/output \
            --ignore-existing \
            --exclude "*.partial" \
            --exclude "*.tmp" \
            --transfers 2 \
            --checkers 2 \
            --s3-no-check-bucket \
            --log-level ERROR || true
    done
}

sync_outputs &

echo "=========================================="
echo "Starting ComfyUI..."
echo "=========================================="

exec python /app/main.py \
    --listen 0.0.0.0 \
    --port 8188 \
    --extra-model-paths-config /workspace/extra_model_paths.yaml
